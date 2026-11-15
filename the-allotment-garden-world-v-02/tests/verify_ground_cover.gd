extends SceneTree
const Store := preload("res://features/garden_editor/ground_cover/surface_store.gd")
const Adapter := preload("res://features/garden_editor/ground_cover/terrain_adapter.gd")
var events: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_verify")

func _height(point: Vector2) -> float:
	return 0.1 * point.x + 0.04 * point.y

func _verify() -> void:
	var store := Store.new()
	root.add_child(store)
	var obstacles: Array[Rect2] = [Rect2(-1,-1,2,2)]
	store.configure("automated_test", "owner", "owner", 1234, Rect2(-12,-12,24,24), func(point: Vector2) -> bool: return point.x >= -12 and point.x <= 12 and point.y >= -12 and point.y <= 12, _height, obstacles)
	store.operation_committed.connect(func(operation: Dictionary) -> void: events.append(operation))
	assert(store.catalog.entries.size() == 83)
	assert(store.catalog.categories.size() == 7)
	var appearances: Dictionary = {}
	for entry in store.catalog.entries:
		var style: Dictionary = store.catalog.default_style(entry.material_id)
		assert(not store.catalog.validate_style(style).is_empty())
		var material := store.catalog.material_for(style)
		assert(material == store.catalog.material_for(style))
		appearances[entry.material_id] = style
	var brick: Dictionary = appearances.brick.duplicate(true)
	brick.base = "cc5533ff"
	brick.joint = "f5e7caff"
	brick.accent = "467a9bff"
	brick.rotation = 45.0
	brick.glow_enabled = true
	brick.glow_color = "a566ffff"
	brick.glow_secondary = "44ddffff"
	brick.glow_palette = 1
	brick.glow_mode = 3
	brick.detail_id = "moss"
	brick.detail_amount = 0.8
	var material := store.catalog.material_for(brick)
	assert(material.get_shader_parameter("base_color") == Color.html(brick.base))
	assert(material.get_shader_parameter("surface_roughness") == brick.roughness)
	store.catalog.set_night(1)
	assert(material.get_shader_parameter("night_amount") == 1.0)
	store.catalog.set_night(0)
	assert(material.get_shader_parameter("night_amount") == 0.0)
	assert(material.get_shader_parameter("base_color") == Color.html(brick.base))
	# A whole stroke is one history entry; erase cannot touch a protected structure.
	store.begin_stroke()
	store.apply_shape({"type":"brush", "points":[Vector2(-6,0)], "width":3.0}, brick)
	store.apply_shape({"type":"line", "points":[Vector2(-6,0),Vector2(6,0)], "width":3.0}, brick)
	assert(store.commit_stroke())
	assert(store.undo_stack.size() == 1 and events.size() == 1)
	assert(store.cells.size() > 0)
	for key in store.cells:
		var cell: Vector2i = store._coord(key)
		assert(not Rect2(Vector2(cell)*0.5, Vector2.ONE*0.5).intersects(obstacles[0], true))
	var stroke_snapshot := store.snapshot()
	store.undo()
	assert(store.cells.is_empty())
	store.redo()
	assert(store.snapshot() == stroke_snapshot)
	# Edging differs from the main surface and survives exact save/load.
	var tile: Dictionary = appearances.basic_tile.duplicate(true)
	tile.base = "e9e5dcff"
	var border: Dictionary = appearances.glowing_pebbles.duplicate(true)
	border.glow_color = "ffaa66ff"
	store.apply_shape({"type":"rectangle", "points":[Vector2(3,3),Vector2(7,7)]}, tile, "paint", {"style":border,"width":1.0})
	assert(store.sample_style(Vector2(5,5)).material_id == "basic_tile")
	assert(store.sample_style(Vector2(7.5,5)).material_id == "glowing_pebbles")
	# Circle rasterization must cover all quadrants, not just the click bounding box.
	store.apply_shape({"type":"circle", "points":[Vector2(-6,-6),Vector2(-3,-6)]}, appearances.moss)
	for point in [Vector2(-8,-6),Vector2(-4,-6),Vector2(-6,-8),Vector2(-6,-4)]: assert(store.sample_style(point).material_id == "moss")
	store.apply_shape({"type":"curve", "points":[Vector2(-9,8),Vector2(-5,5),Vector2(-2,8)], "width":1.0}, appearances.cobblestone)
	assert(not store.sample_style(Vector2(-5,5)).is_empty())
	# Recolor keeps the original material identity and finish detail.
	var recolor: Dictionary = tile.duplicate(true)
	recolor.base = "4499bbff"
	store.apply_shape({"type":"brush", "points":[Vector2(-6,-6)], "width":2.0}, recolor, "recolor")
	assert(store.sample_style(Vector2(-6,-6)).material_id == "moss")
	assert(store.sample_style(Vector2(-6,-6)).base == recolor.base)
	var previous := store.snapshot()
	store.begin_stroke()
	store.apply_shape({"type":"brush", "points":[Vector2(-6,-6)], "width":2.0}, {}, "erase")
	store.cancel_stroke()
	assert(store.snapshot() == previous)
	# Geometry conforms to the height function; UVs stay in metres across chunks.
	store.flush_meshes()
	for chunk in store.chunk_nodes.values():
		for child in chunk.get_children():
			var arrays: Array = child.mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			for i in range(vertices.size()):
				var point := Vector2(vertices[i].x,vertices[i].z)
				assert(absf(vertices[i].y - (_height(point) + 0.025)) < 0.0001)
				assert(uvs[i].distance_to(point) < 0.0001)
	assert(store.save_to("user://ground_cover/automated_test_roundtrip.json"))
	var saved := store.snapshot()
	store.apply_shape({"type":"brush", "points":[Vector2(5,5)], "width":2.0}, {}, "erase")
	assert(store.load_from("user://ground_cover/automated_test_roundtrip.json"))
	assert(store.snapshot() == saved)
	# Invalid saves are rejected atomically; no partial changes or cross-owner reads.
	var wrong := saved.duplicate(true)
	wrong.context_id = "another_garden"
	assert(not store.restore_snapshot(wrong) and store.snapshot() == saved)
	wrong = saved.duplicate(true)
	wrong.world_seed = 999
	assert(not store.restore_snapshot(wrong) and store.snapshot() == saved)
	wrong = saved.duplicate(true)
	wrong.cells.append([999,999,0])
	assert(not store.restore_snapshot(wrong) and store.snapshot() == saved)
	wrong = saved.duplicate(true)
	wrong.styles[0].base = "not-a-color"
	assert(not store.restore_snapshot(wrong) and store.snapshot() == saved)
	var history_size := store.undo_stack.size()
	store.actor_id = "visitor"
	assert(store.apply_shape({"type":"brush", "points":[Vector2(5,5)],"width":5.0}, brick) == 0)
	assert(not store.undo() and not store.redo() and not store.save_to())
	assert(not store.load_from("user://ground_cover/automated_test_roundtrip.json"))
	assert(store.snapshot() == saved and store.undo_stack.size() == history_size)
	store.actor_id = "owner"
	# An ownership change during a stroke cancels edits rather than committing them.
	store.begin_stroke()
	store.apply_shape({"type":"brush", "points":[Vector2(5,5)],"width":2.0}, brick)
	store.actor_id = "visitor"
	assert(not store.commit_stroke() and store.snapshot() == saved)
	store.actor_id = "owner"
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ground_cover/automated_test_roundtrip.json"))
	store.queue_free()
	await process_frame
	# Real integration uses only Garden 01, keeping neighbors and structures intact.
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.open_ground_editor()
	var session = world.ground_editor_session
	assert(session.active and session.store.can_edit())
	assert(session.terrain.obstacles.size() > 0)
	for index in range(2,10): assert(not world.get_node("Garden_%02d" % index).has_node("GroundCovers"))
	var count: int = session.store.apply_shape({"type":"circle","points":[Vector2(0,75),Vector2(30,75)]}, session.panel.style)
	assert(count > 0)
	for key in session.store.cells: assert(session.store._cell_allowed(session.store._coord(key)))
	session.panel._select_tool("curve")
	session._click(Vector2(0,60))
	session._click(Vector2(8,70))
	session._click(Vector2(0,80))
	var before_curve: int = session.store.undo_stack.size()
	session.finish_curve()
	assert(session.pending.is_empty())
	assert(session.store.undo_stack.size() >= before_curve)
	session.close()
	assert(not session.active and world.get_node("GameHUD").visible)
	world.queue_free()
	await process_frame
	print("PASS: 83 materials, color/glow parameters, all shapes, borders, terrain conformity, strokes, undo/redo, save roundtrip, malformed saves, owner guards, real wedge confinement and editor integration")
	quit()
