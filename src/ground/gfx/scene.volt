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


class Scene
{
public:
	texLogo: gfx.Texture;
	texWhite: gfx.Texture;
	mVoxelTestBuf: VoxelBuffer;
	mVoxelHackBuf: VoxelBuffer;
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

		b := new gfx.SimpleVertexBuilder(6);
		b.add(fX,  0.0f, fZ,   0.0f,  0.0f);
		b.add(fXW, 0.0f, fZ,  40.0f,  0.0f);
		b.add(fXW, 0.0f, fZH, 40.0f, 40.0f);
		b.add(fXW, 0.0f, fZH, 40.0f, 40.0f);
		b.add(fX,  0.0f, fZH,  0.0f, 40.0f);
		b.add(fX,  0.0f, fZ,   0.0f,  0.0f);
		mSquareBuf = gfx.SimpleBuffer.make("ground/gfx/ground", b);
		gfx.destroy(ref b);

		hackedScene(out mVoxelHackBuf);
/*
		f := cast(const(u8)[])import("test.vox");
		vb := loadFromData(f);
		mVoxelTestBuf = VoxelBuffer.make("ground/voxel/test", vb);
		destroy(ref vb);
*/
	}

	fn close()
	{
		reference(ref  mVoxelTestBuf, null);
		reference(ref  mVoxelHackBuf, null);
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

		glClearColor(0.1f, 0.3f, 0.1f, 1.0f);
		glClearDepth(1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glBindSampler(0, voxelSampler);

		if (mVoxelTestBuf !is null) {
			drawVoxel(ref vp, mVoxelTestBuf,
			          math.Point3f.opCall(-32.0f, -18.0f, -50.0f),
			          math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f));
		} else {
			drawVoxel(ref vp, mVoxelHackBuf,
			          math.Point3f.opCall(-3.0f, -1.0f, -3.0f),
			          math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f));
			drawSquare(ref vp);
		}

		glBindSampler(0, 0);
		glDisable(GL_DEPTH_TEST);

		gfx.glCheckError();
		glFlush();
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

	fn drawVoxel(ref vp: math.Matrix4x4d, buf: VoxelBuffer, pos: math.Point3f, rot: math.Quatf)
	{
		rot.normalize();

		model: math.Matrix4x4d;
		model.setToModel(ref pos, ref rot);

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

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, buf.buf);
		glDrawElements(GL_TRIANGLES, buf.numQuadDatas * 6, GL_UNSIGNED_INT, null);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, 0);

		glDisable(GL_POLYGON_OFFSET_FILL);
		glBindVertexArray(0);

		// Draw the lines.
		gfx.simpleShader.bind();
		gfx.simpleShader.matrix4("matrix", 1, false, ref matrix);

		glBindVertexArray(buf.vao);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glDrawArrays(GL_LINES, 0, buf.numLineVertices);

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

fn hackedScene(out buf: VoxelBuffer)
{
	b := new VoxelBufferBuilder();

	W := math.Color4b.White;
	R := math.Color4b.from(1.0f, 0.5f, 0.5f, 1.0f);
	G := math.Color4b.from(0.5f, 1.0f, 0.5f, 1.0f);
	B := math.Color4b.from(0.5f, 0.5f, 1.0f, 1.0f);
	tex := 0x0_u32;

	with (VoxelBufferBuilder.Side) {
		b.addQuad(0, 1, 1, XP, tex, W);
		b.addQuad(0, 1, 2, XP, tex, R);
		b.addQuad(0, 1, 3, XP, tex, G);
		b.addQuad(0, 1, 4, XP, tex, B);

		b.addQuad(1, 1, 0, ZP, tex, B);
		b.addQuad(2, 1, 0, ZP, tex, W);
		b.addQuad(3, 1, 0, ZP, tex, R);
		b.addQuad(4, 1, 0, ZP, tex, G);

		b.addQuad(1, 0, 1, YP, tex, R);
		b.addQuad(1, 0, 2, YP, tex, W);
		b.addQuad(1, 0, 3, YP, tex, B);
		b.addQuad(1, 0, 4, YP, tex, G);
		b.addQuad(2, 0, 1, YP, tex, G);
		b.addQuad(2, 0, 2, YP, tex, R);
		b.addQuad(2, 0, 3, YP, tex, W);
		b.addQuad(2, 0, 4, YP, tex, B);
		b.addQuad(3, 0, 1, YP, tex, B);
		b.addQuad(3, 0, 2, YP, tex, G);
		b.addQuad(3, 0, 3, YP, tex, R);
		b.addQuad(3, 0, 4, YP, tex, W);
		b.addQuad(4, 0, 1, YP, tex, W);
		b.addQuad(4, 0, 2, YP, tex, B);
		b.addQuad(4, 0, 3, YP, tex, G);
		b.addQuad(4, 0, 4, YP, tex, R);

		b.addQuad(0, 1, 0, YP, tex, B);
		b.addQuad(1, 1, 0, YP, tex, W);
		b.addQuad(2, 1, 0, YP, tex, R);
		b.addQuad(3, 1, 0, YP, tex, G);
		b.addQuad(4, 1, 0, YP, tex, B);
		b.addQuad(0, 1, 1, YP, tex, G);
		b.addQuad(0, 1, 2, YP, tex, B);
		b.addQuad(0, 1, 3, YP, tex, W);
		b.addQuad(0, 1, 4, YP, tex, R);
	}

	b.switchToLines();

	buf = VoxelBuffer.make("ground/voxel/hack", b);

	destroy(ref b);
}
