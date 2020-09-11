#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
precision mediump float;
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform sampler2D sol_texture;
uniform bool sol_vcolor_only;
uniform bool sol_alpha_mult;
uniform int sol_time;
COMPAT_VARYING vec2 sol_vtex_coord;
COMPAT_VARYING vec4 sol_vcolor;

vec3 cut_lava(vec3 color) {
  vec3 res = vec3(0,0,0);
  vec3 lava_colors[3];
  lava_colors[0] = vec3(0.973, 0.471, 0.125);
  lava_colors[1] = vec3(0.878, 0.125, 0.125);
  lava_colors[2] = vec3(0.565, 0.094, 0.094);
  for(int i = 0; i < 3; i++) {
    if(length(color.rgb - lava_colors[i]) < 0.01) {
      res = color;
    }
  }
  return res;
}

vec3 sample_lava(vec2 coord) {
  return cut_lava(COMPAT_TEXTURE(sol_texture, coord).rgb);
}

void main() {    
    vec4 tex_color = COMPAT_TEXTURE(sol_texture, sol_vtex_coord);
    FragColor = tex_color; //+ vec4(cut_lava(tex_color.rgb), 1.0);
    
    const int ksize = 2;
    float time = float(sol_time*0.001);
    const float kwidth = 0.02+0.005*sin(time);
    for(int i = -ksize; i < ksize+1; i++) {
      for(int j = -ksize; j < ksize+1; j++) {
        vec2 bcoord = sol_vtex_coord + vec2(i*kwidth, j*kwidth);
        FragColor.rgb += sample_lava(bcoord)*0.1;
      }
    }
}
