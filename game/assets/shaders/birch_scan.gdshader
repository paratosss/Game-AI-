shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D bark_color:source_color,repeat_enable,filter_linear_mipmap_anisotropic;
uniform sampler2D bark_normal:hint_normal,repeat_enable,filter_linear_mipmap_anisotropic;
uniform sampler2D bark_rough:repeat_enable,filter_linear_mipmap_anisotropic;
varying vec3 local_position;
varying vec3 local_normal;
void vertex(){local_position=VERTEX;local_normal=NORMAL;}
void fragment(){
 // A scanned bark patch, not a seamless material. Sample only its populated UV
 // region; runtime projection is an approximation, to be assessed close up.
 float angle=atan(local_position.z,local_position.x)/TAU;
 vec2 tile=vec2(angle*2.0,local_position.y/0.75);
 vec2 uv=vec2(0.08,0.02)+fract(tile)*vec2(0.40,0.10);
 vec3 scan=texture(bark_color,uv).rgb;
 float stem=1.0-smoothstep(0.10,0.55,length(local_position.xz));
 float basal=1.0-smoothstep(0.0,0.9,local_position.y);
 ALBEDO=mix(vec3(0.10,0.075,0.048),scan,stem*(1.0-basal*0.65));
 vec3 n=normalize(local_normal);
 vec3 axis=abs(n.y)>0.95?vec3(1.0,0.0,0.0):vec3(0.0,1.0,0.0);
 vec3 tangent=normalize(cross(n,axis));
 TANGENT=normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(tangent,0.0)).xyz);
 BINORMAL=normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(cross(tangent,n),0.0)).xyz);
 NORMAL_MAP=texture(bark_normal,uv).rgb;
 NORMAL_MAP_DEPTH=0.40*stem;
 ROUGHNESS=max(0.78,texture(bark_rough,uv).r);
 SPECULAR=0.20;
}
