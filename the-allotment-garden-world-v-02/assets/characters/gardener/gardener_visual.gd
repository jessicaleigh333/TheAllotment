extends Node3D
const Appearance := preload("res://features/avatar/appearance.gd")
const FABRIC := preload("res://assets/characters/gardener/fabric.gdshader")
const HAIR := preload("res://assets/characters/gardener/hair.gdshader")
const LEATHER := preload("res://assets/characters/gardener/leather.gdshader")
const STRAW := preload("res://assets/characters/gardener/straw.gdshader")
const SKIN := preload("res://assets/characters/gardener/skin.gdshader")
const IRIS := preload("res://assets/characters/gardener/iris.gdshader")
const TEXTURE_DIR := "res://assets/characters/gardener/textures/"
static var texture_cache: Dictionary = {}
var appearance: Dictionary = Appearance.defaults()
var meshes: Dictionary = {}
var originals: Dictionary = {}
var animator: AnimationPlayer
var animation_names: Dictionary = {}
var current_motion := ""

func _ready() -> void:
	_collect($Model)
	if animator != null:
		for animation in animator.get_animation_list():
			var key := str(animation).to_lower()
			if key.ends_with("idle"): animation_names.idle = animation
			if key.ends_with("walk"): animation_names.walk = animation
			if animation != "RESET": animator.get_animation(animation).loop_mode = Animation.LOOP_LINEAR
	apply_appearance(appearance)
	set_motion(false)

func _collect(node: Node) -> void:
	if node is MeshInstance3D:
		meshes[str(node.name)] = node
		if str(node.name) in ["Nose","EyeWhites","Irises","Pupils","EyeGlints","Eyelids","LowerEyelids","Brows","Smile","Freckles"]:
			# Facial relief shades through its normals; tiny shadow maps create
			# harsh marks across a soft face and cannot resolve eyelashes well.
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var materials: Array = []
		for i in range(node.mesh.get_surface_count()): materials.append(node.mesh.surface_get_material(i))
		originals[str(node.name)] = materials
	elif node is AnimationPlayer: animator = node
	for child in node.get_children(): _collect(child)

func _exit_tree() -> void:
	# Release instance materials while their MeshInstances are still alive.
	# This prevents deferred renderer callbacks targeting freed material RIDs.
	for mesh in meshes.values():
		for i in range(mesh.mesh.get_surface_count()):
			mesh.set_surface_override_material(i,null)

static func _texture(filename: String) -> Texture2D:
	if not texture_cache.has(filename):
		texture_cache[filename] = load(TEXTURE_DIR+filename)
	return texture_cache[filename]

func _textured(shader: Shader, tint: Color, detail: String, normal: String = "") -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint",tint)
	material.set_shader_parameter("detail_texture",_texture(detail))
	if not normal.is_empty(): material.set_shader_parameter("detail_normal",_texture(normal))
	return material

func apply_appearance(value: Dictionary) -> bool:
	var validated := Appearance.validate(value)
	if validated.is_empty(): return false
	appearance = validated
	scale = Vector3(appearance.height*appearance.body_build,appearance.height,appearance.height)
	if meshes.is_empty(): return true
	for part in meshes:
		var mesh: MeshInstance3D = meshes[part]
		var show := true
		match part:
			"HairLong": show = appearance.hair_style == "long"
			"HairBob": show = appearance.hair_style == "bob"
			"HairBraids": show = appearance.hair_style == "braids"
			"HairBun": show = appearance.hair_style == "bun"
			"Skirt","SkirtHem","Embroidery": show = appearance.outfit_style == "dress"
			"Hat": show = appearance.hat_enabled
			"HatFlowers": show = appearance.hat_enabled and appearance.flowers_enabled
			"Satchel": show = appearance.satchel_enabled
			"Apron": show = appearance.apron_enabled
			"Freckles": show = appearance.freckles_enabled
			"Cheeks": show = false
		if part.begins_with("Trouser"): show = appearance.outfit_style == "trousers"
		mesh.visible = show
		for i in range(originals[part].size()):
			var original = originals[part][i]
			if original == null: continue
			var material: StandardMaterial3D = original.duplicate()
			var name: String = original.resource_name
			var color_key := ""
			match name:
				"Skin": color_key = "skin_color"
				"Hair","Hair_Highlight": color_key = "hair_color"
				"Eyes": color_key = "eye_color"
				"Lips": color_key = "lip_color"
				"Blouse": color_key = "blouse_color"
				"Outfit": color_key = "outfit_color"
				"Ribbon": color_key = "ribbon_color"
				"Hat","Hat_Weave": color_key = "hat_color"
				"Leather","Leather_Shadow": color_key = "leather_color"
				"Petals": color_key = "flower_color"
			if part == "Brows" or part == "Eyelids": color_key = "brow_color"
			if not color_key.is_empty():
				material.albedo_color = Color.html(appearance[color_key])
				if name == "Hair_Highlight": material.albedo_color = material.albedo_color.lightened(.12)
				if name == "Leather_Shadow" or name == "Hat_Weave": material.albedo_color = material.albedo_color.darkened(.16)
			if name == "Blush": material.albedo_color = Color.html(appearance.skin_color).lerp(Color("d69e91"),.32)
			if name in ["Blush","Freckles","Lips"]:
				material.metallic_specular = 0.0
				material.roughness = .9
			if name in ["Outfit","Blouse"]:
				var fabric := _textured(FABRIC,material.albedo_color,"linen_detail.png","linen_normal.png")
				fabric.set_shader_parameter("flower_tint",Color.html(appearance.flower_color))
				fabric.set_shader_parameter("floral",name == "Outfit" and appearance.outfit_style == "dress")
				fabric.set_shader_parameter("embroidery_texture",_texture("botanical_embroidery.png"))
				fabric.set_shader_parameter("embroidery_normal",_texture("embroidery_normal.png"))
				fabric.set_shader_parameter("woven_normal",load("res://assets/third_party/microsoft_sheen_cloth/technicalFabricSmall_normal_256.png"))
				fabric.set_shader_parameter("woven_orm",load("res://assets/third_party/microsoft_sheen_cloth/technicalFabricSmall_orm_256.png"))
				mesh.set_surface_override_material(i,fabric)
			elif name in ["Hair","Hair_Highlight"] and part.begins_with("Hair"):
				var strands := _textured(HAIR,material.albedo_color,"hair_detail.png","hair_normal.png")
				mesh.set_surface_override_material(i,strands)
			elif name in ["Leather","Leather_Shadow"]:
				mesh.set_surface_override_material(i,_textured(LEATHER,material.albedo_color,"leather_detail.png","leather_normal.png"))
			elif name in ["Hat","Hat_Weave"]:
				var woven := _textured(STRAW,material.albedo_color,"straw_detail.png","straw_normal.png")
				woven.set_shader_parameter("detail_scale",Vector2(2,2))
				woven.set_shader_parameter("normal_strength",.22)
				woven.set_shader_parameter("roughness_bias",.1)
				mesh.set_surface_override_material(i,woven)
			elif name == "Skin":
				var skin := _textured(SKIN,material.albedo_color,"skin_brush_detail.png")
				skin.set_shader_parameter("complexion_texture",_texture("face_complexion.png"))
				skin.set_shader_parameter("face_detail",part in ["Face","Nose"])
				skin.set_shader_parameter("portrait_softness",.35 if part == "Nose" else 0.0)
				mesh.set_surface_override_material(i,skin)
			elif name == "Eyes":
				mesh.set_surface_override_material(i,_textured(IRIS,material.albedo_color,"iris_fibers.png"))
			else: mesh.set_surface_override_material(i,material)
		for j in range(mesh.get_blend_shape_count()):
			var key_name := str(mesh.mesh.get_blend_shape_name(j))
			var property_key: String = {"FaceWidth":"face_width","FaceLength":"face_length","NoseSize":"nose_size","EyeSize":"eye_size","EyeSpacing":"eye_spacing"}.get(key_name,"")
			if not property_key.is_empty(): mesh.set_blend_shape_value(j,appearance[property_key])
	return true

func set_motion(walking: bool, speed: float = 1.0) -> void:
	var key := "walk" if walking else "idle"
	if animator == null or not animation_names.has(key): return
	animator.speed_scale = clampf(speed,.65,1.6) if walking else 1.0
	if current_motion != key:
		current_motion = key
		animator.play(animation_names[key],.2)
