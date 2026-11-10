extends SceneTree
const Art := preload("res://assets/garden_art/garden_library.gd")
const Rules := preload("res://features/market/stack_rules.gd")
const Picker := preload("res://features/market/stack_picker.gd")
const Store := preload("res://features/market/market_store.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Model := preload("res://features/market/item_model.tscn")
func _initialize() -> void:
 root.size = Vector2i(1280,720)
 call_deferred("verify")
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func verify() -> void:
 for id in Art.Roman.SIZES:
  var entry := Catalog.by_id(id)
  assert(Catalog.placeable(entry) and entry.price == 0 and Catalog.icon(entry) != null)
  var model := Model.instantiate()
  model.item_id = id
  root.add_child(model)
  assert(model.mesh_bounds().size.is_equal_approx(Art.Roman.SIZES[id]),"Wrong Roman metre bounds: "+id)
  assert(Art.add_collision(model) > 0)
  model.free()
 var gallery = load("res://staging/roman_building_showcase.tscn").instantiate()
 root.add_child(gallery)
 gallery.show_assembly()
 assert(gallery.assembly_records.size() == 12 and Rules.valid_graph(gallery.assembly_records))
 gallery.free()
 var store := Store.new("user://stack-unit.json")
 assert(store.place("roman_plinth",Vector2.ZERO,0))
 var uid: String = store.data.placed[0].uid
 assert(not store.place("fluted_column_drum",Vector2.ZERO,0,"garden",1,[uid]),"Floating pieces must fail validation")
 assert(store.place("fluted_column_drum",Vector2.ZERO,0,"garden",.22,[uid]))
 assert(not store.retrieve(0) and store.last_error.contains("above"),"Supporting piece must not be removed")
 var malformed: Dictionary = store.data.duplicate(true)
 malformed.placed[1].supports = ["missing"]
 assert(not store._valid(malformed))
 malformed = store.data.duplicate(true)
 malformed.placed[1].uid = malformed.placed[0].uid
 assert(not store._valid(malformed))
 malformed = store.data.duplicate(true)
 malformed.placed[1].elevation = -1
 assert(not store._valid(malformed))
 malformed = store.data.duplicate(true)
 malformed.placed[1].elevation = "one"
 assert(not store._valid(malformed))
 malformed = store.data.duplicate(true)
 malformed.placed[1].x = 5
 assert(not store._valid(malformed),"Support in another position cannot hold a piece")
 malformed = store.data.duplicate(true)
 malformed.placed[1].area = "courtyard"
 assert(not store._valid(malformed),"Support cannot cross areas")
 malformed = store.data.duplicate(true)
 malformed.placed[1].supports = [malformed.placed[1].uid]
 assert(not store._valid(malformed),"Cycles must fail")
 assert(store.retrieve(1) and store.retrieve(0))
 var tall := Store.new("user://stack-height-limit.json")
 for level in range(24):
  var parent_ids: Array = [] if level == 0 else [tall.data.placed[-1].uid]
  assert(tall.place("plain_column_drum",Vector2.ZERO,0,"garden",level,parent_ids))
 assert(not tall.place("plain_column_drum",Vector2.ZERO,0,"garden",24,[tall.data.placed[-1].uid]))
 assert(tall.data.placed.size() == 24)
 # Legacy records gain IDs/ground height without losing their old data.
 var legacy := {"version":1,"runes":0,"owned":{},"favorites":[],"placed":[{"id":"rock_wall_end","x":5,"z":9,"angle":0,"area":"courtyard"}]}
 var legacy_store := Store.new("user://stack-legacy.json")
 assert(legacy_store._commit(legacy))
 assert(legacy_store.ensure_placement_ids(func(_record: Dictionary) -> float: return .125))
 var legacy_uid: String = legacy_store.data.placed[0].uid
 assert(legacy_store.data.placed[0].ground_y == .125)
 assert(Store.new("user://stack-legacy.json").data.placed[0].uid == legacy_uid)
 var world = load("res://main.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var placement = world.market_garden
 var point := Vector2(0,55)
 var expected: Array = []
 var height := 0.0
 for id in ["roman_plinth","attic_column_base","fluted_column_drum","fluted_column_drum","corinthian_capital","garden_muse_bust"]:
  assert(placement.begin(id,"garden"))
  var parents := Rules.supports_for(id,point,0,placement.terrain.sample_height(point)+height,placement.store.data.placed,"garden") if height > 0 else []
  assert(placement.place_at(point,height,parents),"Failed vertical placement: "+id)
  expected.append(height)
  height += Rules.size(id).y
  placement.finish()
 placement.reload_items()
 assert(placement.roots.garden.get_child_count() == 6)
 for i in range(6):
  var model = placement.roots.garden.get_child(i)
  assert(absf(model.position.y-placement.terrains.garden.sample_height(point)-expected[i]) < .001)
 assert(not placement.store.retrieve(2),"Mid-stack retrieval would leave unsupported pieces")
 assert(placement.store.retrieve(5))
 placement.reload_items()
 assert(placement.begin("short_column_drum","garden"))
 var top_record: Dictionary = placement.store.data.placed[-1]
 var top: Vector3 = Vector3(point.x,Rules.top_y(top_record),point.y)
 world.focus = placement.garden.to_global(top)
 world.distance = 10
 world.pitch = .7
 world._update_camera()
 var screen: Vector2 = world.camera.unproject_position(placement.garden.to_global(top))
 var picked := Picker.pick(world.camera,screen,placement.garden,"short_column_drum",0,placement.store.data.placed,"garden",placement.terrain.sample_height)
 assert(not picked.is_empty() and picked.point.is_equal_approx(point),"Clicking a support top must select its actual height")
 assert(absf(picked.elevation-3.1) < .001)
 assert(placement.allowed("short_column_drum",point,picked.elevation,picked.supports))
 assert(not placement.allowed("short_column_drum",point,20,picked.supports))
 assert(not placement.allowed("short_column_drum",point,3.0,picked.supports))
 assert(placement.place_at(point,picked.elevation,picked.supports))
 assert(not placement.allowed("short_column_drum",point,picked.elevation,picked.supports),"Same-level volume overlaps must be rejected")
 placement.finish()
 assert(placement.store.retrieve(placement.store.data.placed.size()-1))
 placement.reload_items()
 # Two complete columns support one beam; a single narrow column cannot.
 var left := Vector2(-4,80)
 var right := Vector2(-1.6,80)
 for p in [left,right]:
  assert(placement.begin("doric_column","garden"))
  assert(placement.place_at(p))
  placement.finish()
 assert(placement.begin("roman_architrave","garden"))
 var center := (left+right)*.5
 var ground: float = placement.terrain.sample_height(center)
 var parents := Rules.supports_for("roman_architrave",center,0,ground+3.2,placement.store.data.placed,"garden")
 assert(parents.size() == 2)
 var left_top: Vector3 = placement.garden.to_global(Vector3(left.x,ground+3.2,left.y))
 world.focus = left_top
 world.distance = 10
 world.pitch = .7
 world._update_camera()
 var beam_pick := Picker.pick(world.camera,world.camera.unproject_position(left_top),placement.garden,"roman_architrave",0,placement.store.data.placed,"garden",placement.terrain.sample_height)
 assert(not beam_pick.is_empty() and beam_pick.point.is_equal_approx(center) and beam_pick.supports.size() == 2,"Picking a column must align a beam between two supports")
 assert(not placement.allowed("roman_architrave",center,3.2,[parents[0]]))
 assert(placement.place_at(center,3.2,parents))
 placement.finish()
 # Wide tops retain the picked horizontal position, so more pieces can be built above a beam.
 assert(placement.begin("short_column_drum","garden"))
 var beam_left: Vector3 = placement.garden.to_global(Vector3(center.x-.9,ground+3.55,center.y))
 world.focus = beam_left
 world.distance = 8
 world.pitch = .7
 world._update_camera()
 var high_pick := Picker.pick(world.camera,world.camera.unproject_position(beam_left),placement.garden,"short_column_drum",0,placement.store.data.placed,"garden",placement.terrain.sample_height)
 assert(not high_pick.is_empty() and absf(high_pick.point.x-(center.x-.9)) < .11 and absf(high_pick.elevation-3.55) < .001)
 assert(placement.place_at(high_pick.point,high_pick.elevation,high_pick.supports))
 assert(not placement.allowed("short_column_drum",high_pick.point,high_pick.elevation,high_pick.supports))
 placement.finish()
 assert(placement.store.retrieve(placement.store.data.placed.size()-1))
 placement.reload_items()
 world.set_walking_mode(true)
 world.orbit = placement.areas.garden.global_rotation.y
 world.player.global_position = placement.areas.garden.to_global(Vector3(center.x,ground+.1,center.y+2))
 world.player.velocity = Vector3.ZERO
 world.player.use_requested_direction = true
 world.player.requested_direction = Vector2(0,-1)
 await frames(120)
 var walked: Vector3 = placement.areas.garden.to_local(world.player.global_position)
 assert(walked.z < center.y-1.5,"Walking under the beam must remain possible")
 world.player.requested_direction = Vector2.ZERO
 var saved := Store.new()
 assert(saved.readable and Rules.valid_graph(saved.data.placed))
 assert(not saved.retrieve(saved.data.placed.size()-2),"Beam must prevent removing either column")
 assert(saved.retrieve(saved.data.placed.size()-1))
 world.free()
 print("PASS vertical building: 14 Roman models/metres/icons, supported 12-piece colonnade, stable save IDs, legacy migration, six-piece stacking/reload, analytic top picking, two-column beams, removal protection, floating/overlap/foreign/cyclic/malformed rejection")
 quit()
