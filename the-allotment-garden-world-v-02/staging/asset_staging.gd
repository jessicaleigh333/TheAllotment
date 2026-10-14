extends "res://scripts/world.gd"
## Preserved grid, with editable asset slots. Adding an asset hides that bay's sample garden.
func _ready() -> void:
	super._ready()
	for slot in $AssetSlots.get_children():
		if slot.get_child_count() > 0:
			get_node(NodePath(str(slot.get_meta("sample_plot")))).hide()

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.position = Vector2(18, 16)
	label.text = "ASSET STAGING • grid preview\nAdd wall / asset scenes under AssetSlots to replace a sample bay.\nWASD: pan • Q/E: rotate • Right-drag: orbit • Wheel: zoom • R: reset"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("fff0ca"))
	label.add_theme_color_override("font_shadow_color", Color("24372a"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(label)
