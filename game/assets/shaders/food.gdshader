shader_type spatial;
render_mode diffuse_burley;
uniform vec4 raw_tint : source_color=vec4(.72,.43,.35,1.);
uniform float cook_top=0.;
uniform float cook_bottom=0.;
uniform float pork=1.;
varying vec3 local_pos;
void vertex(){local_pos=VERTEX;}
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void fragment(){
 float cooked=mix(cook_bottom,cook_top,smoothstep(-.018,.018,local_pos.y));
 float n=noise(local_pos*145.);float grain=noise(local_pos*vec3(230.,420.,64.));
 float vein=1.-smoothstep(.018,.050,abs(sin(local_pos.z*95.+noise(local_pos*46.)*2.4)));
 vec3 raw=mix(raw_tint.rgb*(.86+grain*.19),vec3(.85,.72,.64),vein*pork*.42);
 vec3 roasted=vec3(.38,.19,.08)*(.70+n*.40);
 vec3 tone=mix(raw,roasted,smoothstep(.25,1.1,cooked));
 float grill=1.-smoothstep(.14,.30,abs(sin(local_pos.z*110.+local_pos.x*17.)));
 tone=mix(tone,tone*.35,grill*smoothstep(.65,1.15,cooked)*.65);
 tone=mix(tone,vec3(.055,.037,.025),smoothstep(1.27,1.50,cooked));
 ALBEDO=tone;ROUGHNESS=mix(.48,.83,clamp(cooked,0.,1.));SPECULAR=.25;
}
