extends "res://scripts/world.gd"
## Editable, sloped workshop: eight starter surfaces plus a layered courtyard.
@export var start_at_night := false
const Store := preload("res://features/garden_editor/ground_cover/surface_store.gd")
const Adapter := preload("res://features/garden_editor/ground_cover/terrain_adapter.gd")
const Session := preload("res://features/garden_editor/editor_session.gd")
const DayNight := preload("res://features/garden_editor/day_night.gd")
var demo_store
var demo_terrain
var editor_session
var demo_area: Node3D

func _ready() -> void:
	focus = Vector3(-8, 0, 0)
	orbit = 0.0
	super._ready()
	var cycle := DayNight.new()
	cycle.name = "DayNightCycle"
	add_child(cycle)
	cycle.configure(self)
	cycle.register_catalog(demo_store.catalog)
	editor_session = Session.new()
	editor_session.name = "GroundEditorSession"
	add_child(editor_session)
	editor_session.configure_demo(self, demo_store, demo_terrain)
	editor_session.open()
	cycle.set_night_amount(1.0 if start_at_night else 0.0)
	editor_session.panel.night_slider.set_value_no_signal(cycle.night_amount)

func _build_hud() -> void:
	pass

func _height(point: Vector2) -> float:
	return 0.06 * point.x + 0.025 * point.y

func _build_neighborhood() -> void:
	demo_area = Node3D.new()
	demo_area.name = "SurfaceWorkshop"
	add_child(demo_area)
	demo_terrain = Adapter.new()
	demo_terrain.target = demo_area
	demo_terrain.bounds = Rect2(-24, -18, 48, 36)
	demo_terrain.outline = PackedVector2Array([Vector2(-24,-18), Vector2(24,-18), Vector2(24,18), Vector2(-24,18)])
	var corners := PackedVector3Array()
	for point in demo_terrain.outline: corners.append(Vector3(point.x, _height(point), point.y))
	demo_terrain.triangles.append(PackedVector3Array([corners[0],corners[1],corners[2]]))
	demo_terrain.triangles.append(PackedVector3Array([corners[0],corners[2],corners[3]]))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3(-0.06, 1, -0.025).normalized())
	for index in [0,1,2,0,2,3]: surface.add_vertex(corners[index] - Vector3(0,0.02,0))
	var lawn := MeshInstance3D.new()
	lawn.mesh = surface.commit()
	lawn.material_override = _material(Color("5e8051"))
	demo_area.add_child(lawn)
	demo_store = Store.new()
	demo_store.name = "GroundCovers"
	demo_area.add_child(demo_store)
	demo_store.configure("workshop_demo", "local-demo", "local-demo", 20261013, demo_terrain.bounds, demo_terrain.contains, demo_terrain.sample_height)
	var ids := ["cobblestone", "brick", "moss", "gravel", "basic_tile", "ornate_tile", "glowing_pebbles", "glowing_stepping_stones", "marble"]
	for index in range(9):
		var position := Vector2((index % 3 - 1) * 15.0, (floori(index / 3.0) - 1) * 11.0)
		var style: Dictionary = demo_store.catalog.default_style(ids[index])
		var border := {}
		if index == 0:
			style.joint = "477143ff"
			style.accent = "659455ff"
			style.detail_id = "moss"
			style.detail_amount = 0.7
		elif index == 1:
			style.rotation = 45.0
			style.base = "b07352ff"
		elif index == 3:
			style.detail_id = "glowing_pebbles"
			style.detail_amount = 0.5
			style.glow_enabled = true
			style.glow_color = "70e0c9ff"
			style.glow_intensity = 2.5
		elif index == 4:
			style.base = "edeee0ff"
			style.joint = "49769aff"
			style.roughness = 0.2
		elif index == 5:
			style.glow_enabled = true
			style.glow_mode = 4
			style.glow_color = "e9b5ffff"
			style.glow_intensity = 2.2
		elif index == 6:
			style.glow_palette = 1
			style.glow_mode = 5
		elif index == 7:
			style.glow_palette = 2
			style.scale = 1.3
			style.glow_mode = 0
		elif index == 8:
			style.base = "ede8d5ff"
			style.accent = "fff4dfff"
			style.detail_id = "ornate_tile"
			style.detail_amount = 0.75
			style.glow_enabled = true
			style.glow_mode = 4
			style.glow_color = "76c5ffff"
			var edging: Dictionary = demo_store.catalog.default_style("ornate_tile")
			edging.base = "273c48ff"
			edging.accent = "608aafff"
			edging.glow_enabled = true
			edging.glow_mode = 3
			edging.glow_color = "a47bffff"
			border = {"style": edging, "width": 0.5}
		demo_store.apply_shape({"type": "rectangle", "points": [position - Vector2(5.5,3.5), position + Vector2(5.5,3.5)], "width": 1.0}, style, "paint", border)
		var label := Label3D.new()
		label.text = ["Cobble · moss joints", "Terracotta brick", "Moss ground cover", "Gravel · glow accents", "Tile · blue grout", "Ornate · luminous inlay", "Glow pebbles", "Glow stepping stones", "Marble · inlay & border"][index]
		label.font_size = 48
		label.pixel_size = 0.018
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("fff2cb")
		label.outline_modulate = Color("263b2a")
		label.outline_size = 3
		label.position = Vector3(position.x, _height(position) + 0.6, position.y - 4.3)
		demo_area.add_child(label)
	var trail: Dictionary = demo_store.catalog.default_style("glowing_pebbles")
	trail.glow_palette = 1
	trail.glow_color = "55c7ffff"
	trail.glow_secondary = "b58cffff"
	trail.glow_mode = 1
	demo_store.apply_shape({"type": "curve", "points": [Vector2(-21,16),Vector2(-14,16),Vector2(-8,15.5),Vector2(0,16.5),Vector2(8,16),Vector2(15,16.5),Vector2(21,16)], "width": 1.5}, trail)
	demo_store.undo_stack.clear()
	demo_store.redo_stack.clear()
	demo_store.flush_meshes()

func on_ground_editor_closed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_N:
		var amount: float = 1.0 - get_node("DayNightCycle").night_amount
		get_node("DayNightCycle").set_night_amount(amount)
		editor_session.panel.night_slider.set_value_no_signal(amount)
		get_viewport().set_input_as_handled()
	else: super._unhandled_input(event)
