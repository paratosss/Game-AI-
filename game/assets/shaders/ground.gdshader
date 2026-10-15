shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform sampler2D earth_color : source_color, repeat_enable;
uniform sampler2D earth_normal : hint_normal, repeat_enable;
uniform sampler2D earth_rough : repeat_enable;
varying vec2 world_xz;
void vertex(){world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
float line(vec2 p,vec2 a,vec2 b){vec2 v=b-a;return length(p-a-v*clamp(dot(p-a,v)/dot(v,v),0.0,1.0));}
void fragment(){
 vec2 p=world_xz;vec2 uv=p*.45;vec3 tex=texture(earth_color,uv).rgb;
 float n=noise(p*.3);float path=min(line(p,vec2(-3.,5.),vec2(-2.,.1)),line(p,vec2(-2.,.1),vec2(1.,-2.9)));
 float wear=1.-smoothstep(.3,.8,path+noise(p*4.)*.15);
 vec3 ground=tex*mix(vec3(.58,.82,.47),vec3(.77,.91,.61),n);
 vec3 dirt=tex*vec3(.9,.82,.71);ALBEDO=mix(ground,dirt,wear*.8);
 NORMAL_MAP=texture(earth_normal,uv).rgb;NORMAL_MAP_DEPTH=.38;ROUGHNESS=texture(earth_rough,uv).r;
}
