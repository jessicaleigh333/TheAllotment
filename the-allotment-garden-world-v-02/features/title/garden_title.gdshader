shader_type canvas_item;
uniform float motion = 1.0;
uniform float night = 0.0;
float spot(vec2 uv, vec2 center, vec2 radius) {
 return 1.0 - smoothstep(0.45, 1.0, length((uv-center)/radius));
}
void fragment() {
 vec2 uv = UV;
 // Soft breathing in the dog's chest, keeping eyes and paws steady.
 float chest = spot(uv, vec2(0.50,0.73),vec2(0.075,0.12));
 uv.y += motion * chest * sin(TIME*1.6) * 0.0014;
 // Only the hanging canopy and foreground flowers catch the breeze.
 float foliage = (1.0-smoothstep(0.08,0.19,uv.y))*smoothstep(0.38,0.45,uv.x);
 float flowers = smoothstep(0.87,1.0,uv.y)*(1.0-smoothstep(0.25,0.40,uv.x));
 uv.x += motion * (foliage+flowers)*sin(TIME*0.85+UV.y*18.0)*0.0012;
 vec4 color = texture(TEXTURE, uv);
 // Cool moonlight with readable title and plaques and a warm lantern pool.
 float lettering = spot(UV,vec2(.73,.29),vec2(.27,.24));
 float plaques = spot(UV,vec2(.74,.62),vec2(.17,.15));
 float warm_pool = spot(UV,vec2(.08,.19),vec2(.19,.30));
 vec3 moonlit = color.rgb * vec3(.28,.37,.60);
 moonlit = mix(moonlit,color.rgb*vec3(.83,.77,.68),max(lettering*.82,plaques));
 moonlit += warm_pool*vec3(.12,.058,.008);
 color.rgb = mix(color.rgb,moonlit,night);
 float flame = spot(UV,vec2(0.064,0.12),vec2(0.032,0.065));
 float flicker = 0.08 + motion*(0.045*sin(TIME*9.0)+0.025*sin(TIME*17.3));
 color.rgb += flame*(flicker+night*.28)*vec3(1.0,0.56,0.12);
 COLOR = color;
}
