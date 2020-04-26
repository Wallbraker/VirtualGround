// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Code to to create minecraft like VoxelModels.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.gfx.miners;

import core.exception;

import lib.gl.gl45;

import watt = [watt.io.file];
import math = charge.math;
import gfx = charge.gfx;
import sys = charge.sys;

import io = watt.io.file;

import ground.gfx.voxel;
import ground.gfx.builder;
import ground.miners.data;
import ground.miners.chunk;


fn makeTexture() gfx.Texture2DArray
{
	tex := gfx.Texture2DArray.makeRGBA8("ground/tex/miners", 16, 16, 256, 5);

	colors: math.Color4b[16][16];
	foreach (ref y; colors) {
		foreach (ref x; y) {
			x = math.Color4b.White;
		}
	}

	red: math.Color4b = {128, 64, 64, 0};
	blue: math.Color4b = {64, 64, 128, 0};
	makeSolid16(tex, 0, math.Color4b.White);
	makeSolid16(tex, 1, blue);
	makeSolid16(tex, 2, red);

	tex.loadImport(Id.Bedrock, "pp/blocks/bedrock_0.png", import("pp/assets/minecraft/textures/block/bedrock.png"));
	tex.loadImport(Id.Stone, "pp/blocks/stone_0.png", import("pp/assets/minecraft/textures/block/stone.png"));
	tex.loadImport(Id.Dirt, "pp/blocks/dirt_0.png", import("pp/assets/minecraft/textures/block/dirt.png"));
	tex.loadImport(Id.Grass, "pp/blocks/grass_side_0.png", import("pp/assets/minecraft/textures/block/grass_block_side.png"));

	glGenerateTextureMipmap(tex.id);

	return tex;
}

fn loadImport(tex: gfx.Texture2DArray, layer: GLint, filename: string, data: string)
{
	try {
		file := sys.File.fromImport(filename, data);
		tex.loadImageIntoLayer(file, layer);
	} catch (Exception e) {
	}
}

fn makeSolid16(tex: gfx.Texture2DArray,
               layer: GLint,
               color: math.Color4b)
{
	colors: math.Color4b[16][16];
	foreach (i, ref y; colors) {
		foreach (ref x; y) {
			x = color;
		}
	}

	glTextureSubImage3D(tex.id,           // texture
	                    0,                // level
	                    0,                // xoffset
	                    0,                // yoffset
	                    layer,            // zoffset
	                    16,               // width
	                    16,               // height
	                    1,                // depth
	                    GL_RGBA,          // format
	                    GL_UNSIGNED_BYTE, // type
	                    cast(void*)&colors);
}

/*!
 * A very simple mesh maker.
 */
struct VoxelMeshMaker
{
public:
	enum NumChinks = 4;
	enum WorkSize = ChunkData.Dim * 4;
	enum DimX = cast(i32)(WorkSize);
	enum DimY = cast(i32)(WorkSize);
	enum DimZ = cast(i32)(WorkSize);
	enum StrideX = cast(i32)(1);
	enum StrideY = cast(i32)(DimX);
	enum StrideZ = cast(i32)(DimX * DimY);
	enum Size = cast(i32)(DimX * DimY * DimZ);

	//enum StartOffset = ChunkData.Dim = 

	enum XN = StrideX * -1;
	enum XP = StrideX * +1;
	enum YN = StrideY * -1;
	enum YP = StrideY * +1;
	enum ZN = StrideZ * -1;
	enum ZP = StrideZ * +1;

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


public:
	global empty: ChunkData;
	chunks: ChunkData*[4][4][4];

	offX, offY, offZ: i32;

	fn makeStoneChunk() VoxelBufferBuilder
	{
		chunk: ChunkData;
		foreach (z, ref arr_xy; chunk.data) {
			foreach (y, ref arr_x; arr_xy) {
				foreach (x, ref d; arr_x) {
					switch (y) {
					case 0: d = Id.Bedrock; break;
					case 1, 2, 3, 4, 5: d = Id.Stone; break;
					case 6, 7: d = Id.Dirt; break;
					case 8: d = Id.Grass; break;
					default: d = Id.Air; break;
					}
				}
			}
		}

		fn clearY(x: i32, z: i32) {
			foreach (y; 1 .. ChunkData.Dim) {
				chunk.data[x][y][z] = Id.Air;
			}
		}
		              clearY(7, 1); clearY(8, 1);
		clearY(6, 2); clearY(7, 2); clearY(8, 2); clearY(9, 2);
		clearY(6, 3); clearY(7, 3); clearY(8, 3); clearY(9, 3);
		              clearY(7, 4); clearY(8, 4);

		return makeChunk(&chunk);
	}

	fn makeChunk(chunk: ChunkData*) VoxelBufferBuilder
	{
		foreach (ref x; chunks) {
			foreach (ref y; x) {
				foreach (ref z; y) {
					z = &empty;
				}
			}
		}

		offX = offY = offZ = ChunkData.Dim;

		chunks[1][1][1] = chunk;

		vb := new VoxelBufferBuilder();
		makeQuads(vb);
		vb.switchToLines();
		makeLines(vb);

		return vb;
	}

	fn makeQuads(vb: VoxelBufferBuilder)
	{
		start := ChunkData.Dim;
		stop := start + ChunkData.Dim;

		foreach (z; start .. stop) {
			foreach (y; start .. stop) {
				foreach (x; start .. stop) {
					handleQuadVoxel(vb, x, y, z);
				}
			}
		}
	}

	fn handleQuadVoxel(vb: VoxelBufferBuilder, x: i32, y: i32, z: i32)
	{
		data := getData(x, y, z);
		if (data == 0) {
			return;
		}

		if (getData(x - 1, y, z) == 0) {
			vb.addQuad(x - offX, y - offY, z - offZ,
			           VoxelBufferBuilder.Side.XN,
			           data, math.Color4b.White);
		}
		if (getData(x + 1, y, z) == 0) {
			vb.addQuad(x - offX, y - offY, z - offZ,
			           VoxelBufferBuilder.Side.XP,
			           data, math.Color4b.White);
		}
		if (getData(x, y - 1, z) == 0) {
			vb.addQuad(x - offX, y - offY, z - offZ,
			           VoxelBufferBuilder.Side.YN,
			           data, math.Color4b.White);
		}
		if (getData(x, y + 1, z) == 0) {
			vb.addQuad(x - offX, y - offY, z - offZ,
			           VoxelBufferBuilder.Side.YP,
			           data, math.Color4b.White);
		}
		if (getData(x, y, z - 1) == 0) {
			vb.addQuad(x - offX, y - offY, z - offZ,
			           VoxelBufferBuilder.Side.ZN,
			           data, math.Color4b.White);
		}
		if (getData(x, y, z + 1) == 0) {
			vb.addQuad(x - offX, y - offY, z - offZ,
			           VoxelBufferBuilder.Side.ZP,
			           data, math.Color4b.White);
		}
	}

	fn makeLines(vb: VoxelBufferBuilder)
	{
		start := ChunkData.Dim;
		stop := start + ChunkData.Dim + 1;

		foreach (z; start .. stop) {
			foreach (y; start .. stop) {
				handleLineX(vb, y, z);
			}
		}

		foreach (z; start .. stop) {
			foreach (x; start .. stop) {
				handleLineY(vb, x, z);
			}
		}

		foreach (y; start .. stop) {
			foreach (x; start .. stop) {
				handleLineZ(vb, x, y);
			}
		}
	}

	fn handleLineX(b: VoxelBufferBuilder, y: i32, z: i32)
	{
		lines: u8[257];
		start := ChunkData.Dim;
		stop := start + ChunkData.Dim + 1;

		foreach (x; start .. stop) {
			data: u32;
			data |= getData(x, y, z).isSolid() << 0u;
			data |= getData(x, y - 1, z).isSolid() << 1u;
			data |= getData(x, y, z - 1).isSolid() << 2u;
			data |= getData(x, y - 1, z - 1).isSolid() << 3u;
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
				b.addLineVertex(cast(f32)(x - offX) - lineNudges[current], cast(f32)(y - offY), cast(f32)(z - offZ), lineColors[current]);
			}

			if (line != 0) {
				b.addLineVertex(cast(f32)(x - offX) + lineNudges[line], cast(f32)(y - offY), cast(f32)(z - offZ), lineColors[line]);
			}

			current = line;
		}
	}

	fn handleLineY(b: VoxelBufferBuilder, x: i32, z: i32)
	{
		lines: u8[257];
		start := ChunkData.Dim;
		stop := start + ChunkData.Dim + 1;

		foreach (y; start .. stop) {
			data: u32;
			data |= getData(x, y, z).isSolid() << 0u;
			data |= getData(x - 1, y, z).isSolid() << 1u;
			data |= getData(x, y, z - 1).isSolid() << 2u;
			data |= getData(x - 1, y, z - 1).isSolid() << 3u;
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
				b.addLineVertex(cast(f32)(x - offX), cast(f32)(y - offY)  - lineNudges[current], cast(f32)(z - offZ), lineColors[current]);
			}

			if (line != 0) {
				b.addLineVertex(cast(f32)(x - offX), cast(f32)(y - offY) + lineNudges[line], cast(f32)(z - offZ), lineColors[line]);
			}

			current = line;
		}
	}

	fn handleLineZ(b: VoxelBufferBuilder, x: i32, y: i32)
	{
		lines: u8[257];
		start := ChunkData.Dim;
		stop := start + ChunkData.Dim + 1;

		foreach (z; start .. stop) {
			data: u32;
			data |= getData(x, y, z).isSolid() << 0u;
			data |= getData(x - 1, y, z).isSolid() << 1u;
			data |= getData(x, y - 1, z).isSolid() << 2u;
			data |= getData(x - 1, y -1, z).isSolid() << 3u;
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
				b.addLineVertex(cast(f32)(x - offX), cast(f32)(y - offY), cast(f32)(z - offZ) - lineNudges[current], lineColors[current]);
			}

			if (line != 0) {
				b.addLineVertex(cast(f32)(x - offX), cast(f32)(y - offY), cast(f32)(z - offZ) + lineNudges[line], lineColors[line]);
			}

			current = line;
		}
	}

	fn getData(x: i32, y: i32, z: i32) u8
	{
		return *getDataPtr(x, y, z);
	}

	fn getDataPtr(x: i32, y: i32, z: i32) u8*
	{
		cx := x / ChunkData.Dim;
		cy := y / ChunkData.Dim;
		cz := z / ChunkData.Dim;
		bx := x % ChunkData.Dim;
		by := y % ChunkData.Dim;
		bz := z % ChunkData.Dim;

		return &chunks[cx][cy][cz].data[bx][by][bz];
	}
}
