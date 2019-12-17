// Copyright 2018-2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Main file, it all starts from here.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module main;

import charge.core.openxr : gOpenXR;
import charge.core.openxr.core : CoreOpenXR;

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

	core := new CoreOpenXR();
	scope (exit) {
		core.close();
	}

	p: Program = new Program();

	if (!createActions(ref p.move, ref p.gameplay)) {
		return 1;
	}

	scene := new Scene();
	scope (exit) {
		scene.close();
	}

	gOpenXR.loop(scene);

	return 0;
}
