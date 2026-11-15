extends VBoxContainer
## Forecast module; can also run independently with its own simulated provider.
var provider
var fahrenheit := true
var current_title: Label
var current_details: Label
var forecast_rows: VBoxContainer
var unit_button: Button

func _ready() -> void:
	if provider == null:
		provider = preload("res://features/weather/weather_system.gd").new()
		add_child(provider)
	_build()
	provider.weather_changed.connect(refresh)
	refresh()

func configure(weather_provider) -> void:
	provider = weather_provider

func _label(text: String, size: int = 16, color: Color = Color("334632")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label

func _icon() -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://ui/icons/storybook_icons.png")
	var cell := Vector2(atlas.atlas.get_width()/4.0,atlas.atlas.get_height()/3.0)
	atlas.region = Rect2(Vector2(2,1)*cell,cell)
	atlas.filter_clip = true
	return atlas

func _build() -> void:
	add_theme_constant_override("separation",12)
	var heading := HBoxContainer.new()
	add_child(heading)
	var place := _label(provider.neighborhood_name,16)
	place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(place)
	unit_button = Button.new()
	unit_button.text = "Show °C"
	unit_button.pressed.connect(func() -> void:
		fahrenheit = not fahrenheit
		unit_button.text = "Show °C" if fahrenheit else "Show °F"
		refresh()
	)
	heading.add_child(unit_button)
	var today := HBoxContainer.new()
	today.add_theme_constant_override("separation",14)
	add_child(today)
	var icon := TextureRect.new()
	icon.texture = _icon()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(84,84)
	today.add_child(icon)
	var details := VBoxContainer.new()
	today.add_child(details)
	current_title = _label("",25)
	details.add_child(current_title)
	current_details = _label("",15)
	details.add_child(current_details)
	add_child(HSeparator.new())
	add_child(_label("THE NEXT FIVE DAYS",14,Color("7b613a")))
	forecast_rows = VBoxContainer.new()
	forecast_rows.add_theme_constant_override("separation",6)
	add_child(forecast_rows)
	var note := _label("Garden weather • simulated for this neighborhood",13,Color("6e775e"))
	add_child(note)

func refresh() -> void:
	if current_title == null: return
	var today: Dictionary = provider.current_weather()
	current_title.text = "Today  %s  ·  %s" % [provider.temperature(today.temperature_c,fahrenheit),today.condition]
	current_details.text = "High %s  /  Low %s\nRain %d%%  ·  Wind %d km/h\n%s" % [provider.temperature(today.high_c,fahrenheit),provider.temperature(today.low_c,fahrenheit),today.rain_chance,today.wind_kmh,today.date]
	for child in forecast_rows.get_children():
		forecast_rows.remove_child(child)
		child.queue_free()
	for day in provider.forecast(5):
		var row := PanelContainer.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color("e8ddc2")
		box.set_corner_radius_all(8)
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		row.add_theme_stylebox_override("panel",box)
		forecast_rows.add_child(row)
		var items := HBoxContainer.new()
		items.add_theme_constant_override("separation",12)
		row.add_child(items)
		var date_label := _label(day.weekday+"  "+str(day.date).substr(5),15)
		date_label.custom_minimum_size.x = 105
		items.add_child(date_label)
		var condition := _label(day.condition,15)
		condition.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		items.add_child(condition)
		var temperatures := _label("%s / %s" % [provider.temperature(day.high_c,fahrenheit),provider.temperature(day.low_c,fahrenheit)],15)
		temperatures.custom_minimum_size.x = 120
		items.add_child(temperatures)
		var rain := _label("Rain %d%%" % day.rain_chance,14,Color("476a7a"))
		rain.custom_minimum_size.x = 80
		items.add_child(rain)
