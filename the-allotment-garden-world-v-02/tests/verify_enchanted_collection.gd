extends SceneTree
const Art := preload("res://assets/garden_art/garden_library.gd")
const Model := preload("res://features/market/item_model.tscn")
const Catalog := preload("res://features/market/catalog.gd")
const Rules := preload("res://features/market/stack_rules.gd")
func _initialize() -> void: call_deferred("verify")
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func verify() -> void:
 assert(Art.Enchanted.SIZES.size() == 18)
 for id in Art.Enchanted.SIZES:
  var entry := Catalog.by_id(id)
  assert(Catalog.placeable(entry) and entry.price == 0 and Catalog.icon(entry) != null)
  var dimensions: Vector3 = Art.Enchanted.SIZES[id]
  assert(entry.radius >= Vector2(dimensions.x,dimensions.z).length()*.5,"Placement must reserve the full actual footprint: "+id)
  var model := Model.instantiate()
  model.item_id = id
  root.add_child(model)
  assert(model.mesh_bounds().size.is_equal_approx(Art.Enchanted.SIZES[id]),"Wrong magical metre bounds: "+id)
  assert(model.has_node("EnchantedGlow/SoftNightHalo") and model.has_node("EnchantedGlow/BudgetedGlowLight"))
  assert(Art.add_collision(model) > 0)
  model.free()
 var world = load("res://main.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var placement = world.market_garden
 for id in Art.Enchanted.SIZES:
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
  assert(found,"No valid magic placement: "+id)
  placement.finish()
 placement.reload_items()
 assert(placement.roots.garden.get_child_count() == 18)
 var before: String = JSON.stringify(placement.store.data)
 var clock = world.get_node("DayNightCycle")
 var weather = world.get_node("GardenWeather")
 weather.set_simulation_time(Time.get_unix_time_from_datetime_string("2026-11-10T12:00:00"))
 await process_frame
 assert(clock.night_amount == 0 and Art.Builder.material(13).get_shader_parameter("night_amount") == 0.0)
 weather.set_simulation_time(Time.get_unix_time_from_datetime_string("2026-11-10T23:00:00"))
 await process_frame
 assert(clock.night_amount == 1 and Art.Builder.material(13).get_shader_parameter("night_amount") == 1.0)
 clock.set_night_amount(0)
 weather.set_simulation_time(Time.get_unix_time_from_datetime_string("2026-11-11T01:00:00"))
 assert(clock.manual_override and clock.night_amount == 0)
 clock.resume_clock()
 assert(not clock.manual_override and clock.night_amount == 1)
 world.set_walking_mode(false)
 world.focus = placement.areas.garden.to_global(Vector3(0,1,55))
 world.distance = 10
 world._update_camera()
 var extras := []
 for i in range(12):
  var model := Model.instantiate()
  model.item_id = "firefly_jar"
  model.position = world.focus+Vector3(i*.1,0,0)
  world.add_child(model)
  extras.append(model)
 var ghost := Model.instantiate()
 ghost.item_id = "crystal_cluster"
 ghost.set_meta("placement_preview",true)
 world.add_child(ghost)
 clock.update_decor_lights()
 var lit := 0
 for effect in get_nodes_in_group("enchanted_garden_fx"):
  if effect.lamp.light_energy > 0: lit += 1
 assert(lit == 6,"Decor lights must obey the global six-light budget")
 assert(not ghost.get_node("EnchantedGlow/SoftNightHalo").visible and ghost.get_node("EnchantedGlow/BudgetedGlowLight").light_energy == 0)
 clock.set_night_amount(0)
 for effect in get_nodes_in_group("enchanted_garden_fx"):
  assert(not effect.halo.visible and effect.lamp.light_energy == 0)
 assert(Art.Builder.material(13).get_shader_parameter("night_amount") == 0.0)
 Art.Builder.set_reduced_motion(true)
 assert(Art.Builder.material(13).get_shader_parameter("motion") == 0.0)
 Art.Builder.set_reduced_motion(false)
 assert(JSON.stringify(placement.store.data) == before,"Lighting must not mutate placement/growth saves")
 ghost.free()
 for model in extras: model.free()
 # Compatible magical ornaments retain the existing vertical-building rules.
 assert(placement.begin("roman_pedestal","garden"))
 var pedestal_point := Vector2(8,120)
 assert(placement.place_at(pedestal_point))
 placement.finish()
 assert(placement.begin("firefly_jar","garden"))
 var parents := Rules.supports_for("firefly_jar",pedestal_point,0,placement.terrain.sample_height(pedestal_point)+1,placement.store.data.placed,"garden")
 assert(placement.place_at(pedestal_point,1,parents))
 placement.finish()
 var hud = world.get_node("GameHUD")
 hud._open_market("shop")
 await process_frame
 hud.market_screen.query = "witchy"
 hud.market_screen._refresh_grid()
 assert(hud.market_screen.card_buttons.size() == 18)
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
 for id in ["moon_arch","fairy_ring"]:
  var model := Model.instantiate()
  model.item_id = id
  root.add_child(model)
  Art.add_collision(model)
  var player = load("res://features/avatar/garden_player.tscn").instantiate()
  player.position = Vector3(0,.05,1.8)
  player.use_requested_direction = true
  root.add_child(player)
  player.requested_direction = Vector2(0,-1)
  await frames(90 if id == "moon_arch" else 40)
  assert(player.position.y > -.05)
  if id == "fairy_ring": assert(Vector2(player.position.x,player.position.z).length() < .6,"Fairy ring must be enterable through its gap")
  else: assert(player.position.z < -1.3,"Moon arch must remain walk-through")
  player.free()
  model.free()
 floor.free()
 var gallery = load("res://staging/enchanted_garden_showcase.tscn").instantiate()
 root.add_child(gallery)
 assert(gallery.asset_choice.item_count == 18 and gallery.cycle.night_amount == 1)
 gallery.show_garden()
 gallery.cycle.set_night_amount(0)
 assert(Art.Builder.night_amount == 0)
 gallery.free()
 print("PASS enchanted garden: 18 free models/metres/icons, placement/save restore, UTC auto day/night, manual preview/resume, six-light budget, hidden preview effects, reduced motion, unchanged saves, raised ornaments, searchable family, open arch/ring and showcase")
 quit()
