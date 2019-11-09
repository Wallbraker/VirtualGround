// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  EGL functions.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.egl;

import watt = [watt.conv];

import amp.egl;
import amp.egl.loader;
import lib.gl.gl33;
import lib.gl.loader;

import ground.program;


fn initEGL(p: Program) bool
{
	p.egl.lib = loadEGL();
	if (p.egl.lib is null) {
		p.log("Failed to load EGL!");
		return false;
	}

	if (!loadFuncs(p.egl.lib.symbol)) {
		p.log("Failed to load EGL functions!");
		return false;
	}

	p.egl.dpy = eglGetDisplay(null);
	if (p.egl.dpy is null) {
		p.log("Could not create EGLDisplay!");
		return false;
	}

	if (!eglInitialize(p.egl.dpy, null, null)) {
		p.log("eglInitialize failed!");
		return false;	
	}

	attr: const(EGLint)[] = [
		EGL_RENDERABLE_TYPE,
		EGL_OPENGL_BIT,
		EGL_NONE,
	];

	num_config: EGLint;
	if (!eglChooseConfig(p.egl.dpy,
	                     attr.ptr,
	                     &p.egl.cfg,
	                     1,
	                     &num_config)) {
		p.log("eglChooseConfig failed!");
		return false;
	}

	if (num_config < 1) {
		p.log("We didn't get any config!");
		return false;
	}

	if (!eglBindAPI(EGL_OPENGL_API)) {
		p.log("Failed bind OpenGL");
		return false;
	}

	ctx_attr: const(EGLint)[] = [
		EGL_CONTEXT_MAJOR_VERSION, 4,
		EGL_CONTEXT_MINOR_VERSION, 5,
		EGL_CONTEXT_OPENGL_PROFILE_MASK_KHR,
		EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR,
		EGL_CONTEXT_OPENGL_PROFILE_MASK_KHR,
		EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT_KHR,
		EGL_NONE,
	];

	p.egl.ctx = eglCreateContext(p.egl.dpy, p.egl.cfg, EGL_NO_CONTEXT, ctx_attr.ptr);
	if (p.egl.ctx is EGL_NO_CONTEXT) {
		p.log("We didn't get a context!");
		return false;
	}

	if (!eglMakeCurrent(p.egl.dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, p.egl.ctx)) {
		p.log("Make current failed!");
		return false;
	}

	fn load(str: string) void*
	{
		return cast(void*)eglGetProcAddress(str.ptr);
	}

	if (!gladLoadGL(load)) {
		p.log("Failed to load OpenGL functions!");
		return false;
	}

	if (false) {
		p.log(new "Vendor:   ${watt.toString(cast(const(char)*)glGetString(GL_VENDOR))}");
		p.log(new "Version:  ${watt.toString(cast(const(char)*)glGetString(GL_VERSION))}");
		p.log(new "Renderer: ${watt.toString(cast(const(char)*)glGetString(GL_RENDERER))}");
	}

	return true;
}

fn finiEGL(p: Program)
{
	if (p.egl.dpy !is null) {
		return;
	}

	eglMakeCurrent(p.egl.dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

	if (p.egl.ctx !is EGL_NO_CONTEXT) {
		eglDestroyContext(p.egl.dpy, p.egl.ctx);
		p.egl.ctx = EGL_NO_CONTEXT;
	}

	if (p.egl.dpy !is null) {
		// Can't free a display.
		p.egl.dpy = null;
	}

	return;
}
