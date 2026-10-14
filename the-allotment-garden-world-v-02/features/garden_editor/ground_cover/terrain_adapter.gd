extends RefCounted
## Samples the existing garden mesh, including slopes. No terrain changes.
var triangles: Array[PackedVector3Array] = []
var obstacles: Array[Rect2] = []
var target: Node3D
var bounds := Rect2()
var outline := PackedVector2Array()
var flat_height := NAN
var shared_boundaries: Array[PackedVector2Array] = []

func from_garden(garden: Node3D) -> void:
	target = garden
	var lawn := garden.get_node("WedgeGround") as MeshInstance3D
	var raw_vertices: PackedVector3Array = lawn.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var vertices := PackedVector3Array()
	for vertex in raw_vertices: vertices.append(garden.to_local(lawn.to_global(vertex)))
	triangles.clear()
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for i in range(0, vertices.size(), 3):
		var tri := PackedVector3Array()
		for j in range(3):
			var v: Vector3 = vertices[i + j]
			tri.append(v)
			low = low.min(Vector2(v.x, v.z))
			high = high.max(Vector2(v.x, v.z))
		triangles.append(tri)
	bounds = Rect2(low, high - low)
	var inner := PackedVector2Array()
	var outer := PackedVector2Array()
	for i in range(0, vertices.size(), 6):
		if i == 0:
			inner.append(Vector2(vertices[i].x, vertices[i].z))
			outer.append(Vector2(vertices[i + 2].x, vertices[i + 2].z))
		inner.append(Vector2(vertices[i + 4].x, vertices[i + 4].z))
		outer.append(Vector2(vertices[i + 1].x, vertices[i + 1].z))
	outer.reverse()
	outline = inner + outer
	shared_boundaries.append(PackedVector2Array([inner[0],outer[-1]]))
	shared_boundaries.append(PackedVector2Array([inner[-1],outer[0]]))
	flat_height = vertices[0].y
	for v in vertices:
		if not is_equal_approx(v.y, flat_height):
			flat_height = NAN
			break
	_gather_obstacles(garden)

func _gather_obstacles(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var size: Vector3 = child.mesh.size
			if minf(size.x, size.z) > 0.4 and size.y > 0.15:
				var box: AABB = child.get_aabb()
				var low := Vector2(INF, INF)
				var high := Vector2(-INF, -INF)
				for i in range(8):
					var v: Vector3 = target.to_local(child.to_global(box.get_endpoint(i)))
					low = low.min(Vector2(v.x, v.z))
					high = high.max(Vector2(v.x, v.z))
				obstacles.append(Rect2(low, high - low).grow(0.15))
		_gather_obstacles(child)

func sample_height(point: Vector2) -> float:
	if is_finite(flat_height):
		return flat_height if Geometry2D.is_point_in_polygon(point, outline) else NAN
	for tri in triangles:
		var a := Vector2(tri[0].x, tri[0].z)
		var b := Vector2(tri[1].x, tri[1].z)
		var c := Vector2(tri[2].x, tri[2].z)
		var denom := (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
		if absf(denom) < 0.000001: continue
		var u := ((b.y - c.y) * (point.x - c.x) + (c.x - b.x) * (point.y - c.y)) / denom
		var v := ((c.y - a.y) * (point.x - c.x) + (a.x - c.x) * (point.y - c.y)) / denom
		if u >= -0.000001 and v >= -0.000001 and u + v <= 1.000001:
			return tri[0].y * u + tri[1].y * v + tri[2].y * (1.0 - u - v)
	return NAN

func contains(point: Vector2) -> bool:
	if not bounds.has_point(point) or not is_finite(sample_height(point)): return false
	for edge in shared_boundaries:
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point, edge[0], edge[1])) < 0.75: return false
	for obstacle in obstacles:
		if obstacle.has_point(point): return false
	return true

func pick(camera: Camera3D, screen_point: Vector2) -> Variant:
	var inverse := target.global_transform.affine_inverse()
	var origin: Vector3 = inverse * camera.project_ray_origin(screen_point)
	var direction: Vector3 = inverse.basis * camera.project_ray_normal(screen_point)
	var nearest = null
	var distance := INF
	for tri in triangles:
		var hit = Geometry3D.ray_intersects_triangle(origin, direction, tri[0], tri[1], tri[2])
		if hit != null and origin.distance_squared_to(hit) < distance:
			distance = origin.distance_squared_to(hit)
			nearest = Vector2(hit.x, hit.z)
	return nearest
