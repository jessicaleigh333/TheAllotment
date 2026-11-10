extends SceneTree
const Art := preload("res://assets/garden_art/garden_library.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Model := preload("res://features/market/item_model.tscn")
const Border := preload("res://features/market/boundary_placement.gd")
func _initialize() -> void: call_deferred("verify")
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func verify() -> void:
 assert(Art.French.SIZES.size() == 22)
 for id in Art.French.SIZES:
  var item := Catalog.by_id(id)
  assert(Catalog.placeable(item) and item.price == 0 and item.category == "Decor")
  assert(Catalog.icon(item) != null and item.has("inspiration"))
  var model := Model.instantiate()
  model.item_id = id
  root.add_child(model)
  assert(model.mesh_bounds().size.is_equal_approx(Art.French.SIZES[id]),"Wrong metres: "+id+str(model.mesh_bounds().size))
  assert(Art.add_collision(model) > 0,"Missing collision: "+id)
  var count := model.get_child_count()
  Art.add_collision(model)
  assert(model.get_child_count() == count)
  if Art.French.GATES.has(id):
   var controller = model.get_node("GateController")
   controller.auto_open = false
   controller.set_open(true)
   await frames(60)
   assert(controller.amount > .99 and controller.left.has_node("GateLeafCollision"))
   controller.set_open(false)
   await frames(60)
   assert(controller.amount < .01)
  if id in Border.IDS:
   var canonical: String = Art.French.ALIASES[id]
   assert(Border.sockets(id) == Border.sockets(canonical))
   assert(Border.boxes(id) == Border.boxes(canonical))
  model.free()
 # Real avatar passage through the new gate variants and open structures.
 var floor := StaticBody3D.new()
 var shape := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(30,.2,30)
 shape.shape = box
 shape.position.y = -.1
 floor.add_child(shape)
 root.add_child(floor)
 for id in ["chateau_gate","potager_gate","vine_pergola","iron_pavilion"]:
  var model := Model.instantiate()
  model.item_id = id
  root.add_child(model)
  Art.add_collision(model)
  var player = load("res://features/avatar/garden_player.tscn").instantiate()
  player.position = Vector3(.30,.05,3)
  player.use_requested_direction = true
  root.add_child(player)
  player.requested_direction = Vector2(0,-1)
  await frames(150)
  assert(player.position.z < -2.5,"Navigation blocked: "+id+str(player.position))
  player.free()
  model.free()
 floor.free()
 var world = load("res://main.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var placement = world.market_garden
 for id in Art.French.SIZES:
  assert(placement.begin(id,"garden"))
  var found := false
  for z in range(45,130,8):
   if found: break
   for x in range(-24,25,8):
    var point := Vector2(x,z)
    if placement.allowed(id,point):
     assert(placement.place_at(point))
     found = true
     break
  assert(found,"No valid placement found: "+id)
  placement.finish()
 placement.reload_items()
 await process_frame
 assert(placement.roots.garden.get_child_count() == 22,"All placed French items must restore")
 var hud = world.get_node("GameHUD")
 hud._open_market("shop")
 await process_frame
 hud.market_screen.query = "pottery"
 hud.market_screen._refresh_grid()
 assert(hud.market_screen.card_buttons.has("anduze_jar"),"Inspiration search failed")
 hud.market_screen.query = "sculptures"
 hud.market_screen._refresh_grid()
 assert(hud.market_screen.card_buttons.size() == 5,"Family search failed")
 hud._close()
 world.free()
 var gallery = load("res://staging/french_garden_showcase.tscn").instantiate()
 root.add_child(gallery)
 assert(gallery.asset_choice.item_count == 22)
 gallery.show_asset("stone_urn")
 assert(gallery.selected == "stone_urn")
 gallery.free()
 print("PASS French collection: 22 free models/icons at exact metre dimensions, collision, gate motion, four walk-through assets, connected-boundary compatibility, all-item placement/save restore, inspiration/family search and dedicated showcase")
 quit()
