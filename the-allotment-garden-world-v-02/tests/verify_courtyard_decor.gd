extends SceneTree
const Store := preload("res://features/market/market_store.gd")
func _initialize() -> void:
 call_deferred("verify")
func verify() -> void:
 # Fresh isolated test data only.
 var world = load("res://main.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var session = world.market_garden
 assert(session.begin("bench"))
 assert(session.area == "courtyard" and session.store.count("bench") == 0)
 assert(not session.allowed("bench",Vector2.ZERO))
 assert(not session.allowed("lantern",Vector2(0,29)),"Entrance route must stay clear")
 assert(not session.allowed("lantern",Vector2(6,16)),"Walking loop must stay clear")
 assert(not session.allowed("bench",Vector2(4,55)),"Neighboring gardens are outside the circle scope")
 assert(session.place_at(Vector2(4.5,12)))
 assert(session.active and session.store.count("bench") == 0,"Free decoration must allow repeated copies")
 assert(not session.place_at(Vector2(4.5,12)),"Placed objects must not overlap")
 assert(session.place_at(Vector2(-4.5,12)))
 session.finish()
 assert(world.walking_mode and not world.ui_panel_open)
 assert(session.begin("lantern"))
 assert(session.allowed("lantern",Vector2(1.35,29)),"Path edge should accept small decorations")
 assert(session.place_at(Vector2(1.35,29)))
 var grass := Vector2(sin(PI/9),cos(PI/9))*29
 assert(session.allowed("lantern",grass))
 assert(session.place_at(grass))
 session.finish()
 var restored := Store.new()
 assert(restored.data.placed.size() == 4)
 for placement in restored.data.placed: assert(placement.area == "courtyard")
 session.reload_items()
 assert(session.roots.courtyard.get_child_count() == 4)
 assert(session.roots.garden.get_child_count() == 0)
 var found_grass := false
 var found_path := false
 for item in session.roots.courtyard.get_children():
  if item.position.y < 0: found_grass = true
  if is_equal_approx(item.position.y,.14): found_path = true
 assert(found_grass and found_path,"Grass and raised path items need their actual surface heights")
 # Legacy records without area must continue to load in Garden 01.
 assert(restored.place("rose",Vector2(4,55),0))
 restored.data.placed[-1].erase("area")
 assert(restored._commit(restored.data))
 session.reload_items()
 assert(session.roots.garden.get_child_count() == 1)
 var hud = world.get_node("GameHUD")
 hud._open_market("shop")
 hud.market_screen._select("bench")
 assert(not hud.market_screen.details.get_node("Place").disabled)
 hud.market_screen.details.get_node("Place").pressed.emit()
 assert(session.active and session.area == "courtyard")
 session.finish()
 world.queue_free()
 await process_frame
 print("PASS: free repeated placement, paths/grass surface heights, entrances/walking loop, overlap, courtyard persistence, legacy garden records and Shop action")
 quit()
