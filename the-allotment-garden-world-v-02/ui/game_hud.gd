extends CanvasLayer
## Reusable side navigation. Replace feature screen scenes to connect destinations.
signal destination_opened(destination: String)
signal panel_visibility_changed(is_open: bool)

const LEFT := ["help", "settings", "garden_editor", "shop", "inventory", "journal"]
const RIGHT := ["weather", "world_map", "friends", "messages", "events", "challenges"]
const ICON_ORDER := ["help", "settings", "garden_editor", "shop", "inventory", "journal", "weather", "world_map", "friends", "messages", "events", "challenges"]
const TITLES := {"help": "Help / Louise", "settings": "Settings", "garden_editor": "Garden Editor", "shop": "Shop", "inventory": "Inventory", "journal": "Journal", "weather": "Weather", "world_map": "World Map", "friends": "Friends", "messages": "Messages", "events": "Events", "challenges": "Challenges"}
var dialog: PanelContainer
var title: Label
var content: VBoxContainer
var last_button: Button
var weather_button: Button
var weather_provider

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_column(root, LEFT, false)
	_build_column(root, RIGHT, true)
	_build_dialog(root)
	weather_provider = get_parent().get_node_or_null("GardenWeather")
	if weather_provider != null:
		weather_provider.weather_changed.connect(_update_weather)
		_update_weather()

func _build_column(root: Control, items: Array, right: bool) -> void:
	var column := VBoxContainer.new()
	root.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT if right else Control.PRESET_TOP_LEFT)
	column.offset_left = -150 if right else 18
	column.offset_right = -18 if right else 94
	column.offset_top = 20
	column.offset_bottom = 20
	column.add_theme_constant_override("separation", 8)
	for id in items:
		var button := Button.new()
		button.name = id.to_pascal_case()
		button.custom_minimum_size = Vector2(76, 76)
		button.icon = _icon_texture(id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 64)
		button.tooltip_text = TITLES[id]
		for state in ["normal", "pressed"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		for state in ["hover", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(1, 0.88, 0.6, 0.16)
			style.set_corner_radius_all(16)
			style.border_color = Color("efd6a2")
			style.set_border_width_all(1)
			button.add_theme_stylebox_override(state, style)
		button.pressed.connect(_open.bind(id, button))
		column.add_child(button)
		if id == "weather":
			weather_button = button
			button.text = "—"
			button.add_theme_font_size_override("font_size", 22)
			button.add_theme_color_override("font_color", Color("334632"))
			button.add_theme_color_override("font_shadow_color", Color("fff0ca"))
			button.add_theme_constant_override("shadow_offset_x", 1)
			button.add_theme_constant_override("shadow_offset_y", 2)

func _icon_texture(id: String) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://ui/icons/storybook_icons.png")
	var index := ICON_ORDER.find(id)
	var cell := Vector2(atlas.atlas.get_width() / 4.0, atlas.atlas.get_height() / 3.0)
	atlas.region = Rect2(Vector2(index % 4, floori(index / 4.0)) * cell, cell)
	atlas.filter_clip = true
	return atlas

func _build_dialog(root: Control) -> void:
	dialog = PanelContainer.new()
	root.add_child(dialog)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dialog.offset_left = -230
	dialog.offset_right = 230
	dialog.offset_top = -150
	dialog.offset_bottom = 150
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f2e5ca")
	style.border_color = Color("b79250")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	dialog.add_theme_stylebox_override("panel", style)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	dialog.add_child(layout)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("334632"))
	layout.add_child(title)
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(content)
	var close := Button.new()
	close.text = "Return to garden"
	close.pressed.connect(_close)
	layout.add_child(close)
	dialog.hide()

func _open(id: String, button: Button) -> void:
	last_button = button
	if id == "garden_editor" and get_parent().has_method("open_ground_editor"):
		if dialog.visible: _close()
		destination_opened.emit(id)
		get_parent().open_ground_editor()
		return
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	title.text = TITLES[id]
	var screen: Control = load("res://features/%s/screen.tscn" % id).instantiate()
	screen.add_theme_color_override("font_color", Color("334632"))
	if id == "weather" and weather_provider != null: screen.configure(weather_provider)
	content.add_child(screen)
	# Give the forecast room for five readable rows; other destinations keep
	# their original compact dialog size.
	var half_width := 340.0 if id == "weather" else 230.0
	var half_height := 270.0 if id == "weather" else 150.0
	dialog.offset_left = -half_width
	dialog.offset_right = half_width
	dialog.offset_top = -half_height
	dialog.offset_bottom = half_height
	dialog.show()
	dialog.get_child(0).get_child(2).grab_focus()
	panel_visibility_changed.emit(true)
	destination_opened.emit(id)

func _close() -> void:
	dialog.hide()
	panel_visibility_changed.emit(false)
	if is_instance_valid(last_button):
		last_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if dialog.visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _update_weather() -> void:
	if weather_provider == null or weather_button == null: return
	var current: Dictionary = weather_provider.current_weather()
	weather_button.text = weather_provider.temperature(current.temperature_c)
	weather_button.tooltip_text = "%s · %s
Click for the next five days" % [current.condition,weather_provider.temperature(current.temperature_c)]
