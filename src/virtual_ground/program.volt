// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Holds the main program class.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module virtual_ground.program;

import io = watt.io;
import watt = [watt.library, watt.conv];
import amp.openxr;
import amp.egl;
import lib.gl.types;

import virtual_ground.actions;


/*!
 * Main program struct holding everything together.
 */
class Program
{
public:
	oxr: OpenXR;
	egl: EGL;

	XR_MND_headless: bool;
	XR_MND_egl_enable: bool;

	iProfKhrSimple: XrPath;
	iProfGoogleDaydream: XrPath;
	iProfMndBallOnStick: XrPath;

	subPathUser: XrPath;
	subPathHead: XrPath;
	subPathLeft: XrPath;
	subPathRight: XrPath;
	subPathGamePad: XrPath;

	gameplayActionSet: XrActionSet;
	aimPoseAction: XrAction;
	gripPoseAction: XrAction;
	grabAction: XrAction;
	quitAction: XrAction;

	move: MoveActions;
	gameplay: GameplayActions;


public:
	fn log(str: string)
	{
		io.output.writefln("%s", str);
		io.output.flush();
	}
}

/*!
 * Holds all needed EGL state.
 */
struct EGL
{
	lib: watt.Library;
	dpy: EGLDisplay;
	cfg: EGLConfig;
	ctx: EGLContext;
}

/*!
 * Holds the basic OpenXR state needed.
 */
struct OpenXR
{
	lib: watt.Library;

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

	space: XrSpace;

	views: View[];
}

struct View
{
	width, height: uint;

	swapchain: XrSwapchain;

	location: XrView;

	current_index: u32;
	textures: GLuint[];
	fbos: GLuint[];
	depth: GLuint;
}
