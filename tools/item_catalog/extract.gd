extends SceneTree
## Offline audit of actual evaluated GDScript constants, without reading saves.
const Catalog = preload("res://features/market/catalog.gd")
const Growth = preload("res://features/market/plant_growth.gd")
const Art = preload("res://assets/garden_art/garden_library.gd")
const Stack = preload("res://features/market/stack_rules.gd")
const Model = preload("res://features/market/item_model.tscn")

func plain(value: Variant) -> Variant:
	if value is Vector3: return [value.x,value.y,value.z]
	if value is Vector2: return [value.x,value.y]
	if value is Color: return value.to_html()
	if value is Dictionary:
		var result := {}
		for key in value: result[str(key)] = plain(value[key])
		return result
	if value is Array:
		var result := []
		for item in value: result.append(plain(item))
		return result
	return value

func _initialize() -> void:
	call_deferred("extract")

func extract() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(1)
		return
	var collections := {
		"base": [Catalog.BASE_ITEMS,"features/market/catalog.gd"],
		"climbing": [Catalog.CLIMBING_ITEMS,"features/market/catalog.gd"],
		"woody": [Catalog.WOODY_ITEMS,"features/market/catalog.gd"],
		"french": [Art.French.CATALOG,"assets/garden_art/french_collection.gd"],
		"roman": [Art.Roman.CATALOG,"assets/garden_art/roman_collection.gd"],
		"enchanted": [Art.Enchanted.CATALOG,"assets/garden_art/enchanted_collection.gd"],
		"rustic": [Art.Rustic.CATALOG,"assets/garden_art/rustic_collection.gd"],
		"woodland": [Art.Woodland.CATALOG,"assets/garden_art/woodland_collection.gd"]}
	var listings := []
	var seen := {}
	for collection in collections:
		var data: Array = collections[collection]
		for original in data[0]:
			var ids := [str(original.id)]
			if Growth.PLANTS.has(original.id):
				for suffix in ["@seed","@seedling","@young"]: ids.append(original.id+suffix)
			for id in ids:
				if seen.has(id):
					push_error("Duplicate actual shop ID: "+id)
					quit(1)
					return
				seen[id] = true
				var resolved: Dictionary = Catalog.by_id(id)
				var model = Model.instantiate()
				model.item_id = id
				if id == Catalog.ATRIUM.ID: model.set_meta("placement_record",{})
				root.add_child(model)
				var bounds: AABB = model.mesh_bounds()
				var icon: Texture2D = Catalog.icon(resolved)
				var icon_data := {"path":icon.resource_path}
				if icon is AtlasTexture:
					icon_data = {"path":icon.atlas.resource_path,"region":[icon.region.position.x,icon.region.position.y,icon.region.size.x,icon.region.size.y]}
				var art_id: String = str(Growth.species(id)) if not Growth.species(id).is_empty() else str(id)
				if Growth.Woody.PROFILES.has(art_id): art_id += "@growing"
				var surfaces := []
				for mesh_node in model.find_children("*","MeshInstance3D",true,false):
					var mesh: Mesh = mesh_node.mesh
					var materials := []
					for surface in range(mesh.get_surface_count()):
						var material := mesh.surface_get_material(surface)
						var role_id := -1
						for role in Art.Builder.materials:
							if Art.Builder.materials[role] == material: role_id = int(role)
						materials.append({"surface":surface,"role_id":role_id,"path":material.resource_path if material else "","class":material.get_class() if material else "none"})
					surfaces.append({"node":str(mesh_node.name),"surface_count":mesh.get_surface_count(),"materials":materials})
				Art.add_collision(model)
				var collisions := []
				for shape_node in model.find_children("*","CollisionShape3D",true,false):
					var shape: Shape3D = shape_node.shape
					var size := Vector3.ZERO
					if shape is BoxShape3D: size = shape.size
					elif shape is CylinderShape3D: size = Vector3(shape.radius*2,shape.height,shape.radius*2)
					elif shape is SphereShape3D: size = Vector3.ONE*shape.radius*2
					elif shape is CapsuleShape3D: size = Vector3(shape.radius*2,shape.height,shape.radius*2)
					collisions.append({"shape":shape.get_class(),"dimensions_m":plain(size*shape_node.global_transform.basis.get_scale()),
						"position_m":plain(shape_node.global_position-model.global_position),"rotation_radians":plain(shape_node.global_rotation)})
				listings.append({"id":id,"original":plain(original),"resolved":plain(resolved),"collection":collection,
					"source":data[1],"dimensions_m":plain(bounds.size),"pivot_m":plain(bounds.position),
					"mature_dimensions_m":plain(Stack.size(id)),"stack_top":plain(Stack.top(id)),"stack_foot":plain(Stack.foot(id)),
					"can_stack":Stack.can_stack(id),"icon":icon_data,"model_recipe":art_id,"surfaces":surfaces,
					"collision_shapes":collisions,
					"gate_controller":model.find_child("GateController",true,false)!=null,
					"glow_controller":model.find_child("EnchantedGlow",true,false)!=null})
				model.free()
	var recipes := []
	for id in ["central_planter","shed","greenhouse","stall","bed","tree","cypress","hedge","shrub","iron_gate_leaf","timber_gate_leaf","chateau_gate_leaf","potager_gate_leaf","branch_gate_leaf"]:
		var meshes: Array = Art.meshes(id)
		recipes.append({"id":id,"dimensions_m":plain(meshes[0].get_aabb().size),"lod_count":meshes.size(),"source":"assets/garden_art/garden_library.gd"})
	var file := FileAccess.open(args[0],FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify({"schema_version":"1.0.0","shop":listings,"recipes":recipes,"growth_ids":Growth.PLANTS.keys()},"\t"))
	file.close()
	print("PASS: extracted ",listings.size()," real shop definitions/variants and ",recipes.size()," scenery/component recipes")
	quit(0)
