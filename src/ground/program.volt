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
import oxr = charge.core.openxr;

import charge.core.openxr.core;


/*!
 * Main program struct holding everything together.
 */
class Program
{
public:
	core: CoreOpenXR;

	move: MoveActions;
	gameplay: GameplayActions;


public:
	this()
	{
		oxr.gOpenXR.updateActions = updateActions;
	}

	fn updateActions(predictedDisplayTime: XrTime) bool
	{
		return .updateActions(ref this.move, ref this.gameplay, predictedDisplayTime);
	}
}
