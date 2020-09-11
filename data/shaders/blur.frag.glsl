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

void main() {
  vec4 tex_color = vec4(0,0,0,1);//COMPAT_TEXTURE(sol_texture, sol_vtex_coord);
  const int ksize = 2;
  float time = float(sol_time*0.001);
  const float kwidth = 0.01+0.005*sin(time);
  const float kfac = 1.0 / ((2*ksize+1)*(2*ksize+1));
  for(int i = -ksize; i < ksize+1; i++) {
    for(int j = -ksize; j < ksize+1; j++) {
      vec2 bcoord = sol_vtex_coord + vec2(i*kwidth, j*kwidth);
      tex_color += COMPAT_TEXTURE(sol_texture, bcoord)*kfac;
    }
  }
  FragColor = tex_color;
}
