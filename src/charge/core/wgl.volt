// Copyright 2011-2019, Jakob Bornecrantz.
// Copyright 2019-2023, Collabora, Ltd.
// SPDX-License-Identifier: MIT OR Apache-2.0 OR BSL-1.0
/*!
 * @brief  Chunk of code that creates a EGL display and GL context.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module charge.core.wgl;

version (Windows):

import watt = [watt.conv, watt.library];

import lib.gl.gl45;
import lib.gl.loader;

import core.c.stdio;
import core.c.stdlib;
import core.c.string;
import core.c.windows;

import core.exception;

import charge.gfx.gl;
import charge.gfx.target;


struct WGL
{
	//! Simple logging function.
	log: dg(string);

	hDC: HDC;             //< GDI device context.
	hRC: HGLRC;           //< Rendering context.
	hWnd: HWND;           //< Window handle.
	hInstance: HINSTANCE; //< Application instance.
	opengl32: HMODULE;    //< Handle to opengl32.dll.


	fn loadFunc(c: string) void*
	{
		cstr := watt.toStringz(c);
		ptr := wglGetProcAddress(cstr);
		if (ptr is null) {
			ptr = GetProcAddress(opengl32, cstr);
		}
		return ptr;
	}

};

fn initWGL(ref wgl: WGL) bool
{
	width := cast(i32)256;
	height := cast(i32)32;
	pixelFormat: i32;
	wc: WNDCLASSA;
	dwExStyle: DWORD;
	dwStyle: DWORD;

	windowRect: RECT;
	windowRect.left = 0;
	windowRect.right = width;
	windowRect.top = 0;
	windowRect.bottom = height;

	wgl.hInstance = GetModuleHandleA(null);

	wc.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;  // Redraw on size, we unique DC.
	wc.lpfnWndProc = cast(WNDPROC)wndProcWGL;
	wc.cbClsExtra = 0;
	wc.cbWndExtra = 0;
	wc.hInstance = wgl.hInstance;
	wc.hIcon = LoadIconA(null, cast(LPCSTR)cast(void*)IDI_WINLOGO);
	wc.hCursor = LoadCursorA(null, cast(LPCSTR)cast(void*)IDC_ARROW);
	wc.hbrBackground = null;
	wc.lpszMenuName = null;
	wc.lpszClassName = "OpenGL".ptr;

	if (!RegisterClassA(&wc)) {
		throw new Exception("failed to register window class");
	}


	dwExStyle = WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;
	dwStyle = WS_OVERLAPPEDWINDOW;

	// Adjust window to true requested size.
	AdjustWindowRectEx(&windowRect, dwStyle, FALSE, dwExStyle);

	// Create the window.
	wgl.hWnd = CreateWindowExA(
		dwExStyle,
		"OpenGL".ptr,
		"Charge".ptr,
		dwStyle | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
		0, 0,
		windowRect.right - windowRect.left,
		windowRect.bottom - windowRect.top,
		null, null,
		wgl.hInstance,
		null);
	if (wgl.hWnd is null) {
		wgl.log("error: Couldn't create window");
	}

	pfd: PIXELFORMATDESCRIPTOR;
	memset(cast(void*)&pfd, 0, typeid(PIXELFORMATDESCRIPTOR).size);
	pfd.nSize = cast(WORD)typeid(PIXELFORMATDESCRIPTOR).size;  // Size of this Pixel Format Descriptor.
	pfd.nVersion = 1;
	// Must be an OpenGL window that supports double buffering.
	pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
	pfd.iPixelType = PFD_TYPE_RGBA;
	pfd.cAlphaBits = 8;
	pfd.cColorBits = 24;  // Not including alpha.
	pfd.cDepthBits = 24;  // Z-Buffer depth.
	pfd.cStencilBits = 8;

	wgl.hDC = GetDC(wgl.hWnd);
	if (wgl.hDC is null) {
		wgl.log("error: Can't get gl device context");
		return false;
	}

	pixelFormat = ChoosePixelFormat(wgl.hDC, &pfd);
	if (pixelFormat == 0) {
		wgl.log("error: Can't find suitable pixel format");
		return false;
	}

	if (!SetPixelFormat(wgl.hDC, pixelFormat, &pfd)) {
		wgl.log("error: Can't set pixel format");
		return false;
	}

	wgl.hRC = wglCreateContext(wgl.hDC);
	if (wgl.hRC is null) {
		wgl.log("error: Can't create gl rendering context");
		return false;
	}

	if (!wglMakeCurrent(wgl.hDC, wgl.hRC)) {
		wgl.log("error: Can't activate gl rendering context");
		return false;
	}

	wgl.opengl32 = LoadLibraryA(watt.toStringz("opengl32.dll"));
	if (wgl.opengl32 is null) {
		wgl.log("error: Couldn't get reference to opengl32.dll");
		return false;
	}

	retval := gladLoadGL(wgl.loadFunc);
	if (!retval) {
		wgl.log("error: Couldn't load OpenGL functions");
		return false;
	}

	ShowWindow(wgl.hWnd, SW_SHOW);
	version (none) {
		SetForegroundWindow(wgl.hWnd);
		SetFocus(wgl.hWnd);  // Keyboard focus.
	}

	// Setup the gfx sub-system.
	runDetection();
	printDetection();

	return true;
}

//! Correctly kill the window.
fn finiWGL(ref wgl: WGL)
{
	if (wgl.hRC !is null) {
		// Release the rendering context, if we have one.
		if (!wglMakeCurrent(null, null)) {
			MessageBoxA(null, "Release of DC and RC failed.".ptr,
				"SHUTDOWN ERROR".ptr, MB_OK | MB_ICONINFORMATION);
		}
		if (!wglDeleteContext(wgl.hRC)) {
			MessageBoxA(null, "Release of rendering context failed.".ptr,
				"SHUTDOWN ERROR".ptr, MB_OK | MB_ICONINFORMATION);
		}
		wgl.hRC = null;
	}

	// Release the DC.
	if (wgl.hDC !is null && !ReleaseDC(wgl.hWnd, wgl.hDC)) {
		MessageBoxA(null, "Release Device Context Failed.".ptr,
			"SHUTDOWN ERROR".ptr, MB_OK | MB_ICONINFORMATION);
	}

	// Destroy the window.
	if (wgl.hWnd !is null && !DestroyWindow(wgl.hWnd)) {
		MessageBoxA(null, "Could not release hWnd.".ptr,
			"SHUTDOWN ERROR".ptr, MB_OK | MB_ICONINFORMATION);
	}

	// Unregister the window class.
	if (!UnregisterClassA("OpenGL", wgl.hInstance)) {
		MessageBoxA(null, "Could not unregister window class.".ptr,
			"SHUTDOWN ERROR".ptr, MB_OK | MB_ICONINFORMATION);
	}
}

fn pollEvents(ref wgl: WGL, ref running: bool)
{
	msg: MSG;

	while (PeekMessageA(&msg, wgl.hWnd, 0, 0, PM_REMOVE) != 0) {
		if (msg.message != WM_QUIT) {
			TranslateMessage(&msg);
			DispatchMessageA(&msg);
		} else {
			wgl.log("Got WM_QUIT");
			running = false;
		}
	}
}


private:

extern(Windows) fn wndProcWGL(hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) LRESULT
{
	// This function is fairly cargo culted from win32.volt and needs improvement.

	switch (uMsg) {
	case WM_PAINT:
		// To stop receiving WM_PAINT message
		ValidateRect(hWnd, null);

		return null;
	case WM_ERASEBKGND:
		return cast(LRESULT)1;
	case WM_SIZE:
		// Just keeping track
		t := DefaultTarget.opCall();
		t.width = LOWORD(cast(DWORD)lParam);
		t.height = HIWORD(cast(DWORD)lParam);

		break;
	case WM_UNICHAR:
		if (cast(DWORD)wParam == UNICODE_NOCHAR) {
			return cast(LRESULT)1;
		}
		goto case;
	case WM_CHAR:
		break;
	case WM_CLOSE:
		PostQuitMessage(0);
		return null;
	case WM_MOUSEMOVE:
		return null;
	case WM_SYSCOMMAND:
	case WM_KEYDOWN:
	case WM_SYSKEYDOWN:
	case WM_KEYUP:
	case WM_SYSKEYUP:
	case WM_LBUTTONDOWN:
	case WM_RBUTTONDOWN:
	case WM_MBUTTONDOWN:
	case WM_XBUTTONDOWN:
	case WM_LBUTTONUP:
	case WM_RBUTTONUP:
	case WM_MBUTTONUP:
	case WM_XBUTTONUP:
	default: break;
	}

	return DefWindowProcA(hWnd, uMsg, wParam, lParam);
}

extern (Windows) fn ValidateRect(hWnd: HWND, lpRect: const RECT*) BOOL;
