extends SceneTree
const P := preload("res://protocol.gd")
var fixtures := ""
var public_key := ""
var install_root := ""
func _initialize() -> void: call_deferred("verify")
func read_fixture(path: String) -> PackedByteArray: return FileAccess.get_file_as_bytes(fixtures.path_join(path))
func envelope(build: int) -> PackedByteArray: return read_fixture(str(build)+"/update.json")
func archive(build: int) -> String: return fixtures.path_join(str(build)+"/TheAllotment-Windows-0.3."+str(build)+".zip")
func verify() -> void:
 fixtures = OS.get_cmdline_user_args()[0]
 public_key = read_fixture("test-public.pem").get_string_from_utf8()
 install_root = ProjectSettings.globalize_path("user://test-installs")
 DirAccess.make_dir_recursive_absolute(install_root)
 var saves := install_root.get_base_dir().path_join("garden-save-sentinel.json")
 var sentinel := FileAccess.open(saves,FileAccess.WRITE)
 sentinel.store_string("precious garden progress")
 sentinel.close()
 for bad in ["../escape","/absolute","C:/drive","a\\b","AUX.txt","a/CON","a/../b","trailing.","space ","line\nbreak","nul"+String.chr(0)+".bin"]:
  assert(not P.safe_name(bad),bad)
 assert(P.safe_name("licenses/Godot.txt"))
 assert(P.decode_release(envelope(1),public_key).ok)
 var altered := envelope(1).duplicate()
 altered[40] = 65 if altered[40] != 65 else 66
 assert(not P.decode_release(altered,public_key).ok)
 assert(not P.decode_release(envelope(1),read_fixture("wrong-public.pem").get_string_from_utf8()).ok)
 assert(P.install(install_root,archive(1),envelope(1),public_key).ok)
 var one := P.current(install_root,public_key)
 assert(one.manifest.build == 1)
 assert(P.install(install_root,archive(2),envelope(2),public_key).ok)
 var two := P.current(install_root,public_key)
 assert(two.manifest.build == 2 and two.previous == one.slot)
 assert(not P.install(install_root,archive(1),envelope(1),public_key).ok,"Reject downgrade")
 assert(not P.install(install_root,archive(1),envelope(3),public_key).ok,"Reject wrong archive hash")
 for kind in ["traversal","symlink","duplicate","oversize"]:
  var signed := read_fixture(kind+"/update.json")
  assert(P.decode_release(signed,public_key).ok)
  assert(not P.install(install_root,fixtures.path_join(kind+"/attack.zip"),signed,public_key).ok,"Reject archive attack: "+kind)
  assert(P.current(install_root,public_key).manifest.build == 2)
 assert(not FileAccess.file_exists(install_root.path_join("escaped.txt")))
 assert(P.acquire_lock(install_root))
 assert(not P.install(install_root,archive(3),envelope(3),public_key).ok,"Concurrent installer blocked")
 P.release_lock(install_root)
 var pointer := FileAccess.get_file_as_string(install_root.path_join("active.json"))
 var file := FileAccess.open(install_root.path_join("active.json"),FileAccess.WRITE)
 file.store_string("interrupted pointer")
 file.close()
 assert(P.current(install_root,public_key).manifest.build == 1,"Recover from previous pointer")
 file = FileAccess.open(install_root.path_join("active.json"),FileAccess.WRITE)
 file.store_string(pointer)
 file.close()
 assert(P.rollback(install_root,public_key))
 var rolled := P.current(install_root,public_key)
 assert(rolled.manifest.build == 1 and rolled.highest_build == 2)
 assert(not P.install(install_root,archive(2),envelope(2),public_key).ok,"Rollback is not immediately undone by feed")
 assert(P.install(install_root,archive(3),envelope(3),public_key).ok)
 assert(P.current(install_root,public_key).manifest.build == 3)
 file = FileAccess.open(P.current(install_root,public_key).executable,FileAccess.WRITE)
 file.store_string("damaged exe")
 file.close()
 assert(P.current(install_root,public_key).manifest.build == 1,"Tampered install falls back to verified previous pointer")
 assert(FileAccess.get_file_as_string(saves) == "precious garden progress")
 # Real launcher controls: offline state, checked feed, opt-out, process lock, rollback UI.
 var scene = load("res://launcher.tscn").instantiate()
 scene.auto_check = false
 root.add_child(scene)
 await process_frame
 scene.public_key = public_key
 scene.root_path = install_root
 scene.active = P.current(install_root,public_key)
 scene.automatic.button_pressed = false
 scene._offline()
 assert(not scene.play.disabled)
 scene.request_kind = "feed"
 scene._response(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),envelope(4))
 assert(scene.pending.build == 4 and scene.update_button.visible)
 scene.game_pid = OS.get_process_id()
 scene._refresh()
 assert(scene.play.disabled and scene.update_button.disabled)
 scene.game_pid = -1
 scene._refresh()
 # A newer USB copy also updates an existing installation without internet.
 var media := fixtures.path_join("media")
 DirAccess.make_dir_recursive_absolute(media)
 DirAccess.copy_absolute(fixtures.path_join("4/TheAllotment-Windows-0.3.4.zip"),media.path_join("starter-game.zip"))
 DirAccess.copy_absolute(fixtures.path_join("4/update.json"),media.path_join("starter-update.json"))
 await scene._install_media_if_newer(media)
 assert(scene.active.manifest.build == 4,"Offline media upgrade works for existing installs")
 scene.free()
 print("PASS updater: RSA signatures, archive/file hashes, safe paths/symlinks/case collisions/size limits, first install, newer release, rollback/downgrade protection, concurrent lock, interrupted pointer and tamper recovery, unchanged saves, offline launcher and live-game guard")
 quit()
