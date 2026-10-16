shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_disabled;
uniform sampler2D depth_texture:hint_depth_texture,repeat_disable,filter_nearest;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float depth=textureLod(depth_texture,SCREEN_UV,0.0).r;
 vec4 scene=INV_PROJECTION_MATRIX*vec4(SCREEN_UV*2.0-1.0,depth,1.0);
 scene.xyz/=scene.w;
 float thickness=max(0.0,VERTEX.z-scene.z);
 vec2 p=world_position.xz;
 float a=dot(p,vec2(4.1,2.7))+TIME*0.48;
 float b=dot(p,vec2(-2.1,7.3))-TIME*0.32;
 vec2 gradient=0.0025*cos(a)*vec2(4.1,2.7)+0.0015*cos(b)*vec2(-2.1,7.3);
 vec3 n=normalize(vec3(-gradient.x,1.0,-gradient.y));
 NORMAL=normalize((VIEW_MATRIX*vec4(n,0.0)).xyz);
 ALBEDO=vec3(0.027,0.065,0.044);
 ROUGHNESS=0.075;
 SPECULAR=0.25;
 ALPHA=clamp(1.0-exp(-thickness*3.5),0.035,0.86);
}
