shader_type sky;
uniform sampler2D panorama : source_color, filter_linear_mipmap, repeat_enable;
uniform float sky_energy = 1.0;
void sky() {
    vec3 direction = normalize(EYEDIR);
    vec2 uv = vec2(atan(direction.z,direction.x)/TAU+0.5,acos(clamp(direction.y,-1.0,1.0))/PI);
    COLOR = texture(panorama,uv).rgb*sky_energy;
}
