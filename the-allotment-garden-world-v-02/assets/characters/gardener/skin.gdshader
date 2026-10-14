shader_type spatial;
render_mode diffuse_burley;

uniform vec4 tint : source_color = vec4(0.92,0.76,0.65,1.0);
uniform sampler2D detail_texture : filter_linear_mipmap, repeat_enable;
uniform sampler2D complexion_texture : filter_linear_mipmap, repeat_disable;
uniform bool face_detail = false;
uniform float portrait_softness : hint_range(0.0,0.5) = 0.0;

void fragment() {
	vec3 brush = texture(detail_texture,UV*3.0).rgb;
	vec3 painted = tint.rgb*(0.98+(brush.r-0.5)*0.065);
	if (face_detail) {
		vec3 masks = texture(complexion_texture,UV).rgb;
		// Translucent rose underpaint follows the selected skin tone.
		vec3 rose = tint.rgb*vec3(1.025,0.73,0.71);
		painted = mix(painted,rose,masks.r*0.64);
		painted *= 1.0-masks.g*0.18;
		painted *= 1.0+masks.b*0.075;
	}
	ALBEDO = painted;
	ROUGHNESS = clamp(brush.b,0.73,0.87);
	SPECULAR = 0.18;
	// Soft portrait planes keep tiny facial relief from shading like a hard cut.
	NORMAL = normalize(mix(NORMAL,vec3(0.0,0.0,1.0),portrait_softness));
}
