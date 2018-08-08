/*
 * Copyright (C) 2018 Solarus - http://www.solarus-games.org
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// Mode 7 shader.
// Shows a texture in a perspective view.
// Inspired from https://www.shadertoy.com/view/ltsGWn

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
#endif

#ifdef GL_ES
precision mediump float;
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform mat4 sol_mvp_matrix;
uniform mat3 sol_uv_matrix;
COMPAT_ATTRIBUTE vec2 sol_vertex;
COMPAT_ATTRIBUTE vec3 view_position;
COMPAT_ATTRIBUTE vec3 view_target;
COMPAT_ATTRIBUTE vec2 sol_tex_coord;
COMPAT_ATTRIBUTE vec4 sol_color;

COMPAT_VARYING vec2 sol_vtex_coord;
COMPAT_VARYING vec4 sol_vcolor;

COMPAT_VARYING vec4 vertex_position;

mat4 look_at(vec3 eye, vec3 target, vec3 up) {
  vec3 look = normalize(target-eye);
  vec3 side = cross(up,look);
  vec3 tup = cross(side,look);

  mat4 la = mat4(mat3(side,tup,look));
  la[3].x = -dot(side,eye);
  la[3].y = -dot(tup,eye);
  la[3].z = dot(look,eye);
  return la;
}

const float pi = 3.1415926535897932384626433832795;

const float fov = pi/2.0;
const float d = 1.0/tan(fov/2.0);
const float a = 320.0/256.0;
const float near = 0.1;
const float far = 10;

mat4 perspective() {
  return mat4(
    vec4(d/a,0,0,0),
    vec4(0,d,0,0),
    vec4(0,0,(near+far)/(near-far),-1),
    vec4(0,0,2*near*far/(near-far),0)
);
}

void main() {
    mat4 vp = perspective()*look_at(view_position,view_target,vec3(0,0,1));
    vertex_position = vec4(sol_vertex*2-vec2(1), 0, 1);
    gl_Position = vertex_position;
    sol_vcolor = sol_color;
    sol_vtex_coord = (sol_uv_matrix * vec3(sol_tex_coord, 1)).xy;
}
