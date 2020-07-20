// Copyright 2018-2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0
/*!
 * @brief  OpenXR integration.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module charge.core.openxr;

import watt = [watt.library];
import amp.openxr;
import lib.gl.gl45;

import gfx = charge.gfx;
import charge.core.openxr.enumerate;


/*!
 * Global collection of OpenXR things.
 */
global gOpenXR: OpenXR;

/*!
 * Selecting which mode of OpenXR you want.
 * Headless not available on all runtimes.
 */
enum Mode
{
	Normal,
	Overlay,
	Headless,
}

struct Extentions
{
	XR_KHR_convert_timespec_time: bool;
	XR_KHR_opengl_enable: bool;
	XR_MND_headless: bool;
	XR_MNDX_egl_enable: bool;
	XR_EXTX_overlay: bool;
}

/*!
 * Holds the basic OpenXR state needed.
 */
struct OpenXR
{
	//! Logging delegate.
	log: dg(string);

	//! Loaded loader library (not runtime).
	lib: watt.Library;

	//! We are not rendering to the device.
	headless: bool;

	instance: XrInstance;
	systemId: XrSystemId;
	session: XrSession;

	//! Is this available from the current runtime.
	have: Extentions;
	//! Is this extension enabled.
	enabled: Extentions;

	//! Selected blend mode.
	blendMode: XrEnvironmentBlendMode;
	//! Selected view config.
	viewConfigType: XrViewConfigurationType;
	//! Configuration props for selected view config.
	viewConfigProperties: XrViewConfigurationProperties;
	//! Config for each view.
	viewConfigs: XrViewConfigurationView[];

	stageSpace: XrSpace;
	viewSpace: XrSpace;

	views: View[];

	updateActions: dg(XrTime) bool;

	quadHack: Quad;
}

/*!
 * Holds information about a view.
 */
struct View
{
	width, height: uint;

	swapchain: XrSwapchain;

	location: XrView;

	current_index: u32;
	textures: GLuint[];
	depth: GLuint;
	targets: gfx.Target[];
}

struct Quad
{
public:
	swapchain: XrSwapchain;
	pose: XrPosef;
	size: XrExtent2Df;
	space: XrSpace;

	w, h: u32;
	textures: GLuint[];
	targets: gfx.Target[];
	active: bool;


public:
	fn destroy(ref oxr: OpenXR)
	{
		foreach (k, ref target; targets) {
			gfx.reference(ref target, null);
		}

		if (swapchain !is cast(XrSwapchain)XR_NULL_HANDLE) {
			xrDestroySwapchain(swapchain);
			swapchain = cast(XrSwapchain)XR_NULL_HANDLE;
		}

		w = h = 0;
		textures = null;
		targets = null;
	}

	fn create(ref oxr: OpenXR, w: u32, h: u32)
	{
		destroy(ref oxr);

		this.w = w;
		this.h = h;

		swapchainCreateInfo: XrSwapchainCreateInfo;
		swapchainCreateInfo.type = XR_TYPE_SWAPCHAIN_CREATE_INFO;
		swapchainCreateInfo.arraySize = 1;
		swapchainCreateInfo.format = GL_RGBA8;
		swapchainCreateInfo.width = w;
		swapchainCreateInfo.height = h;
		swapchainCreateInfo.mipCount = 1;
		swapchainCreateInfo.faceCount = 1;
		swapchainCreateInfo.sampleCount = 1;
		swapchainCreateInfo.usageFlags = XrSwapchainUsageFlags.XR_SWAPCHAIN_USAGE_SAMPLED_BIT | XrSwapchainUsageFlags.XR_SWAPCHAIN_USAGE_COLOR_ATTACHMENT_BIT;

		ret: XrResult;
		ret = xrCreateSwapchain(oxr.session, &swapchainCreateInfo, &swapchain);
		if (ret != XR_SUCCESS) {
			oxr.log("xrCreateSwapchain failed!");
			return;
		}

		ret = enumSwapchainImages(ref oxr, swapchain, out textures);
		if (ret != XR_SUCCESS) {
			oxr.log("xrCreateSwapchain failed!");
			return;
		}

		targets = new gfx.Target[](textures.length);
		foreach (k, ref target; targets) {
			fbo: GLuint;
			glGenFramebuffers(1, &fbo);
			glBindFramebuffer(GL_FRAMEBUFFER, fbo);
			glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textures[k], 0);
			name := new "openxr/quad/${k}";
			target = gfx.ExtTarget.make(name, fbo, w, h);
		}

		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}
}
