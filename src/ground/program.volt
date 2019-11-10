// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Holds the main program class.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.program;

import io = watt.io;
import watt = [watt.library, watt.conv];
import amp.openxr;
import amp.egl;
import lib.gl.types;
import lib.gl.gl45;

import ground.actions;

import math = charge.math;
import gfx = charge.gfx;


/*!
 * Main program struct holding everything together.
 */
class Program
{
public:
	oxr: OpenXR;
	egl: EGL;

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
	this()
	{
		oxr.log = log;
		oxr.updateActions = updateActions;
	}

	fn log(str: string)
	{
		io.output.writefln("%s", str);
		io.output.flush();
	}

	fn updateActions() bool
	{
		return .updateActions(this);
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

	//! Is this available
	XR_MND_headless: bool;
	//! Is this available
	XR_MND_egl_enable: bool;

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

	updateActions: dg() bool;
	log: dg(string);
}

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
