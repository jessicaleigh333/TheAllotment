@tool
extends StaticBody3D
## Origin: grass height at the sidewalk edge. Low end is +Z, high end is -Z.
@export_range(0.01, 1.0) var rise: float = 0.2:
	set(value):
		rise = value
		_rebuild()
@export_range(0.2, 5.0) var run: float = 0.8:
	set(value):
		run = value
		_rebuild()
@export_range(0.2, 10.0) var width: float = 2.0:
	set(value):
		width = value
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		add_child(collision)
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(-width / 2, -0.05, -0.05), Vector3(width / 2, -0.05, -0.05),
		Vector3(-width / 2, rise, -0.05), Vector3(width / 2, rise, -0.05),
		Vector3(-width / 2, -0.05, run), Vector3(width / 2, -0.05, run),
		Vector3(-width / 2, 0, run), Vector3(width / 2, 0, run),
	])
	collision.shape = shape
