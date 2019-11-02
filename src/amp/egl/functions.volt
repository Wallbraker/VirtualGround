// Copyright 2017-2019, The Khronos Group Inc.
// SPDX-License-Identifier: Apache-2.0
/*!
 * @brief EGL functions.
 */
module amp.egl.functions;

import amp.egl.types;


extern(C) @loadDynamic:


// Version 1.0

fn eglChooseConfig(dpy: EGLDisplay, attrib_list: const(EGLint)*, configs: EGLConfig*, config_size: EGLint, num_config: EGLint*) EGLBoolean;
fn eglCopyBuffers(dpy: EGLDisplay, surface: EGLSurface, target: EGLNativePixmapType) EGLBoolean;
fn eglCreateContext(dpy: EGLDisplay, config: EGLConfig, share_context: EGLContext, attrib_list: const(EGLint)*) EGLContext;
fn eglCreatePbufferSurface(dpy: EGLDisplay, config: EGLConfig, attrib_list: const(EGLint)*) EGLSurface;
fn eglCreatePixmapSurface(dpy: EGLDisplay, config: EGLConfig, pixmap: EGLNativePixmapType, attrib_list: const(EGLint)*) EGLSurface;
fn eglCreateWindowSurface(dpy: EGLDisplay, config: EGLConfig, win: EGLNativeWindowType, attrib_list: const(EGLint)*) EGLSurface;
fn eglDestroyContext(dpy: EGLDisplay, ctx: EGLContext) EGLBoolean;
fn eglDestroySurface(dpy: EGLDisplay, surface: EGLSurface) EGLBoolean;
fn eglGetConfigAttrib(dpy: EGLDisplay, config: EGLConfig, attribute: EGLint, value: EGLint*) EGLBoolean;
fn eglGetConfigs(dpy: EGLDisplay, configs: EGLConfig*, config_size: EGLint, num_config: EGLint*) EGLBoolean;
fn eglGetCurrentDisplay() EGLDisplay;
fn eglGetCurrentSurface(readdraw: EGLint) EGLSurface;
fn eglGetDisplay(display_id: EGLNativeDisplayType) EGLDisplay;
fn eglGetError() EGLint;
fn eglGetProcAddress(procname: const(char)*) __eglMustCastToProperFunctionPointerType;
fn eglInitialize(dpy: EGLDisplay, major: EGLint*, minor: EGLint*) EGLBoolean;
fn eglMakeCurrent(dpy: EGLDisplay, draw: EGLSurface, read: EGLSurface, ctx: EGLContext) EGLBoolean;
fn eglQueryContext(dpy: EGLDisplay, ctx: EGLContext, attribute: EGLint, value: EGLint*) EGLBoolean;
fn eglQueryString(dpy: EGLDisplay, name: EGLint) const(char)*;
fn eglQuerySurface(dpy: EGLDisplay, surface: EGLSurface, attribute: EGLint, value: EGLint*) EGLBoolean;
fn eglSwapBuffers(dpy: EGLDisplay, surface: EGLSurface) EGLBoolean;
fn eglTerminate(dpy: EGLDisplay) EGLBoolean;
fn eglWaitGL() EGLBoolean;
fn eglWaitNative(engine: EGLint) EGLBoolean;


// Version 1.1

fn eglBindTexImage(dpy: EGLDisplay, surface: EGLSurface, buffer: EGLint) EGLBoolean;
fn eglReleaseTexImage(dpy: EGLDisplay, surface: EGLSurface, buffer: EGLint) EGLBoolean;
fn eglSurfaceAttrib(dpy: EGLDisplay, surface: EGLSurface, attribute: EGLint, value: EGLint) EGLBoolean;
fn eglSwapInterval(dpy: EGLDisplay, interval: EGLint) EGLBoolean;


// Version 1.2

fn eglBindAPI(api: EGLenum) EGLBoolean;
fn eglQueryAPI() EGLenum;
fn eglCreatePbufferFromClientBuffer(dpy: EGLDisplay, buftype: EGLenum, buffer: EGLClientBuffer, config: EGLConfig, attrib_list: const(EGLint)*) EGLSurface;
fn eglReleaseThread() EGLBoolean;
fn eglWaitClient() EGLBoolean;


// Version 1.4

fn eglGetCurrentContext() EGLContext;


// Version 1.5

fn eglCreateSync(dpy: EGLDisplay, type: EGLenum, attrib_list: const(EGLAttrib)*) EGLSync;
fn eglDestroySync(dpy: EGLDisplay, sync: EGLSync) EGLBoolean;
fn eglClientWaitSync(dpy: EGLDisplay, sync: EGLSync, flags: EGLint, timeout: EGLTime) EGLint;
fn eglGetSyncAttrib(dpy: EGLDisplay, sync: EGLSync, attribute: EGLint, value: EGLAttrib*) EGLBoolean;
fn eglCreateImage(dpy: EGLDisplay, ctx: EGLContext, target: EGLenum, buffer: EGLClientBuffer, attrib_list: const(EGLAttrib)*) EGLImage;
fn eglDestroyImage(dpy: EGLDisplay, image: EGLImage) EGLBoolean;
fn eglGetPlatformDisplay(platform: EGLenum, native_display: void*, attrib_list: const(EGLAttrib)*) EGLDisplay;
fn eglCreatePlatformWindowSurface(dpy: EGLDisplay, config: EGLConfig, native_window: void*, attrib_list: const(EGLAttrib)*) EGLSurface;
fn eglCreatePlatformPixmapSurface(dpy: EGLDisplay, config: EGLConfig, native_pixmap: void*, attrib_list: const(EGLAttrib)*) EGLSurface;
fn eglWaitSync(dpy: EGLDisplay, sync: EGLSync, flags: EGLint) EGLBoolean;
