// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Holds action related functions.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module virtual_ground.actions;

import amp.openxr;
import virtual_ground.program;


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
}

struct GameplayActions
{
	set: XrActionSet;

	grab: XrAction;
	quit: XrAction;
	aimPose: XrAction;
	gripPose: XrAction;
}

fn updateActions(p: Program) bool
{
	activeActionSet: XrActiveActionSet[2] = [
		{ p.gameplayActionSet, XR_NULL_PATH },
		{ p.move.set, XR_NULL_PATH },
	];

	syncInfo: XrActionsSyncInfo;
	syncInfo.type = XrStructureType.XR_TYPE_ACTIONS_SYNC_INFO;
	syncInfo.countActiveActionSets = cast(u32)activeActionSet.length;
	syncInfo.activeActionSets = activeActionSet.ptr;

	xrSyncActions(p.session, &syncInfo);

	getInfo: XrActionStateGetInfo;
	getInfo.type = XrStructureType.XR_TYPE_ACTION_STATE_GET_INFO;
	getInfo.action = p.quitAction;
	getInfo.subactionPath = XR_NULL_PATH;

	boolValue: XrActionStateBoolean;
	boolValue.type = XrStructureType.XR_TYPE_ACTION_STATE_BOOLEAN;

	xrGetActionStateBoolean(p.session, &getInfo, &boolValue);
	if (!boolValue.isActive) {
		p.log("Quit action not active!");
		return false;
	}
	if (boolValue.currentState) {
		p.log("Bye bye!");
		return false;
	}

	getInfo.action = p.move.triangle;
	xrGetActionStateBoolean(p.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Triangle");
	}

	getInfo.action = p.move.circle;
	xrGetActionStateBoolean(p.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Circle");
	}

	getInfo.action = p.move.cross;
	xrGetActionStateBoolean(p.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Cross");
	}

	getInfo.action = p.move.square;
	xrGetActionStateBoolean(p.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Square");
	}

	getInfo.action = p.move.start;
	xrGetActionStateBoolean(p.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Start");
	}

	getInfo.action = p.move.select;
	xrGetActionStateBoolean(p.session, &getInfo, &boolValue);
	if (boolValue.changedSinceLastSync && boolValue.currentState) {
		p.log("Select");
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

	xrStringToPath(p.instance, "/interaction_profiles/khr/simple_controller", &p.iProfKhrSimple);
	xrStringToPath(p.instance, "/interaction_profiles/google/daydream_controller", &p.iProfGoogleDaydream);
	xrStringToPath(p.instance, "/interaction_profiles/mnd/ball_on_stick_controller", &p.iProfMndBallOnStick);

	xrStringToPath(p.instance, "/user", &p.subPathUser);
	xrStringToPath(p.instance, "/user/hand/head", &p.subPathHead);
	xrStringToPath(p.instance, "/user/hand/left", &p.subPathLeft);
	xrStringToPath(p.instance, "/user/hand/right", &p.subPathRight);
	xrStringToPath(p.instance, "/user/hand/gamepad", &p.subPathGamePad);

	xrStringToPath(p.instance, "/user/hand/left/input/select", &selectPath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/select", &selectPath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/select/click", &selectClickPath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/select/click", &selectClickPath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/start/click", &startClickPath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/start/click", &startClickPath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/squeeze/value", &squeezeValuePath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/squeeze/value", &squeezeValuePath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/squeeze/click", &squeezeClickPath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/squeeze/click", &squeezeClickPath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/trigger/value", &triggerValuePath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/trigger/value", &triggerValuePath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/aim/pose", &aimPosePath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/aim/pose", &aimPosePath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/grip/pose", &gripPosePath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/grip/pose", &gripPosePath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/output/haptic", &hapticPath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/output/haptic", &hapticPath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/menu/click", &menuClickPath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/menu/click", &menuClickPath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/cross_mnd/click", &moveCrossClickPath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/cross_mnd/click", &moveCrossClickPath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/square_mnd/click", &moveSquareClickPath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/square_mnd/click", &moveSquareClickPath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/circle_mnd/click", &moveCircleClickPath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/circle_mnd/click", &moveCircleClickPath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/triangle_mnd/click", &moveTriangleClickPath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/triangle_mnd/click", &moveTriangleClickPath[Side.Right]);
	xrStringToPath(p.instance, "/user/hand/left/input/ball_mnd/pose", &moveBallPosePath[Side.Left]);
	xrStringToPath(p.instance, "/user/hand/right/input/ball_mnd/pose", &moveBallPosePath[Side.Right]);

	handSubactionPaths: XrPath[2] = [
		p.subPathLeft,
		p.subPathRight,
	];

	XrActionSetCreateInfo actionSetInfo;
	actionSetInfo.type = XrStructureType.XR_TYPE_ACTION_SET_CREATE_INFO;
	actionSetInfo.priority = 0;

	actionSetInfo.actionSetName[] = "gameplay";
	actionSetInfo.localizedActionSetName[] = "Gameplay";
	xrCreateActionSet(p.instance, &actionSetInfo, &p.gameplayActionSet);

	actionSetInfo.actionSetName[] = "move";
	actionSetInfo.localizedActionSetName[] = "Move Controller";
	xrCreateActionSet(p.instance, &actionSetInfo, &p.move.set);

	p.createFloat(p.gameplayActionSet, handSubactionPaths, "grab_object", "Grab Object", ref p.grabAction);
	p.createBoolean(p.gameplayActionSet, handSubactionPaths, "quit_session", "Quit Session", ref p.quitAction);
	p.createPose(p.gameplayActionSet, handSubactionPaths, "aim", "Aim Pose", ref p.aimPoseAction);
	p.createPose(p.gameplayActionSet, handSubactionPaths, "grip", "Grip Pose", ref p.gripPoseAction);
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
			{p.grabAction, selectPath[Side.Left]},
			{p.grabAction, selectPath[Side.Right]},
			{p.aimPoseAction, aimPosePath[Side.Left]},
			{p.aimPoseAction, aimPosePath[Side.Right]},
			{p.gripPoseAction, gripPosePath[Side.Left]},
			{p.gripPoseAction, gripPosePath[Side.Right]},
			{p.quitAction, menuClickPath[Side.Left]},
			{p.quitAction, menuClickPath[Side.Right]},
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
			{p.quitAction, menuClickPath[Side.Left]},
			{p.quitAction, menuClickPath[Side.Right]},
			{p.aimPoseAction, aimPosePath[Side.Left]},
			{p.aimPoseAction, aimPosePath[Side.Right]},
			{p.gripPoseAction, gripPosePath[Side.Left]},
			{p.gripPoseAction, gripPosePath[Side.Right]},
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
		p.gameplayActionSet,
		p.move.set,
	];

	attachInfo: XrSessionActionSetsAttachInfo;
	attachInfo.type = XrStructureType.XR_TYPE_SESSION_ACTION_SETS_ATTACH_INFO;
	attachInfo.countActionSets = cast(u32)actionSets.length;
	attachInfo.actionSets = actionSets.ptr;
	xrAttachSessionActionSets(p.session, &attachInfo);

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

	xrSuggestInteractionProfileBindings(p.instance, &suggestedBindings);
}