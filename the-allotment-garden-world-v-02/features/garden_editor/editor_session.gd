extends Node
## Coordinates the scoped surface store, UI, live terrain preview and commands.
const Store := preload("res://features/garden_editor/ground_cover/surface_store.gd")
const Adapter := preload("res://features/garden_editor/ground_cover/terrain_adapter.gd")
const PanelScene := preload("res://features/garden_editor/screen.tscn")
const DayNight := preload("res://features/garden_editor/day_night.gd")
var world: Node3D
var garden: Node3D
var store
var terrain
var panel
var ui_layer: CanvasLayer
var clock
var active := false
var painting := false
var last_point: Variant = null
var pending: Array[Vector2] = []
var cursor_point: Variant = null
var ghost: MeshInstance3D
var old_focus := Vector3.ZERO
var old_distance := 390.0
var old_pitch := 1.05
var old_orbit := 0.75
var restore_camera := true
var status_prefix := "Local demo garden • "

func configure(target_world: Node3D, target_garden: Node3D, context: String, actor: String, owner: String, seed: int = 0) -> void:
	world = target_world
	garden = target_garden
	terrain = Adapter.new()
	terrain.from_garden(garden)
	if garden.has_node("GroundCovers"):
		store = garden.get_node("GroundCovers")
	else:
		store = Store.new()
		store.name = "GroundCovers"
		garden.add_child(store)
	store.configure(context, owner, actor, seed, terrain.bounds, terrain.contains, terrain.sample_height, terrain.obstacles)
	_setup_interface()
	clock = world.get_node_or_null("DayNightCycle")
	if clock == null:
		clock = DayNight.new()
		clock.name = "DayNightCycle"
		world.add_child(clock)
		clock.configure(world)
	clock.register_catalog(store.catalog)
	clock.phase_changed.connect(func(_amount: float) -> void:
		if panel != null: panel.refresh_previews()
	)
	if FileAccess.file_exists(store.default_save_path()):
		if not store.load_from(): panel.set_status(store.last_error)

func configure_demo(target_world: Node3D, demo_store, terrain_adapter) -> void:
	world = target_world
	garden = demo_store.get_parent()
	store = demo_store
	terrain = terrain_adapter
	restore_camera = false
	status_prefix = "Demo workshop • "
	_setup_interface()
	clock = world.get_node("DayNightCycle")
	clock.register_catalog(store.catalog)
	clock.phase_changed.connect(func(_amount: float) -> void: panel.refresh_previews())

func _setup_interface() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 3
	add_child(ui_layer)
	panel = PanelScene.instantiate()
	ui_layer.add_child(panel)
	panel.setup(store.catalog)
	panel.close_requested.connect(close)
	panel.tool_changed.connect(func(_tool: String) -> void: cancel_pending())
	panel.action_requested.connect(_action)
	panel.night_changed.connect(func(amount: float) -> void: clock.set_night_amount(amount))
	ghost = MeshInstance3D.new()
	ghost.name = "GroundCoverPreview"
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	garden.add_child(ghost)
	ghost.hide()
	ui_layer.hide()
	store.changed.connect(func() -> void: _show_status())

func open() -> void:
	if active: return
	active = true
	old_focus = world.focus
	old_distance = world.distance
	old_pitch = world.pitch
	old_orbit = world.orbit
	if restore_camera:
		world.focus = garden.to_global(Vector3(0, 0.1, 68))
		world.distance = 62.0
		world.pitch = 1.15
		world.orbit = garden.rotation.y + 0.45
	world.ui_panel_open = false
	world.dragging = false
	if world.has_node("GameHUD"): world.get_node("GameHUD").hide()
	ui_layer.show()
	panel.night_slider.set_value_no_signal(clock.night_amount)
	_show_status()

func close() -> void:
	cancel_pending()
	active = false
	ui_layer.hide()
	ghost.hide()
	world.dragging = false
	if restore_camera:
		world.focus = old_focus
		world.distance = old_distance
		world.pitch = old_pitch
		world.orbit = old_orbit
	if world.has_node("GameHUD"): world.get_node("GameHUD").show()
	if world.has_method("on_ground_editor_closed"): world.on_ground_editor_closed()

func _show_status(extra: String = "") -> void:
	if not store.can_edit():
		panel.set_status("Read-only garden • only the owner can change surfaces.")
		return
	var hint: String = {"paint": "Drag to paint", "erase": "Drag to erase", "recolor": "Drag over a surface to recolor it", "line": "Click a start and an end", "curve": "Click points; Enter to finish", "circle": "Click center and edge", "rectangle": "Click opposite corners", "sample": "Click a placed surface to copy it"}[panel.current_tool]
	panel.set_status(status_prefix + hint + " • Right-drag / WASD to explore • " + (extra if not extra.is_empty() else "%d m² covered" % roundi(store.cells.size() * Store.CELL_SIZE * Store.CELL_SIZE)))

func _pointer_on_ui(point: Vector2 = Vector2(-1, -1)) -> bool:
	if point == Vector2(-1, -1): point = get_viewport().get_mouse_position()
	return point.y < 60 or point.y > get_viewport().get_visible_rect().size.y - 50 or panel.sidebar.get_global_rect().has_point(point)

func _pick(screen_point: Vector2) -> Variant:
	return terrain.pick(world.camera, screen_point)

func _process(_delta: float) -> void:
	if not active: return
	if _pointer_on_ui():
		ghost.hide()
		return
	cursor_point = _pick(get_viewport().get_mouse_position())
	if cursor_point == null or not terrain.contains(cursor_point):
		ghost.hide()
		return
	_render_preview()

func _input(event: InputEvent) -> void:
	# Observe release before GUI handling, so ending a terrain stroke over the
	# sidebar commits it without depending on OS mouse-state polling.
	if active and painting and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		painting = false
		last_point = null
		store.commit_stroke()

func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit and event is InputEventKey: return
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_Z:
			_action("redo" if event.shift_pressed else "undo")
			get_viewport().set_input_as_handled()
		elif event.ctrl_pressed and event.keycode == KEY_Y:
			_action("redo")
			get_viewport().set_input_as_handled()
		elif event.ctrl_pressed and event.keycode == KEY_S:
			_action("save")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			finish_curve()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if painting or not pending.is_empty(): cancel_pending()
			else: close()
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _pointer_on_ui(event.position):
			var point = _pick(event.position)
			if point != null and terrain.contains(point): _click(point)
		elif not event.pressed and painting:
			painting = false
			store.commit_stroke()
			last_point = null
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and painting:
		if _pointer_on_ui(event.position):
			last_point = null
			return
		var point = _pick(event.position)
		if point != null and terrain.contains(point):
			var points: Array = [point] if last_point == null else [last_point, point]
			store.apply_shape({"type": "brush" if points.size() == 1 else "line", "points": points, "width": panel.brush_size}, panel.style, panel.current_tool)
			last_point = point
		get_viewport().set_input_as_handled()

func _click(point: Vector2) -> void:
	get_viewport().gui_release_focus()
	if panel.current_tool == "sample":
		var style: Dictionary = store.sample_style(point)
		if not style.is_empty(): panel.select_style(style)
		return
	if not store.can_edit():
		_show_status()
		return
	if panel.current_tool in ["paint", "erase", "recolor"]:
		painting = store.begin_stroke()
		last_point = point
		store.apply_shape({"type": "brush", "points": [point], "width": panel.brush_size}, panel.style, panel.current_tool)
	else:
		pending.append(point)
		if panel.current_tool != "curve" and pending.size() == 2:
			_commit_shape({"type": panel.current_tool, "points": Array(pending), "width": panel.pathway_width})
			pending.clear()
		else: _show_status("%d control points • click to continue" % pending.size())

func _curve_points(points: Array[Vector2]) -> Array:
	if points.size() < 2: return Array(points)
	var curve := Curve2D.new()
	curve.bake_interval = 0.35
	for i in range(points.size()):
		var previous := points[maxi(0, i - 1)]
		var next := points[mini(points.size() - 1, i + 1)]
		var tangent := (next - previous) / 6.0
		curve.add_point(points[i], -tangent, tangent)
	return Array(curve.get_baked_points())

func finish_curve() -> void:
	if panel.current_tool != "curve" or pending.size() < 2:
		_show_status("Add at least two curve points first.")
		return
	_commit_shape({"type": "curve", "points": _curve_points(pending), "width": panel.pathway_width})
	pending.clear()

func _commit_shape(shape: Dictionary) -> void:
	var count: int = store.apply_shape(shape, panel.style, "paint", panel.border_settings())
	_show_status("Placed %d m²" % roundi(count * Store.CELL_SIZE * Store.CELL_SIZE) if store.last_error.is_empty() else store.last_error)

func cancel_pending() -> void:
	painting = false
	last_point = null
	pending.clear()
	if store != null: store.cancel_stroke()
	if ghost != null: ghost.hide()

func _action(action: String) -> void:
	if action == "finish_curve":
		finish_curve()
		return
	cancel_pending()
	match action:
		"undo": store.undo(); _show_status("Undo")
		"redo": store.redo(); _show_status("Redo")
		"save": _show_status("Landscaping saved." if store.save_to() else store.last_error)
		"load": _show_status("Saved landscaping restored." if store.load_from() else store.last_error)
		"demo":
			get_tree().change_scene_to_file("res://staging/ground_cover_demo.tscn")

func _render_preview() -> void:
	var polygon := PackedVector2Array()
	var radius: float = panel.brush_size / 2.0
	var tool: String = panel.current_tool
	if tool in ["line", "curve", "rectangle", "circle"] and not pending.is_empty():
		if tool == "rectangle":
			var a: Vector2 = pending[0]
			var b: Vector2 = cursor_point
			polygon = PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)])
		elif tool == "circle":
			radius = pending[0].distance_to(cursor_point)
			for i in range(48): polygon.append(pending[0] + Vector2.from_angle(float(i) * TAU / 48) * radius)
		else:
			var points: Array[Vector2] = pending.duplicate()
			points.append(cursor_point)
			var path: Array = _curve_points(points) if tool == "curve" else Array(points)
			_render_path_preview(path, panel.pathway_width / 2.0)
			return
	else:
		for i in range(48): polygon.append(cursor_point + Vector2.from_angle(float(i) * TAU / 48) * radius)
	var indices := Geometry2D.triangulate_polygon(polygon)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.UP)
	surface.set_color(Color(0, 0, 0, 0))
	var added := false
	for i in range(0, indices.size(), 3):
		var tri := [polygon[indices[i]], polygon[indices[i + 1]], polygon[indices[i + 2]]]
		if not _preview_triangle_allowed(tri): continue
		for point in tri:
			surface.set_uv(point)
			surface.add_vertex(Vector3(point.x, terrain.sample_height(point) + 0.06, point.y))
		added = true
	_finish_preview(surface, added)

func _preview_triangle_allowed(points: Array) -> bool:
	for point in points:
		if not terrain.contains(point): return false
	return true

func _render_path_preview(path: Array, width: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.UP)
	surface.set_color(Color(0, 0, 0, 0))
	var added := false
	for i in range(path.size() - 1):
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var direction := (b - a).normalized().orthogonal() * width
		var points := [a + direction, a - direction, b - direction, a + direction, b - direction, b + direction]
		if not _preview_triangle_allowed(points): continue
		for point in points:
			surface.set_uv(point)
			surface.add_vertex(Vector3(point.x, terrain.sample_height(point) + 0.06, point.y))
		added = true
	_finish_preview(surface, added)

func _finish_preview(surface: SurfaceTool, added: bool) -> void:
	if not added:
		ghost.hide()
		return
	ghost.mesh = surface.commit()
	var material: ShaderMaterial = store.catalog.material_for(panel.style).duplicate()
	material.set_shader_parameter("preview_opacity", 0.58)
	ghost.material_override = material
	ghost.show()
