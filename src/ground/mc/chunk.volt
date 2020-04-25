// Copyright 2020, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Chunk object holding data.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.mc.chunk;


struct ChunkData
{
public:
	enum Dim = 16;

	data: u8[Dim][Dim][Dim];
}
