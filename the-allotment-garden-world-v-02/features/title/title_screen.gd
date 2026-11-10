extends Control
const ART := preload("res://features/title/garden_title.png")
const PROFILES := preload("res://features/profiles/local_profiles.gd")
const CALENDAR := preload("res://features/title/title_calendar.gd")
const SEASON_ART := [ART,preload("res://features/title/summer.png"),preload("res://features/title/autumn.png"),preload("res://features/title/winter.png")]
const AMBIENCE := preload("res://features/title/garden_ambience.gd")
var canvas: Control
var picture: TextureRect
var ambience: Node
var settings: PanelContainer
var reduced_motion := false
var elapsed := 0.0
var butterfly: Node2D
var left_wing: Polygon2D
var right_wing: Polygon2D
var season_override := -1
var time_override := -1
var southern := false
var current_season := -1
var current_night := 0.0
var calendar_timer := 0.0
var profile_panel: PanelContainer
var profile_store = PROFILES.new()

func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("172219")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	canvas = Control.new()
	canvas.size = Vector2(1536,1024)
	add_child(canvas)
	picture = TextureRect.new()
	picture.texture = ART
	picture.size = canvas.size
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://features/title/garden_title.gdshader")
	picture.material = material
	canvas.add_child(picture)
	butterfly = Node2D.new()
	canvas.add_child(butterfly)
	left_wing = Polygon2D.new()
	left_wing.color = Color("ecb357")
	butterfly.add_child(left_wing)
	right_wing = Polygon2D.new()
	right_wing.color = Color("e29835")
	butterfly.add_child(right_wing)
	var body := Line2D.new()
	body.points = PackedVector2Array([Vector2(0,-5),Vector2(0,5)])
	body.width = 2
	body.default_color = Color("45351e")
	butterfly.add_child(body)
	_hotspot("Login",Rect2(946,523,386,105),_open_profiles.bind(false))
	_hotspot("Create Account",Rect2(946,639,386,106),_open_profiles.bind(true))
	_hotspot("Settings",Rect2(1406,29,103,104),func() -> void: settings.visible = not settings.visible)
	ambience = AMBIENCE.new()
	add_child(ambience)
	_build_settings()
	resized.connect(_fit)
	_fit()
	var config := ConfigFile.new()
	if config.load("user://title_settings.cfg") == OK:
		ambience.volume = clampf(float(config.get_value("title","volume",.55)),0,1)
		ambience.muted = bool(config.get_value("title","muted",false))
		reduced_motion = bool(config.get_value("title","reduced_motion",false))
		season_override = clampi(int(config.get_value("title","season",-1)),-1,3)
		time_override = clampi(int(config.get_value("title","time",-1)),-1,1)
		southern = bool(config.get_value("title","southern",false))
	(settings.get_node("Options/Volume") as HSlider).set_value_no_signal(ambience.volume)
	(settings.get_node("Options/Mute") as CheckBox).set_pressed_no_signal(ambience.muted)
	(settings.get_node("Options/Motion") as CheckBox).set_pressed_no_signal(reduced_motion)
	(settings.get_node("Options/Season") as OptionButton).select(season_override+1)
	(settings.get_node("Options/Time") as OptionButton).select(time_override+1)
	(settings.get_node("Options/Hemisphere") as OptionButton).select(1 if southern else 0)
	_apply_settings()

func _hotspot(label: String, rect: Rect2, action: Callable) -> void:
	var button := Button.new()
	button.name = label.replace(" ","")
	button.position = rect.position
	button.size = rect.size
	button.tooltip_text = label
	button.accessibility_name = label
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	for state in ["hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1,.9,.6,.10 if state != "pressed" else .22)
		style.border_color = Color("ffe6a2")
		style.set_border_width_all(2)
		style.set_corner_radius_all(36)
		button.add_theme_stylebox_override(state,style)
	button.pressed.connect(action)
	canvas.add_child(button)

func _fit() -> void:
	if canvas == null: return
	var ratio := minf(size.x/1536.0,size.y/1024.0)
	canvas.scale = Vector2.ONE*ratio
	canvas.position = (size-canvas.size*ratio)/2

func _build_settings() -> void:
	settings = PanelContainer.new()
	settings.position = Vector2(1030,150)
	settings.custom_minimum_size = Vector2(450,270)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f2e5ca")
	style.border_color = Color("b79250")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	settings.add_theme_stylebox_override("panel",style)
	canvas.add_child(settings)
	var options := VBoxContainer.new()
	options.name = "Options"
	settings.add_child(options)
	var label := Label.new()
	label.text = "Garden sounds"
	label.add_theme_color_override("font_color",Color("334632"))
	options.add_child(label)
	var slider := HSlider.new()
	slider.name = "Volume"
	slider.max_value = 1
	slider.step = .01
	slider.value = .55
	slider.custom_minimum_size.y = 44
	slider.accessibility_name = "Garden sound volume"
	slider.value_changed.connect(func(value: float) -> void: ambience.volume = value; _apply_settings())
	options.add_child(slider)
	for item in [["Mute","Mute sounds"],["Motion","Reduce motion"]]:
		var check := CheckBox.new()
		check.name = item[0]
		check.text = item[1]
		check.custom_minimum_size.y = 46
		check.add_theme_color_override("font_color",Color("334632"))
		options.add_child(check)
	(settings.get_node("Options/Mute") as CheckBox).toggled.connect(func(value: bool) -> void: ambience.muted = value; _apply_settings())
	(settings.get_node("Options/Motion") as CheckBox).toggled.connect(func(value: bool) -> void: reduced_motion = value; _apply_settings())
	for entry in [["Season",["Season: automatic","Spring","Summer","Autumn","Winter"]],["Time",["Time: automatic","Day","Night"]],["Hemisphere",["Northern Hemisphere","Southern Hemisphere"]]]:
		var choice := OptionButton.new()
		choice.name = entry[0]
		choice.custom_minimum_size.y = 44
		for text in entry[1]: choice.add_item(text)
		options.add_child(choice)
		choice.item_selected.connect(_choose_calendar.bind(str(entry[0])))
	var close := Button.new()
	close.text = "Done"
	close.pressed.connect(func() -> void: settings.hide())
	options.add_child(close)
	settings.hide()

func _apply_settings() -> void:
	ambience.apply_volume()
	(picture.material as ShaderMaterial).set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
	var config := ConfigFile.new()
	config.set_value("title","volume",ambience.volume)
	config.set_value("title","muted",ambience.muted)
	config.set_value("title","reduced_motion",reduced_motion)
	config.set_value("title","season",season_override)
	config.set_value("title","time",time_override)
	config.set_value("title","southern",southern)
	config.save("user://title_settings.cfg")
	_refresh_calendar()
	queue_redraw()

func _choose_calendar(index: int, field: String) -> void:
	match field:
		"Season": season_override = index-1
		"Time": time_override = index-1
		"Hemisphere": southern = index == 1
	_apply_settings()

func _refresh_calendar(date: Dictionary = {}) -> void:
	if date.is_empty(): date = Time.get_datetime_dict_from_system(false)
	var season: int = season_override if season_override >= 0 else CALENDAR.season_for_month(int(date.month),southern)
	current_night = float(time_override) if time_override >= 0 else CALENDAR.night_for_hour(float(date.hour)+float(date.minute)/60.0)
	if season != current_season:
		current_season = season
		picture.texture = SEASON_ART[season]
	(picture.material as ShaderMaterial).set_shader_parameter("night",current_night)
	(picture.material as ShaderMaterial).set_shader_parameter("season",season)
	ambience.set_season(season,current_night)

func _open_profiles(create_new: bool) -> void:
	settings.hide()
	if is_instance_valid(profile_panel):
		canvas.remove_child(profile_panel)
		profile_panel.queue_free()
	profile_panel = PanelContainer.new()
	profile_panel.name = "LocalProfiles"
	profile_panel.position = Vector2(470,250)
	profile_panel.custom_minimum_size.x = 600
	var parchment := StyleBoxFlat.new()
	parchment.bg_color = Color("f2e5ca")
	parchment.border_color = Color("b79250")
	parchment.set_border_width_all(3)
	parchment.set_corner_radius_all(22)
	parchment.content_margin_left = 28
	parchment.content_margin_right = 28
	parchment.content_margin_top = 24
	parchment.content_margin_bottom = 24
	profile_panel.add_theme_stylebox_override("panel",parchment)
	canvas.add_child(profile_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	profile_panel.add_child(column)
	var heading := Label.new()
	heading.text = "Create your garden profile" if create_new else "Welcome back"
	heading.add_theme_font_size_override("font_size",28)
	heading.add_theme_color_override("font_color",Color("334632"))
	column.add_child(heading)
	var note := Label.new()
	note.text = "Saved on this device"
	note.add_theme_color_override("font_color",Color("334632"))
	column.add_child(note)
	var feedback := Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.x = 530
	feedback.add_theme_color_override("font_color",Color("9a493d"))
	var start := Button.new()
	start.text = "Enter garden"
	start.custom_minimum_size.y = 52
	if create_new:
		var name_field := LineEdit.new()
		name_field.name = "ProfileName"
		name_field.placeholder_text = "Your profile name"
		name_field.max_length = 24
		name_field.custom_minimum_size.y = 52
		column.add_child(name_field)
		var create := func() -> void:
			var id: String = profile_store.create(name_field.text)
			if id.is_empty(): feedback.text = profile_store.last_error
			else: _enter_garden()
		start.pressed.connect(create)
		name_field.text_submitted.connect(func(_text: String) -> void: create.call())
		name_field.grab_focus()
	else:
		var select := OptionButton.new()
		select.name = "SavedProfiles"
		select.custom_minimum_size.y = 52
		column.add_child(select)
		var data: Dictionary = profile_store.read()
		if data.is_empty():
			feedback.text = "The saved profile list could not be read. Your files have been kept."
			start.disabled = true
		else:
			for profile in data.profiles:
				select.add_item(profile.name)
				select.set_item_metadata(select.item_count-1,profile.id)
				if profile.id == data.active: select.select(select.item_count-1)
			if data.profiles.is_empty():
				feedback.text = "Create a profile to begin your garden story."
				start.disabled = true
		start.pressed.connect(func() -> void:
			if select.selected < 0: return
			if profile_store.activate(str(select.get_selected_metadata())): _enter_garden()
			else: feedback.text = profile_store.last_error
		)
	column.add_child(feedback)
	column.add_child(start)
	var switch_mode := Button.new()
	switch_mode.text = "Choose a saved profile" if create_new else "Create a new profile"
	switch_mode.custom_minimum_size.y = 48
	switch_mode.pressed.connect(_open_profiles.bind(not create_new))
	column.add_child(switch_mode)
	var back := Button.new()
	back.text = "Back to title"
	back.custom_minimum_size.y = 48
	back.pressed.connect(func() -> void: profile_panel.queue_free())
	column.add_child(back)

func _enter_garden() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _process(delta: float) -> void:
	calendar_timer += delta
	if calendar_timer >= 30:
		calendar_timer = 0
		_refresh_calendar()
	butterfly.visible = not reduced_motion and current_night < .5 and current_season != 3
	if reduced_motion: return
	elapsed += delta
	butterfly.position = Vector2(922+sin(elapsed*.27)*78,85+sin(elapsed*.6)*22)
	var wing := 3.0+absf(sin(elapsed*8.5))*8.0
	left_wing.polygon = PackedVector2Array([Vector2.ZERO,Vector2(-wing,-9),Vector2(-wing,5)])
	right_wing.polygon = PackedVector2Array([Vector2.ZERO,Vector2(wing,-9),Vector2(wing,5)])
