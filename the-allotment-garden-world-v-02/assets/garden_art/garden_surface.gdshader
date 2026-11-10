shader_type spatial;
render_mode cull_disabled;
uniform int kind = 0;
uniform float motion = 1.0;
uniform float wind_strength = 0.012;
uniform float roughness_value = 0.8;
uniform float metallic_value = 0.0;
varying vec3 object_position;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
void vertex() {
 object_position = VERTEX;
 vec3 world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 float bend = COLOR.a * wind_strength * motion * ((kind == 1 || kind == 2) ? 1.0 : 0.0);
 VERTEX.x += bend * sin(TIME*.85+world.x*.37+world.z*.23);
 VERTEX.z += bend*.45 * sin(TIME*1.13+world.z*.31);
}
void fragment() {
 vec3 color = COLOR.rgb;
 float detail = 1.0;
 if (kind == 1) {
  float rib = 1.0-smoothstep(.008,.035,abs(UV.x-.5));
  float vein = 1.0-smoothstep(.04,.16,abs(sin(UV.y*34.0-abs(UV.x-.5)*19.0)));
  detail = .83+.17*sin(UV.x*3.14159)+.10*rib+.045*vein;
 } else if (kind == 2) {
  detail = .91+.09*sin(UV.x*3.14159)+.025*sin(UV.x*75.0);
 } else if (kind == 3) {
  float grain = sin(UV.x*110.0+sin(UV.y*17.0)*3.0);
  detail = .89+.09*grain+.035*sin(UV.x*360.0);
 } else if (kind == 4) {
  float fleck = hash(floor(object_position*160.0));
  detail = .91+.09*fleck;
 } else if (kind == 11) {
  float grain = sin(dot(object_position,vec3(31.0,37.0,29.0)))*sin(dot(object_position,vec3(51.0,23.0,43.0)));
  detail = .96+.04*grain;
 } else if (kind == 5) {
  detail = .86+.10*sin(UV.x*17.0)*sin(UV.y*29.0);
 } else if (kind == 6) {
  detail = .90+.07*sin(UV.y*180.0)+.025*sin(UV.x*220.0);
 } else if (kind == 7) {
  detail = .88+.12*sin(UV.x*160.0)*sin(UV.y*160.0);
 }
 ALBEDO = color*detail;
 ROUGHNESS = roughness_value;
 METALLIC = metallic_value;
 if (kind == 8) { EMISSION = color*(1.8+motion*(.12*sin(TIME*7.0)+.06*sin(TIME*13.1))); ROUGHNESS = .35; }
 if (kind == 9) {
  float ripple = sin(UV.x*35.0+TIME*1.4*motion)*sin(UV.y*29.0-TIME*.9*motion);
  ALBEDO = color*(.85+ripple*.12);
  ROUGHNESS = .16;
  METALLIC = .15;
  EMISSION = color*.04;
 }
}
