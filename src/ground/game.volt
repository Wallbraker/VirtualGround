// Copyright 2018-2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Main file, it all starts from here.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.game;

import watt.math : PIf;

import core = charge.core;
import gfx = charge.gfx;
import ctl = charge.ctl;
import math = charge.math;
import scene = charge.game.scene;

import charge.core.openxr.core : CoreOpenXR;

import ground.gfx;
import ground.actions;


global gMoveActions: MoveActions;
global gGameplayActions: GameplayActions;

/*!
 * Very small wrapper class to show the scene without OpenXR.
 */
class WindowGame : scene.ManagerApp
{
public:
	this(args: string[])
	{
		// First init core.
		opts := new .core.Options();
		opts.width = 1920;
		opts.height = 1080;

		core := new CoreOpenXR(opts);

		super(core);

		s := new WrapperScene(this);
		push(s);

		createActions(ref gMoveActions, ref gGameplayActions);
	}
}

/*!
 * Very small wrapper class to show the scene without OpenXR.
 */
class WrapperScene : scene.Simple
{
public:
	s: Scene;

	// Rotation stuff.
	isDragging: bool;
	camPosition: math.Point3f;
	camRotation: math.Quatf;
	camSpeed: f32 = 0.2f;
	aa: gfx.AA;


protected:
	mCamHeading, mCamPitch, distance: f32;
	mCamUp, mCamFore, mCamBack, mCamLeft, mCamRight: bool;


public:
	this(app: scene.ManagerApp)
	{
		super(app, Type.Game);
		s = new Scene();

		aa.kind = gfx.AA.Kind.None;
		camRotation = math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);
		camPosition = math.Point3f.opCall(0.0f, 1.6f, 0.0f);
	}

	override fn render(t: gfx.Target, ref viewInfo: gfx.ViewInfo)
	{
		viewInfo.ensureValidFov(85, t);
		viewInfo.position = camPosition;
		viewInfo.rotation = camRotation;

		// Always use the AA, it supports non-aa.
		aa.bind(t);
		s.renderView(aa.fbo, ref viewInfo);
		aa.resolveToAndBind(t);
	}

	override fn close()
	{
		aa.close();
		s.close();
		s = null;
	}

	override fn updateActions(predictedDisplayTime: i64)
	{
		if (!.updateActions(ref gMoveActions, ref gGameplayActions, predictedDisplayTime)) {
			core.get().quit(0);
		}
	}

	override fn logic()
	{
		camRotation = math.Quatf.opCall(mCamHeading, mCamPitch, 0.0f);
		sum: math.Vector3f;

		if (mCamFore != mCamBack) {
			v: math.Vector3f;
			v.z = mCamBack ? 1.0f : -1.0f;
			sum += camRotation * v;
		}

		if (mCamLeft != mCamRight) {
			v: math.Vector3f;
			v.x = mCamRight ? 1.0f : -1.0f;
			sum += camRotation * v;
		}

		if (mCamUp) {
			sum.y += 1;
		}

		if (sum.lengthSqrd() != 0.f) {
			sum.normalize();
			sum.scale(camSpeed);
			camPosition += sum;
		}
	}

	override fn keyDown(ctl.Keyboard, keycode: int)
	{
		switch (keycode) {
		case 27: mManager.closeMe(this); break;
		case 32: mCamUp = true; break;
		case 'w': mCamFore = true; break;
		case 's': mCamBack = true; break;
		case 'a': mCamLeft = true; break;
		case 'd': mCamRight = true; break;
		case 'o': aa.toggle(); break;
		default:
		}
	}

	override fn keyUp(ctl.Keyboard, keycode: int)
	{
		switch (keycode) {
		case 32: mCamUp = false; break;
		case 'w': mCamFore = false; break;
		case 's': mCamBack = false; break;
		case 'a': mCamLeft = false; break;
		case 'd': mCamRight = false; break;
		default:
		}
	}

	override fn mouseMove(m: ctl.Mouse, x: int, y: int)
	{
		if (isDragging) {
			mCamHeading += x * -0.003f;
			mCamPitch += y * -0.003f;
		}

		if (mCamPitch < -(PIf/2)) mCamPitch = -(PIf/2);
		if (mCamPitch >  (PIf/2)) mCamPitch =  (PIf/2);
	}

	override fn mouseDown(m: ctl.Mouse, button: int)
	{
		switch (button) {
		case 1:
			m.setRelativeMode(true);
			isDragging = true;
			break;
		case 4: // Mouse wheel up.
			distance -= 0.1f;
			if (distance < 0.0f) {
				distance = 0.0f;
			}
			break;
		case 5: // Mouse wheel down.
			distance += 0.1f;
			break;
		default:
		}
	}

	override fn mouseUp(m: ctl.Mouse, button: int)
	{
		if (button == 1) {
			isDragging = false;
			m.setRelativeMode(false);
		}
	}
}
