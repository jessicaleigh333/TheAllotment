extends RefCounted
## Decorative limestone setts laid within the existing approach mesh.
const STONE_SHADER := preload("res://shaders/cobblestone.gdshader")
const SPACING := 0.44
const PALETTE := [Color("9d998a"), Color("aaa391"), Color("b2a993"), Color("918f83"), Color("a9a698"), Color("b8b09d")]

var stone_mesh := _stone_mesh()
var material := ShaderMaterial.new()

func _init() -> void:
	material.shader = STONE_SHADER

func add_to(approach: MeshInstance3D, entrance: int) -> void:
	var size: Vector3 = approach.mesh.size
	var columns := floori(size.x / SPACING)
	var rows := floori(size.z / SPACING) - 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 45713 + entrance
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_custom_data = true
	multi.mesh = stone_mesh
	multi.instance_count = columns * rows
	for column in range(columns):
		for row in range(rows):
			var across := (column - (columns - 1) * 0.5) * SPACING
			var along := (row - (rows - 1) * 0.5 + (0.25 if column % 2 else -0.25)) * SPACING
			var offset := Vector3(across, size.y * 0.5 - 0.025, along)
			var scale_value := Vector3(rng.randf_range(0.94, 1.01), 0.45, rng.randf_range(0.94, 1.01))
			var basis := Basis(Vector3.UP, rng.randf_range(-0.045, 0.045)).scaled(scale_value)
			var slot := column * rows + row
			multi.set_instance_transform(slot, Transform3D(basis, offset))
			var tint: Color = PALETTE[rng.randi_range(0, PALETTE.size() - 1)]
			multi.set_instance_custom_data(slot, Color(tint.r, tint.g, tint.b, rng.randf()))
	var stones := MultiMeshInstance3D.new()
	stones.name = "LimestoneSetts"
	stones.multimesh = multi
	stones.material_override = material
	stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	approach.add_child(stones)

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
