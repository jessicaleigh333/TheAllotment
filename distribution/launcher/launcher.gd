extends Control
const Protocol := preload("res://protocol.gd")
var root_path := ""
var public_key := ""
var active := {}
var pending := {}
var pending_media := false
var pending_envelope := PackedByteArray()
var status_label: Label
var version_label: Label
var notes: Label
var play: Button
var check: Button
var update_button: Button
var rollback_button: Button
var automatic: CheckBox
var progress: ProgressBar
var request: HTTPRequest
var request_kind := ""
var busy := false
var game_pid := -1
var poll_time := 0.
var check_time := 0.
var suppress_build := 0
@export var auto_check := true
var can_launch := true
var channel: Dictionary
var owns_session := false
var cancel_button: Button

func _ready() -> void:
 root_path = ProjectSettings.globalize_path("user://")
 public_key = FileAccess.get_file_as_string("res://release-public.pem")
 channel = Protocol.read_json("res://channel.json")
 _build_ui()
 var session_path := root_path.path_join("launcher-session")
 DirAccess.make_dir_recursive_absolute(session_path)
 owns_session = Protocol.acquire_lock(session_path)
 if not owns_session:
  can_launch = false
  busy = true
  _status("The launcher is already open. Use its existing window.")
  _refresh()
  return
 var process_record := Protocol.read_json(root_path.path_join("game-process.json"))
 if Protocol.whole(process_record.get("pid"),1,2147483647) and Protocol.pid_alive(int(process_record.pid),"TheAllotment.exe"): game_pid = int(process_record.pid)
 request = HTTPRequest.new()
 request.use_threads = true
 request.timeout = 30
 request.max_redirects = 5
 request.request_completed.connect(_response)
 add_child(request)
 active = Protocol.current(root_path,public_key)
 await _install_media_if_newer()
 if not active.is_empty(): _status("Your garden is open. Updates will wait until it closes." if _game_running() else "Ready to play. Your garden saves stay separate from updates.")
 _refresh()
 if auto_check: call_deferred("check_updates")

func _install_media_if_newer(folder: String = "") -> void:
 if busy: return
 if folder.is_empty(): folder = _media_folder()
 var signed_path := folder.path_join("starter-update.json")
 var archive := folder.path_join("starter-game.zip")
 if not FileAccess.file_exists(signed_path) or not FileAccess.file_exists(archive):
  if active.is_empty(): _status("Keep starter-game.zip and starter-update.json beside this launcher for offline installation.")
  return
 var bytes := FileAccess.get_file_as_bytes(signed_path)
 var checked := Protocol.decode_release(bytes,public_key)
 if not checked.ok:
  if active.is_empty(): _status(checked.error)
  return
 if not active.is_empty() and int(checked.manifest.build) <= int(active.highest_build): return
 if _game_running():
  pending_media = true
  return
 busy = true
 request_kind = "media"
 _status("Preparing your garden from this USB/CD or downloaded copy…")
 _refresh()
 await get_tree().process_frame
 var result := Protocol.install(root_path,archive,bytes,public_key)
 busy = false
 pending_media = false
 _status("This copy is installed. Your saved garden is ready." if result.ok else result.error)
 active = Protocol.current(root_path,public_key)
 _refresh()

func _media_folder() -> String:
 return OS.get_executable_path().get_base_dir() if not OS.has_feature("editor") else ProjectSettings.globalize_path("res://../release-assets")

func _build_ui() -> void:
 var backdrop := ColorRect.new()
 backdrop.color = Color("182e25")
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(backdrop)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,56)
 for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,32)
 add_child(margin)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",14)
 margin.add_child(box)
 var eyebrow := Label.new()
 eyebrow.text = "GROW  ·  RESTORE  ·  EXPLORE  ·  BELONG"
 eyebrow.add_theme_font_size_override("font_size",13)
 eyebrow.add_theme_color_override("font_color",Color("c8b989"))
 box.add_child(eyebrow)
 var title := Label.new()
 title.text = "The Allotment"
 title.add_theme_font_size_override("font_size",48)
 title.add_theme_color_override("font_color",Color("f5e7c6"))
 box.add_child(title)
 version_label = Label.new()
 version_label.add_theme_color_override("font_color",Color("d4d9c1"))
 box.add_child(version_label)
 var panel := PanelContainer.new()
 var style := StyleBoxFlat.new()
 style.bg_color = Color("f1e5ca")
 style.border_color = Color("bfa66c")
 style.set_border_width_all(2)
 style.set_corner_radius_all(14)
 for side in ["left","right","top","bottom"]: style.set("content_margin_"+side,18)
 panel.add_theme_stylebox_override("panel",style)
 box.add_child(panel)
 var details := VBoxContainer.new()
 details.add_theme_constant_override("separation",10)
 panel.add_child(details)
 status_label = Label.new()
 status_label.text = "Opening your garden…"
 status_label.custom_minimum_size.y = 46
 status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 status_label.add_theme_color_override("font_color",Color("2b4433"))
 details.add_child(status_label)
 progress = ProgressBar.new()
 progress.custom_minimum_size.y = 12
 progress.show_percentage = false
 progress.visible = false
 details.add_child(progress)
 notes = Label.new()
 notes.custom_minimum_size.y = 44
 notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 notes.add_theme_color_override("font_color",Color("52604b"))
 notes.text = "Play offline whenever you like. Updates download only while the garden is closed."
 details.add_child(notes)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",12)
 box.add_child(row)
 play = _button("Play garden",row,_play)
 play.custom_minimum_size = Vector2(220,54)
 check = _button("Check for updates",row,check_updates)
 update_button = _button("Install update",row,_download)
 cancel_button = _button("Cancel download",row,_cancel_download)
 automatic = CheckBox.new()
 automatic.text = "Download and install new game versions automatically"
 var preferences := Protocol.read_json(root_path.path_join("preferences.json"))
 automatic.button_pressed = bool(preferences.get("automatic",true))
 automatic.toggled.connect(func(enabled: bool) -> void:
  Protocol.atomic_json(root_path.path_join("preferences.json"),{"automatic":enabled})
  if enabled and not pending.is_empty() and not busy and not _game_running(): _download())
 box.add_child(automatic)
 var tools := HBoxContainer.new()
 tools.add_theme_constant_override("separation",12)
 box.add_child(tools)
 rollback_button = _button("Use previous version",tools,_rollback)
 _button("Open game saves",tools,func() -> void:
  var path := OS.get_user_data_dir().get_base_dir().path_join("Godot/app_userdata/The Allotment - Garden World v0.2")
  if OS.get_name() != "Windows": path = OS.get_data_dir().path_join("godot/app_userdata/The Allotment - Garden World v0.2")
  if DirAccess.dir_exists_absolute(path): OS.shell_open(path)
  else: _status("Your save folder is created when you first play the garden."))
 var footer := Label.new()
 footer.text = "WINDOWS BETA  ·  LOCAL GARDEN VAULT  ·  NO ACCOUNT REQUIRED"
 footer.add_theme_font_size_override("font_size",12)
 footer.add_theme_color_override("font_color",Color("c8b989"))
 box.add_child(footer)

func _button(text: String, parent: Control, callback: Callable) -> Button:
 var button := Button.new()
 button.text = text
 button.custom_minimum_size.y = 36
 button.pressed.connect(callback)
 parent.add_child(button)
 return button
func _status(message: String) -> void: status_label.text = message
func _game_running() -> bool: return game_pid > 0 and Protocol.pid_alive(game_pid)
func _refresh() -> void:
 var running := _game_running()
 version_label.text = "Garden beta · No game installed yet" if active.is_empty() else "Garden beta · Version "+str(active.manifest.version)
 play.disabled = active.is_empty() or running or (busy and request_kind != "feed") or not can_launch
 check.disabled = busy or running
 update_button.visible = not pending.is_empty()
 update_button.disabled = busy or running
 cancel_button.visible = busy and request_kind == "archive"
 rollback_button.disabled = busy or running or active.is_empty() or not Protocol.safe_slot(active.get("previous"))

func check_updates() -> void:
 if busy or _game_running(): return
 if not str(channel.get("feed","")).begins_with("https://github.com/jessicaleigh333/TheAllotment/releases/"):
  _status("The update channel is not configured. Your installed game can still be played offline.")
  return
 busy = true
 request_kind = "feed"
 request.download_file = ""
 request.body_size_limit = 262144
 request.timeout = 20
 _status("Checking for new garden updates…")
 _refresh()
 if request.request(channel.feed,["User-Agent: TheAllotmentLauncher/1.0"]) != OK:
  busy = false
  _offline()
func _offline() -> void:
 _status("The update channel is unavailable or has no published release yet. You can play your installed version offline." if not active.is_empty() else "No published update is available. Keep the starter files with this launcher for offline installation.")
 _refresh()
func _response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
 var kind := request_kind
 busy = false
 progress.visible = false
 if result != HTTPRequest.RESULT_SUCCESS or code != 200:
  if kind == "archive":
   DirAccess.remove_absolute(root_path.path_join("download.partial"))
   _status("The download was interrupted. Your installed game is unchanged; try again when connected.")
   _refresh()
  else: _offline()
  return
 if kind == "feed":
  var decoded := Protocol.decode_release(body,public_key)
  if not decoded.ok:
   _status(decoded.error+" Your installed game is unchanged.")
   _refresh()
   return
  var build: int = decoded.manifest.build
  if (not active.is_empty() and build <= int(active.highest_build)) or build == suppress_build:
   _status("Your garden is ready. No newer update is available.")
   _refresh()
   return
  pending = decoded.manifest
  pending_envelope = body
  notes.text = "Version "+str(pending.version)+" · "+str(pending.get("notes","Garden update"))
  _status("A new garden version is available.")
  _refresh()
  if automatic.button_pressed and not _game_running(): call_deferred("_download")
 else:
  if _game_running():
   _status("The garden is open. Close it before installing this update.")
   _refresh()
   return
  busy = true
  request_kind = "install"
  _status("Verifying and installing the update…")
  _refresh()
  await get_tree().process_frame
  var installed := Protocol.install(root_path,root_path.path_join("download.partial"),pending_envelope,public_key)
  DirAccess.remove_absolute(root_path.path_join("download.partial"))
  busy = false
  if installed.ok:
   active = Protocol.current(root_path,public_key)
   pending.clear()
   _status("Update installed. Your saved garden is ready.")
  else: _status(installed.error)
  _refresh()

func _download() -> void:
 if busy or pending.is_empty() or _game_running(): return
 busy = true
 request_kind = "archive"
 request.download_file = root_path.path_join("download.partial")
 request.body_size_limit = int(pending.size)
 request.timeout = 300
 progress.visible = true
 progress.value = 0
 _status("Downloading version "+str(pending.version)+"… Your current game stays available.")
 _refresh()
 if request.request(pending.url,["User-Agent: TheAllotmentLauncher/1.0"]) != OK:
  busy = false
  progress.visible = false
  _offline()
func _cancel_download() -> void:
 if not busy or request_kind != "archive": return
 request.cancel_request()
 DirAccess.remove_absolute(root_path.path_join("download.partial"))
 busy = false
 progress.visible = false
 _status("Download cancelled. Your current garden version is ready to play.")
 _refresh()

func _play() -> void:
 if active.is_empty() or _game_running() or (busy and request_kind != "feed") or not can_launch: return
 var verified := Protocol.installed(root_path,active.slot,public_key)
 if verified.is_empty():
  _status("The installed game failed verification. Use the previous version or install a new update.")
  play.disabled = true
  return
 if OS.get_name() != "Windows":
  _status("This package is for Windows. The launcher can be previewed here, but the game needs a Windows computer.")
  return
 game_pid = OS.create_process(verified.executable,[])
 if game_pid <= 0: _status("Windows could not start this version. You can use the previous version below.")
 else:
  Protocol.atomic_json(root_path.path_join("game-process.json"),{"pid":game_pid})
  _status("Enjoy your garden. Updates will wait until you close the game.")
 _refresh()
func _rollback() -> void:
 if busy or _game_running(): return
 if Protocol.rollback(root_path,public_key):
  active = Protocol.current(root_path,public_key)
  pending.clear()
  _status("Previous game version selected. Garden saves were not changed.")
 else: _status("A verified previous version is not available.")
 _refresh()
func _process(delta: float) -> void:
 poll_time += delta
 check_time += delta
 if request != null and busy and request_kind == "archive":
  var total := request.get_body_size()
  if total > 0: progress.value = request.get_downloaded_bytes()*100./total
 if poll_time < 1: return
 poll_time = 0
 if game_pid > 0 and not _game_running():
  game_pid = -1
  DirAccess.remove_absolute(root_path.path_join("game-process.json"))
  _status("Garden closed. Your local vault remains on this computer.")
  _refresh()
  if pending_media: call_deferred("_install_media_if_newer")
  elif automatic.button_pressed and not pending.is_empty(): _download()
 if check_time >= 1800 and not busy and not _game_running():
  check_time = 0
  check_updates()
func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST and request != null: request.cancel_request()

func _exit_tree() -> void:
 if owns_session: Protocol.release_lock(root_path.path_join("launcher-session"))
