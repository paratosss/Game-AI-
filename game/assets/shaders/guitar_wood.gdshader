shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform vec4 tint : source_color=vec4(.62,.38,.17,1);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){float grain=sin(UV.x*540.+sin(UV.y*6.)*2.)*.025+hash(floor(UV*1400.))*.025;ALBEDO=tint.rgb*(.96+grain);ROUGHNESS=.45;SPECULAR=.34;}
