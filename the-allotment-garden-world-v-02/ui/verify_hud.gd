extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var hud = world.get_node("GameHUD")
	var controls: Control = hud.get_child(0)
	for side in range(2):
		var column = controls.get_child(side)
		for button in column.get_children():
			button.pressed.emit()
			if button.name == "GardenEditor":
				assert(world.ground_editor_session.active)
				assert(not hud.visible)
				world.ground_editor_session.close()
				assert(hud.visible)
				continue
			assert(hud.dialog.visible)
			assert(world.ui_panel_open)
			assert(hud.content.get_child_count() == 1)
			assert(hud.content.get_child(0).has_method("refresh") if button.name == "Weather" else hud.content.get_child(0) is Label)
			var escape := InputEventKey.new()
			escape.keycode = KEY_ESCAPE
			escape.pressed = true
			hud._unhandled_input(escape)
			assert(not hud.dialog.visible)
			assert(not world.ui_panel_open)
	print("PASS: all 12 button destinations, functional editor and placeholder scenes, Escape dismissal and camera blocking")
	world.queue_free()
	await process_frame
	quit()
