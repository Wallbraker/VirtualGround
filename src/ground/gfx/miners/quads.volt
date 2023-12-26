// Copyright 2019-2023, Collabora, Ltd.
// SPDX-License-Identifier: MIT OR Apache-2.0 OR BSL-1.0
/*!
 * @brief  Code handling only quads.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.gfx.miners.quads;

import lib.gl.gl45;

import math = charge.math;
import gfx = charge.gfx;
import sys = charge.sys;

import ground.gfx.voxel;
import ground.gfx.miners;
import ground.miners.data;
import ground.miners.chunk;


fn addQuadsIfNotSolid(ref vmm: VoxelMeshMaker,
                      vb: VoxelBufferBuilder,
                      x: i32, y: i32, z: i32,
                      layer: u32, color: math.Color4b)
{
	vmm.addQuadXNIfSolid(vb, x, y, z, layer, color);
	vmm.addQuadXPIfSolid(vb, x, y, z, layer, color);
	vmm.addQuadYNIfSolid(vb, x, y, z, layer, color);
	vmm.addQuadYPIfSolid(vb, x, y, z, layer, color);
	vmm.addQuadZNIfSolid(vb, x, y, z, layer, color);
	vmm.addQuadZPIfSolid(vb, x, y, z, layer, color);
}

fn addQuadXNIfSolid(ref vmm: VoxelMeshMaker,
                    vb: VoxelBufferBuilder,
                    x: i32, y: i32, z: i32,
                    layer: u32, color: math.Color4b)
{
	if (vmm.getData(x - 1, y, z).isSolid()) {
		return;
	}

	vmm.addQuadXN(vb, x, y, z, layer, color);
}

fn addQuadXPIfSolid(ref vmm: VoxelMeshMaker,
                    vb: VoxelBufferBuilder,
                    x: i32, y: i32, z: i32,
                    layer: u32, color: math.Color4b)
{
	if (vmm.getData(x + 1, y, z).isSolid()) {
		return;
	}

	vmm.addQuadXP(vb, x, y, z, layer, color);
}

fn addQuadYNIfSolid(ref vmm: VoxelMeshMaker,
                    vb: VoxelBufferBuilder,
                    x: i32, y: i32, z: i32,
                    layer: u32, color: math.Color4b)
{
	if (vmm.getData(x, y - 1, z).isSolid()) {
		return;
	}

	vmm.addQuadYN(vb, x, y, z, layer, color);
}

fn addQuadYPIfSolid(ref vmm: VoxelMeshMaker,
                    vb: VoxelBufferBuilder,
                    x: i32, y: i32, z: i32,
                    layer: u32, color: math.Color4b)
{
	if (vmm.getData(x, y + 1, z).isSolid()) {
		return;
	}

	vmm.addQuadYP(vb, x, y, z, layer, color);
}

fn addQuadZNIfSolid(ref vmm: VoxelMeshMaker,
                    vb: VoxelBufferBuilder,
                    x: i32, y: i32, z: i32,
                    layer: u32, color: math.Color4b)
{
	if (vmm.getData(x, y, z - 1).isSolid()) {
		return;
	}

	vmm.addQuadZN(vb, x, y, z, layer, color);
}

fn addQuadZPIfSolid(ref vmm: VoxelMeshMaker,
                    vb: VoxelBufferBuilder,
                    x: i32, y: i32, z: i32,
                    layer: u32, color: math.Color4b)
{
	if (vmm.getData(x, y, z + 1).isSolid()) {
		return;
	}

	vmm.addQuadZP(vb, x, y, z, layer, color);
}

fn addQuadXN(ref vmm: VoxelMeshMaker,
             vb: VoxelBufferBuilder,
             x: i32, y: i32, z: i32,
             layer: u32, color: math.Color4b)
{
	vb.addQuad(x + vmm.offX, y + vmm.offY, z + vmm.offZ,
	           VoxelBufferBuilder.Side.XN,
	           layer, color);
}

fn addQuadXP(ref vmm: VoxelMeshMaker,
             vb: VoxelBufferBuilder,
             x: i32, y: i32, z: i32,
             layer: u32, color: math.Color4b)
{
	vb.addQuad(x + vmm.offX, y + vmm.offY, z + vmm.offZ,
	           VoxelBufferBuilder.Side.XP,
	           layer, color);
}

fn addQuadYN(ref vmm: VoxelMeshMaker,
             vb: VoxelBufferBuilder,
             x: i32, y: i32, z: i32,
             layer: u32, color: math.Color4b)
{
	vb.addQuad(x + vmm.offX, y + vmm.offY, z + vmm.offZ,
	           VoxelBufferBuilder.Side.YN,
	           layer, color);
}

fn addQuadYP(ref vmm: VoxelMeshMaker,
             vb: VoxelBufferBuilder,
             x: i32, y: i32, z: i32,
             layer: u32, color: math.Color4b)
{
	vb.addQuad(x + vmm.offX, y + vmm.offY, z + vmm.offZ,
	           VoxelBufferBuilder.Side.YP,
	           layer, color);
}

fn addQuadZN(ref vmm: VoxelMeshMaker,
             vb: VoxelBufferBuilder,
             x: i32, y: i32, z: i32,
             layer: u32, color: math.Color4b)
{
	vb.addQuad(x + vmm.offX, y + vmm.offY, z + vmm.offZ,
	           VoxelBufferBuilder.Side.ZN,
	           layer, color);
}

fn addQuadZP(ref vmm: VoxelMeshMaker,
             vb: VoxelBufferBuilder,
             x: i32, y: i32, z: i32,
             layer: u32, color: math.Color4b)
{
	vb.addQuad(x + vmm.offX, y + vmm.offY, z + vmm.offZ,
	           VoxelBufferBuilder.Side.ZP,
	           layer, color);
}
