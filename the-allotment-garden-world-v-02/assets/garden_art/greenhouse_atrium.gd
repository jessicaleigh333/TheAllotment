extends Node3D
## Meter-scale atrium shell with authored walking surfaces.
const ID := "greenhouse_atrium_multilevel_01"
const SIZE := Vector3(7.32, 7.32, 10.97)
var staging_ground := false
var walking_collision := true
const WIDTH := 7.32
const LENGTH := 10.97
const RIDGE := 7.32
const EAVE := RIDGE - WIDTH * 0.5 / 1.7320508076
const LANDING := 1.62
const DECK := 3.24
const FLIGHT_RUN := 2.52
const CLEAR_WIDTH := 1.20
const FRAME := Color("27483c")
const STONE := Color("ded0b1")
const WOOD := Color("9f7754")
const GLASS := Color(0.65, 0.89, 0.95, 0.19)

func _ready() -> void:
	if staging_ground:
		_box("StagingGround", Vector3(0, -0.12, 0), Vector3(24, 0.20, 24), Color("839a72"), true)
	_box("Foundation", Vector3(0, -0.09, 0), Vector3(WIDTH, 0.18, LENGTH), STONE, true)
	_build_shell()
	_build_walkway()
	if not staging_ground:
		_build_arches()

func _build_shell() -> void:
	for sign_x in [-1.0, 1.0]:
		var side: float = sign_x * WIDTH * 0.5
		for bay in range(5):
			var z: float = -LENGTH * 0.5 + LENGTH * bay / 4.0
			_box("Jamb", Vector3(side, EAVE * 0.5, z), Vector3(0.13, EAVE, 0.13), FRAME, true)
			_beam("Rafter", Vector3(side, EAVE, z), Vector3(0, RIDGE, z), 0.12)
		for band in [1.05, 2.20, 3.05, 4.12, EAVE]:
			_beam("SideRail", Vector3(side, band, -LENGTH * 0.5), Vector3(side, band, LENGTH * 0.5), 0.09)
		_box("SideMasonry", Vector3(side, 0.49, 0), Vector3(0.15, 0.98, LENGTH), STONE, true)
		_box("SideGlazing", Vector3(side, (EAVE + 0.98) * 0.5, 0),
			Vector3(0.025, EAVE - 0.98, LENGTH), GLASS)
		_box("SideWallCollision", Vector3(side, 2.0, 0), Vector3(0.08, 4.0, LENGTH), Color.TRANSPARENT, true)
		var roof := _box("RoofGlazing", Vector3(side * 0.5, (RIDGE + EAVE) * 0.5, 0),
			Vector3(WIDTH * 0.5 / cos(PI / 6), 0.03, LENGTH), GLASS)
		roof.rotation.z = -sign_x * PI / 6
	_beam("Ridge", Vector3(0, RIDGE, -LENGTH * 0.5), Vector3(0, RIDGE, LENGTH * 0.5), 0.14)
	for z in [-LENGTH * 0.5, LENGTH * 0.5]:
		for x in [-2.25, -0.9, 0.9, 2.25]:
			var height: float = RIDGE - absf(x) / 1.7320508076
			_box("GableStud", Vector3(x, height * 0.5, z), Vector3(0.11, height, 0.11), FRAME, true)
		for side in [-1.0, 1.0]:
			_box("GableWing", Vector3(side * 2.28, 1.525, z), Vector3(2.65, 3.05, 0.14), STONE, true)
			_box("GableWindow", Vector3(side * 2.28, 4.04, z), Vector3(2.65, 1.98, 0.035), GLASS)
		_box("GableTransom", Vector3(0, 3.0, z), Vector3(1.8, 0.12, 0.14), FRAME, true)
	_box("RearWall", Vector3(0, 1.46, LENGTH * 0.5), Vector3(1.8, 2.92, 0.14), GLASS, true)

func _build_arches() -> void:
	for side in [-1.0, 1.0]:
		for bay in range(4):
			var center := Vector3(side * WIDTH * 0.5, 2.14, (float(bay) - 1.5) * LENGTH / 4)
			_arch("MasonryBay", center, Vector3.BACK, 1.10, 0.78, 0.16)
			for edge in [-1.10, 1.10]:
				_box("BayPier", center + Vector3(0, -0.57, edge), Vector3(0.16, 1.14, 0.16), STONE)
	var entry := Vector3(0, 2.10, -LENGTH * 0.5)
	_arch("EntranceArch", entry, Vector3.RIGHT, 0.95, 0.78, 0.14)
	for edge in [-0.95, 0.95]:
		_box("EntranceJamb", entry + Vector3(edge, -1.05, 0), Vector3(0.14, 2.10, 0.20), STONE)

func _arch(title: String, center: Vector3, across: Vector3, radius: float, rise: float, thickness: float) -> void:
	var previous := center + across * radius
	for segment in range(1, 13):
		var angle := float(segment) * PI / 12
		var point := center + across * (radius * cos(angle)) + Vector3.UP * (rise * sin(angle))
		_beam(title, previous, point, thickness, STONE)
		previous = point

func _build_walkway() -> void:
	_flight("LowerStair", Vector3(-2.5, 0, 0.60), Vector3.BACK)
	_box("TurnLanding", Vector3(-2.5, LANDING - 0.095, 3.72), Vector3(1.2, 0.19, 1.2), WOOD, true)
	_flight("UpperStair", Vector3(-1.9, LANDING, 3.72), Vector3.RIGHT)
	_box("RearMezzanine", Vector3(1.865, DECK - 0.095, 4.21), Vector3(2.49, 0.19, 2.18), WOOD, true)
	_box("SideMezzanine", Vector3(2.51, DECK - 0.095, 0.1), Vector3(1.2, 0.19, 6.04), WOOD, true)
	_guard(Vector3(0.62, DECK, 3.12), Vector3(1.91, DECK, 3.12))
	_guard(Vector3(1.91, DECK, 3.12), Vector3(1.91, DECK, -2.92))
	_guard(Vector3(1.91, DECK, -2.92), Vector3(3.11, DECK, -2.92))
	_guard(Vector3(3.11, DECK, -2.92), Vector3(3.11, DECK, 5.3))
	_guard(Vector3(3.11, DECK, 5.3), Vector3(0.62, DECK, 5.3))
	_guard(Vector3(0.62, DECK, 5.3), Vector3(0.62, DECK, 4.32))
	_guard(Vector3(-3.10, LANDING, 3.12), Vector3(-3.10, LANDING, 4.32))
	_guard(Vector3(-3.10, LANDING, 4.32), Vector3(-1.90, LANDING, 4.32))

func _flight(title: String, foot: Vector3, direction: Vector3) -> void:
	var side := direction.cross(Vector3.UP)
	var crosswise := absf(direction.x) > 0.5
	for step in range(9):
		var top := (step + 1) * LANDING / 10.0
		var point := foot + direction * (step + 0.5) * 0.28 + Vector3.UP * (top - 0.085)
		_box("Tread", point, Vector3(0.28, 0.17, CLEAR_WIDTH) if crosswise else Vector3(CLEAR_WIDTH, 0.17, 0.28), WOOD)
	var ramp := StaticBody3D.new()
	ramp.name = title
	ramp.rotation.y = atan2(-direction.x, -direction.z)
	ramp.position = foot
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	# Reach landing height before the capsule can touch the landing box face.
	for edge_x in [-CLEAR_WIDTH * 0.5, CLEAR_WIDTH * 0.5]:
		for profile in [Vector2(0.04, -0.08), Vector2(0.04, 0.0),
			Vector2(0.38 - FLIGHT_RUN, LANDING + 0.035), Vector2(-FLIGHT_RUN - 0.08, LANDING + 0.035),
			Vector2(-FLIGHT_RUN - 0.08, -0.08)]:
			points.append(Vector3(edge_x, profile.y, profile.x))
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	ramp.add_child(collision)
	if walking_collision: add_child(ramp)
	else: ramp.free()
	for sign_side in [-1.0, 1.0]:
		var edge: Vector3 = foot + side * (sign_side * CLEAR_WIDTH * 0.5)
		_guard(edge, edge + direction * FLIGHT_RUN + Vector3.UP * LANDING)

func _guard(from: Vector3, to: Vector3) -> void:
	var rails := 1.05
	_beam("Handrail", from + Vector3.UP * rails, to + Vector3.UP * rails, 0.06)
	var count := ceili(from.distance_to(to) / 0.35)
	for step in range(count + 1):
		var point := from.lerp(to, float(step) / count)
		_box("Baluster", point + Vector3.UP * rails * 0.5, Vector3(0.04, rails, 0.04), FRAME)
	var blocker := _box("RailCollision", (from + to) * 0.5 + Vector3.UP * 0.47,
		Vector3(0.07, 0.98, from.distance_to(to)), Color.TRANSPARENT, true)
	blocker.look_at(blocker.global_position + to - from, Vector3.UP)

func _beam(title: String, from: Vector3, to: Vector3, thickness: float, tint := FRAME) -> void:
	var beam := _box(title, (from + to) * 0.5, Vector3(thickness, thickness, from.distance_to(to)), tint)
	beam.look_at(beam.global_position + to - from, Vector3.UP)

func _box(title: String, point: Vector3, size: Vector3, tint: Color, collide := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.82
	if tint.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.material_override = mat
	node.position = point
	add_child(node)
	if collide and walking_collision:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		node.add_child(body)
	return node
