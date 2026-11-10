extends SceneTree
const Art := preload("res://assets/garden_art/garden_library.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Model := preload("res://features/market/item_model.tscn")
const Border := preload("res://features/market/boundary_placement.gd")
func _initialize() -> void: call_deferred("verify")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func verify() -> void:
	for id in Art.Boundary.IDS:
		var item := Catalog.by_id(id)
		assert(Catalog.placeable(item) and item.price == 0)
		assert(Catalog.icon(item) != null)
		var model := Model.instantiate()
		model.item_id = id
		root.add_child(model)
		var size: Vector3 = model.mesh_bounds().size
		assert(size.is_equal_approx(Art.Boundary.SIZES[id]),"Incorrect boundary dimensions: "+id+str(size))
		assert(Art.add_collision(model) > 0)
		if id in ["garden_gate","timber_gate"]:
			var controller = model.get_node("GateController")
			assert(controller.left.has_node("GateLeafCollision"))
			assert(controller.right.has_node("GateLeafCollision"))
			controller.auto_open = false
			controller.set_open(true)
			await frames(60)
			assert(absf(controller.left.rotation.y) > 1.6 and absf(controller.right.rotation.y) > 1.6)
			controller.set_open(false)
			await frames(60)
			assert(absf(controller.left.rotation.y) < .01)
		model.free()
	for angle in [0.0,PI/2,PI/4]:
		var end := Vector2(2,0).rotated(-angle)
		assert(not Border.overlap("rock_wall",Vector2.ZERO,angle,"rock_wall",end,angle))
		assert(Border.overlap("rock_wall",Vector2.ZERO,angle,"rock_wall",end*.6,angle))
		var records := [{"id":"rock_wall","x":0,"z":0,"angle":angle,"area":"garden"}]
		assert(Border.snap("rock_wall",end+Vector2(.12,.08),angle,records,"garden").is_equal_approx(end))
		assert(Border.snap("rock_wall",end+Vector2(.12,.08),angle,records,"courtyard").is_equal_approx(end+Vector2(.12,.08)))
	assert(Border.overlap("garden_gate",Vector2.ZERO,0,"rock_wall",Vector2(0,.8),0),"Gate swing area must stay clear")
	assert(not Border.overlap("garden_gate",Vector2.ZERO,0,"rock_wall",Vector2(2.5,0),0))
	# Actual walking and physics, with the existing authored gardener.
	var floor := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20,.2,20)
	shape.shape = box
	shape.position.y = -.1
	floor.add_child(shape)
	root.add_child(floor)
	for id in ["garden_gate","timber_gate"]:
		var gate := Model.instantiate()
		gate.item_id = id
		root.add_child(gate)
		Art.add_collision(gate)
		var player = load("res://features/avatar/garden_player.tscn").instantiate()
		player.position = Vector3(.25,.05,2.6)
		player.use_requested_direction = true
		root.add_child(player)
		player.requested_direction = Vector2(0,-1)
		await frames(140)
		assert(player.position.z < -2.5,"Gate blocked walking: "+id+str(player.position))
		assert(gate.get_node("GateController").opened,"Gate should stay open near walking player")
		player.requested_direction = Vector2.ZERO
		player.position.z = -6
		await frames(190)
		assert(not gate.get_node("GateController").opened and gate.get_node("GateController").amount < .01,"Gate failed to close after the gardener left")
		player.free()
		gate.free()
	floor.free()
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var placement = world.market_garden
	assert(placement.begin("rock_wall","garden"))
	var found := false
	for z in range(35,80,3):
		if found: break
		for x in range(-8,9,3):
			var point := Vector2(x,z)
			if not placement.allowed("rock_wall",point) or not placement.allowed("rock_wall",point+Vector2(2,0)): continue
			assert(placement.place_at(point))
			assert(placement.allowed("rock_wall",point+Vector2(2,0)),"Touching modular walls must join")
			assert(placement.place_at(point+Vector2(2,0)))
			assert(not placement.allowed("rock_wall",point+Vector2(.8,0)),"Overlapping walls must be rejected")
			found = true
			break
	assert(found)
	placement.finish()
	assert(placement.begin("garden_gate","garden"))
	found = false
	for z in range(40,90,4):
		if found: break
		for x in range(-8,9,4):
			var point := Vector2(x,z)
			if placement.allowed("garden_gate",point):
				assert(placement.place_at(point))
				found = true
				break
	assert(found)
	placement.finish()
	placement.reload_items()
	await process_frame
	assert(placement.roots.garden.get_child_count() == 3,"New boundary placements failed to restore")
	var restored = placement.roots.garden.get_child(2)
	assert(restored.item_id == "garden_gate" and restored.get_node("GateController").left.has_node("GateLeafCollision"))
	world.free()
	print("PASS: five free shop boundaries, metre bounds, connected walls at three angles, gate swing protection, animated collision and walking through both automatic gates")
	quit()
