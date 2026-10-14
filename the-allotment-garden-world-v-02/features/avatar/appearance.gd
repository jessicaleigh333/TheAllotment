extends RefCounted
## Versioned local appearance. No avatar option assigns plot ownership.
const PATH := "user://avatar/appearance.json"
const DEFAULTS := {"skin_color":"eac2a7ff", "hair_color":"714a33ff", "eye_color":"638274ff", "brow_color":"714a33ff", "lip_color":"b57c76ff", "blouse_color":"eee5cfff", "outfit_color":"667b56ff", "hat_color":"cba76aff", "ribbon_color":"b78683ff", "leather_color":"946443ff", "flower_color":"d89ea1ff", "hair_style":"long", "outfit_style":"dress", "height":1.0, "body_build":1.0, "face_width":0.0, "face_length":0.0, "nose_size":0.0, "eye_size":0.0, "eye_spacing":0.0, "hat_enabled":true, "flowers_enabled":true, "satchel_enabled":true, "apron_enabled":false, "freckles_enabled":true}

static func defaults() -> Dictionary:
	return DEFAULTS.duplicate(true)

static func validate(data: Variant) -> Dictionary:
	if not data is Dictionary: return {}
	var result := defaults()
	for key in result:
		var value = data.get(key,result[key])
		if str(key).ends_with("_color"):
			if not value is String or not Color.html_is_valid(value): return {}
			result[key] = Color.html(value).to_html()
		elif result[key] is bool:
			if not value is bool: return {}
			result[key] = value
		elif result[key] is float:
			if (not value is float and not value is int) or not is_finite(float(value)): return {}
			result[key] = clampf(float(value),.9,1.1) if key == "height" else (clampf(float(value),.88,1.15) if key == "body_build" else clampf(float(value),0,1))
		else:
			var choices: Array = ["long","bob","braids","bun"] if key == "hair_style" else ["dress","trousers"]
			if not choices.has(value): return {}
			result[key] = value
	return result

static func load_saved(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path): return defaults()
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > 65536: return defaults()
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("schema_version",0) != 1: return defaults()
	var value := validate(data.get("appearance"))
	return defaults() if value.is_empty() else value

static func save(value: Dictionary, path: String = PATH) -> bool:
	var validated := validate(value)
	if validated.is_empty(): return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir())) != OK: return false
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"schema_version":1,"appearance":validated}))
	file.flush()
	var error := file.get_error()
	file.close()
	return error == OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path)) == OK
