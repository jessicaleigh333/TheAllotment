extends RefCounted
## Worn limestone/setts in staggered courses, over recessed earthy joints.
const STONE_SHADER = preload("res://shaders/cobblestone.gdshader")
const WIDTH := 3.1
const STEP := 0.44
var stone_mesh: ArrayMesh
var material: ShaderMaterial

func _init() -> void:
	stone_mesh = _stone_mesh()
	material = ShaderMaterial.new()
	material.shader = STONE_SHADER

func build(parent: Node3D, vertical: bool, lane: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 45713 + int(lane * 10.0) + (1000 if vertical else 0)
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for row in range(178):
		for col in range(7):
			# Half-course offsets give hand-laid stones a quietly irregular rhythm.
			var along := -38.78 + row * STEP + (STEP * 0.5 if col % 2 == 1 else 0.0)
			if along > 38.94:
				continue
			var side := _curve(along, lane)
			var across := (col - 3) * 0.44 + rng.randf_range(-0.012, 0.012)
			var x := side + across if vertical else along
			var z := along if vertical else side + across
			# Intersections are paved once, preventing overlapping stones/flicker.
			if not vertical and _in_vertical_lane(x, z):
				continue
			var derivative := 0.66 * TAU * 1.3 / 78.0 * cos((along + 39.0) / 78.0 * TAU * 1.3 + lane * 0.08)
			var angle := atan(derivative) if vertical else PI * 0.5 - atan(derivative)
			angle += rng.randf_range(-0.055, 0.055)
			var scale_value := Vector3(rng.randf_range(0.94, 1.04), rng.randf_range(0.87, 1.12), rng.randf_range(0.94, 1.04))
			transforms.append(Transform3D(Basis(Vector3.UP, angle).scaled(scale_value),Vector3(x, 0.029 + rng.randf_range(-0.003, 0.003), z)))
			# Muted cream, warm grey, and aged sandstone; avoid bright yellow paving.
			var palette := [Color("9d998a"), Color("aaa391"), Color("b2a993"), Color("918f83"), Color("a9a698"), Color("b8b09d")]
			var tone: Color = palette[rng.randi_range(0, palette.size() - 1)]
			tone *= rng.randf_range(0.94, 1.05)
			colors.append(Color(tone.r, tone.g, tone.b, rng.randf()))
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_custom_data = true
	multi.mesh = stone_mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_custom_data(i, colors[i])
	var stones := MultiMeshInstance3D.new()
	stones.name = "Cobblestones_%s_%s" % ["NorthSouth" if vertical else "EastWest", str(lane)]
	stones.multimesh = multi
	stones.material_override = material
	parent.add_child(stones)

func _curve(along: float, lane: float) -> float:
	return lane + 0.66 * sin((along + 39.0) / 78.0 * TAU * 1.3 + lane * 0.08)

func _in_vertical_lane(x: float, z: float) -> bool:
	for lane in [-11.0, 11.0]:
		if abs(x - _curve(z, lane)) < WIDTH * 0.5 + 0.19:
			return true
	return false

func _stone_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_color(Color.WHITE)
	# An eight-sided outline with chamfered corners and a softly domed crown.
	var outline := [Vector2(-0.15,-0.205),Vector2(0.145,-0.205),Vector2(0.20,-0.145),Vector2(0.20,0.145),Vector2(0.145,0.205),Vector2(-0.15,0.205),Vector2(-0.20,0.145),Vector2(-0.20,-0.145)]
	for i in range(8):
		var next := (i+1) % 8
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[next]
		var lower_a := Vector3(a.x, 0.0, a.y)
		var lower_b := Vector3(b.x, 0.0, b.y)
		var edge_a := Vector3(a.x, 0.032, a.y)
		var edge_b := Vector3(b.x, 0.032, b.y)
		var upper_a := Vector3(a.x*0.84, 0.064, a.y*0.84)
		var upper_b := Vector3(b.x*0.84, 0.064, b.y*0.84)
		for vertex in [lower_a,lower_b,edge_a, lower_b,edge_b,edge_a, edge_a,edge_b,upper_a, edge_b,upper_b,upper_a, upper_a,upper_b,Vector3(0,0.07,0)]:
			surface.set_uv(Vector2(vertex.x,vertex.z))
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()
