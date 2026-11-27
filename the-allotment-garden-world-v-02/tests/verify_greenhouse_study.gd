extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var study := preload("res://staging/greenhouse_atrium_study.tscn").instantiate()
	root.add_child(study)
	var player = study.get_node("GardenPlayer")
	player.use_requested_direction = true
	player.position = Vector3(0, 0.05, -6.55)
	await _walk(player, Vector2(0, 1), 45)
	assert(player.position.z > -5.2 and player.position.y > -0.05, "Walk through the front door")
	player.position = Vector3(-2.5, 0.08, 0.20)
	await _walk(player, Vector2(0, 1), 160)
	assert(player.position.y > 1.56 and player.position.z > 3.15, "Reach the quarter-turn landing: " + str(player.position))
	await _walk(player, Vector2(1, 0), 145)
	assert(player.position.x > 0.68 and player.position.y > 3.16, "Reach the upper mezzanine: " + str(player.position))
	await _walk(player, Vector2(1, 0), 100)
	assert(player.position.x < 3.11 and player.position.y > 3.16, "Upper outer rail must block a fall")
	study.free()
	print("PASS: greenhouse entrance, two ramp flights, quarter-turn landing and upper rail collision")
	quit()

func _walk(player: CharacterBody3D, direction: Vector2, frames: int) -> void:
	player.velocity = Vector3.ZERO
	player.requested_direction = direction
	for _frame in range(frames):
		await physics_frame
	player.requested_direction = Vector2.ZERO
