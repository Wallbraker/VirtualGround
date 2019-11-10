// Copyright 2018-2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Main file, it all starts from here.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.game;

import core = charge.core;
import gfx = charge.gfx;
import ctl = charge.ctl;
import math = charge.math;
import scene = charge.game.scene;

import ground.gfx;


/*!
 * Very small wrapper class to show the scene without OpenXR.
 */
class WindowGame : scene.ManagerApp
{
public:
	this(args: string[])
	{
		// First init core.
		opts := new core.Options();
		opts.width = 1920;
		opts.height = 1080;
		super(opts);

		s := new WrapperScene(this);
		push(s);
	}
}

/*!
 * Very small wrapper class to show the scene without OpenXR.
 */
class WrapperScene : scene.Simple
{
public:
	s: Scene;


public:
	this(app: scene.ManagerApp)
	{
		super(app, Type.Game);
		s = new Scene();
	}

	override fn render(t: gfx.Target, ref viewInfo: gfx.ViewInfo)
	{
		viewInfo.ensureValidFov(85, t);
		viewInfo.position = math.Point3f.opCall(0.0f, 1.6f, 0.0f);
		viewInfo.rotation = math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);
		s.renderView(t, ref viewInfo);
	}

	override fn close()
	{
		s.close();
		s = null;
	}

	override fn keyDown(ctl.Keyboard, int)
	{
		mManager.closeMe(this);
	}
}
