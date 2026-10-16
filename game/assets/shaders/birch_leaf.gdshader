shader_type spatial;
render_mode cull_disabled,diffuse_burley;
varying vec3 local_point;
void vertex(){
 local_point=VERTEX;
 // Attached branches remain rigid; leaves have a restrained, height-varying flutter.
 float wind=sin(TIME*1.1+VERTEX.x*1.3+VERTEX.z*0.9);
 VERTEX.x+=wind*0.012*smoothstep(2.0,9.0,VERTEX.y);
}
void fragment(){
 float variation=0.5+0.5*sin(local_point.x*9.3+local_point.y*4.7+local_point.z*3.2);
 float center=1.0-smoothstep(0.002,0.016,abs(UV.x-0.5));
 float veins=pow(max(0.0,cos((UV.y-abs(UV.x-0.5)*0.8)*85.0)),20.0)*0.15;
 ALBEDO=mix(vec3(0.045,0.105,0.012),vec3(0.14,0.24,0.035),variation)*(1.0+center*0.12+veins);
 if(!FRONT_FACING)NORMAL=-NORMAL;
 ROUGHNESS=0.70;
 SPECULAR=0.20;
 BACKLIGHT=ALBEDO*0.45;
}
