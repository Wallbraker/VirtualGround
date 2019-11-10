// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  A view to be rendered.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.gfx.view;

import math = charge.math;
import gfx = charge.gfx;


/*!
 * A view to be rendered.
 *
 * @ingroup gfx
 */
struct ViewInfo
{
public:
	//! A fov to be used on the given target.
	fov: math.Fovf;

	//! Used in XR mode, gives the position of the view.
	position: math.Point3f;

	//! Used in XR mode, gives the rotation of the view.
	rotation: math.Quatf;

	validFov: bool;
	validLocation: bool;
}
