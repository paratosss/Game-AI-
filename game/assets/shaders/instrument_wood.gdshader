shader_type spatial;
render_mode diffuse_burley;
uniform vec4 wood_color : source_color = vec4(0.75,0.52,0.28,1.0);
uniform vec3 grain_axis=vec3(1.0,0.0,0.0);
uniform float coat=0.35;
varying vec3 wood_position;
float random(float n){return fract(sin(n*127.1+43.7)*43758.5453);}
float noise(float x){float i=floor(x);float t=fract(x);return mix(random(i),random(i+1.0),t*t*(3.0-2.0*t));}
void vertex(){wood_position=VERTEX;}
void fragment(){
 float cross_grain=dot(wood_position,grain_axis);
 float slow=noise(cross_grain*85.0+wood_position.y*.15);
 float phase=cross_grain*750.0+noise(wood_position.y*2.0)*.14;
 float filtered=1.0-smoothstep(.12,.5,max(abs(dFdx(phase)),abs(dFdy(phase))));
 float fiber=sin(phase*6.2831853)*filtered;
 ALBEDO=wood_color.rgb*(.94+slow*.08+fiber*.026);
 NORMAL_MAP=normalize(vec3(fiber*.045*filtered,0.0,1.0))*.5+.5;
 NORMAL_MAP_DEPTH=.35;
 ROUGHNESS=.31+slow*.055;
 SPECULAR=.36;
 CLEARCOAT=coat;
 CLEARCOAT_ROUGHNESS=.16;
}
