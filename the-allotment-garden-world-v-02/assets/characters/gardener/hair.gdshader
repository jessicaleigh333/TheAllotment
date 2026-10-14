shader_type spatial;
render_mode diffuse_burley;

uniform vec4 tint : source_color = vec4(0.28, 0.13, 0.07, 1.0);
uniform sampler2D detail_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec2 detail_scale = vec2(1.0, 1.0);

void fragment() {
    vec2 strand_uv = UV * detail_scale;
    vec3 detail = texture(detail_texture, strand_uv).rgb;
    // Painted lock variation stays soft; no metallic sparkle or fixed hair color.
    ALBEDO = tint.rgb * (0.95 + (detail.r - 0.5) * 1.25);
    ROUGHNESS = clamp(detail.b, 0.48, 0.67);
    SPECULAR = 0.25;
    float fibre_visibility = clamp(1.0 - length(fwidth(strand_uv)) * 58.0, 0.0, 1.0);
    vec3 strand_normal = texture(detail_normal, strand_uv).rgb * 2.0 - 1.0;
    NORMAL_MAP = normalize(vec3(strand_normal.xy * 0.44 * fibre_visibility, 1.0)) * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = 1.0;
}
