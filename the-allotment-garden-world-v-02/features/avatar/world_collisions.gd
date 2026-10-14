extends RefCounted
## Add physics to existing visuals without replacing or moving world content.
static func install(node: Node) -> int:
	var count := 0
	for child in node.get_children(): count += install(child)
	if not node is MeshInstance3D or node.has_node("PlayerCollision"): return count
	var shape: Shape3D
	if node.name in ["NeighborhoodGround","WedgeGround","StonePaving"]:
		shape = node.mesh.create_trimesh_shape()
		if shape is ConcavePolygonShape3D: shape.backface_collision = true
	elif node.mesh is BoxMesh:
		var box := BoxShape3D.new()
		box.size = node.mesh.size
		shape = box
	elif node.mesh is CylinderMesh and node.mesh.top_radius >= .18 and node.mesh.height > .2:
		var cylinder := CylinderShape3D.new()
		cylinder.radius = maxf(node.mesh.top_radius,node.mesh.bottom_radius)
		cylinder.height = node.mesh.height
		shape = cylinder
	if shape == null: return count
	var body := StaticBody3D.new()
	body.name = "PlayerCollision"
	body.collision_layer = 1
	body.collision_mask = 2
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	node.add_child(body)
	return count+1
