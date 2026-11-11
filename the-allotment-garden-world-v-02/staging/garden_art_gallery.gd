extends Node3D
const Art := preload("res://assets/garden_art/garden_library.gd")
const Model := preload("res://features/market/item_model.tscn")
const Growth := preload("res://features/market/plant_growth.gd")
const COLLECTION := ["rose","sunflower","lavender","hydrangea","cosmos","daisy","basil","bench","rose_arch","fountain","lantern","trellis","planter","watering_can","straw_hat","tree","cypress","hedge","shrub","shed","greenhouse","stall","bed","central_planter","garden_gate","timber_gate","rock_wall","rock_wall_corner","rock_wall_end","chateau_gate","potager_gate","limestone_wall","fieldstone_wall","ivy_wall","stone_balustrade","anduze_jar","clay_bowl","glazed_olive_pot","stone_urn","stone_trough","carved_square_pot","stone_dove","botanical_medallion","garden_muse_bust","armillary_sphere","garden_sundial","vine_pergola","iron_pavilion","espalier_screen","wall_fountain","stone_alcove","roman_plinth","attic_column_base","plain_column_drum","fluted_column_drum","short_column_drum","doric_capital","ionic_capital","corinthian_capital","doric_column","ionic_column","corinthian_column","roman_architrave","stone_cornice","roman_pedestal","glow_mushrooms","fairy_mushroom_house","fairy_ring","crystal_cluster","moon_lantern","witch_cauldron","witch_hat_planter","spellbook_pedestal","crescent_moon_statue","fairy_door","enchanted_tree","star_mobile","rune_obelisk","lotus_lamp","firefly_jar","fairy_well","moon_arch","potion_shelf","branch_trellis","twig_obelisk","willow_basket_planter","willow_teepee_planter","rustic_arbor","branch_gate","branch_fence","wooden_clothes_airer","garden_chess_set","grass_stone_checkerboard","backyard_bowling_lane","formal_parterre","fairy_light_arbor"]
var specimen: Node3D
var camera: Camera3D
var heading: Label
var stats: Label
var orbit := .5
var pitch := .32
var distance := 3.5
var target := Vector3(0,.65,0)
var dragging := false
var selected := "rose"
var stage := 4
var asset_choice: OptionButton
var stage_choice: OptionButton
var gate_control: Button

func _ready() -> void:
	Art.Builder.set_night(0)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("bacac6")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("f4e9d4")
	environment.environment.ambient_light_energy = .65
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-30,0)
	sun.light_color = Color("ffe9c5")
	sun.light_energy = .8
	sun.shadow_enabled = true
	add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200,200)
	floor.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8f9a80")
	material.roughness = .95
	floor.material_override = material
	add_child(floor)
	camera = Camera3D.new()
	camera.fov = 42
	camera.near = .005
	camera.current = true
	add_child(camera)
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18,18)
	panel.custom_minimum_size.x = 285
	layer.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size",23)
	layout.add_child(heading)
	var choose := OptionButton.new()
	asset_choice = choose
	for id in COLLECTION:
		choose.add_item(id.replace("_"," ").capitalize())
		choose.set_item_metadata(choose.item_count-1,id)
	choose.item_selected.connect(func(index: int) -> void: selected = choose.get_item_metadata(index); show_asset(selected))
	layout.add_child(choose)
	var stages := OptionButton.new()
	stage_choice = stages
	for value in Growth.STAGES: stages.add_item(value)
	stages.select(4)
	stages.item_selected.connect(func(index: int) -> void: stage = index; show_asset(selected))
	layout.add_child(stages)
	stats = Label.new()
	layout.add_child(stats)
	var instruction := Label.new()
	instruction.text = "Right-drag: orbit · Wheel: zoom\nSource assets share metre scale."
	layout.add_child(instruction)
	var gate_button := Button.new()
	gate_control = gate_button
	gate_button.text = "Open / close gates"
	gate_button.pressed.connect(func() -> void:
		var controller := specimen.get_node_or_null("GateController")
		if controller: controller.set_open(not controller.opened))
	layout.add_child(gate_button)
	show_asset(selected)

func show_asset(id: String) -> void:
	selected = id
	if gate_control: gate_control.visible = id in ["garden_gate","timber_gate"] or Art.French.GATES.has(id) or Art.Rustic.GATES.has(id)
	if asset_choice:
		for index in range(asset_choice.item_count):
			if asset_choice.get_item_metadata(index) == id: asset_choice.select(index)
	if stage_choice: stage_choice.visible = Growth.PLANTS.has(id)
	if is_instance_valid(specimen):
		remove_child(specimen)
		specimen.queue_free()
	if Growth.PLANTS.has(id) or Art.SIZES.has(id) or Art.Boundary.SIZES.has(id) or Art.French.SIZES.has(id) or Art.Roman.SIZES.has(id) or Art.Enchanted.SIZES.has(id) or Art.Rustic.SIZES.has(id):
		specimen = Model.instantiate()
		specimen.item_id = id
		if Growth.PLANTS.has(id): specimen.growth_age_days = Growth.PLANTS[id].days[stage]
	else: specimen = Art.instance(id)
	add_child(specimen)
	var bounds := _bounds(specimen)
	target = bounds.get_center()
	var span := maxf(.2,maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z)))
	distance = span*2.05
	heading.text = id.replace("_"," ").capitalize()
	var triangles := 0
	for instance in specimen.find_children("NearDetail","MeshInstance3D",true,false):
		var mesh: ArrayMesh = instance.mesh
		for surface in range(mesh.get_surface_count()): triangles += mesh.surface_get_array_index_len(surface)/3
	stats.text = "%.2f m wide · %.2f m tall\n%d triangles near · 3 detail levels" % [bounds.size.x,bounds.size.y,triangles]
	_update_camera()

func _bounds(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in root.find_children("*","MeshInstance3D",true,false):
		var box: AABB = (root.global_transform.affine_inverse()*child.global_transform)*child.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func _update_camera() -> void:
	camera.position = target+Vector3(sin(orbit)*cos(pitch),sin(pitch),cos(orbit)*cos(pitch))*distance
	camera.look_at(target)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT: dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(.08,distance*.9)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance *= 1.1
	elif event is InputEventMouseMotion and dragging:
		orbit -= event.relative.x*.008
		pitch = clampf(pitch+event.relative.y*.006,.05,1.35)
	_update_camera()
