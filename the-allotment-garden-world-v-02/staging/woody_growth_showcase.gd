extends "res://staging/garden_art_gallery.gd"
var reference: Node3D
func _ready() -> void:
 super._ready()
 asset_choice.clear()
 for id in Growth.Woody.PROFILES:
  asset_choice.add_item(Growth.Woody.PROFILES[id].name)
  asset_choice.set_item_metadata(asset_choice.item_count-1,id)
 stage = 3
 stage_choice.select(stage)
 show_asset("tree")
func show_asset(id: String) -> void:
 super.show_asset(id)
 if not Growth.Woody.PROFILES.has(id): return
 if reference != null: reference.free()
 var profile: Dictionary = Growth.Woody.PROFILES[id]
 heading.text = profile.name
 for i in range(5): stage_choice.set_item_text(i,profile.names[i])
 stage_choice.select(stage)
 stats.text += "\nPlant age: %.2f real years\nDepth / row length: %.2f m\n1.65 m reference post; no live time changes" % [float(profile.days[stage])/365.25,float(profile.depths[stage])]
 reference = Node3D.new()
 add_child(reference)
 var bounds := _bounds(specimen)
 reference.position = Vector3(-maxf(.8,bounds.size.x*.6),0,.45)
 var avatar := preload("res://assets/characters/gardener/gardener_visual.tscn").instantiate()
 avatar.position.x = -.45
 reference.add_child(avatar)
 var material := StandardMaterial3D.new()
 material.albedo_color = Color("e7d7aa")
 var post := MeshInstance3D.new()
 var shape := BoxMesh.new()
 shape.size = Vector3(.025,1.65,.025)
 post.mesh = shape
 post.position.y = .825
 post.material_override = material
 reference.add_child(post)
 for height in [0.,.5,1.,1.5,1.65]:
  var tick := MeshInstance3D.new()
  var box := BoxMesh.new()
  box.size = Vector3(.14,.015,.04)
  tick.mesh = box
  tick.position.y = height
  tick.material_override = material
  reference.add_child(tick)
 var label := Label3D.new()
 label.text = "1.65 m"
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 label.pixel_size = .0015
 label.position.y = 1.8
 reference.add_child(label)
 var span := maxf(2.3,maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z)))
 target = Vector3(0,maxf(.8,bounds.size.y*.5),0)
 distance = span*2.1
 _update_camera()
