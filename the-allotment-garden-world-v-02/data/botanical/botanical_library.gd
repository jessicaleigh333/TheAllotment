extends RefCounted
## Research-backed plant knowledge data. Does NOT change existing growth or saves.
const DATA_PATH := "res://data/botanical/botanical_library.json"
const CURRENT_SCHEMA := "1.0.0"

static func load_library() -> Dictionary:
	if not FileAccess.file_exists(DATA_PATH):
		push_warning("Botanical library missing: " + DATA_PATH)
		return {}
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Botanical library must be a JSON object")
		return {}
	if str(parsed.get("schema_version", "")) != CURRENT_SCHEMA:
		push_warning("Unexpected botanical library schema version")
		return {}
	if not parsed.get("entries") is Array:
		return {}
	var indexed := {}
	for value in parsed["entries"]:
		if not value is Dictionary:
			return {}
		var id := str(value.get("id", ""))
		if id.is_empty() or indexed.has(id):
			push_warning("Missing or duplicated botanical species id: " + id)
			return {}
		if not value.get("identity") is Dictionary or not value.get("environment") is Dictionary or not value.get("gameplay") is Dictionary:
			return {}
		indexed[id] = value
	return indexed

static func species(id: String) -> Dictionary:
	var base := id.get_slice("@", 0)
	if base == "sunflower_seeds":
		base = "sunflower"
	elif base == "basil_seeds":
		base = "basil"
	return load_library().get(base, {})

static func check_existing_growth_ids() -> bool:
	const GROWTH := preload("res://features/market/plant_growth.gd")
	var index := load_library()
	if index.is_empty():
		return false
	for id in GROWTH.PLANTS.keys():
		if not index.has(id):
			push_warning("Missing botanical entry for existing growth id: " + str(id))
			return false
	return true
