extends SceneTree
## Run with a graphical display. Captures actual rendered day/night/UI previews.
func _initialize() -> void:
	call_deferred("_verify")

func _frames(count: int) -> void:
	for i in range(count): await process_frame
	await RenderingServer.frame_post_draw

func _verify() -> void:
	assert(DisplayServer.get_name() != "headless", "This check needs an OpenGL-capable graphical display")
	var demo = load("res://staging/ground_cover_demo.tscn").instantiate()
	root.add_child(demo)
	demo.editor_session.set_process(false)
	demo.editor_session.ghost.hide()
	await _frames(15)
	var day := root.get_texture().get_image()
	assert(not day.is_empty())
	day.save_png("user://ground_cover_day.png")
	# Daytime and night emission share the same stored colors and geometry.
	var before: Dictionary = demo.demo_store.snapshot()
	demo.get_node("DayNightCycle").set_night_amount(1)
	demo.editor_session.panel.night_slider.set_value_no_signal(1)
	await _frames(8)
	var night := root.get_texture().get_image()
	night.save_png("user://ground_cover_night.png")
	assert(demo.demo_store.snapshot() == before)
	var gravel_point: Vector2 = demo.camera.unproject_position(Vector3(-15,demo._height(Vector2(-15,0)),0))
	var ordinary_point: Vector2 = demo.camera.unproject_position(Vector3(0,demo._height(Vector2(0,0)),0))
	var day_brightness := 0.0
	var night_brightness := 0.0
	for x in range(-10,11):
		for y in range(-10,11):
			var point := Vector2i(ordinary_point) + Vector2i(x,y)
			day_brightness += day.get_pixelv(point).get_luminance()
			night_brightness += night.get_pixelv(point).get_luminance()
	assert(day_brightness > night_brightness * 2.0, "Ordinary tiles should darken under moonlight")
	var glow_pixels: Array[float] = []
	var ordinary_pixels: Array[float] = []
	for x in range(-12,13):
		for y in range(-10,11):
			glow_pixels.append(night.get_pixelv(Vector2i(gravel_point) + Vector2i(x,y)).get_luminance())
			ordinary_pixels.append(night.get_pixelv(Vector2i(ordinary_point) + Vector2i(x,y)).get_luminance())
	glow_pixels.sort()
	ordinary_pixels.sort()
	# Scattered accents do not illuminate their whole gravel bed; compare the
	# visible luminous detail samples, rather than the area's mean brightness.
	var index := floori(glow_pixels.size() * 0.95)
	print("Night luminance, 95th percentile: luminous detail=", glow_pixels[index], "; ordinary tile=", ordinary_pixels[index])
	assert(glow_pixels[index] > ordinary_pixels[index] * 1.3, "Luminous details should stay brighter than unlit tiles at night")
	var panel = demo.editor_session.panel
	panel.select_style(demo.demo_store.catalog.default_style("glowing_stepping_stones"))
	panel.component.select(3)
	panel.selected_component = "glow_color"
	panel.color_picker.color = Color.html(panel.style.glow_color)
	panel.scroll.scroll_vertical = maxi(0, int(panel.color_picker.position.y) - 45)
	await _frames(5)
	root.get_texture().get_image().save_png("user://ground_cover_customization.png")
	print("PASS: actual shader rendering, daylight/night contrast, visible luminous details, unchanged placement state, color-wheel UI; captures saved under user://")
	demo.queue_free()
	await process_frame
	quit()
