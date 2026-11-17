extends SceneTree
const Growth := preload("res://features/market/plant_growth.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Art := preload("res://assets/garden_art/garden_library.gd")
const Model := preload("res://features/market/item_model.tscn")
func _initialize() -> void: call_deferred("verify")
func verify() -> void:
 assert(Growth.validate_profiles(),"Every new growing profile needs identity, five age/size knots and sources")
 var invalid: Dictionary = Growth.Woody.PROFILES.tree.duplicate(true)
 invalid.references = []
 assert(not Growth.Woody.valid_profile(invalid))
 invalid = Growth.Woody.PROFILES.tree.duplicate(true)
 invalid.days[2] = -1
 assert(not Growth.Woody.valid_profile(invalid))
 var start := 1700000000.
 for id in Growth.Woody.PROFILES:
  var info: Dictionary = Growth.PLANTS[id]
  assert(info.days[4] >= 3652.5,"Woody maturity is real years")
  var record := {"id":id+"@seed","growth":Growth.new_record(id+"@seed",start)}
  assert(Growth.age_days(record,start+86400.) == 1.)
  for stage in range(5):
   var age := float(info.days[stage])
   var state := Growth.state(id,age)
   assert(state.stage == stage and state.name == info.names[stage])
   assert(state.height == info.heights[stage] and state.width == info.widths[stage] and state.depth == info.depths[stage])
   assert(Growth.state(id,Growth.age_days(record,start+age*86400.)).stage == stage)
   var meshes := Art.meshes(id+"@growing",stage,Color.WHITE,state)
   assert(meshes[0] == Art.meshes(id+"@growing",stage,Color.WHITE,state)[0])
   var previous := 2147483647
   for mesh in meshes:
    var triangles := 0
    for surface in range(mesh.get_surface_count()):
     var arrays := mesh.surface_get_arrays(surface)
     for normal in arrays[Mesh.ARRAY_NORMAL]: assert(normal.is_finite() and normal.length() > .9)
     for vertex in arrays[Mesh.ARRAY_VERTEX]: assert(vertex.is_finite())
     assert(arrays[Mesh.ARRAY_VERTEX].size() == arrays[Mesh.ARRAY_TEX_UV].size())
     for index in arrays[Mesh.ARRAY_INDEX]: assert(index >= 0 and index < arrays[Mesh.ARRAY_VERTEX].size())
     triangles += arrays[Mesh.ARRAY_INDEX].size()/3
    print("MESH ",id," ",stage," ",triangles)
    assert(triangles < 40000 and triangles <= previous,"Woody LOD budget: "+id)
    previous = triangles
   var model := Model.instantiate()
   model.item_id = id
   model.growth_age_days = age
   root.add_child(model)
   var bounds: AABB = model.mesh_bounds()
   assert(bounds.size.is_equal_approx(Vector3(state.width,state.height,state.depth)))
   assert(absf(bounds.position.y) < .001)
   if stage == 4:
    var radius: float = Catalog.by_id(id).radius
    for x in [bounds.position.x,bounds.end.x]:
     for z in [bounds.position.z,bounds.end.z]: assert(Vector2(x,z).length() <= radius,"Mature footprint covers crown")
   Art.add_collision(model)
   var children := model.get_child_count()
   Art.add_collision(model)
   assert(model.get_child_count() == children)
   model.free()
  for suffix in ["@seed","@seedling","@young",""]:
   var item := Catalog.by_id(id+suffix)
   assert(item.get("plant") == id and Catalog.placeable(item) and Catalog.icon(item) != null)
  var middle := (float(info.days[2])+float(info.days[3]))*.5
  var mid := Growth.state(id,middle)
  assert(absf(mid.height-(info.heights[2]+info.heights[3])*.5) < .0001)
  var legacy := {"id":id}
  assert(Growth.age_days(legacy,start) == info.days[4])
 # Collision is requested once, then survives minute-by-minute mesh rebuilds.
 var growing := Model.instantiate()
 growing.item_id = "tree@seed"
 root.add_child(growing)
 Art.add_collision(growing)
 assert(not growing.has_node("PlayerCollision"))
 growing.rebuild(Growth.PLANTS.tree.days[2])
 assert(growing.has_node("PlayerCollision"))
 var before: float = growing.get_node("PlayerCollision").get_child(0).shape.height
 growing.rebuild(Growth.PLANTS.tree.days[3])
 assert(growing.get_node("PlayerCollision").get_child(0).shape.height > before)
 growing.free()
 # Old background meshes stay on their original path, without new unit-size fitting.
 assert(Art.meshes("tree")[0] != Art.meshes("tree@growing")[0])
 var world = load("res://main.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var session = world.market_garden
 for id in Growth.Woody.PROFILES:
  assert(session.begin(id+"@seedling","garden"))
  var found := false
  for z in range(75,135,10):
   if found: break
   for x in range(-30,31,10):
    var point := Vector2(x,z)
    if session.allowed(id+"@seedling",point):
     assert(session.place_at(point))
     found = true
     break
  assert(found,"Full-size clearance must fit in the real garden: "+id)
  session.finish()
 session.reload_items()
 assert(session.roots.garden.get_child_count() == 4)
 var original: Dictionary = session.store.data.placed[0]
 var model = session.roots.garden.get_child(0)
 session.refresh_growth(original.growth.started_at+1826.25*86400.)
 assert(model.current_stage == 3 and model.has_node("PlayerCollision"))
 session.reload_items()
 assert(session.roots.garden.get_child(0).current_stage == 2,"Preview clock must not become saved age")
 assert(world.local_vault.save())
 var hud = world.get_node("GameHUD")
 hud._open_market("shop")
 hud.market_screen.query = "Living trees and hedges"
 hud.market_screen._refresh_grid()
 assert(hud.market_screen.card_buttons.size() == 4)
 hud._close()
 world.free()
 await process_frame
 print("PASS woody growth: four real-time profiles, 20 stage geometries/60 LODs, own size curves, exact metre bounds, full crown clearance, live collision resizing, seed/nursery shop, placement/reload/vault and unchanged scenery mesh paths")
 quit()
