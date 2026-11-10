extends SceneTree
const Art := preload("res://assets/garden_art/garden_library.gd")
const Builder := preload("res://assets/garden_art/mesh_builder.gd")
const Gallery := preload("res://staging/garden_art_gallery.gd")
const Plants := ["rose","sunflower","lavender","hydrangea","cosmos","daisy","basil"]
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var builder := Builder.new()
	builder.box(Vector3.ZERO,Vector3.ONE,.04,4,Color.WHITE)
	var box_data := builder.mesh().surface_get_arrays(0)
	for index in range(box_data[Mesh.ARRAY_VERTEX].size()):
		assert(box_data[Mesh.ARRAY_VERTEX][index].dot(box_data[Mesh.ARRAY_NORMAL][index]) > .1,"Closed box normals must face outward")
	var total := 0
	for id in Gallery.COLLECTION:
		for stage in range(5) if id in Plants else [4]:
			var meshes := Art.meshes(id,stage)
			assert(meshes.size() == 3)
			assert(meshes[0] == Art.meshes(id,stage)[0],"Repeated instances must share resources")
			var previous := 1000000
			for mesh in meshes:
				var triangles := 0
				assert(mesh.get_surface_count() > 0)
				assert(mesh.get_aabb().size.length() > .001)
				for surface in range(mesh.get_surface_count()):
					assert(mesh.surface_get_material(surface) != null)
					var data := mesh.surface_get_arrays(surface)
					assert(data[Mesh.ARRAY_VERTEX].size() == data[Mesh.ARRAY_NORMAL].size())
					assert(data[Mesh.ARRAY_VERTEX].size() == data[Mesh.ARRAY_TEX_UV].size())
					for v in data[Mesh.ARRAY_VERTEX]: assert(v.is_finite())
					for n in data[Mesh.ARRAY_NORMAL]: assert(n.is_finite() and n.length() > .9)
					for index in data[Mesh.ARRAY_INDEX]: assert(index >= 0 and index < data[Mesh.ARRAY_VERTEX].size())
					triangles += mesh.surface_get_array_index_len(surface)/3
				assert(triangles <= previous,"LOD must reduce geometry: "+id)
				assert(triangles < 40000,"Asset triangle budget exceeded: "+id)
				previous = triangles
			var model := Art.instance(id)
			root.add_child(model)
			var count: int = Art.add_collision(model)
			if id in ["bench","rose_arch","fountain","lantern","trellis","planter","watering_can","tree","cypress","hedge","shed","greenhouse","stall","bed","central_planter"]: assert(count > 0,"Missing collision: "+id)
			var first_count := model.get_child_count()
			Art.add_collision(model)
			assert(model.get_child_count() == first_count,"Collision must be idempotent")
			model.free()
			total += 1
	Builder.set_reduced_motion(true)
	assert(Builder.material(1).get_shader_parameter("motion") == 0.0)
	Builder.set_reduced_motion(false)
	print("PASS garden art: ",total," asset/stage combinations; three shared LODs, finite UV/normals/indices, materials, collision and motion settings")
	quit()
