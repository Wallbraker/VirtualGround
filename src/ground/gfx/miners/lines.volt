// Copyright 2019-2023, Collabora, Ltd.
// SPDX-License-Identifier: MIT OR Apache-2.0 OR BSL-1.0
/*!
 * @brief  Code handling only quads.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.gfx.miners.lines;

import core.exception;

import lib.gl.gl45;

import watt = [watt.io.file];
import math = charge.math;
import gfx = charge.gfx;
import sys = charge.sys;

import io = watt.io.file;

import ground.gfx.voxel;
import ground.gfx.miners;
import ground.miners.data;
import ground.miners.chunk;

enum LineType
{
	None = 0,
	Highlight = 1,
	Black = 2,
	Grey = 3,
}

global lineTypes: immutable(u8)[16] = [
	LineType.None,      // 0000
	LineType.Highlight, // 0001
	LineType.Highlight, // 0010
	LineType.Grey,      // 0011
	LineType.Highlight, // 0100
	LineType.Grey,      // 0101
	LineType.Black,     // 0110
	LineType.Black,     // 0111
	LineType.Highlight, // 1000
	LineType.Black,     // 1001
	LineType.Grey,      // 1010
	LineType.Black,     // 1011
	LineType.Grey,      // 1100
	LineType.Black,     // 1101
	LineType.Black,     // 1110
	LineType.None,      // 1111
];

global lineColors: immutable(math.Color4b)[4] = [
	{  0,   0,   0,   0}, // None
	{255, 255, 255,  64}, // Highlight
	{  0,   0,   0,  64}, // Black
	{128, 128, 128,  32}, // Grey
];

global lineNudges: immutable(f32)[4] = [
	0.0f,   // None
	0.0f,   // Highlight
	0.003f, // Black
	0.003f, // Grey
];

fn makeLines(ref vmm: VoxelMeshMaker, vb: VoxelBufferBuilder)
{
	start := ChunkData.Dim;
	stop := start + ChunkData.Dim + 1;

	foreach (z; start .. stop) {
		foreach (y; start .. stop) {
			vmm.handleLineX(vb, y, z);
		}
	}

	foreach (z; start .. stop) {
		foreach (x; start .. stop) {
			vmm.handleLineY(vb, x, z);
		}
	}

	foreach (y; start .. stop) {
		foreach (x; start .. stop) {
			vmm.handleLineZ(vb, x, y);
		}
	}
}

fn handleLineX(ref vmm: VoxelMeshMaker, b: VoxelBufferBuilder, y: i32, z: i32)
{
	lines: u8[257];
	start := ChunkData.Dim;
	stop := start + ChunkData.Dim + 1;

	foreach (x; start .. stop) {
		data: u32;
		data |= vmm.getData(x, y, z).isSolid() << 0u;
		data |= vmm.getData(x, y - 1, z).isSolid() << 1u;
		data |= vmm.getData(x, y, z - 1).isSolid() << 2u;
		data |= vmm.getData(x, y - 1, z - 1).isSolid() << 3u;
		lines[x] = lineTypes[data];
	}

	current: u8;
	foreach (index; start .. stop) {
		line := lines[index]; 
		x := cast(i32)index;

		if (current == line) {
			continue;
		}

		if (current != 0) {
			b.addLineVertex(cast(f32)(x + vmm.offX) - lineNudges[current],
			                cast(f32)(y + vmm.offY),
			                cast(f32)(z + vmm.offZ),
			                lineColors[current]);
		}

		if (line != 0) {
			b.addLineVertex(cast(f32)(x + vmm.offX) + lineNudges[line],
			                cast(f32)(y + vmm.offY),
			                cast(f32)(z + vmm.offZ),
			                lineColors[line]);
		}

		current = line;
	}
}

fn handleLineY(ref vmm: VoxelMeshMaker, b: VoxelBufferBuilder, x: i32, z: i32)
{
	lines: u8[257];
	start := ChunkData.Dim;
	stop := start + ChunkData.Dim + 1;

	foreach (y; start .. stop) {
		data: u32;
		data |= vmm.getData(x, y, z).isSolid() << 0u;
		data |= vmm.getData(x - 1, y, z).isSolid() << 1u;
		data |= vmm.getData(x, y, z - 1).isSolid() << 2u;
		data |= vmm.getData(x - 1, y, z - 1).isSolid() << 3u;
		lines[y] = lineTypes[data];
	}

	current: u8;
	foreach (index; start .. stop) {
		line := lines[index]; 
		y := cast(i32)index;

		if (current == line) {
			continue;
		}

		if (current != 0) {
			b.addLineVertex(cast(f32)(x + vmm.offX),
			                cast(f32)(y + vmm.offY)  - lineNudges[current],
			                cast(f32)(z + vmm.offZ),
			                lineColors[current]);
		}

		if (line != 0) {
			b.addLineVertex(cast(f32)(x + vmm.offX),
			                cast(f32)(y + vmm.offY) + lineNudges[line],
			                cast(f32)(z + vmm.offZ),
			                lineColors[line]);
		}

		current = line;
	}
}

fn handleLineZ(ref vmm: VoxelMeshMaker, b: VoxelBufferBuilder, x: i32, y: i32)
{
	lines: u8[257];
	start := ChunkData.Dim;
	stop := start + ChunkData.Dim + 1;

	foreach (z; start .. stop) {
		data: u32;
		data |= vmm.getData(x, y, z).isSolid() << 0u;
		data |= vmm.getData(x - 1, y, z).isSolid() << 1u;
		data |= vmm.getData(x, y - 1, z).isSolid() << 2u;
		data |= vmm.getData(x - 1, y -1, z).isSolid() << 3u;
		lines[z] = lineTypes[data];
	}

	current: u8;
	foreach (index; start .. stop) {
		line := lines[index]; 
		z := cast(i32)index;

		if (current == line) {
			continue;
		}

		if (current != 0) {
			b.addLineVertex(cast(f32)(x + vmm.offX),
			                cast(f32)(y + vmm.offY),
			                cast(f32)(z + vmm.offZ) - lineNudges[current],
			                lineColors[current]);
		}

		if (line != 0) {
			b.addLineVertex(cast(f32)(x + vmm.offX),
			                cast(f32)(y + vmm.offY),
			                cast(f32)(z + vmm.offZ) + lineNudges[line],
			                lineColors[line]);
		}

		current = line;
	}
}
