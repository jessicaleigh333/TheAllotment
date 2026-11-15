extends "res://staging/garden_art_gallery.gd"
var cycle
func _ready() -> void:
 super._ready()
 asset_choice.clear()
 for entry in Art.Rustic.CATALOG:
  asset_choice.add_item(entry.name)
  asset_choice.set_item_metadata(asset_choice.item_count-1,entry.id)
 cycle = preload("res://features/garden_editor/day_night.gd").new()
 add_child(cycle)
 cycle.configure(self)
 var toggle := Button.new()
 toggle.text = "Toggle day / night"
 toggle.pressed.connect(func() -> void: cycle.set_night_amount(0 if cycle.night_amount > .5 else 1))
 stats.get_parent().add_child(toggle)
 show_asset("willow_teepee_planter")
