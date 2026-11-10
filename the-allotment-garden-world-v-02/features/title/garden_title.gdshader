shader_type canvas_item;
uniform float motion = 1.0;
uniform float night = 0.0;
uniform int season = 0;
float spot(vec2 uv, vec2 center, vec2 radius) {
 return 1.0 - smoothstep(0.45, 1.0, length((uv-center)/radius));
}
float halo(vec2 uv, vec2 center, vec2 radius) {
 vec2 offset = (uv-center)/radius;
 return exp(-dot(offset,offset)*3.0);
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
 vec3 painted = color.rgb;
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
 // Painted light sources have their own soft halos, without renderer bloom.
 float lantern_halo = halo(UV,vec2(.065,.122),vec2(.065,.10));
 color.rgb += night*lantern_halo*vec3(.48,.23,.035);
 // Follow the bright water and basin edges rather than lighting a flat oval.
 float water_mask = spot(UV,vec2(.946,.684),vec2(.065,.122));
 float water_detail = smoothstep(.55,.92,max(painted.r,max(painted.g,painted.b)));
 float shimmer = 1.0 + motion*.12*sin(TIME*1.35+UV.y*75.0);
 float fountain_halo = halo(UV,vec2(.946,.70),vec2(.068,.12));
 color.rgb += night*(water_mask*water_detail*.75*shimmer+fountain_halo*.10)*vec3(.24,.62,.83);
 // Small moonlit flower clusters and trailing greenery catch jewel-like light.
 float petals = halo(UV,vec2(.102,.830),vec2(.035,.032))
  + halo(UV,vec2(.183,.928),vec2(.042,.025))
  + halo(UV,vec2(.923,.843),vec2(.035,.031));
 float petal_detail = smoothstep(.45,.85,max(painted.r,max(painted.g,painted.b)));
 vec3 petal_glow = season == 3 ? vec3(.21,.44,.66) : vec3(.30,.30,.55);
 color.rgb += night*petals*petal_detail*petal_glow;
 // A sparse constellation of fireflies stays in the planting margins.
 // Reduced motion freezes drift and breathing; warm light remains steady.
 float clock = TIME*motion;
 vec3 firefly_color = season == 3 ? vec3(.42,.62,.85) : vec3(.65,.64,.20);
 for (int i=0; i<14; i++) {
  float index = float(i);
  float seed = fract(sin(index*127.1+18.7)*43758.5453);
  float right_side = step(7.0,index);
  vec2 center = vec2(mix(.025+seed*.15,.88+seed*.105,right_side),.47+fract(seed*7.3)*.48);
  center += motion*vec2(sin(clock*.23+index)*.009,cos(clock*.18+index*1.7)*.012);
  float breath = .65+motion*.25*sin(clock*.65+index*2.0);
  float glow = halo(UV,center,vec2(.008,.012));
  float core = halo(UV,center,vec2(.0017,.00255));
  color.rgb += night*breath*(glow*.25+core*.85)*firefly_color;
 }
 COLOR = color;
}
