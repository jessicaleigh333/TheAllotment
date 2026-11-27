extends SceneTree

const Catalog := preload("res://features/market/catalog.gd")
const Profiles := preload("res://features/profiles/local_profiles.gd")
const Store := preload("res://features/market/market_store.gd")
const ID := Catalog.ATRIUM.ID

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(not Profiles.new().create("Atrium verification").is_empty())
	var world = preload("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var garden = world.market_garden
	var hud = world.get_node("GameHUD")
	hud._open_market("shop")
	var shop = hud.market_screen
	shop._select(ID)
	var purchase: Button = shop.details.get_node("Buy")
	var cost := Catalog.rune_cost(Catalog.by_id(ID))
	assert(purchase.text.contains(str(cost)) and not purchase.disabled)
	var store: Store = garden.store
	assert(not store.place(ID, Vector2.ZERO, 0, "garden"))
	var before: int = shop.store.data.runes
	purchase.pressed.emit()
	assert(shop.store.data.runes == before - cost and shop.store.count(ID) == 1)
	hud._close()
	garden.reload_items()
	store = garden.store
	assert(not garden._terrain_allowed(Catalog.by_id(ID), Vector2.ZERO, "courtyard"))
	assert(garden.begin(ID, "garden"))
	assert(not garden.place_at(Vector2.ZERO))
	var point := Vector2(-35, 120)
	assert(garden.place_at(point), "Placement on the tested flat plot")
	var atrium: Node3D = garden.placed_root.get_child(0)
	assert(atrium.find_children("*", "CollisionShape3D", true, false).size() > 10)
	assert(not garden.place_at(point + Vector2(14, 0)), "One purchase permits one placement")
	garden.finish()
	await _verify_walk(world, atrium)
	assert(world.local_vault.save())
	world.free()

	world = preload("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	garden = world.market_garden
	store = garden.store
	assert(store.data.placed.size() == 1 and store.data.placed[0].id == ID)
	assert(store.data.runes == before - cost and store.count(ID) == 0)
	atrium = garden.roots.garden.get_child(0)
	assert(atrium.find_children("*", "CollisionShape3D", true, false).size() > 10)
	assert(store.retrieve(0) and store.count(ID) == 1 and store.data.runes == before - cost)
	garden.reload_items()
	assert(garden.roots.garden.get_child_count() == 0)
	var poor: Dictionary = store.data.duplicate(true)
	poor.runes = cost - 1
	assert(store._commit(poor) and not store.buy(ID) and store.data == poor)
	world.free()
	print("PASS: atrium Rune purchase, footprint, live avatar traversal, rail collision, save/reopen and retrieval")
	quit()


func _verify_walk(world: Node3D, atrium: Node3D) -> void:
	var player: CharacterBody3D = world.player
	player.use_requested_direction = true
	player.global_position = atrium.to_global(Vector3(0, 0.10, -6.55))
	await _walk(world, atrium, Vector3.BACK, 45)
	assert(atrium.to_local(player.global_position).z > -5.2)
	player.global_position = atrium.to_global(Vector3(-2.5, 0.08, 0.20))
	await _walk(world, atrium, Vector3.BACK, 160)
	var point := atrium.to_local(player.global_position)
	assert(point.y > 1.56 and point.z > 3.15, "Reach the landing: " + str(point))
	await _walk(world, atrium, Vector3.RIGHT, 145)
	point = atrium.to_local(player.global_position)
	assert(point.x > 0.68 and point.y > 3.16, "Reach the mezzanine: " + str(point))
	await _walk(world, atrium, Vector3.RIGHT, 100)
	point = atrium.to_local(player.global_position)
	assert(point.x < 3.11 and point.y > 3.16, "Upper rail prevents a fall")
	assert(world.camera.global_position.is_finite())

func _walk(world: Node3D, atrium: Node3D, direction: Vector3, frames: int) -> void:
	var player: CharacterBody3D = world.player
	player.velocity = Vector3.ZERO
	for _frame in range(frames):
		var heading := (atrium.global_basis * direction).rotated(Vector3.UP, -world.orbit)
		player.requested_direction = Vector2(heading.x, heading.z)
		await physics_frame
	player.requested_direction = Vector2.ZERO
