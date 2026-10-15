shader_type spatial;
render_mode diffuse_burley, cull_disabled;

uniform sampler2D earth_color : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D earth_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D earth_rough : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D turf_color : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D turf_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D turf_rough : repeat_enable, filter_linear_mipmap_anisotropic;
uniform float turf_coverage = 1.0;
uniform float shore_wetness = 0.0;
varying vec3 world_position;
varying vec3 world_normal;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(hash(i), hash(i+vec2(1.0,0.0)), f.x), mix(hash(i+vec2(0.0,1.0)), hash(i+vec2(1.0)), f.x), f.y);
}
float segment_distance(vec2 p, vec2 a, vec2 b) {
    vec2 d = b-a;
    return length(p-a-d*clamp(dot(p-a,d)/dot(d,d),0.0,1.0));
}
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
    vec2 p = world_position.xz;
    // Physical scan dimensions: soil 3.15m; leafy ground 2m.
    vec2 earth_uv = vec2(p.x,-p.y)/3.15;
    vec2 turf_uv = vec2(p.x,-p.y)/2.0;
    float path = min(segment_distance(p,vec2(-3.0,5.0),vec2(-2.0,0.1)),segment_distance(p,vec2(-2.0,0.1),vec2(1.0,-2.9)));
    float worn = 1.0-smoothstep(0.25,0.90,path+noise(p*2.0)*0.15);
    float patch = smoothstep(0.25,0.72,noise(p*0.32));
    float turf = (1.0-worn*0.98)*mix(0.85,0.98,patch)*turf_coverage;
    // Slowly changing offsets soften obvious repetition without recolouring the scans.
    float variation = smoothstep(0.30,0.70,noise(p*0.17+17.0));
    vec2 offset = vec2(0.417,0.731);
    vec3 soil = mix(texture(earth_color,earth_uv).rgb,texture(earth_color,earth_uv+offset).rgb,variation);
    vec3 grass = mix(texture(turf_color,turf_uv).rgb,texture(turf_color,turf_uv+offset).rgb,variation);
    vec3 soil_n = mix(texture(earth_normal,earth_uv).xyz,texture(earth_normal,earth_uv+offset).xyz,variation)*2.0-1.0;
    vec3 grass_n = mix(texture(turf_normal,turf_uv).xyz,texture(turf_normal,turf_uv+offset).xyz,variation)*2.0-1.0;
    float damp = shore_wetness*(1.0-smoothstep(3.55,4.15,length(p-vec2(7.0,-6.0))));
    ALBEDO = mix(soil,grass,turf)*(1.0-damp*0.28);
    vec3 n = normalize(world_normal);
    vec3 t = normalize(vec3(1.0,0.0,0.0)-n*dot(n,vec3(1.0,0.0,0.0)));
    TANGENT = normalize((VIEW_MATRIX*vec4(t,0.0)).xyz);
    BINORMAL = normalize((VIEW_MATRIX*vec4(cross(n,t),0.0)).xyz);
    NORMAL_MAP = normalize(mix(soil_n,grass_n,turf))*0.5+0.5;
    NORMAL_MAP_DEPTH = 0.65;
    ROUGHNESS = mix(clamp(mix(texture(earth_rough,earth_uv).r,texture(turf_rough,turf_uv).r,turf),0.68,1.0),0.40,damp);
    SPECULAR = 0.25;
}
