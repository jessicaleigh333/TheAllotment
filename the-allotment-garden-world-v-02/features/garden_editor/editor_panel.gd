extends Control
## Scrollable visual catalog and appearance controls for the live landscaping session.
signal close_requested
signal style_changed(style: Dictionary)
signal tool_changed(tool: String)
signal action_requested(action: String)
signal night_changed(amount: float)
const Preview := preload("res://features/garden_editor/ground_cover/material_preview.gd")
const Favorites := preload("res://features/garden_editor/ground_cover/favorites.gd")
const TOOLS := ["paint", "line", "curve", "circle", "rectangle", "erase", "recolor", "sample"]
const BORDER_IDS := ["none", "brick", "granite", "cobblestone", "basic_tile", "wooden_boardwalk", "metal_edging", "glowing_pebbles", "illuminated_mosaic_tiles"]
const PALETTE := ["f2e5ca", "ece9dc", "333d3c", "9d7255", "aa6754", "598053", "478caa", "51c6bb", "9c79c7", "e9afc8", "d9b45b", "ffffff"]
var catalog
var favorites
var style: Dictionary = {}
var brush_size := 3.0
var pathway_width := 3.0
var border_id := "none"
var border_width := 0.5
var border_color := Color("d8c8a5")
var border_glow_color := Color("6edbff")
var border_glow := false
var border_toggle: CheckBox
var border_intensity := 2.0
var current_tool := "paint"
var updating := false
var selected_component := "base"
var sidebar: PanelContainer
var scroll: ScrollContainer
var catalog_grid: GridContainer
var category: OptionButton
var search: LineEdit
var color_picker: ColorPicker
var component: OptionButton
var selected_title: Label
var live_preview
var status: Label
var tool_buttons: Dictionary = {}
var sliders: Dictionary = {}
var glow_toggle: CheckBox
var glow_scope: OptionButton
var glow_palette: OptionButton
var detail_type: OptionButton
var favorite_styles: OptionButton
var favorite_color_select: OptionButton
var favorite_colors: HBoxContainer
var preview_nodes: Array = []
var night_slider: HSlider

func setup(material_catalog) -> void:
	catalog = material_catalog
	favorites = Favorites.new(catalog)
	style = catalog.default_style("cobblestone")
	_build()
	select_style(style)

func _theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 14
	for type in ["Label", "Button", "OptionButton", "CheckBox", "LineEdit", "SpinBox"]:
		theme.set_color("font_color", type, Color("334632"))
		theme.set_color("font_hover_color", type, Color("263623"))
		theme.set_color("font_pressed_color", type, Color("263623"))
		theme.set_color("font_focus_color", type, Color("263623"))
	for type in ["Button", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "focus"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color("e3dcc6") if state == "normal" else Color("b7c79d")
			box.set_corner_radius_all(6)
			box.content_margin_left = 8
			box.content_margin_right = 8
			box.content_margin_top = 7
			box.content_margin_bottom = 7
			theme.set_stylebox(state, type, box)
	var field := StyleBoxFlat.new()
	field.bg_color = Color("fff8e8")
	field.set_corner_radius_all(5)
	field.content_margin_left = 8
	field.content_margin_top = 6
	field.content_margin_bottom = 6
	theme.set_stylebox("normal", "LineEdit", field)
	theme.set_color("font_placeholder_color", "LineEdit", Color("74816a"))
	return theme

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = _theme()
	var top := PanelContainer.new()
	add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_right = -12
	top.offset_top = 10
	var top_box := StyleBoxFlat.new()
	top_box.bg_color = Color("f1e7cd")
	top_box.set_corner_radius_all(8)
	top_box.content_margin_left = 10
	top_box.content_margin_right = 10
	top_box.content_margin_top = 5
	top_box.content_margin_bottom = 5
	top.add_theme_stylebox_override("panel", top_box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	top.add_child(header)
	var heading := Label.new()
	heading.text = "GARDEN EDITOR  •  Ground covers & paths"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	for item in [["Undo", "undo"], ["Redo", "redo"], ["Save", "save"], ["Load", "load"], ["Demo area", "demo"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(func() -> void: action_requested.emit(item[1]))
		header.add_child(button)
	var close := Button.new()
	close.text = "Return to garden"
	close.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close)
	sidebar = PanelContainer.new()
	add_child(sidebar)
	sidebar.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	sidebar.offset_left = 12
	sidebar.offset_right = 358
	sidebar.offset_top = 62
	sidebar.offset_bottom = -56
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(0.96, 0.93, 0.84, 0.98)
	paper.border_color = Color("b69c65")
	paper.set_border_width_all(1)
	paper.set_corner_radius_all(14)
	paper.content_margin_left = 12
	paper.content_margin_right = 12
	paper.content_margin_top = 12
	paper.content_margin_bottom = 12
	sidebar.add_theme_stylebox_override("panel", paper)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(scroll)
	var body := VBoxContainer.new()
	body.custom_minimum_size.x = 304
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	var tools := GridContainer.new()
	tools.columns = 4
	body.add_child(tools)
	for id in TOOLS:
		var button := Button.new()
		button.text = id.capitalize()
		button.toggle_mode = true
		button.tooltip_text = {"paint": "Drag to paint ground cover", "line": "Click start and end for a straight pathway", "curve": "Click control points, then Enter or Finish curve", "circle": "Click center and edge", "rectangle": "Click opposite corners", "erase": "Drag to remove surfaces", "recolor": "Drag to recolor existing surfaces", "sample": "Click a surface to copy its appearance"}[id]
		button.pressed.connect(_select_tool.bind(id))
		tools.add_child(button)
		tool_buttons[id] = button
	_select_tool("paint")
	_add_slider(body, "Brush diameter (m)", "brush", 0.5, 12, 0.5, brush_size)
	_add_slider(body, "Path width (m)", "width", 0.5, 12, 0.5, pathway_width)
	var finish := Button.new()
	finish.text = "Finish curve  ↵"
	finish.pressed.connect(func() -> void: action_requested.emit("finish_curve"))
	body.add_child(finish)
	_section(body, "MATERIAL CATALOG")
	search = LineEdit.new()
	search.placeholder_text = "Search 83 surfaces…"
	search.text_changed.connect(func(_value: String) -> void: _refresh_catalog())
	body.add_child(search)
	category = OptionButton.new()
	category.add_item("Starter collection")
	for group in catalog.categories: category.add_item(group)
	category.item_selected.connect(func(_index: int) -> void: _refresh_catalog())
	body.add_child(category)
	catalog_grid = GridContainer.new()
	catalog_grid.columns = 3
	catalog_grid.add_theme_constant_override("h_separation", 4)
	catalog_grid.add_theme_constant_override("v_separation", 6)
	body.add_child(catalog_grid)
	selected_title = Label.new()
	selected_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_title.custom_minimum_size.x = 280
	body.add_child(selected_title)
	live_preview = Preview.new()
	body.add_child(live_preview)
	live_preview.setup(catalog, style, Vector2i(280, 152))
	_section(body, "COLORS & FINISH")
	component = OptionButton.new()
	for name in ["Surface / daytime", "Grout / mortar", "Pattern / accent", "Glow primary", "Glow secondary"]: component.add_item(name)
	component.item_selected.connect(func(index: int) -> void:
		selected_component = ["base", "joint", "accent", "glow_color", "glow_secondary"][index]
		updating = true
		color_picker.color = Color.html(style[selected_component])
		updating = false
	)
	body.add_child(component)
	color_picker = ColorPicker.new()
	color_picker.picker_shape = ColorPicker.SHAPE_OKHSL_CIRCLE
	color_picker.color_modes_visible = false
	color_picker.sliders_visible = false
	color_picker.hex_visible = true
	color_picker.presets_visible = false
	color_picker.edit_alpha = false
	color_picker.custom_minimum_size = Vector2(280, 210)
	color_picker.color_changed.connect(func(color: Color) -> void:
		if updating: return
		style[selected_component] = color.to_html()
		_notify_style()
	)
	body.add_child(color_picker)
	var palette := GridContainer.new()
	palette.columns = 6
	body.add_child(palette)
	for hex in PALETTE:
		var button := _swatch(Color(hex))
		button.pressed.connect(func() -> void: color_picker.color = Color(hex); _choose_color(Color(hex)))
		palette.add_child(button)
	favorite_colors = HBoxContainer.new()
	body.add_child(favorite_colors)
	favorite_color_select = OptionButton.new()
	favorite_color_select.item_selected.connect(func(index: int) -> void:
		if index > 0:
			color_picker.color = Color.html(favorites.colors[index - 1])
			_choose_color(color_picker.color)
	)
	body.add_child(favorite_color_select)
	var save_color := Button.new()
	save_color.text = "★ Save this color"
	save_color.pressed.connect(func() -> void:
		set_status("Favorite color saved." if favorites.save_color(color_picker.color) else "Favorite color could not be saved.")
		_refresh_favorites()
	)
	body.add_child(save_color)
	_add_slider(body, "Brightness", "brightness", 0.1, 2, 0.05, 1)
	_add_slider(body, "Saturation", "saturation", 0, 2, 0.05, 1)
	_add_slider(body, "Finish: polished → matte", "roughness", 0.05, 1, 0.05, 0.85)
	_add_slider(body, "Pattern size (m)", "scale", 0.08, 4, 0.02, 0.7)
	_add_slider(body, "Pattern rotation (°)", "rotation", 0, 360, 5, 0)
	var reset := Button.new()
	reset.text = "Restore material defaults"
	reset.pressed.connect(func() -> void: select_style(catalog.default_style(style.material_id)))
	body.add_child(reset)
	_section(body, "LUMINOUS DETAILS")
	glow_toggle = CheckBox.new()
	glow_toggle.text = "Enable glow"
	glow_toggle.toggled.connect(func(enabled: bool) -> void:
		if updating: return
		style.glow_enabled = enabled
		_notify_style()
	)
	body.add_child(glow_toggle)
	_add_slider(body, "Glow intensity", "glow_intensity", 0, 8, 0.1, 2)
	glow_scope = OptionButton.new()
	for value in ["Selected details", "Entire surface", "Soft edges", "Grout lines", "Embedded patterns", "Scattered stones"]: glow_scope.add_item(value)
	glow_scope.item_selected.connect(func(index: int) -> void:
		style.glow_mode = index
		_notify_style()
	)
	body.add_child(glow_scope)
	glow_palette = OptionButton.new()
	for value in ["Single glow color", "Mix primary + secondary", "Rainbow"]: glow_palette.add_item(value)
	glow_palette.item_selected.connect(func(index: int) -> void:
		style.glow_palette = index
		_notify_style()
	)
	body.add_child(glow_palette)
	var glow_presets := OptionButton.new()
	for value in ["Glow presets…", "Blue", "Turquoise", "Green", "Purple", "Pink", "Gold", "White", "Rainbow"]: glow_presets.add_item(value)
	glow_presets.item_selected.connect(func(index: int) -> void:
		if index == 0: return
		style.glow_enabled = true
		style.glow_palette = 2 if index == 8 else 0
		if index < 8: style.glow_color = ["64b6ffff", "51dbcfff", "78e581ff", "ae83ffff", "ffacdfff", "ffdb80ff", "ffffffff"][index - 1]
		select_style(style)
	)
	body.add_child(glow_presets)
	_section(body, "LAYERED MATERIAL DETAILS")
	detail_type = OptionButton.new()
	for value in ["None", "Moss-filled joints", "Luminous pebbles", "Ornate inlay"]: detail_type.add_item(value)
	detail_type.item_selected.connect(func(index: int) -> void:
		style.detail_id = ["none", "moss", "glowing_pebbles", "ornate_tile"][index]
		_notify_style()
	)
	body.add_child(detail_type)
	_add_slider(body, "Detail coverage", "detail_amount", 0, 1, 0.05, 0)
	_section(body, "BORDERS & EDGING")
	var edging := OptionButton.new()
	for value in ["No edging", "Brick", "Stone", "Cobblestone", "Decorative tile", "Timber", "Metal garden edging", "Glowing stone", "Illuminated mosaic"]: edging.add_item(value)
	edging.item_selected.connect(func(index: int) -> void:
		border_id = BORDER_IDS[index]
		border_glow = catalog.by_id[border_id].luminous if catalog.by_id.has(border_id) else false
		border_toggle.set_pressed_no_signal(border_glow)
	)
	body.add_child(edging)
	_add_slider(body, "Border width (m)", "border_width", 0.5, 3, 0.5, 0.5)
	var border_color_button := ColorPickerButton.new()
	border_color_button.text = "Border daytime color"
	border_color_button.color = border_color
	border_color_button.color_changed.connect(func(value: Color) -> void: border_color = value)
	body.add_child(border_color_button)
	var border_glow_button := ColorPickerButton.new()
	border_glow_button.text = "Border glow color"
	border_glow_button.color = border_glow_color
	border_glow_button.color_changed.connect(func(value: Color) -> void: border_glow_color = value)
	body.add_child(border_glow_button)
	border_toggle = CheckBox.new()
	border_toggle.text = "Enable border glow"
	border_toggle.toggled.connect(func(enabled: bool) -> void: border_glow = enabled)
	body.add_child(border_toggle)
	_add_slider(body, "Border glow intensity", "border_intensity", 0, 8, 0.1, 2)
	_section(body, "FAVORITE COMBINATIONS")
	favorite_styles = OptionButton.new()
	favorite_styles.item_selected.connect(func(index: int) -> void:
		if index > 0: select_style(favorites.combinations[index - 1].style)
	)
	body.add_child(favorite_styles)
	var save_style := Button.new()
	save_style.text = "★ Save material + colors"
	save_style.pressed.connect(func() -> void:
		set_status("Combination saved." if favorites.save_combination(style) else "Favorite could not be saved.")
		_refresh_favorites()
	)
	body.add_child(save_style)
	_section(body, "DAY / NIGHT PREVIEW")
	_add_slider(body, "Daylight → moonlight", "night", 0, 1, 0.05, 0)
	night_slider = sliders.night
	status = Label.new()
	add_child(status)
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status.offset_left = 20
	status.offset_right = -20
	status.offset_top = -44
	status.offset_bottom = -10
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_color_override("font_color", Color("fff4db"))
	status.add_theme_color_override("font_shadow_color", Color("24372a"))
	status.add_theme_constant_override("shadow_offset_x", 1)
	status.add_theme_constant_override("shadow_offset_y", 2)
	_refresh_catalog()
	_refresh_favorites()

func _section(body: VBoxContainer, text: String) -> void:
	body.add_child(HSeparator.new())
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	body.add_child(label)

func _add_slider(body: VBoxContainer, text: String, key: String, low: float, high: float, step: float, value: float) -> void:
	var label := Label.new()
	label.text = text + "  " + str(snappedf(value, step))
	body.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	body.add_child(slider)
	sliders[key] = slider
	slider.value_changed.connect(func(number: float) -> void:
		label.text = text + "  " + str(snappedf(number, step))
		if updating: return
		match key:
			"brush": brush_size = number
			"width": pathway_width = number
			"border_width": border_width = number
			"border_intensity": border_intensity = number
			"night": night_changed.emit(number); refresh_previews()
			_: style[key] = number; _notify_style()
	)

func _swatch(color: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(40, 25)
	button.tooltip_text = "#" + color.to_html(false).to_upper()
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.border_color = Color("65745a")
		box.set_border_width_all(1)
		box.set_corner_radius_all(5)
		button.add_theme_stylebox_override(state, box)
	return button

func _choose_color(color: Color) -> void:
	style[selected_component] = color.to_html()
	_notify_style()

func _refresh_catalog() -> void:
	for child in catalog_grid.get_children():
		catalog_grid.remove_child(child)
		child.queue_free()
	preview_nodes.clear()
	var starter := ["cobblestone", "brick", "moss", "gravel", "basic_tile", "ornate_tile", "glowing_pebbles", "glowing_stepping_stones"]
	var needle := search.text.to_lower()
	for item in catalog.entries:
		if not needle.is_empty():
			if not item.display_name.to_lower().contains(needle): continue
		elif category.selected == 0:
			if not starter.has(item.material_id): continue
		elif item.category != catalog.categories[category.selected - 1]: continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(96, 108)
		button.tooltip_text = item.display_name
		button.pressed.connect(func() -> void: select_style(catalog.default_style(item.material_id)))
		catalog_grid.add_child(button)
		var layout := VBoxContainer.new()
		layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(layout)
		layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var preview := Preview.new()
		layout.add_child(preview)
		preview.setup(catalog, catalog.default_style(item.material_id), Vector2i(92, 74))
		preview_nodes.append(preview)
		var label := Label.new()
		label.text = item.display_name
		label.custom_minimum_size.x = 92
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 11)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layout.add_child(label)

func _refresh_favorites() -> void:
	favorite_styles.clear()
	favorite_styles.add_item("Choose a saved combination")
	for item in favorites.combinations: favorite_styles.add_item(item.name)
	for child in favorite_colors.get_children():
		favorite_colors.remove_child(child)
		child.queue_free()
	# Every saved color is selectable; recent swatches also fit the sidebar.
	favorite_color_select.clear()
	favorite_color_select.add_item("Choose a favorite color")
	for hex in favorites.colors: favorite_color_select.add_item("#" + hex.left(6).to_upper())
	for hex in favorites.colors.slice(maxi(0, favorites.colors.size() - 7)):
		var button := _swatch(Color.html(hex))
		button.pressed.connect(func() -> void: color_picker.color = Color.html(hex); _choose_color(Color.html(hex)))
		favorite_colors.add_child(button)

func _select_tool(id: String) -> void:
	current_tool = id
	for key in tool_buttons: tool_buttons[key].set_pressed_no_signal(key == id)
	tool_changed.emit(id)

func select_style(value: Dictionary) -> void:
	var normalized: Dictionary = catalog.validate_style(value)
	if normalized.is_empty(): return
	style = normalized
	updating = true
	selected_title.text = catalog.by_id[style.material_id].display_name
	color_picker.color = Color.html(style[selected_component])
	for key in ["scale", "rotation", "brightness", "saturation", "roughness", "glow_intensity", "detail_amount"]: sliders[key].value = style[key]
	glow_toggle.button_pressed = style.glow_enabled
	glow_scope.select(style.glow_mode)
	glow_palette.select(style.glow_palette)
	detail_type.select(["none", "moss", "glowing_pebbles", "ornate_tile"].find(style.detail_id))
	updating = false
	_notify_style()

func _notify_style() -> void:
	style = catalog.validate_style(style)
	live_preview.set_style(style)
	style_changed.emit(style.duplicate(true))

func border_settings() -> Dictionary:
	if border_id == "none": return {}
	var border: Dictionary = catalog.default_style(border_id)
	border.base = border_color.to_html()
	border.glow_color = border_glow_color.to_html()
	border.glow_enabled = border_glow
	border.glow_intensity = border_intensity
	border.glow_mode = 1
	return {"style": catalog.validate_style(border), "width": border_width}

func refresh_previews() -> void:
	live_preview.refresh()
	for preview in preview_nodes: preview.refresh()

func set_status(value: String) -> void:
	status.text = value
