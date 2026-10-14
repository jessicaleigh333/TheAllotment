extends RefCounted
const Definition := preload("res://features/garden_editor/ground_cover/surface_definition.gd")
const SHADER := preload("res://features/garden_editor/ground_cover/surface.gdshader")
var entries: Array = []
var by_id: Dictionary = {}
var categories: Array[String] = []
var material_cache: Dictionary = {}
var night_amount := 0.0

func _init() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://features/garden_editor/ground_cover/catalog.json"))
	for row in data.materials + data.get("border_materials", []):
		var item = Definition.new()
		item.material_id = row.id
		item.display_name = row.name
		item.category = row.category
		item.profile = int(row.profile)
		item.variant = int(row.variant)
		item.tile_scale = float(row.scale)
		item.base_color = Color(row.base)
		item.joint_color = Color(row.joint)
		item.accent_color = Color(row.accent)
		item.roughness = float(row.roughness)
		item.metallic = float(row.get("metallic", 0.0))
		item.natural = row.natural
		item.luminous = row.luminous
		if item.category != "Borders": entries.append(item)
		by_id[item.material_id] = item
		if item.category != "Borders" and not categories.has(item.category): categories.append(item.category)

func default_style(id: String) -> Dictionary:
	if not by_id.has(id): return {}
	var item = by_id[id]
	return {"material_id": id, "base": item.base_color.to_html(), "joint": item.joint_color.to_html(), "accent": item.accent_color.to_html(), "roughness": item.roughness, "metallic": item.metallic, "scale": item.tile_scale, "rotation": 0.0, "brightness": 1.0, "saturation": 1.0, "glow_enabled": item.luminous, "glow_color": "63e4ffff", "glow_secondary": "c592ffff", "glow_intensity": 2.0, "glow_mode": 0, "glow_palette": 0, "detail_id": "none", "detail_amount": 0.0}

func validate_style(value: Variant) -> Dictionary:
	if not value is Dictionary: return {}
	var id := str(value.get("material_id", ""))
	var result := default_style(id)
	if result.is_empty(): return {}
	for key in ["base", "joint", "accent", "glow_color", "glow_secondary"]:
		var hex := str(value.get(key, result[key]))
		if not Color.html_is_valid(hex): return {}
		result[key] = Color.html(hex).to_html()
	for key in ["scale", "rotation", "roughness", "metallic", "brightness", "saturation", "glow_intensity", "detail_amount"]:
		var number = value.get(key, result[key])
		if not number is float and not number is int: return {}
		if not is_finite(float(number)): return {}
		result[key] = float(number)
	result.scale = clampf(result.scale, 0.08, 8.0)
	result.rotation = wrapf(result.rotation, 0.0, 360.0)
	result.roughness = clampf(result.roughness, 0.05, 1.0)
	result.metallic = clampf(result.metallic, 0.0, 1.0)
	result.brightness = clampf(result.brightness, 0.1, 2.0)
	result.saturation = clampf(result.saturation, 0.0, 2.0)
	result.glow_intensity = clampf(result.glow_intensity, 0.0, 8.0)
	result.detail_amount = clampf(result.detail_amount, 0.0, 1.0)
	result.glow_mode = clampi(int(value.get("glow_mode", 0)), 0, 5)
	result.glow_palette = clampi(int(value.get("glow_palette", 0)), 0, 2)
	result.glow_enabled = value.get("glow_enabled", result.glow_enabled) == true
	var detail := str(value.get("detail_id", "none"))
	result.detail_id = detail if detail in ["none", "moss", "glowing_pebbles", "ornate_tile"] else "none"
	return result

func style_key(style: Dictionary) -> String:
	# Normalized fields have a deterministic insertion order.
	return JSON.stringify(style)

func material_for(style: Dictionary) -> ShaderMaterial:
	var key := style_key(style)
	if material_cache.has(key): return material_cache[key]
	var item = by_id[style.material_id]
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("profile", item.profile)
	material.set_shader_parameter("variant", float(item.variant))
	material.set_shader_parameter("natural_cover", item.natural)
	for pair in [["base_color", "base"], ["joint_color", "joint"], ["accent_color", "accent"], ["glow_color", "glow_color"], ["glow_secondary", "glow_secondary"]]:
		material.set_shader_parameter(pair[0], Color.html(style[pair[1]]))
	for pair in [["tile_scale", "scale"], ["pattern_rotation", "rotation"], ["surface_roughness", "roughness"], ["surface_metallic", "metallic"], ["color_brightness", "brightness"], ["color_saturation", "saturation"], ["glow_enabled", "glow_enabled"], ["glow_intensity", "glow_intensity"], ["glow_mode", "glow_mode"], ["glow_palette", "glow_palette"], ["detail_amount", "detail_amount"]]:
		material.set_shader_parameter(pair[0], style[pair[1]])
	material.set_shader_parameter("detail_mode", ["none", "moss", "glowing_pebbles", "ornate_tile"].find(style.detail_id))
	material.set_shader_parameter("hdr_glow", ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility") != "gl_compatibility")
	material.set_shader_parameter("night_amount", night_amount)
	material_cache[key] = material
	return material

func set_night(amount: float) -> void:
	night_amount = clampf(amount, 0.0, 1.0)
	for material in material_cache.values(): material.set_shader_parameter("night_amount", night_amount)
