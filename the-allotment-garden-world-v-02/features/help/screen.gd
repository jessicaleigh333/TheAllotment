extends VBoxContainer

func _ready() -> void:
	var tabs := HBoxContainer.new()
	add_child(tabs)
	var pages: Array[Control] = []
	for title in ["Louise", "Growing Guide"]:
		var tab := Button.new()
		tab.text = title
		tabs.add_child(tab)
		var page := VBoxContainer.new()
		add_child(page)
		pages.append(page)
		tab.pressed.connect(_show_page.bind(pages, page))

	_line(pages[0], "Welcome to the garden. Choose a seed in the Market and plant it in Garden 01. Plants grow in real time while you are away.")
	_line(pages[0], "Open Backpack → Plants and harvest to water a planting, check harvest readiness or sell what you picked. Your Garden Diary records watering and harvests.")
	_line(pages[0], "If leaves look damaged in a real garden, check both sides for insects, note the pattern of damage and check soil moisture before deciding what caused it.")

	_line(pages[1], "Sweet basil grows in full sun and moist soil that drains well. Pinching back growing tips encourages a bushier plant.")
	_source(pages[1], "University of Maryland Extension · Sweet basil", "https://extension.umd.edu/resource/growing-basil-home-garden")
	_line(pages[1], "Cosmos grows in full sun and well-drained soil. Aphids and slugs can be problems outdoors. Look for evidence before blaming either.")
	_source(pages[1], "Royal Horticultural Society · Cosmos", "https://www.rhs.org.uk/plants/30717/cosmos-bipinnatus/details")
	_line(pages[1], "In this garden, established basil and cosmos yield sprigs or stems. The game uses its own picking intervals and quantities. Watering records your care without changing those timings.")
	_show_page(pages, pages[0])

func _show_page(pages: Array[Control], selected: Control) -> void:
	for page in pages:
		page.visible = page == selected

func _line(page: Control, value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("334632"))
	page.add_child(label)

func _source(page: Control, title: String, url: String) -> void:
	var link := LinkButton.new()
	link.text = title
	link.uri = url
	link.add_theme_color_override("font_color", Color("285641"))
	page.add_child(link)
