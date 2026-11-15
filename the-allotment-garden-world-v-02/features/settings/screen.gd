extends VBoxContainer
var world
var status: Label
func _ready() -> void:
 var description := Label.new()
 description.text = "Local save vault\nYour garden stays on this computer.\nNo account or internet connection needed."
 description.add_theme_color_override("font_color",Color("334632"))
 add_child(description)
 status = Label.new()
 status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 status.add_theme_color_override("font_color",Color("334632"))
 add_child(status)
 var save_button := Button.new()
 save_button.text = "Save garden now"
 save_button.pressed.connect(func() -> void:
  world.local_vault.save()
  status.text = world.local_vault.status)
 add_child(save_button)
 var folder := Button.new()
 folder.text = "Open my save folder"
 folder.pressed.connect(func() -> void: OS.shell_open(ProjectSettings.globalize_path(world.local_vault.save_root)))
 add_child(folder)
 status.text = world.local_vault.status if world != null else "Open this panel from your garden."
 save_button.disabled = world == null
 folder.disabled = world == null
