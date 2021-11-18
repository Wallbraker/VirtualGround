// Copyright 2017-2021, The Khronos Group Inc.
// SPDX-License-Identifier: Apache-2.0
/*!
 * @brief EGL enuns and values.
 */
module amp.egl.enums;

import amp.egl.types;


// Version 1.0

enum EGL_ALPHA_SIZE : i32                    = 0x3021;
enum EGL_BAD_ACCESS : i32                    = 0x3002;
enum EGL_BAD_ALLOC : i32                     = 0x3003;
enum EGL_BAD_ATTRIBUTE : i32                 = 0x3004;
enum EGL_BAD_CONFIG : i32                    = 0x3005;
enum EGL_BAD_CONTEXT : i32                   = 0x3006;
enum EGL_BAD_CURRENT_SURFACE : i32           = 0x3007;
enum EGL_BAD_DISPLAY : i32                   = 0x3008;
enum EGL_BAD_MATCH : i32                     = 0x3009;
enum EGL_BAD_NATIVE_PIXMAP : i32             = 0x300A;
enum EGL_BAD_NATIVE_WINDOW : i32             = 0x300B;
enum EGL_BAD_PARAMETER : i32                 = 0x300C;
enum EGL_BAD_SURFACE : i32                   = 0x300D;
enum EGL_BLUE_SIZE : i32                     = 0x3022;
enum EGL_BUFFER_SIZE : i32                   = 0x3020;
enum EGL_CONFIG_CAVEAT : i32                 = 0x3027;
enum EGL_CONFIG_ID : i32                     = 0x3028;
enum EGL_CORE_NATIVE_ENGINE : i32            = 0x305B;
enum EGL_DEPTH_SIZE : i32                    = 0x3025;
enum EGL_DONT_CARE : i32                     = -1;
enum EGL_DRAW : i32                          = 0x3059;
enum EGL_EXTENSIONS : i32                    = 0x3055;
enum EGL_FALSE : i32                         = 0;
enum EGL_GREEN_SIZE : i32                    = 0x3023;
enum EGL_HEIGHT : i32                        = 0x3056;
enum EGL_LARGEST_PBUFFER : i32               = 0x3058;
enum EGL_LEVEL : i32                         = 0x3029;
enum EGL_MAX_PBUFFER_HEIGHT : i32            = 0x302A;
enum EGL_MAX_PBUFFER_PIXELS : i32            = 0x302B;
enum EGL_MAX_PBUFFER_WIDTH : i32             = 0x302C;
enum EGL_NATIVE_RENDERABLE : i32             = 0x302D;
enum EGL_NATIVE_VISUAL_ID : i32              = 0x302E;
enum EGL_NATIVE_VISUAL_TYPE : i32            = 0x302F;
enum EGL_NONE : i32                          = 0x3038;
enum EGL_NON_CONFORMANT_CONFIG : i32         = 0x3051;
enum EGL_NOT_INITIALIZED : i32               = 0x3001;
enum EGL_NO_CONTEXT : EGLContext             = null;
enum EGL_NO_DISPLAY : EGLDisplay             = null;
enum EGL_NO_SURFACE : EGLSurface             = null;
enum EGL_PBUFFER_BIT : i32                   = 0x0001;
enum EGL_PIXMAP_BIT : i32                    = 0x0002;
enum EGL_READ : i32                          = 0x305A;
enum EGL_RED_SIZE : i32                      = 0x3024;
enum EGL_SAMPLES : i32                       = 0x3031;
enum EGL_SAMPLE_BUFFERS : i32                = 0x3032;
enum EGL_SLOW_CONFIG : i32                   = 0x3050;
enum EGL_STENCIL_SIZE : i32                  = 0x3026;
enum EGL_SUCCESS : i32                       = 0x3000;
enum EGL_SURFACE_TYPE : i32                  = 0x3033;
enum EGL_TRANSPARENT_BLUE_VALUE : i32        = 0x3035;
enum EGL_TRANSPARENT_GREEN_VALUE : i32       = 0x3036;
enum EGL_TRANSPARENT_RED_VALUE : i32         = 0x3037;
enum EGL_TRANSPARENT_RGB : i32               = 0x3052;
enum EGL_TRANSPARENT_TYPE : i32              = 0x3034;
enum EGL_TRUE : i32                          = 1;
enum EGL_VENDOR : i32                        = 0x3053;
enum EGL_VERSION : i32                       = 0x3054;
enum EGL_WIDTH : i32                         = 0x3057;
enum EGL_WINDOW_BIT : i32                    = 0x0004;


// Version 1.1

enum EGL_BACK_BUFFER : i32                   = 0x3084;
enum EGL_BIND_TO_TEXTURE_RGB : i32           = 0x3039;
enum EGL_BIND_TO_TEXTURE_RGBA : i32          = 0x303A;
enum EGL_CONTEXT_LOST : i32                  = 0x300E;
enum EGL_MIN_SWAP_INTERVAL : i32             = 0x303B;
enum EGL_MAX_SWAP_INTERVAL : i32             = 0x303C;
enum EGL_MIPMAP_TEXTURE : i32                = 0x3082;
enum EGL_MIPMAP_LEVEL : i32                  = 0x3083;
enum EGL_NO_TEXTURE : i32                    = 0x305C;
enum EGL_TEXTURE_2D : i32                    = 0x305F;
enum EGL_TEXTURE_FORMAT : i32                = 0x3080;
enum EGL_TEXTURE_RGB : i32                   = 0x305D;
enum EGL_TEXTURE_RGBA : i32                  = 0x305E;
enum EGL_TEXTURE_TARGET : i32                = 0x3081;


// Version 1.2

enum EGL_ALPHA_FORMAT : i32                 = 0x3088;
enum EGL_ALPHA_FORMAT_NONPRE : i32          = 0x308B;
enum EGL_ALPHA_FORMAT_PRE : i32             = 0x308C;
enum EGL_ALPHA_MASK_SIZE : i32              = 0x303E;
enum EGL_BUFFER_PRESERVED : i32             = 0x3094;
enum EGL_BUFFER_DESTROYED : i32             = 0x3095;
enum EGL_CLIENT_APIS : i32                  = 0x308D;
enum EGL_COLORSPACE : i32                   = 0x3087;
enum EGL_COLORSPACE_sRGB : i32              = 0x3089;
enum EGL_COLORSPACE_LINEAR : i32            = 0x308A;
enum EGL_COLOR_BUFFER_TYPE : i32            = 0x303F;
enum EGL_CONTEXT_CLIENT_TYPE : i32          = 0x3097;
enum EGL_DISPLAY_SCALING : i32              = 10000;
enum EGL_HORIZONTAL_RESOLUTION : i32        = 0x3090;
enum EGL_LUMINANCE_BUFFER : i32             = 0x308F;
enum EGL_LUMINANCE_SIZE : i32               = 0x303D;
enum EGL_OPENGL_ES_BIT : i32                = 0x0001;
enum EGL_OPENVG_BIT : i32                   = 0x0002;
enum EGL_OPENGL_ES_API : i32                = 0x30A0;
enum EGL_OPENVG_API : i32                   = 0x30A1;
enum EGL_OPENVG_IMAGE : i32                 = 0x3096;
enum EGL_PIXEL_ASPECT_RATIO : i32           = 0x3092;
enum EGL_RENDERABLE_TYPE : i32              = 0x3040;
enum EGL_RENDER_BUFFER : i32                = 0x3086;
enum EGL_RGB_BUFFER : i32                   = 0x308E;
enum EGL_SINGLE_BUFFER : i32                = 0x3085;
enum EGL_SWAP_BEHAVIOR : i32                = 0x3093;
enum EGL_UNKNOWN : i32                      = -1;
enum EGL_VERTICAL_RESOLUTION : i32          = 0x3091;


// Version 1.3

enum EGL_CONFORMANT : i32                    = 0x3042;
enum EGL_CONTEXT_CLIENT_VERSION : i32        = 0x3098;
enum EGL_MATCH_NATIVE_PIXMAP : i32           = 0x3041;
enum EGL_OPENGL_ES2_BIT : i32                = 0x0004;
enum EGL_VG_ALPHA_FORMAT : i32               = 0x3088;
enum EGL_VG_ALPHA_FORMAT_NONPRE : i32        = 0x308B;
enum EGL_VG_ALPHA_FORMAT_PRE : i32           = 0x308C;
enum EGL_VG_ALPHA_FORMAT_PRE_BIT : i32       = 0x0040;
enum EGL_VG_COLORSPACE : i32                 = 0x3087;
enum EGL_VG_COLORSPACE_sRGB : i32            = 0x3089;
enum EGL_VG_COLORSPACE_LINEAR : i32          = 0x308A;
enum EGL_VG_COLORSPACE_LINEAR_BIT : i32      = 0x0020;


// Version 1.4

enum EGL_DEFAULT_DISPLAY : EGLDisplay        = null;
enum EGL_MULTISAMPLE_RESOLVE_BOX_BIT : i32   = 0x0200;
enum EGL_MULTISAMPLE_RESOLVE : i32           = 0x3099;
enum EGL_MULTISAMPLE_RESOLVE_DEFAULT : i32   = 0x309A;
enum EGL_MULTISAMPLE_RESOLVE_BOX : i32       = 0x309B;
enum EGL_OPENGL_API : i32                    = 0x30A2;
enum EGL_OPENGL_BIT : i32                    = 0x0008;
enum EGL_SWAP_BEHAVIOR_PRESERVED_BIT : i32   = 0x0400;


// Version 1.5

enum EGL_CONTEXT_MAJOR_VERSION : i32          = 0x3098;
enum EGL_CONTEXT_MINOR_VERSION : i32          = 0x30FB;
enum EGL_CONTEXT_OPENGL_PROFILE_MASK : i32    = 0x30FD;
enum EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY : i32  = 0x31BD;
enum EGL_NO_RESET_NOTIFICATION : i32          = 0x31BE;
enum EGL_LOSE_CONTEXT_ON_RESET : i32          = 0x31BF;
enum EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT : i32  = 0x00000001;
enum EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT : i32  = 0x00000002;
enum EGL_CONTEXT_OPENGL_DEBUG : i32           = 0x31B0;
enum EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE : i32  = 0x31B1;
enum EGL_CONTEXT_OPENGL_ROBUST_ACCESS : i32   = 0x31B2;
enum EGL_OPENGL_ES3_BIT : i32                 = 0x00000040;
enum EGL_CL_EVENT_HANDLE : i32                = 0x309C;
enum EGL_SYNC_CL_EVENT : i32                  = 0x30FE;
enum EGL_SYNC_CL_EVENT_COMPLETE : i32         = 0x30FF;
enum EGL_SYNC_PRIOR_COMMANDS_COMPLETE : i32   = 0x30F0;
enum EGL_SYNC_TYPE : i32                      = 0x30F7;
enum EGL_SYNC_STATUS : i32                    = 0x30F1;
enum EGL_SYNC_CONDITION : i32                 = 0x30F8;
enum EGL_SIGNALED : i32                       = 0x30F2;
enum EGL_UNSIGNALED : i32                     = 0x30F3;
enum EGL_SYNC_FLUSH_COMMANDS_BIT : i32        = 0x0001;
enum EGL_FOREVER : EGLTime                    = 0xFFFFFFFFFFFFFFFF_u64;
enum EGL_TIMEOUT_EXPIRED : i32                = 0x30F5;
enum EGL_CONDITION_SATISFIED : i32            = 0x30F6;
enum EGL_NO_SYNC : EGLSync                    = null;
enum EGL_SYNC_FENCE : i32                     = 0x30F9;
enum EGL_GL_COLORSPACE : i32                  = 0x309D;
enum EGL_GL_COLORSPACE_SRGB : i32             = 0x3089;
enum EGL_GL_COLORSPACE_LINEAR : i32           = 0x308A;
enum EGL_GL_RENDERBUFFER : i32                = 0x30B9;
enum EGL_GL_TEXTURE_2D : i32                  = 0x30B1;
enum EGL_GL_TEXTURE_LEVEL : i32               = 0x30BC;
enum EGL_GL_TEXTURE_3D : i32                  = 0x30B2;
enum EGL_GL_TEXTURE_ZOFFSET : i32             = 0x30BD;
enum EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_X : i32 = 0x30B3;
enum EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_X : i32 = 0x30B4;
enum EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Y : i32 = 0x30B5;
enum EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Y : i32 = 0x30B6;
enum EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Z : i32 = 0x30B7;
enum EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z : i32 = 0x30B8;
enum EGL_IMAGE_PRESERVED : i32                = 0x30D2;
enum EGL_NO_IMAGE : EGLImage                  = null;


// EGL_KHR_create_context

enum EGL_CONTEXT_MAJOR_VERSION_KHR : i32                      = 0x3098;
enum EGL_CONTEXT_MINOR_VERSION_KHR : i32                      = 0x30FB;
enum EGL_CONTEXT_FLAGS_KHR : i32                              = 0x30FC;
enum EGL_CONTEXT_OPENGL_PROFILE_MASK_KHR : i32                = 0x30FD;
enum EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY_KHR : i32 = 0x31BD;
enum EGL_NO_RESET_NOTIFICATION_KHR : i32                      = 0x31BE;
enum EGL_LOSE_CONTEXT_ON_RESET_KHR : i32                      = 0x31BF;
enum EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR : i32                   = 0x00000001;
enum EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE_BIT_KHR : i32      = 0x00000002;
enum EGL_CONTEXT_OPENGL_ROBUST_ACCESS_BIT_KHR : i32           = 0x00000004;
enum EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT_KHR : i32            = 0x00000001;
enum EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT_KHR : i32   = 0x00000002;
enum EGL_OPENGL_ES3_BIT_KHR : i32                             = 0x00000040;


// EGL_KHR_no_config_context

enum EGL_NO_CONFIG_KHR : EGLConfig                            = null;


// EGL_EXT_device_base

enum EGL_NO_DEVICE_EXT : EGLDeviceEXT                         = null;
enum EGL_BAD_DEVICE_EXT : i32                                 = 0x322B;
enum EGL_DEVICE_EXT : i32                                     = 0x322C;


// EGL_EXT_platform_device

enum EGL_PLATFORM_DEVICE_EXT : i32                            = 0x313F;


// MESA_platform_surfaceless

enum EGL_PLATFORM_SURFACELESS_MESA : i32                      = 0x31DD;
