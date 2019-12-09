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
import amp.openxr;
import amp.openxr.loader;

import core = charge.core;
import egl = charge.core.egl;
import oxr = charge.core.openxr;
import gfx = charge.gfx;

import charge.core.openxr.core;

import ground.program;
import ground.game;
import ground.actions;
import ground.openxr;
import ground.gfx;


fn main(args: string[]) i32
{
	if (args.length >= 2) {
		g := new WindowGame(args);
		return g.loop();
	} else {
		return runOpenXR(args);
	}
}

fn runOpenXR(args: string[]) i32
{
	p: Program = new Program();

	scope (exit) {
		finiOpenXR(p);
		egl.finiEGL(ref p.egl);
	}

	if (!egl.initEGL(ref p.egl) || !initOpenXR(p)) {
		return 1;
	}

	// Only here to integrate better with charge code.
	core := new CoreOpenXR();
	defTarget := gfx.DefaultTarget.opCall();
	scope (exit) {
		foreach (ref view; p.oxr.views) {
			foreach (ref target; view.targets) {
				gfx.reference(ref target, null);
			}
			glDeleteTextures(1, &view.depth);
		}

		gfx.DefaultTarget.close();
		core.close();
	}

	scene := new Scene();
	scope (exit) {
		scene.close();
	}

	p.oxr.loop(scene);

	return 0;
}


/*
 *
 * OpenXR functions.
 *
 */

fn initOpenXR(p: Program) bool
{
	return setupLoader(p) &&
	       p.oxr.createInstance() &&
	       p.oxr.createSessionEGL(ref p.egl) &&
	       createActions(p) &&
	       p.oxr.createViews() &&
	       p.oxr.startSession();
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

fn createInstance(ref oxr: oxr.OpenXR) bool
{
	XrResult ret;

	extProps: XrExtensionProperties[];
	enumExtensionProps(ref oxr, out extProps);
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
	createInfo.applicationInfo.applicationName[] = "Virtual Ground";
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

	return true;
}

fn createSessionEGL(ref oxr: oxr.OpenXR, ref egl: egl.EGL) bool
{
	XrResult ret;

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

	referenceSpaceCreateInfo: XrReferenceSpaceCreateInfo;
	referenceSpaceCreateInfo.type = XR_TYPE_REFERENCE_SPACE_CREATE_INFO;
	referenceSpaceCreateInfo.poseInReferenceSpace.orientation.w = 1.0f;
	referenceSpaceCreateInfo.referenceSpaceType = XR_REFERENCE_SPACE_TYPE_LOCAL;

	ret = xrCreateReferenceSpace(oxr.session, &referenceSpaceCreateInfo, &oxr.space);
	if (ret != XR_SUCCESS) {
		oxr.log("xrCreateReferenceSpace failed!");
		return false;
	}

	return true;
}

fn createViews(ref oxr: oxr.OpenXR) bool
{
	XrResult ret;

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
			name := new "ground/view/${i}/${k}";
			target = gfx.ExtTarget.make(name, fbo, view.width, view.height);
		}
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}

	return true;
}

fn startSession(ref oxr: oxr.OpenXR) bool
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
