extends SceneTree

const Profiles := preload("res://features/profiles/local_profiles.gd")
const Store := preload("res://features/market/market_store.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(not Profiles.new().create("Harvest verification").is_empty())
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var placement = world.market_garden
	assert(placement.begin("basil@seed", "garden"))
	assert(placement.place_at(Vector2(4, 55)))
	placement.finish()
	assert(placement.begin("cosmos", "garden"))
	assert(placement.place_at(Vector2(7, 55)))
	placement.finish()

	var store := Store.new()
	assert(not store.harvest(0), "Seeds cannot yield")
	assert(not store.harvest(1), "Free mature purchases need time in the garden")
	var history := store.data.duplicate(true)
	history.placed[0].growth.started_at -= 60 * 86400
	history.placed[1].growth.started_at -= 15 * 86400
	assert(store._commit(history))
	placement.reload_items()

	var hud = world.get_node("GameHUD")
	hud._open_market("inventory")
	var screen = hud.market_screen
	assert(screen.planted_items_button.visible)
	screen.planted_items_button.pressed.emit()
	_press(screen.details, "Harvest 3 · Sweet basil")
	assert(int(screen.store.data.harvest_stock.get("basil", 0)) == 3)
	_press(screen.details, "Harvest 2 · Cosmos")
	assert(int(screen.store.data.harvest_stock.get("cosmos", 0)) == 2)
	assert(screen.store.data.placed.size() == 2)
	assert(not screen.store.harvest(0), "The same plant must not yield twice at once")
	var purse: int = int(screen.store.data.runes)
	_press(screen.details, "Basil sprig ×3 · Sell one")
	assert(int(screen.store.data.harvest_stock.basil) == 2)
	assert(int(screen.store.data.harvest_stock.cosmos) == 2)
	assert(int(screen.store.data.runes) == purse + 2)
	hud._close()
	assert(world.local_vault.save())
	world.free()
	world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame

	store = world.market_garden.store
	assert(int(store.data.harvest_stock.basil) == 2 and int(store.data.harvest_stock.cosmos) == 2)
	assert(int(store.data.runes) == purse + 2 and store.data.placed.size() == 2)
	assert(not store.harvest(0), "Cooldown must survive a vault save and reopen")
	assert(store.retrieve(0) and store.count("basil") == 1)
	assert(store.place("basil", Vector2(4, 55), 0.0))
	assert(not store.harvest(1), "Pickup and replant must not bypass the waiting interval")
	world.free()
	print("PASS: planted seed growth, species-specific yield, backpack sale, cooldown, vault save/reopen and replant guard")
	quit()

func _press(container: Control, label_prefix: String) -> void:
	for child in container.get_children():
		if child is Button and child.text.begins_with(label_prefix):
			child.pressed.emit()
			return
	push_error("Missing Backpack control: " + label_prefix)
