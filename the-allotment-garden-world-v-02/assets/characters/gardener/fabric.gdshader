shader_type spatial;
render_mode diffuse_burley, cull_disabled;

// Neutral original maps retain the player's dyed palette. Botanical embroidery
// is separate thread masks and relief, never a flat color baked into the cloth.
uniform vec4 tint : source_color = vec4(0.4, 0.48, 0.33, 1.0);
uniform vec4 flower_tint : source_color = vec4(0.82, 0.57, 0.6, 1.0);
uniform bool floral = false;
uniform sampler2D detail_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D embroidery_texture : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D embroidery_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec2 detail_scale = vec2(4.0, 3.0);
uniform vec2 embroidery_scale = vec2(1.0, 1.0);
uniform sampler2D woven_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D woven_orm : hint_default_white, filter_linear_mipmap, repeat_enable;

void fragment() {
    vec2 cloth_uv = UV * detail_scale;
    vec3 detail = texture(detail_texture, cloth_uv).rgb;
    vec3 color = tint.rgb * (0.97 + (detail.r - 0.5) * 0.65);
    vec3 thread_normal = texture(detail_normal, cloth_uv).rgb * 2.0 - 1.0;
    // Filter raised fibres before they become sparkly at the walking camera.
    float fibre_visibility = clamp(1.0 - length(fwidth(cloth_uv)) * 46.0, 0.0, 1.0);
    vec2 tangent_normal = thread_normal.xy * 0.42 * fibre_visibility;
    // Microsoft/Khronos CC0 woven-cloth detail supplements our dyed linen.
    vec2 woven_uv = UV * vec2(6.0, 5.0);
    float woven_visibility = clamp(1.0-length(fwidth(woven_uv))*32.0,0.0,1.0);
    vec3 woven = texture(woven_normal,woven_uv).rgb*2.0-1.0;
    vec3 weave_surface = texture(woven_orm,woven_uv).rgb;
    tangent_normal += woven.xy*0.18*woven_visibility;
    color *= mix(0.94,1.0,weave_surface.r);
    float embroidered = 0.0;
    if (floral) {
        vec2 stitch_uv = UV * embroidery_scale;
        vec3 stitch = texture(embroidery_texture, stitch_uv).rgb;
        vec3 leaves = mix(tint.rgb, vec3(0.52, 0.57, 0.33), 0.40);
        vec3 petals = mix(flower_tint.rgb, vec3(0.82, 0.74, 0.57), 0.18);
        vec3 old_gold = mix(flower_tint.rgb, vec3(0.77, 0.66, 0.43), 0.70);
        color = mix(color, leaves, stitch.g * 0.75);
        color = mix(color, petals, stitch.r * 0.88);
        color = mix(color, old_gold, stitch.b * 0.78);
        embroidered = max(max(stitch.r, stitch.g), stitch.b);
        vec3 raised_thread = texture(embroidery_normal, stitch_uv).rgb * 2.0 - 1.0;
        tangent_normal += raised_thread.xy * 0.30;
    }
    ALBEDO = color;
    ROUGHNESS = mix(0.82 + detail.b * 0.12, 0.83, embroidered);
    ROUGHNESS = mix(ROUGHNESS,clamp(weave_surface.g,0.73,0.94),0.18);
    SPECULAR = 0.23;
    NORMAL_MAP = normalize(vec3(tangent_normal, 1.0)) * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = 1.0;
}
