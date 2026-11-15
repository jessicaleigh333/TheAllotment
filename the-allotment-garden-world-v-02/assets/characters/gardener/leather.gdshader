shader_type spatial;
render_mode diffuse_burley;

// Reusable dye-preserving grain material. Straw uses its own woven maps through
// this same lightweight shader, with softer normals and high roughness.
uniform vec4 tint : source_color = vec4(0.45, 0.28, 0.17, 1.0);
uniform sampler2D detail_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec2 detail_scale = vec2(3.0, 3.0);
uniform float roughness_bias : hint_range(-0.2, 0.2) = 0.0;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.55;

void fragment() {
    vec2 grain_uv = UV * detail_scale;
    vec3 detail = texture(detail_texture, grain_uv).rgb;
    ALBEDO = tint.rgb * (0.97 + (detail.r - 0.5) * 1.1);
    ROUGHNESS = clamp(detail.b + roughness_bias, 0.57, 0.97);
    SPECULAR = 0.23;
    float grain_visibility = clamp(1.0 - length(fwidth(grain_uv)) * 34.0, 0.0, 1.0);
    vec3 grain_normal = texture(detail_normal, grain_uv).rgb * 2.0 - 1.0;
    NORMAL_MAP = normalize(vec3(grain_normal.xy * normal_strength * grain_visibility, 1.0)) * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = 1.0;
}
