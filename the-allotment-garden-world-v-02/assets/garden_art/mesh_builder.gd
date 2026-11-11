extends RefCounted
## Indexed, UV-mapped, vertex-colored surfaces batched by material role.
var surfaces := {}
var detail := 0
static var materials := {}
static var night_amount := 0.0

func _init(level: int = 0) -> void:
	detail = level

static func set_reduced_motion(reduced: bool) -> void:
	for value in materials.values():
		if value is ShaderMaterial: value.set_shader_parameter("motion",0.0 if reduced else 1.0)

static func set_night(value: float) -> void:
	night_amount = clampf(value,0,1)
	if materials.has(13): materials[13].set_shader_parameter("night_amount",night_amount)

static func material(role: int) -> Material:
	if materials.has(role): return materials[role]
	if role == 10:
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(.75,.88,.82,.18)
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.roughness = .13
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		materials[role] = glass
		return glass
	var result := ShaderMaterial.new()
	result.shader = preload("res://assets/garden_art/garden_surface.gdshader")
	result.set_shader_parameter("kind",role)
	result.set_shader_parameter("night_amount",night_amount)
	var settings := ConfigFile.new()
	settings.load("user://title_settings.cfg")
	result.set_shader_parameter("motion",0.0 if settings.get_value("title","reduced_motion",false) else 1.0)
	result.set_shader_parameter("roughness_value",.28 if role == 12 else (.38 if role in [5,8] else .83))
	result.set_shader_parameter("metallic_value",.72 if role == 5 else 0.0)
	materials[role] = result
	return result

func grid(points: PackedVector3Array, rows: int, columns: int, role: int, color: Color, flex: float = 0.0) -> void:
	if not surfaces.has(role):
		surfaces[role] = {"v":PackedVector3Array(),"n":PackedVector3Array(),"uv":PackedVector2Array(),"c":PackedColorArray(),"i":PackedInt32Array()}
	var data: Dictionary = surfaces[role]
	var offset: int = data.v.size()
	for row in range(rows):
		for column in range(columns):
			var index := row*columns+column
			var across := points[row*columns+mini(column+1,columns-1)]-points[row*columns+maxi(column-1,0)]
			var along := points[mini(row+1,rows-1)*columns+column]-points[maxi(row-1,0)*columns+column]
			var normal := across.cross(along).normalized()
			if normal.length_squared() < .1: normal = Vector3.UP
			data.v.append(points[index])
			data.n.append(normal)
			data.uv.append(Vector2(float(column)/maxi(1,columns-1),float(row)/maxi(1,rows-1)))
			data.c.append(Color(color.r,color.g,color.b,flex*float(row)/maxi(1,rows-1)))
	for row in range(rows-1):
		for column in range(columns-1):
			var a := offset+row*columns+column
			for index in [a,a+columns,a+1,a+1,a+columns,a+columns+1]: data.i.append(index)

func tube(path: PackedVector3Array, radii: PackedFloat32Array, role: int, color: Color, sides: int = 8) -> void:
	sides = maxi(4,sides-detail*2)
	var points := PackedVector3Array()
	for row in range(path.size()):
		var tangent := (path[mini(row+1,path.size()-1)]-path[maxi(row-1,0)]).normalized()
		var normal := tangent.cross(Vector3.UP).normalized()
		if normal.length_squared() < .1: normal = Vector3.RIGHT
		var other := tangent.cross(normal).normalized()
		for column in range(sides+1):
			var angle := float(column)*TAU/sides
			points.append(path[row]+(normal*cos(angle)+other*sin(angle))*radii[row])
	grid(points,path.size(),sides+1,role,color)

func beam(a: Vector3, b: Vector3, radius: float, role: int, color: Color, sides: int = 8) -> void:
	tube(PackedVector3Array([a,b]),PackedFloat32Array([radius,radius]),role,color,sides)

func lathe(profile: PackedVector2Array, center: Vector3, role: int, color: Color, segments: int = 24, stretch: Vector2 = Vector2.ONE) -> void:
	segments = maxi(8,segments/(detail+1))
	var points := PackedVector3Array()
	for point in profile:
		for i in range(segments+1):
			var angle := float(i)*TAU/segments
			points.append(center+Vector3(cos(angle)*point.x*stretch.x,point.y,sin(angle)*point.x*stretch.y))
	var first_vertex: int = surfaces[role].v.size() if surfaces.has(role) else 0
	var first_index: int = surfaces[role].i.size() if surfaces.has(role) else 0
	grid(points,profile.size(),segments+1,role,color)
	_flip_surface(role,first_vertex,first_index)

func leaf(origin: Vector3, direction: Vector3, length: float, width: float, color: Color, shape: int = 0) -> void:
	var forward := direction.normalized()
	var side := forward.cross(Vector3.UP).normalized()
	if side.length_squared() < .1: side = Vector3.RIGHT
	var normal := side.cross(forward).normalized()
	var rows := 7 if detail == 0 else (4 if detail == 1 else 3)
	var columns := 5 if detail == 0 else 3
	var points := PackedVector3Array()
	for row in range(rows):
		var t := float(row)/(rows-1)
		var silhouette := pow(maxf(.01,sin(PI*t)),.72)
		if shape == 1: silhouette *= .72+.28*cos(t*PI*7)
		if shape == 2: silhouette = pow(maxf(.01,sin(PI*t)),.4)
		for column in range(columns):
			var u := float(column)/(columns-1)*2-1
			var fold := (1.0-absf(u))*.10*sin(PI*t)+t*t*.16
			points.append(origin+forward*(length*t)+side*(u*width*.5*silhouette)+normal*(length*fold))
	grid(points,rows,columns,1,color,1)

func petal(center: Vector3, right: Vector3, forward: Vector3, length: float, width: float, curl: float, color: Color, role: int = 2) -> void:
	var normal := right.cross(forward).normalized()
	var rows := 5 if detail == 0 else (4 if detail == 1 else 3)
	var columns := 3
	var points := PackedVector3Array()
	for row in range(rows):
		var t := float(row)/(rows-1)
		for column in range(columns):
			var u := float(column)/(columns-1)*2-1
			var breadth := pow(maxf(.005,sin(PI*t)),.55)
			points.append(center+forward*(length*t)+right*(u*width*.5*breadth)+normal*(length*(curl*t*t+.08*u*u*sin(PI*t))))
	grid(points,rows,columns,role,color,.6)

func box(center: Vector3, size: Vector3, bevel: float, role: int, color: Color) -> void:
	# Chamfered cross section sweeps along Y. The end faces are capped.
	var x := size.x*.5
	var z := size.z*.5
	var b := minf(bevel,minf(x,z)*.4)
	var section := PackedVector2Array([Vector2(-x+b,-z),Vector2(x-b,-z),Vector2(x,-z+b),Vector2(x,z-b),Vector2(x-b,z),Vector2(-x+b,z),Vector2(-x,z-b),Vector2(-x,-z+b),Vector2(-x+b,-z)])
	var points := PackedVector3Array()
	for row in range(4):
		var y: float = [-size.y*.5,-size.y*.5+b,size.y*.5-b,size.y*.5][row]
		var taper := .96 if row in [0,3] else 1.0
		for p in section: points.append(center+Vector3(p.x*taper,y,p.y*taper))
	var first_vertex: int = surfaces[role].v.size() if surfaces.has(role) else 0
	var first_index: int = surfaces[role].i.size() if surfaces.has(role) else 0
	grid(points,4,section.size(),role,color)
	_flip_surface(role,first_vertex,first_index)
	for sign_y in [-1.0,1.0]:
		var cap := PackedVector3Array()
		for p in section:
			cap.append(center+Vector3(0,sign_y*size.y*.5,0))
			cap.append(center+Vector3(p.x*.96,sign_y*size.y*.5,p.y*.96))
		var first_normal: int = surfaces[role].n.size()
		var cap_first_index: int = surfaces[role].i.size()
		grid(cap,section.size(),2,role,color)
		for index in range(first_normal,surfaces[role].n.size()):
			surfaces[role].n[index] = Vector3.UP*sign_y
		if sign_y > 0:
			for index in range(cap_first_index,surfaces[role].i.size(),3):
				var previous: int = surfaces[role].i[index+1]
				surfaces[role].i[index+1] = surfaces[role].i[index+2]
				surfaces[role].i[index+2] = previous

func _flip_surface(role: int, first_vertex: int, first_index: int) -> void:
	for index in range(first_vertex,surfaces[role].n.size()): surfaces[role].n[index] *= -1
	for index in range(first_index,surfaces[role].i.size(),3):
		var previous: int = surfaces[role].i[index+1]
		surfaces[role].i[index+1] = surfaces[role].i[index+2]
		surfaces[role].i[index+2] = previous

func mesh() -> ArrayMesh:
	var result := ArrayMesh.new()
	for role in surfaces:
		var data: Dictionary = surfaces[role]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = data.v
		arrays[Mesh.ARRAY_NORMAL] = data.n
		arrays[Mesh.ARRAY_TEX_UV] = data.uv
		arrays[Mesh.ARRAY_COLOR] = data.c
		arrays[Mesh.ARRAY_INDEX] = data.i
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		result.surface_set_material(result.get_surface_count()-1,material(role))
	return result


func merge(other: RefCounted, transform: Transform3D) -> void:
	var normals := transform.basis.inverse().transposed()
	for role in other.surfaces:
		if not surfaces.has(role):
			surfaces[role] = {"v":PackedVector3Array(),"n":PackedVector3Array(),"uv":PackedVector2Array(),"c":PackedColorArray(),"i":PackedInt32Array()}
		var source: Dictionary = other.surfaces[role]
		var target: Dictionary = surfaces[role]
		var offset: int = target.v.size()
		for v in source.v: target.v.append(transform*v)
		for n in source.n: target.n.append((normals*n).normalized())
		target.uv.append_array(source.uv)
		target.c.append_array(source.c)
		for index in source.i: target.i.append(index+offset)
