// Copyright 2017-2021, The Khronos Group Inc.
// SPDX-License-Identifier: Apache-2.0
/*!
 * @brief EGL types.
 */
module amp.egl.types;

import core.c.stdint : intptr_t;


// Version 1.0

alias EGLNativeDisplayType = void*;
alias EGLNativeWindowType = int;
alias EGLNativePixmapType = int;
alias EGLint = int;
alias EGLBoolean = uint;
alias EGLDisplay = void*;
alias EGLConfig = void*;
alias EGLSurface = void*;
alias EGLContext = void*;
alias __eglMustCastToProperFunctionPointerType = fn!C();


alias PFNEGLGETPROCADDRESSPROC = fn!C(const(char)*) __eglMustCastToProperFunctionPointerType;

// Version 1.2

alias EGLenum = uint;
alias EGLClientBuffer = void*;


// Version 1.5

alias EGLSync = void*;
alias EGLAttrib = intptr_t;
alias EGLTime = u64;
alias EGLImage = void*;
