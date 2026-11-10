extends "res://staging/garden_art_gallery.gd"
const Rules := preload("res://features/market/stack_rules.gd")
var assembly_records: Array = []
func _ready() -> void:
 super._ready()
 asset_choice.clear()
 for entry in Art.Roman.CATALOG:
  asset_choice.add_item(entry.name)
  asset_choice.set_item_metadata(asset_choice.item_count-1,entry.id)
 var assembly := Button.new()
 assembly.text = "Show stacked colonnade"
 assembly.pressed.connect(show_assembly)
 stats.get_parent().add_child(assembly)
 show_asset("corinthian_column")

func show_assembly() -> void:
 if is_instance_valid(specimen):
  remove_child(specimen)
  specimen.queue_free()
 specimen = Node3D.new()
 add_child(specimen)
 assembly_records.clear()
 for x in [-1.2,1.2]:
  var height := 0.0
  for id in ["roman_plinth","attic_column_base","fluted_column_drum","fluted_column_drum","corinthian_capital"]:
   _part(id,Vector2(x,0),height)
   height += Rules.size(id).y
 _part("roman_architrave",Vector2.ZERO,3.1)
 _part("garden_muse_bust",Vector2.ZERO,3.45)
 target = _bounds(specimen).get_center()
 distance = 12
 orbit = .4
 pitch = .22
 heading.text = "Stacked Roman garden colonnade"
 stats.text = "12 separate supported pieces · 5.15 m tall\nSame module dimensions and support rules as the Shop"
 stage_choice.hide()
 gate_control.hide()
 _update_camera()

func _part(id: String, point: Vector2, height: float) -> void:
 var parents := Rules.supports_for(id,point,0,height,assembly_records,"garden") if height > 0 else []
 var record := {"id":id,"uid":Crypto.new().generate_random_bytes(12).hex_encode(),"x":point.x,"z":point.y,"angle":0.0,"ground_y":0.0,"area":"garden"}
 if height > 0:
  record.elevation = height
  record.supports = parents
 assembly_records.append(record)
 var model := Model.instantiate()
 model.item_id = id
 model.position = Vector3(point.x,height,point.y)
 specimen.add_child(model)
