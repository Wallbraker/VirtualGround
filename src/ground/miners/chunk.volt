// Copyright 2020-2023, Collabora, Ltd.
// SPDX-License-Identifier: MIT OR Apache-2.0 OR BSL-1.0
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
