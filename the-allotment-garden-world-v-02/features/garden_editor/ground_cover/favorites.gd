extends RefCounted
const PATH := "user://ground_cover/favorites.json"
var colors: Array[String] = []
var combinations: Array[Dictionary] = []
var catalog
var storage_path := PATH

func _init(material_catalog, path: String = PATH) -> void:
	catalog = material_catalog
	storage_path = path
	if FileAccess.file_exists(storage_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(storage_path))
		if data is Dictionary and data.get("schema_version", 0) == 1 and data.get("colors", []) is Array and data.get("combinations", []) is Array:
			for value in data.get("colors", []):
				if value is String and Color.html_is_valid(value) and colors.size() < 32: colors.append(Color.html(value).to_html())
			for value in data.get("combinations", []):
				if not value is Dictionary or combinations.size() >= 64: continue
				var style: Dictionary = catalog.validate_style(value.get("style"))
				if not style.is_empty(): combinations.append({"name": str(value.get("name", "Favorite")).left(80), "style": style})

func save_color(color: Color) -> bool:
	var hex := color.to_html()
	if colors.has(hex): return _save()
	if colors.size() >= 32: colors.pop_front()
	colors.append(hex)
	return _save()

func save_combination(style: Dictionary) -> bool:
	var normalized: Dictionary = catalog.validate_style(style)
	if normalized.is_empty(): return false
	for item in combinations:
		if item.style == normalized: return _save()
	if combinations.size() >= 64: combinations.pop_front()
	combinations.append({"name": catalog.by_id[normalized.material_id].display_name + " • " + normalized.base.left(6).to_upper(), "style": normalized})
	return _save()

func _save() -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(storage_path.get_base_dir()))
	var file := FileAccess.open(storage_path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"schema_version": 1, "colors": colors, "combinations": combinations}))
	file.flush()
	var error := file.get_error()
	file.close()
	return error == OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(storage_path + ".tmp"), ProjectSettings.globalize_path(storage_path)) == OK
