// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Code to load a VoxelModel from a MagicaVoxel file.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.gfx.magica;

import watt = [watt.io.file];
import math = charge.math;
import gfx = charge.gfx;

import ground.gfx.voxel;
import ground.gfx.builder;


fn loadFile(filename: string) VoxelBufferBuilder
{
	return loadFromData(cast(u8[])watt.read(filename));
}

fn loadFromData(arr: const(u8)[]) VoxelBufferBuilder
{
	ptr := cast(const(u8)*)arr.ptr;
	end := cast(const(u8)*)arr.ptr + arr.length;
	h := *cast(const(Header)*)ptr; ptr += typeid(Header).size;

	x, y, z : u32;
	voxels : MagicaVoxel[];
	numVoxels : size_t;
	colors := defaultMagicaColors[];

	while (cast(size_t)ptr < cast(size_t)end) {
		c := cast(const(Chunk)*)ptr;
		ptr += typeid(Chunk).size;

		switch (c.id[]) {
		case "MAIN": break;
		case "SIZE":
			u32Ptr := cast(u32*)ptr;
			x = u32Ptr[0];
			y = u32Ptr[1];
			z = u32Ptr[2];
			break;
		case "XYZI":
			numVoxels = *cast(u32*)ptr;
			voxels = (cast(MagicaVoxel*)(ptr + 4))[0 .. numVoxels];
			break;
		case "RGBA":
			colors = (cast(math.Color4b*)ptr)[0 .. 255];
			break;
		default:
		}
		ptr = ptr + c.chunkSize;
	}

	// Copy the data into the buffer.
	sharedMeshMaker.reset();
	sharedMeshMaker.setSize(x, z, y);
	sharedMeshMaker.setColors(colors);
	foreach (voxel; voxels) {
		sharedMeshMaker.setVoxel(voxel.x, voxel.y, voxel.z, voxel.color);
	}

	return sharedMeshMaker.makeVoxelBufferBuilder();
}

struct Header
{
	magic: char[4];
	ver: u32;
}

struct Chunk
{
	id: char[4];
	chunkSize: u32;
	childSize: u32;
}

struct MagicaVoxel
{
	x: u8;
	z: u8; //!< Z is up in MagicaVoxel.
	y: u8; //!< Y is depth in MagicaVoxel.
	color: u8;
}
