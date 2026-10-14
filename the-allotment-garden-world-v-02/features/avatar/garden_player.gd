extends CharacterBody3D
## Camera-relative strolling; all gardens are visitable, no editing/claiming here.
@export var stroll_speed := 2.6
@export var brisk_speed := 4.2
var world: Node3D
var movement_enabled := true
var spawn_position := Vector3(0,.2,18)
var maximum_radius := 165.0
var requested_direction := Vector2.ZERO
var use_requested_direction := false

func _ready() -> void:
	$Visual.apply_appearance(preload("res://features/avatar/appearance.gd").load_saved())
	var height: float = $Visual.appearance.height
	var build: float = $Visual.appearance.body_build
	$CollisionShape3D.shape = $CollisionShape3D.shape.duplicate()
	$CollisionShape3D.shape.height = 1.65*height
	$CollisionShape3D.shape.radius = .25*height*build
	$CollisionShape3D.position.y = .84*height

func _physics_process(delta: float) -> void:
	var move := Vector2.ZERO
	var can_move := movement_enabled
	if world != null:
		can_move = can_move and not world.ui_panel_open and world.walking_mode
		if world.ground_editor_session != null and world.ground_editor_session.active: can_move = false
		if get_viewport().gui_get_focus_owner() is LineEdit: can_move = false
	if can_move:
		if use_requested_direction: move = requested_direction.limit_length(1.0)
		else:
			move = Vector2(float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))).limit_length(1.0)
	var heading: float = world.orbit if world != null else 0.0
	var direction := Vector3(move.x,0,move.y).rotated(Vector3.UP,heading)
	var speed := brisk_speed if Input.is_key_pressed(KEY_SHIFT) else stroll_speed
	velocity.x = move_toward(velocity.x,direction.x*speed,delta*14.0)
	velocity.z = move_toward(velocity.z,direction.z*speed,delta*14.0)
	if not can_move:
		velocity.x = 0
		velocity.z = 0
	if not is_on_floor(): velocity.y -= 16.0*delta
	else: velocity.y = -.5
	move_and_slide()
	var moving := Vector2(velocity.x,velocity.z).length() > .1
	if moving: $Visual.rotation.y = lerp_angle($Visual.rotation.y,atan2(velocity.x,velocity.z),minf(1,delta*9))
	$Visual.set_motion(moving,speed/stroll_speed)
	if position.y < -12 or Vector2(position.x,position.z).length() > maximum_radius: respawn()

func respawn() -> void:
	position = spawn_position
	velocity = Vector3.ZERO
