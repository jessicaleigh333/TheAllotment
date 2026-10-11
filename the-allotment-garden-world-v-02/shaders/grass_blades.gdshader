shader_type spatial;
render_mode cull_disabled, diffuse_burley;
varying vec3 world_position;
varying vec4 tint;
void vertex() {
 world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 tint = COLOR;
 float breeze = sin(world_position.x*0.7+world_position.z*0.43+TIME*1.2);
 VERTEX.x += breeze*0.009*UV.y*UV.y;
}
void fragment() {
 float patch = sin(world_position.x*0.27+sin(world_position.z*0.31))*0.5+0.5;
 vec3 root = vec3(0.15,0.25,0.08);
 vec3 tip = mix(vec3(0.28,0.39,0.12),vec3(0.38,0.46,0.18),patch);
 ALBEDO = mix(root,tip,smoothstep(0.0,1.0,UV.y))*tint.rgb;
 ROUGHNESS = 0.93; SPECULAR = 0.18; METALLIC = 0.0;
 // Rounded blade lighting and a little transmitted light at the fresh tips.
 NORMAL = normalize(mix(FRONT_FACING ? NORMAL : -NORMAL, (VIEW_MATRIX*vec4(0.0,1.0,0.0,0.0)).xyz, 0.65));
 BACKLIGHT = ALBEDO*0.18*UV.y;
}
