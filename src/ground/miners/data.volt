// Copyright 2020, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Data descriptions.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.miners.data;


enum Id
{
	Air,
	Bedrock,
	Stone,
	Dirt,
	GrassBlock,

	Wood,
	Planks,
	Leaves,

	Sand,
	Sandstone,
}

fn isSolid(id: Id) bool
{
	final switch (id) with (Id) {
	case Air:
		return false;
	case Bedrock, Stone, Dirt, GrassBlock, Wood, Planks, Leaves, Sand, Sandstone:
		return true;
	}
}
