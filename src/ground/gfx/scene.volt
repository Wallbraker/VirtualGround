// Copyright 2019, Collabora, Ltd.
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

import watt.math;

import ground.gfx.voxel;
import ground.gfx.magica;
import ground.gfx.builder;


global gGroundObj: VoxelObject;
global gPsMvBall: VoxelObject[2];
global gPsMvComplete: VoxelObject[2];
global gPsMvControllerOnly: VoxelObject[2];

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

	gGroundObj.active = true;
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
	completeBuf := loadModel("ground/psmv/no_ball", import("hardware/psmv_complete.vox"));

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
	texLogo: gfx.Texture;
	texWhite: gfx.Texture;
	mSquareBuf: gfx.SimpleBuffer;


public:
	this()
	{
		file := sys.File.fromImport("default.png", import("default.png"));
		texLogo = gfx.Texture2D.load(file);
		texWhite = gfx.Texture2D.makeRGBA8("ground/tex/white", 1, 1, 1);
		glTextureSubImage2D(texWhite.id, 0, 0, 0, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, cast(void*)&math.Color4b.White);

		fX := -20.0f;
		fZ := -20.0f;
		fXW := 20.0f;
		fZH := 20.0f;

		setupGround();
		setupPsMvs();

		b := new gfx.SimpleVertexBuilder(6);
		b.add(fX,  0.0f, fZ,   0.0f,  0.0f);
		b.add(fXW, 0.0f, fZ,  40.0f,  0.0f);
		b.add(fXW, 0.0f, fZH, 40.0f, 40.0f);
		b.add(fXW, 0.0f, fZH, 40.0f, 40.0f);
		b.add(fX,  0.0f, fZH,  0.0f, 40.0f);
		b.add(fX,  0.0f, fZ,   0.0f,  0.0f);
		mSquareBuf = gfx.SimpleBuffer.make("ground/gfx/ground", b);
		gfx.destroy(ref b);
	}

	fn close()
	{
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

		gfx.reference(ref texLogo, null);
		gfx.reference(ref texWhite, null);
		gfx.reference(ref mSquareBuf, null);
	}

	fn renderView(target: gfx.Target, ref viewInfo: gfx.ViewInfo)
	{
		proj: math.Matrix4x4d;
		proj.setToFrustum(ref viewInfo.fov, 0.05, 256.0);

		view: math.Matrix4x4d;
		view.setToLookFrom(ref viewInfo.position, ref viewInfo.rotation);

		vp: math.Matrix4x4d;
		vp.setToMultiply(ref proj, ref view);

		glClearColor(0.6f, 0.6f, 1.0f, 1.0f);
		glClearDepth(1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glBindSampler(0, voxelSampler);

		if (gGroundObj.active) { drawVoxel(ref vp, ref gGroundObj); }
		foreach (ref ball; gPsMvBall) {
			if (ball.active) { drawVoxel(ref vp, ref ball); }
		}
		foreach (ref only; gPsMvControllerOnly) {
			if (only.active) { drawVoxel(ref vp, ref only); }
		}
		foreach (ref complete; gPsMvComplete) {
			if (complete.active) { drawVoxel(ref vp, ref complete); }
		}

		glBindSampler(0, 0);
		glDisable(GL_DEPTH_TEST);

		gfx.glCheckError();
		glFlush();
		gfx.glCheckError();
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

	fn drawVoxel(ref vp: math.Matrix4x4d, ref obj: VoxelObject)
	{
		model: math.Matrix4x4d;
		model.setToModel(ref obj.pos, ref obj.rot, ref obj.scale, ref obj.origin);

		matrix: math.Matrix4x4f;
		matrix.setToMultiplyAndTranspose(ref vp, ref model);

		// Shared for everything.
		texWhite.bind();

		// Draw the voxels.
		voxelShader.bind();
		voxelShader.matrix4("u_matrix", 1, false, ref matrix);

		glBindVertexArray(voxelVAO);
		glEnable(GL_POLYGON_OFFSET_FILL);
		glPolygonOffset(1.0f, 1.0f);

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, obj.buf.buf);
		glDrawElements(GL_TRIANGLES, obj.buf.numQuadDatas * 6, GL_UNSIGNED_INT, null);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, 0);

		glDisable(GL_POLYGON_OFFSET_FILL);
		glBindVertexArray(0);

		// Draw the lines.
		gfx.simpleShader.bind();
		gfx.simpleShader.matrix4("matrix", 1, false, ref matrix);

		glBindVertexArray(obj.buf.vao);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glDrawArrays(GL_LINES, 0, obj.buf.numLineVertices);

		glDisable(GL_BLEND);
		glBindVertexArray(0);

		// Finally remove the texture.
		texWhite.unbind();
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
