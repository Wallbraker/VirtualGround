// Copyright 2020, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Fixed sized chunk manager.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.miners.fixed;

import sys = charge.sys;

import ground.miners.data;
import ground.miners.chunk;


private global emptyChunk: ChunkData;

class FixedTerrain
{
public:
	enum DimX = 128;
	enum DimY = 32;
	enum DimZ = 128;

	enum NumChunksX = DimX / ChunkData.Dim;
	enum NumChunksY = DimY / ChunkData.Dim;
	enum NumChunksZ = DimZ / ChunkData.Dim;


public:
	chunks: ChunkData*[NumChunksX][NumChunksY][NumChunksZ];


public:
	this()
	{
		foreach (ref arr_xy; chunks) {
			foreach (ref arr_x; arr_xy) {
				foreach (ref x; arr_x) {
					x = &emptyChunk;
				}
			}
		}
	}

	fn close()
	{
		resetToAir();
	}

	fn resetToAir()
	{
		foreach (ref arr_xy; chunks) {
			foreach (ref arr_x; arr_xy) {
				foreach (ref x; arr_x) {
					if (x is &emptyChunk) {
						continue;
					}
					sys.cFree(cast(void*)x);
					x = &emptyChunk;
				}
			}
		}
	}

	fn setYSlice(y: i32, id: Id)
	{
		for (z: i32; z < DimZ; z++) {
			for (x: i32; x < DimX; x += ChunkData.Dim) {
				cd := getChunkForWriting(x, y, z);
				by := y % ChunkData.Dim;
				bz := z % ChunkData.Dim;

				foreach (ref b; cd.data[bz][by]) {
					b = cast(u8)id;
				}
			}
		}
	}

	final fn getData(x: i32, y: i32, z: i32) Id
	{
		bx := x % ChunkData.Dim;
		by := y % ChunkData.Dim;
		bz := z % ChunkData.Dim;

		return getChunk(x, y, z).data[bz][by][bx];
	}

	final fn getChunk(x: i32, y: i32, z: i32) ChunkData*
	{
		if (x < 0 || y < 0 || z < 0 ||
		    x >= DimX || y >= DimY || z >= DimZ) {
			return &emptyChunk;
		}

		cx := x / ChunkData.Dim;
		cy := y / ChunkData.Dim;
		cz := z / ChunkData.Dim;

		return chunks[cz][cy][cx];
	}

	final fn getChunkForWriting(x: i32, y: i32, z: i32) ChunkData*
	{
		if (x < 0 || y < 0 || z < 0 ||
		    x >= DimX || y >= DimY || z >= DimZ) {
			return null;
		}

		cx := x / ChunkData.Dim;
		cy := y / ChunkData.Dim;
		cz := z / ChunkData.Dim;

		c := chunks[cz][cy][cx];
		if (c is &emptyChunk) {
			c = chunks[cz][cy][cx] = allocChunk();
		}

		return c;
	}

	fn allocChunk() ChunkData*
	{
		chunk := cast(ChunkData*)sys.cMalloc(typeid(ChunkData).size);
		chunk.resetToAir();

		return chunk;
	}
}
