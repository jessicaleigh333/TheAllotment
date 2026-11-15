extends Node
## Proximity opening works on desktop and touch, with hysteresis and safe closing.
var opened := false
var auto_open := true
var amount := 0.0
var clear_time := 0.0
var left: Node3D
var right: Node3D

func _ready() -> void:
	left = get_parent().find_child("LeftHinge",true,false)
	right = get_parent().find_child("RightHinge",true,false)

func set_open(value: bool) -> void:
	opened = value

func _physics_process(delta: float) -> void:
	if not is_instance_valid(left) or not is_instance_valid(right): return
	var preview: bool = get_parent().get_meta("placement_preview",false)
	if preview: return
	if auto_open:
		var players := get_tree().get_nodes_in_group("garden_players")
		if not players.is_empty():
			var nearby := false
			var center: Vector3 = (left.global_position+right.global_position)*.5
			for player in players:
				if not player is Node3D: continue
				var offset: Vector3 = player.global_position-center
				if Vector2(offset.x,offset.z).length() < (3.0 if opened else 2.7) and absf(offset.y) < 2.2: nearby = true
			if nearby:
				clear_time = 0
				opened = true
			else:
				clear_time += delta
				if clear_time > 2: opened = false
	amount = move_toward(amount,1.0 if opened else 0.0,delta*1.25)
	left.rotation.y = -amount*deg_to_rad(100)
	right.rotation.y = amount*deg_to_rad(100)

func install_leaf_collision() -> int:
	var count := 0
	for hinge in [left,right]:
		if not is_instance_valid(hinge) or hinge.has_node("GateLeafCollision"): continue
		var body := StaticBody3D.new()
		body.name = "GateLeafCollision"
		body.collision_layer = 1
		body.collision_mask = 2
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var timber: bool = get_parent().get_meta("gate_timber",false)
		box.size = Vector3(1,1.12 if timber else 1.60,.10)
		shape.shape = box
		shape.position = Vector3(.5 if hinge == left else -.5,.64 if timber else .94,0)
		body.add_child(shape)
		hinge.add_child(body)
		count += 1
	return count
