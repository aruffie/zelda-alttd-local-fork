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
COMPAT_VARYING vec2 sol_vtex_coord;
uniform vec2 sol_input_size;
COMPAT_VARYING vec4 sol_vcolor;

uniform float step; 
float remainder(float a, float b){
  float x=a/b;
  float y=ceil(x);
  return(b-(y*b))-a;
}

void main() {
    float pixel_size=pow(2.0, step);
    vec2 relative_region_size=pixel_size/sol_input_size;

    vec2 region_xy=vec2(
             floor(sol_vtex_coord.x/relative_region_size.x),
             floor(sol_vtex_coord.y/relative_region_size.y)
    );
    
    vec4 tex_color = COMPAT_TEXTURE(sol_texture, (region_xy*pixel_size)/sol_input_size);
    FragColor = tex_color;
}
