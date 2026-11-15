extends "res://scripts/world.gd"

const PLANT = preload("res://scenes/plant_prototype.tscn")
const ENTRIES := [
	["Blush flower", 0, 0, 0, 0.8, 0],
	["Golden flower", 0, 1, 1, 0.8, 0],
	["Lilac flower", 0, 2, 2, 0.8, 0],
	["Cream flower", 0, 3, 0, 0.8, 0],
	["Rose-pink flower", 0, 4, 1, 0.8, 0],
	["Apricot flower", 0, 5, 2, 0.8, 0],
	["Flowering border shrub", 1, 0, 0, 0.8, 0],
	["Leafy border shrub", 1, 0, 0, 0.8, 1],
	["Large leafy shrub", 1, 0, 0, 1.2, 2],
]
var specimen: Node3D
var details: Label

func _ready() -> void:
	_build_lighting()
	_box(Vector3(0, -0.18, 0), Vector3(200, 0.3, 200), Color("799767"))
	_cylinder(Vector3.ZERO, 1.65, 0.12, Color("bda88b"))
	focus = Vector3(0, 0.7, 0)
	distance = 6.0
	pitch = 0.35
	_build_camera()
	_build_catalog_ui()
	_select(0)

func _process(_delta: float) -> void:
	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(3.0, distance - 0.5)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(12.0, distance + 0.5)
	elif event is InputEventMouseMotion and dragging:
		orbit -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.006, 0.15, 1.35)

func _build_catalog_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size.x = 275
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "THE ALLOTMENT\nFlowers & shrubs"
	heading.add_theme_font_size_override("font_size", 22)
	column.add_child(heading)
	var note := Label.new()
	note.text = "Existing prototype models\nRight-drag: orbit · Wheel: zoom"
	column.add_child(note)
	for category in [0, 1]:
		var label := Label.new()
		label.text = "FLOWERS" if category == 0 else "SHRUBS"
		column.add_child(label)
		for index in range(ENTRIES.size()):
			if ENTRIES[index][1] != category:
				continue
			var button := Button.new()
			button.text = ENTRIES[index][0]
			button.pressed.connect(_select.bind(index))
			column.add_child(button)
	details = Label.new()
	column.add_child(details)

func _select(index: int) -> void:
	if is_instance_valid(specimen):
		remove_child(specimen)
		specimen.queue_free()
	var entry: Array = ENTRIES[index]
	specimen = PLANT.instantiate()
	specimen.plant_kind = entry[1]
	specimen.palette = entry[2]
	specimen.flower_variant = entry[3]
	specimen.shrub_size = entry[4]
	specimen.shrub_seed = entry[5]
	specimen.position.y = 0.06
	add_child(specimen)
	details.text = "%s\nPrototype · ready for art review\nDecorative, no collision" % entry[0]
