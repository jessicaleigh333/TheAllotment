extends RefCounted
## Signed, bounded release data and immutable installs. Never touches game user:// saves.
const APP := "the-allotment-windows"
const MAX_ARCHIVE := 536870912
const MAX_UNPACKED := 2147483648
const ENTRY := "TheAllotment.exe"
var last_error := ""

static func digest(bytes: PackedByteArray) -> PackedByteArray:
 var context := HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 context.update(bytes)
 return context.finish()

static func fail(message: String) -> Dictionary: return {"ok":false,"error":message}
static func whole(value: Variant, minimum: int, maximum: int) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum
static func hex_hash(value: Variant) -> bool:
 return value is String and value.length() == 64 and value.is_valid_hex_number(false)
static func safe_name(name: String) -> bool:
 if name.is_empty() or name.length() > 180 or name.begins_with("/") or name.contains("\\") or name.contains(":"): return false
 if name.ends_with("/"): name = name.left(-1)
 for part in name.split("/"):
  for i in range(part.length()):
   if part.unicode_at(i) < 32 or part.unicode_at(i) == 127 or part.unicode_at(i) == 65533: return false
  if part.is_empty() or part in [".",".."] or not part.is_valid_filename() or part.ends_with(".") or part.ends_with(" "): return false
  if part.get_slice(".",0).to_upper() in ["CON","PRN","AUX","NUL","COM1","COM2","COM3","COM4","COM5","COM6","COM7","COM8","COM9","LPT1","LPT2","LPT3","LPT4","LPT5","LPT6","LPT7","LPT8","LPT9"]: return false
 return true
static func release_url(value: Variant) -> bool:
 return value is String and value.begins_with("https://github.com/jessicaleigh333/TheAllotment/releases/download/") and not value.contains("?") and not value.contains("#") and not value.contains("\\") and value.length() < 600

static func decode_release(bytes: PackedByteArray, public_key: String) -> Dictionary:
 if bytes.size() > 262144: return fail("The update description is too large.")
 var parser := JSON.new()
 if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary: return fail("The update description is unreadable.")
 var outer: Dictionary = parser.data
 if not outer.get("payload") is String or not outer.get("signature") is String or outer.payload.length() > 180000 or outer.signature.length() > 1200: return fail("The update signature is missing.")
 var raw := Marshalls.base64_to_raw(outer.payload)
 var signature := Marshalls.base64_to_raw(outer.signature)
 var key := CryptoKey.new()
 if key.load_from_string(public_key,true) != OK or signature.size() != 256: return fail("The update signing key is not valid.")
 if not Crypto.new().verify(HashingContext.HASH_SHA256,digest(raw),signature,key): return fail("This update is not signed by The Allotment's release key.")
 if parser.parse(raw.get_string_from_utf8()) != OK or not parser.data is Dictionary: return fail("The signed update is unreadable.")
 var manifest: Dictionary = parser.data
 if manifest.get("schema") != 1 or manifest.get("app_id") != APP or manifest.get("platform") != "windows-x86_64" or manifest.get("entrypoint") != ENTRY: return fail("This update is for a different game or platform.")
 if not manifest.get("version") is String or manifest.version.length() > 40: return fail("The update version is invalid.")
 var version_regex := RegEx.new()
 version_regex.compile("^[0-9]+\\.[0-9]+\\.[0-9]+(-[a-z0-9.-]+)?$")
 if version_regex.search(manifest.version) == null or not whole(manifest.get("build"),1,2147483647): return fail("The update version is invalid.")
 if not release_url(manifest.get("url")) or not hex_hash(manifest.get("sha256")) or not whole(manifest.get("size"),1,MAX_ARCHIVE) or not whole(manifest.get("unpacked_size"),1,MAX_UNPACKED): return fail("The update download details are invalid.")
 var files = manifest.get("files")
 if not files is Dictionary or files.is_empty() or files.size() > 128 or not files.has(ENTRY) or not files.has("TheAllotment.pck"): return fail("The update does not contain the complete game.")
 var names := {}
 var total := 0
 for name in files:
  if not name is String or not safe_name(name) or names.has(name.to_lower()) or name.ends_with("/"): return fail("The update contains unsafe file names.")
  names[name.to_lower()] = true
  var info = files[name]
  if not info is Dictionary or not hex_hash(info.get("sha256")) or not whole(info.get("size"),1,MAX_ARCHIVE): return fail("The update file list is invalid.")
  total += int(info.size)
 if total != int(manifest.unpacked_size): return fail("The update size does not match its files.")
 if not manifest.get("notes","") is String or str(manifest.get("notes","")).length() > 2000: return fail("The release notes are invalid.")
 return {"ok":true,"manifest":manifest}

static func hash_file(path: String) -> String: return FileAccess.get_sha256(path)

static func inspect_archive(path: String, manifest: Dictionary) -> Dictionary:
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null or file.get_length() != int(manifest.size) or hash_file(path) != str(manifest.sha256).to_lower(): return fail("The download is incomplete or has changed. Your installed game is untouched.")
 var length := file.get_length()
 if length < 22: return fail("The downloaded archive is invalid.")
 var tail_size := mini(length,65557)
 file.seek(length-tail_size)
 var tail := file.get_buffer(tail_size)
 var eocd := -1
 for i in range(tail.size()-22,-1,-1):
  if tail.decode_u32(i) == 0x06054b50 and i+22+tail.decode_u16(i+20) == tail.size(): eocd = i; break
 if eocd < 0: return fail("The downloaded archive has no valid directory.")
 var count := tail.decode_u16(eocd+10)
 var central_size := tail.decode_u32(eocd+12)
 var offset := tail.decode_u32(eocd+16)
 if tail.decode_u16(eocd+4) != 0 or tail.decode_u16(eocd+6) != 0 or tail.decode_u16(eocd+8) != count or count < 1 or count > 256 or central_size > 262144 or offset+central_size != length-tail_size+eocd: return fail("Unsupported update archive layout.")
 var names := {}
 var total := 0
 file.seek(offset)
 var central := file.get_buffer(central_size)
 var position := 0
 for i in range(count):
  if position+46 > central.size() or central.decode_u32(position) != 0x02014b50: return fail("The archive directory is damaged.")
  var flags := central.decode_u16(position+8)
  var compression := central.decode_u16(position+10)
  var packed := central.decode_u32(position+20)
  var unpacked := central.decode_u32(position+24)
  var name_length := central.decode_u16(position+28)
  var extra_length := central.decode_u16(position+30)
  var comment_length := central.decode_u16(position+32)
  var mode := (central.decode_u32(position+38)>>16)&0xf000
  var local_offset := central.decode_u32(position+42)
  if position+46+name_length+extra_length+comment_length > central.size(): return fail("The archive directory is damaged.")
  var name := central.slice(position+46,position+46+name_length).get_string_from_utf8()
  position += 46+name_length+extra_length+comment_length
  if not safe_name(name) or names.has(name.to_lower()) or mode == 0xa000 or flags&1 or compression not in [0,8] or packed > MAX_ARCHIVE or unpacked > MAX_ARCHIVE or local_offset >= offset: return fail("The archive contains unsafe or unsupported entries.")
  names[name.to_lower()] = true
  if name.ends_with("/"):
   if unpacked != 0: return fail("The archive contains a nonempty directory.")
   continue
  if not manifest.files.has(name) or int(manifest.files[name].size) != unpacked: return fail("The archive does not match its signed file list.")
  total += unpacked
  if total > MAX_UNPACKED: return fail("The update expands beyond the allowed size.")
 if position != central.size() or total != int(manifest.unpacked_size): return fail("The archive is missing signed files.")
 for name in manifest.files:
  if not names.has(name.to_lower()): return fail("The archive is missing signed files.")
 return {"ok":true}

static func atomic_json(path: String, data: Dictionary) -> bool:
 var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file == null: return false
 file.store_string(JSON.stringify(data))
 file.flush()
 var error := file.get_error()
 file.close()
 return error == OK and DirAccess.rename_absolute(path+".tmp",path) == OK

static func safe_slot(slot: Variant) -> bool:
 if not slot is String or slot.length() != 24 or not slot.is_valid_hex_number(false): return false
 return true

static func read_json(path: String, limit: int = 262144) -> Dictionary:
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null or file.get_length() > limit: return {}
 var parser := JSON.new()
 if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary: return {}
 return parser.data

static func installed(root: String, slot: Variant, public_key: String) -> Dictionary:
 if not safe_slot(slot): return {}
 var folder := root.path_join("versions").path_join(slot)
 var bytes := FileAccess.get_file_as_bytes(folder.path_join(".signed-release.json"))
 var checked := decode_release(bytes,public_key)
 if not checked.ok: return {}
 var manifest: Dictionary = checked.manifest
 for name in manifest.files:
  var path := folder.path_join(name)
  var file := FileAccess.open(path,FileAccess.READ)
  if file == null or file.get_length() != int(manifest.files[name].size) or hash_file(path) != str(manifest.files[name].sha256).to_lower(): return {}
 return {"slot":slot,"manifest":manifest,"executable":folder.path_join(ENTRY)}

static func current(root: String, public_key: String) -> Dictionary:
 for name in ["active.json","active.previous.json"]:
  var state := read_json(root.path_join(name))
  var active := installed(root,state.get("active"),public_key)
  if active.is_empty(): continue
  active.previous = state.get("previous","")
  active.highest_build = maxi(int(state.get("highest_build",0)),int(active.manifest.build))
  return active
 return {}

static func pid_alive(pid: int, expected_name: String = "") -> bool:
 if pid <= 0: return false
 if pid == OS.get_process_id(): return expected_name.is_empty() or OS.get_executable_path().get_file().nocasecmp_to(expected_name) == 0
 if OS.get_name() == "Linux": return DirAccess.dir_exists_absolute("/proc/"+str(pid))
 if OS.get_name() == "Windows":
  # Godot's child-process table does not survive restarting the launcher.
  var system := OS.get_environment("SystemRoot")
  if system.is_empty(): system = "C:/Windows"
  var output := []
  var result := OS.execute(system.path_join("System32/tasklist.exe"),["/FI","PID eq "+str(pid),"/NH","/FO","CSV"],output,false,false)
  if result != 0 or output.is_empty(): return false
  var text := str(output[0]).strip_edges()
  return text.contains('","'+str(pid)+'",') and (expected_name.is_empty() or text.to_lower().begins_with('"'+expected_name.to_lower()+'",'))
 return OS.is_process_running(pid)

static func acquire_lock(root: String) -> bool:
 var folder := root.path_join("install.lock")
 if DirAccess.dir_exists_absolute(folder):
  var lock := read_json(folder.path_join("owner.json"))
  if lock.is_empty() and Time.get_unix_time_from_system()-FileAccess.get_modified_time(folder) < 120: return false
  if whole(lock.get("pid"),1,2147483647) and pid_alive(int(lock.pid)): return false
  DirAccess.remove_absolute(folder.path_join("owner.json"))
  if DirAccess.remove_absolute(folder) != OK: return false
 if DirAccess.make_dir_absolute(folder) != OK: return false
 return atomic_json(folder.path_join("owner.json"),{"pid":OS.get_process_id()})
static func release_lock(root: String) -> void:
 var folder := root.path_join("install.lock")
 DirAccess.remove_absolute(folder.path_join("owner.json"))
 DirAccess.remove_absolute(folder)

static func install(root: String, archive: String, envelope: PackedByteArray, public_key: String) -> Dictionary:
 var verified := decode_release(envelope,public_key)
 if not verified.ok: return verified
 var manifest: Dictionary = verified.manifest
 var preflight := inspect_archive(archive,manifest)
 if not preflight.ok: return preflight
 if DirAccess.make_dir_recursive_absolute(root.path_join("versions")) != OK: return fail("The game install folder could not be created.")
 if not acquire_lock(root): return fail("Another launcher is installing an update. Try again shortly.")
 var slot := Crypto.new().generate_random_bytes(12).hex_encode()
 var result := _install_locked(root,archive,envelope,manifest,public_key,slot)
 if not result.ok: _remove_tree(root.path_join("staging-"+slot))
 release_lock(root)
 return result

static func _install_locked(root: String, archive: String, envelope: PackedByteArray, manifest: Dictionary, public_key: String, slot: String) -> Dictionary:
 var old := current(root,public_key)
 if not old.is_empty() and int(manifest.build) <= int(old.highest_build): return fail("This release is not newer than the version already received.")
 var stage := root.path_join("staging-"+slot)
 if DirAccess.make_dir_absolute(stage) != OK: return fail("There is not enough access or disk space to prepare this update.")
 var zip := ZIPReader.new()
 if zip.open(archive) != OK: return fail("The download could not be opened.")
 for name in manifest.files:
  var bytes := zip.read_file(name)
  if bytes.size() != int(manifest.files[name].size) or digest(bytes).hex_encode() != str(manifest.files[name].sha256).to_lower():
   zip.close()
   return fail("An update file failed verification. The current game is untouched.")
  var path := stage.path_join(name)
  if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
   zip.close()
   return fail("The update could not create a file folder.")
  var file := FileAccess.open(path,FileAccess.WRITE)
  if file == null:
   zip.close()
   return fail("The update could not be written. Check free disk space.")
  file.store_buffer(bytes)
  file.flush()
  var error := file.get_error()
  file.close()
  if error != OK:
   zip.close()
   return fail("The update could not be written. Your current version is still available.")
 zip.close()
 var signed_file := FileAccess.open(stage.path_join(".signed-release.json"),FileAccess.WRITE)
 if signed_file == null: return fail("The installed version could not be recorded.")
 signed_file.store_buffer(envelope)
 signed_file.close()
 var destination := root.path_join("versions").path_join(slot)
 if DirAccess.rename_absolute(stage,destination) != OK: return fail("The new game folder could not be activated.")
 if installed(root,slot,public_key).is_empty(): return fail("The installed files could not be verified.")
 var previous: String = old.get("slot","")
 var state := {"active":slot,"previous":previous,"highest_build":manifest.build}
 if not old.is_empty():
  if not atomic_json(root.path_join("active.previous.json"),{"active":old.slot,"previous":old.get("previous",""),"highest_build":maxi(int(old.highest_build),int(manifest.build))}): return fail("The previous-version pointer could not be saved.")
 if not atomic_json(root.path_join("active.json"),state): return fail("The new version could not be activated. The previous game is still available.")
 for old_slot in DirAccess.get_directories_at(root.path_join("versions")):
  if not safe_slot(old_slot) or old_slot in [slot,previous]: continue
  var folder := root.path_join("versions").path_join(old_slot)
  if decode_release(FileAccess.get_file_as_bytes(folder.path_join(".signed-release.json")),public_key).ok: _remove_tree(folder)
 return {"ok":true,"version":manifest.version,"slot":slot}

static func rollback(root: String, public_key: String) -> bool:
 if not acquire_lock(root): return false
 var active := current(root,public_key)
 var previous := installed(root,active.get("previous"),public_key)
 var ok := false
 if not previous.is_empty():
  ok = atomic_json(root.path_join("active.json"),{"active":previous.slot,"previous":active.slot,"highest_build":active.highest_build})
 release_lock(root)
 return ok

static func _remove_tree(folder: String) -> void:
 var directory := DirAccess.open(folder)
 if directory == null: return
 for name in directory.get_files(): DirAccess.remove_absolute(folder.path_join(name))
 for name in directory.get_directories():
  if directory.is_link(name): DirAccess.remove_absolute(folder.path_join(name))
  else: _remove_tree(folder.path_join(name))
 DirAccess.remove_absolute(folder)
