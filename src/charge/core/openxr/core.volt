// Copyright 2018-2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0
/*!
 * @brief  Core using EGL and OpenXR to show content.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module charge.core.openxr.core;

import core.exception;
import core.c.stdio : fprintf, fflush, stderr;
import core.c.stdlib : exit;

import watt = [watt.library, watt.conv];

import lib.gl.gl45;

import amp.egl;
import amp.openxr;
import amp.openxr.loader;

import io = watt.io;

import egl = charge.core.egl;
import gfx = charge.gfx;
import ctl = charge.ctl;
import math = charge.math;

import charge.core;
import charge.core.basic;
import charge.core.sdl;
import charge.core.win32;
import charge.core.openxr;
import charge.core.openxr.enumerate;
import charge.sys.resource;
import charge.sys.memheader;

import charge.core.openxr : gOpenXR, OpenXR;


class CoreOpenXR : BasicCore
{
public:
	egl: .egl.EGL;


private:
	mRunning: bool;
	mChain: Core;


public:
	this(opts: Options, mode: Mode)
	{
		assert(opts !is null);

		// Need to do this ASAP.
		this.egl.log = doLog;
		gOpenXR.log = doLog;

		gInstance = this;
		super(Flag.GFX);

		final switch (mode) {
		case Mode.Normal:
			new InputOpenXR();

			initOpenXRAndEGL(ref gOpenXR, ref this.egl);

			foreach (initFunc; gInitFuncs) {
				initFunc();
			}

			mRunning = true;

			break;
		case Mode.Headless:
			initOpenXRHeadless(ref gOpenXR);

			version (Windows) {
				mChain = new CoreWin32(opts);
			} else {
				mChain = new CoreSDL(opts);
			}

			mChain.setUpdateActions(chainUpdateActions);
			mChain.setLogic(chainLogic);
			mChain.setRender(chainRender);
			mChain.setClose(chainClose);
			mChain.setIdle(chainIdle);

			break;
		}
	}

	override fn loop() int
	{
		if (mChain !is null) {
			return mChain.loop();
		} else {
			while (mRunning) {
				oneLoop(ref gOpenXR, doRender, doUpdateActions);
			}

			doClose();

			return mRetVal;
		}
	}

	override fn quit(ret: int)
	{
		if (mChain !is null) {
			mChain.quit(ret);
		} else {
			mRetVal = ret;
			mRunning = false;
		}
	}

	override fn panic(msg: string)
	{
		if (mChain !is null) {
			return mChain.panic(msg);
		} else {
			io.error.writefln("panic");
			io.error.writefln("%s", msg);
			io.error.flush();
			exit(-1);
		}
	}

	override fn getClipboardText() string
	{
		if (mChain !is null) {
			return mChain.getClipboardText();
		} else {
			return null;
		}
	}

	override fn screenShot()
	{
		if (mChain !is null) {
			return mChain.screenShot();
		}
	}

	override fn resize(w: uint, h: uint, mode: WindowMode)
	{
		if (mChain !is null) {
			return mChain.resize(w, h, mode);
		}
	}

	override fn size(out w: uint, out h: uint, out mode: WindowMode)
	{
		if (mChain !is null) {
			return mChain.size(out w, out h, out mode);
		}
	}


private:
	fn doClose()
	{
		closeDg();

		finiOpenXR(ref gOpenXR);

		foreach (closeFunc; gCloseFuncs) {
			closeFunc();
		}

		p := Pool.opCall();
		p.collect();
		p.cleanAndLeakCheck(io.output.write);
		cMemoryPrintAll(io.output.write);
		io.output.flush();
	}

	fn doUpdateActions(predictedDisplayTime: XrTime)
	{
		updateActionsDg(predictedDisplayTime);
	}

	fn doRender(t: gfx.Target, ref viewInfo: gfx.ViewInfo)
	{
		renderDg(t, ref viewInfo);
	}

	fn doLog(str: string)
	{
		io.output.writefln("%s", str);
		io.output.flush();
	}


	/*
	 *
	 * Chain functions.
	 *
	 */

	fn chainUpdateActions(predictedDisplayTime: i64) { updateActionsDg(predictedDisplayTime); }
	fn chainLogic() { logicDg(); }

	fn chainRender(t: gfx.Target, ref viewInfo: gfx.ViewInfo)
	{
		updateActionsDg(0);

		renderDg(t, ref viewInfo);
	}

	fn chainClose() { doClose(); }
	fn chainIdle(time: i64) { idleDg(time); }
}

class InputOpenXR : ctl.Input
{
public:
	this()
	{
		super();

		keyboardArray ~= new KeyboardOpenXR();
		mouseArray ~= new MouseOpenXR();
	}
}

class MouseOpenXR : ctl.Mouse
{
protected:
	mRelMode: bool;


public:
	this()
	{

	}

	override fn setRelativeMode(value: bool) { mRelMode = value; }

	override fn getRelativeMode() bool { return mRelMode; }
}

class KeyboardOpenXR : ctl.Keyboard
{

}


/*
 *
 * Init and fini OpenXR functions.
 *
 */

fn initOpenXRAndEGL(ref oxr: OpenXR, ref egl: egl.EGL) bool
{
	return oxr.setupLoader() &&
	       oxr.findExtensions() &&
	       oxr.createInstanceEGL() &&
	       .egl.initEGL(ref egl) &&
	       oxr.createSessionEGL(ref egl) &&
	       oxr.createViewsGL() &&
	       oxr.startSession();
}

fn initOpenXRHeadless(ref oxr: OpenXR) bool
{
	return oxr.setupLoader() &&
	       oxr.findExtensions() &&
	       oxr.createInstanceHeadless() &&
	       oxr.createSessionHeadless() &&
	       oxr.createViewsHeadless() &&
	       oxr.startSession();
}

fn finiOpenXR(ref oxr: OpenXR)
{
	foreach (ref view; oxr.views) {
		foreach (ref target; view.targets) {
			gfx.reference(ref target, null);
		}
		glDeleteTextures(1, &view.depth);
	}

	gfx.DefaultTarget.close();

	if (oxr.instance !is null) {
		xrDestroyInstance(oxr.instance);
		oxr.instance = cast(XrInstance)XR_NULL_HANDLE;
	}
}

fn setupLoader(ref oxr: OpenXR) bool
{
	oxr.lib = loadLoader();
	if (oxr.lib is null) {
		oxr.log("Failed to load OpenXR runtime!");
		return false;
	}

	if (!loadRuntimeFuncs(oxr.lib.symbol)) {
		oxr.log("Failed to load OpenXR runtime functions!");
		return false;
	}

	return true;
}

fn findExtensions(ref oxr: OpenXR) bool
{
	extProps: XrExtensionProperties[];
	ret: XrResult;

	ret = enumExtensionProps(ref oxr, out extProps);
	if (ret != XR_SUCCESS) {
		// Already logged.
		return false;
	}

	foreach (ref ext; extProps) {
		name := watt.toString(ext.extensionName.ptr);
		switch (name) {
		case "XR_MND_headless":
			oxr.XR_MND_headless = true;
			break;
		case "XR_MND_egl_enable":
			oxr.XR_MND_egl_enable = true;
			break;
		default:
		}
	}

	return true;
}

fn createReferenceSpace(ref oxr: OpenXR, type: XrReferenceSpaceType, out space: XrSpace) bool
{
	referenceSpaceCreateInfo: XrReferenceSpaceCreateInfo;
	referenceSpaceCreateInfo.type = XR_TYPE_REFERENCE_SPACE_CREATE_INFO;
	referenceSpaceCreateInfo.poseInReferenceSpace.orientation.w = 1.0f;
	referenceSpaceCreateInfo.referenceSpaceType = type;

	ret := xrCreateReferenceSpace(oxr.session, &referenceSpaceCreateInfo, &space);
	if (ret != XR_SUCCESS) {
		oxr.log("xrCreateReferenceSpace failed!");
		return false;
	}

	return true;
}

fn createInstanceHeadless(ref oxr: OpenXR) bool
{
	ret: XrResult;

	if (!oxr.XR_MND_headless) {
		oxr.log("Doesn't have XR_MND_headless! :(");
		return false;
	}

	exts: const(char)*[2] = [
		"XR_KHR_convert_timespec_time".ptr,
		"XR_MND_headless".ptr,
	];

	createInfo: XrInstanceCreateInfo;
	createInfo.type = XR_TYPE_INSTANCE_CREATE_INFO;
	createInfo.enabledExtensionCount = cast(u32)exts.length;
	createInfo.enabledExtensionNames = exts.ptr;
	createInfo.applicationInfo.applicationName[] = "CoreOpenXR";
	createInfo.applicationInfo.applicationVersion = 1;
	createInfo.applicationInfo.engineName[] = "Charge";
	createInfo.applicationInfo.engineVersion = 1;
	createInfo.applicationInfo.apiVersion = XR_MAKE_VERSION(1, 0, 3);

	ret = xrCreateInstance(&createInfo, &oxr.instance);
	if (ret != XR_SUCCESS) {
		oxr.log("Failed to create instance");
		return false;
	}

	// Also load functions for this instance.
	loadInstanceFunctions(oxr.instance);

	// Make that we are headless.
	oxr.headless = true;

	return true;
}

fn createSessionHeadless(ref oxr: OpenXR) bool
{
	assert(oxr.headless);

	ret: XrResult;

	getInfo: XrSystemGetInfo;
	getInfo.type = XR_TYPE_SYSTEM_GET_INFO;
	getInfo.formFactor = XrFormFactor.XR_FORM_FACTOR_HEAD_MOUNTED_DISPLAY;

	ret = xrGetSystem(oxr.instance, &getInfo, &oxr.systemId);
	if (ret != XR_SUCCESS) {
		oxr.log("xrGetSystem failed!");
		return false;
	}

	// Hard coded for now.
	oxr.viewConfigType = XrViewConfigurationType.XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO;

	envBlendModes: XrEnvironmentBlendMode[];
	ret = enumEnvironmentBlendModes(ref oxr, oxr.viewConfigType, out envBlendModes);
	if (ret != XR_SUCCESS || envBlendModes.length <= 0) {
		return false;
	}
	oxr.blendMode = envBlendModes[0];

	createInfo: XrSessionCreateInfo;
	createInfo.type = XR_TYPE_SESSION_CREATE_INFO;
	createInfo.systemId = oxr.systemId;
	ret = xrCreateSession(oxr.instance, &createInfo, &oxr.session);
	if (ret != XR_SUCCESS) {
		oxr.log("xrCreateSession failed!");
		return false;
	}

	if (!oxr.createReferenceSpace(XR_REFERENCE_SPACE_TYPE_LOCAL, out oxr.localSpace) ||
	    !oxr.createReferenceSpace(XR_REFERENCE_SPACE_TYPE_VIEW, out oxr.viewSpace)) {
		return false;
	}

	return true;
}

fn createViewsHeadless(ref oxr: OpenXR) bool
{
	assert(oxr.headless);

	ret: XrResult;

	oxr.viewConfigProperties.type = XR_TYPE_VIEW_CONFIGURATION_PROPERTIES;
	ret = xrGetViewConfigurationProperties(oxr.instance, oxr.systemId, oxr.viewConfigType, &oxr.viewConfigProperties);
	if (ret != XR_SUCCESS) {
		oxr.log("xrGetViewConfigurationProperties failed!");
		return false;
	}

	ret = enumViewConfigurationViews(ref oxr, out oxr.viewConfigs);
	if (ret != XR_SUCCESS) {
		oxr.log("enumViewConfigurationViews failed!");
		return false;
	}

	oxr.views = new .oxr.View[](oxr.viewConfigs.length);

	return true;
}

fn createInstanceEGL(ref oxr: OpenXR) bool
{
	ret: XrResult;

	if (!oxr.XR_MND_egl_enable) {
		oxr.log("Doesn't have XR_MND_egl_enable! :(");
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
	createInfo.applicationInfo.applicationName[] = "CoreOpenXR";
	createInfo.applicationInfo.applicationVersion = 1;
	createInfo.applicationInfo.engineName[] = "Charge";
	createInfo.applicationInfo.engineVersion = 1;
	createInfo.applicationInfo.apiVersion = XR_MAKE_VERSION(1, 0, 3);

	ret = xrCreateInstance(&createInfo, &oxr.instance);
	if (ret != XR_SUCCESS) {
		oxr.log("Failed to create instance");
		return false;
	}

	// Also load functions for this instance.
	loadInstanceFunctions(oxr.instance);

	// We are not headless.
	oxr.headless = false;

	return true;
}

fn createSessionEGL(ref oxr: OpenXR, ref egl: egl.EGL) bool
{
	assert(!oxr.headless);

	ret: XrResult;

	getInfo: XrSystemGetInfo;
	getInfo.type = XR_TYPE_SYSTEM_GET_INFO;
	getInfo.formFactor = XrFormFactor.XR_FORM_FACTOR_HEAD_MOUNTED_DISPLAY;

	ret = xrGetSystem(oxr.instance, &getInfo, &oxr.systemId);
	if (ret != XR_SUCCESS) {
		oxr.log("xrGetSystem failed!");
		return false;
	}

	// Hard coded for now.
	oxr.viewConfigType = XrViewConfigurationType.XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO;

	envBlendModes: XrEnvironmentBlendMode[];
	ret = enumEnvironmentBlendModes(ref oxr, oxr.viewConfigType, out envBlendModes);
	if (ret != XR_SUCCESS || envBlendModes.length <= 0) {
		return false;
	}
	oxr.blendMode = envBlendModes[0];

	eglInfo: XrGraphicsBindingEGLMND;
	eglInfo.type = XR_TYPE_GRAPHICS_BINDING_EGL_MND;
	eglInfo.getProcAddress = eglGetProcAddress;
	eglInfo.display = egl.dpy;
	eglInfo.config = egl.cfg;
	eglInfo.context = egl.ctx;

	createInfo: XrSessionCreateInfo;
	createInfo.type = XR_TYPE_SESSION_CREATE_INFO;
	createInfo.next = cast(void*)&eglInfo;
	createInfo.systemId = oxr.systemId;
	ret = xrCreateSession(oxr.instance, &createInfo, &oxr.session);
	if (ret != XR_SUCCESS) {
		oxr.log("xrCreateSession failed!");
		return false;
	}

	if (!oxr.createReferenceSpace(XR_REFERENCE_SPACE_TYPE_LOCAL, out oxr.localSpace) ||
	    !oxr.createReferenceSpace(XR_REFERENCE_SPACE_TYPE_VIEW, out oxr.viewSpace)) {
		return false;
	}

	return true;
}

fn createViewsGL(ref oxr: OpenXR) bool
{
	assert(!oxr.headless);

	ret: XrResult;

	oxr.viewConfigProperties.type = XR_TYPE_VIEW_CONFIGURATION_PROPERTIES;
	ret = xrGetViewConfigurationProperties(oxr.instance, oxr.systemId, oxr.viewConfigType, &oxr.viewConfigProperties);
	if (ret != XR_SUCCESS) {
		oxr.log("xrGetViewConfigurationProperties failed!");
		return false;
	}

	ret = enumViewConfigurationViews(ref oxr, out oxr.viewConfigs);
	if (ret != XR_SUCCESS) {
		oxr.log("enumViewConfigurationViews failed!");
		return false;
	}

	oxr.views = new .oxr.View[](oxr.viewConfigs.length);

	foreach(i, ref viewConfig; oxr.viewConfigs) {
		view := &oxr.views[i];
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

		ret = xrCreateSwapchain(oxr.session, &swapchainCreateInfo, &view.swapchain);
		if (ret != XR_SUCCESS) {
			oxr.log("xrCreateSwapchain failed!");
			return false;
		}

		ret = enumSwapchainImages(ref oxr, view.swapchain, out view.textures);
		if (ret != XR_SUCCESS) {
			oxr.log("xrCreateSwapchain failed!");
			return false;
		}

		glGenTextures(1, &view.depth);
		glBindTexture(GL_TEXTURE_2D, view.depth);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, cast(GLsizei)view.width, cast(GLsizei)view.height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null);

		view.targets = new gfx.Target[](view.textures.length);
		foreach (k, ref target; view.targets) {
			fbo: GLuint;
			glGenFramebuffers(1, &fbo);
			glBindFramebuffer(GL_FRAMEBUFFER, fbo);
			glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, view.textures[k], 0);
			glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, view.depth, 0);
			name := new "openxr/view/${i}/${k}";
			target = gfx.ExtTarget.make(name, fbo, view.width, view.height);
		}
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}

	return true;
}

fn startSession(ref oxr: OpenXR) bool
{
	ret: XrResult;

	beginInfo: XrSessionBeginInfo;
	beginInfo.type = XR_TYPE_SESSION_BEGIN_INFO;
	beginInfo.primaryViewConfigurationType = oxr.viewConfigType;
	ret = xrBeginSession(oxr.session, &beginInfo);

	if (ret != XR_SUCCESS) {
		oxr.log("xrBeginSession failed!");
		return false;
	}

	return true;
}


/*
 *
 * Loop OpenXR functions.
 *
 */

fn oneLoop(ref oxr: OpenXR,
           renderDg: dg(gfx.Target, ref gfx.ViewInfo),
           updateActionsDg: dg(XrTime)
           ) bool
{
	defTarget := gfx.DefaultTarget.opCall();
	ret: XrResult;
	predictedDisplayTime: XrTime;

	ret = oxr.waitFrame(out predictedDisplayTime);
	if (ret != XR_SUCCESS) {
		// Already logged.
		return false;
	}

	// We have a new preditcted time, get the swapchains ready.
	foreach (ref view; oxr.views) {
		oxr.acquireAndWaitViewImage(ref view);
	}

	// Grab the action state.
	updateActionsDg(predictedDisplayTime);

	ret = oxr.getViewLocation(predictedDisplayTime);
	if (ret != XR_SUCCESS) {
		// Already logged.
		return false;
	}

	// Swapchains are now ready, signal that we are starting to render.
	ret = xrBeginFrame(oxr.session, null);
	if (ret != XR_SUCCESS) {
		oxr.log("xrBeginFrame failed!");
		return false;
	}

	releaseInfo: XrSwapchainImageReleaseInfo;
	releaseInfo.type = XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO;

	layerViews: XrCompositionLayerProjectionView[2];

	// This is where we render each view.
	foreach (i, ref view; oxr.views) {
		viewInfo: gfx.ViewInfo;
		viewInfo.validFov = true;
		viewInfo.validLocation = true;
		viewInfo.fov = *cast(math.Fovf*)&view.location.fov;
		viewInfo.position = *cast(math.Point3f*)&view.location.pose.position;
		viewInfo.rotation = *cast(math.Quatf*)&view.location.pose.orientation;

		gfx.glCheckError();

		target := view.targets[view.current_index];
		target.bind(defTarget);
		glViewport(0, 0, cast(GLsizei)view.width, cast(GLsizei)view.height);

		gfx.glCheckError();

		// This is where we render!
		renderDg(target, ref viewInfo);

		gfx.glCheckError();

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

	gfx.glCheckError();

	layer: XrCompositionLayerProjection;
	layer.type = XR_TYPE_COMPOSITION_LAYER_PROJECTION;
	layer.viewCount = cast(u32)layerViews.length;
	layer.views = layerViews.ptr;

	layers: XrCompositionLayerBaseHeader*[1];
	layers[0] = cast(XrCompositionLayerBaseHeader*)&layer;

	endFrame: XrFrameEndInfo;
	endFrame.type = XR_TYPE_FRAME_END_INFO;
	endFrame.displayTime = predictedDisplayTime;
	endFrame.environmentBlendMode = oxr.blendMode;
	endFrame.layerCount = cast(u32)layers.length;
	endFrame.layers = layers.ptr;

	xrEndFrame(oxr.session, &endFrame);

	gfx.glCheckError();

	return true;
}

fn waitFrame(ref oxr: OpenXR, out predictedDisplayTime: XrTime) XrResult
{
	ret: XrResult;

	frameState: XrFrameState;
	frameState.type = XR_TYPE_FRAME_STATE;

	ret = xrWaitFrame(oxr.session, null, &frameState);
	if (ret != XR_SUCCESS) {
		oxr.log("xrWaitFrame failed!");
		return ret;
	}

	predictedDisplayTime = frameState.predictedDisplayTime;

	return XR_SUCCESS;
}

fn acquireAndWaitViewImage(ref oxr: OpenXR, ref view: View) XrResult
{
	ret: XrResult;

	acquireInfo: XrSwapchainImageAcquireInfo;
	acquireInfo.type = XR_TYPE_SWAPCHAIN_IMAGE_ACQUIRE_INFO;
	ret = xrAcquireSwapchainImage(view.swapchain, &acquireInfo, &view.current_index);
	if (ret != XR_SUCCESS) {
		oxr.log("xrAcquireSwapchainImage failed!");
		return ret;
	}

	waitInfo: XrSwapchainImageWaitInfo;
	waitInfo.type = XR_TYPE_SWAPCHAIN_IMAGE_WAIT_INFO;
	waitInfo.timeout = XR_INFINITE_DURATION;
	ret = xrWaitSwapchainImage(view.swapchain, &waitInfo);
	if (ret != XR_SUCCESS) {
		oxr.log("xrWaitSwapchainImage failed!");
		return ret;
	}

	return XR_SUCCESS;
}

fn getViewLocation(ref oxr: OpenXR, predictedDisplayTime: XrTime) XrResult
{
	ret: XrResult;
	views: XrView[32];

	ret = enumViews(ref oxr, predictedDisplayTime, ref views);
	if (ret != XR_SUCCESS) {
		// Already logged.
		return ret;
	}

	foreach (i, ref view; oxr.views) {
		view.location = views[i];
	}

	return XR_SUCCESS;
}
