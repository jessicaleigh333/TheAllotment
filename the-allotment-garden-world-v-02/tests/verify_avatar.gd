extends SceneTree
const Appearance := preload("res://features/avatar/appearance.gd")
func _initialize() -> void:
	call_deferred("_verify")
func _wait_physics(frames: int) -> void:
	for i in range(frames): await physics_frame

func _role_material(visual: Node3D, part: String, role: String) -> Material:
	for index in range(visual.originals[part].size()):
		var original = visual.originals[part][index]
		if original != null and original.resource_name == role:
			return visual.meshes[part].get_surface_override_material(index)
	return null

func _weighted_bones(mesh: MeshInstance3D) -> Dictionary:
	var result := {}
	for surface in range(mesh.mesh.get_surface_count()):
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		for index in range(weights.size()):
			if weights[index] > .001:
				result[str(mesh.skin.get_bind_name(joints[index]))] = true
	return result

func _verify_textured_surfaces(visual: Node3D, second: Node3D, restore: Dictionary) -> void:
	# Dyed surfaces retain their authored variation, normal and roughness maps.
	# Texture resources can be shared; changing one avatar must not share its dye.
	var surfaces := [
		["Skirt","Outfit",["detail_texture","detail_normal","embroidery_texture","embroidery_normal","woven_normal","woven_orm"]],
		["HairLong","Hair",["detail_texture","detail_normal"]],
		["Satchel","Leather",["detail_texture","detail_normal"]],
		["Hat","Hat",["detail_texture","detail_normal"]],
		["Face","Skin",["detail_texture","complexion_texture"],["skin_brush_detail.png","face_complexion.png"]],
		["Irises","Eyes",["detail_texture"],["iris_fibers.png"]]
	]
	var before := {}
	for entry in surfaces:
		var material := _role_material(visual,entry[0],entry[1]) as ShaderMaterial
		var other := _role_material(second,entry[0],entry[1]) as ShaderMaterial
		assert(material != null and other != null,"Missing textured surface: "+entry[0])
		assert(material != other,"Avatar dye material is shared: "+entry[0])
		if entry[0] == "Face": assert(material.get_shader_parameter("face_detail") == true)
		var maps := {}
		for index in range(entry[2].size()):
			var uniform: String = entry[2][index]
			var texture = material.get_shader_parameter(uniform)
			assert(texture is Texture2D,"Missing surface map: "+entry[0]+"/"+uniform)
			assert(texture.get_width() >= 128 and texture.get_height() >= 128,"Surface map is too small: "+entry[0]+"/"+uniform)
			assert(texture == other.get_shader_parameter(uniform),"Immutable surface map was duplicated per avatar: "+entry[0]+"/"+uniform)
			if entry.size() > 3:
				assert(texture == load("res://assets/characters/gardener/textures/"+entry[3][index]),"Wrong painted face map: "+entry[0]+"/"+uniform)
			maps[uniform] = texture
		before[entry[0]] = maps
	var recolored := Appearance.defaults()
	recolored.outfit_color = "385d82ff"
	recolored.hair_color = "8b3248ff"
	recolored.leather_color = "4b653aff"
	recolored.hat_color = "b7a16aff"
	recolored.skin_color = "895d45ff"
	recolored.eye_color = "5e84b0ff"
	var color_fields := {"Skirt":"outfit_color","HairLong":"hair_color","Satchel":"leather_color","Hat":"hat_color","Face":"skin_color","Irises":"eye_color"}
	var other_appearance: Dictionary = second.appearance.duplicate(true)
	assert(visual.apply_appearance(recolored))
	for entry in surfaces:
		var material := _role_material(visual,entry[0],entry[1]) as ShaderMaterial
		assert(material.get_shader_parameter("tint") == Color.html(recolored[color_fields[entry[0]]]),"Surface dye did not update: "+entry[0])
		if entry[0] == "Face": assert(material.get_shader_parameter("face_detail") == true)
		for uniform in entry[2]:
			assert(material.get_shader_parameter(uniform) == before[entry[0]][uniform],"Recoloring removed surface detail: "+entry[0]+"/"+uniform)
	assert(second.appearance == other_appearance,"Textured recoloring changed another avatar")
	assert(visual.apply_appearance(restore))

func _verify_soft_proportions(visual: Node3D) -> void:
	# Exported bounds include each arm's diagonal tilt and cuff width in X.
	# Forward depth measures the limb/sleeve thickness independently of that tilt.
	for suffix in ["-1","1"]:
		var arm: MeshInstance3D = visual.meshes["UpperArm"+suffix]
		var sleeve: MeshInstance3D = visual.meshes["Sleeve"+suffix]
		assert(arm.mesh.get_aabb().size.z < .075,"Upper arm has reverted to the bulky prototype silhouette")
		assert(sleeve.mesh.get_aabb().size.z < .125,"Puff sleeve has reverted to the bulky prototype silhouette")

func _verify_animation(visual: Node3D) -> void:
	var mesh: MeshInstance3D = visual.meshes["Boot-1"]
	var skeleton := mesh.get_node(mesh.skeleton) as Skeleton3D
	var thigh := skeleton.find_bone("Thigh.L")
	assert(thigh >= 0)
	visual.set_motion(false)
	visual.animator.advance(.25)
	await process_frame
	var idle_pose := skeleton.get_bone_pose_rotation(thigh)
	visual.set_motion(true)
	visual.animator.advance(.65)
	await process_frame
	assert(idle_pose.angle_to(skeleton.get_bone_pose_rotation(thigh)) > .05,"Walk clip did not animate the character's skeleton")
	visual.set_motion(false)
	for pair in [["Boot-1","Shin.L","Foot.L"],["Boot1","Shin.R","Foot.R"]]:
		var weighted := _weighted_bones(visual.meshes[pair[0]])
		assert(weighted.has(pair[1]) and weighted.has(pair[2]),"Tall boots must follow both the calf and foot: "+pair[0])

func _verify_customization(visual: Node3D, restore: Dictionary) -> void:
	# Each exported alternative must remain independently selectable after art updates.
	var look := Appearance.defaults()
	var hair_parts := {"long":"HairLong","bob":"HairBob","braids":"HairBraids","bun":"HairBun"}
	for style in hair_parts:
		look.hair_style = style
		assert(visual.apply_appearance(look))
		for other in hair_parts:
			assert(visual.meshes[hair_parts[other]].visible == (style == other))
	for outfit in ["dress","trousers"]:
		look.outfit_style = outfit
		assert(visual.apply_appearance(look))
		for part in ["Skirt","SkirtHem","Embroidery","Underskirt","Overskirt","OverskirtTrim","SkirtLace"]:
			if visual.meshes.has(part):
				assert(visual.meshes[part].visible == (outfit == "dress"),"Dress detail leaks into the trousers outfit: "+part)
		for part in visual.meshes:
			if part.begins_with("Trouser"):
				assert(visual.meshes[part].visible == (outfit == "trousers"))
	look.hat_enabled = false
	look.flowers_enabled = true
	look.satchel_enabled = false
	look.apron_enabled = false
	look.freckles_enabled = false
	assert(visual.apply_appearance(look))
	for part in ["Hat","HatFlowers","Satchel","Apron","Freckles"]:
		assert(not visual.meshes[part].visible)
	look.hat_enabled = true
	look.flowers_enabled = false
	look.satchel_enabled = true
	look.apron_enabled = true
	look.freckles_enabled = true
	assert(visual.apply_appearance(look))
	assert(visual.meshes.Hat.visible and not visual.meshes.HatFlowers.visible)
	for part in ["Satchel","Apron","Freckles"]: assert(visual.meshes[part].visible)
	# The face controls must still drive all exported facial components together.
	look.face_width = .35
	look.face_length = .45
	look.nose_size = .55
	look.eye_size = .65
	look.eye_spacing = .75
	look.height = 1.08
	look.body_build = 1.12
	look.outfit_style = "dress"
	look.outfit_color = "525ea8ff"
	look.blouse_color = "edd1a0ff"
	look.flower_color = "d0789aff"
	assert(visual.apply_appearance(look))
	assert(visual.scale.is_equal_approx(Vector3(1.08*1.12,1.08,1.08)))
	for pair in [["Face","FaceWidth","face_width"],["Face","FaceLength","face_length"],["Face","NoseSize","nose_size"]]:
		var mesh: MeshInstance3D = visual.meshes[pair[0]]
		var index := mesh.find_blend_shape_by_name(pair[1])
		assert(index >= 0 and is_equal_approx(mesh.get_blend_shape_value(index),look[pair[2]]),"Missing facial morph: "+pair[0]+"/"+pair[1])
	for part in ["EyeWhites","Irises","Pupils","EyeGlints","Eyelids","LowerEyelids","Brows"]:
		for pair in [["EyeSize","eye_size"],["EyeSpacing","eye_spacing"]]:
			var mesh: MeshInstance3D = visual.meshes[part]
			var index := mesh.find_blend_shape_by_name(pair[0])
			assert(index >= 0 and is_equal_approx(mesh.get_blend_shape_value(index),look[pair[1]]),"Missing facial morph: "+part+"/"+pair[0])
	var cloth := _role_material(visual,"Skirt","Outfit") as ShaderMaterial
	assert(cloth != null and cloth.shader != null)
	assert(cloth.get_shader_parameter("tint") == Color.html(look.outfit_color))
	assert(cloth.get_shader_parameter("flower_tint") == Color.html(look.flower_color))
	assert(cloth.get_shader_parameter("floral") == true)
	var before: Dictionary = visual.appearance.duplicate(true)
	var invalid := look.duplicate(true)
	invalid.hair_style = "missing-style"
	assert(not visual.apply_appearance(invalid))
	assert(visual.appearance == before and _role_material(visual,"Skirt","Outfit") == cloth)
	assert(visual.apply_appearance(restore))
	# Exported decorative additions must remain bound to the same reusable rig.
	for mesh in visual.meshes.values():
		assert(mesh.skin != null and mesh.skin.get_bind_count() > 0,"Unskinned avatar part: "+str(mesh.name))
		assert(mesh.get_node_or_null(mesh.skeleton) is Skeleton3D)
	for name in visual.animation_names.values():
		assert(visual.animator.get_animation(name).loop_mode == Animation.LOOP_LINEAR)

func _verify() -> void:
	var look := Appearance.defaults()
	look.skin_color = "855a42ff"
	look.hair_style = "braids"
	look.outfit_style = "trousers"
	look.hat_enabled = false
	look.face_width = .4
	look.eye_size = .6
	assert(Appearance.save(look,"user://avatar/automated_test_appearance.json"))
	assert(Appearance.load_saved("user://avatar/automated_test_appearance.json") == Appearance.validate(look))
	var invalid := look.duplicate(true)
	invalid.skin_color = "invalid"
	assert(not Appearance.save(invalid,"user://avatar/automated_test_appearance.json"))
	assert(Appearance.validate(invalid).is_empty())
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://avatar/automated_test_appearance.json"))
	var preview = load("res://features/avatar/screen.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	var visual = preview.character
	assert(visual.meshes.has("Face") and visual.meshes.has("HairLong"))
	assert(visual.animation_names.has("idle") and visual.animation_names.has("walk"))
	assert(visual.apply_appearance(look))
	assert(not visual.meshes.Hat.visible and visual.meshes.HairBraids.visible and not visual.meshes.HairLong.visible)
	assert(not visual.meshes.Skirt.visible and visual.meshes["TrouserUpper-1"].visible)
	assert(is_equal_approx(visual.meshes.Face.get_blend_shape_value(visual.meshes.Face.find_blend_shape_by_name("FaceWidth")),.4))
	var second = load("res://assets/characters/gardener/gardener_visual.tscn").instantiate()
	root.add_child(second)
	assert(second.meshes.Hat.visible and second.meshes.Skirt.visible)
	assert(second.meshes.Face.get_surface_override_material(0) != visual.meshes.Face.get_surface_override_material(0))
	_verify_soft_proportions(visual)
	_verify_textured_surfaces(visual,second,look)
	_verify_customization(visual,look)
	assert(second.meshes.Hat.visible and second.meshes.Skirt.visible)
	assert(second.appearance == Appearance.defaults(),"Customizing one avatar changed another avatar")
	visual.set_motion(true)
	assert(visual.current_motion == "walk")
	visual.set_motion(false)
	assert(visual.current_motion == "idle")
	await _verify_animation(visual)
	preview.apply_preset(1)
	assert(visual.meshes.HairBob.visible)
	preview.apply_preset(2)
	assert(visual.meshes.HairBraids.visible and not visual.meshes.Skirt.visible)
	preview.queue_free()
	second.queue_free()
	await process_frame
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await _wait_physics(20)
	var player = world.player
	assert(player != null and world.walking_mode)
	assert(player.is_on_floor(),"Player should stand on the actual courtyard")
	assert(absf(player.position.y - .11) < .08)
	var initial: Vector3 = player.position
	world.orbit = 0
	player.use_requested_direction = true
	player.requested_direction = Vector2(1,0)
	await _wait_physics(25)
	assert(player.position.x > initial.x+.5)
	assert(player.get_node("Visual").current_motion == "walk")
	world.ui_panel_open = true
	var paused: Vector3 = player.position
	await _wait_physics(8)
	assert(Vector2(player.position.x,player.position.z).distance_to(Vector2(paused.x,paused.z)) < .001)
	world.ui_panel_open = false
	world.set_walking_mode(false)
	paused = player.position
	await _wait_physics(8)
	assert(Vector2(player.position.x,player.position.z).distance_to(Vector2(paused.x,paused.z)) < .001)
	world.set_walking_mode(true)
	player.requested_direction = Vector2.ZERO
	# Every wedge entrance is physically accessible; no visitor/ownership lock.
	for index in range(9):
		var angle := float(index)*TAU/9
		player.position = Vector3(sin(angle)*28,.25,cos(angle)*28)
		player.velocity = Vector3.ZERO
		world.orbit = angle
		player.requested_direction = Vector2(0,1)
		await _wait_physics(125)
		var radius := Vector2(player.position.x,player.position.z).length()
		assert(radius > 32.5,"A garden entrance is blocked: "+str(index))
		assert(player.position.y > -.2,"Player fell through garden terrain")
	# A hedge blocks sideways crossing between gardens.
	var angle: float = world.WEDGE_ANGLE/2
	player.position = Vector3(sin(angle-.03)*70,.3,cos(angle-.03)*70)
	player.velocity = Vector3.ZERO
	world.orbit = angle
	player.requested_direction = Vector2(1,0)
	await _wait_physics(90)
	assert(atan2(player.position.x,player.position.z) < angle)
	world.open_ground_editor()
	paused = player.position
	await _wait_physics(8)
	assert(Vector2(player.position.x,player.position.z).distance_to(Vector2(paused.x,paused.z)) < .001)
	world.ground_editor_session.close()
	player.position.y = -20
	player.respawn()
	assert(player.position == player.spawn_position)
	world.queue_free()
	await process_frame
	print("PASS: appearance save/validation, all modular hair/outfits/accessories, complete exported face morphs, textured recoloring with shared maps and independent dye, rig bindings, idle/walk animation, floor collision, movement, UI/editor pause, overview, all nine entrances and hedge collision")
	quit()
