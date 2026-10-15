shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D wood_color : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D wood_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D wood_rough : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec2 grain_offset=vec2(0.0);
varying vec3 local_position;
varying vec3 local_surface_normal;

void vertex(){
 local_position=VERTEX;
 local_surface_normal=NORMAL;
}

void fragment(){
 vec3 n=normalize(local_surface_normal);
 vec3 axis=abs(n);
 vec2 coordinate=vec2(local_position.z*1.05,local_position.x*.52);
 vec3 tangent=vec3(0.,0.,1.);
 vec3 bitangent=vec3(1.,0.,0.);
 float end_grain=0.;
 if(axis.z>axis.y && axis.z>axis.x){
  coordinate=vec2(-sign(n.z)*local_position.y*1.05,local_position.x*.52);
  tangent=vec3(0.,-sign(n.z),0.);
 }else if(axis.x>axis.y && axis.x>axis.z){
  coordinate=vec2(local_position.z*1.05,-sign(n.x)*local_position.y*1.05);
  tangent=vec3(0.,0.,1.);
  bitangent=vec3(0.,-sign(n.x),0.);
  end_grain=1.;
 }else{
  tangent*=sign(n.y);
  coordinate.x*=sign(n.y);
 }
 coordinate+=grain_offset;
 vec3 color=texture(wood_color,coordinate).rgb;
 float luminance=dot(color,vec3(.2126,.7152,.0722));
 // Existing photographed wood stays the source; ageing reduces the strong
 // varnish saturation without fabricating a higher-resolution texture.
 ALBEDO=mix(color,vec3(luminance)*vec3(1.06,1.02,.95),.48)*1.12;
 ALBEDO*=mix(1.,.88,end_grain);
 TANGENT=normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(tangent,0.)).xyz);
 BINORMAL=normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(bitangent,0.)).xyz);
 NORMAL_MAP=texture(wood_normal,coordinate).rgb;
 NORMAL_MAP_DEPTH=.45;
 ROUGHNESS=clamp(texture(wood_rough,coordinate).r*.78+.20,.55,.96);
 SPECULAR=.28;
}
