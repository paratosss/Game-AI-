shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D skin_tex : source_color;
uniform sampler2D mask_tex : filter_nearest;
uniform vec4 shirt_color : source_color = vec4(.4,.25,.22,1);
uniform vec4 trousers_color : source_color = vec4(.16,.21,.28,1);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 float region=texture(mask_tex,UV).r;
 vec3 skin=texture(skin_tex,UV).rgb;skin=mix(skin,vec3(.76,.57,.46),.16);
 float fabric=hash(floor(UV*1500.0))*.03+.985;
 if(region>.82){discard;}
 else if(region>.5){ALBEDO=trousers_color.rgb*fabric;ROUGHNESS=.95;}
 else if(region>.15){ALBEDO=shirt_color.rgb*fabric;ROUGHNESS=.96;}
 else{ALBEDO=skin;ROUGHNESS=.82;}
}
