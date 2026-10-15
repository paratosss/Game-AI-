shader_type spatial;
render_mode cull_disabled,diffuse_burley;
void vertex() {
    float bend=UV.y*UV.y;
    VERTEX.x+=sin(TIME*1.2+INSTANCE_CUSTOM.x*TAU)*0.010*bend;
    VERTEX.z+=cos(TIME*0.8+INSTANCE_CUSTOM.x*TAU)*0.006*bend;
}
void fragment() {
    ALBEDO=mix(vec3(0.055,0.115,0.018),vec3(0.20,0.285,0.065),UV.y)*COLOR.rgb;
    if (!FRONT_FACING) { NORMAL=-NORMAL; }
    BACKLIGHT=ALBEDO*0.30;
    ROUGHNESS=0.87;
    SPECULAR=0.18;
}
