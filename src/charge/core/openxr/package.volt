// Copyright 2018-2022, Collabora, Ltd.
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
import math = charge.math;
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
	Ar,
	Overlay,
	Headless,
}

struct Extentions
{
	XR_KHR_composition_layer_depth: bool;
	XR_KHR_convert_timespec_time: bool;
	XR_KHR_opengl_enable: bool;
	XR_KHR_win32_convert_performance_counter_time: bool;
	XR_EXT_local_floor: bool;
	XR_MND_headless: bool;
	XR_EXTX_overlay: bool;
	XR_MNDX_ball_on_a_stick_controller: bool;
	XR_MNDX_egl_enable: bool;
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

	//! Which mode are we in.
	mode: Mode;

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

	frameID: i64;

	views: View[];

	updateActions: dg(XrTime) bool;

	quadHack: Quad;


public:
	@property fn ar() bool { return mode == Mode.Ar; }
	@property fn overlay() bool { return mode == Mode.Overlay; }
	@property fn headless() bool { return mode == Mode.Headless; }
}

/*!
 * Holds information about a view.
 */
struct View
{
	static struct Location
	{
		oxr: XrView;

		@property fn orientation() math.Quatf { return *cast(math.Quatf*)&this.oxr.pose.orientation; }
		@property fn position() math.Point3f { return *cast(math.Point3f*)&this.oxr.pose.position; }
		@property fn fov() math.Fovf { return *cast(math.Fovf*)&this.oxr.fov; }
	};

	location: Location;

	// The rest are only valid if not headless

	width, height: uint;

	static struct Swapchains
	{
		texture: XrSwapchain;
		depth: XrSwapchain;
	}

	swapchains: Swapchains;

	current_index: u32;
	textures: GLuint[];
	depths: GLuint[];
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
