extends Control
## UI prototype only: no credentials, consent or garden ownership are stored.
signal neighborhood_requested(code: String)
@export var open_garden_on_request := true
const DEMO_CODE := "BLOOM-0001"
var pages: Array[VBoxContainer] = []
var step_label: Label
var code_input: LineEdit
var feedback: Label
var terms_check: CheckBox
var terms_next: Button
var stage := 0

func _ready() -> void:
	_build_interface()
	show_step(0)

func _build_interface() -> void:
	var background := TextureRect.new()
	background.texture = preload("res://ui/backgrounds/storybook_countryside.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 0)
	var parchment := StyleBoxFlat.new()
	parchment.bg_color = Color(0.98, 0.95, 0.86, 0.97)
	parchment.border_color = Color("c6a56b")
	parchment.set_border_width_all(2)
	parchment.set_corner_radius_all(24)
	parchment.shadow_color = Color(0.16, 0.24, 0.15, 0.2)
	parchment.shadow_size = 16
	parchment.content_margin_left = 36
	parchment.content_margin_right = 36
	parchment.content_margin_top = 28
	parchment.content_margin_bottom = 28
	card.add_theme_stylebox_override("panel", parchment)
	center.add_child(card)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	card.add_child(layout)
	var brand := _label("THE ALLOTMENT", 16)
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(brand)
	step_label = _label("", 14)
	step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(step_label)
	for i in range(3):
		var page := VBoxContainer.new()
		page.name = ["Account", "Terms", "Neighborhood"][i]
		page.add_theme_constant_override("separation", 16)
		layout.add_child(page)
		pages.append(page)
	_build_account(pages[0])
	_build_terms(pages[1])
	_build_neighborhood(pages[2])
	var note := _label("Welcome-flow preview • no account or garden is created", 13)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(note)

func _label(value: String, font_size: int = 17) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 468
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("334632"))
	return label

func _button(page: VBoxContainer, title: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 17)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("526c43") if primary else Color("eee4cc")
		if state == "hover" or state == "focus": style.bg_color = Color("6b8759") if primary else Color("e2d3ad")
		if state == "disabled": style.bg_color = Color("c8cbbd")
		style.set_corner_radius_all(10)
		style.content_margin_left = 16
		style.content_margin_right = 16
		button.add_theme_stylebox_override(state, style)
		button.add_theme_color_override("font_%s_color" % state if state != "normal" else "font_color", Color("fff7e4") if primary else Color("334632"))
	button.pressed.connect(action)
	page.add_child(button)
	return button

func _build_account(page: VBoxContainer) -> void:
	page.add_child(_label("Your garden story begins here", 28))
	page.add_child(_label("Create an account or log in to begin. For now, these buttons let you preview the welcome screens."))
	_button(page, "Create account (preview)", show_step.bind(1), true)
	_button(page, "Log in (preview)", show_step.bind(1))

func _build_terms(page: VBoxContainer) -> void:
	page.add_child(_label("Terms & privacy", 28))
	page.add_child(_label("The terms and privacy documents will appear here before account registration opens. This preview does not record legal consent."))
	terms_check = CheckBox.new()
	terms_check.text = "I understand this is a preview"
	terms_check.add_theme_color_override("font_color", Color("334632"))
	terms_check.custom_minimum_size.y = 44
	page.add_child(terms_check)
	terms_next = _button(page, "Continue", show_step.bind(2), true)
	terms_next.disabled = true
	terms_check.toggled.connect(func(checked: bool) -> void: terms_next.disabled = not checked)
	_button(page, "Back", show_step.bind(0))

func _build_neighborhood(page: VBoxContainer) -> void:
	page.add_child(_label("Find your neighborhood", 28))
	page.add_child(_label("Have a friend in The Allotment? Enter their neighborhood code to join them."))
	page.add_child(_label("Neighborhood code", 15))
	code_input = LineEdit.new()
	code_input.name = "NeighborhoodCode"
	code_input.placeholder_text = "Enter a neighborhood code"
	code_input.custom_minimum_size.y = 48
	code_input.max_length = 64
	code_input.add_theme_color_override("font_color", Color("334632"))
	code_input.add_theme_color_override("font_placeholder_color", Color("697360"))
	var field := StyleBoxFlat.new()
	field.bg_color = Color("fffaf0")
	field.border_color = Color("b7bda4")
	field.set_border_width_all(1)
	field.set_corner_radius_all(8)
	field.content_margin_left = 14
	code_input.add_theme_stylebox_override("normal", field)
	page.add_child(code_input)
	code_input.text_submitted.connect(func(_value: String) -> void: join_neighborhood())
	page.add_child(_label("Try the demo code: " + DEMO_CODE, 14))
	feedback = _label("", 14)
	feedback.add_theme_color_override("font_color", Color("9a493d"))
	page.add_child(feedback)
	_button(page, "Join neighborhood", join_neighborhood, true)
	page.add_child(_label("No code? Find a place to start your garden.", 15))
	_button(page, "Find a neighborhood", find_neighborhood)
	page.add_child(_label("Joining lets you explore. Choosing a garden will be a separate step.", 14))
	_button(page, "Back", show_step.bind(1))

func show_step(index: int) -> void:
	if index == 2 and not terms_check.button_pressed: return
	stage = clampi(index, 0, 2)
	for i in range(pages.size()): pages[i].visible = i == stage
	step_label.text = "STEP %d OF 3  •  %s" % [stage + 1, ["ACCOUNT", "TERMS & PRIVACY", "NEIGHBORHOOD"][stage]]
	if stage == 2:
		code_input.grab_focus()
	else:
		for child in pages[stage].get_children():
			if child is Button:
				child.grab_focus()
				break

func join_neighborhood() -> void:
	if stage != 2: return
	var code := code_input.text.strip_edges().to_upper()
	if code.is_empty():
		feedback.text = "Enter a code, or choose Find a neighborhood."
		code_input.grab_focus()
		return
	if code != DEMO_CODE:
		feedback.text = "This preview recognizes only %s. Check the code and try again." % DEMO_CODE
		code_input.grab_focus()
		return
	_enter_preview(code)

func find_neighborhood() -> void:
	if stage == 2: _enter_preview(DEMO_CODE)

func _enter_preview(code: String) -> void:
	feedback.text = ""
	neighborhood_requested.emit(code)
	if open_garden_on_request:
		var error := get_tree().change_scene_to_file("res://main.tscn")
		if error != OK: feedback.text = "The garden preview could not open. Please try again."
