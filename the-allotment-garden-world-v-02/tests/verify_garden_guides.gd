extends SceneTree

const Profiles := preload("res://features/profiles/local_profiles.gd")
const Store := preload("res://features/market/market_store.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(not Profiles.new().create("Diary verification").is_empty())
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var store := Store.new()
	assert(store.place("basil", Vector2(4, 55), 0.0))
	var aged := store.data.duplicate(true)
	aged.placed[0].growth.started_at -= 15 * 86400
	assert(store._commit(aged))
	assert(store.water(0))
	assert(store.harvest(0))
	assert(store.retrieve(0), "History must survive picking a plant up")
	assert(world.local_vault.save())
	world.free()
	world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame

	var hud = world.get_node("GameHUD")
	var column = hud.get_child(0).get_child(0)
	var help: Button = column.get_node("Help")
	help.pressed.emit()
	var tabs: HBoxContainer = hud.content.get_child(0).get_child(0)
	assert(tabs.get_child(0).text == "Louise")
	var guide: Button = tabs.get_child(1)
	guide.pressed.emit()
	var pages = hud.content.get_child(0)
	assert(not pages.get_child(1).visible and pages.get_child(2).visible)
	var links = pages.get_child(2).find_children("*", "LinkButton", true, false)
	assert(links.size() == 2 and links[0].uri.begins_with("https://"))
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	assert(not hud.dialog.visible and help.has_focus())

	var journal: Button = column.get_node("Journal")
	journal.pressed.emit()
	assert(hud.title.text == "Garden Diary")
	var entries = hud.content.get_child(0).get_child(0)
	assert(entries.get_child_count() == 2)
	assert(entries.get_child(0).text.contains("Harvested Sweet basil"))
	assert(entries.get_child(1).text.contains("Watered Sweet basil"))
	root.push_input(escape)
	assert(not hud.dialog.visible and journal.has_focus())
	world.free()
	print("PASS: Louise and Growing Guide navigation, source links, Diary save/reopen and Escape")
	quit()
