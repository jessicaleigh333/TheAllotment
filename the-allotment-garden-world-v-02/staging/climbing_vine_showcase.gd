extends Node3D
const Model := preload("res://features/market/item_model.tscn")
const Vines := preload("res://features/market/climbing_vines.gd")
const Growth := preload("res://features/market/plant_growth.gd")
const Art := preload("res://assets/garden_art/garden_library.gd")
var plant_id := "clematis"
var support_id := "rustic_arbor"
var stage := 4
var specimens: Node3D
var camera: Camera3D
var info: Label
var plant_choice: OptionButton
var support_choice: OptionButton
var heading := .6
var pitch := .24
var distance := 4.8
var dragging := false
func _ready() -> void:
 Art.Builder.set_night(0.)
 var environment := WorldEnvironment.new()
 environment.environment = Environment.new()
 environment.environment.background_mode = Environment.BG_COLOR
 environment.environment.background_color = Color("c4d3d0")
 environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color = Color("eee8ce")
 environment.environment.ambient_light_energy = .6
 add_child(environment)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-48,-30,0)
 sun.light_energy = 1.1
 sun.shadow_enabled = true
 add_child(sun)
 var floor_mesh := MeshInstance3D.new()
 floor_mesh.mesh = PlaneMesh.new()
 floor_mesh.mesh.size = Vector2(200,200)
 var material := StandardMaterial3D.new()
 material.albedo_color = Color("8b9b72")
 floor_mesh.material_override = material
 add_child(floor_mesh)
 camera = Camera3D.new()
 add_child(camera)
 var ui := CanvasLayer.new()
 add_child(ui)
 var panel := PanelContainer.new()
 panel.position = Vector2(18,18)
 panel.custom_minimum_size.x = 300
 ui.add_child(panel)
 var box := VBoxContainer.new()
 panel.add_child(box)
 var title := Label.new()
 title.text = "Climbing vines · 3D review"
 title.add_theme_font_size_override("font_size",23)
 box.add_child(title)
 var plants := OptionButton.new()
 plant_choice = plants
 for id in Vines.REACH: plants.add_item(id.replace("_"," ").capitalize())
 plants.select(1)
 plants.item_selected.connect(func(index: int) -> void: plant_id = Vines.REACH.keys()[index]; rebuild())
 box.add_child(plants)
 var supports := OptionButton.new()
 support_choice = supports
 for id in ["rustic_arbor","branch_trellis","vine_pergola","corinthian_column","lantern_picnic_canopy"]:
  supports.add_item(id.replace("_"," ").capitalize())
  supports.set_item_metadata(supports.item_count-1,id)
 supports.item_selected.connect(func(index: int) -> void: support_id = supports.get_item_metadata(index); rebuild())
 box.add_child(supports)
 var stages := OptionButton.new()
 for i in [0,2,3,4]:
  stages.add_item(Growth.STAGES[i])
  stages.set_item_metadata(stages.item_count-1,i)
 stages.select(3)
 stages.item_selected.connect(func(index: int) -> void: stage = stages.get_item_metadata(index); rebuild())
 box.add_child(stages)
 info = Label.new()
 box.add_child(info)
 var note := Label.new()
 note.text = "Preview ages only. Live growth uses real days.\nRight-drag: orbit · Wheel: zoom\nExisting decorative foliage stays on older props."
 box.add_child(note)
 rebuild()
func rebuild() -> void:
 plant_choice.select(Vines.REACH.keys().find(plant_id))
 for i in range(support_choice.item_count):
  if support_choice.get_item_metadata(i) == support_id: support_choice.select(i)
 if specimens != null: specimens.free()
 specimens = Node3D.new()
 add_child(specimens)
 var support := Model.instantiate()
 support.item_id = support_id
 specimens.add_child(support)
 var support_record := {"id":support_id,"x":0.,"z":0.,"angle":0.,"area":"garden","ground_y":0.,"uid":"111111111111111111111111"}
 var route := Vines.world_route(support_record,Vines.routes(support_id)[0],[support_record])
 var point: Vector3 = route[0]+Vector3(0,0,.55)
 var record := {"id":plant_id,"x":point.x,"z":point.z,"angle":0.,"area":"garden","ground_y":0.,"uid":"222222222222222222222222"}
 var plant := Model.instantiate()
 plant.item_id = plant_id
 plant.growth_age_days = Growth.PLANTS[plant_id].days[stage]
 plant.position = Vector3(point.x,0,point.z)
 plant.set_meta("placement_record",record)
 specimens.add_child(plant)
 Vines.refresh({"garden":specimens},[support_record,record])
 info.text = "Plant age: %s real days\n%s" % [plant.growth_age_days,"Training onto nearby support" if plant.has_meta("climbing_support") else "No nearby support"]
 _update_camera()
func _update_camera() -> void:
 var target := Vector3(0,1.25,0)
 camera.position = target+Vector3(sin(heading)*cos(pitch),sin(pitch),cos(heading)*cos(pitch))*distance
 camera.look_at(target)
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_RIGHT: dragging = event.pressed
  elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   distance = clampf(distance+(-.5 if event.button_index == MOUSE_BUTTON_WHEEL_UP else .5),2,15)
   _update_camera()
 elif event is InputEventMouseMotion and dragging:
  heading -= event.relative.x*.008
  pitch = clampf(pitch+event.relative.y*.006,.05,1.2)
  _update_camera()
