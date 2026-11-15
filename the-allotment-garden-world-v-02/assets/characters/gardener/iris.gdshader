shader_type spatial;
render_mode diffuse_burley;

uniform vec4 tint : source_color = vec4(0.39,0.51,0.45,1.0);
uniform sampler2D detail_texture : filter_linear_mipmap, repeat_disable;

void fragment() {
	vec3 fibres = texture(detail_texture,UV).rgb;
	vec3 color = tint.rgb*(0.66+fibres.r*0.55);
	vec3 warm_ring = tint.rgb*vec3(1.18,0.92,0.58);
	color = mix(color,warm_ring,fibres.g*0.36);
	ALBEDO = color;
	ROUGHNESS = 0.38;
	SPECULAR = 0.25;
}
