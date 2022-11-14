// Copyright 2019-2022, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  A single scene that can be rendered from multiple views.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.gfx.scene;

import lib.gl.gl45;
import core.c.stdio;

import sys = charge.sys;
import gfx = charge.gfx;
import math = charge.math;
import tui = charge.game.tui;

import io = watt.io;
import text = [
	watt.text.sink,
	core.rt.format,
	];


import watt.math;

import miners = [
	ground.miners.data,
	ground.miners.chunk,
	ground.miners.fixed,
	ground.gfx.miners,
	];

import ground.gfx.voxel;
import ground.gfx.magica;
import ground.gfx.builder;

import amp.openxr;
import charge.core.openxr;
import charge.core.openxr.enumerate;


struct Pose
{
	rot: math.Quatf;
	pos: math.Point3f;
};

global gViewSpace: Pose;
global gGroundObj: VoxelObject;
global gPsMvBall: VoxelObject[2];
global gStaticModels: VoxelObject[2];
global gPsMvComplete: VoxelObject[2];
global gPsMvControllerOnly: VoxelObject[2];
global gAxis: VoxelObject[16];
global gChunks: VoxelObject[1024];

fn setupAxis()
{
	lightRed: const(math.Color4b)   = {255, 128, 128, 255};
	lightGreen: const(math.Color4b) = {128, 255, 128, 255};
	lightBlue: const(math.Color4b)  = {128, 128, 255, 255};
	darkRed: const(math.Color4b)    = {128,   0,   0, 255};
	darkGreen: const(math.Color4b)  = {  0, 128,   0, 255};
	darkBlue: const(math.Color4b)   = {  0,   0, 128, 255};

	d := 1.0f;

	vb := new VoxelBufferBuilder();
	// No quads
	vb.switchToLines();
	vb.addLineVertex(0.0f, 0.0f, 0.0f, lightRed);
	vb.addLineVertex(   d, 0.0f, 0.0f, lightRed);
	vb.addLineVertex(0.0f, 0.0f, 0.0f, lightGreen);
	vb.addLineVertex(0.0f,    d, 0.0f, lightGreen);
	vb.addLineVertex(0.0f, 0.0f, 0.0f, lightBlue);
	vb.addLineVertex(0.0f, 0.0f,    d, lightBlue);
	vb.addLineVertex(0.0f, 0.0f, 0.0f, darkRed);
	vb.addLineVertex(  -d, 0.0f, 0.0f, darkRed);
	vb.addLineVertex(0.0f, 0.0f, 0.0f, darkGreen);
	vb.addLineVertex(0.0f,   -d, 0.0f, darkGreen);
	vb.addLineVertex(0.0f, 0.0f, 0.0f, darkBlue);
	vb.addLineVertex(0.0f, 0.0f,   -d, darkBlue);

	buf := VoxelBuffer.make("ground/voxel/axis", vb);
	vb.close();

	foreach (ref obj; gAxis) {
		obj.active = false;
		reference(ref obj.buf, buf);
		obj.rot = math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);
		obj.rot.normalize();
		obj.scale = math.Vector3f.opCall(1.0f, 1.0f, 1.0f);
		obj.origin = math.Point3f.opCall(0.0f, 0.0f, 0.0f);
	}

	reference(ref buf, null);
}

fn setupGround()
{
	dim := 32u;
	white: const(math.Color4b) = {192, 192, 192, 255};
	black: const(math.Color4b) = { 64,  64,  64, 255};

	sharedMeshMaker.reset();
	sharedMeshMaker.setSize(dim, 1, dim);
	sharedMeshMaker.colors[1] = white;
	sharedMeshMaker.colors[3] = black;

	foreach (x; 0 .. cast(i32)dim) {
		foreach (z; 0 .. cast(i32)dim) {
			c := ((x & 2) ^ (z & 2)) + 1;
			sharedMeshMaker.setVoxel(x, 0, z, cast(u8)c);
		}
	}

	vb := sharedMeshMaker.makeVoxelBufferBuilder();
	buf := VoxelBuffer.make("ground/voxel/ground", vb);
	vb.close();

	gGroundObj.active = false;
	gGroundObj.buf = buf;
	gGroundObj.rot = math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);
	gGroundObj.rot.normalize();
	gGroundObj.scale = math.Vector3f.opCall(0.5f, 0.5f, 0.5f);
	gGroundObj.origin = math.Point3f.opCall(dim / 2.0f, 1, dim / 2.0f);
}

fn loadModel(name: string, data: string) VoxelBuffer
{
	vb := loadFromData(cast(const(u8)[])data);
	buf := VoxelBuffer.make(name, vb);
	destroy(ref vb);
	return buf;
}

fn setupPsMvs()
{
	ballBuf := loadModel("ground/psmv/ball", import("hardware/psmv_only_ball.vox"));
	noBallBuf := loadModel("ground/psmv/no_ball", import("hardware/psmv_no_ball.vox"));
	completeBuf := loadModel("ground/psmv/complete", import("hardware/psmv_complete.vox"));

	foreach (ref ball; gPsMvBall) {
		reference(ref ball.buf, ballBuf);
		ball.rot = math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);
		ball.rot.normalize();
		ball.scale = math.Vector3f.opCall(0.005f, 0.005f, 0.005f);
		ball.origin = math.Point3f.opCall(4.5f, 4.5f, 4.5f);
	}

	foreach (ref only; gPsMvControllerOnly) {
		reference(ref only.buf, noBallBuf);
		only.rot = math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);
		only.rot.normalize();
		only.scale = math.Vector3f.opCall(0.005f, 0.005f, 0.005f);
		only.origin = math.Point3f.opCall(4.5f, 17.0f, 4.5f);
	}

	foreach (ref complete; gPsMvComplete) {
		reference(ref complete.buf, completeBuf);
		complete.rot = math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);
		complete.rot.normalize();
		complete.scale = math.Vector3f.opCall(0.005f, 0.005f, 0.005f);
		complete.origin = math.Point3f.opCall(4.5f, 17.0f, 4.5f);
	}

	reference(ref ballBuf, null);
	reference(ref noBallBuf, null);
	reference(ref completeBuf, null);
}

fn setupVoxModels()
{
	m: VoxelBuffer[2];
	m[0] = loadModel("model/01", import("kluchek-vox-models/#street/#street_scene.vox"));
	m[1] = loadModel("model/02", import("kluchek-vox-models/#treehouse/#treehouse.vox"));

	pos: f32 = -cast(f32)(gStaticModels.length / 2);
	foreach (i, ref obj; gStaticModels) {
		obj.pos = math.Point3f.opCall(pos, 0.5f, -1.0f);
		obj.rot = math.Quatf.opCall(0.0f, 0.0f, 1.0f, 0.0f);
		obj.rot.normalize();
		obj.scale = math.Vector3f.opCall(0.02f, 0.02f, 0.02f);
		obj.origin = math.Point3f.opCall(0.f, 0.f, 0.f);
		obj.active = true;
		reference(ref obj.buf, m[i % m.length]);
		pos += 3.0f;
	}

	foreach (ref buf; m) {
		reference(ref buf, null);
	}
}

fn setupChunk()
{
	buf: VoxelBuffer;
	minersMeshMaker: miners.VoxelMeshMaker;

	terrain := new miners.FixedTerrain();
	terrain.setYSlice(0, miners.Id.Bedrock);
	foreach (y; 1 .. 13) {
		terrain.setYSlice(y, miners.Id.Stone);
	}
	terrain.setYSlice(13, miners.Id.Dirt);
	terrain.setYSlice(14, miners.Id.Dirt);
	terrain.setYSlice(15, miners.Id.GrassBlock);

	numChunks: size_t;
	for (x: i32; x < miners.FixedTerrain.DimX; x += miners.ChunkData.Dim) {
		for (y: i32; y < miners.FixedTerrain.DimY; y += miners.ChunkData.Dim) {
			for (z: i32; z < miners.FixedTerrain.DimZ; z += miners.ChunkData.Dim) {
				vb := minersMeshMaker.makeChunk(terrain, x, y, z);
				if (vb.empty) {
					vb.close();
					continue;
				}

				buf = VoxelBuffer.make(new "ground/voxel/miners_${x}_${y}_${z}", vb);
				vb.close();
				chunk : VoxelObject* = &gChunks[numChunks++];
				chunk.active = true;
				chunk.buf = buf;
				chunk.rot = math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);
				chunk.rot.normalize();
				chunk.pos = math.Point3f.opCall(0.0f, 0.0f, 0.0f);
				chunk.scale = math.Vector3f.opCall(1.0f, 1.0f, 1.0f);
				chunk.origin = math.Point3f.opCall(64.0f, 16.0f, 64.0f);
			}
		}
	}

	terrain.close();
}

fn setupQuad()
{
	if (gOpenXR.headless) {
		return;
	}

	width: u32 = 64;
	height: u32 = 64;
	data: math.Color4b[64][64];

	foreach (y, ref xarr; data) {
		foreach (x, ref colour; xarr) {
			alpha: u8 = 255;

			if (x >= 16 && x < 48 &&
			    y >= 16 && y < 48) {
			        alpha = 0;
			}

			xv := cast(u8)((cast(f32)x / (width - 1)) * 255);
			yv := cast(u8)((cast(f32)y / (height - 1)) * 255);

			colour = math.Color4b.from(xv, yv, 0, alpha);
		}
	}

	q := &gOpenXR.quadHack;
	q.create(ref gOpenXR, width, height);
	q.active = false; // Start off inactive.

	waitInfo: XrSwapchainImageWaitInfo;
	waitInfo.type = XR_TYPE_SWAPCHAIN_IMAGE_WAIT_INFO;

	index: u32;
	xrAcquireSwapchainImage(q.swapchain, null, &index);
	xrWaitSwapchainImage(q.swapchain, &waitInfo);
	glTextureSubImage2D(q.textures[index],
	                    0,
	                    0,
	                    0, // yoffset
	                    cast(GLsizei)width,
	                    cast(GLsizei)height,
	                    GL_RGBA,
	                    GL_UNSIGNED_BYTE,
	                    cast(void*)data.ptr);
	xrReleaseSwapchainImage(q.swapchain, null);

	q.pose.position.x = 0.0f;
	q.pose.position.y = 1.0f;
	q.pose.position.z = -2.0f;
	q.pose.orientation.w = 1.0f;
	q.size.width = 1.0f;
	q.size.height = 1.0f;
}

fn prettyF32(f: f32) string
{
	s: text.StringSink;
	text.vrt_format_f32(s.sink, f, 3, true);
	return s.toString();
}

struct VoxelObject
{
public:
	active: bool;
	buf: VoxelBuffer;
	pos: math.Point3f;
	rot: math.Quatf;
	scale: math.Vector3f;
	origin: math.Point3f;


public:
	fn close()
	{
		reference(ref buf, null);
	}
}

class Scene
{
public:
	enum GLYPH_NUM_WIDTH : u32 = 46;
	enum GLYPH_NUM_HEIGHT : u32 = 7;

	texLogo: gfx.Texture;
	texWhite: gfx.Texture;
	texWhiteArray: gfx.Texture;
	mSquareBuf: gfx.SimpleBuffer;

	// Text rendering stuff.
	mGrid : tui.Grid;
	mGridScale: f32 = 0.005f;


public:
	this()
	{
		file := sys.File.fromImport("default.png", import("default.png"));
		texLogo = gfx.Texture2D.load(file);
		texWhite = gfx.Texture2D.makeRGBA8("ground/tex/white", 1, 1, 1);
		glTextureSubImage2D(texWhite.id,      // texture
		                    0,                // level
		                    0,                // xoffset
		                    0,                // yoffset
		                    1,                // width
		                    1,                // height
		                    GL_RGBA,          // format
		                    GL_UNSIGNED_BYTE, // type
		                    cast(void*)&math.Color4b.White);
		texWhiteArray = miners.makeTexture();

		fX := -20.0f;
		fZ := -20.0f;
		fXW := 20.0f;
		fZH := 20.0f;

		setupAxis();
		setupGround();
		setupPsMvs();
		setupChunk();
		setupVoxModels();

		b := new gfx.SimpleVertexBuilder(6);
		b.add(fX,  0.0f, fZ,   0.0f,  0.0f);
		b.add(fXW, 0.0f, fZ,  40.0f,  0.0f);
		b.add(fXW, 0.0f, fZH, 40.0f, 40.0f);
		b.add(fXW, 0.0f, fZH, 40.0f, 40.0f);
		b.add(fX,  0.0f, fZH,  0.0f, 40.0f);
		b.add(fX,  0.0f, fZ,   0.0f,  0.0f);
		mSquareBuf = gfx.SimpleBuffer.make("ground/gfx/ground", b);
		gfx.destroy(ref b);

		setupQuad();

		mGrid = new tui.Grid(GLYPH_NUM_WIDTH, GLYPH_NUM_HEIGHT);
	}

	fn close()
	{
		gOpenXR.quadHack.destroy(ref gOpenXR);

		gGroundObj.close();
		foreach (ref ball; gPsMvBall) {
			ball.close();
		}
		foreach (ref only; gPsMvControllerOnly) {
			only.close();
		}
		foreach (ref complete; gPsMvComplete) {
			complete.close();
		}
		foreach (ref axis; gAxis) {
			axis.close();
		}
		foreach (ref chunk; gChunks) {
			chunk.close();
		}
		foreach (ref staticModel; gStaticModels) {
			staticModel.close();
		}

		gfx.reference(ref texLogo, null);
		gfx.reference(ref texWhite, null);
		gfx.reference(ref texWhiteArray, null);
		gfx.reference(ref mSquareBuf, null);

		mGrid.close();
		mGrid = null;
	}

	fn renderPrepare()
	{
		s: text.StringSink;
		mGrid.reset();

		tui.makeFrameSingle(mGrid, 0, 0, GLYPH_NUM_WIDTH, GLYPH_NUM_HEIGHT);
		s.sink("FrameID: ");
		text.vrt_format_i64(s.sink, gOpenXR.frameID);
		tui.makeCenteredText(mGrid, 0, 1, GLYPH_NUM_WIDTH, s.borrowUnsafe());

		foreach (i, ref view; gOpenXR.views) {
			pos := view.location.position;
			px := pos.x.prettyF32();
			py := pos.y.prettyF32();
			pz := pos.z.prettyF32();

			ori := view.location.orientation;
			ox := ori.x.prettyF32();
			oy := ori.y.prettyF32();
			oz := ori.z.prettyF32();
			ow := ori.w.prettyF32();

			str := new "x: ${px}, y: ${py}, z: ${pz}\nx: ${ox}, y: ${oy}, z: ${oz}, w: ${ow}";
			tui.makeText(mGrid, 2, 2 + 2 * cast(i32)i, str);
		}
	}

	fn renderView(target: gfx.Target, ref viewInfo: gfx.ViewInfo)
	{
		proj: math.Matrix4x4d;
		proj.setToFrustum(ref viewInfo.fov, 0.05, 256.0);

		view: math.Matrix4x4d;
		view.setToLookFrom(ref viewInfo.position, ref viewInfo.rotation);

		vp: math.Matrix4x4d;
		vp.setToMultiply(ref proj, ref view);

		if (gOpenXR.overlay || gOpenXR.ar) {
			glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
		} else {
			glClearColor(0.6f, 0.6f, 1.0f, 1.0f);
		}

		glClearDepth(1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glBindSampler(0, voxelSampler);
		glLineWidth(2.0f);

		objs: VoxelObject*[1024];
		count: u32;

		if (gGroundObj.active) { objs[count++] = &gGroundObj; }
		foreach (ref ball; gPsMvBall) {
			if (ball.active) { objs[count++] = &ball; }
		}
		foreach (ref only; gPsMvControllerOnly) {
			if (only.active) { objs[count++] = &only; }
		}
		foreach (ref complete; gPsMvComplete) {
			if (complete.active) { objs[count++] = &complete; }
		}
		foreach (ref axis; gAxis) {
			if (axis.active) { objs[count++] = &axis; }
		}
		foreach (ref staticModel; gStaticModels) {
			if (staticModel.active) { objs[count++] = &staticModel; }
		}
		if (!gOpenXR.overlay && !gOpenXR.ar) {
			foreach (ref chunk; gChunks) {
				if (chunk.active) { objs[count++] = &chunk; }
			}
		}

		drawVoxelQuads(ref vp, objs[0 .. count]);
		drawVoxelLines(ref vp, objs[0 .. count]);

		glLineWidth(1.0f);

		drawText(target, ref vp);

		glBindSampler(0, 0);
		glDisable(GL_DEPTH_TEST);

		gfx.glCheckError();
	}

	fn drawText(target: gfx.Target, ref vp: math.Matrix4x4d)
	{
		pos := gViewSpace.pos;
		rot := gViewSpace.rot;

		// Place it 1.5m in front of the view.
		pos += rot * math.Vector3f.opCall(0.0f, 0.0f, -1.5f);

		mGrid.draw(ref vp, ref pos, ref rot, mGridScale);
	}

	fn drawSquare(ref vp: math.Matrix4x4d)
	{
		pos := math.Point3f.opCall(0.0f, -1.0f, 0.0f);
		rot := math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);

		model: math.Matrix4x4d;
		model.setToModel(ref pos, ref rot);

		matrix: math.Matrix4x4f;
		matrix.setToMultiplyAndTranspose(ref vp, ref model);

		gfx.simpleShader.bind();
		gfx.simpleShader.matrix4("matrix", 1, false, ref matrix);

		glBindVertexArray(mSquareBuf.vao);
		texLogo.bind();
		glDrawArrays(GL_TRIANGLES, 0, mSquareBuf.num);
		texLogo.unbind();
		glBindVertexArray(0);
	}

	fn drawVoxelLines(ref vp: math.Matrix4x4d, objs: VoxelObject*[])
	{
		// Swap to the regular 2D texture.
		texWhite.bind();

		// Draw the lines.
		gfx.simpleShader.bind();

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glColorMask(true, true, true, false);

		foreach (obj; objs) {
			if (obj.buf.numLineVertices == 0) {
				continue;
			}

			model: math.Matrix4x4d;
			model.setToModel(ref obj.pos, ref obj.rot, ref obj.scale, ref obj.origin);

			matrix: math.Matrix4x4f;
			matrix.setToMultiplyAndTranspose(ref vp, ref model);

			gfx.simpleShader.matrix4("matrix", 1, false, ref matrix);

			glBindVertexArray(obj.buf.vao);

			glDrawArrays(GL_LINES, 0, obj.buf.numLineVertices);
		}

		glColorMask(true, true, true, true);
		glDisable(GL_BLEND);
		glBindVertexArray(0);

		// Finally remove the texture.
		texWhite.unbind();
	}

	fn drawVoxelQuads(ref vp: math.Matrix4x4d, objs: VoxelObject*[])
	{
		// Shared for everything.
		texWhiteArray.bind();

		// Draw the voxels.
		voxelShader.bind();

		glEnable(GL_POLYGON_OFFSET_FILL);
		glPolygonOffset(1.0f, 1.0f);

		foreach (obj; objs) {
			if (obj.buf.numQuadDatas == 0) {
				continue;
			}

			model: math.Matrix4x4d;
			model.setToModel(ref obj.pos, ref obj.rot, ref obj.scale, ref obj.origin);

			matrix: math.Matrix4x4f;
			matrix.setToMultiplyAndTranspose(ref vp, ref model);

			voxelShader.matrix4("u_matrix", 1, false, ref matrix);

			glBindVertexArray(voxelVAO);

			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, obj.buf.buf);
			glDrawElements(GL_TRIANGLES, obj.buf.numQuadDatas * 6, GL_UNSIGNED_INT, null);
		}

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, 0);

		glDisable(GL_POLYGON_OFFSET_FILL);
		glBindVertexArray(0);

		texWhiteArray.unbind();
	}


private:
	fn dumpMatrix(str: string, ref matrix: math.Matrix4x4d)
	{
		m: math.Matrix4x4f;
		m.setToAndTranspose(ref matrix);

		fprintf(stderr, "Matrix %s!\n", str.ptr);
		for (int i = 0; i < 4; i++) {
			fprintf(stderr, "  %+f, %+f, %+f, %+f\n",
			        m.a[i * 4 + 0],
			        m.a[i * 4 + 1],
			        m.a[i * 4 + 2],
			        m.a[i * 4 + 3]);
		}
	}
}
