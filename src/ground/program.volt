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
import egl = charge.core.egl;
import oxr = charge.core.openxr;


/*!
 * Main program struct holding everything together.
 */
class Program
{
public:
	egl: .egl.EGL;
	oxr: .oxr.OpenXR;

	iProfKhrSimple: XrPath;
	iProfGoogleDaydream: XrPath;
	iProfMndBallOnStick: XrPath;

	subPathUser: XrPath;
	subPathHead: XrPath;
	subPathLeft: XrPath;
	subPathRight: XrPath;
	subPathGamePad: XrPath;

	move: MoveActions;
	gameplay: GameplayActions;


public:
	this()
	{
		egl.log = log;
		oxr.log = log;
		oxr.updateActions = updateActions;
	}

	fn log(str: string)
	{
		io.output.writefln("%s", str);
		io.output.flush();
	}

	fn updateActions(predictedDisplayTime: XrTime) bool
	{
		return .updateActions(this, predictedDisplayTime);
	}
}
