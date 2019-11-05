// Copyright 2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  A single scene that can be rendered from multiple views.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module ground.gfx.voxel;

import lib.gl.gl45;

import core = charge.core;
import gfx = charge.gfx;
import charge.gfx.gl;


/*!
 * Shader to be used with the vertex format in this file.
 *
 * It has one shader uniform called 'matrix' that is the.
 */
global voxelShader: gfx.Shader;
global voxelSampler: GLuint;

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

	if (voxelSampler) { glDeleteSamplers(1, &voxelSampler); voxelSampler = 0; }
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

const uint indices[] = uint[](0, 1, 2, 1, 2, 3);


struct Quad
{
	uint x_y;
	uint z;
	uint rgb_face;
};

/*
layout (binding = 0, std430) buffer BufferIn
{
	Quad in_data[];
};
*/

#define XM 0
#define XP 1
#define YM 2
#define YP 3
#define ZM 4
#define ZP 5

#define W vec4(1.0, 1.0, 1.0, 0.0)
#define R vec4(1.0, 0.5, 0.5, 0.0)
#define G vec4(0.5, 1.0, 0.5, 0.0)
#define B vec4(0.5, 0.5, 1.0, 0.0)

#define QUAD(x, y, z, face, color) \
	Quad(y << 16 | x, z, face << 24 | packUnorm4x8(color))

const Quad in_data[] = Quad[](
	QUAD(0, 1, 1, XP, W),
	QUAD(0, 1, 2, XP, R),
	QUAD(0, 1, 3, XP, G),
	QUAD(0, 1, 4, XP, B),

	QUAD(1, 1, 0, ZP, B),
	QUAD(2, 1, 0, ZP, W),
	QUAD(3, 1, 0, ZP, R),
	QUAD(4, 1, 0, ZP, G),

	QUAD(1, 0, 1, YP, R), QUAD(1, 0, 2, YP, W), QUAD(1, 0, 3, YP, B), QUAD(1, 0, 4, YP, G),
	QUAD(2, 0, 1, YP, G), QUAD(2, 0, 2, YP, R), QUAD(2, 0, 3, YP, W), QUAD(2, 0, 4, YP, B),
	QUAD(3, 0, 1, YP, B), QUAD(3, 0, 2, YP, G), QUAD(3, 0, 3, YP, R), QUAD(3, 0, 4, YP, W),
	QUAD(4, 0, 1, YP, W), QUAD(4, 0, 2, YP, B), QUAD(4, 0, 3, YP, G), QUAD(4, 0, 4, YP, R),

	QUAD(0, 1, 0, YP, B), QUAD(1, 1, 0, YP, W), QUAD(2, 1, 0, YP, R), QUAD(3, 1, 0, YP, G), QUAD(4, 1, 0, YP, B),
	QUAD(0, 1, 1, YP, G),
	QUAD(0, 1, 2, YP, R),
	QUAD(0, 1, 3, YP, W),
	QUAD(0, 1, 4, YP, B),

	QUAD(0, 0, 0, YP, W)
);


uniform mat4 u_matrix;

layout (location = 0) out vec3 out_color;
layout (location = 1) out vec2 out_uv;


void main(void)
{
	Quad q = in_data[gl_VertexID / 6];
	uint offset = indices[gl_VertexID % 6];

	vec3 position = vec3(
		bitfieldExtract(q.x_y,  0, 16),
		bitfieldExtract(q.x_y, 16, 16),
		bitfieldExtract(  q.z,  0, 16)
	);

	uint face = bitfieldExtract(q.rgb_face, 24, 8);

	position += verts[face * 4 + offset].pos;

	out_uv = verts[face * 4 + offset].uv;
	out_color = unpackUnorm4x8(q.rgb_face).rgb;
	gl_Position = u_matrix * vec4(position, 1.0);
}
`;

enum string fragmentShader45 = `
#version 450 core

layout (location = 0) in  vec3 in_color;
layout (location = 1) in  vec2 in_uv;

layout (location = 0) out vec4 out_color;

layout (binding = 0) uniform sampler2D texture;

void main(void)
{
	out_color = vec4(in_color * texture2D(texture, in_uv).rgb, 1.0);
}
`;
