// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Main loop function.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.openxr.loop;

import lib.gl.gl45;
import amp.openxr;

import gfx = charge.gfx;
import math = charge.math;
import oxr = charge.core.openxr;

import ground.program;
import ground.gfx.scene;


fn loop(ref oxr: oxr.OpenXR, scene: Scene)
{
	while (oxr.oneLoop(scene.renderView));
}

fn oneLoop(ref oxr: oxr.OpenXR, render: dg(t: gfx.Target, ref viewInfo: gfx.ViewInfo)) bool
{
	defTarget := gfx.DefaultTarget.opCall();
	ret: XrResult;
	predictedDisplayTime: XrTime;

	ret = oxr.waitFrame(out predictedDisplayTime);
	if (ret != XR_SUCCESS) {
		// Already logged.
		return false;
	}

	// We have a new preditcted time, get the swapchains ready.
	foreach (ref view; oxr.views) {
		oxr.acquireAndWaitViewImage(ref view);
	}

	// Returns false if we should quit.
	if (!oxr.updateActions(predictedDisplayTime)) {
		return false;
	}

	ret = oxr.getViewLocation(predictedDisplayTime);
	if (ret != XR_SUCCESS) {
		// Already logged.
		return false;
	}

	// Swapchains are now ready, signal that we are starting to render.
	ret = xrBeginFrame(oxr.session, null);
	if (ret != XR_SUCCESS) {
		oxr.log("xrBeginFrame failed!");
		return false;
	}

	releaseInfo: XrSwapchainImageReleaseInfo;
	releaseInfo.type = XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO;

	layerViews: XrCompositionLayerProjectionView[2];

	// This is where we render each view.
	foreach (i, ref view; oxr.views) {
		glViewport(0, 0, cast(GLsizei)view.width, cast(GLsizei)view.height);

		viewInfo: gfx.ViewInfo;
		viewInfo.validFov = true;
		viewInfo.validLocation = true;
		viewInfo.fov = *cast(math.Fovf*)&view.location.fov;
		viewInfo.position = *cast(math.Point3f*)&view.location.pose.position;
		viewInfo.rotation = *cast(math.Quatf*)&view.location.pose.orientation;

		target := view.targets[view.current_index];
		target.bind(defTarget);

		// This is where we render!
		render(target, ref viewInfo);

		xrReleaseSwapchainImage(view.swapchain, &releaseInfo);
		view.current_index = 0xffff_ffff_u32;

		layerViews[i].type = XR_TYPE_COMPOSITION_LAYER_PROJECTION_VIEW;
		layerViews[i].pose = view.location.pose;
		layerViews[i].fov = view.location.fov;
		layerViews[i].subImage.swapchain = view.swapchain;
		layerViews[i].subImage.imageRect.offset.x = 0;
		layerViews[i].subImage.imageRect.offset.y = 0;
		layerViews[i].subImage.imageRect.extent.width = cast(i32)view.width;
		layerViews[i].subImage.imageRect.extent.height = cast(i32)view.height;
	}

	layer: XrCompositionLayerProjection;
	layer.type = XR_TYPE_COMPOSITION_LAYER_PROJECTION;
	layer.viewCount = cast(u32)layerViews.length;
	layer.views = layerViews.ptr;

	layers: XrCompositionLayerBaseHeader*[1];
	layers[0] = cast(XrCompositionLayerBaseHeader*)&layer;

	endFrame: XrFrameEndInfo;
	endFrame.type = XR_TYPE_FRAME_END_INFO;
	endFrame.displayTime = predictedDisplayTime;
	endFrame.environmentBlendMode = oxr.blendMode;
	endFrame.layerCount = cast(u32)layers.length;
	endFrame.layers = layers.ptr;

	xrEndFrame(oxr.session, &endFrame);

	return true;
}

fn waitFrame(ref oxr: oxr.OpenXR, out predictedDisplayTime: XrTime) XrResult
{
	ret: XrResult;

	frameState: XrFrameState;
	frameState.type = XR_TYPE_FRAME_STATE;

	ret = xrWaitFrame(oxr.session, null, &frameState);
	if (ret != XR_SUCCESS) {
		oxr.log("xrWaitFrame failed!");
		return ret;
	}

	predictedDisplayTime = frameState.predictedDisplayTime;

	return XR_SUCCESS;
}

fn acquireAndWaitViewImage(ref oxr: oxr.OpenXR, ref view: oxr.View) XrResult
{
	ret: XrResult;

	acquireInfo: XrSwapchainImageAcquireInfo;
	acquireInfo.type = XR_TYPE_SWAPCHAIN_IMAGE_ACQUIRE_INFO;
	ret = xrAcquireSwapchainImage(view.swapchain, &acquireInfo, &view.current_index);
	if (ret != XR_SUCCESS) {
		oxr.log("xrAcquireSwapchainImage failed!");
		return ret;
	}

	waitInfo: XrSwapchainImageWaitInfo;
	waitInfo.type = XR_TYPE_SWAPCHAIN_IMAGE_WAIT_INFO;
	waitInfo.timeout = XR_INFINITE_DURATION;
	ret = xrWaitSwapchainImage(view.swapchain, &waitInfo);
	if (ret != XR_SUCCESS) {
		oxr.log("xrWaitSwapchainImage failed!");
		return ret;
	}

	return XR_SUCCESS;
}

fn getViewLocation(ref oxr: oxr.OpenXR, predictedDisplayTime: XrTime) XrResult
{
	ret: XrResult;
	views: XrView[32];

	viewLocateInfo: XrViewLocateInfo;
	viewLocateInfo.type = XR_TYPE_VIEW_LOCATE_INFO;
	viewLocateInfo.viewConfigurationType = oxr.viewConfigType;
	viewLocateInfo.displayTime = predictedDisplayTime;
	viewLocateInfo.space = oxr.space;

	viewState: XrViewState;
	viewState.type = XR_TYPE_VIEW_STATE;

	viewCountOutput: u32;
	ret = xrLocateViews(oxr.session, &viewLocateInfo, &viewState, 0, &viewCountOutput, null);
	if (ret != XR_SUCCESS) {
		oxr.log("xrLocateViews failed");
		return ret;
	}
	if (views.length < viewCountOutput) {
		oxr.log("Way to main views");
		return XR_ERROR_VALIDATION_FAILURE;
	}

	viewCapacityInput := cast(u32)views.length;
	ret = xrLocateViews(oxr.session, &viewLocateInfo, &viewState, viewCapacityInput, &viewCountOutput, views.ptr);
	if (ret != XR_SUCCESS) {
		oxr.log("xrLocateViews failed");
		return ret;
	}

	foreach (i, ref view; oxr.views) {
		view.location = views[i];
	}

	return XR_SUCCESS;
}
