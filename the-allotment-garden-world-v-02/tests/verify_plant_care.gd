extends SceneTree

const Growth := preload("res://features/market/plant_growth.gd")
const Profiles := preload("res://features/profiles/local_profiles.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(not Profiles.new().create("Care verification").is_empty())
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var placement = world.market_garden
	assert(placement.begin("basil@seed", "garden"))
	assert(placement.place_at(Vector2(4, 55)))
	placement.finish()
	assert(placement.begin("watering_can", "garden"))
	assert(placement.place_at(Vector2(7, 55)))
	placement.finish()
	var hud = world.get_node("GameHUD")
	hud._open_market("inventory")
	var screen = hud.market_screen
	assert(not screen.store.water(1), "Decorative tools cannot be watered")
	var original: Dictionary = screen.store.data.placed[0].growth.duplicate()
	var runes: int = screen.store.data.runes
	screen._show_placed()
	var water: Button
	for child in screen.details.get_children():
		if child is Button and child.text.begins_with("Water Sweet basil"):
			water = child
	assert(is_instance_valid(water) and not water.disabled)
	water.pressed.emit()
	var recorded: int = int(screen.store.data.placed[0].get("last_watered_at", 0))
	assert(recorded > 0)
	assert(screen.store.data.placed[0].growth == original)
	assert(screen.store.data.runes == runes)
	assert(not screen.store.data.placed[1].has("last_watered_at"))
	hud._close()
	assert(world.local_vault.save())
	world.free()
	world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var persisted: Dictionary = world.market_garden.store.data.placed[0]
	assert(int(persisted.last_watered_at) == recorded)
	assert(Growth.species(persisted.id) == "basil")
	assert(persisted.growth.started_at == original.started_at)
	world.free()
	print("PASS: planting, Backpack watering, decorative exclusion, unchanged growth and balance, vault save and reopen")
	quit()
