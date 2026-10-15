shader_type spatial;
render_mode diffuse_burley;
uniform vec2 pond_center=vec2(7.,-6.);
uniform float pond_radius=3.7;
varying vec3 world_position;

void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}

void fragment(){
 vec2 p=world_position.xz;
 float a=dot(p,vec2(4.1,2.7))+TIME*.48;
 float b=dot(p,vec2(-2.1,7.3))-TIME*.32;
 float c=dot(p,vec2(19.,13.))+TIME*.7;
 vec2 gradient=.0035*cos(a)*vec2(4.1,2.7)+.0018*cos(b)*vec2(-2.1,7.3)+.00018*cos(c)*vec2(19.,13.);
 vec3 world_normal=normalize(vec3(-gradient.x,1.,-gradient.y));
 NORMAL=normalize((VIEW_MATRIX*vec4(world_normal,0.)).xyz);
 float shore=smoothstep(pond_radius-.65,pond_radius,length(p-pond_center));
 ALBEDO=mix(vec3(.024,.055,.042),vec3(.064,.079,.041),shore);
 ROUGHNESS=.085;
 // Water's normal-incidence reflectance is about 0.02: Godot's dielectric
 // specular parameter maps 0..1 to F0=0..0.08.
 SPECULAR=.25;
 METALLIC=0.;
}
