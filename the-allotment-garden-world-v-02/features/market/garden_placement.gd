extends Node
const Growth := preload("res://features/market/plant_growth.gd")
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
var area := "courtyard"
var areas := {}
var terrains := {}
var roots := {}
var ghost_materials: Array[StandardMaterial3D] = []
var ghost_valid := false
var growth_timer := 0.0

func configure(target_world: Node3D) -> void:
	world = target_world
	areas = {"garden":world.get_node("Garden_01"),"courtyard":world.get_node("CircularCourtyard")}
	var garden_terrain := Terrain.new()
	garden_terrain.from_garden(areas.garden)
	terrains = {"garden":garden_terrain,"courtyard":preload("res://features/market/courtyard_terrain.gd").new(areas.courtyard)}
	for scope in areas:
		var root := Node3D.new()
		root.name = "PurchasedItems"
		areas[scope].add_child(root)
		roots[scope] = root
	_select_area("courtyard")
	reload_items()

func _select_area(scope: String) -> void:
	area = scope
	garden = areas[scope]
	terrain = terrains[scope]
	placed_root = roots[scope]

func reload_items() -> void:
	store = Store.new()
	for root in roots.values():
		for child in root.get_children():
			root.remove_child(child)
			child.queue_free()
	for placement in store.data.placed:
		var scope: String = placement.get("area","garden")
		var point := Vector2(placement.x,placement.z)
		var item := Catalog.by_id(placement.id)
		if not _terrain_allowed(item,point,scope): continue
		var model := _model(placement.id)
		if not Growth.species(placement.id).is_empty():
			model.growth_age_days = Growth.age_days(placement,Time.get_unix_time_from_system())
			model.set_meta("growth_record",placement)
		model.position = Vector3(point.x,terrains[scope].sample_height(point),point.y)
		model.rotation.y = placement.angle
		roots[scope].add_child(model)
		preload("res://features/avatar/world_collisions.gd").install(model)

func _model(id: String) -> Node3D:
	var model := Model.instantiate()
	model.item_id = id
	return model

func begin(id: String, scope: String = "courtyard") -> bool:
	if active: finish()
	if not areas.has(scope): return false
	_select_area(scope)
	reload_items()
	if not store.readable or not Catalog.placeable(Catalog.by_id(id)): return false
	item_id = id
	angle = 0
	old_camera = {"focus":world.focus,"distance":world.distance,"pitch":world.pitch,"orbit":world.orbit,"walking":world.walking_mode}
	world.set_walking_mode(false)
	world.ui_panel_open = true
	world.focus = garden.to_global(Vector3(0,.1,0) if area == "courtyard" else Vector3(0,.1,46))
	world.distance = 68 if area == "courtyard" else 33
	world.pitch = .95
	world.orbit = .2
	world._update_camera()
	world.get_node("GameHUD").hide()
	ghost = _model(id)
	garden.add_child(ghost)
	ghost.hide()
	ghost_materials.clear()
	for mesh in ghost.find_children("*","MeshInstance3D",true,false):
		if mesh.material_override is StandardMaterial3D:
			mesh.material_override = mesh.material_override.duplicate()
			mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.material_override.albedo_color.a = .5
			ghost_materials.append(mesh.material_override)
	_tint_ghost(false)
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

func _terrain_allowed(item: Dictionary, point: Vector2, scope: String = "") -> bool:
	if scope.is_empty(): scope = area
	var surface = terrains[scope]
	if not Catalog.placeable(item) or not surface.contains(point): return false
	var radius := float(item.radius)+.2
	if surface.has_method("fits") and not surface.fits(point,radius): return false
	var height: float = surface.sample_height(point)
	for i in range(16):
		var a := float(i)*TAU/16
		var edge := point+Vector2(cos(a),sin(a))*radius
		if not surface.contains(edge): return false
		if absf(surface.sample_height(edge)-height) > .06: return false
	return true

func allowed(id: String, point: Vector2) -> bool:
	var item := Catalog.by_id(id)
	if not _terrain_allowed(item,point): return false
	for placement in store.data.placed:
		if placement.get("area","garden") != area: continue
		var other := Catalog.by_id(placement.id)
		if point.distance_to(Vector2(placement.x,placement.z)) < float(item.radius)+float(other.radius)+.15: return false
	return true

func place_at(point: Vector2) -> bool:
	if not active or not allowed(item_id,point): return false
	if not store.place(item_id,point,angle,area): return false
	var model := _model(item_id)
	if not Growth.species(item_id).is_empty():
		var record: Dictionary = store.data.placed[-1]
		model.growth_age_days = Growth.age_days(record,Time.get_unix_time_from_system())
		model.set_meta("growth_record",record)
	model.position = Vector3(point.x,terrain.sample_height(point),point.y)
	model.rotation.y = angle
	placed_root.add_child(model)
	preload("res://features/avatar/world_collisions.gd").install(model)
	return true

func _tint_ghost(valid: bool) -> void:
	ghost_valid = valid
	for material in ghost_materials:
		material.albedo_color = Color(.4,.85,.5,.5) if valid else Color(.95,.3,.25,.5)

func _process(delta: float) -> void:
	growth_timer += delta
	if growth_timer >= 60:
		growth_timer = 0
		refresh_growth()
	if not active: return
	var move := Vector3(float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A)),0,float(Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_W)))
	world.focus += move.limit_length(1.0).rotated(Vector3.UP,world.orbit)*delta*world.distance*.5
	world._update_camera()
	candidate = terrain.pick(world.camera,get_viewport().get_mouse_position())
	ghost.visible = candidate != null
	var valid := candidate != null and allowed(item_id,candidate)
	if valid != ghost_valid: _tint_ghost(valid)
	if candidate != null:
		ghost.position = Vector3(candidate.x,terrain.sample_height(candidate),candidate.y)
		ghost.rotation.y = angle
	var destination := "the inner circle" if area == "courtyard" else "Garden 01"
	hint.text = "%s · Free decorating · %s\nWASD: pan · Wheel: zoom" % [Catalog.by_id(item_id).name,"Click to place in "+destination if valid else "Choose open space; keep walking routes clear"]

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

func refresh_growth(now: float = -1.0) -> void:
	var real_clock := now < 0
	if now < 0: now = Time.get_unix_time_from_system()
	for root in roots.values():
		for model in root.get_children():
			if not model.has_meta("growth_record"): continue
			var record: Dictionary = model.get_meta("growth_record")
			var age := maxf(model.growth_age_days,Growth.age_days(record,now))
			if real_clock and record.has("growth"):
				record.growth.observed_age_days = maxf(float(record.growth.observed_age_days),age)
			if absf(age-model.growth_age_days) > .0005: model.rebuild(age)

func _exit_tree() -> void:
	# Preserve the greatest observed age on normal exit, without overwriting shop changes.
	var latest := Store.new()
	if not latest.readable: return
	var next: Dictionary = latest.data.duplicate(true)
	var changed := false
	var now := Time.get_unix_time_from_system()
	var observed := {}
	for root in roots.values():
		if not is_instance_valid(root): continue
		for model in root.get_children():
			if not model.has_meta("growth_record"): continue
			var local_record: Dictionary = model.get_meta("growth_record")
			if local_record.has("growth"): observed[_growth_key(local_record)] = local_record.growth.observed_age_days
	for record in next.placed:
		if not record.has("growth"): continue
		var age := maxf(Growth.age_days(record,now),float(observed.get(_growth_key(record),0)))
		if age > float(record.growth.observed_age_days):
			record.growth.observed_age_days = age
			changed = true
	if changed: latest._commit(next)

func _growth_key(record: Dictionary) -> String:
	return "%s|%s|%s|%s|%s" % [record.id,record.get("area","garden"),record.x,record.z,record.growth.started_at]
