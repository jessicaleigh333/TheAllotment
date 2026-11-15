extends "res://staging/garden_art_gallery.gd"
var cycle
var night_button: Button
func _ready() -> void:
 super._ready()
 asset_choice.clear()
 for entry in Art.Enchanted.CATALOG:
  asset_choice.add_item(entry.name)
  asset_choice.set_item_metadata(asset_choice.item_count-1,entry.id)
 cycle = preload("res://features/garden_editor/day_night.gd").new()
 cycle.name = "DayNightCycle"
 add_child(cycle)
 cycle.configure(self)
 night_button = Button.new()
 night_button.text = "Preview: night · click for day"
 night_button.pressed.connect(func() -> void:
  cycle.set_night_amount(0 if cycle.night_amount > .5 else 1)
  night_button.text = "Preview: night · click for day" if cycle.night_amount > .5 else "Preview: day · click for night")
 stats.get_parent().add_child(night_button)
 cycle.phase_changed.connect(func(amount: float) -> void:
  night_button.text = "Preview: night · click for day" if amount > .5 else "Preview: day · click for night")
 var assembled := Button.new()
 assembled.text = "Show enchanted garden scene"
 assembled.pressed.connect(show_garden)
 stats.get_parent().add_child(assembled)
 show_asset("fairy_mushroom_house")
 cycle.set_night_amount(1)

func show_garden() -> void:
 if is_instance_valid(specimen):
  remove_child(specimen)
  specimen.queue_free()
 specimen = Node3D.new()
 add_child(specimen)
 for entry in [["moon_arch",Vector3(0,0,-1.2)],["fairy_mushroom_house",Vector3(-1.8,0,.2)],["glow_mushrooms",Vector3(-1.1,0,1.1)],["crystal_cluster",Vector3(1.7,0,.3)],["witch_cauldron",Vector3(1.5,0,1.5)],["moon_lantern",Vector3(-2.8,0,-.8)],["enchanted_tree",Vector3(2.8,0,-1.5)],["lotus_lamp",Vector3(0,0,1.9)],["firefly_jar",Vector3(-.5,0,1.8)]]:
  var model := Model.instantiate()
  model.item_id = entry[0]
  model.position = entry[1]
  specimen.add_child(model)
 target = Vector3(0,1,0)
 distance = 10
 orbit = .3
 pitch = .28
 heading.text = "Witchy fairy moon garden"
 stats.text = "Nine freely placeable decorations · day/night preview"
 stage_choice.hide()
 gate_control.hide()
 _update_camera()
 cycle.update_decor_lights()
