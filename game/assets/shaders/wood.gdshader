shader_type spatial;
render_mode diffuse_burley,cull_disabled;
uniform sampler2D wood_color : source_color,repeat_enable;
uniform sampler2D wood_normal : hint_normal,repeat_enable;
uniform sampler2D wood_rough : repeat_enable;
varying vec3 local_pos;
varying vec3 local_normal;
uniform vec2 grain_offset=vec2(0.0);
void vertex(){local_pos=VERTEX;local_normal=NORMAL;}
void fragment(){
 vec3 n=abs(local_normal);
 vec2 coord=vec2(local_pos.x*.52,local_pos.z*1.05)+grain_offset;
 if(n.z>n.y && n.z>n.x)coord=vec2(local_pos.x*.52,local_pos.y*1.05)+grain_offset;
 if(n.x>n.y && n.x>n.z)coord=vec2(local_pos.z*1.05,local_pos.y*1.05)+grain_offset;
 vec3 tex=texture(wood_color,coord).rgb;
 float lum=dot(tex,vec3(.2126,.7152,.0722));
 ALBEDO=mix(tex,vec3(lum),.30)*vec3(.74,.79,.78);
 if(n.x>n.y && n.x>n.z)ALBEDO*=.78;
 ROUGHNESS=max(texture(wood_rough,coord).r,.66);SPECULAR=.24;
}
