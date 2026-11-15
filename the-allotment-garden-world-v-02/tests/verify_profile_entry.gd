extends SceneTree
func _initialize() -> void:
 call_deferred("verify")
func verify() -> void:
 var title = load("res://features/title/title_screen.tscn").instantiate()
 root.add_child(title)
 current_scene = title
 await process_frame
 title._open_profiles(true)
 title.profile_panel.find_child("ProfileName",true,false).text = "Garden Visitor"
 var column = title.profile_panel.get_child(0)
 for control in column.get_children():
  if control is Button and control.text == "Enter garden":
   control.pressed.emit()
   break
 await scene_changed
 for i in range(20): await physics_frame
 assert(current_scene.player != null and current_scene.player.is_on_floor())
 var profiles = load("res://features/profiles/local_profiles.gd").new()
 var data: Dictionary = profiles.read()
 assert(data.profiles.size() == 1 and data.profiles[0].name == "Garden Visitor")
 current_scene.open_ground_editor()
 assert(current_scene.ground_editor_session.store.default_save_path().begins_with("user://profiles/"+data.active+"/"))
 current_scene.ground_editor_session.close()
 change_scene_to_file("res://features/title/title_screen.tscn")
 await scene_changed
 current_scene._open_profiles(false)
 assert(current_scene.profile_panel.find_child("SavedProfiles",true,false).item_count == 1)
 current_scene.queue_free()
 await process_frame
 await create_timer(.2).timeout
 print("PASS: create local profile, enter playable garden, scoped editor saves, return to title and choose saved profile")
 quit()
