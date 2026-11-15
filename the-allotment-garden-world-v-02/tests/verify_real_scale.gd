extends SceneTree
const Growth := preload("res://features/market/plant_growth.gd")
const Model := preload("res://features/market/item_model.tscn")
const ACRE_M2 := 4046.8564224

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var count := 0
	for garden in world.get_children():
		if not str(garden.name).begins_with("Garden_"): continue
		var lawn: MeshInstance3D = garden.get_node("WedgeGround")
		var vertices: PackedVector3Array = lawn.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var area := 0.0
		for i in range(0,vertices.size(),3):
			var a: Vector3 = lawn.to_global(vertices[i])
			var b: Vector3 = lawn.to_global(vertices[i+1])
			var c: Vector3 = lawn.to_global(vertices[i+2])
			area += (b-a).cross(c-a).length()*.5
		assert(absf(area-1.84*ACRE_M2) < .2,"World-space mesh acreage is wrong")
		assert(lawn.global_basis.get_scale().is_equal_approx(Vector3.ONE))
		print("MEASURED ",garden.name,": ",area," m² = ",area/ACRE_M2," acres")
		count += 1
	assert(count == 9)
	var paving: MeshInstance3D = world.get_node("CircularCourtyard/StonePaving")
	var faces: PackedVector3Array = paving.mesh.get_faces()
	var paving_area := 0.0
	for i in range(0,faces.size(),3):
		var a: Vector3 = paving.to_global(faces[i])
		var b: Vector3 = paving.to_global(faces[i+1])
		var c: Vector3 = paving.to_global(faces[i+2])
		if absf(a.y-.125) > .001 or absf(b.y-.125) > .001 or absf(c.y-.125) > .001: continue
		paving_area += (b-a).cross(c-a).length()*.5
	assert(paving_area > 2120 and paving_area < 2125)
	print("MEASURED shared stone circle: ",paving_area," m² = ",paving_area/ACRE_M2," acres")
	print("MEASURED radial depth: ",world.outer_radius-world.INNER_RADIUS," m; outer chord: ",2*world.outer_radius*sin(PI/9)," m")
	print("MEASURED player collision height: ",world.player.get_node("CollisionShape3D").shape.height," m")
	for plant in Growth.PLANTS:
		var model := Model.instantiate()
		model.item_id = plant
		root.add_child(model)
		var size: Vector3 = model.mesh_bounds().size
		assert(absf(size.y-float(Growth.PLANTS[plant].height)) < .001)
		assert(absf(size.x-float(Growth.PLANTS[plant].width)) < .001)
		print("MEASURED ",plant,": ",size," m")
		model.free()
	world.queue_free()
	await process_frame
	print("PASS: world-space areas, unscaled metre geometry, avatar reference and measured mature plant dimensions")
	quit()
