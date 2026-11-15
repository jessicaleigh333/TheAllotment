extends Node3D
## The Allotment — first editable world. All objects are generated at startup.
## No paid assets, plugins, players, or network connection required.

const GardenArt := preload("res://assets/garden_art/garden_library.gd")
const PLOT_SPACING := 22.0
const PLOT_SIZE := 18.0
const COLOURS := [Color("df909d"), Color("f0c86b"), Color("a995d4"), Color("f3e5ce"), Color("c879ad"), Color("e7aa7f")]
@export var default_pitch := 0.72
@export var default_distance := 57.0
@export var maximum_distance := 115.0
var camera: Camera3D
var focus := Vector3(0.0, 0.0, 0.0)
var orbit := 0.75
var distance := 57.0
var pitch := 0.72
var dragging := false
var ui_panel_open := false

func _ready() -> void:
	distance = default_distance
	pitch = default_pitch
	_build_lighting()
	_build_neighborhood()
	_build_camera()
	_build_hud()

func _process(delta: float) -> void:
	if ui_panel_open or get_viewport().gui_get_focus_owner() is LineEdit: return
	var movement := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): movement.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): movement.z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): movement.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): movement.x += 1.0
	if movement.length() > 0.0:
		movement = movement.normalized().rotated(Vector3.UP, orbit)
		focus += movement * delta * distance * 0.30
	if Input.is_key_pressed(KEY_Q): orbit -= delta * 1.1
	if Input.is_key_pressed(KEY_E): orbit += delta * 1.1
	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if ui_panel_open: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(12.0, distance - maxf(3.0, distance * 0.06))
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(maximum_distance, distance + maxf(3.0, distance * 0.06))
	elif event is InputEventMouseMotion and dragging:
		orbit -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.006, 0.3, 1.35)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		focus = Vector3.ZERO
		orbit = 0.75
		pitch = default_pitch
		distance = default_distance

func _build_lighting() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("b6d0ce")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e9e1cc")
	env.ambient_light_energy = 0.47
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color("ffdfb3")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(sun)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 55.0
	add_child(camera)
	_update_camera()

func _update_camera() -> void:
	if camera == null: return
	var horizontal := distance * cos(pitch)
	camera.position = focus + Vector3(sin(orbit) * horizontal, sin(pitch) * distance, cos(orbit) * horizontal)
	camera.look_at(focus, Vector3.UP)

func _build_hud() -> void:
	var game_hud := preload("res://ui/game_hud.tscn").instantiate()
	add_child(game_hud)
	game_hud.panel_visibility_changed.connect(func(is_open: bool) -> void:
		ui_panel_open = is_open
		dragging = false
	)


func _material(color: Color, roughness: float = 1.0, transparent: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _box(pos: Vector3, size: Vector3, color: Color, parent: Node3D = null, transparent: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _material(color, 1.0, transparent)
	node.position = pos
	if parent == null:
		add_child(node)
	else:
		parent.add_child(node)
	return node

func _ball(pos: Vector3, radius: float, color: Color, parent: Node3D = null) -> void:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = pos
	if parent == null:
		add_child(node)
	else:
		parent.add_child(node)

func _cylinder(pos: Vector3, radius: float, height: float, color: Color, parent: Node3D = null) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 7
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = pos
	if parent == null:
		add_child(node)
	else:
		parent.add_child(node)

func _build_neighborhood() -> void:
	_box(Vector3(0, -0.43, 0), Vector3(108, 0.65, 108), Color("668557"))
	# Paths are composed of small overlapping stone segments, producing gentle curves.
	for lane in [-11.0, 11.0]:
		_path_curve(true, lane)
		_path_curve(false, lane)
	for gx in range(-1, 2):
		for gz in range(-1, 2):
			_build_plot(Vector3(gx * PLOT_SPACING, 0, gz * PLOT_SPACING), gx, gz)
	_build_common_garden()
	# Shrubbery softens the outer borders of the neighborhood.
	for i in range(40):
		var a := float(i) * TAU / 40.0
		var radius := 43.0 + 2.5 * sin(float(i) * 2.13)
		_shrub(self, Vector3(cos(a) * radius, 0, sin(a) * radius), 0.8 + 0.2 * float(i % 3), i)

func _path_curve(vertical: bool, lane: float) -> void:
	var previous := Vector3.ZERO
	for i in range(49):
		var t := float(i) / 48.0
		var along := -39.0 + 78.0 * t
		var side := lane + 0.66 * sin(t * TAU * 1.3 + lane * 0.08)
		var here := Vector3(side, 0.045, along) if vertical else Vector3(along, 0.045, side)
		if i > 0:
			var midway := (previous + here) * 0.5
			var piece := _box(midway, Vector3(3.1, 0.085, previous.distance_to(here) + 0.20), Color("bda88b"))
			if not vertical:
				piece.rotation.y = PI * 0.5
		previous = here

func _build_plot(origin: Vector3, gx: int, gz: int) -> void:
	var plot := Node3D.new()
	plot.name = "Plot_%s_%s" % [gx + 2, gz + 2]
	plot.position = origin
	add_child(plot)
	var style := (gx + 1) * 3 + gz + 1
	var ground: Color = [Color("799767"), Color("829c70"), Color("769365"), Color("869b72")][style % 4]
	_box(Vector3(0, 0.01, 0), Vector3(PLOT_SIZE, 0.13, PLOT_SIZE), ground, plot)
	# Low timber edging with the front left open for a gate.
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 8.7, 0.30, 0), Vector3(0.14, 0.50, 17.4), Color("987955"), plot)
	_box(Vector3(0, 0.30, -8.7), Vector3(17.4, 0.50, 0.14), Color("987955"), plot)
	_box(Vector3(-5.3, 0.30, 8.7), Vector3(6.8, 0.50, 0.14), Color("987955"), plot)
	_box(Vector3(5.3, 0.30, 8.7), Vector3(6.8, 0.50, 0.14), Color("987955"), plot)
	# Different bed patterns help plots feel owned, instead of cloned.
	var offset := float(style % 3) * 0.48
	for idx in range(4):
		var bx := -4.8 if idx % 2 == 0 else -0.6
		var bz := -4.1 if idx < 2 else 0.6
		_build_bed(plot, Vector3(bx + offset, 0, bz), (idx + style) % COLOURS.size())
	# Informal flowering border along one edge.
	for j in range(9):
		var z := -7.5 + 1.8 * float(j)
		_shrub(plot, Vector3(-7.65, 0, z), 0.48, style * 17 + j)
		if j % 2 == 0:
			_flower(plot, Vector3(-6.95, 0.1, z + 0.2), COLOURS[(j + style) % COLOURS.size()], j % 3)
	_tree(plot, Vector3(5.7, 0, -5.8), 0.85 + 0.1 * float(style % 3))
	if style == 4:
		_build_greenhouse(plot, Vector3(4.8, 0, -1.4))
	elif style % 3 == 0:
		_build_greenhouse(plot, Vector3(4.8, 0, -1.4))
	else:
		_build_shed(plot, Vector3(4.9, 0, -1.3))
	_build_stall(plot, Vector3(5.6, 0, 5.8), style == 4)
	if style % 2 == 0:
		_arch(plot, Vector3(-1.4, 0, 6.8))
	else:
		_round_planter(plot, Vector3(-3.3, 0, 6.8), style)

func _build_bed(parent: Node3D, p: Vector3, palette: int) -> void:
	_garden_art(parent,"bed",p)
	for x in range(3):
		for z in range(3):
			var fx := p.x - 0.95 + x * 0.95
			var fz := p.z - 1.05 + z * 1.05
			_flower(parent, Vector3(fx, 0.38, fz), COLOURS[palette], (x + z) % 3)

func _flower(parent: Node3D, p: Vector3, color: Color, variant: int) -> void:
	var model := preload("res://features/market/item_model.tscn").instantiate()
	model.item_id = ["cosmos","daisy","rose"][posmod(variant,3)]
	model.blossom_tint = color
	model.position = p
	parent.add_child(model)

func _tree(parent: Node3D, p: Vector3, scale_factor: float) -> void:
	var id := "cypress" if posmod(int(p.x+p.z),4) == 0 else "tree"
	_garden_art(parent,id,p,scale_factor)

func _build_stall(parent: Node3D, p: Vector3, featured: bool) -> void:
	_garden_art(parent,"stall",p,1.0,Color("ead9d8") if featured else Color.WHITE)

func _build_greenhouse(parent: Node3D, p: Vector3) -> void:
	_garden_art(parent,"greenhouse",p)

func _build_shed(parent: Node3D, p: Vector3) -> void:
	_garden_art(parent,"shed",p)

func _shrub(parent: Node3D, p: Vector3, size: float, seed_value: int) -> void:
	_garden_art(parent,"rose" if seed_value%3 == 0 else "shrub",p,size,COLOURS[posmod(seed_value,COLOURS.size())] if seed_value%3 == 0 else Color.WHITE)

func _arch(parent: Node3D, p: Vector3) -> void:
	_garden_art(parent,"rose_arch",p)

func _round_planter(parent: Node3D, p: Vector3, seed_value: int) -> void:
	_garden_art(parent,"planter",p,2.2,COLOURS[posmod(seed_value,COLOURS.size())])

func _build_common_garden() -> void:
	for x in [-37.5, 37.5]:
		for z in [-37.5, 37.5]:
			_tree(self, Vector3(x, 0, z), 1.25)
	# Gentle village square at the main intersection, with a planted focal point.
	_cylinder(Vector3(-11.0, 0.20, -11.0), 2.1, 0.35, Color("b7a18a"))
	_cylinder(Vector3(-11.0, 0.60, -11.0), 1.1, 0.45, Color("8a9c77"))
	for i in range(8):
		var a := float(i) * TAU / 8.0
		_flower(self, Vector3(-11.0 + cos(a) * 0.80, 0.78, -11.0 + sin(a) * 0.80), COLOURS[i % COLOURS.size()], i % 3)
	# Small park vignette with curved stepping stones, trees, and shrubs.
	for i in range(12):
		var a := float(i) * TAU / 12.0
		var p := Vector3(34.0 + cos(a) * 5.4, 0, -11.0 + sin(a) * 5.4)
		_cylinder(p + Vector3(0, 0.05, 0), 0.65, 0.1, Color("baa88c"))
	for i in range(9):
		var a := float(i) * TAU / 9.0
		_shrub(self, Vector3(34.0 + cos(a) * 7.1, 0, -11.0 + sin(a) * 7.1), 0.8, i)
	_tree(self, Vector3(34.0, 0, -11.0), 1.3)

func _garden_art(parent: Node3D, id: String, position: Vector3, factor: float = 1.0, tint: Color = Color.WHITE) -> Node3D:
	var model := GardenArt.instance(id,tint)
	model.position = position
	model.scale = Vector3.ONE*factor
	parent.add_child(model)
	return model
