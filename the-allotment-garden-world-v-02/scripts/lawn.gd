extends RefCounted
## Short, dense turf: opaque blade geometry over a procedural PBR ground layer.
## Chunked MultiMeshes keep draw calls low and allow offscreen grass to be culled.
const GROUND_SHADER = preload("res://shaders/lawn.gdshader")
const BLADE_SHADER = preload("res://shaders/grass_blades.gdshader")
const CHUNK_SIZE := 12.0
const DENSITY := 22.0
var ground_material: ShaderMaterial
var blade_mesh: ArrayMesh
var blade_material: ShaderMaterial

func _init() -> void:
	ground_material = ShaderMaterial.new()
	ground_material.shader = GROUND_SHADER
	blade_material = ShaderMaterial.new()
	blade_material.shader = BLADE_SHADER
	blade_mesh = _make_clump()

func cover_ground(node: MeshInstance3D) -> void:
	node.material_override = ground_material

func populate(parent: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 736281
	for cx in range(9):
		for cz in range(9):
			var center := Vector2(-48.0 + cx * CHUNK_SIZE, -48.0 + cz * CHUNK_SIZE)
			var transforms: Array[Transform3D] = []
			var colors: Array[Color] = []
			for i in range(int(CHUNK_SIZE * CHUNK_SIZE * DENSITY)):
				var x := center.x + rng.randf_range(-6.0, 6.0)
				var z := center.y + rng.randf_range(-6.0, 6.0)
				var height := _ground_height(x, z)
				if height < -1.0:
					continue
				var scale_factor := rng.randf_range(0.78, 1.18)
				var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale_factor, rng.randf_range(0.72, 1.16), scale_factor))
				transforms.append(Transform3D(basis, Vector3(x - center.x, height, z - center.y)))
				var shade := rng.randf_range(0.85, 1.12)
				colors.append(Color(shade, shade * rng.randf_range(0.97, 1.03), shade * rng.randf_range(0.88, 1.08), 1.0))
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.use_colors = true
			multi.mesh = blade_mesh
			multi.instance_count = transforms.size()
			for i in range(transforms.size()):
				multi.set_instance_transform(i, transforms[i])
				multi.set_instance_color(i, colors[i])
			var grass := MultiMeshInstance3D.new()
			grass.name = "ShortGrass_%d_%d" % [cx, cz]
			grass.multimesh = multi
			grass.material_override = blade_material
			grass.position = Vector3(center.x, 0, center.y)
			# The detailed turf underneath carries the appearance at longer distances.
			grass.visibility_range_end = 70.0
			grass.visibility_range_end_margin = 8.0
			grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(grass)

func _ground_height(x: float, z: float) -> float:
	# Match the curved stone lanes, leaving their edges clean.
	if abs(x) <= 39.3 and abs(z) <= 39.3:
		for lane in [-11.0, 11.0]:
			var side_x: float = lane + 0.66 * sin((z + 39.0) / 78.0 * TAU * 1.3 + lane * 0.08)
			var side_z: float = lane + 0.66 * sin((x + 39.0) / 78.0 * TAU * 1.3 + lane * 0.08)
			if abs(x - side_x) < 1.72 or abs(z - side_z) < 1.72:
				return -100.0
	for gx in range(-1, 2):
		for gz in range(-1, 2):
			var local := Vector2(x - gx * 22.0, z - gz * 22.0)
			if abs(local.x) <= 9.1 and abs(local.y) <= 9.1:
				if abs(local.x) > 8.55 or abs(local.y) > 8.55:
					return -100.0
				var style := (gx + 1) * 3 + gz + 1
				var offset := float(style % 3) * 0.48
				for bx in [-4.8, -0.6]:
					for bz in [-4.1, 0.6]:
						if abs(local.x - bx - offset) < 1.72 and abs(local.y - bz) < 1.87:
							return -100.0
				# Shed/greenhouse footprint, tree, stall, and ornamental planter.
				if abs(local.x - 4.85) < 2.0 and abs(local.y + 1.35) < 2.4:
					return -100.0
				if abs(local.x - 5.6) < 1.65 and abs(local.y - 5.8) < 0.85:
					return -100.0
				if local.distance_to(Vector2(5.7, -5.8)) < 0.45:
					return -100.0
				if style % 2 != 0 and local.distance_to(Vector2(-3.3, 6.8)) < 0.9:
					return -100.0
				return 0.076
	# Park stepping stones and tree trunks.
	for i in range(12):
		var angle := float(i) * TAU / 12.0
		if Vector2(x, z).distance_to(Vector2(34.0 + cos(angle) * 5.4, -11.0 + sin(angle) * 5.4)) < 0.73:
			return -100.0
	if Vector2(x, z).distance_to(Vector2(34, -11)) < 0.45:
		return -100.0
	return -0.104

func _make_clump() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_color(Color.WHITE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91043
	# Ten tapered, bent blades per clump: no billboards or alpha overdraw.
	for blade in range(10):
		var angle := rng.randf() * TAU
		var across := Vector3(cos(angle), 0, sin(angle))
		var lean := Vector3(-sin(angle), 0, cos(angle)) * rng.randf_range(0.015, 0.05)
		var root := Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12))
		var h := rng.randf_range(0.08, 0.15)
		var w := rng.randf_range(0.012, 0.021)
		var points := [root-across*w, root+across*w, root+Vector3(0,h*0.58,0)+lean*0.35-across*w*0.58, root+Vector3(0,h*0.58,0)+lean*0.35+across*w*0.58, root+Vector3(0,h,0)+lean]
		var uvs := [Vector2(0,0),Vector2(1,0),Vector2(0,0.58),Vector2(1,0.58),Vector2(0.5,1)]
		for index in [0, 2, 1, 1, 2, 3, 2, 4, 3]:
			surface.set_uv(uvs[index])
			surface.add_vertex(points[index])
	surface.generate_normals()
	return surface.commit()
