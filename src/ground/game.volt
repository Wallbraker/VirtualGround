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

import charge.core.openxr : Mode, gOpenXR;
import charge.core.openxr.core : CoreOpenXR;

import ground.gfx;
import ground.actions;

import io = watt.io;

alias wfln = io.writefln;

global gMoveActions: MoveActions;
global gGameplayActions: GameplayActions;

/*!
 * Very small wrapper class to show the scene without OpenXR.
 */
class Game : scene.ManagerApp
{
public:
	this(args: string[])
	{
		// First init core.
		opts := new .core.Options();
		opts.width = 1920;
		opts.height = 1080;

		mode := Mode.Normal;
		switch (args.length >= 2 ? args[1] : "normal") {
		case "normal": mode = Mode.Normal; break;
		case "ar": mode = Mode.Ar; break;
		case "overlay": mode = Mode.Overlay; break;
		case "headless": mode = Mode.Headless; break;
		default: mode = Mode.Normal; break;
		}

		if (args.length == 1) {
			wfln("Please provide a argument:");
			wfln("\t%s <mode>", args[0]);
			wfln("");
			wfln("\tnormal   - VR Mode");
			wfln("\tar       - AR Mode");
			wfln("\toverlay  - Overlay mode");
			wfln("\theadless - Headless");
			wfln("");
			super();
			.core.get().quit(1);
			return;
		}

		core := new CoreOpenXR(opts, mode);

		super(core);

		s := new MainScene(this, mode);
		push(s);

		createActions(ref gMoveActions, ref gGameplayActions);
	}
}

/*!
 * Very small wrapper class to show the scene without OpenXR.
 */
class MainScene : scene.Simple
{
public:
	s: Scene;

	enum CamSpeed: f32[3] = [
		0.002f,
		0.01f,
		0.03f,
	];


protected:
	// XR Mode.
	mMode: Mode;

	// AA, only used for headless.
	mAA: gfx.AA;

	// Rotation stuff.
	mIsDragging: bool;
	camPosition: math.Point3f;
	camRotation: math.Quatf;
	mCamHeading, mCamPitch, mDistance: f32;
	mCamDown, mCamUp, mCamFore, mCamBack, mCamLeft, mCamRight, mCamSlow, mCamFast: bool;


public:
	this(app: scene.ManagerApp, mode: Mode)
	{
		super(app, Type.Game);
		this.s = new Scene();

		this.mMode = mode;
		if (mMode == Mode.Headless) {
			mAA.kind = gfx.AA.Kind.MSAA4;
		} else {
			mAA.kind = gfx.AA.Kind.None;
		}

		camRotation = math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);
		camPosition = math.Point3f.opCall(0.0f, 1.6f, 0.0f);
	}

	override fn render(t: gfx.Target, ref viewInfo: gfx.ViewInfo)
	{
		if (mMode == Mode.Headless) {
			viewInfo.ensureValidFov(85, t);
			viewInfo.position = camPosition;
			viewInfo.rotation = camRotation;
		}

		// Always use the AA, it supports non-aa.
		mAA.bind(t);
		s.renderView(mAA.fbo, ref viewInfo);
		mAA.resolveToAndBind(t);
	}

	override fn close()
	{
		mAA.close();
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
		if (mCamDown) {
			sum.y -= 1;
		}

		speedIndex := mCamFast - mCamSlow + 1;
		speed := CamSpeed[speedIndex];

		if (sum.lengthSqrd() != 0.f) {
			sum.normalize();
			sum.scale(speed);
			camPosition += sum;
		}
	}

	override fn keyDown(ctl.Keyboard, keycode: int)
	{
		switch (keycode) {
		case 27: mManager.closeMe(this); break;
		case 'w': mCamFore = true; break;
		case 's': mCamBack = true; break;
		case 'a': mCamLeft = true; break;
		case 'd': mCamRight = true; break;
		case 32, 'q': mCamUp = true; break;
		case 'e', 'z': mCamDown = true; break;
		case 'o': mAA.toggle(); break;
		case (224 | 1 << 30), (228 | 1 << 30): mCamSlow = true; break;
		case (225 | 1 << 30), (229 | 1 << 30): mCamFast = true; break;
		default:
		}
	}

	override fn keyUp(ctl.Keyboard, keycode: int)
	{
		switch (keycode) {
		case 'w': mCamFore = false; break;
		case 's': mCamBack = false; break;
		case 'a': mCamLeft = false; break;
		case 'd': mCamRight = false; break;
		case 32, 'q': mCamUp = false; break;
		case 'e', 'z': mCamDown = false; break;
		case (224 | 1 << 30), (228 | 1 << 30): mCamSlow = false; break;
		case (225 | 1 << 30), (229 | 1 << 30): mCamFast = false; break;
		default:
		}
	}

	override fn mouseMove(m: ctl.Mouse, x: int, y: int)
	{
		if (mIsDragging) {
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
			mIsDragging = true;
			break;
		case 4: // Mouse wheel up.
			mDistance -= 0.1f;
			if (mDistance < 0.0f) {
				mDistance = 0.0f;
			}
			break;
		case 5: // Mouse wheel down.
			mDistance += 0.1f;
			break;
		default:
		}
	}

	override fn mouseUp(m: ctl.Mouse, button: int)
	{
		if (button == 1) {
			mIsDragging = false;
			m.setRelativeMode(false);
		}
	}
}
