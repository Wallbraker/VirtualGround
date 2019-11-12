// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Holds action related functions.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.actions;

import amp.openxr;
import math = charge.math;

import ground.program;
import ground.gfx.scene;


struct MoveActions
{
	set: XrActionSet;

	start: XrAction;
	select: XrAction;
	cross: XrAction;
	triangle: XrAction;
	square: XrAction;
	circle: XrAction;

	ballPose: XrAction;
	ballSpace: XrSpace[2];
}

struct GameplayActions
{
	set: XrActionSet;

	grab: XrAction;
	quit: XrAction;
	aimPose: XrAction;
	aimSpace: XrSpace[2];
	gripPose: XrAction;
	gripSpace: XrSpace[2];
}

fn updateActions(p: Program, predictedDisplayTime: XrTime) bool
{
	activeActionSet: XrActiveActionSet[2] = [
		{ p.gameplay.set, XR_NULL_PATH },
		{ p.move.set, XR_NULL_PATH },
	];

	syncInfo: XrActionsSyncInfo;
	syncInfo.type = XrStructureType.XR_TYPE_ACTIONS_SYNC_INFO;
	syncInfo.countActiveActionSets = cast(u32)activeActionSet.length;
	syncInfo.activeActionSets = activeActionSet.ptr;

	xrSyncActions(p.oxr.session, &syncInfo);

	getInfo: XrActionStateGetInfo;
	getInfo.type = XrStructureType.XR_TYPE_ACTION_STATE_GET_INFO;
	getInfo.action = p.gameplay.quit;
	getInfo.subactionPath = XR_NULL_PATH;

	boolValue: XrActionStateBoolean;
	boolValue.type = XrStructureType.XR_TYPE_ACTION_STATE_BOOLEAN;

	xrGetActionStateBoolean(p.oxr.session, &getInfo, &boolValue);
	if (!boolValue.isActive) {
		p.log("Quit action not active!");
		return false;
	}
	if (boolValue.currentState) {
		return false;
	}

	getInfo.action = p.move.triangle;
	xrGetActionStateBoolean(p.oxr.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Triangle");
	}

	getInfo.action = p.move.circle;
	xrGetActionStateBoolean(p.oxr.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Circle");
	}

	getInfo.action = p.move.cross;
	xrGetActionStateBoolean(p.oxr.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Cross");
	}

	getInfo.action = p.move.square;
	xrGetActionStateBoolean(p.oxr.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Square");
	}

	getInfo.action = p.move.start;
	xrGetActionStateBoolean(p.oxr.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Start");
	}

	getInfo.action = p.move.select;
	xrGetActionStateBoolean(p.oxr.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Select");
	}

	spaceLocation: XrSpaceLocation;
	spaceLocation.type = XR_TYPE_SPACE_LOCATION;

	ret: XrResult;
	foreach (hand; 0 .. 2) {
		ret = xrLocateSpace(p.move.ballSpace[hand], p.oxr.space, predictedDisplayTime, &spaceLocation);
		if (ret != XR_SUCCESS) {
			gPsMvBall[hand].active = false;
			continue;
		}

		gPsMvBall[hand].active = true;
		gPsMvBall[hand].pos = *cast(math.Point3f*) &spaceLocation.pose.position;
	}

	foreach (hand; 0 .. 2) {
		ret = xrLocateSpace(p.gameplay.gripSpace[hand], p.oxr.space, predictedDisplayTime, &spaceLocation);
		if (ret != XR_SUCCESS) {
			gPsMvComplete[hand].active = false;
			gPsMvControllerOnly[hand].active = false;
			continue;
		}

		gPsMvComplete[hand].active = !gPsMvBall[hand].active;
		gPsMvComplete[hand].pos = *cast(math.Point3f*) &spaceLocation.pose.position;
		gPsMvComplete[hand].rot = *cast(math.Quatf*) &spaceLocation.pose.orientation;

		gPsMvControllerOnly[hand].active = gPsMvBall[hand].active;
		gPsMvControllerOnly[hand].pos = *cast(math.Point3f*) &spaceLocation.pose.position;
		gPsMvControllerOnly[hand].rot = *cast(math.Quatf*) &spaceLocation.pose.orientation;
	}

	return true;
}

enum Side : size_t
{
	Left = 0,
	Right = 1,
}

fn createActions(p: Program) bool
{
	selectPath: XrPath[2];
	squeezeValuePath: XrPath[2];
	squeezeClickPath: XrPath[2];
	triggerValuePath: XrPath[2];
	gripPosePath: XrPath[2];
	aimPosePath: XrPath[2];
	hapticPath: XrPath[2];
	menuClickPath: XrPath[2];
	startClickPath: XrPath[2];
	selectClickPath: XrPath[2];

	moveCrossClickPath: XrPath[2];
	moveSquareClickPath: XrPath[2];
	moveCircleClickPath: XrPath[2];
	moveTriangleClickPath: XrPath[2];
	moveBallPosePath: XrPath[2];

	xrStringToPath(p.oxr.instance, "/interaction_profiles/khr/simple_controller", &p.iProfKhrSimple);
	xrStringToPath(p.oxr.instance, "/interaction_profiles/google/daydream_controller", &p.iProfGoogleDaydream);
	xrStringToPath(p.oxr.instance, "/interaction_profiles/mnd/ball_on_stick_controller", &p.iProfMndBallOnStick);

	xrStringToPath(p.oxr.instance, "/user", &p.subPathUser);
	xrStringToPath(p.oxr.instance, "/user/hand/head", &p.subPathHead);
	xrStringToPath(p.oxr.instance, "/user/hand/left", &p.subPathLeft);
	xrStringToPath(p.oxr.instance, "/user/hand/right", &p.subPathRight);
	xrStringToPath(p.oxr.instance, "/user/hand/gamepad", &p.subPathGamePad);

	xrStringToPath(p.oxr.instance, "/user/hand/left/input/select", &selectPath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/select", &selectPath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/select/click", &selectClickPath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/select/click", &selectClickPath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/start/click", &startClickPath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/start/click", &startClickPath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/squeeze/value", &squeezeValuePath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/squeeze/value", &squeezeValuePath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/squeeze/click", &squeezeClickPath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/squeeze/click", &squeezeClickPath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/trigger/value", &triggerValuePath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/trigger/value", &triggerValuePath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/aim/pose", &aimPosePath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/aim/pose", &aimPosePath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/grip/pose", &gripPosePath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/grip/pose", &gripPosePath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/output/haptic", &hapticPath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/output/haptic", &hapticPath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/menu/click", &menuClickPath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/menu/click", &menuClickPath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/cross_mnd/click", &moveCrossClickPath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/cross_mnd/click", &moveCrossClickPath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/square_mnd/click", &moveSquareClickPath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/square_mnd/click", &moveSquareClickPath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/circle_mnd/click", &moveCircleClickPath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/circle_mnd/click", &moveCircleClickPath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/triangle_mnd/click", &moveTriangleClickPath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/triangle_mnd/click", &moveTriangleClickPath[Side.Right]);
	xrStringToPath(p.oxr.instance, "/user/hand/left/input/ball_mnd/pose", &moveBallPosePath[Side.Left]);
	xrStringToPath(p.oxr.instance, "/user/hand/right/input/ball_mnd/pose", &moveBallPosePath[Side.Right]);

	handSubactionPaths: XrPath[2] = [
		p.subPathLeft,
		p.subPathRight,
	];

	XrActionSetCreateInfo actionSetInfo;
	actionSetInfo.type = XrStructureType.XR_TYPE_ACTION_SET_CREATE_INFO;
	actionSetInfo.priority = 0;

	actionSetInfo.actionSetName[] = "gameplay";
	actionSetInfo.localizedActionSetName[] = "Gameplay";
	xrCreateActionSet(p.oxr.instance, &actionSetInfo, &p.gameplay.set);

	actionSetInfo.actionSetName[] = "move";
	actionSetInfo.localizedActionSetName[] = "Move Controller";
	xrCreateActionSet(p.oxr.instance, &actionSetInfo, &p.move.set);

	p.createFloat(p.gameplay.set, handSubactionPaths, "grab_object", "Grab Object", ref p.gameplay.grab);
	p.createBoolean(p.gameplay.set, handSubactionPaths, "quit_session", "Quit Session", ref p.gameplay.quit);
	p.createPose(p.gameplay.set, handSubactionPaths, "aim", "Aim Pose", ref p.gameplay.aimPose);
	p.createPose(p.gameplay.set, handSubactionPaths, "grip", "Grip Pose", ref p.gameplay.gripPose);
	p.createBoolean(p.move.set, handSubactionPaths, "start", "Start", ref p.move.start);
	p.createBoolean(p.move.set, handSubactionPaths, "select", "Select", ref p.move.select);
	p.createBoolean(p.move.set, handSubactionPaths, "triangle", "Triangle", ref p.move.triangle);
	p.createBoolean(p.move.set, handSubactionPaths, "circle", "Circle", ref p.move.circle);
	p.createBoolean(p.move.set, handSubactionPaths, "cross", "Cross", ref p.move.cross);
	p.createBoolean(p.move.set, handSubactionPaths, "square", "Square", ref p.move.square);
	p.createPose(p.move.set, handSubactionPaths, "ball", "Ball Pose", ref p.move.ballPose);


	// Simple Controller
	{
		bindings: XrActionSuggestedBinding[] = [
			{p.gameplay.grab, selectPath[Side.Left]},
			{p.gameplay.grab, selectPath[Side.Right]},
			{p.gameplay.aimPose, aimPosePath[Side.Left]},
			{p.gameplay.aimPose, aimPosePath[Side.Right]},
			{p.gameplay.gripPose, gripPosePath[Side.Left]},
			{p.gameplay.gripPose, gripPosePath[Side.Right]},
			{p.gameplay.quit, menuClickPath[Side.Left]},
			{p.gameplay.quit, menuClickPath[Side.Right]},
/*
			{p.vibrateAction, p.hapticPath[Side.Left]},
			{p.vibrateAction, p.hapticPath[Side.Right]}
*/
		];

		p.suggest(p.iProfKhrSimple, bindings);
	}

	// PlayStation Move
	{
		bindings: XrActionSuggestedBinding[] = [
			{p.gameplay.quit, menuClickPath[Side.Left]},
			{p.gameplay.quit, menuClickPath[Side.Right]},
			{p.gameplay.aimPose, aimPosePath[Side.Left]},
			{p.gameplay.aimPose, aimPosePath[Side.Right]},
			{p.gameplay.gripPose, gripPosePath[Side.Left]},
			{p.gameplay.gripPose, gripPosePath[Side.Right]},
/*
			{p.vibrateAction, p.hapticPath[Side.Left]},
			{p.vibrateAction, p.hapticPath[Side.Right]}
*/
			{p.move.start, startClickPath[Side.Left]},
			{p.move.start, startClickPath[Side.Right]},
			{p.move.select, selectClickPath[Side.Left]},
			{p.move.select, selectClickPath[Side.Right]},
			{p.move.triangle, moveTriangleClickPath[Side.Left]},
			{p.move.triangle, moveTriangleClickPath[Side.Right]},
			{p.move.circle, moveCircleClickPath[Side.Left]},
			{p.move.circle, moveCircleClickPath[Side.Right]},
			{p.move.cross, moveCrossClickPath[Side.Left]},
			{p.move.cross, moveCrossClickPath[Side.Right]},
			{p.move.square, moveSquareClickPath[Side.Left]},
			{p.move.square, moveSquareClickPath[Side.Right]},
			{p.move.ballPose, moveBallPosePath[Side.Left]},
			{p.move.ballPose, moveBallPosePath[Side.Right]},
		];

		p.suggest(p.iProfMndBallOnStick, bindings);
	}

	actionSets: XrActionSet[2] = [
		p.gameplay.set,
		p.move.set,
	];

	attachInfo: XrSessionActionSetsAttachInfo;
	attachInfo.type = XrStructureType.XR_TYPE_SESSION_ACTION_SETS_ATTACH_INFO;
	attachInfo.countActionSets = cast(u32)actionSets.length;
	attachInfo.actionSets = actionSets.ptr;
	xrAttachSessionActionSets(p.oxr.session, &attachInfo);


        actionSpaceInfo: XrActionSpaceCreateInfo;
        actionSpaceInfo.type = XR_TYPE_ACTION_SPACE_CREATE_INFO;
	actionSpaceInfo.poseInActionSpace.orientation.w = 1.f;

	// Pose action
	actionSpaceInfo.action = p.gameplay.gripPose;
	actionSpaceInfo.subactionPath = handSubactionPaths[0];
	xrCreateActionSpace(p.oxr.session, &actionSpaceInfo, &p.gameplay.gripSpace[0]);
	actionSpaceInfo.subactionPath = handSubactionPaths[1];
	xrCreateActionSpace(p.oxr.session, &actionSpaceInfo, &p.gameplay.gripSpace[1]);

	// Ball pose action
	actionSpaceInfo.action = p.move.ballPose;
	actionSpaceInfo.subactionPath = handSubactionPaths[0];
	xrCreateActionSpace(p.oxr.session, &actionSpaceInfo, &p.move.ballSpace[0]);
	actionSpaceInfo.subactionPath = handSubactionPaths[1];
	xrCreateActionSpace(p.oxr.session, &actionSpaceInfo, &p.move.ballSpace[1]);

	return true;
}



private:

fn createBoolean(p: Program,
                 actionSet: XrActionSet,
                 subactionPaths: scope XrPath[],
                 name: string,
                 localized: string,
                 ref action: XrAction) XrResult
{
	actionInfo: XrActionCreateInfo;
	actionInfo.type = XrStructureType.XR_TYPE_ACTION_CREATE_INFO;
	actionInfo.subactionPaths = subactionPaths.ptr;
	actionInfo.countSubactionPaths = cast(u32)subactionPaths.length;
	actionInfo.actionType = XrActionType.XR_ACTION_TYPE_BOOLEAN_INPUT;
	actionInfo.actionName[] = name;
	actionInfo.localizedActionName[] = localized;

	return xrCreateAction(actionSet, &actionInfo, &action);
}

fn createFloat(p: Program,
               actionSet: XrActionSet,
               subactionPaths: scope XrPath[],
               name: string,
               localized: string,
               ref action: XrAction) XrResult
{
	actionInfo: XrActionCreateInfo;
	actionInfo.type = XrStructureType.XR_TYPE_ACTION_CREATE_INFO;
	actionInfo.subactionPaths = subactionPaths.ptr;
	actionInfo.countSubactionPaths = cast(u32)subactionPaths.length;
	actionInfo.actionType = XrActionType.XR_ACTION_TYPE_FLOAT_INPUT;
	actionInfo.actionName[] = name;
	actionInfo.localizedActionName[] = localized;

	return xrCreateAction(actionSet, &actionInfo, &action);
}

fn createPose(p: Program,
              actionSet: XrActionSet,
              subactionPaths: scope XrPath[],
              name: string,
              localized: string,
              ref action: XrAction) XrResult
{
	actionInfo: XrActionCreateInfo;
	actionInfo.type = XrStructureType.XR_TYPE_ACTION_CREATE_INFO;
	actionInfo.subactionPaths = subactionPaths.ptr;
	actionInfo.countSubactionPaths = cast(u32)subactionPaths.length;
	actionInfo.actionType = XrActionType.XR_ACTION_TYPE_POSE_INPUT;
	actionInfo.actionName[] = name;
	actionInfo.localizedActionName[] = localized;

	return xrCreateAction(actionSet, &actionInfo, &action);
}

fn suggest(p: Program, profile: XrPath, bindings: scope XrActionSuggestedBinding[])
{
	XrInteractionProfileSuggestedBinding suggestedBindings;
	suggestedBindings.type =  XrStructureType.XR_TYPE_INTERACTION_PROFILE_SUGGESTED_BINDING;
	suggestedBindings.interactionProfile = profile;
	suggestedBindings.suggestedBindings = bindings.ptr;
	suggestedBindings.countSuggestedBindings = cast(u32)bindings.length;

	xrSuggestInteractionProfileBindings(p.oxr.instance, &suggestedBindings);
}