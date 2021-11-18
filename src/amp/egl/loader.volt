// Copyright 2019-2021, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or Apache-2.0
/*!
 * @brief  Loader functions.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module amp.egl.loader;

import amp.egl.enums;
import amp.egl.types;
import amp.egl.functions;
import amp.egl.exts;
import watt = [watt.library, watt.conv];
import watt.text.string : indexOf;


fn loadEGL() watt.Library
{
	return watt.Library.load("libEGL.so.1");
}

fn loadClientExtensions() bool
{
	const(char) *c_str = eglQueryString(EGL_NO_DISPLAY, EGL_EXTENSIONS);
	if (c_str is null) {
		return false;
	}

	str := watt.toString(c_str);
	EGL_EXT_client_extensions = str.indexOf("EGL_EXT_client_extensions") >= 0;
	EGL_EXT_platform_base = str.indexOf("EGL_EXT_platform_base") >= 0;
	EGL_EXT_platform_device = str.indexOf("EGL_EXT_platform_device") >= 0;
	EGL_EXT_device_base = str.indexOf("EGL_EXT_device_base") >= 0;
	EGL_EXT_device_query = str.indexOf("EGL_EXT_device_query") >= 0;
	EGL_EXT_device_enumeration = str.indexOf("EGL_EXT_device_enumeration") >= 0;
	EGL_MESA_platform_surfaceless = str.indexOf("EGL_MESA_platform_surfaceless") >= 0;

	return true;
}

fn loadExtensions(dpy: EGLDisplay) bool
{
	const(char) *c_str = eglQueryString(dpy, EGL_EXTENSIONS);
	if (c_str is null) {
		return false;
	}

	str := watt.toString(c_str);
	EGL_KHR_create_context = str.indexOf("EGL_KHR_create_context") >= 0;
	EGL_KHR_no_config_context = str.indexOf("EGL_KHR_no_config_context") >= 0;

	return true;
}

fn loadFuncs(l: dg(string) void*) bool
{
	eglGetProcAddress = cast(typeof(eglGetProcAddress))l("eglGetProcAddress");

	eglChooseConfig = cast(typeof(eglChooseConfig))eglGetProcAddress("eglChooseConfig");
	eglCopyBuffers = cast(typeof(eglCopyBuffers))eglGetProcAddress("eglCopyBuffers");
	eglCreateContext = cast(typeof(eglCreateContext))eglGetProcAddress("eglCreateContext");
	eglCreatePbufferSurface = cast(typeof(eglCreatePbufferSurface))eglGetProcAddress("eglCreatePbufferSurface");
	eglCreatePixmapSurface = cast(typeof(eglCreatePixmapSurface))eglGetProcAddress("eglCreatePixmapSurface");
	eglCreateWindowSurface = cast(typeof(eglCreateWindowSurface))eglGetProcAddress("eglCreateWindowSurface");
	eglDestroyContext = cast(typeof(eglDestroyContext))eglGetProcAddress("eglDestroyContext");
	eglDestroySurface = cast(typeof(eglDestroySurface))eglGetProcAddress("eglDestroySurface");
	eglGetConfigAttrib = cast(typeof(eglGetConfigAttrib))eglGetProcAddress("eglGetConfigAttrib");
	eglGetConfigs = cast(typeof(eglGetConfigs))eglGetProcAddress("eglGetConfigs");
	eglGetCurrentDisplay = cast(typeof(eglGetCurrentDisplay))eglGetProcAddress("eglGetCurrentDisplay");
	eglGetCurrentSurface = cast(typeof(eglGetCurrentSurface))eglGetProcAddress("eglGetCurrentSurface");
	eglGetDisplay = cast(typeof(eglGetDisplay))eglGetProcAddress("eglGetDisplay");
	eglGetError = cast(typeof(eglGetError))eglGetProcAddress("eglGetError");
	eglGetProcAddress = cast(typeof(eglGetProcAddress))eglGetProcAddress("eglGetProcAddress");
	eglInitialize = cast(typeof(eglInitialize))eglGetProcAddress("eglInitialize");
	eglMakeCurrent = cast(typeof(eglMakeCurrent))eglGetProcAddress("eglMakeCurrent");
	eglQueryContext = cast(typeof(eglQueryContext))eglGetProcAddress("eglQueryContext");
	eglQueryString = cast(typeof(eglQueryString))eglGetProcAddress("eglQueryString");
	eglQuerySurface = cast(typeof(eglQuerySurface))eglGetProcAddress("eglQuerySurface");
	eglSwapBuffers = cast(typeof(eglSwapBuffers))eglGetProcAddress("eglSwapBuffers");
	eglTerminate = cast(typeof(eglTerminate))eglGetProcAddress("eglTerminate");
	eglWaitGL = cast(typeof(eglWaitGL))eglGetProcAddress("eglWaitGL");
	eglWaitNative = cast(typeof(eglWaitNative))eglGetProcAddress("eglWaitNative");
	eglBindTexImage = cast(typeof(eglBindTexImage))eglGetProcAddress("eglBindTexImage");
	eglReleaseTexImage = cast(typeof(eglReleaseTexImage))eglGetProcAddress("eglReleaseTexImage");
	eglSurfaceAttrib = cast(typeof(eglSurfaceAttrib))eglGetProcAddress("eglSurfaceAttrib");
	eglSwapInterval = cast(typeof(eglSwapInterval))eglGetProcAddress("eglSwapInterval");
	eglBindAPI = cast(typeof(eglBindAPI))eglGetProcAddress("eglBindAPI");
	eglQueryAPI = cast(typeof(eglQueryAPI))eglGetProcAddress("eglQueryAPI");
	eglCreatePbufferFromClientBuffer = cast(typeof(eglCreatePbufferFromClientBuffer))eglGetProcAddress("eglCreatePbufferFromClientBuffer");
	eglReleaseThread = cast(typeof(eglReleaseThread))eglGetProcAddress("eglReleaseThread");
	eglWaitClient = cast(typeof(eglWaitClient))eglGetProcAddress("eglWaitClient");
	eglGetCurrentContext = cast(typeof(eglGetCurrentContext))eglGetProcAddress("eglGetCurrentContext");
	eglCreateSync = cast(typeof(eglCreateSync))eglGetProcAddress("eglCreateSync");
	eglDestroySync = cast(typeof(eglDestroySync))eglGetProcAddress("eglDestroySync");
	eglClientWaitSync = cast(typeof(eglClientWaitSync))eglGetProcAddress("eglClientWaitSync");
	eglGetSyncAttrib = cast(typeof(eglGetSyncAttrib))eglGetProcAddress("eglGetSyncAttrib");
	eglCreateImage = cast(typeof(eglCreateImage))eglGetProcAddress("eglCreateImage");
	eglDestroyImage = cast(typeof(eglDestroyImage))eglGetProcAddress("eglDestroyImage");
	eglGetPlatformDisplay = cast(typeof(eglGetPlatformDisplay))eglGetProcAddress("eglGetPlatformDisplay");
	eglCreatePlatformWindowSurface = cast(typeof(eglCreatePlatformWindowSurface))eglGetProcAddress("eglCreatePlatformWindowSurface");
	eglCreatePlatformPixmapSurface = cast(typeof(eglCreatePlatformPixmapSurface))eglGetProcAddress("eglCreatePlatformPixmapSurface");
	eglWaitSync = cast(typeof(eglWaitSync))eglGetProcAddress("eglWaitSync");

	eglGetPlatformDisplayEXT = cast(typeof(eglGetPlatformDisplayEXT))eglGetProcAddress("eglGetPlatformDisplayEXT");
	eglCreatePlatformWindowSurfaceEXT = cast(typeof(eglCreatePlatformWindowSurfaceEXT))eglGetProcAddress("eglCreatePlatformWindowSurfaceEXT");
	eglCreatePlatformPixmapSurfaceEXT = cast(typeof(eglCreatePlatformPixmapSurfaceEXT))eglGetProcAddress("eglCreatePlatformPixmapSurfaceEXT");

	eglQueryDeviceAttribEXT = cast(typeof(eglQueryDeviceAttribEXT))eglGetProcAddress("eglQueryDeviceAttribEXT");
	eglQueryDeviceStringEXT = cast(typeof(eglQueryDeviceStringEXT))eglGetProcAddress("eglQueryDeviceStringEXT");
	eglQueryDevicesEXT = cast(typeof(eglQueryDevicesEXT))eglGetProcAddress("eglQueryDevicesEXT");
	eglQueryDisplayAttribEXT = cast(typeof(eglQueryDisplayAttribEXT))eglGetProcAddress("eglQueryDisplayAttribEXT");

	return eglGetProcAddress !is null && eglWaitSync !is null;
}
