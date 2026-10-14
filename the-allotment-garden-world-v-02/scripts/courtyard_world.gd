extends "res://scripts/world.gd"
## Nine acre-scale annular wedges. One Godot world unit represents one metre.
const GARDEN_COUNT := 9
const ACRE_M2 := 4046.8564224
const STANDARD_ACRES := 1.84
const INNER_RADIUS := 32.0
const COURTYARD_RADIUS := 26.0
const SECTOR_ANGLE := TAU / GARDEN_COUNT
const WEDGE_ANGLE := SECTOR_ANGLE
const HEDGE_SEGMENT := preload("res://assets/hedges/hedge_segment.tscn")
const ARC_SEGMENTS := 64
# Compensate for the polygon approximation so the actual rendered surface has
# the specified acreage, not just the ideal mathematical circular sector.
var outer_radius := sqrt(INNER_RADIUS * INNER_RADIUS + 2.0 * STANDARD_ACRES * ACRE_M2 / (ARC_SEGMENTS * sin(WEDGE_ANGLE / ARC_SEGMENTS)))

var player
var walking_mode := true
var exploration_button: Button
var exploration_hint: Label
var overview_focus := Vector3.ZERO
var overview_distance := 390.0
var overview_pitch := 1.05
var overview_orbit := .75

func _ready() -> void:
	super._ready()
	preload("res://features/avatar/world_collisions.gd").install(self)
	player = preload("res://features/avatar/garden_player.tscn").instantiate()
	player.world = self
	player.maximum_radius = outer_radius+14.0
	add_child(player)
	player.position = player.spawn_position
	_build_exploration_controls()
	set_walking_mode(true)

func _build_exploration_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ExplorationControls"
	add_child(layer)
	var box := VBoxContainer.new()
	layer.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	box.offset_left = -440
	box.offset_right = -20
	box.offset_top = -80
	box.offset_bottom = -16
	exploration_button = Button.new()
	exploration_button.custom_minimum_size.y = 34
	exploration_button.pressed.connect(func() -> void: set_walking_mode(not walking_mode))
	box.add_child(exploration_button)
	exploration_hint = Label.new()
	exploration_hint.add_theme_font_size_override("font_size",13)
	exploration_hint.add_theme_color_override("font_color",Color("fff1ce"))
	exploration_hint.add_theme_color_override("font_shadow_color",Color("273a2a"))
	exploration_hint.add_theme_constant_override("shadow_offset_x",1)
	exploration_hint.add_theme_constant_override("shadow_offset_y",2)
	box.add_child(exploration_hint)

func set_walking_mode(enabled: bool) -> void:
	if player == null: return
	if enabled and not walking_mode:
		overview_focus = focus
		overview_distance = distance
		overview_pitch = pitch
		overview_orbit = orbit
	walking_mode = enabled
	player.movement_enabled = enabled
	dragging = false
	if enabled:
		focus = player.position+Vector3(0,1.0,0)
		distance = 4.6
		pitch = .28
		orbit = .55
	else:
		focus = overview_focus
		distance = overview_distance
		pitch = overview_pitch
		orbit = overview_orbit
	exploration_button.text = "Neighborhood overview  ·  Tab" if enabled else "Walk in the garden  ·  Tab"
	exploration_hint.text = "WASD: stroll  •  Shift: faster  •  Right-drag: camera" if enabled else "WASD: pan  •  Wheel: zoom  •  Walk to explore up close"
	_update_camera()

func _process(delta: float) -> void:
	if player == null:
		super._process(delta)
		return
	var editing: bool = ground_editor_session != null and ground_editor_session.active
	$ExplorationControls.visible = not editing and not ui_panel_open
	if editing or not walking_mode:
		super._process(delta)
		return
	if ui_panel_open or get_viewport().gui_get_focus_owner() is LineEdit: return
	if Input.is_key_pressed(KEY_Q): orbit -= delta*1.1
	if Input.is_key_pressed(KEY_E): orbit += delta*1.1
	focus = focus.lerp(player.position+Vector3(0,1.0,0),minf(1,delta*9))
	_update_camera()

func _input(event: InputEvent) -> void:
	if ui_panel_open or (ground_editor_session != null and ground_editor_session.active): return
	if get_viewport().gui_get_focus_owner() is LineEdit: return
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		set_walking_mode(not walking_mode)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if ui_panel_open: return
	if ground_editor_session != null and ground_editor_session.active:
		super._unhandled_input(event)
		return
	if walking_mode:
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(distance+(-.4 if event.button_index == MOUSE_BUTTON_WHEEL_UP else .4),2.8,10)
			return
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			distance = 4.6
			pitch = .28
			orbit = .55
			return
	super._unhandled_input(event)

func _build_lighting() -> void:
	super._build_lighting()
	# Draw the illustrated canvas behind the 3D neighborhood. The staging scene
	# continues to use the original plain environment from world.gd.
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.background_mode = Environment.BG_CANVAS
			child.environment.background_canvas_max_layer = -1
			var panorama := PanoramaSkyMaterial.new()
			panorama.panorama = load("res://assets/third_party/poly_haven/spruit_sunrise/spruit_sunrise_1k.hdr")
			panorama.energy_multiplier = .6
			var sky := Sky.new()
			sky.sky_material = panorama
			sky.radiance_size = Sky.RADIANCE_SIZE_128
			child.environment.sky = sky
			child.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			child.environment.ambient_light_energy = .32
			child.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
			break
	for child in get_children():
		if child is DirectionalLight3D:
			child.light_energy = .55
			child.light_color = Color("ffead4")

func _build_neighborhood() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "NeighborhoodGround"
	var mesh := CylinderMesh.new()
	mesh.top_radius = outer_radius + 16.0
	mesh.bottom_radius = outer_radius + 16.0
	mesh.height = 0.65
	mesh.radial_segments = 128
	ground.mesh = mesh
	ground.position.y = -0.43
	ground.material_override = _material(Color("668557"))
	add_child(ground)
	_build_courtyard()
	for index in range(GARDEN_COUNT):
		_build_wedge_garden(index)
	for i in range(72):
		var angle := float(i) * TAU / 72.0
		_shrub(self, _polar(outer_radius + 8.0, angle), 1.3, i)
		if i % 4 == 0:
			_tree(self, _polar(outer_radius + 11.0, angle), 1.65)

func _polar(radius: float, angle: float, height: float = 0.0) -> Vector3:
	return Vector3(sin(angle) * radius, height, cos(angle) * radius)

func _build_wedge_garden(index: int) -> void:
	var garden := Node3D.new()
	garden.name = "Garden_%02d" % (index + 1)
	garden.rotation.y = index * SECTOR_ANGLE
	garden.set_meta("garden_index", index + 1)
	garden.set_meta("area_acres", STANDARD_ACRES)
	garden.set_meta("area_m2", STANDARD_ACRES * ACRE_M2)
	add_child(garden)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.UP)
	for segment in range(ARC_SEGMENTS):
		var a := -WEDGE_ANGLE / 2.0 + segment * WEDGE_ANGLE / ARC_SEGMENTS
		var b := -WEDGE_ANGLE / 2.0 + (segment + 1) * WEDGE_ANGLE / ARC_SEGMENTS
		var inner_a := _polar(INNER_RADIUS, a, 0.1)
		var inner_b := _polar(INNER_RADIUS, b, 0.1)
		var outer_a := _polar(outer_radius, a, 0.1)
		var outer_b := _polar(outer_radius, b, 0.1)
		for vertex in [inner_a, outer_b, outer_a, inner_a, inner_b, outer_b]:
			surface.add_vertex(vertex)
	var lawn := MeshInstance3D.new()
	lawn.name = "WedgeGround"
	lawn.mesh = surface.commit()
	var tones := [Color("799767"), Color("829c70"), Color("769365"), Color("869b72")]
	lawn.material_override = _material(tones[index % 4])
	garden.add_child(lawn)
	var entrance := Marker3D.new()
	entrance.name = "Entrance"
	entrance.position = _polar(INNER_RADIUS, 0)
	entrance.rotation.y = PI
	garden.add_child(entrance)
	# Curved front boundary leaves a four-metre entry opening; all boundaries
	# follow the wedge footprint, rather than enclosing a small square garden.
	for radius in [INNER_RADIUS, outer_radius]:
		for segment in range(ARC_SEGMENTS):
			var a := -WEDGE_ANGLE / 2.0 + segment * WEDGE_ANGLE / ARC_SEGMENTS
			var b := -WEDGE_ANGLE / 2.0 + (segment + 1) * WEDGE_ANGLE / ARC_SEGMENTS
			if radius == INNER_RADIUS and absf((a + b) / 2.0) < 2.0 / INNER_RADIUS: continue
			_edge(garden, _polar(radius, a), _polar(radius, b))
	# Adjoining wedges share a single hedge along their common radial boundary.
	# There is no paved lane or empty strip between gardens.
	_hedge_divider(garden)
	var angle := index * SECTOR_ANGLE
	_stone_link(_polar(COURTYARD_RADIUS - 0.3, angle), _polar(INNER_RADIUS, angle), 4.0)
	# Reuse prototype furnishings at their original sizes, leaving most acreage
	# available for planting, large landmarks and future owner customization.
	for bed in range(4):
		_build_bed(garden, Vector3(-5.0 if bed % 2 == 0 else 1.0, 0, INNER_RADIUS + 7.0 + 5.0 * floori(bed / 2.0)), (bed + index) % COLOURS.size())
	_arch(garden, Vector3(0, 0.1, INNER_RADIUS + 1.0))
	_build_stall(garden, Vector3(8.0, 0.1, INNER_RADIUS + 15.0), index == 4)
	var utilities := Vector3(0, 0, outer_radius - 15.0)
	if index % 3 == 0:
		_build_greenhouse(garden, utilities)
	else:
		_build_shed(garden, utilities)
	for i in range(9):
		var radius := INNER_RADIUS + 24.0 + i * 11.0
		for side in [-1.0, 1.0]:
			var position := _polar(radius, side * (WEDGE_ANGLE / 2.0 - 0.035))
			_shrub(garden, position, 1.1, index * 19 + i)
			if i % 3 == 0: _tree(garden, position + Vector3(0, 0, 3), 1.2)
	for i in range(7):
		_tree(garden, _polar(outer_radius - 7.0, (float(i) - 3.0) * WEDGE_ANGLE / 8.0), 1.4)

func _hedge_divider(garden: Node3D) -> void:
	var divider := Node3D.new()
	divider.name = "SharedHedge"
	garden.add_child(divider)
	var length := outer_radius - INNER_RADIUS
	var count := ceili(length / 2.0)
	var spacing := length / count
	for i in range(count):
		var segment := HEDGE_SEGMENT.instantiate() as Node3D
		segment.position = _polar(INNER_RADIUS + (i + 0.5) * spacing, WEDGE_ANGLE / 2.0)
		segment.rotation.y = WEDGE_ANGLE / 2.0
		divider.add_child(segment)

func _edge(parent: Node3D, start: Vector3, end: Vector3) -> void:
	var stone := _box((start + end) * 0.5 + Vector3(0, 0.28, 0), Vector3(0.3, 0.35, start.distance_to(end) + 0.02), Color("ae9473"), parent)
	stone.rotation.y = atan2(end.x - start.x, end.z - start.z)

func _build_courtyard() -> void:
	var courtyard := Node3D.new()
	courtyard.name = "CircularCourtyard"
	add_child(courtyard)
	var paving := MeshInstance3D.new()
	paving.name = "StonePaving"
	var mesh := CylinderMesh.new()
	mesh.top_radius = COURTYARD_RADIUS
	mesh.bottom_radius = COURTYARD_RADIUS
	mesh.height = 0.12
	mesh.radial_segments = 96
	paving.mesh = mesh
	paving.material_override = _material(Color("c8b597"))
	paving.position.y = 0.065
	courtyard.add_child(paving)
	# Warm stone rim and concentric paving joints make the shared circle readable.
	for radius in [8.0, 17.0, 25.7]:
		for i in range(96):
			var angle := float(i) * TAU / 96.0
			var next_angle := float(i + 1) * TAU / 96.0
			var start := Vector3(sin(angle) * radius, 0.13, cos(angle) * radius)
			var end := Vector3(sin(next_angle) * radius, 0.13, cos(next_angle) * radius)
			var stone := _box((start + end) * 0.5, Vector3(0.12 if radius < 25 else 0.35, 0.045, start.distance_to(end) + 0.02), Color("ae9473"), courtyard)
			stone.rotation.y = atan2(end.x - start.x, end.z - start.z)
	# Reuse the established planted centerpiece; fountain art can replace it later.
	_cylinder(Vector3(0, 0.3, 0), 3.2, 0.45, Color("b7a18a"), courtyard)
	_cylinder(Vector3(0, 0.65, 0), 2.7, 0.35, Color("544536"), courtyard)
	for i in range(18):
		var angle := float(i) * TAU / 18.0
		_flower(courtyard, Vector3(sin(angle) * 2.2, 0.85, cos(angle) * 2.2), COLOURS[i % COLOURS.size()], i % 3)
	for i in range(9):
		var angle := (float(i) + 0.5) * TAU / 9.0
		_round_planter(courtyard, Vector3(sin(angle) * 22.0, 0.12, cos(angle) * 22.0), i)

func _stone_link(start: Vector3, end: Vector3, width: float) -> void:
	var stone := _box((start + end) * 0.5 + Vector3(0, 0.08, 0), Vector3(width, 0.12, start.distance_to(end) + 0.25), Color("bda88b"))
	stone.name = "GardenApproach"
	stone.rotation.y = atan2(end.x - start.x, end.z - start.z)

# Until account/claiming services exist, the trowel opens one explicitly local
# demo scope. It never assigns ownership to another garden or account.
var ground_editor_session

func open_ground_editor() -> void:
	if ground_editor_session == null:
		ground_editor_session = preload("res://features/garden_editor/editor_session.gd").new()
		ground_editor_session.name = "GroundEditorSession"
		add_child(ground_editor_session)
		ground_editor_session.configure(self, $Garden_01, "local_demo_neighborhood_garden_01", "local-demo", "local-demo", 20261013)
	ground_editor_session.open()
