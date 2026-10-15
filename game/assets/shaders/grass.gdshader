shader_type spatial;
render_mode cull_disabled;
void vertex(){NORMAL=vec3(0.,1.,0.);VERTEX.x+=sin(TIME*1.6+INSTANCE_CUSTOM.x*30.0)*.012*UV.y;}
void fragment(){ALBEDO=mix(vec3(.15,.26,.10),vec3(.38,.47,.21),UV.y)*COLOR.rgb;ROUGHNESS=1.0;}
