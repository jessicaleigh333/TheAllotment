shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_position;
varying vec3 world_normal;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float turf(vec2 p) { return noise(p*24.0)*0.55 + noise(p*57.0)*0.3 + noise(p*113.0)*0.15; }
void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL,0.0)).xyz);
}
void fragment() {
 vec2 p = world_position.xz;
 float patch = noise(p*0.23)*0.65 + noise(p*0.79)*0.35;
 float footprint = max(length(dFdx(p)), length(dFdy(p)));
 float detail = mix(turf(p), 0.5, smoothstep(0.02,0.16,footprint));
 vec3 green = mix(vec3(0.115,0.205,0.055),vec3(0.29,0.385,0.125),patch);
 ALBEDO = green * mix(0.78,1.22,detail);
 ROUGHNESS = mix(0.88,0.98,detail);
 METALLIC = 0.0; SPECULAR = 0.22;
 // Fine relief fades with distance so the lawn stays soft instead of sparkling.
 float relief = 0.12 * (1.0-smoothstep(18.0,55.0,length(VERTEX)));
 float dx = turf(p+vec2(0.008,0.0))-detail;
 float dz = turf(p+vec2(0.0,0.008))-detail;
 if (abs(world_normal.y)>0.7) { NORMAL = normalize(NORMAL + (VIEW_MATRIX*vec4(-dx*relief,0.0,-dz*relief,0.0)).xyz); }
}
