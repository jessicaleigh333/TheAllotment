extends RefCounted
## Local device profiles only. No passwords, remote accounts or ownership claims.
const INDEX := "user://profiles/index.json"
var path := INDEX
var last_error := ""

func _init(index_path: String = INDEX) -> void:
	path = index_path

func read() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"version":1,"active":"","profiles":[]}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > 262144:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return {}
	var data = parser.data
	if not data is Dictionary or data.get("version") != 1 or not data.get("profiles") is Array:
		return {}
	var ids := {}
	for profile in data.profiles:
		if not profile is Dictionary or not profile.get("id") is String or not profile.get("name") is String:
			return {}
		var id: String = profile.id
		if id.length() != 32 or not id.is_valid_hex_number(false) or ids.has(id): return {}
		if profile.name.strip_edges().is_empty() or profile.name.length() > 24: return {}
		ids[id] = true
	if not data.get("active") is String: return {}
	if not data.active.is_empty() and not ids.has(data.active): return {}
	return data

func create(display_name: String) -> String:
	last_error = ""
	var name := display_name.strip_edges()
	if name.is_empty() or name.length() > 24:
		last_error = "Choose a name between 1 and 24 characters."
		return ""
	var data := read()
	if data.is_empty():
		last_error = "The profile list could not be read. Your saves have been kept."
		return ""
	if data.profiles.size() >= 24:
		last_error = "This device already has 24 profiles."
		return ""
	for profile in data.profiles:
		if profile.name.to_lower() == name.to_lower():
			last_error = "That name already has a saved profile. Choose it under Login."
			return ""
	var id := Crypto.new().generate_random_bytes(16).hex_encode()
	if data.profiles.is_empty() and path == INDEX and not _copy_legacy(id):
		last_error = "Your existing saves could not be copied. They have been kept unchanged."
		return ""
	data.profiles.append({"id":id,"name":name})
	data.active = id
	return id if _write(data) else ""

func _copy_legacy(id: String) -> bool:
	var files: Array[String] = []
	if FileAccess.file_exists("user://avatar/appearance.json"):
		files.append("avatar/appearance.json")
	if FileAccess.file_exists("user://market.json"):
		files.append("market.json")
	if DirAccess.dir_exists_absolute("user://ground_cover"):
		for file in DirAccess.get_files_at("user://ground_cover"):
			if file.ends_with(".json"): files.append("ground_cover/"+file)
	for file in files:
		var target := "user://profiles/"+id+"/"+file
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir())) != OK: return false
		if DirAccess.copy_absolute(ProjectSettings.globalize_path("user://"+file),ProjectSettings.globalize_path(target)) != OK: return false
	return true

func activate(id: String) -> bool:
	var data := read()
	if data.is_empty(): return false
	for profile in data.profiles:
		if profile.id == id:
			data.active = id
			return _write(data)
	last_error = "Choose a saved profile."
	return false

func _write(data: Dictionary) -> bool:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir())) != OK:
		last_error = "Profiles could not be saved on this device."
		return false
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		last_error = "Profiles could not be saved on this device."
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path)) != OK:
		last_error = "Profiles could not be saved on this device."
		return false
	return true

static func save_root() -> String:
	var data := new().read()
	if data.is_empty() or data.active.is_empty(): return "user://"
	return "user://profiles/"+data.active+"/"
