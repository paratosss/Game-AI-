shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D wood_color : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D wood_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D wood_rough : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec2 grain_offset = vec2(0.0);
// The photographed Wood Table Worn patch covers 0.55 metres, with grain along U.
uniform float patch_metres = 0.55;
varying vec3 local_position;
varying vec3 local_normal;

void vertex() {
    local_position = VERTEX;
    local_normal = NORMAL;
}

void fragment() {
    vec3 n = normalize(local_normal);
    vec3 axis = abs(n);
    vec3 tangent = vec3(1.0, 0.0, 0.0);
    vec3 bitangent = vec3(0.0, 0.0, -sign(n.y));
    if (axis.z > axis.y && axis.z > axis.x) {
        bitangent = vec3(0.0, sign(n.z), 0.0);
    } else if (axis.x > axis.y && axis.x > axis.z) {
        tangent = vec3(0.0, 0.0, -sign(n.x));
        bitangent = vec3(0.0, 1.0, 0.0);
    }
    vec2 uv = vec2(dot(local_position, tangent), dot(local_position, bitangent)) / patch_metres + grain_offset;
    ALBEDO = texture(wood_color, uv).rgb;
    TANGENT = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(tangent, 0.0)).xyz);
    BINORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(bitangent, 0.0)).xyz);
    NORMAL_MAP = texture(wood_normal, uv).rgb;
    NORMAL_MAP_DEPTH = 0.65;
    ROUGHNESS = clamp(texture(wood_rough, uv).r, 0.42, 0.98);
    SPECULAR = 0.35;
}
