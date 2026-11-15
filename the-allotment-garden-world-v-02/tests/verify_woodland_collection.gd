extends SceneTree
const Art := preload("res://assets/garden_art/garden_library.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Model := preload("res://features/market/item_model.tscn")
const Rules := preload("res://features/market/stack_rules.gd")
func _initialize() -> void: call_deferred("verify")
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func verify() -> void:
 assert(Art.Woodland.SIZES.size() == 13)
 for id in Art.Woodland.SIZES:
  var entry := Catalog.by_id(id)
  assert(Catalog.placeable(entry) and entry.price == 0 and Catalog.icon(entry) != null)
  var dimensions: Vector3 = Art.Woodland.SIZES[id]
  assert(entry.radius >= Vector2(dimensions.x,dimensions.z).length()*.5)
  var model := Model.instantiate()
  model.item_id = id
  root.add_child(model)
  assert(model.mesh_bounds().size.is_equal_approx(dimensions),"Wrong woodland metre bounds: "+id)
  var bounds: AABB = model.mesh_bounds()
  var required := 0.0
  for x in [bounds.position.x,bounds.end.x]:
   for z in [bounds.position.z,bounds.end.z]: required = maxf(required,Vector2(x,z).length())
  print("FOOTPRINT ",id," ",required," radius ",entry.radius)
  assert(entry.radius+.001 >= required,"Footprint fails to cover geometry: "+id)
  var count: int = Art.add_collision(model)
  assert(count > 0)
  var children := model.get_child_count()
  Art.add_collision(model)
  assert(model.get_child_count() == children)
  if id == "lantern_picnic_canopy": assert(model.has_node("EnchantedGlow"))
  model.free()
 var world = load("res://main.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var placement = world.market_garden
 for id in Art.Woodland.SIZES:
  assert(placement.begin(id,"garden"))
  var found := false
  for z in range(45,130,10):
   if found: break
   for x in range(-30,31,10):
    var point := Vector2(x,z)
    if placement.allowed(id,point):
     assert(placement.place_at(point))
     found = true
     break
  assert(found,"No valid woodland placement: "+id)
  placement.finish()
 placement.reload_items()
 assert(placement.roots.garden.get_child_count() == 13)
 var deck: Dictionary = placement.store.data.placed[9]
 assert(deck.id == "forest_gathering_deck")
 var deck_point := Vector2(deck.x,deck.z-.45)
 assert(placement.begin("stump_stool","garden"))
 var deck_y := Rules.top_y(deck)
 var parents := Rules.supports_for("stump_stool",deck_point,0,deck_y,placement.store.data.placed,"garden")
 assert(placement.place_at(deck_point,deck_y-placement.terrain.sample_height(deck_point),parents),"Furniture must place on deck")
 placement.finish()
 placement.reload_items()
 assert(placement.roots.garden.get_child_count() == 14)
 assert(not placement.store.retrieve(9),"Occupied deck cannot be removed")
 assert(placement.store.retrieve(13))
 var clock = world.get_node("DayNightCycle")
 clock.set_night_amount(1)
 assert(Art.Builder.material(13).get_shader_parameter("night_amount") == 1.0)
 clock.set_night_amount(0)
 var hud = world.get_node("GameHUD")
 hud._open_market("shop")
 await process_frame
 hud.market_screen.query = "gathering play"
 hud.market_screen._refresh_grid()
 assert(hud.market_screen.card_buttons.size() == 13)
 hud._close()
 world.free()
 var floor := StaticBody3D.new()
 var shape := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(20,.2,20)
 shape.shape = box
 shape.position.y = -.1
 floor.add_child(shape)
 root.add_child(floor)
 for id in ["forest_gathering_deck","stump_balance_trail"]:
  var model := Model.instantiate()
  model.item_id = id
  root.add_child(model)
  Art.add_collision(model)
  var player = load("res://features/avatar/garden_player.tscn").instantiate()
  player.position = Vector3(0,.05,3.5) if id == "forest_gathering_deck" else Vector3(1.25,.05,3)
  player.use_requested_direction = true
  root.add_child(player)
  await frames(12)
  player.requested_direction = Vector2(0,-1)
  await frames(80 if id == "forest_gathering_deck" else 55)
  print("RAMP ",id," ",player.position)
  assert(player.position.y > (.21 if id == "forest_gathering_deck" else .38),"Ramp blocked: "+id+str(player.position))
  player.free()
  model.free()
 floor.free()
 var rules := preload("res://features/market/stack_rules.gd")
 var parent := {"id":"forest_gathering_deck","x":0.,"z":0.,"angle":0.,"area":"garden","uid":"111111111111111111111111"}
 assert(rules.supports_for("stump_stool",Vector2(0,-.45),0,.24,[parent],"garden").size() == 1)
 assert(rules.supports_for("stump_stool",Vector2(0,2),0,.24,[parent],"garden").is_empty())
 for angle in [0.,PI/2,PI]:
  assert(rules.inside("forest_gathering_deck",Vector2(0,-2.3).rotated(-angle),Vector2.ZERO,angle))
  assert(not rules.inside("forest_gathering_deck",Vector2(0,2).rotated(-angle),Vector2.ZERO,angle))
 var gallery = load("res://staging/woodland_gathering_showcase.tscn").instantiate()
 root.add_child(gallery)
 assert(gallery.asset_choice.item_count == 13)
 gallery.free()
 print("PASS woodland: 13 free shop models/icons/metre bounds/full footprints, idempotent collisions, placement/save restore, search, night-light hookup, two actual player ramp walks and offset deck stacking")
 quit()
