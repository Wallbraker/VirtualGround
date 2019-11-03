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

import charge.core.openxr;

import virtual_ground.program;
import virtual_ground.actions;
import virtual_ground.openxr;
import virtual_ground.egl;
import virtual_ground.gfx;


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

	// Only here to integrate better with charge code.
	core := new CoreOpenXR();
	scope (exit) {
		core.close();
	}

	scene := new Scene();
	scope (exit) {
		scene.close();
	}

	while (true) {
		frameState: XrFrameState;
		frameState.type = XR_TYPE_FRAME_STATE;

		ret = xrWaitFrame(p.oxr.session, null, &frameState);
		if (ret != XR_SUCCESS) {
			p.log("xrWaitFrame failed!");
			break;
		}

		// We have a new preditcted time, get the swapchains ready.
		foreach (ref view; p.oxr.views) {
			acquireAndWaitViewImage(p, ref view);
		}

		ret = getViewLocation(p, ref frameState);
		if (ret != XR_SUCCESS) {
			// Already logged.
			break;
		}

		// Swapchains are now ready, signal that we are starting to render.
		ret = xrBeginFrame(p.oxr.session, null);
		if (ret != XR_SUCCESS) {
			p.log("xrBeginFrame failed!");
			break;
		}

		releaseInfo: XrSwapchainImageReleaseInfo;
		releaseInfo.type = XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO;

		layerViews: XrCompositionLayerProjectionView[2];

		// This is where we render each view.
		foreach (i, ref view; p.oxr.views) {
			glBindFramebuffer(GL_FRAMEBUFFER, view.fbos[view.current_index]);

			glViewport(0, 0, cast(GLsizei)view.width, cast(GLsizei)view.height);

			scene.renderView(ref view.location);

			xrReleaseSwapchainImage(view.swapchain, &releaseInfo);
			view.current_index = 0xffff_ffff_u32;

			layerViews[i].type = XR_TYPE_COMPOSITION_LAYER_PROJECTION_VIEW;
			layerViews[i].pose = view.location.pose;
			layerViews[i].fov = view.location.fov;
			layerViews[i].subImage.swapchain = view.swapchain;
			layerViews[i].subImage.imageRect.offset.x = 0;
			layerViews[i].subImage.imageRect.offset.y = 0;
			layerViews[i].subImage.imageRect.extent.width = cast(i32)view.width;
			layerViews[i].subImage.imageRect.extent.height = cast(i32)view.height;
		}

		layer: XrCompositionLayerProjection;
		layer.type = XR_TYPE_COMPOSITION_LAYER_PROJECTION;
		layer.viewCount = cast(u32)layerViews.length;
		layer.views = layerViews.ptr;

		layers: XrCompositionLayerBaseHeader*[1];
		layers[0] = cast(XrCompositionLayerBaseHeader*)&layer;

		endFrame: XrFrameEndInfo;
		endFrame.type = XR_TYPE_FRAME_END_INFO;
		endFrame.displayTime = frameState.predictedDisplayTime;
		endFrame.environmentBlendMode = p.oxr.blendMode;
		endFrame.layerCount = cast(u32)layers.length;
		endFrame.layers = layers.ptr;

		xrEndFrame(p.oxr.session, &endFrame);

		if (!p.updateActions()) {
			break;
		}
	}

	return 0;
}

/*
 *
 * OpenXR functions.
 *
 */


fn frame(p: Program, ref oxr: OpenXR)
{

}

fn acquireAndWaitViewImage(p: Program, ref view: View)
{
	acquireInfo: XrSwapchainImageAcquireInfo;
	acquireInfo.type = XR_TYPE_SWAPCHAIN_IMAGE_ACQUIRE_INFO;
	xrAcquireSwapchainImage(view.swapchain, &acquireInfo, &view.current_index);

	waitInfo: XrSwapchainImageWaitInfo;
	waitInfo.type = XR_TYPE_SWAPCHAIN_IMAGE_WAIT_INFO;
	waitInfo.timeout = XR_INFINITE_DURATION;
	xrWaitSwapchainImage(view.swapchain, &waitInfo);
}

fn getViewLocation(p: Program, ref frameState: XrFrameState) XrResult
{
	ret: XrResult;
	views: XrView[32];

	viewLocateInfo: XrViewLocateInfo;
	viewLocateInfo.type = XR_TYPE_VIEW_LOCATE_INFO;
	viewLocateInfo.viewConfigurationType = p.oxr.viewConfigType;
	viewLocateInfo.displayTime = frameState.predictedDisplayTime;
	viewLocateInfo.space = p.oxr.space;

	viewState: XrViewState;
	viewState.type = XR_TYPE_VIEW_STATE;

	viewCountOutput: u32;
	ret = xrLocateViews(p.oxr.session, &viewLocateInfo, &viewState, 0, &viewCountOutput, null);
	if (ret != XR_SUCCESS) {
		p.log("xrLocateViews failed");
		return ret;
	}
	if (views.length < viewCountOutput) {
		p.log("Way to main views");
		return XR_ERROR_VALIDATION_FAILURE;
	}

	viewCapacityInput := cast(u32)views.length;
	ret = xrLocateViews(p.oxr.session, &viewLocateInfo, &viewState, viewCapacityInput, &viewCountOutput, views.ptr);
	if (ret != XR_SUCCESS) {
		p.log("xrLocateViews failed");
		return ret;
	}

	foreach (i, ref view; p.oxr.views) {
		view.location = views[i];
	}

	return XR_SUCCESS;
}

fn initOpenXR(p: Program) bool
{
	return setupLoader(p) &&
	       createInstance(p) &&
	       createSession(p) &&
	       createActions(p) &&
	       createViews(p) &&
	       startSession(p);
}

fn finiOpenXR(p: Program)
{
	if (p.oxr.instance !is null) {
		xrDestroyInstance(p.oxr.instance);
		p.oxr.instance = cast(XrInstance)XR_NULL_HANDLE;
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
	createInfo.type = XR_TYPE_INSTANCE_CREATE_INFO;
	createInfo.enabledExtensionCount = cast(u32)exts.length;
	createInfo.enabledExtensionNames = exts.ptr;
	createInfo.applicationInfo.applicationName[] = "Virtual Ground";
	createInfo.applicationInfo.applicationVersion = 1;
	createInfo.applicationInfo.engineName[] = "Charge";
	createInfo.applicationInfo.engineVersion = 1;
	createInfo.applicationInfo.apiVersion = XR_MAKE_VERSION(1, 0, 3);

	ret = xrCreateInstance(&createInfo, &p.oxr.instance);
	if (ret != XR_SUCCESS) {
		p.log("Failed to create instance");
		return false;
	}

	// Also load functions for this instance.
	loadInstanceFunctions(p.oxr.instance);

	return true;
}

fn createSession(p: Program) bool
{
	XrResult ret;

	getInfo: XrSystemGetInfo;
	getInfo.type = XR_TYPE_SYSTEM_GET_INFO;
	getInfo.formFactor = XrFormFactor.XR_FORM_FACTOR_HEAD_MOUNTED_DISPLAY;

	ret = xrGetSystem(p.oxr.instance, &getInfo, &p.oxr.systemId);
	if (ret != XR_SUCCESS) {
		p.log("xrGetSystem failed!");
		return false;
	}

	// Hard coded for now.
	p.oxr.viewConfigType = XrViewConfigurationType.XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO;

	envBlendModes: XrEnvironmentBlendMode[];
	ret = enumEnvironmentBlendModes(p, p.oxr.viewConfigType, out envBlendModes);
	if (ret != XR_SUCCESS || envBlendModes.length <= 0) {
		return false;
	}
	p.oxr.blendMode = envBlendModes[0];

	eglInfo: XrGraphicsBindingEGLMND;
	eglInfo.type = XR_TYPE_GRAPHICS_BINDING_EGL_MND;
	eglInfo.getProcAddress = eglGetProcAddress;
	eglInfo.display = p.egl.dpy;
	eglInfo.config = p.egl.cfg;
	eglInfo.context = p.egl.ctx;

	createInfo: XrSessionCreateInfo;
	createInfo.type = XR_TYPE_SESSION_CREATE_INFO;
	createInfo.next = cast(void*)&eglInfo;
	createInfo.systemId = p.oxr.systemId;
	ret = xrCreateSession(p.oxr.instance, &createInfo, &p.oxr.session);
	if (ret != XR_SUCCESS) {
		p.log("xrCreateSession failed!");
		return false;
	}

	referenceSpaceCreateInfo: XrReferenceSpaceCreateInfo;
	referenceSpaceCreateInfo.type = XR_TYPE_REFERENCE_SPACE_CREATE_INFO;
	referenceSpaceCreateInfo.poseInReferenceSpace.orientation.w = 1.0f;
	referenceSpaceCreateInfo.referenceSpaceType = XR_REFERENCE_SPACE_TYPE_LOCAL;

	ret = xrCreateReferenceSpace(p.oxr.session, &referenceSpaceCreateInfo, &p.oxr.space);
	if (ret != XR_SUCCESS) {
		p.log("xrCreateReferenceSpace failed!");
		return false;
	}

	return true;
}

fn createViews(p: Program) bool
{
	XrResult ret;

	p.oxr.viewConfigProperties.type = XR_TYPE_VIEW_CONFIGURATION_PROPERTIES;
	ret = xrGetViewConfigurationProperties(p.oxr.instance, p.oxr.systemId, p.oxr.viewConfigType, &p.oxr.viewConfigProperties);
	if (ret != XR_SUCCESS) {
		p.log("xrGetViewConfigurationProperties failed!");
		return false;
	}

	p.log(new "viewConfigProperties.fovMutable: ${cast(bool)p.oxr.viewConfigProperties.fovMutable}");

	ret = enumViewConfigurationViews(p, out p.oxr.viewConfigs);
	if (ret != XR_SUCCESS) {
		p.log("enumViewConfigurationViews failed!");
		return false;
	}

	p.oxr.views = new View[](p.oxr.viewConfigs.length);

	foreach(i, ref viewConfig; p.oxr.viewConfigs) {
		view := &p.oxr.views[i];
		view.width = viewConfig.recommendedImageRectWidth;
		view.height = viewConfig.recommendedImageRectHeight;

		swapchainCreateInfo: XrSwapchainCreateInfo;
		swapchainCreateInfo.type = XR_TYPE_SWAPCHAIN_CREATE_INFO;
		swapchainCreateInfo.arraySize = 1;
		swapchainCreateInfo.format = GL_RGBA8;
		swapchainCreateInfo.width = viewConfig.recommendedImageRectWidth;
		swapchainCreateInfo.height = viewConfig.recommendedImageRectHeight;
		swapchainCreateInfo.mipCount = 1;
		swapchainCreateInfo.faceCount = 1;
		swapchainCreateInfo.sampleCount = 1;
		swapchainCreateInfo.usageFlags = XrSwapchainUsageFlags.XR_SWAPCHAIN_USAGE_SAMPLED_BIT | XrSwapchainUsageFlags.XR_SWAPCHAIN_USAGE_COLOR_ATTACHMENT_BIT;

		ret = xrCreateSwapchain(p.oxr.session, &swapchainCreateInfo, &view.swapchain);
		if (ret != XR_SUCCESS) {
			p.log("xrCreateSwapchain failed!");
			return false;
		}

		ret = enumSwapchainImages(p, view.swapchain, out view.textures);
		if (ret != XR_SUCCESS) {
			p.log("xrCreateSwapchain failed!");
			return false;
		}

		glGenTextures(1, &view.depth);
		glBindTexture(GL_TEXTURE_2D, view.depth);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, cast(GLsizei)view.width, cast(GLsizei)view.height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null);

		view.fbos = new GLuint[](view.textures.length);
		glGenFramebuffers(cast(GLsizei)view.fbos.length, view.fbos.ptr);
		foreach (k, ref fbo; view.fbos) {
			glBindFramebuffer(GL_FRAMEBUFFER, fbo);
			glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, view.textures[k], 0);
			glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, view.depth, 0);
		}
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}

	return true;
}

fn startSession(p: Program) bool
{
	ret: XrResult;

	beginInfo: XrSessionBeginInfo;
	beginInfo.type = XR_TYPE_SESSION_BEGIN_INFO;
	beginInfo.primaryViewConfigurationType = p.oxr.viewConfigType;
	ret = xrBeginSession(p.oxr.session, &beginInfo);

	if (ret != XR_SUCCESS) {
		p.log("xrBeginSession failed!");
		return false;
	}

	return true;
}
