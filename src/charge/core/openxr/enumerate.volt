// Copyright 2019-2023, Collabora, Ltd.
// SPDX-License-Identifier: MIT OR Apache-2.0 OR BSL-1.0
/*!
 * @brief  Holds enumartion related functions.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module charge.core.openxr.enumerate;

import lib.gl.gl33 : GLuint;
import amp.openxr;
import charge.core.openxr;


fn enumExtensionProps(ref oxr: OpenXR, out outExtProps: XrExtensionProperties[]) XrResult
{
	XrResult ret;
	num: u32;

	ret = xrEnumerateInstanceExtensionProperties(null, 0, &num, null);
	if (ret != XR_SUCCESS) {
		oxr.log("xrEnumerateInstanceExtensionProperties failed (call 1)!");
		return ret;
	}

	extProps := new XrExtensionProperties[](num);
	foreach (ref extProp; extProps) {
		extProp.type = XR_TYPE_EXTENSION_PROPERTIES;
	}

	ret = xrEnumerateInstanceExtensionProperties(null, num, &num, extProps.ptr);
	if (ret != XR_SUCCESS) {
		oxr.log("xrEnumerateInstanceExtensionProperties failed (call 2)!");
		return ret;
	}

	outExtProps = extProps;

	return XR_SUCCESS;
}

fn enumEnvironmentBlendModes(ref oxr: OpenXR, viewConfigurationType: XrViewConfigurationType, out outEnvBlendModes: XrEnvironmentBlendMode[]) XrResult
{
	XrResult ret;
	num: u32;

	ret = xrEnumerateEnvironmentBlendModes(oxr.instance, oxr.systemId, viewConfigurationType, 0, &num, null);
	if (ret != XR_SUCCESS) {
		oxr.log("xrEnumerateEnvironmentBlendModes failed (call 1)!");
		return ret;
	}

	envBlendModes := new XrEnvironmentBlendMode[](num);
	ret = xrEnumerateEnvironmentBlendModes(oxr.instance, oxr.systemId, viewConfigurationType, num, &num, envBlendModes.ptr);
	if (ret != XR_SUCCESS) {
		oxr.log("xrEnumerateEnvironmentBlendModes failed (call 2)!");
		return ret;
	}

	outEnvBlendModes = envBlendModes;

	return XR_SUCCESS;
}

fn enumViewConfigurationViews(ref oxr: OpenXR, out outViewConfigs: XrViewConfigurationView[]) XrResult
{
	XrResult ret;
	num: u32;

	ret = xrEnumerateViewConfigurationViews(oxr.instance, oxr.systemId, oxr.viewConfigType, 0, &num, null);
	if (ret != XR_SUCCESS) {
		oxr.log("xrEnumerateViewConfigurationViews failed (call 1)!");
		return ret;
	}

	viewConfigs := new XrViewConfigurationView[](num);
	foreach (ref view; viewConfigs) {
		view.type = XR_TYPE_VIEW_CONFIGURATION_VIEW;
	}

	ret = xrEnumerateViewConfigurationViews(oxr.instance, oxr.systemId, oxr.viewConfigType, num, &num, viewConfigs.ptr);
	if (ret != XR_SUCCESS) {
		oxr.log("xrEnumerateViewConfigurationViews failed (call 2)!");
		return ret;
	}

	outViewConfigs = viewConfigs;

	return XR_SUCCESS;
}

fn enumSwapchainImages(ref oxr: OpenXR, handle: XrSwapchain, out outTextures: GLuint[]) XrResult
{
	XrResult ret;
	num: u32;

	ret = xrEnumerateSwapchainImages(handle, 0, &num, null);
	if (ret != XR_SUCCESS) {
		oxr.log("xrEnumerateSwapchainImages(GL) failed (call 1)!");
		return ret;
	}

	images := new XrSwapchainImageOpenGLKHR[](num);
	foreach (ref image; images) {
		image.type = XR_TYPE_SWAPCHAIN_IMAGE_OPENGL_KHR;
	}

	ptr := cast(XrSwapchainImageBaseHeader*)images.ptr;
	ret = xrEnumerateSwapchainImages(handle, num, &num, ptr);
	if (ret != XR_SUCCESS) {
		oxr.log("xrEnumerateSwapchainImages(GL) failed (call 2)!");
		return ret;
	}

	textures := new GLuint[](num);
	foreach (i, ref texture; textures) {
		texture = images[i].image;
	}

	outTextures = textures;

	return XR_SUCCESS;
}


fn enumViews(ref oxr: OpenXR, baseSpace: XrSpace, predictedDisplayTime: XrTime, ref views: XrView[32]) XrResult
{
	ret: XrResult;

	viewLocateInfo: XrViewLocateInfo;
	viewLocateInfo.type = XR_TYPE_VIEW_LOCATE_INFO;
	viewLocateInfo.viewConfigurationType = oxr.viewConfigType;
	viewLocateInfo.displayTime = predictedDisplayTime;
	viewLocateInfo.space = baseSpace;

	viewState: XrViewState;
	viewState.type = XR_TYPE_VIEW_STATE;

	viewCountOutput: u32;
	ret = xrLocateViews(oxr.session, &viewLocateInfo, &viewState, 0, &viewCountOutput, null);
	if (ret != XR_SUCCESS) {
		oxr.log("xrLocateViews failed");
		return ret;
	}
	if (views.length < viewCountOutput) {
		oxr.log("Way too many views");
		return XR_ERROR_VALIDATION_FAILURE;
	}

	viewCapacityInput := cast(u32)views.length;

	// Must be set.
	foreach (ref view; views[0 .. viewCapacityInput]) {
		view.type = XR_TYPE_VIEW;
	}

	ret = xrLocateViews(oxr.session, &viewLocateInfo, &viewState, viewCapacityInput, &viewCountOutput, views.ptr);
	if (ret != XR_SUCCESS) {
		oxr.log("xrLocateViews failed");
		return ret;
	}

	return XR_SUCCESS;
}
