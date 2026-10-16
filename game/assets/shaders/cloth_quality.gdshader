shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D base_color : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D cloth_normal : hint_normal, filter_linear_mipmap_anisotropic;
void fragment() {
 vec2 weave_uv=UV*900.0;
 // Filter the procedural weave at distance instead of generating moire.
 float visible=1.0-smoothstep(0.12,0.50,max(length(dFdx(weave_uv)),length(dFdy(weave_uv))));
 vec2 threads=sin(weave_uv*6.2831853);
 float weave=threads.x*threads.y;
 ALBEDO=texture(base_color,UV).rgb*(1.0+weave*0.025*visible);
 vec3 normal=texture(cloth_normal,UV).rgb*2.0-1.0;
 NORMAL_MAP=normalize(vec3(normal.xy+threads*0.025*visible,normal.z))*0.5+0.5;
 NORMAL_MAP_DEPTH=0.70;
 ROUGHNESS=0.86+weave*0.035*visible;
 SPECULAR=0.23;
}
