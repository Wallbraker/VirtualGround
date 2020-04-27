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
import ground.gfx.miners.lines;
import ground.gfx.miners.quads;


enum TextureLayer
{
	Bedrock = 1,
	Stone,
	Dirt,
	GrassOverlay,
	GrassSide,
	GrassTop,
	Wood,
	Planks,
	Leaves,
	Sand,
	Sandstone,
}

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

	tex.loadImport(TextureLayer.Bedrock, "pp/blocks/bedrock_0.png", import("pp/assets/minecraft/textures/block/bedrock.png"));
	tex.loadImport(TextureLayer.Stone, "pp/blocks/stone_0.png", import("pp/assets/minecraft/textures/block/stone.png"));
	tex.loadImport(TextureLayer.Dirt, "pp/blocks/dirt_0.png", import("pp/assets/minecraft/textures/block/dirt.png"));
	tex.loadImport(TextureLayer.GrassOverlay, "pp/blocks/grass_overlay_0.png", import("pp/assets/minecraft/textures/block/grass_block_side_overlay.png"));
	tex.loadImport(TextureLayer.GrassSide, "pp/blocks/grass_side_0.png", import("pp/assets/minecraft/textures/block/grass_block_side.png"));
	tex.loadImport(TextureLayer.GrassTop, "pp/blocks/grass_top_0.png", import("pp/assets/minecraft/textures/block/grass_block_top.png"));

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
	global empty: ChunkData;
	chunks: ChunkData*[4][4][4];

	offX, offY, offZ: i32;


public:
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
					case 8: d = Id.GrassBlock; break;
					default: d = Id.Air; break;
					}
				}
			}
		}

		fn clearY(x: i32, z: i32) {
			foreach (y; 1 .. ChunkData.Dim) {
				chunk.data[z][y][x] = Id.Air;
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
		this.makeLines(vb);

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
		id := cast(Id)getData(x, y, z);
		final switch (id) with (Id) {
		case Air: return;
		case Bedrock, Stone, Dirt, Wood, Planks, Leaves, Sand, Sandstone:
			layer := getTextureLayer(id);
			this.addQuadsIfNotSolid(vb, x, y, z, layer, math.Color4b.White);
			break;
		case GrassBlock:
			handleGrassBlock(vb, x, y, z);
			break;
		}
	}

	fn handleGrassBlock(vb: VoxelBufferBuilder, x: i32, y: i32, z: i32)
	{
		green: math.Color4b = {109, 196, 117, 255};

		this.addQuadXNIfSolid(vb, x, y, z, TextureLayer.GrassSide, math.Color4b.White);
		this.addQuadXPIfSolid(vb, x, y, z, TextureLayer.GrassSide, math.Color4b.White);
		this.addQuadYNIfSolid(vb, x, y, z, TextureLayer.Dirt, math.Color4b.White);
		this.addQuadYPIfSolid(vb, x, y, z, TextureLayer.GrassTop, green);
		this.addQuadZNIfSolid(vb, x, y, z, TextureLayer.GrassSide, math.Color4b.White);
		this.addQuadZPIfSolid(vb, x, y, z, TextureLayer.GrassSide, math.Color4b.White);
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

		return &chunks[cx][cy][cz].data[bz][by][bx];
	}

	fn getTextureLayer(id: Id) u32
	{
		final switch (id) with (Id) {
		case Air, GrassBlock: return 0;
		case Bedrock: return TextureLayer.Bedrock;
		case Stone: return TextureLayer.Stone;
		case Dirt: return TextureLayer.Dirt;
		case Wood: return TextureLayer.Wood;
		case Planks: return TextureLayer.Planks;
		case Leaves: return TextureLayer.Leaves;
		case Sand: return TextureLayer.Sand;
		case Sandstone: return TextureLayer.Sandstone;
		}
	}
}