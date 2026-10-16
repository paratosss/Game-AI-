shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D skin_color:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D skin_normal:hint_normal,filter_linear_mipmap_anisotropic;
uniform sampler2D skin_roughness:filter_linear_mipmap_anisotropic;
uniform vec4 roughness_channel=vec4(0.0,1.0,0.0,0.0);
void fragment(){
 ALBEDO=texture(skin_color,UV).rgb;
 NORMAL_MAP=texture(skin_normal,UV).rgb;
 NORMAL_MAP_DEPTH=0.45;
 ROUGHNESS=clamp(dot(texture(skin_roughness,UV),roughness_channel)*0.65+0.28,0.38,0.78);
 SPECULAR=0.30;
 SSS_STRENGTH=0.08;
}
