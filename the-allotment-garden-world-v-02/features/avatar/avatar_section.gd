extends Node3D
## Standalone appearance workshop. Intentionally absent from main navigation.
const Appearance := preload("res://features/avatar/appearance.gd")
var look := Appearance.defaults()
var character
var status: Label
var controls: Dictionary = {}
var syncing := false
var preview_walk := false
var turntable := false

func _ready() -> void:
	look = Appearance.load_saved()
	character = preload("res://assets/characters/gardener/gardener_visual.tscn").instantiate()
	character.name = "AvatarPreview"
	add_child(character)
	character.apply_appearance(look)
	_build_stage()
	_build_interface()

func _build_stage() -> void:
	# Keep this portrait rig separate from the shared neighborhood lighting.
	# The 1K CC0 sunrise panorama supplies broad, colored garden bounce;
	# the three direct lights gently shape the face rather than overexpose it.
	var environment := WorldEnvironment.new()
	environment.name = "PortraitEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = -1
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = preload("res://assets/third_party/poly_haven/spruit_sunrise/spruit_sunrise_1k.hdr")
	panorama.energy_multiplier = .6
	var sky := Sky.new()
	sky.sky_material = panorama
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = sky
	env.sky_rotation = Vector3(0,deg_to_rad(115),0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = .25
	env.ambient_light_sky_contribution = 1.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name = "PortraitWarmKey"
	sun.rotation_degrees = Vector3(-32,-50,0)
	sun.light_energy = .42
	sun.light_color = Color("ffe9cf")
	sun.shadow_enabled = true
	# Angular size is also useful if a later build uses Forward+ soft shadows.
	sun.light_angular_distance = 0.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 12.0
	sun.shadow_bias = .1
	sun.shadow_normal_bias = 1.5
	add_child(sun)
	# Low cool fill reaches beneath the straw brim without flattening the nose.
	var fill := DirectionalLight3D.new()
	fill.name = "PortraitCoolFill"
	fill.rotation_degrees = Vector3(-8,20,0)
	fill.light_energy = .14
	fill.light_color = Color("c9d7e5")
	add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.name = "PortraitSunsetRim"
	rim.rotation_degrees = Vector3(-26,145,0)
	rim.light_energy = .32
	rim.light_color = Color("ffd6ad")
	add_child(rim)
	var camera := Camera3D.new()
	camera.name = "PortraitCamera"
	camera.position = Vector3(1.1,1.42,3.4)
	camera.fov = 36
	add_child(camera)
	camera.look_at(Vector3(-.42,.94,0))
	camera.current = true
	var dais := MeshInstance3D.new()
	var stone := CylinderMesh.new()
	stone.top_radius = .68
	stone.bottom_radius = .72
	stone.height = .08
	stone.radial_segments = 64
	dais.mesh = stone
	dais.position.y = -.045
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("b0a991")
	material.roughness = .95
	dais.material_override = material
	add_child(dais)

func _label(text: String,size: int = 15) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 292
	label.add_theme_color_override("font_color",Color("334632"))
	label.add_theme_font_size_override("font_size",size)
	return label

func _build_interface() -> void:
	var backdrop = preload("res://ui/world_backdrop.tscn").instantiate()
	add_child(backdrop)
	# A subdued illustration keeps the portrait and ivory cloth readable.
	backdrop.get_node("Countryside").modulate = Color(.68,.66,.57,1.0)
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 16
	panel.offset_right = 360
	panel.offset_top = 16
	panel.offset_bottom = -16
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.98,.95,.88,.97)
	box.border_color = Color("bda06c")
	box.set_border_width_all(1)
	box.set_corner_radius_all(18)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel",box)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var body := VBoxContainer.new()
	body.custom_minimum_size.x = 292
	body.add_theme_constant_override("separation",10)
	scroll.add_child(body)
	body.add_child(_label("Your garden self",26))
	body.add_child(_label("A little romance, a little wildflower.\nAvatar workshop • main-menu access coming later.",14))
	var presets := OptionButton.new()
	for name in ["Rose garden", "Lavender morning", "Woodland wanderer"]: presets.add_item(name)
	presets.item_selected.connect(apply_preset)
	body.add_child(presets)
	_section(body,"HAIR & GARDEN CLOTHES")
	_choice(body,"Hair style","hair_style",["long","bob","braids","bun"],["Long soft waves","Wavy bob","Garden braids","Romantic bun"])
	_choice(body,"Outfit","outfit_style",["dress","trousers"],["Floral garden dress","Waistcoat & trousers"])
	for item in [["Hat","hat_enabled"],["Flowers on hat","flowers_enabled"],["Leather satchel","satchel_enabled"],["Gardening apron","apron_enabled"],["Freckles","freckles_enabled"]]:
		var toggle := CheckBox.new()
		toggle.text = item[0]
		toggle.button_pressed = look[item[1]]
		toggle.add_theme_color_override("font_color",Color("334632"))
		for state in ["font_pressed_color","font_hover_pressed_color","font_hover_color"]:
			toggle.add_theme_color_override(state,Color("334632"))
		toggle.toggled.connect(func(value: bool) -> void:
			if syncing: return
			look[item[1]] = value
			character.apply_appearance(look)
		)
		body.add_child(toggle)
		controls[item[1]] = toggle
	_section(body,"COLOR PALETTE")
	for item in [["Skin","skin_color"],["Hair","hair_color"],["Eyes","eye_color"],["Brows & lashes","brow_color"],["Lips","lip_color"],["Dress / waistcoat","outfit_color"],["Blouse / apron","blouse_color"],["Straw hat","hat_color"],["Ribbons","ribbon_color"],["Leather & boots","leather_color"],["Flower accents","flower_color"]]:
		var row := HBoxContainer.new()
		body.add_child(row)
		var label := _label(item[0])
		label.custom_minimum_size.x = 158
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var picker := ColorPickerButton.new()
		picker.custom_minimum_size = Vector2(100,32)
		picker.color = Color.html(look[item[1]])
		picker.edit_alpha = false
		picker.color_changed.connect(func(value: Color) -> void:
			if syncing: return
			look[item[1]] = value.to_html()
			character.apply_appearance(look)
		)
		row.add_child(picker)
		controls[item[1]] = picker
	_section(body,"BODY & FACE")
	for item in [["Height","height",.9,1.1],["Body proportions","body_build",.88,1.15],["Face width","face_width",0,1],["Face length","face_length",0,1],["Nose shape","nose_size",0,1],["Eye size","eye_size",0,1],["Eye spacing","eye_spacing",0,1]]:
		body.add_child(_label(item[0]))
		var slider := HSlider.new()
		slider.min_value = item[2]
		slider.max_value = item[3]
		slider.step = .01
		slider.value = look[item[1]]
		slider.value_changed.connect(func(value: float) -> void:
			if syncing: return
			look[item[1]] = value
			character.apply_appearance(look)
		)
		body.add_child(slider)
		controls[item[1]] = slider
	_section(body,"PREVIEW & SAVE")
	_button(body,"Turn around",func() -> void: turntable = not turntable)
	_button(body,"Idle / walking preview",func() -> void: preview_walk = not preview_walk; character.set_motion(preview_walk))
	_button(body,"Save and use this look",func() -> void: status.text = "Saved. Your character will wear this look next time you enter the garden." if Appearance.save(look) else "Could not save this appearance.")
	_button(body,"Restore original look",func() -> void: look = Appearance.defaults(); _sync())
	_button(body,"Enter the garden",func() -> void: get_tree().change_scene_to_file("res://main.tscn"))
	status = _label("These are the first appearance options. More face details, body types, hair and clothing can be added here.",13)
	body.add_child(status)

func _section(body: VBoxContainer,title: String) -> void:
	body.add_child(HSeparator.new())
	body.add_child(_label(title,13))

func _button(body: VBoxContainer,title: String,action: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 38
	button.pressed.connect(action)
	body.add_child(button)

func _choice(body: VBoxContainer,title: String,key: String,values: Array,labels: Array) -> void:
	body.add_child(_label(title))
	var choice := OptionButton.new()
	for label in labels: choice.add_item(label)
	choice.select(values.find(look[key]))
	choice.set_meta("values",values)
	choice.item_selected.connect(func(index: int) -> void:
		if syncing: return
		look[key] = values[index]
		character.apply_appearance(look)
	)
	body.add_child(choice)
	controls[key] = choice

func _sync() -> void:
	syncing = true
	for key in controls:
		var control = controls[key]
		if control is ColorPickerButton: control.color = Color.html(look[key])
		elif control is CheckBox: control.button_pressed = look[key]
		elif control is HSlider: control.value = look[key]
		elif control is OptionButton: control.select(control.get_meta("values").find(look[key]))
	syncing = false
	character.apply_appearance(look)

func apply_preset(index: int) -> void:
	look = Appearance.defaults()
	if index == 1:
		look.hair_style = "bob"
		look.hair_color = "442e29ff"
		look.brow_color = "442e29ff"
		look.skin_color = "ba8667ff"
		look.outfit_color = "a19ab8ff"
		look.ribbon_color = "cbb8c8ff"
		look.flower_color = "d8c4eaff"
	elif index == 2:
		look.hair_style = "braids"
		look.skin_color = "865a42ff"
		look.outfit_style = "trousers"
		look.hair_color = "352c26ff"
		look.brow_color = "352c26ff"
		look.outfit_color = "8b765cff"
		look.ribbon_color = "9d9b7cff"
		look.eye_color = "735b3fff"
		look.apron_enabled = true
	_sync()

func _process(delta: float) -> void:
	if turntable: character.rotation.y += delta*.4
