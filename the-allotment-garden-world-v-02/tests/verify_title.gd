extends SceneTree
func _initialize() -> void:
 call_deferred("verify")
func verify() -> void:
 var title = load("res://features/title/title_screen.tscn").instantiate()
 root.add_child(title)
 await process_frame
 assert(title.canvas.get_node("Login") is Button)
 assert(title.canvas.get_node("CreateAccount") is Button)
 assert(title.ambience.breeze.playing and title.ambience.insects.playing)
 assert(title.ambience.chime_delay >= 14)
 title.canvas.get_node("Settings").pressed.emit()
 assert(title.settings.visible)
 title.ambience.muted = true
 title.reduced_motion = true
 title._apply_settings()
 assert(title.ambience.breeze.volume_db <= -80)
 await process_frame
 assert(not title.butterfly.visible)
 title._open_welcome()
 var welcome = title.get_child(title.get_child_count()-1)
 assert(welcome.stage == 1)
 welcome.terms_check.button_pressed = true
 welcome.show_step(2)
 assert(welcome.stage == 2)
 title.ambience.muted = false
 title.reduced_motion = false
 title._apply_settings()
 title.queue_free()
 await process_frame
 await create_timer(.2).timeout
 print("PASS: title artwork/buttons, looping ambience, timed chimes, mute/reduced motion and welcome flow")
 quit()
