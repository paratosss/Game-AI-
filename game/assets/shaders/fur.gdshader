shader_type spatial;
render_mode diffuse_burley;
varying vec3 surface_pos;
void vertex(){surface_pos=VERTEX;}
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void fragment(){
 float grain=noise(surface_pos*vec3(480.,900.,400.));float tone=noise(surface_pos*27.);
 ALBEDO=COLOR.rgb*(.93+grain*.05+tone*.06);ROUGHNESS=.89;SPECULAR=.19;
}
