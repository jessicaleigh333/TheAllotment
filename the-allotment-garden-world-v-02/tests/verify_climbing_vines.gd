extends SceneTree
const Vines := preload("res://features/market/climbing_vines.gd")
const Growth := preload("res://features/market/plant_growth.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Art := preload("res://assets/garden_art/garden_library.gd")
func _initialize() -> void: call_deferred("verify")
func verify() -> void:
 var start := 1700000000.0
 for id in Vines.REACH:
  for suffix in ["@seed","@seedling","@young",""]:
   var entry := Catalog.by_id(id+suffix)
   assert(Catalog.placeable(entry) and entry.price == 0 and Catalog.icon(entry) != null)
  var record := {"id":id+"@seed","growth":Growth.new_record(id+"@seed",start)}
  assert(Growth.age_days(record,start+86400) == 1.,"Exactly one real day")
  assert(Growth.state(id,Growth.age_days(record,start+3600)).stage == 0)
  assert(Growth.state(id,Growth.age_days(record,start+Growth.PLANTS[id].days[4]*86400)).stage == 4)
  record.growth.observed_age_days = 10.
  assert(Growth.age_days(record,start-86400) == 10.,"No backwards growth")
 for id in Vines.REACH:
  var previous := 2147483647
  for detail in range(3):
   var builder := Art.Builder.new(detail)
   Vines.VineArt.trained(builder,id,PackedVector3Array([Vector3.ZERO,Vector3(0,8,0)]),Vines.REACH[id],4)
   var mesh := builder.mesh()
   var triangles := 0
   for surface in range(mesh.get_surface_count()):
    triangles += mesh.surface_get_array_index_len(surface)/3
    var arrays := mesh.surface_get_arrays(surface)
    for normal in arrays[Mesh.ARRAY_NORMAL]: assert(normal.is_finite() and normal.length() > .9)
   assert(triangles < 40000 and triangles <= previous,"Trained vine detail budget: "+id)
   previous = triangles
 var uid := "111111111111111111111111"
 for id in ["trellis","branch_trellis","rustic_arbor","fairy_light_arbor","vine_pergola","lantern_picnic_canopy","sheltered_workbench","woodland_potting_station","twig_obelisk","willow_teepee_planter","corinthian_column"]:
  for angle in [0.,PI/4,PI/2]:
   var support := {"id":id,"x":4.,"z":60.,"angle":angle,"uid":uid,"ground_y":.1,"area":"garden"}
   var path := Vines.world_route(support,Vines.routes(id)[0],[support])
   var point: Vector3 = path[0]+Vector3(0,0,-.6).rotated(Vector3.UP,angle)
   var plant := {"id":"clematis","x":point.x,"z":point.z,"ground_y":.1,"area":"garden"}
   assert(Vines.attachment(plant,[support]).get("uid") == uid,"Rotated support not found: "+id)
   plant.area = "courtyard"
   assert(Vines.attachment(plant,[support]).is_empty())
   plant.area = "garden"
   plant.ground_y = 2.
   assert(Vines.attachment(plant,[support]).is_empty(),"Do not bridge vertical gaps")
 assert(Vines.routes("log_bench").is_empty())
 assert(not Vines.root_clear({"id":"woodland_potting_station","x":0.,"z":0.,"angle":0.},Vector3(1.05,0,.2)),"Roots cannot occupy a worktable interior")
 var base := {"id":"roman_plinth","x":0.,"z":0.,"angle":0.,"ground_y":0.,"uid":uid}
 var shaft := {"id":"corinthian_column","x":0.,"z":0.,"angle":0.,"ground_y":0.,"elevation":Art.Roman.SIZES.roman_plinth.y,"uid":"222222222222222222222222"}
 var stack_path := Vines.world_route(base,Vines.routes(base.id)[0],[base,shaft])
 assert(stack_path[-1].y > Art.Roman.SIZES.corinthian_column.y)
 var world = load("res://main.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var placement = world.market_garden
 assert(placement.begin("trellis","garden"))
 assert(placement.place_at(Vector2(0,60)))
 placement.finish()
 assert(placement.begin("clematis@seed","garden"))
 var point := Vector2(.575,60.55)
 assert(placement.allowed("clematis@seed",point),"Planting beside compatible support must be allowed")
 assert(not placement.allowed("clematis@seed",Vector2(0,60)),"Support interior must remain protected")
 assert(placement.place_at(point))
 placement.finish()
 var model = placement.roots.garden.get_child(1)
 assert(model.current_stage == 0 and not model.has_node("ClimbingGrowth"))
 var planted: float = placement.store.data.placed[1].growth.started_at
 placement.refresh_growth(planted+100*86400)
 assert(model.current_stage == 2 and model.has_node("ClimbingGrowth"))
 var small: AABB = model.mesh_bounds()
 placement.refresh_growth(planted+800*86400)
 assert(model.current_stage == 4 and model.mesh_bounds().size.y > small.size.y+.8)
 var meshes: Array[ArrayMesh] = []
 for mesh in model.get_node("ClimbingGrowth").get_children():
  meshes.append(mesh.mesh)
  assert(mesh.mesh.get_surface_count() > 0)
 assert(meshes.size() == 3)
 assert(model.get_meta("climbing_support") == placement.store.data.placed[0].uid)
 # A test clock never changes real save age; reload returns to the real seed.
 placement.reload_items()
 model = placement.roots.garden.get_child(1)
 assert(model.current_stage == 0)
 # Simulate a real old timestamp in the saved file, then restore normally.
 var next: Dictionary = placement.store.data.duplicate(true)
 next.placed[1].growth.started_at -= 800*86400
 assert(placement.store._commit(next))
 placement.reload_items()
 model = placement.roots.garden.get_child(1)
 assert(model.current_stage == 4 and model.has_node("ClimbingGrowth"))
 var signature: String = model.get_meta("climbing_signature")
 placement.reload_items()
 assert(placement.roots.garden.get_child(1).get_meta("climbing_signature") == signature)
 assert(placement.store.retrieve(0))
 placement.reload_items()
 model = placement.roots.garden.get_child(0)
 assert(not model.has_node("ClimbingGrowth") and model.current_stage == 4,"Removing structure preserves plant/age")
 assert(placement.begin("trellis","garden"))
 assert(placement.place_at(Vector2(0,60)),"Support can be placed beside an existing vine")
 placement.finish()
 assert(placement.roots.garden.get_child(0).has_node("ClimbingGrowth"))
 var hud = world.get_node("GameHUD")
 hud._open_market("shop")
 hud.market_screen.query = "climbing vines"
 hud.market_screen._refresh_grid()
 assert(hud.market_screen.card_buttons.size() == 5)
 hud._close()
 world.free()
 print("PASS climbing vines: five species/stage shops, real/offline/rollback clocks, rotated/cross-area/height support rules, vertical columns, close planting both orders, live trained geometry/three LODs, reproducible save restore and support removal preserving plants")
 quit()
