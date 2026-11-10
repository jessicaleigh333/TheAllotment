extends "res://scripts/world.gd"
const Growth := preload("res://features/market/plant_growth.gd")
const Model := preload("res://features/market/item_model.tscn")

func _ready() -> void:
	_build_lighting()
	_box(Vector3(0,-.06,0),Vector3(20,.12,21),Color("82946a"))
	var row := 0
	for plant in Growth.PLANTS:
		var column := 0
		for suffix in ["@seed","@seedling","@young",""]:
			var model := Model.instantiate()
			model.item_id = plant+suffix
			model.position = Vector3(-4.5+column*3,0,-6.6+row*2.2)
			add_child(model)
			var label := Label3D.new()
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.text = plant.capitalize()+" · "+Growth.STAGES[Growth.starting_stage(model.item_id)]
			label.pixel_size = .007
			label.position = model.position+Vector3(0,.12,1)
			add_child(label)
			column += 1
		row += 1
	# One-metre rods and a 1.65-metre human-height reference share the plant scale.
	for y in range(11):
		_box(Vector3(6.5,float(y)*.1,0),Vector3(.18,.012,.06),Color("f3e6c5"))
	_box(Vector3(6.5,.5,0),Vector3(.025,1,.025),Color("6b503b"))
	_box(Vector3(7.5,.825,0),Vector3(.35,1.65,.20),Color("c6b28a"))
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.position = Vector2(18,18)
	title.text = "PLANT SCALE STUDIO · metre scale\nColumns: Seed · Seedling · Young · Mature\nRight-hand ruler: 1 m · person reference: 1.65 m\nWASD: pan · Right-drag: orbit · Wheel: zoom"
	title.add_theme_font_size_override("font_size",16)
	layer.add_child(title)
	focus = Vector3.ZERO
	distance = 22
	orbit = 0
	pitch = .86
	_build_camera()
