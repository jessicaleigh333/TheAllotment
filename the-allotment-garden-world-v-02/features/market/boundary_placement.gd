extends RefCounted
## Socket alignment and oriented footprint checks for modular borders.
const IDS := ["garden_gate","timber_gate","rock_wall","rock_wall_corner","rock_wall_end"]

static func sockets(id: String) -> Array:
	match id:
		"rock_wall": return [Vector2(-1,0),Vector2(1,0)]
		"rock_wall_corner": return [Vector2(1,-.775),Vector2(-.775,1)]
		"rock_wall_end": return [Vector2(-.3,0),Vector2(.3,0),Vector2(0,-.3),Vector2(0,.3)]
		"garden_gate": return [Vector2(-1.5,0),Vector2(1.5,0)]
		"timber_gate": return [Vector2(-1.2,0),Vector2(1.2,0)]
	return []

static func snap(id: String, point: Vector2, angle: float, placed: Array, area: String) -> Vector2:
	var result := point
	var nearest := .55
	for record in placed:
		if record.get("area","garden") != area or record.id not in IDS: continue
		for target in sockets(record.id):
			var anchor: Vector2 = Vector2(record.x,record.z)+target.rotated(-float(record.angle))
			for source in sockets(id):
				var candidate: Vector2 = anchor-source.rotated(-angle)
				var distance := point.distance_to(candidate)
				if distance < nearest:
					nearest = distance
					result = candidate
	return result

static func boxes(id: String) -> Array:
	match id:
		"rock_wall": return [[Vector2.ZERO,Vector2(2,.45)]]
		"rock_wall_corner": return [[Vector2(0,-.775),Vector2(2,.45)],[Vector2(-.775,0),Vector2(.45,2)]]
		"rock_wall_end": return [[Vector2.ZERO,Vector2(.6,.6)]]
		# Reserve the full gate opening and leaf swing; other borders cannot fill it.
		"garden_gate": return [[Vector2.ZERO,Vector2(3,2.2)]]
		"timber_gate": return [[Vector2.ZERO,Vector2(2.4,2.2)]]
	return []

static func overlap(a_id: String, a: Vector2, angle_a: float, b_id: String, b: Vector2, angle_b: float) -> bool:
	for box_a in boxes(a_id):
		for box_b in boxes(b_id):
			var center_a: Vector2 = a+box_a[0].rotated(-angle_a)
			var center_b: Vector2 = b+box_b[0].rotated(-angle_b)
			var axes_a := [Vector2.RIGHT.rotated(-angle_a),Vector2.DOWN.rotated(-angle_a)]
			var axes_b := [Vector2.RIGHT.rotated(-angle_b),Vector2.DOWN.rotated(-angle_b)]
			var separated := false
			for axis in axes_a+axes_b:
				var radius_a: float = absf(axis.dot(axes_a[0]))*box_a[1].x*.5+absf(axis.dot(axes_a[1]))*box_a[1].y*.5
				var radius_b: float = absf(axis.dot(axes_b[0]))*box_b[1].x*.5+absf(axis.dot(axes_b[1]))*box_b[1].y*.5
				if absf((center_b-center_a).dot(axis)) >= radius_a+radius_b-.025:
					separated = true
					break
			if not separated: return true
	return false
