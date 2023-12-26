// Copyright 2019-2023, Collabora, Ltd.
// SPDX-License-Identifier: MIT OR Apache-2.0 OR BSL-1.0
/*!
 * @brief  Loader functions.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module amp.openxr.loader;

import amp.openxr;
import watt = [watt.library];


fn loadLoader() watt.Library
{
	version (Linux) {
		return watt.Library.load("libopenxr_loader.so.1");
	} else version (Windows) {
		return watt.Library.load("openxr_loader.dll");
	} else {
		return null;
	}
}

fn loadRuntimeFuncs(l: dg(string) void*) bool
{
	xrGetInstanceProcAddr = cast(typeof(xrGetInstanceProcAddr))l("xrGetInstanceProcAddr");
	xrGetInstanceProcAddr(null, "xrEnumerateApiLayerProperties".ptr, cast(PFN_xrVoidFunction*)&xrEnumerateApiLayerProperties);
	xrGetInstanceProcAddr(null, "xrEnumerateInstanceExtensionProperties".ptr, cast(PFN_xrVoidFunction*)&xrEnumerateInstanceExtensionProperties);
	xrGetInstanceProcAddr(null, "xrCreateInstance".ptr, cast(PFN_xrVoidFunction*)&xrCreateInstance);

	return true;
}

fn loadInstanceFunctions(instance: XrInstance) bool
{
	xrGetInstanceProcAddr(instance, "xrDestroyInstance".ptr, cast(PFN_xrVoidFunction*)&xrDestroyInstance);
	xrGetInstanceProcAddr(instance, "xrGetInstanceProperties".ptr, cast(PFN_xrVoidFunction*)&xrGetInstanceProperties);
	xrGetInstanceProcAddr(instance, "xrPollEvent".ptr, cast(PFN_xrVoidFunction*)&xrPollEvent);
	xrGetInstanceProcAddr(instance, "xrResultToString".ptr, cast(PFN_xrVoidFunction*)&xrResultToString);
	xrGetInstanceProcAddr(instance, "xrStructureTypeToString".ptr, cast(PFN_xrVoidFunction*)&xrStructureTypeToString);
	xrGetInstanceProcAddr(instance, "xrGetSystem".ptr, cast(PFN_xrVoidFunction*)&xrGetSystem);
	xrGetInstanceProcAddr(instance, "xrGetSystemProperties".ptr, cast(PFN_xrVoidFunction*)&xrGetSystemProperties);
	xrGetInstanceProcAddr(instance, "xrEnumerateEnvironmentBlendModes".ptr, cast(PFN_xrVoidFunction*)&xrEnumerateEnvironmentBlendModes);
	xrGetInstanceProcAddr(instance, "xrCreateSession".ptr, cast(PFN_xrVoidFunction*)&xrCreateSession);
	xrGetInstanceProcAddr(instance, "xrDestroySession".ptr, cast(PFN_xrVoidFunction*)&xrDestroySession);
	xrGetInstanceProcAddr(instance, "xrEnumerateReferenceSpaces".ptr, cast(PFN_xrVoidFunction*)&xrEnumerateReferenceSpaces);
	xrGetInstanceProcAddr(instance, "xrCreateReferenceSpace".ptr, cast(PFN_xrVoidFunction*)&xrCreateReferenceSpace);
	xrGetInstanceProcAddr(instance, "xrGetReferenceSpaceBoundsRect".ptr, cast(PFN_xrVoidFunction*)&xrGetReferenceSpaceBoundsRect);
	xrGetInstanceProcAddr(instance, "xrCreateActionSpace".ptr, cast(PFN_xrVoidFunction*)&xrCreateActionSpace);
	xrGetInstanceProcAddr(instance, "xrLocateSpace".ptr, cast(PFN_xrVoidFunction*)&xrLocateSpace);
	xrGetInstanceProcAddr(instance, "xrDestroySpace".ptr, cast(PFN_xrVoidFunction*)&xrDestroySpace);
	xrGetInstanceProcAddr(instance, "xrEnumerateViewConfigurations".ptr, cast(PFN_xrVoidFunction*)&xrEnumerateViewConfigurations);
	xrGetInstanceProcAddr(instance, "xrGetViewConfigurationProperties".ptr, cast(PFN_xrVoidFunction*)&xrGetViewConfigurationProperties);
	xrGetInstanceProcAddr(instance, "xrEnumerateViewConfigurationViews".ptr, cast(PFN_xrVoidFunction*)&xrEnumerateViewConfigurationViews);
	xrGetInstanceProcAddr(instance, "xrEnumerateSwapchainFormats".ptr, cast(PFN_xrVoidFunction*)&xrEnumerateSwapchainFormats);
	xrGetInstanceProcAddr(instance, "xrCreateSwapchain".ptr, cast(PFN_xrVoidFunction*)&xrCreateSwapchain);
	xrGetInstanceProcAddr(instance, "xrDestroySwapchain".ptr, cast(PFN_xrVoidFunction*)&xrDestroySwapchain);
	xrGetInstanceProcAddr(instance, "xrEnumerateSwapchainImages".ptr, cast(PFN_xrVoidFunction*)&xrEnumerateSwapchainImages);
	xrGetInstanceProcAddr(instance, "xrAcquireSwapchainImage".ptr, cast(PFN_xrVoidFunction*)&xrAcquireSwapchainImage);
	xrGetInstanceProcAddr(instance, "xrWaitSwapchainImage".ptr, cast(PFN_xrVoidFunction*)&xrWaitSwapchainImage);
	xrGetInstanceProcAddr(instance, "xrReleaseSwapchainImage".ptr, cast(PFN_xrVoidFunction*)&xrReleaseSwapchainImage);
	xrGetInstanceProcAddr(instance, "xrBeginSession".ptr, cast(PFN_xrVoidFunction*)&xrBeginSession);
	xrGetInstanceProcAddr(instance, "xrEndSession".ptr, cast(PFN_xrVoidFunction*)&xrEndSession);
	xrGetInstanceProcAddr(instance, "xrRequestExitSession".ptr, cast(PFN_xrVoidFunction*)&xrRequestExitSession);
	xrGetInstanceProcAddr(instance, "xrWaitFrame".ptr, cast(PFN_xrVoidFunction*)&xrWaitFrame);
	xrGetInstanceProcAddr(instance, "xrBeginFrame".ptr, cast(PFN_xrVoidFunction*)&xrBeginFrame);
	xrGetInstanceProcAddr(instance, "xrEndFrame".ptr, cast(PFN_xrVoidFunction*)&xrEndFrame);
	xrGetInstanceProcAddr(instance, "xrLocateViews".ptr, cast(PFN_xrVoidFunction*)&xrLocateViews);
	xrGetInstanceProcAddr(instance, "xrStringToPath".ptr, cast(PFN_xrVoidFunction*)&xrStringToPath);
	xrGetInstanceProcAddr(instance, "xrPathToString".ptr, cast(PFN_xrVoidFunction*)&xrPathToString);
	xrGetInstanceProcAddr(instance, "xrCreateActionSet".ptr, cast(PFN_xrVoidFunction*)&xrCreateActionSet);
	xrGetInstanceProcAddr(instance, "xrDestroyActionSet".ptr, cast(PFN_xrVoidFunction*)&xrDestroyActionSet);
	xrGetInstanceProcAddr(instance, "xrCreateAction".ptr, cast(PFN_xrVoidFunction*)&xrCreateAction);
	xrGetInstanceProcAddr(instance, "xrDestroyAction".ptr, cast(PFN_xrVoidFunction*)&xrDestroyAction);
	xrGetInstanceProcAddr(instance, "xrSuggestInteractionProfileBindings".ptr, cast(PFN_xrVoidFunction*)&xrSuggestInteractionProfileBindings);
	xrGetInstanceProcAddr(instance, "xrAttachSessionActionSets".ptr, cast(PFN_xrVoidFunction*)&xrAttachSessionActionSets);
	xrGetInstanceProcAddr(instance, "xrGetCurrentInteractionProfile".ptr, cast(PFN_xrVoidFunction*)&xrGetCurrentInteractionProfile);
	xrGetInstanceProcAddr(instance, "xrGetActionStateBoolean".ptr, cast(PFN_xrVoidFunction*)&xrGetActionStateBoolean);
	xrGetInstanceProcAddr(instance, "xrGetActionStateFloat".ptr, cast(PFN_xrVoidFunction*)&xrGetActionStateFloat);
	xrGetInstanceProcAddr(instance, "xrGetActionStateVector2f".ptr, cast(PFN_xrVoidFunction*)&xrGetActionStateVector2f);
	xrGetInstanceProcAddr(instance, "xrGetActionStatePose".ptr, cast(PFN_xrVoidFunction*)&xrGetActionStatePose);
	xrGetInstanceProcAddr(instance, "xrSyncActions".ptr, cast(PFN_xrVoidFunction*)&xrSyncActions);
	xrGetInstanceProcAddr(instance, "xrEnumerateBoundSourcesForAction".ptr, cast(PFN_xrVoidFunction*)&xrEnumerateBoundSourcesForAction);
	xrGetInstanceProcAddr(instance, "xrGetInputSourceLocalizedName".ptr, cast(PFN_xrVoidFunction*)&xrGetInputSourceLocalizedName);
	xrGetInstanceProcAddr(instance, "xrApplyHapticFeedback".ptr, cast(PFN_xrVoidFunction*)&xrApplyHapticFeedback);
	xrGetInstanceProcAddr(instance, "xrStopHapticFeedback".ptr, cast(PFN_xrVoidFunction*)&xrStopHapticFeedback);

	xrGetInstanceProcAddr(instance, "xrGetOpenGLGraphicsRequirementsKHR".ptr, cast(PFN_xrVoidFunction*)&xrGetOpenGLGraphicsRequirementsKHR);

	version (Posix) {
		xrGetInstanceProcAddr(instance, "xrConvertTimespecTimeToTimeKHR".ptr, cast(PFN_xrVoidFunction*)&xrConvertTimespecTimeToTimeKHR);
		xrGetInstanceProcAddr(instance, "xrConvertTimeToTimespecTimeKHR".ptr, cast(PFN_xrVoidFunction*)&xrConvertTimeToTimespecTimeKHR);
	}

	version (Windows) {
		xrGetInstanceProcAddr(instance, "xrConvertWin32PerformanceCounterToTimeKHR".ptr, cast(PFN_xrVoidFunction*)&xrConvertWin32PerformanceCounterToTimeKHR);
		xrGetInstanceProcAddr(instance, "xrConvertTimeToWin32PerformanceCounterKHR".ptr, cast(PFN_xrVoidFunction*)&xrConvertTimeToWin32PerformanceCounterKHR);
	}

	return true;
}
