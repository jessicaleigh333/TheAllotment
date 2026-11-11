extends SceneTree
const Growth := preload("res://features/market/plant_growth.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Store := preload("res://features/market/market_store.gd")
const Model := preload("res://features/market/item_model.tscn")
func _initialize() -> void:
 call_deferred("verify")
func verify() -> void:
 var start := 1700000000.0
 for plant in Growth.PLANTS:
  var info: Dictionary = Growth.PLANTS[plant]
  var record := {"id":plant+"@seed","growth":Growth.new_record(plant+"@seed",start)}
  for stage in range(5):
   var now: float = start+float(info.days[stage])*86400
   var age := Growth.age_days(record,now)
   assert(Growth.state(plant,age).stage == stage)
  assert(Growth.age_days(record,start-86400) == 0,"Clock rollback must not create negative growth")
  record.growth.observed_age_days = float(info.days[2])
  assert(Growth.age_days(record,start) == info.days[2])
  for suffix in ["@seed","@seedling","@young",""]:
   var item := Catalog.by_id(plant+suffix)
   assert(Catalog.placeable(item))
   var model = Model.instantiate()
   model.item_id = plant+suffix
   root.add_child(model)
   var state := Growth.state(plant,Growth.starting_age(model.item_id))
   var bounds: AABB = model.mesh_bounds()
   assert(absf(bounds.size.y-state.height) < .001,"Wrong plant height in metres")
   assert(absf(bounds.size.x-state.width) < .001 and absf(bounds.size.z-state.width) < .001)
   assert(absf(bounds.position.y) < .001,"Plant pivot must sit on the ground")
   model.free()
 assert(Growth.state("sunflower",6.99).stage == 0)
 assert(Growth.state("sunflower",7).stage == 1)
 assert(Growth.state("sunflower",90).stage == 4)
 assert(Catalog.by_id("sunflower@bad").is_empty())
 var store := Store.new("user://growth-test.json")
 assert(store.buy("sunflower@seedling"))
 assert(store.place("sunflower@seedling",Vector2(4,55),0))
 var next: Dictionary = store.data.duplicate(true)
 next.placed[0].growth.started_at = Time.get_unix_time_from_system()-35*86400
 assert(store._commit(next))
 var expected := Growth.age_days(next.placed[0],Time.get_unix_time_from_system())
 assert(store.retrieve(0))
 assert(store.count("sunflower@young") == 1)
 assert(store.place("sunflower@young",Vector2(4,55),0))
 var age := Growth.age_days(store.data.placed[0],Time.get_unix_time_from_system())
 assert(absf(age-expected) < .01,"Returning and replanting must keep the achieved age")
 assert(Store.new("user://growth-test.json").data.placed[0].has("growth"))
 var invalid := store.data.duplicate(true)
 invalid.placed[0].growth.started_at = NAN
 assert(not store._commit(invalid))
 # Existing mature saves must not become seeds.
 assert(Growth.age_days({"id":"rose"},start) == Growth.PLANTS.rose.days[4])
 var world = load("res://main.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var session = world.market_garden
 assert(session.begin("sunflower@seed","garden"))
 assert(session.place_at(Vector2(4,55)))
 session.finish()
 var model = session.roots.garden.get_child(0)
 assert(model.current_stage == 0)
 var planted: float = session.store.data.placed[0].growth.started_at
 session.refresh_growth(planted+21*86400)
 assert(model.current_stage == 2)
 session.refresh_growth(planted+100*86400)
 assert(model.current_stage == 4 and absf(model.mesh_bounds().size.y-1.8) < .001)
 session.reload_items()
 assert(session.roots.garden.get_child(0).current_stage == 0,"Artificial test time must not change the real clock")
 var hud = world.get_node("GameHUD")
 hud._open_market("shop")
 hud.market_screen.stage_choice.item_selected.emit(0)
 assert(hud.market_screen.card_buttons.has("sunflower@seed"))
 hud.market_screen.stage_choice.item_selected.emit(1)
 assert(hud.market_screen.card_buttons.has("sunflower@seedling"))
 hud.market_screen._buy("lavender@young")
 hud.market_screen._set_mode("backpack")
 assert(hud.market_screen.card_buttons.has("lavender@young"))
 hud._close()
 world.queue_free()
 await process_frame
 print("PASS: all 12 species and stages, real/offline clock boundaries, metre bounds, legacy saves, stage inventory, age-preserving pickup/replant, live growth and Shop stages")
 quit()
