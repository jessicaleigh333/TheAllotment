extends ScrollContainer

const Store := preload("res://features/market/market_store.gd")
const Catalog := preload("res://features/market/catalog.gd")

func _ready() -> void:
	var entries := VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(entries)
	var store := Store.new()
	if not store.readable:
		_entry(entries, store.last_error)
		return
	var observations: Array = store.data.get("observations", [])
	if observations.is_empty():
		_entry(entries, "Water or harvest a plant to make your first journal entry.")
		return
	for index in range(observations.size() - 1, -1, -1):
		var observation: Dictionary = observations[index]
		var action := "Watered" if observation.kind == "water" else "Harvested"
		var date := Time.get_date_string_from_unix_time(int(observation.at))
		_entry(entries, "%s UTC · %s %s" % [date, action, Catalog.by_id(observation.plant).name])

func _entry(entries: Control, value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("334632"))
	entries.add_child(label)
