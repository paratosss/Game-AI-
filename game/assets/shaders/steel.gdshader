shader_type spatial;
render_mode diffuse_burley,cull_disabled;
uniform sampler2D steel_color : source_color,repeat_enable;
uniform sampler2D steel_normal : hint_normal,repeat_enable;
uniform sampler2D steel_rough : repeat_enable;
void fragment(){
 vec2 coord=UV*vec2(1.2,.65);
 vec3 color=texture(steel_color,coord).rgb;
 float oxide=clamp((color.r-color.b)*2.,0.,1.);
 ALBEDO=mix(color*.30,vec3(.045,.049,.052),.35);
 NORMAL_MAP=texture(steel_normal,coord).rgb;NORMAL_MAP_DEPTH=.35;
 METALLIC=mix(.85,.12,oxide);
 ROUGHNESS=clamp(texture(steel_rough,coord).r*.75+.16,.30,.90);SPECULAR=.40;
}
