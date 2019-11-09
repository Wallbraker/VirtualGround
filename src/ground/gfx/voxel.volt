// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  A single scene that can be rendered from multiple views.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.gfx.voxel;

import lib.gl.gl45;

import core = charge.core;
import math = charge.math;
import gfx = charge.gfx;
import charge.gfx.gl;


struct QuadData
{
	x_y: u32;
	z_t: u32;
	rgb_face: u32;
}

class VoxelQuadBuilder : gfx.Builder
{
public:
	enum Side
	{
		XN,
		XP,
		YN,
		YP,
		ZN,
		ZP,
	}


public:
	quads: QuadData[];


public:
	this()
	{
		super();
	}

	alias add = gfx.Builder.add;

	fn add(x: i32, y: i32, z: i32, side: Side, texture: GLuint, color: math.Color4b)
	{
		// Bake side into the alpha channel.
		color.a = cast(u8)side;

		q: QuadData;
		q.x_y = cast(u32)(x | (y << 16));
		q.z_t = cast(u32)(z | cast(i32)(texture << 16));
		q.rgb_face = color.toABGR();

		add(q);
	}

	fn add(quad: QuadData)
	{
		add(cast(void*)&quad, typeid(QuadData).size);
	}

	final fn bake(out buf: GLuint, out num: GLsizei)
	{
		// Setup vertex buffer and upload the data.
		glCreateBuffers(1, &buf);
		glNamedBufferData(buf, cast(GLsizeiptr)length, ptr, GL_STATIC_DRAW);

		stride := cast(GLsizei)typeid(QuadData).size;
		num = (cast(GLsizei)length / stride) * 6;
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

layout (binding = 0) uniform sampler2D tex;

void main(void)
{
	out_color = vec4(in_color * texture(tex, in_uv.xy).rgb, 1.0);
}
`;
