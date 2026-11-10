extends SceneTree
func _initialize() -> void:
    call_deferred("verify")
func frames(count: int) -> void:
    for i in range(count): await physics_frame
func verify() -> void:
    var world = load("res://main.tscn").instantiate()
    root.add_child(world)
    await frames(30)
    var player = world.player
    player.use_requested_direction = true
    for index in range(9):
        var angle = float(index) * TAU / 9
        world.orbit = angle
        player.position = Vector3(-3.1,.2,29).rotated(Vector3.UP,angle)
        player.velocity = Vector3.ZERO
        player.requested_direction = Vector2.ZERO
        await frames(20)
        player.requested_direction = Vector2(1,0)
        await frames(65)
        var local = player.position.rotated(Vector3.UP,-angle)
        assert(local.x > -.8, "Sidewalk entry blocked: " + str(index))
        assert(local.y > .10, "Player did not reach paving")
        player.requested_direction = Vector2(-1,0)
        await frames(70)
        local = player.position.rotated(Vector3.UP,-angle)
        assert(local.x < -2.7, "Sidewalk exit blocked")
    player.requested_direction = Vector2.ZERO
    world._open_plant_catalog()
    await process_frame
    assert(world.ui_panel_open)
    print("PASS: all nine sidewalk side entries and exits, catalog opens")
    quit()
