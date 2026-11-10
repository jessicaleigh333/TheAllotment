extends "res://staging/garden_art_gallery.gd"
## Dedicated close-up browser for the 22 French garden additions.
func _ready() -> void:
	super._ready()
	asset_choice.clear()
	for entry in Art.French.CATALOG:
		asset_choice.add_item(entry.name)
		asset_choice.set_item_metadata(asset_choice.item_count-1,entry.id)
	show_asset("anduze_jar")
