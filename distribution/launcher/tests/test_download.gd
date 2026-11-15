extends SceneTree
const P := preload("res://protocol.gd")
var scene
var fixtures := ""
var server := ""
func _initialize() -> void: call_deferred("verify")
func set_pending(build: int, path: String) -> void:
 scene.pending_envelope = FileAccess.get_file_as_bytes(fixtures.path_join(str(build)+"/update.json"))
 scene.pending = P.decode_release(scene.pending_envelope,scene.public_key).manifest
 # Substitute only the transport URL for the local HTTP fixture. Signed data is unchanged.
 scene.pending.url = server+path
func wait_idle() -> void:
 for i in range(500):
  if not scene.busy: return
  await create_timer(.01).timeout
 assert(false,"HTTP integration timed out")
func verify() -> void:
 fixtures = OS.get_cmdline_user_args()[0]
 server = OS.get_cmdline_user_args()[1]
 scene = load("res://launcher.tscn").instantiate()
 scene.auto_check = false
 root.add_child(scene)
 await process_frame
 scene.public_key = FileAccess.get_file_as_string(fixtures.path_join("test-public.pem"))
 scene.root_path = ProjectSettings.globalize_path("user://http-install")
 scene.automatic.button_pressed = false
 DirAccess.make_dir_recursive_absolute(scene.root_path)
 set_pending(1,"/1/TheAllotment-Windows-0.3.1.zip")
 scene._download()
 await wait_idle()
 assert(scene.active.manifest.build == 1,"Actual HTTP first install")
 set_pending(2,"/missing.zip")
 scene._download()
 await wait_idle()
 assert(P.current(scene.root_path,scene.public_key).manifest.build == 1,"404 preserves installed game")
 set_pending(2,"/truncated.zip")
 scene._download()
 await wait_idle()
 assert(P.current(scene.root_path,scene.public_key).manifest.build == 1,"Truncated response preserves game")
 set_pending(2,"/2/TheAllotment-Windows-0.3.2.zip")
 scene._download()
 await wait_idle()
 assert(scene.active.manifest.build == 2,"Actual HTTP upgrade")
 set_pending(4,"/slow.zip")
 scene._download()
 await create_timer(.1).timeout
 scene._cancel_download()
 assert(not scene.busy and not scene.play.disabled)
 assert(P.current(scene.root_path,scene.public_key).manifest.build == 2,"Cancelled download preserves game")
 scene.game_pid = OS.get_process_id()
 scene._download()
 assert(not scene.busy,"Running game prevents download/install")
 scene.game_pid = -1
 scene.free()
 print("PASS real HTTP updater: first install, upgrade, 404, truncated response, cancellation, installed-game preservation and running-game guard")
 quit()
