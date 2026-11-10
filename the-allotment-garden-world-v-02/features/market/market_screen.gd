extends Control
signal close_requested
signal placement_requested(id: String, area: String)
const Growth := preload("res://features/market/plant_growth.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Store := preload("res://features/market/market_store.gd")
const Model := preload("res://features/market/item_model.tscn")
@export var initial_mode := "market"
var mode := "market"
var category := "All"
var query := ""
var owned_only := false
var selected := "rose"
var store
var world: Node3D
var grid: GridContainer
var details: VBoxContainer
var balance: Label
var status: Label
var heading: Label
var quickbar: HBoxContainer
var owned_toggle: CheckBox
var viewport: SubViewport
var preview_model: Node3D
var preview_camera: Camera3D
var card_buttons: Dictionary = {}
var shop_stage := 4
var stage_choice: OptionButton

func _ready() -> void:
	store = Store.new()
	mode = initial_mode
	_build()
	refresh()

func _style(color: Color, border: Color = Color("a8894e")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _text(value: String, font_size: int = 16, color: Color = Color("f1e2bd")) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	return label

func _button(value: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 40
	button.add_theme_font_size_override("font_size",15)
	button.add_theme_color_override("font_color",Color("f6e8bf"))
	button.add_theme_color_override("font_hover_color",Color("fff5d8"))
	button.add_theme_stylebox_override("normal",_style(Color("354c38") if primary else Color("44352a")))
	button.add_theme_stylebox_override("hover",_style(Color("586247"),Color("e2c47a")))
	button.add_theme_stylebox_override("focus",_style(Color("586247"),Color("fff1ab")))
	button.add_theme_stylebox_override("pressed",_style(Color("70533b")))
	button.pressed.connect(action)
	return button

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := TextureRect.new()
	background.texture = preload("res://features/market/market_background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.06,.05,.025,.23)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",10)
	margin.add_child(layout)
	var top := HBoxContainer.new()
	var top_panel := PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel",_style(Color(.13,.10,.075,.91)))
	layout.add_child(top_panel)
	top_panel.add_child(top)
	heading = _text("The Allotment · MARKET",29)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia","DejaVu Serif"])
	heading.add_theme_font_override("font",serif)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	balance = _text("",21)
	top.add_child(balance)
	top.add_child(_button("Back to garden",func() -> void: close_requested.emit()))
	var tabs := HBoxContainer.new()
	layout.add_child(tabs)
	for entry in [["market","Market"],["backpack","Backpack"],["catalog","Botanical catalog"]]:
		tabs.add_child(_button(entry[1],_set_mode.bind(entry[0])))
	var toolbar := HBoxContainer.new()
	layout.add_child(toolbar)
	var search := LineEdit.new()
	search.name = "Search"
	search.placeholder_text = "Search plants, decor and garden treasures…"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.custom_minimum_size.y = 40
	search.add_theme_stylebox_override("normal",_style(Color("f2e4c5")))
	search.add_theme_color_override("font_color",Color("354532"))
	search.add_theme_color_override("font_placeholder_color",Color("68735b"))
	search.text_changed.connect(func(value: String) -> void: query = value; _refresh_grid())
	toolbar.add_child(search)
	stage_choice = OptionButton.new()
	stage_choice.name = "PlantStage"
	for title in ["Seeds","Seedlings","Young plants","Mature plants"]: stage_choice.add_item(title)
	stage_choice.select(3)
	stage_choice.item_selected.connect(func(index: int) -> void:
		stage_choice.select(index)
		shop_stage = [0,2,3,4][index]
		selected = Catalog.stage_id(selected,shop_stage)
		refresh()
	)
	toolbar.add_child(stage_choice)
	owned_toggle = CheckBox.new()
	owned_toggle.text = "Owned only"
	owned_toggle.add_theme_color_override("font_color",Color("fff2d5"))
	owned_toggle.toggled.connect(func(value: bool) -> void: owned_only = value; _refresh_grid())
	toolbar.add_child(owned_toggle)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	var navigation := PanelContainer.new()
	navigation.add_theme_stylebox_override("panel",_style(Color(.13,.10,.075,.95)))
	navigation.custom_minimum_size.x = 155
	body.add_child(navigation)
	var categories := VBoxContainer.new()
	categories.add_theme_constant_override("separation",4)
	navigation.add_child(categories)
	categories.add_child(_text("Browse the stalls",16))
	for name in ["All","Featured","Plants","Decor","Avatar","Tools","Seeds","Pinned"]:
		var category_button := _button(name,func() -> void: category = name; _refresh_grid())
		category_button.custom_minimum_size.y = 34
		for state in ["normal","hover","focus","pressed"]:
			var box := category_button.get_theme_stylebox(state) as StyleBoxFlat
			box.content_margin_top = 5
			box.content_margin_bottom = 5
		categories.add_child(category_button)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	categories.add_child(spacer)
	var center := PanelContainer.new()
	center.add_theme_stylebox_override("panel",_style(Color(.12,.09,.06,.92)))
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(center)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	center.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",10)
	scroll.add_child(grid)
	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size.x = 300
	detail_panel.add_theme_stylebox_override("panel",_style(Color("eee0bd"),Color("b99152")))
	body.add_child(detail_panel)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_panel.add_child(detail_scroll)
	details = VBoxContainer.new()
	details.custom_minimum_size.x = 274
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation",9)
	detail_scroll.add_child(details)
	quickbar = HBoxContainer.new()
	quickbar.add_theme_constant_override("separation",8)
	layout.add_child(quickbar)
	status = _text("",14)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status)
	resized.connect(_resize_cards)

func _resize_cards() -> void:
	if grid == null: return
	grid.columns = 3 if size.x >= 1150 else 2

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _set_mode(value: String) -> void:
	mode = value
	category = "All"
	refresh()

func refresh() -> void:
	balance.text = "Free decorating"
	stage_choice.disabled = mode == "backpack"
	heading.text = "The Allotment · "+{"market":"MARKET","backpack":"BACKPACK","catalog":"BOTANICAL CATALOG"}[mode]
	status.text = store.last_error if not store.readable else ("Everything is free to use. Choose an item and Decorate inner circle." if mode == "market" else "Choose an owned item to place, equip or pin." if mode == "backpack" else "Discover · Grow · Learn — browse the starter plant collection.")
	_refresh_grid()
	_refresh_details()
	_clear(quickbar)
	quickbar.add_child(_text("Common items",16))
	for id in store.data.favorites:
		var item := Catalog.by_id(id)
		var button := _button("×%d" % store.count(id),_select.bind(id))
		button.icon = Catalog.icon(item)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",32)
		button.custom_minimum_size.x = 90
		button.tooltip_text = item.name
		quickbar.add_child(button)
	if store.data.favorites.is_empty(): quickbar.add_child(_text("Pin up to six favorites here.",14))
	_resize_cards()

func _refresh_grid() -> void:
	_clear(grid)
	card_buttons.clear()
	var matches := 0
	var entries: Array = []
	if mode == "backpack":
		for id in store.data.owned:
			if store.count(id) > 0: entries.append(Catalog.by_id(id))
	elif category == "Pinned":
		for id in store.data.favorites: entries.append(Catalog.by_id(id))
	else:
		for source in Catalog.ITEMS:
			if str(source.id).ends_with("_seeds"): continue
			var id: String = source.id
			if source.category == "Plants": id = Catalog.stage_id(id,0 if category == "Seeds" else shop_stage)
			entries.append(Catalog.by_id(id))
	for item in entries:
		if mode == "catalog" and item.category not in ["Plants","Seeds"]: continue
		if mode == "backpack" and store.count(item.id) <= 0: continue
		if owned_only and store.total_owned(item.id) <= 0: continue
		if category == "Featured" and not item.get("featured",false): continue
		if category == "Pinned" and not store.data.favorites.has(item.id): continue
		if category == "Seeds" and (not item.has("plant") or int(item.growth_stage) != 0): continue
		if category == "Plants" and not item.has("plant"): continue
		if category not in ["All","Featured","Pinned","Seeds","Plants"] and item.category != category: continue
		if not query.is_empty() and (str(item.name)+" "+str(item.get("latin",""))).to_lower().find(query.to_lower()) < 0: continue
		matches += 1
		var card := _button("",_select.bind(item.id))
		card.custom_minimum_size = Vector2(160,191)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = item.name
		card.accessibility_name = item.name
		grid.add_child(card)
		card_buttons[item.id] = card
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(margin)
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,8)
		var contents := VBoxContainer.new()
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(contents)
		var image := TextureRect.new()
		image.texture = Catalog.icon(item)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(140,125)
		image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(image)
		if item.has("plant") and int(item.growth_stage) < 4:
			image.hide()
			contents.add_child(_stage_thumbnail(item.id))
		var name := _text(item.name,14)
		name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(name)
		var tag_text: String = "Free · "+Growth.STAGES[int(item.growth_stage)] if item.has("plant") else "Free · ×%d in bag" % store.count(item.id)
		var tag := _text(tag_text,12)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(tag)
	if matches == 0:
		var empty := _text("No items here yet.\nTry another category or visit the Market.",16)
		empty.custom_minimum_size.x = 280
		grid.add_child(empty)

func _select(id: String) -> void:
	selected = id
	_refresh_details()

func _refresh_details() -> void:
	_clear(details)
	preview_model = null
	var item := Catalog.by_id(selected)
	if item.is_empty(): return
	var name := _text(item.name,23,Color("334632"))
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(name)
	if item.has("latin"): details.add_child(_text(item.latin,14,Color("657058")))
	var image := TextureRect.new()
	image.texture = Catalog.icon(item)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(250,170)
	image.visible = not item.has("plant")
	details.add_child(image)
	if item.has("plant"):
		var info: Dictionary = Growth.PLANTS[item.plant]
		var state := Growth.state(item.plant,_display_age(item.id))
		var measurements := _text("%s · %.2f m tall now\nFull size: %.2f m tall × %.2f m across\nGrowth uses real days, including offline time." % [state.name,state.height,info.height,info.width],14,Color("425b3c"))
		measurements.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(measurements)
		if int(state.stage) < 4:
			var remaining: float = float(info.days[4])-_display_age(item.id)
			details.add_child(_text("About %d days to full size.\nSpace is reserved for the grown plant." % int(remaining),13,Color("657058")))
	var description := _text(item.description,15,Color("3c4935"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 260
	details.add_child(description)
	if item.has("season"):
		details.add_child(_text("%s · %s\nWater: %s" % [item.season,item.sun,item.water],14,Color("5a664a")))
	details.add_child(_text("In backpack: %d" % store.count(item.id),16,Color("334632")))
	if mode != "backpack":
		var buy := _button("Add to backpack · Free",_buy.bind(item.id),true)
		buy.name = "Buy"
		buy.disabled = not store.readable or not item.get("available",true)
		details.add_child(buy)
	if Catalog.placeable(item):
		for scope in ["courtyard","garden"]:
			var place := _button("Decorate inner circle" if scope == "courtyard" else "Place in Garden 01",func() -> void: placement_requested.emit(item.id,scope),true)
			place.name = "Place" if scope == "courtyard" else "PlaceGarden"
			place.disabled = not store.readable or world == null
			details.add_child(place)
			if scope == "courtyard": details.move_child(place,2 if item.has("latin") else 1)
	elif item.id == "straw_hat":
		var equip := _button("Equip hat",_equip_hat,true)
		equip.disabled = not store.readable or store.count(item.id) <= 0
		details.add_child(equip)
	var pin := _button("Unpin common item" if store.data.favorites.has(item.id) else "Pin to common items",_pin.bind(item.id))
	pin.disabled = not store.readable
	details.add_child(pin)
	if item.get("available",true):
		details.add_child(_button("Inspect 3D model",_preview.bind(item.id)))
		details.add_child(_text("Illustration above · View the garden model in 3D",11,Color("68735d")))
	if mode == "backpack":
		for index in range(store.data.placed.size()):
			if store.data.placed[index].id == item.id:
				details.add_child(_button("Return one placed item to bag",_retrieve.bind(index)))
				break
		# A placed stack may have no remaining bag items; access it below the grid.
		var placed_count: int = store.data.placed.size()
		if placed_count > 0:
			details.add_child(_text("Placed in garden: %d" % placed_count,13,Color("5a664a")))
			details.add_child(_button("Browse placed items",_show_placed))
	if item.has("plant"): _preview(item.id)

func _buy(id: String) -> void:
	var success: bool = store.buy(id)
	refresh()
	status.text = "%s added to your backpack." % Catalog.by_id(id).name if success else store.last_error

func _pin(id: String) -> void:
	var success: bool = store.favorite(id)
	refresh()
	if not success: status.text = store.last_error

func _retrieve(index: int) -> void:
	if store.retrieve(index):
		if world != null: world.market_garden.reload_items()
		refresh()
	else: status.text = store.last_error

func _show_placed() -> void:
	_clear(details)
	details.add_child(_text("In your garden",23,Color("334632")))
	for index in range(store.data.placed.size()):
		var placement: Dictionary = store.data.placed[index]
		var item := Catalog.by_id(placement.id)
		var plant := Growth.species(item.id)
		if not plant.is_empty():
			var state := Growth.state(plant,Growth.age_days(placement,Time.get_unix_time_from_system()))
			details.add_child(_text("%s · %s · %.2f m" % [plant.capitalize(),state.name,state.height],14,Color("425b3c")))
		details.add_child(_button("Return "+item.name,_retrieve.bind(index)))

func _equip_hat() -> void:
	var appearance := preload("res://features/avatar/appearance.gd")
	var look: Dictionary = appearance.load_saved()
	look.hat_enabled = true
	look.flowers_enabled = true
	if appearance.save(look):
		if world != null: world.player.get_node("Visual").apply_appearance(look)
		status.text = "Your flower-trimmed hat is equipped."
	else: status.text = "The outfit could not be saved."

func _preview(id: String) -> void:
	if is_instance_valid(viewport):
		viewport.get_parent().queue_free()
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(250,200)
	container.stretch = true
	details.add_child(container)
	details.move_child(container,2)
	viewport = SubViewport.new()
	viewport.size = Vector2i(250,200)
	viewport.own_world_3d = true
	container.add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("d8d8bd")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff0cf")
	environment.environment.ambient_light_energy = .7
	viewport.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50,-35,0)
	viewport.add_child(sun)
	preview_model = Model.instantiate()
	preview_model.item_id = id
	if not Growth.species(id).is_empty(): preview_model.growth_age_days = _display_age(id)
	viewport.add_child(preview_model)
	preview_camera = Camera3D.new()
	viewport.add_child(preview_camera)
	var bounds: AABB = preview_model.mesh_bounds()
	var span := maxf(.04,maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z)))
	var center := bounds.get_center()
	preview_camera.near = .001
	preview_camera.fov = 40
	preview_camera.position = center+Vector3(span*1.2,span*.7,span*1.2)
	preview_camera.look_at(center)

func _display_age(id: String) -> float:
	var bag: Dictionary = store.data.get("bag_growth",{})
	if mode == "backpack" and bag.has(id) and not bag[id].is_empty(): return float(bag[id][0])
	return Growth.starting_age(id)

func _stage_thumbnail(id: String) -> SubViewportContainer:
	var container := SubViewportContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.custom_minimum_size = Vector2(140,125)
	container.stretch = true
	var view := SubViewport.new()
	view.size = Vector2i(160,140)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	container.add_child(view)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("c8c7a9")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff1d0")
	environment.environment.ambient_light_energy = .85
	view.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50,-30,0)
	view.add_child(sun)
	var model := Model.instantiate()
	model.item_id = id
	view.add_child(model)
	# Nodes are not in the tree yet, so build on the next ready notification.
	view.ready.connect(func() -> void:
		var bounds: AABB = model.mesh_bounds()
		var span := maxf(.04,maxf(bounds.size.x,bounds.size.y))
		var camera := Camera3D.new()
		camera.near = .001
		camera.fov = 40
		view.add_child(camera)
		camera.position = bounds.get_center()+Vector3(span*1.2,span*.7,span*1.2)
		camera.look_at(bounds.get_center())
	)
	return container

func _process(delta: float) -> void:
	if is_instance_valid(preview_model): preview_model.rotation.y += delta*.35
