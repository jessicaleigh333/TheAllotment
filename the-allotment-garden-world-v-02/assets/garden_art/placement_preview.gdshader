shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform vec4 tint : source_color = vec4(.4,.85,.5,.45);
void fragment() { ALBEDO = tint.rgb; ALPHA = tint.a; ROUGHNESS = .9; }
