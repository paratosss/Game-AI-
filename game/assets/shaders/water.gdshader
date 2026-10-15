shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 p=world_pos.xz;
 float a=sin(p.x*5.1+p.y*2.7+TIME*.48);float b=cos(p.y*8.3-p.x*2.1-TIME*.32);
 float small=sin(p.x*23.+p.y*17.+TIME*.7)*.18;
 ALBEDO=mix(vec3(.09,.18,.135),vec3(.14,.245,.18),a*.13+b*.09+.5);
 ROUGHNESS=.26;SPECULAR=.68;METALLIC=0.;
 NORMAL_MAP=normalize(vec3(.5+(a+small)*.016,.5+(b-small)*.016,1.));NORMAL_MAP_DEPTH=.30;
}
