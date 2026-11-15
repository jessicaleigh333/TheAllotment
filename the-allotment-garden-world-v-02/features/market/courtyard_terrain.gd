extends RefCounted
## Existing circle/approach/grass surfaces, in the courtyard's local coordinates.
var target: Node3D
const RADIUS := 31.5

func _init(courtyard: Node3D) -> void:
	target = courtyard

func _polar(radius: float, angle: float) -> Vector2:
	return Vector2(sin(angle),cos(angle))*radius

func sample_height(point: Vector2) -> float:
	var radius := point.length()
	if radius > RADIUS: return NAN
	# The nine four-metre stone links have a top surface at 0.14 metres.
	for i in range(9):
		var local := point.rotated(float(i)*TAU/9)
		if absf(local.x) <= 2.0 and local.y >= 25.575 and local.y <= 32.125: return .14
	if radius <= 25.98:
		for ring in [8.0,17.0,25.7]:
			if absf(radius-ring) < (.24 if ring > 25 else .085): return .1525
		return .125
	return -.105

func fits(point: Vector2, footprint: float) -> bool:
	var radius := point.length()
	if radius-footprint < 3.8 or radius+footprint > RADIUS: return false
	# Preserve a continuous walking loop and nine routes to the entrances.
	if absf(radius-17.0) < .65+footprint: return false
	for i in range(9):
		var angle := float(i)*TAU/9
		var nearest := Geometry2D.get_closest_point_to_segment(point,_polar(3.8,angle),_polar(RADIUS,angle))
		if point.distance_to(nearest) < .65+footprint: return false
		var planter := _polar(22.0,angle+PI/9)
		if point.distance_to(planter) < 1.0+footprint: return false
	return true

func contains(point: Vector2) -> bool:
	return fits(point,0)

func pick(camera: Camera3D, screen_point: Vector2) -> Variant:
	var inverse := target.global_transform.affine_inverse()
	var origin: Vector3 = inverse*camera.project_ray_origin(screen_point)
	var direction: Vector3 = inverse.basis*camera.project_ray_normal(screen_point)
	if absf(direction.y) < .00001: return null
	var nearest: Variant = null
	var distance := INF
	for height in [.125,.14,.1525,-.105]:
		var along: float = (height-origin.y)/direction.y
		if along <= 0 or along >= distance: continue
		var position := origin+direction*along
		var point := Vector2(position.x,position.z)
		var actual := sample_height(point)
		if is_finite(actual) and absf(actual-height) < .002:
			nearest = point
			distance = along
	return nearest
