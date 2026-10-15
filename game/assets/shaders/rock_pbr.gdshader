shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D rock_color : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_rough : repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 position_world;
varying vec3 normal_world;
void vertex() {
    position_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    normal_world=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
    vec3 n=normalize(normal_world);
    vec3 weight=pow(abs(n),vec3(4.0));
    weight/=dot(weight,vec3(1.0));
    vec3 p=position_world/1.5;
    vec2 x_uv=vec2(-sign(n.x)*p.z,p.y);
    vec2 y_uv=vec2(p.x,-sign(n.y)*p.z);
    vec2 z_uv=vec2(p.x,sign(n.z)*p.y);
    ALBEDO=texture(rock_color,x_uv).rgb*weight.x+texture(rock_color,y_uv).rgb*weight.y+texture(rock_color,z_uv).rgb*weight.z;
    vec2 x_n=texture(rock_normal,x_uv).xy*2.0-1.0;
    vec2 y_n=texture(rock_normal,y_uv).xy*2.0-1.0;
    vec2 z_n=texture(rock_normal,z_uv).xy*2.0-1.0;
    vec3 detail=vec3(0.0,x_n.y,-sign(n.x)*x_n.x)*weight.x+vec3(y_n.x,0.0,-sign(n.y)*y_n.y)*weight.y+vec3(z_n.x,sign(n.z)*z_n.y,0.0)*weight.z;
    NORMAL=normalize((VIEW_MATRIX*vec4(normalize(n+detail*0.65),0.0)).xyz);
    ROUGHNESS=clamp(texture(rock_rough,x_uv).r*weight.x+texture(rock_rough,y_uv).r*weight.y+texture(rock_rough,z_uv).r*weight.z,0.62,1.0);
    SPECULAR=0.30;
}
