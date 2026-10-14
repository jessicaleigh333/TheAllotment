extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.has_node("CircularCourtyard"))
	assert(game.has_node("GameHUD"))
	var gardens: Array[Node3D] = []
	for child in game.get_children():
		if str(child.name).begins_with("Garden_"):
			gardens.append(child)
	assert(gardens.size() == 9)
	var expected_area := 1.84 * 4046.8564224
	for garden in gardens:
		assert(garden.has_node("SharedHedge"))
		assert(garden.get_node("SharedHedge").get_child_count() > 0)
		assert(not garden.has_node("SharedStoneLane"))
		var lawn := garden.get_node("WedgeGround") as MeshInstance3D
		var arrays := lawn.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var area := 0.0
		for i in range(0, vertices.size(), 3):
			area += (vertices[i + 1] - vertices[i]).cross(vertices[i + 2] - vertices[i]).length() / 2.0
		assert(absf(area - expected_area) < 0.2, "Rendered acreage differs from 1.84 acres")
		assert(absf(float(garden.get_meta("area_acres")) - 1.84) < 0.0001)
		for vertex in vertices:
			var radius := Vector2(vertex.x, vertex.z).length()
			assert(radius >= 31.99 and radius <= game.outer_radius + 0.01)
			assert(absf(atan2(vertex.x, vertex.z)) <= game.WEDGE_ANGLE / 2.0 + 0.0001)
		var entrance := garden.get_node("Entrance") as Marker3D
		assert(entrance.global_basis.z.dot(-entrance.global_position.normalized()) > 0.999)
		for other in gardens:
			if garden == other: continue
			var separation := absf(wrapf(garden.rotation.y - other.rotation.y, -PI, PI))
			assert(separation + 0.0001 >= game.WEDGE_ANGLE, "Wedge sectors overlap")
	game.set_walking_mode(false)
	var reset := InputEventKey.new()
	reset.keycode = KEY_R
	reset.pressed = true
	game.distance = 20.0
	game._unhandled_input(reset)
	assert(game.distance == 390.0)
	game.queue_free()
	await process_frame
	var staging = load("res://staging/asset_staging.tscn").instantiate()
	var sample := Node3D.new()
	staging.get_node("AssetSlots/Slot01").add_child(sample)
	root.add_child(staging)
	await process_frame
	assert(staging.get_node("AssetSlots").get_child_count() == 9)
	assert(not staging.has_node("CircularCourtyard"))
	assert(not staging.has_node("GameHUD"))
	assert(not staging.get_node("Plot_1_1").visible)
	assert(staging.get_node("Plot_1_2").visible)
	staging.queue_free()
	await process_frame
	print("PASS: nine non-overlapping inward-facing 1.84-acre wedges (actual mesh areas), hedge dividers without paved lanes, courtyard, main HUD, camera reset and separate staging slots")
	quit()
