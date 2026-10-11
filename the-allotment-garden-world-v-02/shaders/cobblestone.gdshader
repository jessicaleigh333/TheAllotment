shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_position;
varying vec4 stone_tint;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
 vec3 i=floor(p); vec3 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() {
 stone_tint=INSTANCE_CUSTOM;
 float seed=INSTANCE_CUSTOM.a*731.0;
 // Slightly irregular corners and crown avoid perfectly repeated paving blocks.
 VERTEX.x += (hash(vec3(VERTEX.xz*31.0,seed))-0.5)*0.012;
 VERTEX.z += (hash(vec3(VERTEX.zx*43.0,seed+7.0))-0.5)*0.012;
 VERTEX.y += (hash(vec3(VERTEX.xz*23.0,seed+11.0))-0.5)*0.004*smoothstep(0.0,0.04,VERTEX.y);
 world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
 float mineral=noise(world_position*17.0);
 float grain=noise(world_position*140.0);
 float footprint=max(length(dFdx(world_position)),length(dFdy(world_position)));
 grain=mix(grain,0.5,smoothstep(0.006,0.04,footprint));
 ALBEDO=stone_tint.rgb*mix(0.87,1.10,mineral)*mix(0.96,1.04,grain);
 ROUGHNESS=mix(0.82,0.96,mineral);
 SPECULAR=0.24;
 METALLIC=0.0;
 // Small mineral relief, beneath the actual rounded stone silhouette.
 float height=noise(world_position*70.0);
 vec3 bump=vec3(noise((world_position+vec3(0.006,0,0))*70.0)-height,0,noise((world_position+vec3(0,0,0.006))*70.0)-height);
 NORMAL=normalize(NORMAL-(VIEW_MATRIX*vec4(bump,0.0)).xyz*0.15*(1.0-smoothstep(0.015,0.06,footprint)));
}
