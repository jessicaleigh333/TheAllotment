extends SceneTree
const Favorites := preload("res://features/garden_editor/ground_cover/favorites.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _mouse(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	root.push_input(event, true)

func _verify() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.open_ground_editor()
	var session = world.ground_editor_session
	var panel = session.panel
	await process_frame
	for index in range(panel.category.item_count):
		panel.category.select(index)
		panel._refresh_catalog()
		assert(panel.catalog_grid.get_child_count() > 0)
	panel.search.text = "moon-shaped"
	panel._refresh_catalog()
	assert(panel.catalog_grid.get_child_count() == 1)
	panel.search.text = "not-a-material"
	panel._refresh_catalog()
	assert(panel.catalog_grid.get_child_count() == 0)
	panel.search.text = ""
	panel.category.select(0)
	panel._refresh_catalog()
	assert(panel.catalog_grid.get_child_count() == 8)
	panel.select_style(session.store.catalog.default_style("brick"))
	panel.color_picker.color = Color("48a2b9")
	panel._choose_color(Color("48a2b9"))
	panel.sliders.rotation.value = 90
	panel.glow_toggle.button_pressed = true
	assert(panel.style.base == Color("48a2b9").to_html())
	assert(panel.style.rotation == 90 and panel.style.glow_enabled)
	panel.border_id = "metal_edging"
	panel.border_color = Color("89adbc")
	panel.border_glow = true
	assert(panel.border_settings().style.metallic == 0.85)
	assert(panel.border_settings().style.glow_enabled)
	var favorites = Favorites.new(session.store.catalog, "user://ground_cover/automated_test_favorites.json")
	assert(favorites.save_color(Color("aabbcc")))
	assert(favorites.save_combination(panel.style))
	var reloaded = Favorites.new(session.store.catalog, "user://ground_cover/automated_test_favorites.json")
	assert(reloaded.colors == [Color("aabbcc").to_html()])
	assert(reloaded.combinations[0].style == panel.style)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ground_cover/automated_test_favorites.json"))
	# Pointer events through the actual viewport paint a stroke and commit on release.
	panel._select_tool("paint")
	world._update_camera()
	var a: Vector2 = world.camera.unproject_position(session.garden.to_global(Vector3(10,0.1,65)))
	var b: Vector2 = world.camera.unproject_position(session.garden.to_global(Vector3(12,0.1,65)))
	assert(a.x > 358 and a.y > 60 and a.y < 670)
	var history_count: int = session.store.undo_stack.size()
	_mouse(a,true)
	await process_frame
	assert(session.painting)
	var motion := InputEventMouseMotion.new()
	motion.position = b
	motion.global_position = b
	motion.relative = b - a
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	await process_frame
	_mouse(b,false)
	await process_frame
	assert(not session.painting and not session.store.transaction)
	assert(session.store.undo_stack.size() == history_count + 1)
	assert(session.store.sample_style(Vector2(11,65)).base == panel.style.base)
	# Releasing over UI must also commit the brush rather than leave it active.
	a = world.camera.unproject_position(session.garden.to_global(Vector3(9,0.1,69)))
	_mouse(a,true)
	await process_frame
	_mouse(Vector2(50,400),false)
	await process_frame
	await process_frame
	assert(not session.painting and not session.store.transaction)
	# Enter finishes a clicked curve even after selecting a tool button.
	panel._select_tool("curve")
	panel.tool_buttons.curve.grab_focus()
	for point in [Vector2(4,70),Vector2(8,74),Vector2(4,78)]: session._click(point)
	assert(get_root().gui_get_focus_owner() == null)
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	root.push_input(key, true)
	await process_frame
	assert(session.pending.is_empty())
	panel.night_slider.value = 1.0
	assert(session.clock.night_amount == 1.0 and session.store.catalog.night_amount == 1.0)
	var hud = world.get_node("GameHUD")
	panel.close_requested.emit()
	assert(hud.visible and not session.active)
	world.queue_free()
	await process_frame
	print("PASS: all catalog categories and search, live color/rotation/glow UI, independent metal border, favorite persistence, real mouse strokes, UI-release regression, curve Enter and day/night controls")
	quit()
