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

import amp.openxr : XrView;

import ground.gfx.voxel;


class Scene
{
public:
	tex: gfx.Texture;
	buf: gfx.SimpleBuffer;


public:
	this()
	{
		file := sys.File.fromImport("default.png", import("default.png"));
		tex = gfx.Texture2D.load(file);

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
	}

	fn close()
	{
		gfx.reference(ref tex, null);
		gfx.reference(ref buf, null);
	}

	fn renderView(ref loc: XrView)
	{
		cameraPosition := *cast(math.Point3f*)&loc.pose.position;
		cameraRotation := *cast(math.Quatf*)&loc.pose.orientation;

		proj: math.Matrix4x4d;
		proj.setToFrustum(loc.fov.angleLeft, loc.fov.angleRight,
		                  loc.fov.angleDown, loc.fov.angleUp,
		                  0.05, 100.0);

		view: math.Matrix4x4d;
		view.setToLookFrom(ref cameraPosition, ref cameraRotation);

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
		tex.bind();
		glDrawArrays(GL_TRIANGLES, 0, buf.num);
		tex.unbind();
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

		glBindVertexArray(buf.vao);
		tex.bind();
		glDrawArrays(GL_TRIANGLES, 0, 6 * (4 * 4 + 4 + 4 + 9));
		tex.unbind();
		glBindVertexArray(0);
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
