shader_type spatial;
render_mode diffuse_burley;
varying vec3 local_position;
void vertex(){local_position=VERTEX;}
void fragment(){
 // Centers measured from the source sclera geometry in object-local coordinates.
 float center_x=local_position.x<0.0?-0.0265063522:0.0258339928;
 vec3 center=vec3(center_x,0.0177822113,0.0603648629);
 vec3 eye=normalize(local_position-center);
 float radius=length(eye.xy);
 float iris=(1.0-smoothstep(0.52,0.57,radius))*step(0.0,eye.z);
 float pupil=1.0-smoothstep(0.17,0.20,radius);
 float angle=atan(eye.y,eye.x);
 float fiber=0.5+0.5*sin(angle*39.0+sin(angle*17.0)*2.0+radius*14.0);
 vec3 iris_color=mix(vec3(0.055,0.085,0.027),vec3(0.18,0.22,0.085),fiber);
 iris_color*=mix(0.35,1.0,1.0-smoothstep(0.44,0.56,radius));
 iris_color=mix(iris_color,vec3(0.003),pupil);
 ALBEDO=mix(vec3(0.23,0.245,0.22),iris_color,iris);
 ROUGHNESS=0.23;
 SPECULAR=0.30;
 CLEARCOAT=0.20;
 CLEARCOAT_ROUGHNESS=0.10;
}
