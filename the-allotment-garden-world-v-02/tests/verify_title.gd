extends SceneTree
const Calendar := preload("res://features/title/title_calendar.gd")
func _initialize() -> void:
 call_deferred("verify")
func verify() -> void:
 var expected := [3,3,0,0,0,1,1,1,2,2,2,3]
 for month in range(1,13):
  assert(Calendar.season_for_month(month) == expected[month-1])
  assert(Calendar.season_for_month(month,true) == (expected[month-1]+2)%4)
 assert(Calendar.night_for_hour(0) == 1 and Calendar.night_for_hour(12) == 0)
 assert(Calendar.night_for_hour(7) > 0 and Calendar.night_for_hour(7) < 1)
 var title = load("res://features/title/title_screen.tscn").instantiate()
 root.add_child(title)
 await process_frame
 assert(title.canvas.get_node("Login") is Button)
 assert(title.canvas.get_node("CreateAccount") is Button)
 assert(title.ambience.breeze.playing and title.ambience.insects.playing)
 assert(title.ambience.chime_delay >= 14)
 title.canvas.get_node("Settings").pressed.emit()
 assert(title.settings.visible)
 for season in range(4):
  for night in range(2):
   title.season_override = season
   title.time_override = night
   title._refresh_calendar()
   assert(title.current_season == season and title.current_night == night)
   assert(title.picture.texture == title.SEASON_ART[season])
 assert(title.ambience.insects.volume_db < -80,"Winter insects should be silent")
 title.season_override = -1
 title.time_override = -1
 title.southern = false
 title._refresh_calendar({"month":11,"hour":23,"minute":0})
 assert(title.current_season == 2 and title.current_night == 1)
 title.ambience.muted = true
 title.reduced_motion = true
 title._apply_settings()
 assert(title.ambience.breeze.volume_db <= -80)
 await process_frame
 assert(not title.butterfly.visible)
 title.canvas.get_node("Login").pressed.emit()
 assert(title.profile_panel != null)
 title.canvas.get_node("CreateAccount").pressed.emit()
 assert(title.profile_panel.find_child("ProfileName",true,false) is LineEdit)
 title.ambience.muted = false
 title.reduced_motion = false
 title._apply_settings()
 title.queue_free()
 await process_frame
 await create_timer(.2).timeout
 print("PASS: all seasonal/day-night combinations, hemisphere and clock boundaries, profile panels, ambience, mute/reduced motion")
 quit()
