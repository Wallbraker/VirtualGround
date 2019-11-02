// Copyright 2017-2019, The Khronos Group Inc.
// SPDX-License-Identifier: Apache-2.0
/*!
 * @brief OpenXR types.
 */
module amp.openxr.types;

import amp.openxr.enums;


// Version 1.0

version (V_P64) {
	struct XrInstance_T {}
	alias XrInstance = XrInstance_T*;
	struct XrSession_T {}
	alias XrSession = XrSession_T*;
	struct XrSpace_T {}
	alias XrSpace = XrSpace_T*;
	struct XrAction_T {}
	alias XrAction = XrAction_T*;
	struct XrSwapchain_T {}
	alias XrSwapchain = XrSwapchain_T*;
	struct XrActionSet_T {}
	alias XrActionSet = XrActionSet_T*;
} else version (V_P32) {
	struct XrInstance { _value: u64; }
	struct XrSession { _value: u64; }
	struct XrSpace { _value: u64; }
	struct XrAction { _value: u64; }
	struct XrSwapchain { _value: u64; }
	struct XrActionSet { _value: u64; }
} else {
	static assert(false, "Non-supported pointer size");
}

alias XrVersion = u64;
alias XrFlags64 = u64;
struct XrSystemId { _value: u64; }
alias XrBool32 = u32;
struct XrPath { _value: u64; }
alias XrTime = i64;
alias XrDuration = i64;

alias PFN_xrVoidFunction = fn!C();

struct XrApiLayerProperties
{
	type: XrStructureType;
	next: void*;
	layerName: char[XR_MAX_API_LAYER_NAME_SIZE];
	specVersion: XrVersion;
	layerVersion: u32;
	description: char[XR_MAX_API_LAYER_DESCRIPTION_SIZE];
}

struct XrExtensionProperties
{
	type: XrStructureType;
	next: void*;
	extensionName: char[XR_MAX_EXTENSION_NAME_SIZE];
	extensionVersion: u32;
}

struct XrApplicationInfo
{
	applicationName: char[XR_MAX_APPLICATION_NAME_SIZE];
	applicationVersion: u32;
	engineName: char[XR_MAX_ENGINE_NAME_SIZE];
	engineVersion: u32;
	apiVersion: XrVersion;
}

struct XrInstanceCreateInfo
{
	type: XrStructureType;
	next: const(void)*;
	createFlags: XrInstanceCreateFlags;
	applicationInfo: XrApplicationInfo;
	enabledApiLayerCount: u32;
	enabledApiLayerNames: const(const(char)*)*;
	enabledExtensionCount: u32;
	enabledExtensionNames: const(const(char)*)*;
}

struct XrInstanceProperties
{
	type: XrStructureType;
	next: void*;
	runtimeVersion: XrVersion;
	runtimeName: char[XR_MAX_RUNTIME_NAME_SIZE];
}

struct XrEventDataBuffer
{
	type: XrStructureType;
	next: const(void)*;
	varying: u8[4000];
}

struct XrSystemGetInfo
{
	type: XrStructureType;
	next: const(void)*;
	formFactor: XrFormFactor;
}

struct XrSystemGraphicsProperties
{
	maxSwapchainImageHeight: u32;
	maxSwapchainImageWidth: u32;
	maxLayerCount: u32;
}

struct XrSystemTrackingProperties
{
	orientationTracking: XrBool32;
	positionTracking: XrBool32;
}

struct XrSystemProperties
{
	type: XrStructureType;
	next: void*;
	systemId: XrSystemId;
	vendorId: u32;
	systemName: char[XR_MAX_SYSTEM_NAME_SIZE];
	graphicsProperties: XrSystemGraphicsProperties;
	trackingProperties: XrSystemTrackingProperties;
}

struct XrSessionCreateInfo
{
	type: XrStructureType;
	next: const(void)*;
	createFlags: XrSessionCreateFlags;
	systemId: XrSystemId;
}

struct XrVector3f
{
	x: f32;
	y: f32;
	z: f32;
}

struct XrSpaceVelocity
{
	type: XrStructureType;
	next: void*;
	velocityFlags: XrSpaceVelocityFlags;
	linearVelocity: XrVector3f;
	angularVelocity: XrVector3f;
}

struct XrQuaternionf
{
	x: f32;
	y: f32;
	z: f32;
	w: f32;
}

struct XrPosef
{
	orientation: XrQuaternionf;
	position: XrVector3f;
}

struct XrReferenceSpaceCreateInfo
{
	type: XrStructureType;
	next: const(void)*;
	referenceSpaceType: XrReferenceSpaceType;
	poseInReferenceSpace: XrPosef;
}
struct XrExtent2Df
{
	width: f32;
	height: f32;
}

struct XrActionSpaceCreateInfo
{
	type: XrStructureType;
	next: const(void)*;
	action: XrAction;
	subactionPath: XrPath;
	poseInActionSpace: XrPosef;
}

struct XrSpaceLocation
{
	type: XrStructureType;
	next: void*;
	locationFlags: XrSpaceLocationFlags;
	pose: XrPosef;
}

struct XrViewConfigurationProperties
{
	type: XrStructureType;
	next: void*;
	viewConfigurationType: XrViewConfigurationType;
	fovMutable: XrBool32;
}

struct XrViewConfigurationView
{
	type: XrStructureType;
	next: void*;
	recommendedImageRectWidth: u32;
	maxImageRectWidth: u32;
	recommendedImageRectHeight: u32;
	maxImageRectHeight: u32;
	recommendedSwapchainSampleCount: u32;
	maxSwapchainSampleCount: u32;
}

struct XrSwapchainCreateInfo
{
	type: XrStructureType;
	next: const(void)*;
	createFlags: XrSwapchainCreateFlags;
	usageFlags: XrSwapchainUsageFlags;
	format: i64;
	sampleCount: u32;
	width: u32;
	height: u32;
	faceCount: u32;
	arraySize: u32;
	mipCount: u32;
}

struct XrSwapchainImageBaseHeader
{
	type: XrStructureType;
	next: void*;
}

struct XrSwapchainImageAcquireInfo
{
	type: XrStructureType;
	next: const(void)*;
}

struct XrSwapchainImageWaitInfo
{
	type: XrStructureType;
	next: const(void)*;
	timeout: XrDuration;
}

struct XrSwapchainImageReleaseInfo
{
	type: XrStructureType;
	next: const(void)*;
}

struct XrSessionBeginInfo
{
	type: XrStructureType;
	next: const(void)*;
	primaryViewConfigurationType: XrViewConfigurationType;
}

struct XrFrameWaitInfo
{
	type: XrStructureType;
	next: const(void)*;
}

struct XrFrameState
{
	type: XrStructureType;
	next: void*;
	predictedDisplayTime: XrTime;
	predictedDisplayPeriod: XrDuration;
	shouldRender: XrBool32;
}

struct XrFrameBeginInfo
{
	type: XrStructureType;
	next: const(void)*;
}

struct XrCompositionLayerBaseHeader
{
	type: XrStructureType;
	next: const(void)*;
	layerFlags: XrCompositionLayerFlags;
	space: XrSpace;
}

struct XrFrameEndInfo
{
	type: XrStructureType;
	next: const(void)*;
	displayTime: XrTime;
	environmentBlendMode: XrEnvironmentBlendMode;
	layerCount: u32;
	layers: const(const(XrCompositionLayerBaseHeader)*)*;
}

struct XrViewLocateInfo
{
	type: XrStructureType;
	next: const(void)*;
	viewConfigurationType: XrViewConfigurationType;
	displayTime: XrTime;
	space: XrSpace;
}

struct XrViewState
{
	type: XrStructureType;
	next: void*;
	viewStateFlags: XrViewStateFlags;
}

struct XrFovf
{
	angleLeft: f32;
	angleRight: f32;
	angleUp: f32;
	angleDown: f32;
}

struct XrView
{
	type: XrStructureType;
	next: void*;
	pose: XrPosef;
	fov: XrFovf;
}

struct XrActionSetCreateInfo
{
	type: XrStructureType;
	next: const(void)*;
	actionSetName: char[XR_MAX_ACTION_SET_NAME_SIZE];
	localizedActionSetName: char[XR_MAX_LOCALIZED_ACTION_SET_NAME_SIZE];
	priority: u32;
}

struct XrActionCreateInfo
{
	type: XrStructureType;
	next: const(void)*;
	actionName: char[XR_MAX_ACTION_NAME_SIZE];
	actionType: XrActionType;
	countSubactionPaths: u32;
	subactionPaths: const(XrPath)*;
	localizedActionName: char[XR_MAX_LOCALIZED_ACTION_NAME_SIZE];
}

struct XrActionSuggestedBinding
{
	action: XrAction;
	binding: XrPath;
}

struct XrInteractionProfileSuggestedBinding
{
	type: XrStructureType;
	next: const(void)*;
	interactionProfile: XrPath;
	countSuggestedBindings: u32;
	suggestedBindings: const(XrActionSuggestedBinding)*;
}

struct XrSessionActionSetsAttachInfo
{
	type: XrStructureType;
	next: const(void)*;
	countActionSets: u32;
	actionSets: const(XrActionSet)*;
}

struct XrInteractionProfileState
{
	type: XrStructureType;
	next: void*;
	interactionProfile: XrPath;
}

struct XrActionStateGetInfo
{
	type: XrStructureType;
	next: const(void)*;
	action: XrAction;
	subactionPath: XrPath;
}

struct XrActionStateBoolean
{
	type: XrStructureType;
	next: void*;
	currentState: XrBool32;
	changedSinceLastSync: XrBool32;
	lastChangeTime: XrTime;
	isActive: XrBool32;
}

struct XrActionStateFloat
{
	type: XrStructureType;
	next: void*;
	currentState: f32;
	changedSinceLastSync: XrBool32;
	lastChangeTime: XrTime;
	isActive: XrBool32;
}

struct XrVector2f
{
	x: f32;
	y: f32;
}

struct XrActionStateVector2f
{
	type: XrStructureType;
	next: void*;
	currentState: XrVector2f;
	changedSinceLastSync: XrBool32;
	lastChangeTime: XrTime;
	isActive: XrBool32;
}

struct XrActionStatePose
{
	type: XrStructureType;
	next: void*;
	isActive: XrBool32;
}

struct XrActiveActionSet
{
	actionSet: XrActionSet;
	subactionPath: XrPath;
}

struct XrActionsSyncInfo
{
	type: XrStructureType;
	next: const(void)*;
	countActiveActionSets: u32;
	activeActionSets: const(XrActiveActionSet)*;
}

struct XrBoundSourcesForActionEnumerateInfo
{
	type: XrStructureType;
	next: const(void)*;
	action: XrAction;
}

struct XrInputSourceLocalizedNameGetInfo
{
	type: XrStructureType;
	next: const(void)*;
	sourcePath: XrPath;
	whichComponents: XrInputSourceLocalizedNameFlags;
}

struct XrHapticActionInfo
{
	type: XrStructureType;
	next: const(void)*;
	action: XrAction;
	subactionPath: XrPath;
}

struct XrHapticBaseHeader
{
	type: XrStructureType;
	next: const(void)*;
}

struct XrBaseInStructure
{
	type: XrStructureType;
	next: const(XrBaseInStructure)*;
}

struct XrBaseOutStructure
{
	type: XrStructureType;
	next: XrBaseOutStructure*;
}

struct XrOffset2Di
{
	x: i32;
	y: i32;
}

struct XrExtent2Di
{
	width: i32;
	height: i32;
}

struct XrRect2Di
{
	offset: XrOffset2Di;
	extent: XrExtent2Di;
}

struct XrSwapchainSubImage
{
	swapchain: XrSwapchain;
	imageRect: XrRect2Di;
	imageArrayIndex: u32;
}

struct XrCompositionLayerProjectionView
{
	type: XrStructureType;
	next: const(void)*;
	pose: XrPosef;
	fov: XrFovf;
	subImage: XrSwapchainSubImage;
}

struct XrCompositionLayerProjection
{
	type: XrStructureType;
	next: const(void)*;
	layerFlags: XrCompositionLayerFlags;
	space: XrSpace;
	viewCount: u32;
	views: const(XrCompositionLayerProjectionView)*;
}

struct XrCompositionLayerQuad
{
	type: XrStructureType;
	next: const(void)*;
	layerFlags: XrCompositionLayerFlags;
	space: XrSpace;
	eyeVisibility: XrEyeVisibility;
	subImage: XrSwapchainSubImage;
	pose: XrPosef;
	size: XrExtent2Df;
}

struct XrEventDataBaseHeader
{
	type: XrStructureType;
	next: const(void)*;
}

struct XrEventDataEventsLost
{
	type: XrStructureType;
	next: const(void)*;
	lostEventCount: u32;
}

struct XrEventDataInstanceLossPending
{
	type: XrStructureType;
	next: const(void)*;
	lossTime: XrTime;
}

struct XrEventDataSessionStateChanged
{
	type: XrStructureType;
	next: const(void)*;
	session: XrSession;
	state: XrSessionState;
	time: XrTime;
}

struct XrEventDataReferenceSpaceChangePending
{
	type: XrStructureType;
	next: const(void)*;
	session: XrSession;
	referenceSpaceType: XrReferenceSpaceType;
	changeTime: XrTime;
	poseValid: XrBool32;
	poseInPreviousSpace: XrPosef;
}

struct XrEventDataInteractionProfileChanged
{
	type: XrStructureType;
	next: const(void)*;
	session: XrSession;
}

struct XrHapticVibration
{
	type: XrStructureType;
	next: const(void)*;
	duration: XrDuration;
	frequency: f32;
	amplitude: f32;
}

struct XrOffset2Df
{
	x: f32;
	y: f32;
}

struct XrRect2Df
{
	offset: XrOffset2Df;
	extent: XrExtent2Df;
}

struct XrVector4f
{
	x: f32;
	y: f32;
	z: f32;
	w: f32;
}

struct XrColor4f
{
	r: f32;
	g: f32;
	b: f32;
	a: f32;
}


// XR_MND_egl_enable

import amp.egl.types;

struct XrGraphicsBindingEGLMND
{
	type: XrStructureType;
	next: const(void)*;
	getProcAddress: PFNEGLGETPROCADDRESSPROC;
	display: EGLDisplay;
	config: EGLConfig;
	context: EGLContext;
}


// XR_KHR_opengl_enable || XR_MND_egl_enable

struct XrSwapchainImageOpenGLKHR
{
	type: XrStructureType;
	next: void*;
	image: u32;
}
