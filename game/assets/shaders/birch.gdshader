shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D bark_color : source_color,repeat_enable;
uniform sampler2D bark_normal : hint_normal,repeat_enable;
uniform sampler2D bark_rough : repeat_enable;
void fragment(){
 vec2 coord=UV*vec2(1.1,2.4);
 vec3 tex=texture(bark_color,coord).rgb;
 float value=dot(tex,vec3(.21,.72,.07));
 float scar=1.-smoothstep(.12,.25,value);
 float basal=smoothstep(.82,.96,UV.y);
 ALBEDO=mix(vec3(.70,.72,.65)*(0.88+value*.15),vec3(.16,.18,.15),scar*.7);
 ALBEDO=mix(ALBEDO,tex*.5,basal*.40);
 NORMAL_MAP=texture(bark_normal,coord).rgb;NORMAL_MAP_DEPTH=.45;
 ROUGHNESS=max(texture(bark_rough,coord).r,.80);SPECULAR=.22;
}
