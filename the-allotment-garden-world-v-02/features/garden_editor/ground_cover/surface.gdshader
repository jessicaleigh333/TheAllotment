shader_type spatial;
render_mode cull_disabled, depth_draw_always;
uniform float preview_opacity = 1.0;
uniform float surface_metallic = 0.0;
uniform int profile = 0;
uniform float variant = 0.0;
uniform vec4 base_color : source_color = vec4(0.6, 0.5, 0.4, 1.0);
uniform vec4 joint_color : source_color = vec4(0.4, 0.4, 0.3, 1.0);
uniform vec4 accent_color : source_color = vec4(0.7, 0.6, 0.4, 1.0);
uniform float tile_scale = 0.7;
uniform float pattern_rotation = 0.0;
uniform float surface_roughness = 0.85;
uniform float color_brightness = 1.0;
uniform float color_saturation = 1.0;
uniform bool natural_cover = false;
uniform bool glow_enabled = false;
uniform vec4 glow_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform vec4 glow_secondary : source_color = vec4(0.8, 0.4, 1.0, 1.0);
uniform float glow_intensity = 2.0;
uniform bool hdr_glow = false;
uniform int glow_mode = 0;
uniform int glow_palette = 0;
uniform float night_amount = 0.0;
uniform int detail_mode = 0;
uniform float detail_amount = 0.0;
uniform float cell_size = 0.5;

float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 hash22(vec2 p) { return vec2(hash2(p), hash2(p + 17.31)); }
float noise2(vec2 p) {
 vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
 return mix(mix(hash2(i), hash2(i + vec2(1, 0)), f.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), f.x), f.y);
}
vec3 stones(vec2 p) {
 vec2 grid = floor(p); vec2 f = fract(p); float first = 8.0; float second = 8.0; float seed = 0.0;
 for (int y = -1; y <= 1; y++) {
  for (int x = -1; x <= 1; x++) {
   vec2 g = vec2(float(x), float(y)); vec2 d = g + 0.18 + hash22(grid + g) * 0.64 - f;
   float dist = length(d);
   if (dist < first) { second = first; first = dist; seed = hash2(grid + g); }
   else { second = min(second, dist); }
  }
 }
 return vec3(first, second - first, seed);
}
float tile_body(vec2 p, float grout) {
 vec2 f = fract(p); return smoothstep(grout, grout + 0.035, min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)));
}
vec3 rainbow(float t) { return 0.55 + 0.45 * cos(6.28318 * (vec3(0.0, 0.33, 0.67) + t)); }

void fragment() {
 float a = radians(pattern_rotation); mat2 turn = mat2(vec2(cos(a), -sin(a)), vec2(sin(a), cos(a)));
 vec2 p = turn * UV / max(tile_scale, 0.08); vec2 f = fract(p) - 0.5;
 float body = 1.0; float motif = 0.0; float seed = hash2(floor(p)); float relief = 0.0;
 float grain = noise2(p * 19.0 + variant * 0.71) * 0.6 + noise2(p * 63.0 + variant * 1.37) * 0.4;
 vec3 vor = stones(p);
 if (profile == 0) {
  vec2 q = p; q.x += mod(floor(q.y), 2.0) * 0.5; q.y *= variant == 1.0 ? 1.8 : 1.35;
  vec2 d = abs(fract(q) - 0.5); float shape = length(max(d - vec2(0.28, 0.27), 0.0));
  body = 1.0 - smoothstep(0.15, 0.19, shape); seed = hash2(floor(q)); relief = body * (0.65 + 0.35 * cos(length(d) * 4.0));
 } else if (profile == 1 || profile == 9 || profile == 21 || profile == 22) {
  vec2 q = p;
  if (profile == 9) { q = mat2(vec2(0.707, -0.707), vec2(0.707, 0.707)) * p; if (mod(floor(q.x) + floor(q.y), 2.0) > 0.5) q = q.yx; }
  if (profile == 21) { if (mod(floor(p.x / 2.0) + floor(p.y / 2.0), 2.0) > 0.5) q = p.yx; }
  if (profile == 22) q = vec2(atan(p.y, p.x) * max(1.0, floor(length(p))) * 1.5, length(p));
  q.y *= 2.0; q.x += mod(floor(q.y), 2.0) * 0.5;
  body = tile_body(q, 0.045); seed = hash2(floor(q)); relief = body;
 } else if (profile == 2 || profile == 13 || profile == 12 || profile == 15) {
  body = 1.0; motif = smoothstep(0.6, 0.82, noise2(p * 2.0));
  if (profile == 13) {
   motif = pow(abs(sin(p.x * 18.0 + noise2(p * 3.0) * 9.0)), 14.0);
   if (variant == 3.0) { // three rounded clover leaflets
    float leaf = min(length(f - vec2(-0.11, 0.08)), min(length(f - vec2(0.11, 0.08)), length(f - vec2(0.0, -0.12))));
    motif = 1.0 - smoothstep(0.10, 0.15, leaf);
   }
   if (variant == 4.0) { // scattered meadow flowers
    float flower = 0.10 + 0.025 * cos(atan(f.y, f.x) * 5.0);
    motif = (1.0 - smoothstep(flower, flower + 0.02, length(f))) * step(0.76, seed);
   }
  }
  if (profile == 15) {
   vec2 d = abs(f); motif = (1.0 - smoothstep(0.08, 0.2, d.x + d.y * 0.35)) * smoothstep(0.05, 0.13, length(f));
   if (variant == 10.0) motif = pow(abs(sin(p.x * 21.0 + p.y * 6.0)), 24.0);
   if (variant == 14.0) motif = (1.0 - smoothstep(0.04, 0.10, abs(f.x) - 0.08 * abs(sin(f.y * 32.0)))) * (1.0 - smoothstep(0.30, 0.43, abs(f.y)));
  }
  if (profile == 12) motif = smoothstep(0.68, 0.9, grain);
  relief = grain;
 } else if (profile == 3) {
  body = 1.0 - smoothstep(0.26, 0.43, vor.x); seed = vor.z; relief = body * (1.0 - vor.x);
 } else if (profile == 4 || profile == 19 || profile == 24 || profile == 25) {
  body = tile_body(p, 0.018); relief = body;
  if (profile == 19) motif = mod(floor(p.x) + floor(p.y), 2.0);
  if (profile == 24) motif = noise2(vec2(p.x * 25.0, p.y * 2.0));
  if (profile == 25) { body *= 1.0 - smoothstep(0.69, 0.75, abs(f.x) + abs(f.y)); motif = step(0.66, abs(f.x) + abs(f.y)); }
  if (variant > 8.0 && profile == 4) motif = smoothstep(0.52, 0.62, noise2(p * 2.0 + sin(p.y * 3.0))); // mineral veining
 } else if (profile == 5 || profile == 23 || profile == 17 || profile == 18 || profile == 26 || profile == 27) {
  body = tile_body(p, 0.025); float r = length(f); float angle = atan(f.y, f.x);
  if (profile == 5 || profile == 23) {
   float petal = 0.22 + 0.08 * cos(angle * (profile == 23 ? 5.0 : 8.0));
   motif = 1.0 - smoothstep(0.022, 0.045, abs(r - petal));
   motif = max(motif, (1.0 - smoothstep(0.045, 0.065, r)));
   motif = max(motif, (1.0 - smoothstep(0.008, 0.02, abs(abs(f.x) + abs(f.y) - 0.45))));
  }
  if (profile == 17 || profile == 18) {
   float star = 0.18 + 0.22 * pow(abs(cos(angle * (profile == 17 ? 4.0 : 2.5))), 5.0);
   motif = 1.0 - smoothstep(star, star + 0.012, r);
   if (profile == 17) motif = max(motif, 1.0 - smoothstep(0.008, 0.02, abs(r - 0.43)));
   if (profile == 18) body = max(motif, 0.04);
  }
  if (profile == 26) { motif = (1.0 - smoothstep(0.30, 0.32, r)) * smoothstep(0.27, 0.29, length(f - vec2(0.14, 0.08))); body = motif; }
  if (profile == 27) { body = 1.0 - smoothstep(0.36, 0.4, abs(f.x) + abs(f.y)); motif = step(0.0, f.x * f.y) * 0.65; }
  relief = body * (0.7 + motif * 0.3);
 } else if (profile == 7 || profile == 14) {
  float r = length(f); body = 1.0 - smoothstep(0.36, 0.40, r + noise2(p * 5.0) * 0.03); seed = hash2(floor(p)); relief = body;
  if (profile == 14) motif = 0.3 + 0.3 * sin(r * 110.0 + noise2(p * 15.0) * 4.0);
 } else if (profile == 8) {
  body = smoothstep(0.03, 0.075, vor.y); seed = vor.z; relief = body;
 } else if (profile == 10) {
  vec2 q = p; q.x *= 1.1547; q.x += mod(floor(q.y), 2.0) * 0.5;
  vec2 d = abs(fract(q) - 0.5); float edge = max(d.x * 0.866 + d.y * 0.5, d.y);
  body = 1.0 - smoothstep(0.44, 0.49, edge); seed = hash2(floor(q)); relief = body;
 } else if (profile == 11) {
  vec2 q = vec2(p.x, p.y / 7.0); q.y += hash2(vec2(floor(p.x), 0.0)); body = tile_body(q, 0.025); seed = hash2(floor(q));
  motif = 0.25 + 0.25 * sin(p.x * 31.0 + noise2(vec2(p.x * 2.0, p.y * 0.4)) * 15.0); relief = body;
 } else if (profile == 16) {
  vec2 q = fract(p / 4.0) * 4.0 - vec2(2.0, 0.0);
  float r = length(q); float angle = atan(q.x, q.y); vec2 grid = vec2(angle * max(1.0, floor(r * 3.0)) * 2.0, r * 3.0);
  body = tile_body(grid, 0.06); seed = hash2(floor(grid)); relief = body;
 } else if (profile == 20) {
  body = smoothstep(0.03, 0.09, vor.y); seed = vor.z; motif = step(0.5, seed); relief = body;
 }
 vec3 stone_color = mix(base_color.rgb, accent_color.rgb, clamp(motif, 0.0, 1.0));
 stone_color *= (0.82 + seed * 0.24) * (0.85 + grain * 0.24);
 vec3 color = mix(joint_color.rgb * (0.88 + grain * 0.2), stone_color, body);
 if (detail_mode == 1) { float moss = (1.0 - body) * detail_amount + smoothstep(0.62, 0.85, noise2(p * 3.0)) * detail_amount * 0.4; color = mix(color, accent_color.rgb, clamp(moss, 0.0, 1.0)); }
 float detail_glow = 0.0;
 if (detail_mode == 2) { vec3 v = stones(p * 2.0); detail_glow = (1.0 - smoothstep(0.10, 0.19, v.x)) * step(1.0 - detail_amount, v.z); color = mix(color, accent_color.rgb, detail_glow * 0.65); }
 if (detail_mode == 3) { float flower = 1.0 - smoothstep(0.015, 0.045, abs(length(f) - (0.20 + 0.06 * cos(atan(f.y, f.x) * 8.0)))); color = mix(color, accent_color.rgb, flower * detail_amount); detail_glow = flower * detail_amount; }
 float lum = (profile == 3 ? body * step(0.65, seed) : max(motif, body * 0.65));
 if (glow_mode == 1) lum = 1.0;
 if (glow_mode == 2) lum = body * (1.0 - smoothstep(0.3, 0.75, relief));
 if (glow_mode == 3) lum = 1.0 - body;
 if (glow_mode == 4) lum = motif;
 if (glow_mode == 5) lum = body * step(0.75, seed);
 lum = max(lum, detail_glow);
 vec3 emission_color = glow_color.rgb;
 if (glow_palette == 1) emission_color = mix(glow_color.rgb, glow_secondary.rgb, step(0.5, seed));
 if (glow_palette == 2) emission_color = rainbow(seed + variant * 0.027);
 float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
 ALBEDO = max(vec3(0.0), mix(vec3(luminance), color, color_saturation) * color_brightness);
 ROUGHNESS = clamp(surface_roughness + (grain - 0.5) * 0.12, 0.05, 1.0);
 METALLIC = surface_metallic;
 NORMAL_MAP = normalize(vec3((grain - 0.5) * 0.16, (relief - 0.5) * 0.12, 1.0)) * 0.5 + 0.5;
 float glow_energy = hdr_glow ? glow_intensity : 1.0 - exp(-glow_intensity * 0.8);
 EMISSION = glow_enabled ? emission_color * lum * glow_energy * mix(0.025, 1.0, night_amount) : vec3(0.0);
 vec2 cell = fract(UV / cell_size);
 float edge = 1.0;
 if (COLOR.r > 0.5) edge = min(edge, cell.x);
 if (COLOR.g > 0.5) edge = min(edge, 1.0 - cell.x);
 if (COLOR.b > 0.5) edge = min(edge, cell.y);
 if (COLOR.a > 0.5) edge = min(edge, 1.0 - cell.y);
 ALPHA = preview_opacity * smoothstep(0.0, natural_cover ? 0.26 : 0.065, edge);
}
