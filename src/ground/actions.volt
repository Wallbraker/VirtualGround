// Copyright 2019-2023, Collabora, Ltd.
// SPDX-License-Identifier: MIT OR Apache-2.0 OR BSL-1.0
/*!
 * @brief  Holds action related functions.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.actions;

import amp.openxr;
import math = charge.math;
import sys = charge.sys;

import charge.core.openxr : gOpenXR;
import charge.core.openxr.enumerate;

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

fn updateVoxelObject(ref obj: VoxelObject, ref loc: XrSpaceLocation)
{
	if ((loc.locationFlags & XrSpaceLocationFlags.XR_SPACE_LOCATION_POSITION_VALID_BIT) != 0) {
		obj.active = true;
		obj.pos = *cast(math.Point3f*) &loc.pose.position;
	} else {
		obj.active = false;
		obj.pos.x = 0.0f;
		obj.pos.y = 0.0f;
		obj.pos.z = 0.0f;
	}

	if ((loc.locationFlags & XrSpaceLocationFlags.XR_SPACE_LOCATION_ORIENTATION_VALID_BIT) != 0) {
		obj.rot = *cast(math.Quatf*) &loc.pose.orientation;
	} else {
		obj.rot.x = 0.0f;
		obj.rot.y = 0.0f;
		obj.rot.z = 0.0f;
		obj.rot.w = 1.0f;
	}
}

fn updateActions(ref move: MoveActions, ref gameplay: GameplayActions, predictedDisplayTime: XrTime) bool
{
	shouldShowQuad: bool = false;
	activeActionSet: XrActiveActionSet[2] = [
		{ gameplay.set, XR_NULL_PATH },
		{ move.set, XR_NULL_PATH },
	];

	syncInfo: XrActionsSyncInfo;
	syncInfo.type = XrStructureType.XR_TYPE_ACTIONS_SYNC_INFO;
	syncInfo.countActiveActionSets = cast(u32)activeActionSet.length;
	syncInfo.activeActionSets = activeActionSet.ptr;

	xrSyncActions(gOpenXR.session, &syncInfo);

	getInfo: XrActionStateGetInfo;
	getInfo.type = XrStructureType.XR_TYPE_ACTION_STATE_GET_INFO;
	getInfo.action = gameplay.quit;
	getInfo.subactionPath = XR_NULL_PATH;

	boolValue: XrActionStateBoolean;
	boolValue.type = XrStructureType.XR_TYPE_ACTION_STATE_BOOLEAN;

	logMessage := gOpenXR.headless;

	xrGetActionStateBoolean(gOpenXR.session, &getInfo, &boolValue);
	if (boolValue.isActive && boolValue.currentState) {
		if (logMessage) { gOpenXR.log("Quit!"); }
		return false;
	}


	getInfo.action = gameplay.grab;
	xrGetActionStateBoolean(gOpenXR.session, &getInfo, &boolValue);
	if (boolValue.isActive && boolValue.currentState) {
		if (logMessage) { gOpenXR.log("Grab!"); }
		shouldShowQuad = true;
	}

	getInfo.action = move.triangle;
	xrGetActionStateBoolean(gOpenXR.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		if (logMessage) { gOpenXR.log("Triangle"); }
		gOpenXR.log(new "Memory usage: ${sys.cMemoryUsage()}");
	}

	getInfo.action = move.circle;
	xrGetActionStateBoolean(gOpenXR.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		if (logMessage) { gOpenXR.log("Circle"); }
	}

	getInfo.action = move.cross;
	xrGetActionStateBoolean(gOpenXR.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		if (logMessage) { gOpenXR.log("Cross"); }
	}

	getInfo.action = move.square;
	xrGetActionStateBoolean(gOpenXR.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		if (logMessage) { gOpenXR.log("Square"); }
	}

	getInfo.action = move.start;
	xrGetActionStateBoolean(gOpenXR.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		if (logMessage) { gOpenXR.log("Start"); }
	}

	getInfo.action = move.select;
	xrGetActionStateBoolean(gOpenXR.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		if (logMessage) { gOpenXR.log("Select"); }
	}

	spaceLocation: XrSpaceLocation;
	spaceLocation.type = XR_TYPE_SPACE_LOCATION;

	ret: XrResult;
	paths: XrPath[2];
	baseSpace := gOpenXR.stageSpace;
	xrStringToPath(gOpenXR.instance, "/user/hand/left", &paths[0]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right", &paths[1]);

	foreach (hand; 0 .. 2) {
		// Is this hand active.
		if (!isPoseActive(move.ballPose, paths[hand])) {
			gPsMvBall[hand].active = false;
			continue;
		}

		ret = xrLocateSpace(move.ballSpace[hand], baseSpace, predictedDisplayTime, &spaceLocation);
		if (ret != XR_SUCCESS) {
			gPsMvBall[hand].active = false;
			continue;
		}

		gPsMvBall[hand].updateVoxelObject(ref spaceLocation);
	}

	foreach (hand; 0 .. 2) {
		// Is this hand active.
		if (!isPoseActive(gameplay.gripPose, paths[hand])) {
			gPsMvComplete[hand].active = false;
			gPsMvControllerOnly[hand].active = false;
			continue;
		}

		ret = xrLocateSpace(gameplay.gripSpace[hand], baseSpace, predictedDisplayTime, &spaceLocation);
		if (ret != XR_SUCCESS) {
			gPsMvComplete[hand].active = false;
			gPsMvControllerOnly[hand].active = false;
			continue;
		}

		gPsMvComplete[hand].updateVoxelObject(ref spaceLocation);
		gPsMvComplete[hand].active = !gPsMvBall[hand].active && gPsMvComplete[hand].active;

		gPsMvControllerOnly[hand].updateVoxelObject(ref spaceLocation);
		gPsMvControllerOnly[hand].active = gPsMvBall[hand].active && gPsMvControllerOnly[hand].active;

		gOpenXR.quadHack.pose.orientation = *cast(XrQuaternionf*) &gPsMvControllerOnly[hand].rot;
		gOpenXR.quadHack.pose.position = *cast(XrVector3f*) &gPsMvControllerOnly[hand].pos;
		gOpenXR.quadHack.active = shouldShowQuad;
	}

	ret = xrLocateSpace(gOpenXR.viewSpace, baseSpace, predictedDisplayTime, &spaceLocation);
	if (ret == XR_SUCCESS) {
		gViewSpace.pos = *cast(math.Point3f*) &spaceLocation.pose.position;
		gViewSpace.rot = *cast(math.Quatf*) &spaceLocation.pose.orientation;
	}

	if (!gOpenXR.headless) {
		return true;
	}

	if (ret == XR_SUCCESS) {
		gAxis[gOpenXR.views.length].active = true;
		gAxis[gOpenXR.views.length].pos = *cast(math.Point3f*) &spaceLocation.pose.position;
		gAxis[gOpenXR.views.length].rot = *cast(math.Quatf*) &spaceLocation.pose.orientation;
	}

	views: XrView[32];
	ret = enumViews(ref gOpenXR, baseSpace, predictedDisplayTime, ref views);
	if (ret == XR_SUCCESS) {
		foreach (i, ref view; gOpenXR.views) {
			gAxis[i].active = true;
			gAxis[i].pos = *cast(math.Point3f*) &views[i].pose.position;
			gAxis[i].rot = *cast(math.Quatf*) &views[i].pose.orientation;
		}
	}

	return true;
}

fn isPoseActive(pose: XrAction, subactionPath: XrPath) bool
{
	ret: XrResult;
	getInfo: XrActionStateGetInfo;
	getInfo.type = XrStructureType.XR_TYPE_ACTION_STATE_GET_INFO;
	getInfo.action = pose;
	getInfo.subactionPath = subactionPath;

	poseValue: XrActionStatePose;
	poseValue.type = XrStructureType.XR_TYPE_ACTION_STATE_POSE;

	ret = xrGetActionStatePose(gOpenXR.session, &getInfo, &poseValue);
	if (ret != XR_SUCCESS) {
		return false;
	}

	return poseValue.isActive == XR_TRUE;
}

enum Side : size_t
{
	Left = 0,
	Right = 1,
}

fn createActions(ref move: MoveActions, ref gameplay: GameplayActions) bool
{
	iProfKhrSimple: XrPath;
	iProfGoogleDaydream: XrPath;
	iProfMndxBallOnAStick: XrPath;

	subPathUser: XrPath;
	subPathHead: XrPath;
	subPathLeft: XrPath;
	subPathRight: XrPath;
	subPathGamePad: XrPath;

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

	xrStringToPath(gOpenXR.instance, "/interaction_profiles/khr/simple_controller", &iProfKhrSimple);
	xrStringToPath(gOpenXR.instance, "/interaction_profiles/google/daydream_controller", &iProfGoogleDaydream);
	xrStringToPath(gOpenXR.instance, "/interaction_profiles/mndx/ball_on_a_stick_controller", &iProfMndxBallOnAStick);

	xrStringToPath(gOpenXR.instance, "/user", &subPathUser);
	xrStringToPath(gOpenXR.instance, "/user/hand/head", &subPathHead);
	xrStringToPath(gOpenXR.instance, "/user/hand/left", &subPathLeft);
	xrStringToPath(gOpenXR.instance, "/user/hand/right", &subPathRight);
	xrStringToPath(gOpenXR.instance, "/user/hand/gamepad", &subPathGamePad);

	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/select", &selectPath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/select", &selectPath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/select/click", &selectClickPath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/select/click", &selectClickPath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/start/click", &startClickPath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/start/click", &startClickPath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/squeeze/value", &squeezeValuePath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/squeeze/value", &squeezeValuePath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/squeeze/click", &squeezeClickPath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/squeeze/click", &squeezeClickPath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/trigger/value", &triggerValuePath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/trigger/value", &triggerValuePath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/aim/pose", &aimPosePath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/aim/pose", &aimPosePath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/grip/pose", &gripPosePath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/grip/pose", &gripPosePath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/output/haptic", &hapticPath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/output/haptic", &hapticPath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/menu/click", &menuClickPath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/menu/click", &menuClickPath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/cross_mndx/click", &moveCrossClickPath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/cross_mndx/click", &moveCrossClickPath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/square_mndx/click", &moveSquareClickPath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/square_mndx/click", &moveSquareClickPath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/circle_mndx/click", &moveCircleClickPath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/circle_mndx/click", &moveCircleClickPath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/triangle_mndx/click", &moveTriangleClickPath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/triangle_mndx/click", &moveTriangleClickPath[Side.Right]);
	xrStringToPath(gOpenXR.instance, "/user/hand/left/input/ball_mndx/pose", &moveBallPosePath[Side.Left]);
	xrStringToPath(gOpenXR.instance, "/user/hand/right/input/ball_mndx/pose", &moveBallPosePath[Side.Right]);

	handSubactionPaths: XrPath[2] = [
		subPathLeft,
		subPathRight,
	];

	XrActionSetCreateInfo actionSetInfo;
	actionSetInfo.type = XrStructureType.XR_TYPE_ACTION_SET_CREATE_INFO;
	actionSetInfo.priority = 0;

	actionSetInfo.actionSetName[] = "gameplay";
	actionSetInfo.localizedActionSetName[] = "Gameplay";
	xrCreateActionSet(gOpenXR.instance, &actionSetInfo, &gameplay.set);

	actionSetInfo.actionSetName[] = "move";
	actionSetInfo.localizedActionSetName[] = "Move Controller";
	xrCreateActionSet(gOpenXR.instance, &actionSetInfo, &move.set);

	createBoolean(gameplay.set, handSubactionPaths, "grab_object", "Grab Object", ref gameplay.grab);
	createBoolean(gameplay.set, handSubactionPaths, "quit_session", "Quit Session", ref gameplay.quit);
	createPose(gameplay.set, handSubactionPaths, "aim", "Aim Pose", ref gameplay.aimPose);
	createPose(gameplay.set, handSubactionPaths, "grip", "Grip Pose", ref gameplay.gripPose);
	createBoolean(move.set, handSubactionPaths, "start", "Start", ref move.start);
	createBoolean(move.set, handSubactionPaths, "select", "Select", ref move.select);
	createBoolean(move.set, handSubactionPaths, "triangle", "Triangle", ref move.triangle);
	createBoolean(move.set, handSubactionPaths, "circle", "Circle", ref move.circle);
	createBoolean(move.set, handSubactionPaths, "cross", "Cross", ref move.cross);
	createBoolean(move.set, handSubactionPaths, "square", "Square", ref move.square);
	createPose(move.set, handSubactionPaths, "ball", "Ball Pose", ref move.ballPose);


	// Simple Controller
	{
		bindings: XrActionSuggestedBinding[] = [
			{gameplay.grab, selectPath[Side.Left]},
			{gameplay.grab, selectPath[Side.Right]},
			{gameplay.aimPose, aimPosePath[Side.Left]},
			{gameplay.aimPose, aimPosePath[Side.Right]},
			{gameplay.gripPose, gripPosePath[Side.Left]},
			{gameplay.gripPose, gripPosePath[Side.Right]},
			{gameplay.quit, menuClickPath[Side.Left]},
			{gameplay.quit, menuClickPath[Side.Right]},
/*
			{p.vibrateAction, p.hapticPath[Side.Left]},
			{p.vibrateAction, p.hapticPath[Side.Right]}
*/
		];

		suggest(iProfKhrSimple, bindings);
	}

	// PlayStation Move
	{
		bindings: XrActionSuggestedBinding[] = [
			{gameplay.quit, menuClickPath[Side.Left]},
			{gameplay.quit, menuClickPath[Side.Right]},
			{gameplay.grab, triggerValuePath[Side.Left]},
			{gameplay.grab, triggerValuePath[Side.Right]},
			{gameplay.aimPose, aimPosePath[Side.Left]},
			{gameplay.aimPose, aimPosePath[Side.Right]},
			{gameplay.gripPose, gripPosePath[Side.Left]},
			{gameplay.gripPose, gripPosePath[Side.Right]},
/*
			{p.vibrateAction, p.hapticPath[Side.Left]},
			{p.vibrateAction, p.hapticPath[Side.Right]}
*/
			{move.start, startClickPath[Side.Left]},
			{move.start, startClickPath[Side.Right]},
			{move.select, selectClickPath[Side.Left]},
			{move.select, selectClickPath[Side.Right]},
			{move.triangle, moveTriangleClickPath[Side.Left]},
			{move.triangle, moveTriangleClickPath[Side.Right]},
			{move.circle, moveCircleClickPath[Side.Left]},
			{move.circle, moveCircleClickPath[Side.Right]},
			{move.cross, moveCrossClickPath[Side.Left]},
			{move.cross, moveCrossClickPath[Side.Right]},
			{move.square, moveSquareClickPath[Side.Left]},
			{move.square, moveSquareClickPath[Side.Right]},
			{move.ballPose, moveBallPosePath[Side.Left]},
			{move.ballPose, moveBallPosePath[Side.Right]},
		];

		suggest(iProfMndxBallOnAStick, bindings);
	}

	actionSets: XrActionSet[2] = [
		gameplay.set,
		move.set,
	];

	attachInfo: XrSessionActionSetsAttachInfo;
	attachInfo.type = XrStructureType.XR_TYPE_SESSION_ACTION_SETS_ATTACH_INFO;
	attachInfo.countActionSets = cast(u32)actionSets.length;
	attachInfo.actionSets = actionSets.ptr;
	xrAttachSessionActionSets(gOpenXR.session, &attachInfo);

	actionSpaceInfo: XrActionSpaceCreateInfo;
	actionSpaceInfo.type = XR_TYPE_ACTION_SPACE_CREATE_INFO;
	actionSpaceInfo.poseInActionSpace.orientation.x = -0.7071068f;
	actionSpaceInfo.poseInActionSpace.orientation.w = 0.7071068f;

	// Pose action
	actionSpaceInfo.action = gameplay.gripPose;
	actionSpaceInfo.subactionPath = handSubactionPaths[0];
	xrCreateActionSpace(gOpenXR.session, &actionSpaceInfo, &gameplay.gripSpace[0]);
	actionSpaceInfo.subactionPath = handSubactionPaths[1];
	xrCreateActionSpace(gOpenXR.session, &actionSpaceInfo, &gameplay.gripSpace[1]);

	// Ball pose action
	actionSpaceInfo.action = move.ballPose;
	actionSpaceInfo.subactionPath = handSubactionPaths[0];
	xrCreateActionSpace(gOpenXR.session, &actionSpaceInfo, &move.ballSpace[0]);
	actionSpaceInfo.subactionPath = handSubactionPaths[1];
	xrCreateActionSpace(gOpenXR.session, &actionSpaceInfo, &move.ballSpace[1]);

	return true;
}



private:

fn createBoolean(actionSet: XrActionSet,
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

fn createFloat(actionSet: XrActionSet,
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

fn createPose(actionSet: XrActionSet,
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

fn suggest(profile: XrPath, bindings: scope XrActionSuggestedBinding[])
{
	XrInteractionProfileSuggestedBinding suggestedBindings;
	suggestedBindings.type =  XrStructureType.XR_TYPE_INTERACTION_PROFILE_SUGGESTED_BINDING;
	suggestedBindings.interactionProfile = profile;
	suggestedBindings.suggestedBindings = bindings.ptr;
	suggestedBindings.countSuggestedBindings = cast(u32)bindings.length;

	xrSuggestInteractionProfileBindings(gOpenXR.instance, &suggestedBindings);
}