extends Node
## Device-local progress checkpoint plus rotating ZIP backups. No account service.
signal status_changed(message: String)
const Profiles := preload("res://features/profiles/local_profiles.gd")
const Market := preload("res://features/market/market_store.gd")
var world: Node3D
var save_root := ""
var last_error := ""
var status := "Local vault · autosave every minute"
var timer := 0.0
var busy := false

func configure(target: Node3D) -> void:
 world = target
 save_root = Profiles.save_root()
 # Restore landscaping before play, even if the editor is never opened.
 if DirAccess.dir_exists_absolute(save_root+"ground_cover"):
  world.ensure_ground_editor()
 var session := read_session()
 if not session.is_empty():
  world.player.position = Vector3(session.position[0],session.position[1]+.06,session.position[2])
  world.player.rotation.y = float(session.facing)
  world.orbit = float(session.orbit)
  world.pitch = float(session.pitch)
  world.distance = float(session.distance)
  world.focus = world.player.position+Vector3(0,1,0)
  status = "Local vault · restored your garden"
 elif not last_error.is_empty(): status = last_error
 if world.ground_editor_session != null and not world.ground_editor_session.save_loaded_ok:
  status = "Saved landscaping could not be restored. Its file was kept unchanged."
 world.get_tree().auto_accept_quit = false

func read_session() -> Dictionary:
 var path := save_root+"session.json"
 if not FileAccess.file_exists(path): return {}
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null or file.get_length() > 16384:
  last_error = "Vault session could not be read. Existing saves were kept."
  return {}
 var parser := JSON.new()
 if parser.parse(file.get_as_text()) != OK or not valid_session(parser.data):
  last_error = "Vault session could not be read. Existing saves were kept."
  return {}
 return parser.data

static func valid_session(value: Variant) -> bool:
 if not value is Dictionary or value.get("version") != 1: return false
 var position = value.get("position")
 if not position is Array or position.size() != 3: return false
 for number in position:
  if not (number is int or number is float) or not is_finite(float(number)) or absf(float(number)) > 400: return false
 if float(position[1]) < -2 or float(position[1]) > 30: return false
 for key in ["facing","orbit","pitch","distance","saved_at"]:
  var number = value.get(key)
  if not (number is int or number is float) or not is_finite(float(number)): return false
 return value.pitch >= .05 and value.pitch <= 1.5 and value.distance >= 2 and value.distance <= 500 and value.saved_at >= 0

func save() -> bool:
 if busy or not is_instance_valid(world): return false
 busy = true
 var ok := _save()
 busy = false
 status = "Saved to your local vault · "+Time.get_time_string_from_system() if ok else last_error
 status_changed.emit(status)
 return ok

func _save() -> bool:
 last_error = ""
 if Profiles.new().read().is_empty() or Profiles.save_root() != save_root: return fail("The active profile changed. Your files were kept.")
 # Never replace a damaged save with an empty/default garden.
 if FileAccess.file_exists(save_root+"session.json"):
  read_session()
  if not last_error.is_empty(): return false
 var market := Market.new()
 if not market.readable: return fail(market.last_error)
 if not world.market_garden.save_growth_progress(): return fail("Plant progress could not be saved. Try again.")
 if not FileAccess.file_exists(market.path) and not market._commit(market.data): return fail(market.last_error)
 if world.ground_editor_session != null:
  if not world.ground_editor_session.save_loaded_ok: return fail("Saved landscaping could not be read. Its file was kept unchanged.")
  var ground = world.ground_editor_session.store
  if ground.transaction: ground.commit_stroke()
  if not ground.save_to(): return fail(ground.last_error)
 var p: Vector3 = world.player.position
 var camera_state: Dictionary = world.market_garden.old_camera if world.market_garden.active else {}
 if not bool(camera_state.get("walking",world.walking_mode)):
  camera_state = {"orbit":world.orbit,"pitch":.28,"distance":4.6}
 var session := {"version":1,"position":[p.x,p.y,p.z],"facing":world.player.rotation.y,"orbit":camera_state.get("orbit",world.orbit),"pitch":camera_state.get("pitch",world.pitch),"distance":camera_state.get("distance",world.distance),"saved_at":Time.get_unix_time_from_system()}
 if not valid_session(session): return fail("The garden position is not ready to save yet.")
 if not atomic_json(save_root+"session.json",session): return fail("Your vault checkpoint could not be written.")
 if not backup(): return fail("Progress was saved, but its backup could not be written. Check free disk space.")
 return true

static func atomic_json(path: String, value: Dictionary) -> bool:
 if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir())) != OK: return false
 var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file == null: return false
 file.store_string(JSON.stringify(value))
 file.flush()
 var error := file.get_error()
 file.close()
 return error == OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path)) == OK

func backup() -> bool:
 var folder := save_root+"vault/"
 if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) != OK: return false
 var files: Array[String] = []
 for name in ["market.json","session.json","avatar/appearance.json"]:
  if FileAccess.file_exists(save_root+name): files.append(name)
 if DirAccess.dir_exists_absolute(save_root+"ground_cover"):
  for name in DirAccess.get_files_at(save_root+"ground_cover"):
   if name.ends_with(".json"): files.append("ground_cover/"+name)
 var zip := ZIPPacker.new()
 if zip.open(folder+"latest.tmp") != OK: return false
 for name in files:
  var bytes := FileAccess.get_file_as_bytes(save_root+name)
  if bytes.is_empty() or zip.start_file(name) != OK or zip.write_file(bytes) != OK or zip.close_file() != OK:
   zip.close()
   return false
 if zip.close() != OK: return false
 var check := ZIPReader.new()
 if check.open(folder+"latest.tmp") != OK: return false
 for name in files:
  if check.read_file(name) != FileAccess.get_file_as_bytes(save_root+name):
   check.close()
   return false
 check.close()
 # Preserve one previous checkpoint; only rotate after verifying the new archive.
 if FileAccess.file_exists(folder+"latest.zip"):
  if DirAccess.rename_absolute(ProjectSettings.globalize_path(folder+"latest.zip"),ProjectSettings.globalize_path(folder+"previous.zip")) != OK: return false
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(folder+"latest.tmp"),ProjectSettings.globalize_path(folder+"latest.zip")) == OK

func fail(message: String) -> bool:
 last_error = message
 return false

func _process(delta: float) -> void:
 timer += delta
 if timer >= 60:
  timer = 0
  save()

func _notification(what: int) -> void:
 if world == null or not is_inside_tree(): return
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT: save()
 elif what == NOTIFICATION_WM_CLOSE_REQUEST:
  if save(): get_tree().quit()
  elif not has_node("QuitAfterSaveFailure"):
   var dialog := ConfirmationDialog.new()
   dialog.name = "QuitAfterSaveFailure"
   dialog.title = "Garden could not be saved"
   dialog.dialog_text = last_error+"\nExisting files were kept. Quit anyway?"
   dialog.confirmed.connect(func() -> void: get_tree().quit())
   dialog.canceled.connect(func() -> void: dialog.queue_free())
   add_child(dialog)
   dialog.popup_centered()
