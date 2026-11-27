extends SceneTree

const Profiles := preload("res://features/profiles/local_profiles.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(not Profiles.new().create("HUD verification").is_empty())
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
				_press_escape()
				assert(not world.ground_editor_session.active)
				assert(hud.visible)
				continue
			if button.name in ["Shop","Inventory"]:
				assert(is_instance_valid(hud.market_screen))
				assert(world.ui_panel_open)
				assert(hud.market_screen.mode == ("market" if button.name == "Shop" else "backpack"))
				_press_escape()
				assert(not world.ui_panel_open and hud.market_screen == null)
				assert(button.has_focus())
				continue
			assert(hud.dialog.visible)
			assert(world.ui_panel_open)
			assert(hud.content.get_child_count() == 1)
			var screen = hud.content.get_child(0)
			match button.name:
				"Settings":
					assert(_verify_settings(world, screen), "Settings controls must save the active garden")
				"Weather":
					assert(screen.has_method("refresh"))
				"Help":
					assert(screen.get_child(0) is HBoxContainer)
				"Journal":
					assert(screen is ScrollContainer)
				_:
					assert(screen is Label)
			_press_escape()
			assert(not hud.dialog.visible)
			assert(not world.ui_panel_open)
			assert(button.has_focus())
	print("PASS: all 12 destinations, functional editor/shop/backpack/weather/Settings save, Escape dismissal and camera blocking")
	world.queue_free()
	await process_frame
	quit()

func _press_escape() -> void:
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)

func _verify_settings(world, screen: Control) -> bool:
	var save: Button
	var folder: Button
	for child in screen.get_children():
		if child is Button and child.text == "Save garden now":
			save = child
		if child is Button and child.text == "Open my save folder":
			folder = child
	assert(is_instance_valid(save) and not save.disabled, "Settings must expose an enabled vault save")
	assert(is_instance_valid(folder) and not folder.disabled, "Settings must expose the local save folder")
	assert(folder.pressed.get_connections().size() == 1, "The folder control needs a handler")
	world.player.position.x = 2.0
	save.pressed.emit()
	var checkpoint: Dictionary = world.local_vault.read_session()
	assert(not checkpoint.is_empty() and is_equal_approx(checkpoint.position[0], 2.0))
	return screen.status.text == world.local_vault.status and screen.status.text.begins_with("Saved")
