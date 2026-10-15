shader_type spatial;
render_mode cull_disabled,diffuse_burley;
uniform sampler2D leaf_texture : source_color,filter_linear_mipmap;
varying float phase;
void vertex(){
 phase=INSTANCE_CUSTOM.x*6.283;
 VERTEX.x+=sin(TIME*.9+phase)*.008*(1.-UV.y);
 VERTEX.z+=cos(TIME*.7+phase)*.006*(1.-UV.y);
}
void fragment(){
 vec4 leaf=texture(leaf_texture,UV);ALBEDO=leaf.rgb*COLOR.rgb;ALPHA=leaf.a;ALPHA_SCISSOR_THRESHOLD=.45;
 ROUGHNESS=.88;SPECULAR=.18;
 if(!FRONT_FACING){NORMAL=-NORMAL;ALBEDO*=.88;}
}
