extends Control
const ART := preload("res://features/title/garden_title.png")
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
	_hotspot("Login",Rect2(946,523,386,105),_open_welcome)
	_hotspot("Create Account",Rect2(946,639,386,106),_open_welcome)
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
	(settings.get_node("Options/Volume") as HSlider).value = ambience.volume
	(settings.get_node("Options/Mute") as CheckBox).button_pressed = ambience.muted
	(settings.get_node("Options/Motion") as CheckBox).button_pressed = reduced_motion
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
	config.save("user://title_settings.cfg")
	queue_redraw()

func _open_welcome() -> void:
	settings.hide()
	var welcome := preload("res://features/onboarding/welcome.tscn").instantiate()
	add_child(welcome)
	welcome.show_step(1)
	var back := Button.new()
	back.text = "Back to title"
	back.position = Vector2(20,20)
	back.custom_minimum_size = Vector2(150,44)
	welcome.add_child(back)
	back.pressed.connect(func() -> void: welcome.queue_free())

func _process(delta: float) -> void:
	butterfly.visible = not reduced_motion
	if reduced_motion: return
	elapsed += delta
	butterfly.position = Vector2(922+sin(elapsed*.27)*78,85+sin(elapsed*.6)*22)
	var wing := 3.0+absf(sin(elapsed*8.5))*8.0
	left_wing.polygon = PackedVector2Array([Vector2.ZERO,Vector2(-wing,-9),Vector2(-wing,5)])
	right_wing.polygon = PackedVector2Array([Vector2.ZERO,Vector2(wing,-9),Vector2(wing,5)])
