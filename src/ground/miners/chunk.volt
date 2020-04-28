// Copyright 2020, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Chunk object holding data.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.miners.chunk;

import ground.miners.data;


struct ChunkData
{
public:
	enum Dim = 8;


public:
	data: u8[Dim][Dim][Dim];


public:
	fn resetToAir()
	{
		foreach (ref arr_xy; data) {
			foreach (ref arr_x; arr_xy) {
				foreach (ref x; arr_x) {
					x = Id.Air;
				}
			}
		}
	}
}
