shader_type spatial;
render_mode diffuse_burley;

// Source centers are in the shared mesh's local coordinates. A recessed iris
// is evaluated through the spherical surface; the sclera stays opaque.
uniform float iris_depth : hint_range(0.0, 0.002) = 0.00085;
uniform float eye_radius = 0.0125;
uniform bool use_iris_uv = false;
varying vec3 local_position;
varying vec3 local_camera;

float hash(float x) { return fract(sin(x * 127.1 + 311.7) * 43758.5453); }
float noise(float x) {
 float cell = floor(x);
 float t = fract(x);
 return mix(hash(cell), hash(cell + 1.0), t * t * (3.0 - 2.0 * t));
}

void vertex() {
 local_position = VERTEX;
 local_camera = (inverse(MODELVIEW_MATRIX) * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
}

void fragment() {
 float center_x = local_position.x < 0.0 ? -0.0265063522 : 0.0258339928;
 vec3 center = vec3(center_x, 0.0177822113, 0.0603648629);
 vec3 surface = (local_position - center) / eye_radius;
 vec3 view_ray = normalize(local_camera - local_position);
 if (use_iris_uv) {
  surface = vec3((UV - vec2(0.5)) * 2.0, 1.0);
  view_ray = vec3(dot(VIEW, TANGENT), -dot(VIEW, BINORMAL), dot(VIEW, NORMAL));
 }
 // Clamp grazing views so the iris cannot slide over the side of the eye.
 vec2 iris_point = surface.xy - view_ray.xy / max(view_ray.z, 0.30) * iris_depth / eye_radius;
 float r = length(iris_point);
 float angle = atan(iris_point.y, iris_point.x);
 float front = smoothstep(0.15, 0.45, surface.z);
 float iris = (1.0 - smoothstep(0.515, 0.55, r)) * front;
 float pupil = 1.0 - smoothstep(0.155, 0.175, r);
 float fibers = noise(angle * 79.0 + noise(angle * 17.0) * 3.0 + r * 9.0);
 fibers = mix(fibers, noise(angle * 173.0 - r * 18.0), 0.30);
 vec3 iris_color = mix(vec3(0.025, 0.036, 0.017), vec3(0.100, 0.115, 0.045), fibers);
 float inner_ring = exp(-pow((r - 0.23) / 0.075, 2.0));
 iris_color = mix(iris_color, vec3(0.115, 0.067, 0.023), inner_ring * 0.42);
 float limbus = smoothstep(0.43, 0.52, r);
 iris_color *= mix(1.0, 0.18, limbus);
 iris_color = mix(iris_color, vec3(0.0008), pupil);
 float side = smoothstep(0.58, 0.95, length(surface.xy));
 vec3 sclera = mix(vec3(0.33, 0.32, 0.285), vec3(0.30, 0.24, 0.22), side * 0.35);
 ALBEDO = mix(sclera, iris_color, iris);
 // Light-dependent catchlights, with no white marks painted in the iris.
 ROUGHNESS = mix(0.18, 0.055, iris);
 SPECULAR = 0.48;
 CLEARCOAT = mix(0.35, 0.85, iris);
 CLEARCOAT_ROUGHNESS = 0.035;
}
