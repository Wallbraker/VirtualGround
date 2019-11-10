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
import gfx = [charge.gfx, ground.gfx.view];
import math = charge.math;

import watt.math;

import ground.gfx.voxel;
import ground.gfx.magica;


class Scene
{
public:
	texLogo: gfx.Texture;
	texWhite: gfx.Texture;
	buf: gfx.SimpleBuffer;

	mVoxelStore: GLuint;
	mNumVerticies: GLsizei;


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
		buf = gfx.SimpleBuffer.make("ground/gfx/ground", b);
		gfx.destroy(ref b);

		hackedScene(out mVoxelStore, out mNumVerticies);
/*
		f := import("test.vox");
		qb := loadFromData(cast(const(u8)[])import("test.vox"));
		qb.bake(out mVoxelStore, out mNumVerticies);
		qb.close();
*/
	}

	fn close()
	{
		gfx.reference(ref buf, null);
		gfx.reference(ref texLogo, null);
		gfx.reference(ref texWhite, null);
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

		drawSquare(ref vp);
		drawVoxel(ref vp);

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

		glBindVertexArray(buf.vao);
		texLogo.bind();
		glDrawArrays(GL_TRIANGLES, 0, buf.num);
		texLogo.unbind();
		glBindVertexArray(0);
	}

	fn drawVoxel(ref vp: math.Matrix4x4d)
	{
		pos := math.Point3f.opCall(-3.0f, -1.0f, -3.0f);
		rot := math.Quatf.opCall(1.0f, 0.0f, 0.0f, 0.0f);
		rot.normalize();

		model: math.Matrix4x4d;
		model.setToModel(ref pos, ref rot);

		matrix: math.Matrix4x4f;
		matrix.setToMultiplyAndTranspose(ref vp, ref model);

		voxelShader.bind();
		voxelShader.matrix4("u_matrix", 1, false, ref matrix);

		voxelTexture.bind();
		glBindVertexArray(voxelVAO);

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, mVoxelStore);
		glDrawElements(GL_TRIANGLES, mNumVerticies, GL_UNSIGNED_INT, null);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, mVoxelStore);

		glBindVertexArray(0);
		voxelTexture.unbind();
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

fn hackedScene(out buf: GLuint, out num: GLsizei)
{
	b := new VoxelQuadBuilder();

	W := math.Color4b.White;
	R := math.Color4b.from(1.0f, 0.5f, 0.5f, 1.0f);
	G := math.Color4b.from(0.5f, 1.0f, 0.5f, 1.0f);
	B := math.Color4b.from(0.5f, 0.5f, 1.0f, 1.0f);
	tex := 0x0_u32;

	with (VoxelQuadBuilder.Side) {
		b.add(0, 1, 1, XP, tex, W);
		b.add(0, 1, 2, XP, tex, R);
		b.add(0, 1, 3, XP, tex, G);
		b.add(0, 1, 4, XP, tex, B);

		b.add(1, 1, 0, ZP, tex, B);
		b.add(2, 1, 0, ZP, tex, W);
		b.add(3, 1, 0, ZP, tex, R);
		b.add(4, 1, 0, ZP, tex, G);

		b.add(1, 0, 1, YP, tex, R);
		b.add(1, 0, 2, YP, tex, W);
		b.add(1, 0, 3, YP, tex, B);
		b.add(1, 0, 4, YP, tex, G);
		b.add(2, 0, 1, YP, tex, G);
		b.add(2, 0, 2, YP, tex, R);
		b.add(2, 0, 3, YP, tex, W);
		b.add(2, 0, 4, YP, tex, B);
		b.add(3, 0, 1, YP, tex, B);
		b.add(3, 0, 2, YP, tex, G);
		b.add(3, 0, 3, YP, tex, R);
		b.add(3, 0, 4, YP, tex, W);
		b.add(4, 0, 1, YP, tex, W);
		b.add(4, 0, 2, YP, tex, B);
		b.add(4, 0, 3, YP, tex, G);
		b.add(4, 0, 4, YP, tex, R);

		b.add(0, 1, 0, YP, tex, B);
		b.add(1, 1, 0, YP, tex, W);
		b.add(2, 1, 0, YP, tex, R);
		b.add(3, 1, 0, YP, tex, G);
		b.add(4, 1, 0, YP, tex, B);
		b.add(0, 1, 1, YP, tex, G);
		b.add(0, 1, 2, YP, tex, R);
		b.add(0, 1, 3, YP, tex, W);
		b.add(0, 1, 4, YP, tex, B);
	}

	b.bake(out buf, out num);
	b.close();
}
