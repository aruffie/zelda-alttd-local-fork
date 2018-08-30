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
uniform sampler2D reflection;
COMPAT_VARYING vec2 sol_vtex_coord;
COMPAT_VARYING vec4 sol_vcolor;

const vec3 key = vec3(122.0,164.0,230.0)/255.0;
const vec3 key2 = vec3(88.0,128.0,200.0)/255.0;

const float threshold = 0.1;

void main() {
    vec4 tex_color = COMPAT_TEXTURE(sol_texture, sol_vtex_coord);
    if(distance(tex_color.rgb,key) < threshold ||
       distance(tex_color.rgb,key2) < threshold) {
      vec4 refl = COMPAT_TEXTURE(reflection,sol_vtex_coord);
      tex_color.rgb = mix(tex_color.rgb,refl.rgb,0.3);
    }
    FragColor = tex_color;
    FragColor.a = 1.0;
    //FragColor.rgb = key;
}
