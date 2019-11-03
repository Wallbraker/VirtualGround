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
		fY := -20.0f;
		fXW := 20.0f;
		fYH := 20.0f;

		b := new gfx.SimpleVertexBuilder(6);
		b.add(fX,  0.0f, fY,  40.0f,  0.0f);
		b.add(fXW, 0.0f, fY,   0.0f,  0.0f);
		b.add(fXW, 0.0f, fYH,  0.0f, 40.0f);
		b.add(fXW, 0.0f, fYH,  0.0f, 40.0f);
		b.add(fX,  0.0f, fYH, 40.0f, 40.0f);
		b.add(fX,  0.0f, fY,  40.0f,  0.0f);
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

		drawSquare(ref vp);

		glFlush();
	}

	fn drawSquare(ref vp: math.Matrix4x4d)
	{
		pos := math.Point3f.opCall(0.0f, 0.0f, 0.0f);
		rot := math.Quatf.opCall(0.0f, 0.0f, 0.0f, 1.0f);

		model: math.Matrix4x4d;
		model.setToModel(ref pos, ref rot);

		matrix: math.Matrix4x4f;
		matrix.setToMultiplyAndTranspose(ref vp, ref model);

		gfx.simpleShader.bind();
		gfx.simpleShader.matrix4("matrix", 1, false, ref matrix);

		gfx.glCheckError();

		glBindVertexArray(buf.vao);
		tex.bind();

		glDrawArrays(GL_TRIANGLES, 0, buf.num);

		tex.unbind();
		glBindVertexArray(0);

		gfx.glCheckError();
	}


private:
	fn dumpMatrix(ref matrix: math.Matrix4x4d)
	{
		m: math.Matrix4x4f;
		m.setToAndTranspose(ref matrix);

		fprintf(stderr, "Matrix!\n");
		for (int i = 0; i < 4; i++) {
			fprintf(stderr, "  %+f, %+f, %+f, %+f\n",
			        m.a[i * 4 + 0],
			        m.a[i * 4 + 1],
			        m.a[i * 4 + 2],
			        m.a[i * 4 + 3]);
		}
	}
}
