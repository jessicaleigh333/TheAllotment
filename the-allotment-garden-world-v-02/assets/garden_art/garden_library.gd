extends RefCounted
const French := preload("res://assets/garden_art/french_collection.gd")
const Boundary := preload("res://assets/garden_art/garden_boundary.gd")
const Builder := preload("res://assets/garden_art/mesh_builder.gd")
const GREEN := Color("547b45")
const WOOD := Color("9a744e")
const STONE := Color("c2b394")
const BRONZE := Color("8f713f")
const SIZES := {"bench":Vector3(1.8,.9,.65),"rose_arch":Vector3(2.4,2.5,.7),"fountain":Vector3(2.2,2,2.2),"lantern":Vector3(.22,.45,.22),"trellis":Vector3(1.6,2,.25),"planter":Vector3(.55,.75,.55),"watering_can":Vector3(.65,.4,.28),"straw_hat":Vector3(.42,.16,.42)}
static var cache := {}

static func meshes(id: String, stage: int = 4, tint: Color = Color.WHITE) -> Array[ArrayMesh]:
	var key := "%s:%d:%s" % [id,stage,tint.to_html()]
	if cache.has(key): return cache[key]
	var result: Array[ArrayMesh] = []
	for lod in range(3):
		var builder := Builder.new(lod)
		if id in ["sunflower","rose","lavender","hydrangea","cosmos","daisy","basil"]:
			_plant(builder,id,stage,tint)
		else:
			_object(builder,id,tint)
		result.append(builder.mesh())
	cache[key] = result
	return result

static func attach(root: Node3D, id: String, stage: int = 4, tint: Color = Color.WHITE) -> void:
	var resources := meshes(id,stage,tint)
	var reference: AABB = resources[0].get_aabb()
	for lod in range(3):
		var node := MeshInstance3D.new()
		node.name = ["NearDetail","MidDetail","FarDetail"][lod]
		node.mesh = resources[lod]
		var bounds: AABB = resources[lod].get_aabb()
		if minf(bounds.size.x,minf(bounds.size.y,bounds.size.z)) > .0001:
			node.scale = reference.size/bounds.size
			node.position = reference.position-bounds.position*node.scale
		node.visibility_range_begin = [0,18,45][lod]
		node.visibility_range_end = [18,45,0][lod]
		root.add_child(node)
	root.set_meta("garden_asset",id)
	if id in ["garden_gate","timber_gate"] or French.GATES.has(id):
		var gate_type: String = French.GATES.get(id,id)
		root.set_meta("gate_timber",gate_type == "timber_gate")
		for side in [-1,1]:
			var hinge := Node3D.new()
			hinge.name = "LeftHinge" if side == -1 else "RightHinge"
			hinge.position.x = side*(1.05 if gate_type == "garden_gate" else 1.0)
			root.add_child(hinge)
			attach(hinge,{"chateau_gate":"chateau_gate_leaf","potager_gate":"potager_gate_leaf"}.get(id,"iron_gate_leaf" if gate_type == "garden_gate" else "timber_gate_leaf"))
			if side == 1:
				for mesh in hinge.get_children():
					if mesh is MeshInstance3D: mesh.scale.x *= -1
		var controller := preload("res://assets/garden_art/gate_controller.gd").new()
		controller.name = "GateController"
		root.add_child(controller)
	if id in ["vine_pergola","iron_pavilion","espalier_screen","wall_fountain","stone_alcove"]:
		var dimensions: Vector3 = French.SIZES[id]
		root.set_meta("asset_footprint",Vector2(dimensions.x,dimensions.z))
	if id in ["shed","greenhouse","stall","bed"]:
		root.set_meta("asset_footprint",{"shed":Vector2(3.8,4.5),"greenhouse":Vector2(3.8,4.5),"stall":Vector2(3.4,2.1),"bed":Vector2(3.2,3.5)}[id])

static func instance(id: String, tint: Color = Color.WHITE) -> Node3D:
	var root := Node3D.new()
	root.name = id.to_pascal_case()
	attach(root,id,4,tint)
	return root

static func _count(high: int, b: RefCounted) -> int:
	return maxi(2,int(float(high)*[1.0,.55,.22][b.detail]))

static func _path(b: RefCounted, a: Vector3, end: Vector3, radius: float, color: Color = GREEN) -> void:
	var mid := (a+end)*.5+Vector3(.025,0,.018)
	b.tube(PackedVector3Array([a,mid,end]),PackedFloat32Array([radius,radius*.82,radius*.45]),0,color,8)

static func _leaves(b: RefCounted, origin: Vector3, height: float, width: float, count: int, shape: int = 0) -> void:
	for i in range(_count(count,b)):
		var t := float(i)/maxi(1,_count(count,b)-1)
		var a := float(i)*2.39996
		var start := origin+Vector3(0,height*(.15+t*.66),0)
		var direction := Vector3(cos(a),.22+sin(float(i))*.18,sin(a))
		b.leaf(start,direction,width*(.75+.25*sin(float(i)*1.7)),width*.52,GREEN.lightened(float(i%4)*.035),shape)

static func _disk(b: RefCounted, center: Vector3, normal: Vector3, radius: float, color: Color, depth: float = .025) -> void:
	var right := normal.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < .1: right = Vector3.RIGHT
	var forward := right.cross(normal).normalized()
	var points := PackedVector3Array()
	var segments := 8 if radius < .03 else (24 if b.detail == 0 else 12)
	var rows := 3 if radius < .03 else 5
	for row in range(rows):
		var r := float(row)/(rows-1)*radius
		for i in range(segments+1):
			var a := float(i)*TAU/segments
			points.append(center+(right*cos(a)+forward*sin(a))*r+normal*(depth*(1-pow(r/radius,2))))
	b.grid(points,rows,segments+1,2,color)

static func _flower(b: RefCounted, center: Vector3, normal: Vector3, radius: float, petals: int, color: Color, seed_color: Color = Color("d3a447")) -> void:
	var right := normal.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < .1: right = Vector3.RIGHT
	var forward := right.cross(normal).normalized()
	for ring in range(2 if petals > 12 else 1):
		for i in range(petals):
			var a := (float(i)+ring*.4)*TAU/petals
			var dir := right*cos(a)+forward*sin(a)
			b.petal(center+dir*radius*.23,dir.cross(normal),dir,radius*(.82-ring*.12),radius*(.36 if petals > 12 else .65),.16-ring*.1,color.lightened(.035*float(i%3)))
	_disk(b,center+normal*.012,normal,radius*.31,seed_color,radius*.10)
	if radius < .085: return
	for i in range(_count(35 if petals > 12 else 12,b)):
		var a := float(i)*2.4
		var r := radius*.29*sqrt(float(i)/maxi(1,_count(35 if petals > 12 else 12,b)))
		var p := center+(right*cos(a)+forward*sin(a))*r+normal*(radius*.12)
		b.beam(p,p+normal*radius*.035,radius*.018,2,seed_color.lightened(.18),5)

static func _rose(b: RefCounted, center: Vector3, radius: float, color: Color) -> void:
	for ring in range(3):
		for i in range(7):
			var a := (float(i)+ring*.37)*TAU/7
			var dir := Vector3(cos(a),0,sin(a))
			var base := center+dir*radius*(.05+ring*.14)+Vector3(0,(2-ring)*radius*.10,0)
			b.petal(base,Vector3(-sin(a),0,cos(a)),dir,radius*(.40+ring*.19),radius*(.7+ring*.07),.60-ring*.12,color.lightened(float((i+ring)%3)*.04))
	var curl := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in range(12):
		var a := float(i)*.6
		var r := radius*(.02+float(i)*.008)
		curl.append(center+Vector3(cos(a)*r,radius*.26,sin(a)*r))
		radii.append(radius*.035)
	b.tube(curl,radii,2,color.darkened(.08),5)

static func _plant(b: RefCounted, id: String, stage: int, tint: Color) -> void:
	if stage == 0:
		b.lathe(PackedVector2Array([Vector2(0,0),Vector2(.05,0),Vector2(.05,.006),Vector2(0,.012)]),Vector3.ZERO,4,Color("69513c"),16)
		return
	if stage < 4:
		var stems := 1 if stage < 3 else 4
		for branch in range(stems):
			var p := Vector3(cos(branch*2.4)*branch*.018,0,sin(branch*2.4)*branch*.018)
			var h := .20 if stage == 1 else (.35 if stage == 2 else .8-float(branch)*.08)
			_path(b,p,p+Vector3(.025,h,.015),.008)
			_leaves(b,p,h,.11 if stage < 3 else .22,2 if stage == 1 else 6,1 if id == "rose" else 0)
			if stage == 3 and id != "basil":
				b.lathe(PackedVector2Array([Vector2(0,0),Vector2(.025,.01),Vector2(.035,.05),Vector2(.012,.09),Vector2(0,.10)]),p+Vector3(.025,h,.015),1,GREEN,10)
		return
	match id:
		"sunflower":
			_path(b,Vector3.ZERO,Vector3(.035,1.55,.02),.022)
			_leaves(b,Vector3.ZERO,1.45,.29,10,1)
			_flower(b,Vector3(.035,1.55,.02),Vector3(0,.22,1).normalized(),.30,18,Color("edbe42")*tint,Color("665035"))
		"cosmos", "daisy":
			for i in range(5):
				var a := float(i)*2.4
				var p := Vector3(cos(a)*.18,0,sin(a)*.18)
				var head := p+Vector3(cos(a)*.07,.65+float(i%3)*.12,sin(a)*.07)
				_path(b,p,head,.009)
				_leaves(b,p,head.y,.12,5,1 if id == "daisy" else 0)
				if id == "cosmos":
					for j in range(_count(8,b)):
						var origin := p+Vector3(0,.1+j*.055,0)
						b.leaf(origin,Vector3(cos(j*2.4),.1,sin(j*2.4)),.15,.015,GREEN)
				_flower(b,head,Vector3(0,1,.25).normalized(),.14,8 if id == "cosmos" else 15,(Color("d994ad") if id == "cosmos" else Color("f6efd9"))*tint)
		"rose", "hydrangea":
			for branch in range(6):
				var a := float(branch)*2.4
				var head := Vector3(cos(a)*.28,.55+float(branch%3)*.16,sin(a)*.28)
				_path(b,Vector3.ZERO,head,.017,Color("607649"))
				for j in range(_count(5,b)):
					var t := .2+float(j)*.12
					var origin := head*t
					var direction := Vector3(cos(a+j*2),.18,sin(a+j*2))
					b.leaf(origin,direction,.25 if id == "hydrangea" else .18,.18 if id == "hydrangea" else .10,GREEN.lightened(float(j%3)*.04),1)
				if id == "rose": _rose(b,head,.14,Color("db9aa9")*tint)
				elif branch % 2 == 0:
					for j in range(_count(24,b)):
						var angle := float(j)*2.4
						var y := 1.0-2.0*(float(j)+.5)/_count(24,b)
						var direction := Vector3(sqrt(1-y*y)*cos(angle),y,sqrt(1-y*y)*sin(angle))
						_flower(b,head+direction*.18,direction,.065,4,(Color("a49acb") if j%2 == 0 else Color("88a5ce"))*tint)
		"lavender":
			for i in range(_count(15,b)):
				var a := float(i)*2.4
				var p := Vector3(cos(a)*.18,0,sin(a)*.18)
				var height := .45+float(i%4)*.045
				_path(b,p,p+Vector3(cos(a)*.06,height,sin(a)*.06),.006)
				for j in range(4):
					b.leaf(p+Vector3(0,.10+j*.055,0),Vector3(cos(a+j*2),.2,sin(a+j*2)),.15,.025,Color("7e956c"))
				for j in range(6):
					var c := p+Vector3(cos(a)*.06,height+j*.025,sin(a)*.06)
					_flower(b,c,Vector3.UP,.027,4,Color("9983bb")*tint,Color("a28bc4"))
		"basil":
			for branch in range(5):
				var a := float(branch)*2.4
				var p := Vector3(cos(a)*.05,0,sin(a)*.05)
				var height := .44-float(branch)*.035
				_path(b,p,p+Vector3(0,height,0),.009)
				_leaves(b,p,height,.17,8,2)

static func _object(b: RefCounted, id: String, tint: Color) -> void:
	if French.SIZES.has(id) or id in ["chateau_gate_leaf","potager_gate_leaf"]:
		French.build(b,id)
		return
	if id in Boundary.IDS or id in ["iron_gate_leaf","timber_gate_leaf"]:
		Boundary.build(b,id)
		return
	match id:
		"bench": _bench(b)
		"rose_arch", "trellis": _trellis(b,id == "rose_arch",tint)
		"fountain": _fountain(b)
		"planter", "central_planter": _planter(b,id == "central_planter",tint)
		"lantern": _lantern(b)
		"watering_can": _watering_can(b)
		"straw_hat": _hat(b)
		"tree", "cypress", "hedge", "shrub": _foliage(b,id)
		"shed", "greenhouse", "stall": _building(b,id,tint)
		"bed": _bed(b)
		_: b.box(Vector3(0,.175,0),Vector3(.3,.35,1),.025,4,STONE)

static func _ring(b: RefCounted, center: Vector3, radius: float, thickness: float, role: int, color: Color, vertical: bool = false) -> void:
	var path := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in range(33):
		var a := float(i)*TAU/32
		path.append(center+(Vector3(cos(a),sin(a),0) if vertical else Vector3(cos(a),0,sin(a)))*radius)
		radii.append(thickness)
	b.tube(path,radii,role,color,6)

static func _bench(b: RefCounted) -> void:
	for x in [-.78,.78]:
		for z in [-.22,.22]:
			b.lathe(PackedVector2Array([Vector2(.035,0),Vector2(.048,.04),Vector2(.03,.12),Vector2(.024,.3),Vector2(.04,.43),Vector2(.035,.48)]),Vector3(x,0,z),5,BRONZE,12)
		var curve := PackedVector3Array()
		var radii := PackedFloat32Array()
		for i in range(20):
			var a := float(i)/19*TAU*1.2
			var r := .18*(1-float(i)/24)
			curve.append(Vector3(x,.52+sin(a)*r,-.04+cos(a)*r))
			radii.append(.018)
		b.tube(curve,radii,5,BRONZE,8)
	for z in [-.21,-.07,.07,.21]: b.box(Vector3(0,.46,z),Vector3(1.8,.065,.12),.015,3,WOOD)
	for y in [.61,.74,.87]: b.box(Vector3(0,y,-.27-(y-.6)*.15),Vector3(1.73,.095,.045),.012,3,WOOD.lightened(.04))
	for x in [-.8,.8]:
		b.beam(Vector3(x,.42,-.25),Vector3(x,.93,-.33),.023,5,BRONZE)
		for y in [.61,.74,.87]: _disk(b,Vector3(x,y,-.24-(y-.6)*.15),Vector3.FORWARD,.012,BRONZE,.006)
	for x in [-.81,.81]: b.box(Vector3(x,.63,0),Vector3(.085,.045,.48),.018,3,WOOD)

static func _trellis(b: RefCounted, arch: bool, tint: Color) -> void:
	var half := 1.1 if arch else .75
	var height := 1.35 if arch else 2.0
	for x in [-half,half]:
		b.lathe(PackedVector2Array([Vector2(.08,0),Vector2(.08,.10),Vector2(.05,.14),Vector2(.045,height),Vector2(.065,height+.03),Vector2(.045,height+.07)]),Vector3(x,0,0),3,WOOD,12)
		if arch:
			b.beam(Vector3(x,0,-.3),Vector3(x,height,-.3),.04,3,WOOD)
			b.beam(Vector3(x,0,.3),Vector3(x,height,.3),.04,3,WOOD)
			for j in range(6): b.beam(Vector3(x,.15+j*.22,-.3),Vector3(x,.15+j*.22,.3),.018,3,WOOD)
	if arch:
		for depth in [-.3,.3]:
			var path := PackedVector3Array()
			var radii := PackedFloat32Array()
			for i in range(25):
				var a := float(i)*PI/24
				path.append(Vector3(cos(a)*half,height+sin(a)*half,depth))
				radii.append(.045)
			b.tube(path,radii,3,WOOD,10)
		for i in range(9):
			var a := float(i)*PI/8
			b.beam(Vector3(cos(a)*half,height+sin(a)*half,-.32),Vector3(cos(a)*half,height+sin(a)*half,.32),.018,3,WOOD)
	else:
		for i in range(9):
			var start := Vector3(-half,.15+i*.2,0)
			var end := Vector3(half,clampf(start.y+.7,.15,2),0)
			b.beam(start,end,.015,3,WOOD)
			b.beam(Vector3(half,start.y,.025),Vector3(-half,end.y,.025),.015,3,WOOD)
	for i in range(_count(24,b)):
		var t := float(i)/maxi(1,_count(24,b)-1)
		var p: Vector3
		if arch:
			var a := t*PI
			p = Vector3(cos(a)*half,height+sin(a)*half,.32)
		else: p = Vector3(sin(t*10)*.52,.2+t*1.65,.08)
		b.leaf(p,Vector3(cos(i*2.4),.25,sin(i*2.4)),.18,.09,GREEN,1)
		if i%2 == 0: _rose(b,p+Vector3(0,.025,.04),.10,Color("dca1ad")*tint)

static func _fountain(b: RefCounted) -> void:
	b.lathe(PackedVector2Array([Vector2(0,0),Vector2(.9,0),Vector2(.96,.04),Vector2(.96,.1),Vector2(.85,.14),Vector2(.85,.2)]),Vector3.ZERO,4,STONE,40)
	for tier in range(3):
		var radius: float = [1.1,.65,.32][tier]
		var y: float = [.2,1.08,1.70][tier]
		b.lathe(PackedVector2Array([Vector2(.10,0),Vector2(radius*.45,.04),Vector2(radius*.85,.12),Vector2(radius,.22),Vector2(radius,.28),Vector2(radius*.93,.29),Vector2(radius*.84,.20),Vector2(.10,.16)]),Vector3(0,y,0),4,STONE,40)
		_ring(b,Vector3(0,y+.26,0),radius,.018,4,STONE.lightened(.08))
		b.lathe(PackedVector2Array([Vector2(0,.225),Vector2(radius*.87,.225)]),Vector3(0,y,0),9,Color("4d9f9f"),32)
		if tier < 2:
			var end_y: float = [1.13,1.74][tier]
			b.lathe(PackedVector2Array([Vector2(.18,0),Vector2(.23,.035),Vector2(.15,.09),Vector2(.11,end_y-y-.27),Vector2(.18,end_y-y-.22)]),Vector3(0,y+.25,0),4,STONE,24)
		if tier > 0:
			for i in range(_count(12,b)):
				var a := float(i)*TAU/_count(12,b)
				var start := Vector3(cos(a)*radius*.94,y+.24,sin(a)*radius*.94)
				var end := Vector3(cos(a)*radius*1.35,y-.55,sin(a)*radius*1.35)
				b.tube(PackedVector3Array([start,start+Vector3(cos(a)*.10,-.12,sin(a)*.10),end]),PackedFloat32Array([.009,.006,.003]),9,Color("90c9c2"),5)
	b.lathe(PackedVector2Array([Vector2(.1,0),Vector2(.13,.06),Vector2(.08,.14),Vector2(0,.20)]),Vector3(0,1.88,0),4,STONE,20)
	for i in range(_count(16,b)):
		var a := float(i)*TAU/_count(16,b)
		var p := Vector3(cos(a)*1.04,.4,sin(a)*1.04)
		_disk(b,p,Vector3(cos(a),0,sin(a)),.04,STONE.darkened(.08),.012)

static func _planter(b: RefCounted, large: bool, tint: Color) -> void:
	var radius := 3.2 if large else .28
	var height := .65 if large else .43
	var color := STONE if large else Color("b77e59")
	b.lathe(PackedVector2Array([Vector2(radius*.55,0),Vector2(radius*.62,.04),Vector2(radius*.65,height*.12),Vector2(radius*.87,height*.85),Vector2(radius,height*.9),Vector2(radius,height),Vector2(radius*.87,height),Vector2(radius*.82,height*.9),Vector2(radius*.75,height*.18)]),Vector3.ZERO,4,color,40 if large else 24)
	_ring(b,Vector3(0,height*.92,0),radius,.035 if large else .012,4,color.lightened(.07))
	b.lathe(PackedVector2Array([Vector2(0,height*.86),Vector2(radius*.82,height*.86)]),Vector3.ZERO,4,Color("514130"),24)
	for i in range(_count(16 if large else 12,b)):
		var a := float(i)*TAU/_count(16 if large else 12,b)
		var p := Vector3(cos(a)*radius*.78,height*.6,sin(a)*radius*.78)
		_disk(b,p,Vector3(cos(a),0,sin(a)),.05 if large else .018,color.lightened(.06),.012)
	if not large:
		for i in range(6):
			var a := float(i)*2.4
			var p := Vector3(cos(a)*.13,height*.9,sin(a)*.13)
			_path(b,p,p+Vector3(0,.20+float(i%2)*.05,0),.008)
			b.leaf(p,Vector3(cos(a),.6,sin(a)),.18,.1,GREEN)
			_flower(b,p+Vector3(0,.23+float(i%2)*.05,0),Vector3.UP,.10,8,(Color("dc9bad") if i%2 == 0 else Color("f4e6be"))*tint)

static func _lantern(b: RefCounted) -> void:
	b.lathe(PackedVector2Array([Vector2(0,0),Vector2(.11,0),Vector2(.11,.025),Vector2(.085,.045),Vector2(.085,.06)]),Vector3.ZERO,5,BRONZE,16)
	b.lathe(PackedVector2Array([Vector2(.075,.06),Vector2(.075,.29)]),Vector3.ZERO,10,Color.WHITE,8)
	for i in range(4):
		var a := PI/4+float(i)*PI/2
		b.beam(Vector3(cos(a)*.085,.045,sin(a)*.085),Vector3(cos(a)*.085,.30,sin(a)*.085),.009,5,BRONZE,6)
	b.lathe(PackedVector2Array([Vector2(.11,.29),Vector2(.11,.315),Vector2(.08,.33),Vector2(.035,.37),Vector2(.02,.38)]),Vector3.ZERO,5,BRONZE,8)
	_ring(b,Vector3(0,.415,0),.035,.006,5,BRONZE,true)
	b.lathe(PackedVector2Array([Vector2(.026,.065),Vector2(.026,.15),Vector2(.015,.155)]),Vector3.ZERO,4,Color("e5d2a2"),12)
	b.lathe(PackedVector2Array([Vector2(0,0),Vector2(.018,.02),Vector2(.012,.045),Vector2(0,.068)]),Vector3(0,.152,0),8,Color("f9c977"),12)

static func _watering_can(b: RefCounted) -> void:
	var enamel := Color("829d91")
	b.lathe(PackedVector2Array([Vector2(0,0),Vector2(.12,0),Vector2(.14,.02),Vector2(.16,.21),Vector2(.15,.26),Vector2(.135,.27),Vector2(.13,.25)]),Vector3.ZERO,5,enamel,32)
	_ring(b,Vector3(0,.24,0),.15,.009,5,enamel.lightened(.1))
	b.tube(PackedVector3Array([Vector3(.1,.06,0),Vector3(.22,.12,0),Vector3(.31,.26,0),Vector3(.40,.32,0)]),PackedFloat32Array([.045,.033,.025,.022]),5,enamel,12)
	b.tube(PackedVector3Array([Vector3(.40,.32,0),Vector3(.44,.34,0)]),PackedFloat32Array([.025,.065]),5,enamel,16)
	var handle := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in range(20):
		var a := float(i)*PI/19
		handle.append(Vector3(-.1+cos(a)*.10,.25+sin(a)*.15,0))
		radii.append(.012)
	b.tube(handle,radii,5,enamel,8)
	_flower(b,Vector3(0,.13,.151),Vector3.FORWARD,.04,6,Color("e8c2a1"))

static func _hat(b: RefCounted) -> void:
	b.lathe(PackedVector2Array([Vector2(.12,.02),Vector2(.16,.014),Vector2(.21,.025),Vector2(.21,.035),Vector2(.16,.024),Vector2(.125,.03),Vector2(.123,.12),Vector2(.10,.15),Vector2(.055,.16),Vector2(0,.16)]),Vector3.ZERO,7,Color("c8a667"),40,Vector2(1,.9))
	_ring(b,Vector3(0,.03,0),.205,.004,7,Color("e2c38a"))
	b.lathe(PackedVector2Array([Vector2(.125,.035),Vector2(.125,.065)]),Vector3.ZERO,6,Color("ac7988"),32)
	for i in range(5):
		var a := .5+float(i)*.3
		_rose(b,Vector3(cos(a)*.125,.067,sin(a)*.125),.022,Color("dc9faa"))

static func _foliage(b: RefCounted, id: String) -> void:
	var tree := id in ["tree","cypress"]
	if tree:
		_path(b,Vector3.ZERO,Vector3(.08,3.5,0),.16,Color("725438"))
		for i in range(7):
			var a := float(i)*2.4
			_path(b,Vector3(.02,1.5+float(i)*.2,0),Vector3(cos(a)*.9,2.6+float(i%3)*.35,sin(a)*.9),.07,Color("725438"))
	var clusters: Array = []
	if id == "tree": clusters = [[Vector3(-.65,3.2,0),Vector3(1.1,1.05,1.05)],[Vector3(.65,3.3,.1),Vector3(1.05,1.15,1.0)],[Vector3(0,3.9,-.15),Vector3(1.0,1.1,1.0)]]
	elif id == "cypress": clusters = [[Vector3(0,3.3,0),Vector3(.64,2.8,.64)]]
	elif id == "hedge": clusters = [[Vector3(0,1,0),Vector3(.64,.9,1.05)]]
	else: clusters = [[Vector3(0,.55,0),Vector3(.65,.55,.65)]]
	for cluster in clusters:
		var center: Vector3 = cluster[0]
		var extent: Vector3 = cluster[1]
		# An irregular inner crown gives foliage a solid silhouette at distance.
		var points := PackedVector3Array()
		var rows := 10
		var columns := 25 if b.detail == 0 else 13
		for row in range(rows):
			var latitude := float(row)*PI/(rows-1)
			for column in range(columns):
				var a := float(column)*TAU/(columns-1)
				var wave := .78+.10*sin(a*5+latitude*3)+.07*cos(a*9-latitude*7)
				var r := sin(latitude)*wave
				points.append(center+Vector3(cos(a)*extent.x*r,cos(latitude)*extent.y*.85,sin(a)*extent.z*r))
		b.grid(points,rows,columns,0,GREEN.darkened(.08))
		var amount := _count(200 if id == "tree" else 280,b)
		for i in range(amount):
			var y := 1.0-2.0*(float(i)+.5)/amount
			var a := float(i)*2.39996
			var direction := Vector3(sqrt(1-y*y)*cos(a),y,sqrt(1-y*y)*sin(a))
			var origin := center+direction*extent*(.81+.10*sin(float(i)*5.7))
			var leaf_size := .55 if tree else .34
			b.leaf(origin,Vector3(direction.z+cos(a*3)*.5,.15+.65*sin(float(i)*4.7),-direction.x+sin(a*3)*.5),leaf_size,leaf_size*.62,GREEN.lightened(float(i%5)*.035),1 if tree else 0)

static func _pane(b: RefCounted, a: Vector3, end: Vector3, depth: Vector3) -> void:
	b.grid(PackedVector3Array([a,end,a+depth,end+depth]),2,2,10,Color.WHITE)

static func _building(b: RefCounted, id: String, tint: Color) -> void:
	if id == "stall":
		for x in [-1.4,1.4]:
			for z in [-.7,.7]:
				b.box(Vector3(x,1.35,z),Vector3(.11,2.7,.11),.015,3,WOOD)
				b.beam(Vector3(x,.2,z),Vector3(x*.6,.85,z),.025,3,WOOD)
		for z in [-.55,-.27,0,.27,.55]: b.box(Vector3(0,.85,z),Vector3(3.1,.1,.24),.015,3,WOOD.lightened(.08))
		for stripe in range(12):
			var x := -1.7+stripe*3.4/12
			var points := PackedVector3Array()
			for row in range(7):
				var t := float(row)/6
				for side in [0.0,1.0]: points.append(Vector3(x+side*3.4/12,2.5+sin(t*PI)*.3,-1.05+t*2.1))
			b.grid(points,7,2,6,(Color("95626b") if stripe%2 == 0 else Color("e6d6b1"))*tint)
			b.grid(PackedVector3Array([Vector3(x,2.5,1.05),Vector3(x+3.4/12,2.5,1.05),Vector3(x,2.31,1.05),Vector3(x+3.4/12,2.35,1.05)]),2,2,6,(Color("95626b") if stripe%2 == 0 else Color("e6d6b1"))*tint)
		for x in [-.9,0,.9]:
			b.lathe(PackedVector2Array([Vector2(.13,0),Vector2(.2,.24),Vector2(.21,.27),Vector2(.17,.28)]),Vector3(x,.9,0),4,Color("b37c56"),16)
			for j in range(5): b.leaf(Vector3(x,1.15,0),Vector3(cos(j*2.4),.6,sin(j*2.4)),.2,.08,GREEN)
		return
	var green := Color("5b786a")
	var w := 1.7
	var d := 2.1
	if id == "shed":
		for x in [-w,w]: b.box(Vector3(x,1.25,0),Vector3(.14,2.5,d*2),.015,3,Color("a28a6b"))
		b.box(Vector3(0,1.25,-d),Vector3(w*2,2.5,.14),.015,3,WOOD)
		for x in [-1.1,1.1]: b.box(Vector3(x,1.25,d),Vector3(1.2,2.5,.13),.02,3,WOOD)
		for i in range(5): b.box(Vector3(-.4+i*.2,1.0,d+.08),Vector3(.18,2.0,.05),.009,3,green)
		for y in [.35,1.7]: b.box(Vector3(-.37,y,d+.14),Vector3(.22,.035,.035),.008,5,BRONZE)
		b.beam(Vector3(.3,1,d+.13),Vector3(.3,1,d+.20),.035,5,BRONZE,10)
		for i in range(15):
			var z := -d+float(i)*d*2/14
			for side in [-1.0,1.0]: b.box(Vector3(side*(w+.075),1.25,z),Vector3(.025,2.4,.025),.004,3,WOOD.darkened(.12))
		_ring(b,Vector3(1.1,1.65,d+.08),.3,.025,3,green,true)
		_disk(b,Vector3(1.1,1.65,d+.09),Vector3.FORWARD,.27,Color("54736b"),0)
		b.beam(Vector3(.85,1.65,d+.1),Vector3(1.35,1.65,d+.1),.012,3,green)
		b.beam(Vector3(1.1,1.4,d+.1),Vector3(1.1,1.9,d+.1),.012,3,green)
	else:
		for x in [-w,w]:
			b.box(Vector3(x,.15,0),Vector3(.16,.3,d*2),.015,4,STONE)
			_pane(b,Vector3(x,.3,-d),Vector3(x,.3,d),Vector3(0,2.1,0))
		for z in [-d,d]:
			if z < 0:
				b.box(Vector3(0,.15,z),Vector3(w*2,.3,.16),.015,4,STONE)
				_pane(b,Vector3(-w,.3,z),Vector3(w,.3,z),Vector3(0,2.1,0))
			else:
				for side in [-1.0,1.0]:
					_pane(b,Vector3(side*.5,.3,z),Vector3(side*w,.3,z),Vector3(0,2.1,0))
		for x in [-w,w]:
			for z in [-d,-1.4,-.7,0,.7,1.4,d]: b.box(Vector3(x,1.35,z),Vector3(.045,2.7,.045),.006,5,green)
		for z in [-d,d]:
			for x in [-w,-.5,.5,w]: b.box(Vector3(x,1.25,z),Vector3(.055,2.5,.055),.008,5,green)
			for y in [.3,1.2,2.4]:
				if z > 0 and y < 2.4:
					for side in [-1.0,1.0]: b.box(Vector3(side*1.1,y,z),Vector3(1.2,.045,.045),.006,5,green)
				else: b.box(Vector3(0,y,z),Vector3(w*2,.045,.045),.006,5,green)
		b.box(Vector3(0,.8,-1.7),Vector3(2.6,.1,.5),.02,3,WOOD)
		for i in range(3):
			b.lathe(PackedVector2Array([Vector2(.1,0),Vector2(.15,.2),Vector2(.15,.22)]),Vector3(-.8+i*.8,.85,-1.7),4,Color("b47e59"),16)
			for j in range(5): b.leaf(Vector3(-.8+i*.8,1.04,-1.7),Vector3(cos(j*2.4),.8,sin(j*2.4)),.2,.08,GREEN)
	var roof_role := 4 if id == "shed" else 10
	for side in [-1.0,1.0]:
		b.grid(PackedVector3Array([Vector3(0,3.3,-d-.15),Vector3(0,3.3,d+.15),Vector3(side*(w+.18),2.4,-d-.15),Vector3(side*(w+.18),2.4,d+.15)]),2,2,roof_role,Color("687466"))
	if id == "shed":
		for z in [-d,d]:
			b.grid(PackedVector3Array([Vector3(-w,2.4,z),Vector3(w,2.4,z),Vector3(0,3.3,z),Vector3(0,3.3,z)]),2,2,3,WOOD)
	for z in [-d-.15,d+.15]:
		for side in [-1.0,1.0]: b.beam(Vector3(0,3.3,z),Vector3(side*(w+.18),2.4,z),.045,3 if id == "shed" else 5,green)
	for i in range(7):
		var z := -d+float(i)*d*2/6
		for side in [-1.0,1.0]: b.beam(Vector3(0,3.3,z),Vector3(side*(w+.18),2.4,z),.025,3 if id == "shed" else 5,green)

static func _bed(b: RefCounted) -> void:
	for side in [-1.0,1.0]:
		b.box(Vector3(side*1.55,.18,0),Vector3(.12,.34,3.5),.018,3,WOOD)
		b.box(Vector3(0,.18,side*1.69),Vector3(3.2,.34,.12),.018,3,WOOD)
		for z in [-1.68,1.68]:
			b.box(Vector3(side*1.53,.2,z),Vector3(.15,.4,.15),.015,3,WOOD.darkened(.08))
			for y in [.10,.26]: _disk(b,Vector3(side*1.62,y,z),Vector3(side,0,0),.012,BRONZE,.004)
	b.box(Vector3(0,.31,0),Vector3(2.96,.10,3.24),.03,4,Color("584635"))

static func add_collision(root: Node3D) -> int:
	if root.has_node("PlayerCollision") or root.has_node("Geometry/PlayerCollision"): return 0
	var source_id: String = root.get_meta("garden_asset","")
	var id: String = French.ALIASES.get(source_id,source_id)
	var recipes: Array = French.collision(id) if French.SIZES.has(id) else []
	if id in ["garden_gate","timber_gate"]:
		var controller := root.get_node_or_null("GateController")
		if controller: controller.install_leaf_collision()
	match id:
		"garden_gate":
			for side in [-1,1]: recipes.append([Vector3(side*1.275,.95,0),Vector3(.45,1.9,.45),"box"])
		"timber_gate":
			for side in [-1,1]: recipes.append([Vector3(side*1.1,.65,0),Vector3(.20,1.3,.22),"box"])
		"rock_wall": recipes = [[Vector3(0,.575,0),Vector3(2,1.15,.45),"box"]]
		"rock_wall_corner": recipes = [[Vector3(0,.575,-.775),Vector3(2,1.15,.45),"box"],[Vector3(-.775,.575,0),Vector3(.45,1.15,2),"box"]]
		"rock_wall_end": recipes = [[Vector3(0,.675,0),Vector3(.6,1.35,.6),"box"]]
		"bench": recipes = [[Vector3(0,.45,0),Vector3(1.8,.12,.6),"box"],[Vector3(0,.73,-.28),Vector3(1.8,.4,.10),"box"]]
		"rose_arch":
			for side in [-1.0,1.0]: recipes.append([Vector3(side*1.0,1.0,0),Vector3(.17,2,.65),"box"])
		"trellis": recipes = [[Vector3(0,1,0),Vector3(1.6,2,.15),"box"]]
		"fountain": recipes = [[Vector3(0,.24,0),Vector3(2.2,.48,2.2),"cylinder"],[Vector3(0,1.15,0),Vector3(.35,1.7,.35),"cylinder"]]
		"planter": recipes = [[Vector3(0,.22,0),Vector3(.5,.44,.5),"cylinder"]]
		"central_planter": recipes = [[Vector3(0,.33,0),Vector3(6.4,.66,6.4),"cylinder"]]
		"lantern": recipes = [[Vector3(0,.18,0),Vector3(.20,.36,.20),"box"]]
		"watering_can": recipes = [[Vector3(0,.16,0),Vector3(.30,.32,.30),"cylinder"]]
		"tree", "cypress": recipes = [[Vector3(0,1.25,0),Vector3(.34,2.5,.34),"cylinder"]]
		"hedge": recipes = [[Vector3(0,.85,0),Vector3(1.15,1.5,2.1),"box"]]
		"bed": recipes = [[Vector3(0,.17,0),Vector3(3.2,.34,3.5),"box"]]
		"stall":
			recipes = [[Vector3(0,.85,0),Vector3(3.1,.14,1.4),"box"]]
			for x in [-1.4,1.4]:
				for z in [-.7,.7]: recipes.append([Vector3(x,1.35,z),Vector3(.12,2.7,.12),"box"])
		"shed", "greenhouse":
			for x in [-1.7,1.7]: recipes.append([Vector3(x,1.2,0),Vector3(.15,2.4,4.2),"box"])
			recipes.append([Vector3(0,1.2,-2.1),Vector3(3.4,2.4,.15),"box"])
			if id == "shed": recipes.append([Vector3(0,1.2,2.1),Vector3(3.4,2.4,.15),"box"])
			else:
				for x in [-1.1,1.1]: recipes.append([Vector3(x,1.2,2.1),Vector3(1.2,2.4,.15),"box"])
	if source_id in ["limestone_wall","fieldstone_wall","ivy_wall","stone_balustrade"]:
		var dimensions: Vector3 = French.SIZES[source_id]
		if source_id == "ivy_wall": dimensions.y = 1.15
		recipes = [[Vector3(0,dimensions.y*.5,0),dimensions,"box"]]
	if recipes.is_empty(): return 0
	var body := StaticBody3D.new()
	body.name = "PlayerCollision"
	body.collision_layer = 1
	body.collision_mask = 2
	var collision_parent: Node = root
	if source_id in ["vine_pergola","iron_pavilion","espalier_screen","wall_fountain","stone_alcove"] and root.has_node("Geometry"):
		collision_parent = root.get_node("Geometry")
	collision_parent.add_child(body)
	for recipe in recipes:
		var collision := CollisionShape3D.new()
		if recipe[2] == "box":
			var shape := BoxShape3D.new()
			shape.size = recipe[1]
			collision.shape = shape
		else:
			var shape := CylinderShape3D.new()
			shape.radius = recipe[1].x*.5
			shape.height = recipe[1].y
			collision.shape = shape
		collision.position = recipe[0]
		body.add_child(collision)
	return recipes.size()
