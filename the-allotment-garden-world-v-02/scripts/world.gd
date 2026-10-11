extends Node3D
## The Allotment — first editable world. All objects are generated at startup.
## No paid assets, plugins, players, or network connection required.

const PLOT_SPACING := 22.0
const PLOT_SIZE := 18.0
const COLOURS := [Color("df909d"), Color("f0c86b"), Color("a995d4"), Color("f3e5ce"), Color("c879ad"), Color("e7aa7f")]
const Lawn = preload("res://scripts/lawn.gd")
var lawn = Lawn.new()
const CobblePaths = preload("res://scripts/cobble_paths.gd")
var cobble_paths = CobblePaths.new()
var camera: Camera3D
var focus := Vector3(0.0, 0.0, 0.0)
var orbit := 0.75
var distance := 57.0
var pitch := 0.72
var dragging := false
var hud: Label

func _ready() -> void:
	_build_lighting()
	_build_neighborhood()
	lawn.populate(self)
	_build_camera()
	_build_hud()

func _process(delta: float) -> void:
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
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(12.0, distance - 3.0)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(115.0, distance + 3.0)
	elif event is InputEventMouseMotion and dragging:
		orbit -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.006, 0.3, 1.35)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		focus = Vector3.ZERO
		orbit = 0.75
		pitch = 0.72
		distance = 57.0

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
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(14, 14)
	panel.custom_minimum_size = Vector2(325, 0)
	layer.add_child(panel)
	hud = Label.new()
	hud.text = "THE ALLOTMENT | Garden neighborhood v0.2\nWASD: pan   Q/E: rotate   Right-drag: orbit\nMouse wheel: zoom   R: reset"
	hud.add_theme_color_override("font_color", Color("24372a"))
	hud.add_theme_font_size_override("font_size", 13)
	panel.add_child(hud)

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
	lawn.cover_ground(_box(Vector3(0, -0.43, 0), Vector3(108, 0.65, 108), Color("668557")))
	# Curved cobblestone lanes sit above a recessed bed of earthy joints.
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
		var here := Vector3(side, 0.004, along) if vertical else Vector3(along, 0.004, side)
		if i > 0:
			var midway := (previous + here) * 0.5
			var piece := _box(midway, Vector3(3.1, 0.05, previous.distance_to(here) + 0.20), Color("706958"))
			if not vertical:
				piece.rotation.y = PI * 0.5
		previous = here
	cobble_paths.build(self, vertical, lane)

func _build_plot(origin: Vector3, gx: int, gz: int) -> void:
	var plot := Node3D.new()
	plot.name = "Plot_%s_%s" % [gx + 2, gz + 2]
	plot.position = origin
	add_child(plot)
	var style := (gx + 1) * 3 + gz + 1
	var ground: Color = [Color("799767"), Color("829c70"), Color("769365"), Color("869b72")][style % 4]
	lawn.cover_ground(_box(Vector3(0, 0.01, 0), Vector3(PLOT_SIZE, 0.13, PLOT_SIZE), ground, plot))
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
	_box(p + Vector3(0, 0.16, 0), Vector3(3.2, 0.30, 3.5), Color("8a684d"), parent)
	_box(p + Vector3(0, 0.33, 0), Vector3(2.9, 0.08, 3.2), Color("544536"), parent)
	for x in range(3):
		for z in range(3):
			var fx := p.x - 0.95 + x * 0.95
			var fz := p.z - 1.05 + z * 1.05
			_flower(parent, Vector3(fx, 0.38, fz), COLOURS[palette], (x + z) % 3)

func _flower(parent: Node3D, p: Vector3, color: Color, variant: int) -> void:
	var height := 0.8 + 0.17 * variant
	_cylinder(p + Vector3(0, height * 0.5, 0), 0.04, height, Color("477c49"), parent)
	_ball(p + Vector3(-0.18, height * 0.35, 0), 0.16, Color("568551"), parent)
	_ball(p + Vector3(0.18, height * 0.55, 0), 0.17, Color("61915c"), parent)
	var head := p + Vector3(0, height, 0)
	for petal in range(5):
		var angle := float(petal) * TAU / 5.0
		_ball(head + Vector3(cos(angle) * 0.16, 0.0, sin(angle) * 0.16), 0.17, color, parent)
	_ball(head + Vector3(0, 0.035, 0), 0.11, Color("d8a83e"), parent)

func _tree(parent: Node3D, p: Vector3, scale_factor: float) -> void:
	_cylinder(p + Vector3(0, 1.4 * scale_factor, 0), 0.23 * scale_factor, 2.8 * scale_factor, Color("765138"), parent)
	for v in [Vector3(0, 3.3, 0), Vector3(-0.8, 2.8, 0), Vector3(0.7, 2.9, 0.3)]:
		_ball(p + v * scale_factor, 1.18 * scale_factor, Color("527b4d"), parent)
	for v in [Vector3(-0.6, 3.15, 0.5), Vector3(0.7, 2.7, -0.3), Vector3(0.0, 3.8, 0.2)]:
		_ball(p + v * scale_factor, 0.19, Color("d6ad69"), parent)

func _build_stall(parent: Node3D, p: Vector3, featured: bool) -> void:
	var timber := Color("8f6346")
	_box(p + Vector3(0, 0.62, 0), Vector3(3.0, 0.16, 1.5), Color("d6b68a"), parent)
	for x in [-1.3, 1.3]:
		for z in [-0.57, 0.57]:
			_box(p + Vector3(x, 1.38, z), Vector3(0.12, 2.7, 0.12), timber, parent)
	_box(p + Vector3(0, 2.74, 0), Vector3(3.4, 0.22, 2.1), Color("a76d60") if featured else Color("77896e"), parent)
	_box(p + Vector3(0, 2.37, 0.79), Vector3(1.8, 0.43, 0.09), Color("e0c49b"), parent)
	for x in [-0.8, 0, 0.8]:
		_cylinder(p + Vector3(x, 0.82, 0), 0.25, 0.35, Color("ba7956"), parent)
		_ball(p + Vector3(x, 1.13, 0), 0.28, Color("638c53"), parent)

func _build_greenhouse(parent: Node3D, p: Vector3) -> void:
	var glass := Color(0.66, 0.79, 0.73, 0.33)
	var frame := Color("d4e6d7")
	_box(p + Vector3(0, 1.6, 0), Vector3(3.4, 3.15, 4.2), glass, parent, true)
	for x in [-1.75, 1.75]:
		for z in [-2.15, 2.15]:
			_box(p + Vector3(x, 1.6, z), Vector3(0.10, 3.3, 0.1), frame, parent)
	_box(p + Vector3(0, 3.25, 0), Vector3(3.8, 0.17, 4.5), frame, parent)
	_box(p + Vector3(0, 0.2, 0), Vector3(3.6, 0.32, 4.4), Color("a3a58c"), parent)

func _build_shed(parent: Node3D, p: Vector3) -> void:
	_box(p + Vector3(0, 1.35, 0), Vector3(3.2, 2.7, 3.5), Color("b39579"), parent)
	_box(p + Vector3(0, 2.81, 0), Vector3(3.7, 0.26, 4.0), Color("5b695c"), parent)
	_box(p + Vector3(0, 1.08, 1.79), Vector3(0.95, 1.92, 0.08), Color("6d856f"), parent)

func _shrub(parent: Node3D, p: Vector3, size: float, seed_value: int) -> void:
	var tones := [Color("416b46"), Color("557a4d"), Color("688658"), Color("607a51")]
	_ball(p + Vector3(0, size * 0.6, 0), size * 0.75, tones[seed_value % tones.size()], parent)
	_ball(p + Vector3(size * 0.4, size * 0.45, 0.15), size * 0.55, tones[(seed_value + 1) % tones.size()], parent)
	if seed_value % 3 == 0:
		for j in range(3):
			_ball(p + Vector3(float(j - 1) * size * 0.35, size * 1.12, -0.1), size * 0.13, COLOURS[(seed_value + j) % COLOURS.size()], parent)

func _arch(parent: Node3D, p: Vector3) -> void:
	var wood := Color("7a694e")
	for x in [-1.1, 1.1]:
		_cylinder(p + Vector3(x, 1.35, 0), 0.095, 2.7, wood, parent)
	_box(p + Vector3(0, 2.75, 0), Vector3(2.5, 0.14, 0.25), wood, parent)
	for i in range(7):
		var xx := -1.15 + float(i) * 0.38
		_ball(p + Vector3(xx, 2.75 + 0.25 * sin(float(i) * 0.5), 0), 0.30, Color("4e7751"), parent)
		if i % 2 == 0:
			_ball(p + Vector3(xx, 2.95, 0.15), 0.19, COLOURS[i % COLOURS.size()], parent)

func _round_planter(parent: Node3D, p: Vector3, seed_value: int) -> void:
	_cylinder(p + Vector3(0, 0.30, 0), 0.82, 0.58, Color("ad8e70"), parent)
	_ball(p + Vector3(0, 0.85, 0), 0.7, Color("63815a"), parent)
	for i in range(5):
		var a := float(i) * TAU / 5.0
		_ball(p + Vector3(cos(a) * 0.46, 1.0, sin(a) * 0.46), 0.20, COLOURS[(seed_value + i) % COLOURS.size()], parent)

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
