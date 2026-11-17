extends SceneTree
## Read-only export smoke test; deliberately disconnected from gameplay.
func _initialize() -> void:
	var paths := OS.get_cmdline_user_args()
	if paths.size() != 2:
		push_error("Expected knowledge.json and godot_approved.json")
		quit(1)
		return
	for path in paths:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			quit(1)
			return
		var parser := JSON.new()
		if parser.parse(file.get_as_text()) != OK:
			quit(1)
			return
		var data: Variant = parser.data
		if not data is Dictionary or data.get("schema_version") != "1.0.0" or not data.get("records") is Array:
			quit(1)
			return
		var ids := {}
		for record in data.records:
			if not record is Dictionary or not record.get("plant_id") is String or record.plant_id.is_empty() or ids.has(record.plant_id):
				quit(1)
				return
			ids[record.plant_id] = true
			if not record.get("source_records") is Array or record.source_records.is_empty():
				quit(1)
				return
		print("READ-ONLY BUNDLE: ", path.get_file(), " records=", ids.size())
	print("PASS: Godot reads versioned botanical exports without changing gameplay or saves")
	quit(0)
