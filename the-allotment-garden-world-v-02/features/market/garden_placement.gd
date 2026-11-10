extends Node
const Store := preload("res://features/market/market_store.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Model := preload("res://features/market/item_model.tscn")
const Terrain := preload("res://features/garden_editor/ground_cover/terrain_adapter.gd")
var world: Node3D
var garden: Node3D
var terrain
var store
var placed_root: Node3D
var ghost: Node3D
var active := false
var item_id := ""
var angle := 0.0
var candidate: Variant = null
var overlay: CanvasLayer
var hint: Label
var old_camera := {}

func configure(target_world: Node3D) -> void:
	world = target_world
	garden = world.get_node("Garden_01")
	terrain = Terrain.new()
	terrain.from_garden(garden)
	placed_root = Node3D.new()
	placed_root.name = "PurchasedItems"
	garden.add_child(placed_root)
	reload_items()

func reload_items() -> void:
	store = Store.new()
	for child in placed_root.get_children():
		placed_root.remove_child(child)
		child.queue_free()
	for placement in store.data.placed:
		var point := Vector2(placement.x,placement.z)
		var item := Catalog.by_id(placement.id)
		if not _terrain_allowed(item,point): continue
		var model := _model(placement.id)
		model.position = Vector3(point.x,terrain.sample_height(point),point.y)
		model.rotation.y = placement.angle
		placed_root.add_child(model)
		preload("res://features/avatar/world_collisions.gd").install(model)

func _model(id: String) -> Node3D:
	var model := Model.instantiate()
	model.item_id = id
	return model

func begin(id: String) -> bool:
	if active: finish()
	reload_items()
	if not Catalog.placeable(Catalog.by_id(id)) or store.count(id) <= 0: return false
	item_id = id
	angle = 0
	old_camera = {"focus":world.focus,"distance":world.distance,"pitch":world.pitch,"orbit":world.orbit,"walking":world.walking_mode}
	world.set_walking_mode(false)
	world.ui_panel_open = true
	world.focus = garden.to_global(Vector3(0,.1,46))
	world.distance = 33
	world.pitch = .95
	world.orbit = .2
	world._update_camera()
	world.get_node("GameHUD").hide()
	ghost = _model(id)
	garden.add_child(ghost)
	ghost.hide()
	for mesh in ghost.find_children("*","MeshInstance3D",true,false):
		if mesh.material_override is StandardMaterial3D:
			mesh.material_override = mesh.material_override.duplicate()
			mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.material_override.albedo_color.a = .5
	active = true
	_build_overlay()
	return true

func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 10
	add_child(overlay)
	var panel := PanelContainer.new()
	overlay.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -100
	var column := VBoxContainer.new()
	panel.add_child(column)
	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	for action in [["Rotate · R",func() -> void: angle += PI/4],["Done · Esc",finish]]:
		var button := Button.new()
		button.text = action[0]
		button.custom_minimum_size = Vector2(160,44)
		button.pressed.connect(action[1])
		row.add_child(button)

func _terrain_allowed(item: Dictionary, point: Vector2) -> bool:
	if not Catalog.placeable(item) or not terrain.contains(point): return false
	var radius := float(item.radius)+.2
	for i in range(8):
		var a := float(i)*TAU/8
		if not terrain.contains(point+Vector2(cos(a),sin(a))*radius): return false
	return true

func allowed(id: String, point: Vector2) -> bool:
	var item := Catalog.by_id(id)
	if not _terrain_allowed(item,point): return false
	for placement in store.data.placed:
		var other := Catalog.by_id(placement.id)
		if point.distance_to(Vector2(placement.x,placement.z)) < float(item.radius)+float(other.radius)+.15: return false
	return true

func place_at(point: Vector2) -> bool:
	if not active or not allowed(item_id,point): return false
	if not store.place(item_id,point,angle): return false
	var model := _model(item_id)
	model.position = Vector3(point.x,terrain.sample_height(point),point.y)
	model.rotation.y = angle
	placed_root.add_child(model)
	preload("res://features/avatar/world_collisions.gd").install(model)
	if store.count(item_id) == 0: finish()
	return true

func _process(delta: float) -> void:
	if not active: return
	var move := Vector3(float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A)),0,float(Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_W)))
	world.focus += move.limit_length(1.0).rotated(Vector3.UP,world.orbit)*delta*world.distance*.5
	world._update_camera()
	candidate = terrain.pick(world.camera,get_viewport().get_mouse_position())
	ghost.visible = candidate != null
	var valid := candidate != null and allowed(item_id,candidate)
	if candidate != null:
		ghost.position = Vector3(candidate.x,terrain.sample_height(candidate),candidate.y)
		ghost.rotation.y = angle
	hint.text = "%s · %d in backpack · %s\nWASD: pan · Wheel: zoom" % [Catalog.by_id(item_id).name,store.count(item_id),"Click to place in Garden 01" if valid else "Choose open space inside Garden 01"]

func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE: finish()
		elif event.keycode == KEY_R: angle += PI/4
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if candidate != null: place_at(candidate)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		world.distance = clampf(world.distance+(-3 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 3),8,130)
		get_viewport().set_input_as_handled()

func finish() -> void:
	if not active: return
	active = false
	ghost.queue_free()
	overlay.queue_free()
	world.ui_panel_open = false
	world.get_node("GameHUD").show()
	world.set_walking_mode(old_camera.walking)
	world.focus = old_camera.focus
	world.distance = old_camera.distance
	world.pitch = old_camera.pitch
	world.orbit = old_camera.orbit
	world._update_camera()
