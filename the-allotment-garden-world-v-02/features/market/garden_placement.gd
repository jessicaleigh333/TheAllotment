extends Node
const Vines := preload("res://features/market/climbing_vines.gd")
const Stack := preload("res://features/market/stack_rules.gd")
const Picker := preload("res://features/market/stack_picker.gd")
const Boundary := preload("res://features/market/boundary_placement.gd")
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
var ghost_shaders: Array[ShaderMaterial] = []
var growth_timer := 0.0
var stack_mode := false
var stack_button: Button
var candidate_elevation := 0.0
var candidate_supports: Array = []

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
		model.position = Vector3(point.x,terrains[scope].sample_height(point)+Stack.elevation(placement),point.y)
		model.rotation.y = placement.angle
		model.set_meta("placement_record",placement)
		roots[scope].add_child(model)
		preload("res://features/avatar/world_collisions.gd").install(model)

	refresh_vines()

func refresh_vines() -> void:
	Vines.refresh(roots,store.data.placed)

func _model(id: String) -> Node3D:
	var model := Model.instantiate()
	model.item_id = id
	return model

func begin(id: String, scope: String = "courtyard") -> bool:
	if active: finish()
	if not areas.has(scope): return false
	_select_area(scope)
	reload_items()
	if not store.ensure_placement_ids(func(record: Dictionary) -> float:
		return terrains[record.get("area","garden")].sample_height(Vector2(record.x,record.z))): return false
	if not store.readable or not Catalog.placeable(Catalog.by_id(id)): return false
	item_id = id
	stack_mode = Stack.Roman.SIZES.has(id)
	candidate_elevation = 0
	candidate_supports = []
	angle = 0
	old_camera = {"focus":world.focus,"distance":world.distance,"pitch":world.pitch,"orbit":world.orbit,"walking":world.walking_mode}
	world.set_walking_mode(false)
	world.ui_panel_open = true
	world.focus = garden.to_global(Vector3(0,.1,0) if area == "courtyard" else Vector3(0,.1,46))
	world.distance = 68 if area == "courtyard" else 33
	world.pitch = .95
	world.orbit = .2
	if Stack.Roman.SIZES.has(id):
		world.distance = 20
		world.focus = garden.to_global(Vector3(5,.4,9) if area == "courtyard" else Vector3(0,.4,46))
		for record in store.data.placed:
			if record.get("area","garden") == area and not Stack.top(record.id).is_empty():
				world.focus = garden.to_global(Vector3(record.x,Stack.top_y(record),record.z))
	world._update_camera()
	world.get_node("GameHUD").hide()
	ghost = _model(id)
	ghost.set_meta("placement_preview",true)
	garden.add_child(ghost)
	ghost.hide()
	ghost_materials.clear()
	ghost_shaders.clear()
	for mesh in ghost.find_children("*","MeshInstance3D",true,false):
		if mesh.material_override is StandardMaterial3D:
			mesh.material_override = mesh.material_override.duplicate()
			mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.material_override.albedo_color.a = .5
			ghost_materials.append(mesh.material_override)
		else:
			var material := ShaderMaterial.new()
			material.shader = preload("res://assets/garden_art/placement_preview.gdshader")
			mesh.material_override = material
			ghost_shaders.append(material)
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
	if Stack.can_stack(item_id):
		stack_button = Button.new()
		stack_button.custom_minimum_size = Vector2(150,44)
		stack_button.text = "Stack: on · T" if stack_mode else "Stack: off · T"
		stack_button.pressed.connect(_toggle_stack)
		row.add_child(stack_button)
	for action in [["Rotate · R",func() -> void: angle += PI/4],["View ↑",func() -> void: _raise_view(.75)],["View ↓",func() -> void: _raise_view(-.75)],["Done · Esc",finish]]:
		var button := Button.new()
		button.text = action[0]
		button.custom_minimum_size = Vector2(100,44)
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

func allowed(id: String, point: Vector2, elevation: float = 0.0, supports: Array = []) -> bool:
	var item := Catalog.by_id(id)
	if not _terrain_allowed(item,point) or not is_finite(elevation) or elevation < 0 or elevation+Stack.size(id).y > Stack.MAX_HEIGHT: return false
	var bottom: float = terrain.sample_height(point)+elevation
	if elevation > 0:
		var required := Stack.supports_for(id,point,angle,bottom,store.data.placed,area)
		var provided: Array = supports.duplicate()
		required.sort()
		provided.sort()
		if required.is_empty() or provided != required: return false
	elif not supports.is_empty(): return false
	var training := Vines.nearby_support(id,point,bottom,store.data.placed,area) if elevation == 0 else {}
	for placement in store.data.placed:
		if placement.get("area","garden") != area: continue
		if not training.is_empty() and training.uid == placement.get("uid",""): continue
		if Vines.is_vine(placement.id) and elevation == 0:
			var prospective := {"id":id,"x":point.x,"z":point.y,"angle":angle,"ground_y":bottom,"area":area,"uid":"candidate"}
			if not Vines.attachment(placement,[prospective]).is_empty(): continue
		var other := Catalog.by_id(placement.id)
		var other_bottom: float = terrain.sample_height(Vector2(placement.x,placement.z))+Stack.elevation(placement)
		if bottom >= other_bottom+Stack.size(placement.id).y-Stack.EPS or other_bottom >= bottom+Stack.size(id).y-Stack.EPS: continue
		if elevation > 0 or Stack.elevation(placement) > 0:
			if Stack.volume_overlap(id,point,angle,placement.id,Vector2(placement.x,placement.z),placement.angle): return false
		elif id in Boundary.IDS and placement.id in Boundary.IDS:
			if Boundary.overlap(id,point,angle,placement.id,Vector2(placement.x,placement.z),placement.angle): return false
		elif point.distance_to(Vector2(placement.x,placement.z)) < float(item.radius)+float(other.radius)+.15: return false
	return true

func place_at(point: Vector2, elevation: float = 0.0, supports: Array = []) -> bool:
	if not active or not allowed(item_id,point,elevation,supports): return false
	var ground: float = terrain.sample_height(point)
	if not store.place(item_id,point,angle,area,elevation,supports,ground): return false
	var model := _model(item_id)
	if not Growth.species(item_id).is_empty():
		var record: Dictionary = store.data.placed[-1]
		model.growth_age_days = Growth.age_days(record,Time.get_unix_time_from_system())
		model.set_meta("growth_record",record)
	model.position = Vector3(point.x,ground+elevation,point.y)
	model.rotation.y = angle
	model.set_meta("placement_record",store.data.placed[-1])
	placed_root.add_child(model)
	preload("res://features/avatar/world_collisions.gd").install(model)
	refresh_vines()
	if stack_mode:
		world.focus.y = garden.to_global(Vector3(point.x,ground+elevation+Stack.size(item_id).y,point.y)).y
		world._update_camera()
	return true

func _toggle_stack() -> void:
	stack_mode = not stack_mode
	if is_instance_valid(stack_button): stack_button.text = "Stack: on · T" if stack_mode else "Stack: off · T"

func _raise_view(amount: float) -> void:
	world.focus.y = clampf(world.focus.y+amount,0,Stack.MAX_HEIGHT)
	world._update_camera()

func _tint_ghost(valid: bool) -> void:
	ghost_valid = valid
	for material in ghost_shaders:
		material.set_shader_parameter("tint",Color(.4,.85,.5,.45) if valid else Color(.95,.3,.25,.45))
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
	candidate_elevation = 0
	candidate_supports = []
	var picked := Picker.pick(world.camera,get_viewport().get_mouse_position(),garden,item_id,angle,store.data.placed,area,terrain.sample_height) if stack_mode else {}
	if not picked.is_empty():
		candidate = picked.point
		candidate_elevation = picked.elevation
		candidate_supports = picked.supports
		angle = picked.angle
	else: candidate = terrain.pick(world.camera,get_viewport().get_mouse_position())
	if candidate != null and candidate_elevation == 0 and item_id in Boundary.IDS: candidate = Boundary.snap(item_id,candidate,angle,store.data.placed,area)
	ghost.visible = candidate != null
	var valid := candidate != null and allowed(item_id,candidate,candidate_elevation,candidate_supports)
	if valid != ghost_valid: _tint_ghost(valid)
	if candidate != null:
		ghost.position = Vector3(candidate.x,terrain.sample_height(candidate)+candidate_elevation,candidate.y)
		ghost.rotation.y = angle
	var destination := "the inner circle" if area == "courtyard" else "Garden 01"
	hint.text = "%s · %s · %.2f m above ground\n%s · WASD: pan · Wheel: zoom" % [Catalog.by_id(item_id).name,"Stack" if stack_mode else "Ground",candidate_elevation,"Click to place in "+destination if valid else "Choose a supported top or open ground; keep routes clear"]
	if Vines.is_vine(item_id):
		var training := Vines.nearby_support(item_id,candidate,terrain.sample_height(candidate),store.data.placed,area) if candidate != null else {}
		hint.text += "\nWill climb "+str(Catalog.by_id(training.id).name)+" · real days and weeks" if not training.is_empty() else "\nPlant within 85 cm of a suitable post or trellis to climb"

func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE: finish()
		elif event.keycode == KEY_R: angle += PI/4
		elif event.keycode == KEY_T and Stack.can_stack(item_id): _toggle_stack()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if candidate != null: place_at(candidate,candidate_elevation,candidate_supports)
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

	refresh_vines()

func save_growth_progress() -> bool:
	# Preserve the greatest observed age on normal exit, without overwriting shop changes.
	var latest := Store.new()
	if not latest.readable: return false
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
	return latest._commit(next) if changed else true

func _exit_tree() -> void:
	save_growth_progress()

func _growth_key(record: Dictionary) -> String:
	return "%s|%s|%s|%s|%s" % [record.id,record.get("area","garden"),record.x,record.z,record.growth.started_at]
