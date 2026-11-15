extends SceneTree
const Art := preload("res://assets/garden_art/garden_library.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Model := preload("res://features/market/item_model.tscn")
const Border := preload("res://features/market/boundary_placement.gd")
func _initialize() -> void: call_deferred("verify")
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func verify() -> void:
 assert(Art.Rustic.SIZES.size() == 13)
 for id in Art.Rustic.SIZES:
  var entry := Catalog.by_id(id)
  assert(Catalog.placeable(entry) and entry.price == 0 and Catalog.icon(entry) != null)
  var dimensions: Vector3 = Art.Rustic.SIZES[id]
  assert(entry.radius >= Vector2(dimensions.x,dimensions.z).length()*.5)
  var model := Model.instantiate()
  model.item_id = id
  root.add_child(model)
  assert(model.mesh_bounds().size.is_equal_approx(dimensions),"Wrong rustic metre bounds: "+id)
  var count: int = Art.add_collision(model)
  assert(count > 0 or id == "grass_stone_checkerboard")
  var children := model.get_child_count()
  Art.add_collision(model)
  assert(model.get_child_count() == children)
  if id == "branch_gate":
   var controller = model.get_node("GateController")
   controller.auto_open = false
   controller.set_open(true)
   await frames(60)
   assert(controller.amount > .99 and controller.left.has_node("GateLeafCollision"))
  if id == "fairy_light_arbor": assert(model.has_node("EnchantedGlow"))
  model.free()
 assert(Border.sockets("branch_gate") == Border.sockets("timber_gate"))
 assert(Border.sockets("branch_fence") == Border.sockets("rock_wall"))
 var world = load("res://main.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var placement = world.market_garden
 for id in Art.Rustic.SIZES:
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
  assert(found,"No valid rustic placement: "+id)
  placement.finish()
 placement.reload_items()
 assert(placement.roots.garden.get_child_count() == 13)
 var clock = world.get_node("DayNightCycle")
 clock.set_night_amount(1)
 assert(Art.Builder.material(13).get_shader_parameter("night_amount") == 1.0)
 clock.set_night_amount(0)
 var hud = world.get_node("GameHUD")
 hud._open_market("shop")
 await process_frame
 hud.market_screen.query = "campsite"
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
 for id in ["branch_gate","rustic_arbor","fairy_light_arbor","formal_parterre"]:
  var model := Model.instantiate()
  model.item_id = id
  root.add_child(model)
  Art.add_collision(model)
  var player = load("res://features/avatar/garden_player.tscn").instantiate()
  player.position = Vector3(0,.05,2.6)
  player.use_requested_direction = true
  root.add_child(player)
  player.requested_direction = Vector2(0,-1)
  await frames(140)
  assert(player.position.z < -2.5,"Rustic entrance or parterre cross path blocked: "+id+str(player.position))
  player.free()
  model.free()
 floor.free()
 var gallery = load("res://staging/rustic_garden_showcase.tscn").instantiate()
 root.add_child(gallery)
 assert(gallery.asset_choice.item_count == 13)
 gallery.free()
 print("PASS rustic inspiration: 13 free models/icons/metre bounds/full footprints, collision, opening gate, boundary compatibility, all-item placement/save restore, campsite search, night-light hookup and four actual walk-through checks")
 quit()
