// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  A single scene that can be rendered from multiple views.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.gfx.magica;

import watt = [watt.io.file];
import math = charge.math;
import gfx = charge.gfx;

import ground.gfx.voxel;

import io = watt.io;


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
	voxels : Voxel[];
	numVoxels : size_t;
	colors := defaultColors;

	while (cast(size_t)ptr < cast(size_t)end) {
		c := cast(const(Chunk)*)ptr;
		ptr += typeid(Chunk).size;

		switch (c.id[..]) {
		case "MAIN": break;
		case "SIZE":
			u32Ptr := cast(u32*)ptr;
			x = u32Ptr[0];
			y = u32Ptr[1];
			z = u32Ptr[2];
			break;
		case "XYZI":
			numVoxels = *cast(u32*)ptr;
			voxels = (cast(Voxel*)(ptr + 4))[0 .. numVoxels];
			break;
		case "RGBA":
			colors = (cast(math.Color4b*)ptr)[0 .. 256];
			break;
		default:
		}
		ptr = ptr + c.chunkSize;
	}

	// Copy the data into the buffer.
	buf.setSize(x, y, z);
	buf.setColors(colors);
	foreach (voxel; voxels) {
		buf.setVoxel(voxel);
	}

	vb := new VoxelBufferBuilder();
	buf.makeQuads(vb);
	vb.switchToLines();
	buf.makeLines(vb);

	return vb;
}

global buf: MagicaBuilder;

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

struct Voxel
{
	x: u8;
	y: u8;
	z: u8;
	color: u8;
}

struct MagicaBuilder
{
public:
	enum DimX = cast(i32)(256 + 2);
	enum DimY = cast(i32)(256 + 2);
	enum DimZ = cast(i32)(256 + 2);
	enum StrideX = cast(i32)(1);
	enum StrideY = cast(i32)(DimX);
	enum StrideZ = cast(i32)(DimX * DimY);
	enum Size = cast(i32)(DimX * DimY * DimZ);

	enum StartOffset = StrideX + StrideY + StrideZ;

	enum XN = StrideX * -1;
	enum XP = StrideX * +1;
	enum YN = StrideY * -1;
	enum YP = StrideY * +1;
	enum ZN = StrideZ * -1;
	enum ZP = StrideZ * +1;


public:
	buf: u8[Size];
	sizeX, sizeY, sizeZ: i32;

	// Copy of the palette so this struct doesn't have pointers.
	colors: math.Color4b[256];


public:
	fn setSize(x: u32, y: u32, z: u32)
	{
		// Flipped y and z axis.
		sizeX = cast(i32)x;
		sizeY = cast(i32)z;
		sizeZ = cast(i32)y;
	}

	fn setColors(colors: math.Color4b[])
	{
		this.colors[] = colors[];
	}

	fn setVoxel(v: Voxel)
	{
		// Flipped y and z axis.
		buf[index(v.x, v.z, v.y)] = v.color;
	}

	fn index(x: i32, y: i32, z: i32) i32
	{
		return StartOffset + x * StrideX + y * StrideY + z * StrideZ;
	}

	fn makeQuads(b: VoxelBufferBuilder)
	{
		foreach (z; 0 .. sizeZ) {
			foreach (y; 0 .. sizeY) {
				i := index(0, y, z);
				foreach (x; 0 .. sizeX) {
					handleQuadVoxel(b, x, y, z, i);
					i++;
				}
			}
		}
	}

	fn handleQuadVoxel(b: VoxelBufferBuilder, x: i32, y: i32, z: i32, i: i32)
	{
		c := buf[i];
		if (c == 0) {
			return;
		}

		if (buf[i + XN] == 0) {
			b.addQuad(x, y, z, VoxelBufferBuilder.Side.XN, 0, colors[c]);
		}
		if (buf[i + XP] == 0) {
			b.addQuad(x, y, z, VoxelBufferBuilder.Side.XP, 0, colors[c]);
		}
		if (buf[i + YN] == 0) {
			b.addQuad(x, y, z, VoxelBufferBuilder.Side.YN, 0, colors[c]);
		}
		if (buf[i + YP] == 0) {
			b.addQuad(x, y, z, VoxelBufferBuilder.Side.YP, 0, colors[c]);
		}
		if (buf[i + ZN] == 0) {
			b.addQuad(x, y, z, VoxelBufferBuilder.Side.ZN, 0, colors[c]);
		}
		if (buf[i + ZP] == 0) {
			b.addQuad(x, y, z, VoxelBufferBuilder.Side.ZP, 0, colors[c]);
		}
	}

	fn makeLines(b: VoxelBufferBuilder)
	{
		foreach (z; 0 .. sizeZ + 1) {
			foreach (y; 0 .. sizeY + 1) {
				i := index(0, y, z);
				handleLineX(b, i, y, z);
			}
		}

		foreach (z; 0 .. sizeZ + 1) {
			foreach (x; 0 .. sizeX + 1) {
				i := index(x, 0, z);
				handleLineY(b, i, x, z);
			}
		}

		foreach (y; 0 .. sizeY + 1) {
			foreach (x; 0 .. sizeX + 1) {
				i := index(x, y, 0);
				handleLineZ(b, i, x, y);
			}
		}
	}

	enum LineType
	{
		None = 0,
		Highlight = 1,
		Black = 2,
		Grey = 3,
	}

	global lineType: u8[16] = [
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

	global lineNudge: immutable(f32)[4] = [
		0.0f,   // None
		0.0f,   // Highlight
		0.003f, // Black
		0.003f, // Grey
	];

	fn handleLineX(b: VoxelBufferBuilder, i: i32, y: i32, z: i32)
	{
		lines: u8[257];

		foreach (x; 0 .. sizeX) {
			data: u32;
			data |= (buf[i] != 0) << 0u;
			data |= (buf[i + YN] != 0) << 1u;
			data |= (buf[i + ZN] != 0) << 2u;
			data |= (buf[i + YN + ZN] != 0) << 3u;
			lines[x] = lineType[data];
			i += StrideX;
		}

		current: u8;
		foreach (x, line; lines[0 .. sizeX + 1]) {
			if (current == line) {
				continue;
			}

			if (current != 0) {
				b.addLineVertex(cast(f32)x - lineNudge[current], cast(f32)y, cast(f32)z, lineColors[current]);
			}

			if (line != 0) {
				b.addLineVertex(cast(f32)x + lineNudge[line], cast(f32)y, cast(f32)z, lineColors[line]);
			}

			current = line;
		}
	}

	fn handleLineY(b: VoxelBufferBuilder, i: i32, x: i32, z: i32)
	{
		lines: u8[257];

		foreach (y; 0 .. sizeY) {
			data: u32;
			data |= (buf[i] != 0) << 0u;
			data |= (buf[i + XN] != 0) << 1u;
			data |= (buf[i + ZN] != 0) << 2u;
			data |= (buf[i + XN + ZN] != 0) << 3u;
			lines[y] = lineType[data];
			i += StrideY;
		}

		current: u8;
		foreach (y, line; lines[0 .. sizeY + 1]) {
			if (current == line) {
				continue;
			}

			if (current != 0) {
				b.addLineVertex(cast(f32)x, cast(f32)y - lineNudge[current], cast(f32)z, lineColors[current]);
			}

			if (line != 0) {
				b.addLineVertex(cast(f32)x, cast(f32)y + lineNudge[line], cast(f32)z, lineColors[line]);
			}

			current = line;
		}
	}

	fn handleLineZ(b: VoxelBufferBuilder, i: i32, x: i32, y: i32)
	{
		lines: u8[257];

		foreach (z; 0 .. sizeZ) {
			data: u32;
			data |= (buf[i] != 0) << 0u;
			data |= (buf[i + XN] != 0) << 1u;
			data |= (buf[i + YN] != 0) << 2u;
			data |= (buf[i + XN + YN] != 0) << 3u;
			lines[z] = lineType[data];
			i += StrideZ;
		}

		current: u8;
		foreach (z, line; lines[0 .. sizeZ + 1]) {
			if (current == line) {
				continue;
			}

			if (current != 0) {
				b.addLineVertex(cast(f32)x, cast(f32)y, cast(f32)z - lineNudge[current], lineColors[current]);
			}

			if (line != 0) {
				b.addLineVertex(cast(f32)x, cast(f32)y, cast(f32)z + lineNudge[line], lineColors[line]);
			}

			current = line;
		}
	}
}


@mangledName("llvm.ctpop.i32")
fn countSetBits(bits: u32) u32;


global math.Color4b[] defaultColors = [
	{255, 255, 255, 255}, {255, 255, 204, 255}, {255, 255, 153, 255},
	{255, 255, 102, 255}, {255, 255,  51, 255}, {255, 255,   0, 255},
	{255, 204, 255, 255}, {255, 204, 204, 255}, {255, 204, 153, 255},
	{255, 204, 102, 255}, {255, 204,  51, 255}, {255, 204,   0, 255},
	{255, 153, 255, 255}, {255, 153, 204, 255}, {255, 153, 153, 255},
	{255, 153, 102, 255}, {255, 153,  51, 255}, {255, 153,   0, 255},
	{255, 102, 255, 255}, {255, 102, 204, 255}, {255, 102, 153, 255},
	{255, 102, 102, 255}, {255, 102,  51, 255}, {255, 102,   0, 255},
	{255,  51, 255, 255}, {255,  51, 204, 255}, {255,  51, 153, 255},
	{255,  51, 102, 255}, {255,  51,  51, 255}, {255,  51,   0, 255},
	{255,   0, 255, 255}, {255,   0, 204, 255}, {255,   0, 153, 255},
	{255,   0, 102, 255}, {255,   0,  51, 255}, {255,   0,   0, 255},
	{204, 255, 255, 255}, {204, 255, 204, 255}, {204, 255, 153, 255},
	{204, 255, 102, 255}, {204, 255,  51, 255}, {204, 255,   0, 255},
	{204, 204, 255, 255}, {204, 204, 204, 255}, {204, 204, 153, 255},
	{204, 204, 102, 255}, {204, 204,  51, 255}, {204, 204,   0, 255},
	{204, 153, 255, 255}, {204, 153, 204, 255}, {204, 153, 153, 255},
	{204, 153, 102, 255}, {204, 153,  51, 255}, {204, 153,   0, 255},
	{204, 102, 255, 255}, {204, 102, 204, 255}, {204, 102, 153, 255},
	{204, 102, 102, 255}, {204, 102,  51, 255}, {204, 102,   0, 255},
	{204,  51, 255, 255}, {204,  51, 204, 255}, {204,  51, 153, 255},
	{204,  51, 102, 255}, {204,  51,  51, 255}, {204,  51,   0, 255},
	{204,   0, 255, 255}, {204,   0, 204, 255}, {204,   0, 153, 255},
	{204,   0, 102, 255}, {204,   0,  51, 255}, {204,   0,   0, 255},
	{153, 255, 255, 255}, {153, 255, 204, 255}, {153, 255, 153, 255},
	{153, 255, 102, 255}, {153, 255,  51, 255}, {153, 255,   0, 255},
	{153, 204, 255, 255}, {153, 204, 204, 255}, {153, 204, 153, 255},
	{153, 204, 102, 255}, {153, 204,  51, 255}, {153, 204,   0, 255},
	{153, 153, 255, 255}, {153, 153, 204, 255}, {153, 153, 153, 255},
	{153, 153, 102, 255}, {153, 153,  51, 255}, {153, 153,   0, 255},
	{153, 102, 255, 255}, {153, 102, 204, 255}, {153, 102, 153, 255},
	{153, 102, 102, 255}, {153, 102,  51, 255}, {153, 102,   0, 255},
	{153,  51, 255, 255}, {153,  51, 204, 255}, {153,  51, 153, 255},
	{153,  51, 102, 255}, {153,  51,  51, 255}, {153,  51,   0, 255},
	{153,   0, 255, 255}, {153,   0, 204, 255}, {153,   0, 153, 255},
	{153,   0, 102, 255}, {153,   0,  51, 255}, {153,   0,   0, 255},
	{102, 255, 255, 255}, {102, 255, 204, 255}, {102, 255, 153, 255},
	{102, 255, 102, 255}, {102, 255,  51, 255}, {102, 255,   0, 255},
	{102, 204, 255, 255}, {102, 204, 204, 255}, {102, 204, 153, 255},
	{102, 204, 102, 255}, {102, 204,  51, 255}, {102, 204,   0, 255},
	{102, 153, 255, 255}, {102, 153, 204, 255}, {102, 153, 153, 255},
	{102, 153, 102, 255}, {102, 153,  51, 255}, {102, 153,   0, 255},
	{102, 102, 255, 255}, {102, 102, 204, 255}, {102, 102, 153, 255},
	{102, 102, 102, 255}, {102, 102,  51, 255}, {102, 102,   0, 255},
	{102,  51, 255, 255}, {102,  51, 204, 255}, {102,  51, 153, 255},
	{102,  51, 102, 255}, {102,  51,  51, 255}, {102,  51,   0, 255},
	{102,   0, 255, 255}, {102,   0, 204, 255}, {102,   0, 153, 255},
	{102,   0, 102, 255}, {102,   0,  51, 255}, {102,   0,   0, 255},
	{ 51, 255, 255, 255}, { 51, 255, 204, 255}, { 51, 255, 153, 255},
	{ 51, 255, 102, 255}, { 51, 255,  51, 255}, { 51, 255,   0, 255},
	{ 51, 204, 255, 255}, { 51, 204, 204, 255}, { 51, 204, 153, 255},
	{ 51, 204, 102, 255}, { 51, 204,  51, 255}, { 51, 204,   0, 255},
	{ 51, 153, 255, 255}, { 51, 153, 204, 255}, { 51, 153, 153, 255},
	{ 51, 153, 102, 255}, { 51, 153,  51, 255}, { 51, 153,   0, 255},
	{ 51, 102, 255, 255}, { 51, 102, 204, 255}, { 51, 102, 153, 255},
	{ 51, 102, 102, 255}, { 51, 102,  51, 255}, { 51, 102,   0, 255},
	{ 51,  51, 255, 255}, { 51,  51, 204, 255}, { 51,  51, 153, 255},
	{ 51,  51, 102, 255}, { 51,  51,  51, 255}, { 51,  51,   0, 255},
	{ 51,   0, 255, 255}, { 51,   0, 204, 255}, { 51,   0, 153, 255},
	{ 51,   0, 102, 255}, { 51,   0,  51, 255}, { 51,   0,   0, 255},
	{  0, 255, 255, 255}, {  0, 255, 204, 255}, {  0, 255, 153, 255},
	{  0, 255, 102, 255}, {  0, 255,  51, 255}, {  0, 255,   0, 255},
	{  0, 204, 255, 255}, {  0, 204, 204, 255}, {  0, 204, 153, 255},
	{  0, 204, 102, 255}, {  0, 204,  51, 255}, {  0, 204,   0, 255},
	{  0, 153, 255, 255}, {  0, 153, 204, 255}, {  0, 153, 153, 255},
	{  0, 153, 102, 255}, {  0, 153,  51, 255}, {  0, 153,   0, 255},
	{  0, 102, 255, 255}, {  0, 102, 204, 255}, {  0, 102, 153, 255},
	{  0, 102, 102, 255}, {  0, 102,  51, 255}, {  0, 102,   0, 255},
	{  0,  51, 255, 255}, {  0,  51, 204, 255}, {  0,  51, 153, 255},
	{  0,  51, 102, 255}, {  0,  51,  51, 255}, {  0,  51,   0, 255},
	{  0,   0, 255, 255}, {  0,   0, 204, 255}, {  0,   0, 153, 255},
	{  0,   0, 102, 255}, {  0,   0,  51, 255}, {238,   0,   0, 255},
	{221,   0,   0, 255}, {187,   0,   0, 255}, {170,   0,   0, 255},
	{136,   0,   0, 255}, {119,   0,   0, 255}, { 85,   0,   0, 255},
	{ 68,   0,   0, 255}, { 34,   0,   0, 255}, { 17,   0,   0, 255},
	{  0, 238,   0, 255}, {  0, 221,   0, 255}, {  0, 187,   0, 255},
	{  0, 170,   0, 255}, {  0, 136,   0, 255}, {  0, 119,   0, 255},
	{  0,  85,   0, 255}, {  0,  68,   0, 255}, {  0,  34,   0, 255},
	{  0,  17,   0, 255}, {  0,   0, 238, 255}, {  0,   0, 221, 255},
	{  0,   0, 187, 255}, {  0,   0, 170, 255}, {  0,   0, 136, 255},
	{  0,   0, 119, 255}, {  0,   0,  85, 255}, {  0,   0,  68, 255},
	{  0,   0,  34, 255}, {  0,   0,  17, 255}, {238, 238, 238, 255},
	{221, 221, 221, 255}, {187, 187, 187, 255}, {170, 170, 170, 255},
	{136, 136, 136, 255}, {119, 119, 119, 255}, { 85,  85,  85, 255},
	{ 68,  68,  68, 255}, { 34,  34,  34, 255}, { 17,  17,  17, 255}
];
