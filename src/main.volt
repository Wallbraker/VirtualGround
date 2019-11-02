// Copyright 2018-2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Main file, it all starts from here.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module main;

import c = core.c.stdlib;
import watt = [watt.library, watt.conv];

import lib.gl.loader;
import lib.gl.types;
import lib.gl.funcs;
import lib.gl.enums;

import amp.egl;
import amp.egl.loader;
import amp.openxr;
import amp.openxr.loader;

import charge.core;

import virtual_ground.program;
import virtual_ground.actions;


fn main(args: string[]) i32
{
	XrResult ret;
	p: Program = new Program();

	scope (exit) {
		finiOpenXR(p);
		finiEGL(p);
	}

	if (!initEGL(p) || !initOpenXR(p)) {
		return 1;
	}

	while (p.updateActions()) {
		frameState: XrFrameState;
		frameState.type = XrStructureType.XR_TYPE_FRAME_STATE;

		xrWaitFrame(p.session, null, &frameState);
		xrBeginFrame(p.session, null);

		endFrame: XrFrameEndInfo;
		endFrame.type = XrStructureType.XR_TYPE_FRAME_END_INFO;
		endFrame.displayTime = frameState.predictedDisplayTime;
		endFrame.environmentBlendMode = p.oxr.blendMode;

		xrEndFrame(p.session, &endFrame);
	}

	return 0;
}

fn initOpenXR(p: Program) bool
{
	return setupLoader(p) &&
	       createInstance(p) &&
	       createSession(p) &&
	       createActions(p) &&
	       createSwapchains(p) &&
	       startSession(p);
}

fn finiOpenXR(p: Program)
{
	if (p.instance !is null) {
		xrDestroyInstance(p.instance);
		p.instance = cast(XrInstance)XR_NULL_HANDLE;
	}
}

fn setupLoader(p: Program) bool
{
	p.oxr.lib = loadLoader();
	if (p.oxr.lib is null) {
		p.log("Failed to load OpenXR runtime!");
		return false;
	}

	if (!loadRuntimeFuncs(p.oxr.lib.symbol)) {
		p.log("Failed to load OpenXR runtime functions!");
		return false;
	}

	return true;
}

fn createInstance(p: Program) bool
{
	XrResult ret;

	extProps: XrExtensionProperties[];
	enumExtensionProps(out extProps);
	foreach (ref ext; extProps) {
		name := watt.toString(ext.extensionName.ptr);
		switch (name) {
		case "XR_MND_headless":
			p.XR_MND_headless = true;
			break;
		case "XR_MND_egl_enable":
			p.XR_MND_egl_enable = true;
			break;
		default:
		}
		p.log(new "${name}");
	}

	if (!p.XR_MND_egl_enable) {
		p.log("Doesn't have XR_MND_egl_enable! :(");
		return false;
	}

	exts: const(char)*[2] = [
		"XR_KHR_convert_timespec_time".ptr,
		"XR_MND_egl_enable".ptr,
	];

	createInfo: XrInstanceCreateInfo;
	createInfo.type = XrStructureType.XR_TYPE_INSTANCE_CREATE_INFO;
	createInfo.enabledExtensionCount = cast(u32)exts.length;
	createInfo.enabledExtensionNames = exts.ptr;
	createInfo.applicationInfo.applicationName[] = "Virtual Ground";
	createInfo.applicationInfo.applicationVersion = 1;
	createInfo.applicationInfo.engineName[] = "Charge";
	createInfo.applicationInfo.engineVersion = 0;
	createInfo.applicationInfo.apiVersion = XR_MAKE_VERSION(1, 0, 3);

	ret = xrCreateInstance(&createInfo, &p.instance);
	if (ret != XrResult.XR_SUCCESS) {
		p.log("Failed to create instance");
		return false;
	}

	// Also load functions for this instance.
	loadInstanceFunctions(p.instance);

	return true;
}

fn createSession(p: Program) bool
{
	XrResult ret;

	getInfo: XrSystemGetInfo;
	getInfo.type = XrStructureType.XR_TYPE_SYSTEM_GET_INFO;
	getInfo.formFactor = XrFormFactor.XR_FORM_FACTOR_HEAD_MOUNTED_DISPLAY;

	ret = xrGetSystem(p.instance, &getInfo, &p.systemId);
	if (ret != XrResult.XR_SUCCESS) {
		return false;
	}

	// Hard coded for now.
	p.oxr.viewConfigType = XrViewConfigurationType.XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO;

	envBlendModes: XrEnvironmentBlendMode[];
	ret = enumEnvironmentBlendModes(p, p.oxr.viewConfigType, out envBlendModes);
	if (ret != XrResult.XR_SUCCESS || envBlendModes.length <= 0) {
		return false;
	}
	p.oxr.blendMode = envBlendModes[0];

	eglInfo: XrGraphicsBindingEGLMND;
	eglInfo.type = XrStructureType.XR_TYPE_GRAPHICS_BINDING_EGL_MND;
	eglInfo.getProcAddress = eglGetProcAddress;
	eglInfo.display = p.egl.dpy;
	eglInfo.config = p.egl.cfg;
	eglInfo.context = p.egl.ctx;

	createInfo: XrSessionCreateInfo;
	createInfo.type = XrStructureType.XR_TYPE_SESSION_CREATE_INFO;
	createInfo.next = cast(void*)&eglInfo;
	createInfo.systemId = p.systemId;
	xrCreateSession(p.instance, &createInfo, &p.session);

	return true;
}

fn createSwapchains(p: Program) bool
{
	XrResult ret;

	p.oxr.viewConfigProperties.type = XrStructureType.XR_TYPE_VIEW_CONFIGURATION_PROPERTIES;
	ret = xrGetViewConfigurationProperties(p.instance, p.systemId, p.oxr.viewConfigType, &p.oxr.viewConfigProperties);
	if (ret != XrResult.XR_SUCCESS) {
		p.log("xrGetViewConfigurationProperties failed!");
		return false;
	}

	p.log(new "viewConfigProperties.fovMutable: ${cast(bool)p.oxr.viewConfigProperties.fovMutable}");

	ret = enumViewConfigurationViews(p, out p.oxr.viewConfigs);
	if (ret != XrResult.XR_SUCCESS) {
		p.log("enumViewConfigurationViews failed!");
		return false;
	}

	p.oxr.swaps = new Swapchain[](p.oxr.viewConfigs.length);

	foreach(i, ref viewConfig; p.oxr.viewConfigs) {
		swap := &p.oxr.swaps[i];
		swap.width = viewConfig.recommendedImageRectWidth;
		swap.height = viewConfig.recommendedImageRectHeight;

		swapchainCreateInfo: XrSwapchainCreateInfo;
		swapchainCreateInfo.type = XrStructureType.XR_TYPE_SWAPCHAIN_CREATE_INFO;
		swapchainCreateInfo.arraySize = 1;
		swapchainCreateInfo.format = GL_RGBA8;
		swapchainCreateInfo.width = viewConfig.recommendedImageRectWidth;
		swapchainCreateInfo.height = viewConfig.recommendedImageRectHeight;
		swapchainCreateInfo.mipCount = 1;
		swapchainCreateInfo.faceCount = 1;
		swapchainCreateInfo.sampleCount = 1;
		swapchainCreateInfo.usageFlags = XrSwapchainUsageFlags.XR_SWAPCHAIN_USAGE_SAMPLED_BIT | XrSwapchainUsageFlags.XR_SWAPCHAIN_USAGE_COLOR_ATTACHMENT_BIT;

		ret = xrCreateSwapchain(p.session, &swapchainCreateInfo, &swap.handle);
		if (ret != XrResult.XR_SUCCESS) {
			p.log("xrCreateSwapchain failed!");
			return false;
		}

		enumSwapchainImages(p, swap.handle, out swap.textures);
	}

	return true;
}

fn startSession(p: Program) bool
{
	ret: XrResult;

	beginInfo: XrSessionBeginInfo;
	beginInfo.type = XrStructureType.XR_TYPE_SESSION_BEGIN_INFO;
	beginInfo.primaryViewConfigurationType = p.oxr.viewConfigType;
	ret = xrBeginSession(p.session, &beginInfo);

	if (ret != XrResult.XR_SUCCESS) {
		p.log("xrBeginSession failed!");
		return false;
	}

	return true;
}

fn enumExtensionProps(out outExtProps: XrExtensionProperties[]) XrResult
{
	XrResult ret;
	num: u32;

	ret = xrEnumerateInstanceExtensionProperties(null, 0, &num, null);
	if (ret != XrResult.XR_SUCCESS) {
		return ret;
	}

	extProps := new XrExtensionProperties[](num);
	foreach (ref extProp; extProps) {
		extProp.type = XrStructureType.XR_TYPE_EXTENSION_PROPERTIES;
	}

	ret = xrEnumerateInstanceExtensionProperties(null, num, &num, extProps.ptr);
	if (ret != XrResult.XR_SUCCESS) {
		return ret;
	}

	outExtProps = extProps;

	return XrResult.XR_SUCCESS;
}

fn enumEnvironmentBlendModes(p: Program, viewConfigurationType: XrViewConfigurationType, out outEnvBlendModes: XrEnvironmentBlendMode[]) XrResult
{
	XrResult ret;
	num: u32;

	ret = xrEnumerateEnvironmentBlendModes(p.instance, p.systemId, viewConfigurationType, 0, &num, null);
	if (ret != XrResult.XR_SUCCESS) {
		return ret;
	}

	envBlendModes := new XrEnvironmentBlendMode[](num);
	ret = xrEnumerateEnvironmentBlendModes(p.instance, p.systemId, viewConfigurationType, num, &num, envBlendModes.ptr);
	if (ret != XrResult.XR_SUCCESS) {
		return ret;
	}

	outEnvBlendModes = envBlendModes;

	return XrResult.XR_SUCCESS;
}

fn enumViewConfigurationViews(p: Program, out outViewConfigs: XrViewConfigurationView[]) XrResult
{
	XrResult ret;
	num: u32;

	ret = xrEnumerateViewConfigurationViews(p.instance, p.systemId, p.oxr.viewConfigType, 0, &num, null);
	if (ret != XrResult.XR_SUCCESS) {
		return ret;
	}

	viewConfigs := new XrViewConfigurationView[](num);
	foreach (ref view; viewConfigs) {
		view.type = XrStructureType.XR_TYPE_VIEW_CONFIGURATION_VIEW;
	}

	ret = xrEnumerateViewConfigurationViews(p.instance, p.systemId, p.oxr.viewConfigType, num, &num, viewConfigs.ptr);
	if (ret != XrResult.XR_SUCCESS) {
		return ret;
	}

	outViewConfigs = viewConfigs;

	return XrResult.XR_SUCCESS;
}

fn enumSwapchainImages(p: Program, handle: XrSwapchain, out outTextures: GLuint[]) XrResult
{
	XrResult ret;
	num: u32;

	ret = xrEnumerateSwapchainImages(handle, 0, &num, null);
	if (ret != XrResult.XR_SUCCESS) {
		return ret;
	}

	images := new XrSwapchainImageOpenGLKHR[](num);
	foreach (image; images) {
		image.type = XrStructureType.XR_TYPE_SWAPCHAIN_IMAGE_OPENGL_KHR;
	}

	ptr := cast(XrSwapchainImageBaseHeader*)images.ptr;
	ret = xrEnumerateSwapchainImages(handle, num, &num, ptr);
	if (ret != XrResult.XR_SUCCESS) {
		return ret;
	}

	textures := new GLuint[](num);
	foreach (i, ref texture; textures) {
		texture = images[i].image;
	}

	outTextures = textures;

	return XrResult.XR_SUCCESS;
}


/*
 *
 * EGL functions.
 *
 */

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

	p.log(new "Vendor:   ${watt.toString(cast(const(char)*)glGetString(GL_VENDOR))}");
	p.log(new "Version:  ${watt.toString(cast(const(char)*)glGetString(GL_VERSION))}");
	p.log(new "Renderer: ${watt.toString(cast(const(char)*)glGetString(GL_RENDERER))}");

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
