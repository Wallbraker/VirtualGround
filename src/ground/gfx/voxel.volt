// Copyright 2019-2023, Collabora, Ltd.
// SPDX-License-Identifier: MIT OR Apache-2.0 OR BSL-1.0
/*!
 * @brief  A single scene that can be rendered from multiple views.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.gfx.voxel;

import lib.gl.gl45;

import core = charge.core;
import math = charge.math;
import gfx = charge.gfx;
import sys = charge.sys;
import charge.gfx.gl;


/*!
 * Dereference and reference helper function.
 *
 * @param dec Object to dereference passed by reference, set to `inc`.
 * @param inc Object to reference.
 */
fn reference(ref dec: VoxelBuffer, inc: VoxelBuffer)
{
	if (inc !is null) { inc.incRef(); }
	if (dec !is null) { dec.decRef(); }
	dec = inc;
}

/*!
 * Closes and sets reference to null.
 *
 * @param obj Object to be destroyed.
 */
fn destroy(ref obj: VoxelBufferBuilder)
{
	if (obj !is null) { obj.close(); obj = null; }
}

/*!
 * Voxel buffer containing both quad data and line vertices.
 */
class VoxelBuffer : gfx.Buffer
{
public:
	numQuadDatas: GLsizei;
	numLineVertices: GLsizei;


public:
	global fn make(name: string, vb: VoxelBufferBuilder) VoxelBuffer
	{
		dummy: void*;
		buffer := cast(VoxelBuffer)sys.Resource.alloc(
			typeid(VoxelBuffer), uri, name, 0, out dummy);
		buffer.__ctor(0, 0, 0, 0);
		buffer.update(vb);
		return buffer;
	}

	fn update(vb: VoxelBufferBuilder)
	{
		deleteBuffers();
		vb.bake(out vao, out buf, out numQuadDatas, out numLineVertices);
	}


protected:
	this(vao: GLuint, buf: GLuint, numQuadDatas: GLsizei, numLineVertices: GLsizei)
	{
		this.numQuadDatas = numQuadDatas;
		this.numLineVertices = numLineVertices;
		super(vao, buf);
	}

	override fn deleteBuffers()
	{
		super.deleteBuffers();
		numQuadDatas = 0;
		numLineVertices = 0;
	}
}

/*!
 * For building a voxel quad buffer.
 */
class VoxelBufferBuilder : gfx.Builder
{
public:
	//! Which side of the cube is this quad.
	enum Side
	{
		XN,
		XP,
		YN,
		YP,
		ZN,
		ZP,
	}

	//! Layout of the line vertices.
	struct LineVertex
	{
		x, y, z: f32;
		color: math.Color4b;
	}

	//! Layout of the data in the buffer.
	struct QuadData
	{
		x_y: u32;
		z_t: u32;
		rgb_face: u32;
	}

	enum QaudStride = cast(GLsizei)typeid(QuadData).size;
	enum LineStride = cast(GLsizei)typeid(LineVertex).size;


public:
	numQuadDatas: GLsizei;


public:
	this()
	{
		super();
	}

	@property fn empty() bool
	{
		return length <= 0;
	}

	fn addLineVertex(x: f32, y: f32, z: f32, color: math.Color4b)
	{
		lv: LineVertex;
		lv.x = x;
		lv.y = y;
		lv.z = z;
		lv.color = color;

		addLineVertex(lv);
	}

	fn addLineVertex(lv: LineVertex)
	{
		add(cast(void*)&lv, typeid(lv).size);
	}

	fn switchToLines()
	{
		numQuadDatas = cast(GLsizei)length / QaudStride;
	}

	fn addQuad(x: i32, y: i32, z: i32, side: Side, texture: GLuint, color: math.Color4b)
	{
		// Bake side into the alpha channel.
		color.a = cast(u8)side;

		q: QuadData;
		q.x_y = cast(u32)(x | (y << 16));
		q.z_t = cast(u32)(z | cast(i32)(texture << 16));
		q.rgb_face = color.toABGR();

		addQuad(q);
	}

	fn addQuad(q: QuadData)
	{
		add(cast(void*)&q, typeid(q).size);
	}

	final fn bake(out buf: GLuint, out num: GLsizei)
	{
		// Setup vertex buffer and upload the data.
		glCreateBuffers(1, &buf);
		glNamedBufferData(buf, cast(GLsizeiptr)length, ptr, GL_STATIC_DRAW);

		stride := cast(GLsizei)typeid(QuadData).size;
		num = (cast(GLsizei)length / stride) * 6;
	}

	final fn bake(out vao: GLuint, out buf: GLuint, out numQuadDatas: GLsizei, out numLineVertices: GLsizei)
	{
		numQuadDatas = this.numQuadDatas;

		// Setup vertex buffer and upload the data.
		glCreateBuffers(1, &buf);
		glNamedBufferData(buf, cast(GLsizeiptr)length, ptr, GL_STATIC_DRAW);

		glCreateVertexArrays(1, &vao);

		linesOffset := cast(GLsizei)(numQuadDatas * QaudStride);
		numLineVertices = (cast(GLsizei)length - linesOffset) / LineStride;

		glVertexArrayVertexBuffer(vao, 0, buf, linesOffset, LineStride);

		glEnableVertexArrayAttrib(vao, 0);
		glEnableVertexArrayAttrib(vao, 2);

		glVertexArrayAttribBinding(vao, 0, 0);
		glVertexArrayAttribBinding(vao, 2, 0);

		posOffset := cast(GLuint)0;
		colorOffset := cast(GLuint)typeid(f32).size * 3;
		glVertexArrayAttribFormat(vao, 0, 3, GL_FLOAT, GL_FALSE, posOffset);
		glVertexArrayAttribFormat(vao, 2, 4, GL_UNSIGNED_BYTE, GL_TRUE, colorOffset);
	}
}

/*!
 * Shader to be used with the vertex format in this file.
 *
 * It has one shader uniform called 'matrix' that is the.
 */
global voxelShader: gfx.Shader;
global voxelSampler: GLuint;
global voxelIndexBuffer: GLuint;
global voxelVAO: GLuint;

private:

global this()
{
	core.addInitAndCloseRunners(initVoxel, closeVoxel);
}

fn initVoxel()
{
	glGenSamplers(1, &voxelSampler);
	glSamplerParameteri(voxelSampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glSamplerParameteri(voxelSampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glSamplerParameteri(voxelSampler, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glSamplerParameteri(voxelSampler, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	voxelIndexBuffer = createIndexBuffer(662230u);
	glCreateVertexArrays(1, &voxelVAO);
	glVertexArrayElementBuffer(voxelVAO, voxelIndexBuffer);

	max: f32;
	glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &max);
	glSamplerParameterf(voxelSampler, GL_TEXTURE_MAX_ANISOTROPY_EXT, max);

	voxelShader = new gfx.Shader("ground.gfx.voxel", vertexShader45,
	                    fragmentShader45,
	                    null,
	                    null);
}

fn closeVoxel()
{
	gfx.destroy(ref voxelShader);

	if (voxelIndexBuffer) { glDeleteBuffers(1, &voxelIndexBuffer); voxelIndexBuffer = 0; }
	if (voxelVAO) { glDeleteVertexArrays(1, &voxelVAO); voxelVAO = 0; }
	if (voxelSampler) { glDeleteSamplers(1, &voxelSampler); voxelSampler = 0; }
}

/*!
 * Generates a index buffer for quads.
 *
 *     0-------1   Quad = 4 verticies
 *     |  A __/|   ==================
 *     | __/   |      Indicies: 0 1 2 2 1 3
 *     |/   B  |   2 triangles:     A     B
 *     2-------3
 */
fn createIndexBuffer(numQuads: u32) GLuint
{
	data: u32[] = [0, 1, 2, 2, 1, 3];
	length := cast(GLsizeiptr)(data.length * numQuads * typeid(u32).size);

	buffer: GLuint;
	glCreateBuffers(1, &buffer);
	glNamedBufferData(buffer, length, null, GL_STATIC_DRAW);
	ptr := cast(u32*)glMapNamedBuffer(buffer, GL_WRITE_ONLY);

	foreach (i; 0 .. numQuads) {
		foreach (d; data) {
			*ptr = d + i * 4;
			ptr++;
		}
	}

	glUnmapNamedBuffer(buffer);

	return buffer;
}

enum string vertexShader45 = `
#version 450 core

struct Vertex
{
	vec3 pos;
	vec2 uv;
};

const Vertex verts[] = Vertex[](
	// -X
	Vertex(vec3(0.0, 0.0, 0.0), vec2(0.0, 1.0)),
	Vertex(vec3(0.0, 1.0, 0.0), vec2(0.0, 0.0)),
	Vertex(vec3(0.0, 0.0, 1.0), vec2(1.0, 1.0)),
	Vertex(vec3(0.0, 1.0, 1.0), vec2(1.0, 0.0)),

	// +X
	Vertex(vec3(1.0, 0.0, 0.0), vec2(1.0, 1.0)),
	Vertex(vec3(1.0, 1.0, 0.0), vec2(1.0, 0.0)),
	Vertex(vec3(1.0, 0.0, 1.0), vec2(0.0, 1.0)),
	Vertex(vec3(1.0, 1.0, 1.0), vec2(0.0, 0.0)),

	// -Y
	Vertex(vec3(0.0, 0.0, 0.0), vec2(1.0, 0.0)),
	Vertex(vec3(1.0, 0.0, 0.0), vec2(0.0, 0.0)),
	Vertex(vec3(0.0, 0.0, 1.0), vec2(1.0, 1.0)),
	Vertex(vec3(1.0, 0.0, 1.0), vec2(0.0, 1.0)),

	// +Y
	Vertex(vec3(0.0, 1.0, 0.0), vec2(0.0, 0.0)),
	Vertex(vec3(1.0, 1.0, 0.0), vec2(1.0, 0.0)),
	Vertex(vec3(0.0, 1.0, 1.0), vec2(0.0, 1.0)),
	Vertex(vec3(1.0, 1.0, 1.0), vec2(1.0, 1.0)),

	// -Z
	Vertex(vec3(0.0, 0.0, 0.0), vec2(1.0, 1.0)),
	Vertex(vec3(1.0, 0.0, 0.0), vec2(0.0, 1.0)),
	Vertex(vec3(0.0, 1.0, 0.0), vec2(1.0, 0.0)),
	Vertex(vec3(1.0, 1.0, 0.0), vec2(0.0, 0.0)),

	// +Z
	Vertex(vec3(0.0, 0.0, 1.0), vec2(0.0, 1.0)),
	Vertex(vec3(1.0, 0.0, 1.0), vec2(1.0, 1.0)),
	Vertex(vec3(0.0, 1.0, 1.0), vec2(0.0, 0.0)),
	Vertex(vec3(1.0, 1.0, 1.0), vec2(1.0, 0.0))
);

const vec3 normals[] = vec3[](
	vec3(-1.0,  0.0,  0.0),
	vec3( 1.0,  0.0,  0.0),
	vec3( 0.0, -1.0,  0.0),
	vec3( 0.0,  1.0,  0.0),
	vec3( 0.0,  0.0, -1.0),
	vec3( 0.0,  0.0,  1.0)
);

struct Quad
{
	uint x_y;
	uint z_t;
	uint rgb_face;
};

layout (binding = 0, std430) buffer BufferIn
{
	Quad in_data[];
};

uniform mat4 u_matrix;

layout (location = 0) out vec3 out_color;
layout (location = 1) out vec3 out_uv;


void main(void)
{
	Quad q = in_data[gl_VertexID / 4];
	uint offset = gl_VertexID % 4;

	uvec4 pos_tex = uvec4(
		bitfieldExtract(q.x_y,  0, 16),
		bitfieldExtract(q.x_y, 16, 16),
		bitfieldExtract(q.z_t,  0, 16),
		bitfieldExtract(q.z_t, 16, 16)
	);
	vec3 position = vec3(pos_tex.xyz);
	uint texture = pos_tex.w;

	uint face = bitfieldExtract(q.rgb_face, 24, 8);

	position += verts[face * 4 + offset].pos;

	out_uv = vec3(verts[face * 4 + offset].uv, texture);
	out_color = unpackUnorm4x8(q.rgb_face).rgb;

	gl_Position = u_matrix * vec4(position, 1.0);
}
`;

enum string fragmentShader45 = `
#version 450 core

layout (location = 0) in  vec3 in_color;
layout (location = 1) in  vec3 in_uv;

layout (location = 0) out vec4 out_color;

layout (binding = 0) uniform sampler2DArray tex;

void main(void)
{
	out_color = vec4(in_color * texture(tex, in_uv.xyz).rgb, 1.0);
}
`;
