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
	Headless,
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

	//! Is this available from the current runtime.
	XR_MND_headless: bool;
	//! Is this available from the current runtime.
	XR_MND_egl_enable: bool;

	//! We are not rendering to the device.
	headless: bool;

	instance: XrInstance;
	systemId: XrSystemId;
	session: XrSession;

	//! Selected blend mode.
	blendMode: XrEnvironmentBlendMode;
	//! Selected view config.
	viewConfigType: XrViewConfigurationType;
	//! Configuration props for selected view config.
	viewConfigProperties: XrViewConfigurationProperties;
	//! Config for each view.
	viewConfigs: XrViewConfigurationView[];

	localSpace: XrSpace;
	viewSpace: XrSpace;

	views: View[];

	updateActions: dg(XrTime) bool;
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
