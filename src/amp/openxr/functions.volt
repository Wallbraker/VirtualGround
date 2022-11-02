// Copyright 2017-2019, The Khronos Group Inc.
// SPDX-License-Identifier: Apache-2.0
/*!
 * @brief OpenXR functions.
 */
module amp.openxr.functions;

import amp.openxr.enums;
import amp.openxr.types;

version (Posix) {
	import core.c.posix.time : timespec;
}

version (Windows) {
	import core.c.windows.windows : LARGE_INTEGER;
}


// Version 1.0

fn XR_MAKE_VERSION(major: u32, minor: u32, patch: u32) XrVersion
{
	return ((((major) & 0xffff_u64) << 48) | (((minor) & 0xffff_u64) << 32) | ((patch) & 0xffffffff_u64));
}

extern(C) @loadDynamic:

fn xrGetInstanceProcAddr(instance: XrInstance, name: const char*, func: PFN_xrVoidFunction*) XrResult;
fn xrEnumerateApiLayerProperties(propertyCapacityInput: u32, propertyCountOutput: u32*, properties: XrApiLayerProperties*) XrResult;
fn xrEnumerateInstanceExtensionProperties(layerName: const char*, propertyCapacityInput: u32, propertyCountOutput: u32*, properties: XrExtensionProperties*) XrResult;
fn xrCreateInstance(createInfo: const XrInstanceCreateInfo*, instance: XrInstance*) XrResult;
fn xrDestroyInstance(instance: XrInstance) XrResult;
fn xrGetInstanceProperties(instance: XrInstance, instanceProperties: XrInstanceProperties*) XrResult;
fn xrPollEvent(instance: XrInstance, eventData: XrEventDataBuffer*) XrResult;
fn xrResultToString(instance: XrInstance, value: XrResult, buffer: char[XR_MAX_RESULT_STRING_SIZE]*) XrResult;
fn xrStructureTypeToString(instance: XrInstance, value: XrStructureType, buffer: char[XR_MAX_STRUCTURE_NAME_SIZE]*) XrResult;
fn xrGetSystem(instance: XrInstance, getInfo: const(XrSystemGetInfo)*, systemId: XrSystemId*) XrResult;
fn xrGetSystemProperties(instance: XrInstance, systemId: XrSystemId, properties: XrSystemProperties*) XrResult;
fn xrEnumerateEnvironmentBlendModes(instance: XrInstance, systemId: XrSystemId, viewConfigurationType: XrViewConfigurationType, environmentBlendModeCapacityInput: u32, environmentBlendModeCountOutput: u32*, environmentBlendModes: XrEnvironmentBlendMode*) XrResult;
fn xrCreateSession(instance: XrInstance, createInfo: const XrSessionCreateInfo*, session: XrSession*) XrResult;
fn xrDestroySession(session: XrSession) XrResult;
fn xrEnumerateReferenceSpaces(session: XrSession, spaceCapacityInput: u32, spaceCountOutput: u32*, spaces: XrReferenceSpaceType*) XrResult;
fn xrCreateReferenceSpace(session: XrSession, createInfo: const XrReferenceSpaceCreateInfo*, space: XrSpace*) XrResult;
fn xrGetReferenceSpaceBoundsRect(session: XrSession, referenceSpaceType: XrReferenceSpaceType, bounds: XrExtent2Df*) XrResult;
fn xrCreateActionSpace(session: XrSession, createInfo: const XrActionSpaceCreateInfo*, space: XrSpace*) XrResult;
fn xrLocateSpace(space: XrSpace, baseSpace: XrSpace, time: XrTime, location: XrSpaceLocation*) XrResult;
fn xrDestroySpace(space: XrSpace) XrResult;
fn xrEnumerateViewConfigurations(instance: XrInstance, systemId: XrSystemId, viewConfigurationTypeCapacityInput: u32, viewConfigurationTypeCountOutput: u32*, viewConfigurationTypes: XrViewConfigurationType*) XrResult;
fn xrGetViewConfigurationProperties(instance: XrInstance, systemId: XrSystemId, viewConfigurationType: XrViewConfigurationType, configurationProperties: XrViewConfigurationProperties*) XrResult;
fn xrEnumerateViewConfigurationViews(instance: XrInstance, systemId: XrSystemId, viewConfigurationType: XrViewConfigurationType, viewCapacityInput: u32, viewCountOutput: u32*, views: XrViewConfigurationView*) XrResult;
fn xrEnumerateSwapchainFormats(session: XrSession, formatCapacityInput: u32, formatCountOutput: u32*, formats: i64*) XrResult;
fn xrCreateSwapchain(session: XrSession, createInfo: const XrSwapchainCreateInfo*, swapchain: XrSwapchain*) XrResult;
fn xrDestroySwapchain(swapchain: XrSwapchain) XrResult;
fn xrEnumerateSwapchainImages(swapchain: XrSwapchain, imageCapacityInput: u32, imageCountOutput: u32*, images: XrSwapchainImageBaseHeader*) XrResult;
fn xrAcquireSwapchainImage(swapchain: XrSwapchain, acquireInfo: const XrSwapchainImageAcquireInfo*, index: u32*) XrResult;
fn xrWaitSwapchainImage(swapchain: XrSwapchain, waitInfo: const XrSwapchainImageWaitInfo*) XrResult;
fn xrReleaseSwapchainImage(swapchain: XrSwapchain, releaseInfo: const XrSwapchainImageReleaseInfo*) XrResult;
fn xrBeginSession(session: XrSession, beginInfo: const XrSessionBeginInfo*) XrResult;
fn xrEndSession(session: XrSession) XrResult;
fn xrRequestExitSession(session: XrSession) XrResult;
fn xrWaitFrame(session: XrSession, frameWaitInfo: const XrFrameWaitInfo*, frameState: XrFrameState*) XrResult;
fn xrBeginFrame(session: XrSession, frameBeginInfo: const XrFrameBeginInfo*) XrResult;
fn xrEndFrame(session: XrSession, frameEndInfo: const XrFrameEndInfo*) XrResult;
fn xrLocateViews(session: XrSession, viewLocateInfo: const XrViewLocateInfo*, viewState: XrViewState*, viewCapacityInput: u32, viewCountOutput: u32*, views: XrView*) XrResult;
fn xrStringToPath(instance: XrInstance, pathString: const char*, path: XrPath*) XrResult;
fn xrPathToString(instance: XrInstance, path: XrPath, bufferCapacityInput: u32, bufferCountOutput: u32*, buffer: char*) XrResult;
fn xrCreateActionSet(instance: XrInstance, createInfo: const XrActionSetCreateInfo*, actionSet: XrActionSet*) XrResult;
fn xrDestroyActionSet(actionSet: XrActionSet) XrResult;
fn xrCreateAction(actionSet: XrActionSet, createInfo: const XrActionCreateInfo*, action: XrAction*) XrResult;
fn xrDestroyAction(action: XrAction) XrResult;
fn xrSuggestInteractionProfileBindings(instance: XrInstance, suggestedBindings: const XrInteractionProfileSuggestedBinding*) XrResult;
fn xrAttachSessionActionSets(session: XrSession, attachInfo: const XrSessionActionSetsAttachInfo*) XrResult;
fn xrGetCurrentInteractionProfile(session: XrSession, topLevelUserPath: XrPath, interactionProfile: XrInteractionProfileState*) XrResult;
fn xrGetActionStateBoolean(session: XrSession, getInfo: const XrActionStateGetInfo*, state: XrActionStateBoolean*) XrResult;
fn xrGetActionStateFloat(session: XrSession, getInfo: const XrActionStateGetInfo*, state: XrActionStateFloat*) XrResult;
fn xrGetActionStateVector2f(session: XrSession, getInfo: const XrActionStateGetInfo*, state: XrActionStateVector2f*) XrResult;
fn xrGetActionStatePose(session: XrSession, getInfo: const XrActionStateGetInfo*, state: XrActionStatePose*) XrResult;
fn xrSyncActions(session: XrSession, syncInfo: const XrActionsSyncInfo*) XrResult;
fn xrEnumerateBoundSourcesForAction(session: XrSession, enumerateInfo: const XrBoundSourcesForActionEnumerateInfo*, sourceCapacityInput: u32, sourceCountOutput: u32*, sources: XrPath*) XrResult;
fn xrGetInputSourceLocalizedName(session: XrSession, getInfo: const XrInputSourceLocalizedNameGetInfo*, bufferCapacityInput: u32, bufferCountOutput: u32*, buffer: char*) XrResult;
fn xrApplyHapticFeedback(session: XrSession, hapticActionInfo: const XrHapticActionInfo*, hapticFeedback: const XrHapticBaseHeader*) XrResult;
fn xrStopHapticFeedback(session: XrSession, hapticActionInfo: const XrHapticActionInfo*) XrResult;

fn xrGetOpenGLGraphicsRequirementsKHR(instance: XrInstance, systemId: XrSystemId, graphicsRequirements: XrGraphicsRequirementsOpenGLKHR*) XrResult;

version (Posix) {
	fn xrConvertTimespecTimeToTimeKHR(instance: XrInstance, timespecTime: const(timespec)*, time: XrTime*) XrResult;
	fn xrConvertTimeToTimespecTimeKHR(instance: XrInstance, time: XrTime, timespecTime: timespec*) XrResult;
}

version (Windows) {
	fn xrConvertWin32PerformanceCounterToTimeKHR(instance: XrInstance, performanceCounter: const(LARGE_INTEGER)*, time: XrTime*) XrResult;
	fn xrConvertTimeToWin32PerformanceCounterKHR(instance: XrInstance, time: XrTime, performanceCounter: LARGE_INTEGER*) XrResult;
}
