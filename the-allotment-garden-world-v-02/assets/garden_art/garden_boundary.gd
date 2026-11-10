extends RefCounted
## Original modular limestone / fieldstone and working garden gate geometry.
const STONE := Color("b7aa8d")
const IRON := Color("46554c")
const WOOD := Color("9b7b53")
const IDS := ["garden_gate","timber_gate","rock_wall","rock_wall_corner","rock_wall_end"]
const SIZES := {"garden_gate":Vector3(3,2,.6),"timber_gate":Vector3(2.4,1.3,.4),"rock_wall":Vector3(2,1.15,.45),"rock_wall_corner":Vector3(2,1.15,2),"rock_wall_end":Vector3(.6,1.35,.6)}

static func build(b: RefCounted, id: String) -> void:
	match id:
		"rock_wall": _wall(b,Vector3(-1,0,0),Vector3(1,0,0))
		"rock_wall_corner":
			_wall(b,Vector3(-.775,0,-.775),Vector3(1,0,-.775))
			_wall(b,Vector3(-.775,0,-.55),Vector3(-.775,0,1))
		"rock_wall_end": _pier(b,0,.6,1.35)
		"garden_gate":
			for side in [-1.0,1.0]: _pier(b,side*1.275,.45,2)
		"timber_gate":
			for side in [-1.0,1.0]:
				b.box(Vector3(side*1.1,.65,0),Vector3(.20,1.3,.22),.025,3,WOOD)
				b.lathe(PackedVector2Array([Vector2(.14,1.28),Vector2(0,1.40)]),Vector3(side*1.1,0,0),3,WOOD,8)
		"iron_gate_leaf": _iron_leaf(b)
		"timber_gate_leaf": _timber_leaf(b)

static func _wall(b: RefCounted, a: Vector3, end: Vector3) -> void:
	var length := a.distance_to(end)
	var direction := (end-a).normalized()
	var along_x := absf(direction.x) > .5
	var center := (a+end)*.5
	# Recessed mortar core and individually beveled, staggered stones.
	b.box(center+Vector3(0,.51,0),Vector3(length,1.02,.34) if along_x else Vector3(.34,1.02,length),.018,11,Color("877f6b"))
	for row in range(4):
		var pieces := 4+row%2
		var segment := length/pieces
		for i in range(pieces):
			var p := a+direction*(segment*(i+.5))+Vector3(0,.13+row*.255,0)
			var depth := .40+.035*sin(float(i*7+row*3))
			var size := Vector3(segment-.018,.237,depth) if along_x else Vector3(depth,.237,segment-.018)
			b.box(p,size,.060,11,STONE.lightened(float((i+row*3)%5)*.022))
	for i in range(4):
		var p := a+direction*(length*(i+.5)/4)+Vector3(0,1.075,0)
		b.box(p,Vector3(length/4-.008,.15,.45) if along_x else Vector3(.45,.15,length/4-.008),.025,11,STONE.lightened(.10))
	if b.detail == 0:
		for i in range(7):
			var p := a+direction*(length*(i+.5)/7)+Vector3(0,.04,0)
			b.leaf(p,Vector3(direction.z,.4,direction.x),.10,.045,Color("71834d"))

static func _pier(b: RefCounted, x: float, width: float, height: float) -> void:
	var rows := 5 if height > 1.5 else 4
	var cap := .14
	for row in range(rows):
		var h := (height-cap)/rows
		b.box(Vector3(x,h*(row+.5),0),Vector3(width-.025,h-.014,width-.025),.025,11,STONE.lightened(float(row%3)*.035))
	b.box(Vector3(x,height-cap*.5,0),Vector3(width,cap,width),.035,11,STONE.lightened(.13))

static func _scroll(b: RefCounted, center: Vector3, radius: float, mirror: float = 1) -> void:
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	var count := 29 if b.detail == 0 else 16
	for i in range(count):
		var t := float(i)/(count-1)
		var a := t*TAU*1.3
		var r := radius*(1-t*.88)
		points.append(center+Vector3(cos(a)*r*mirror,sin(a)*r,0))
		radii.append(.009)
	b.tube(points,radii,5,IRON,6)

static func _iron_leaf(b: RefCounted) -> void:
	# Hinge origin: x=0; leaf extends towards the meeting stile at x=1.025.
	for x in [0,1.025]: b.box(Vector3(x,.82,0),Vector3(.04,1.55,.045),.006,5,IRON)
	for y in [.22,.57,1.2]: b.box(Vector3(.5125,y,0),Vector3(1.025,.03,.035),.005,5,IRON)
	var crest := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in range(17):
		var t := float(i)/16
		crest.append(Vector3(t*1.025,1.48+sin(t*PI/2)*.28,0))
		radii.append(.020)
	b.tube(crest,radii,5,IRON,8)
	for i in range(7):
		var x := .11+i*.135
		var h := 1.47+sin(x/1.025*PI/2)*.28
		b.beam(Vector3(x,.22,0),Vector3(x,h+.055,0),.011,5,IRON,6)
		b.lathe(PackedVector2Array([Vector2(0,0),Vector2(.028,.035),Vector2(0,.09)]),Vector3(x,h+.025,0),5,Color("a18c58"),8)
	for x in [.24,.76]:
		_scroll(b,Vector3(x,.86,0),.18)
		_scroll(b,Vector3(x,.40,0),.12,-1)
	for y in [.32,1.2]:
		b.beam(Vector3(-.035,y,-.04),Vector3(.05,y,-.04),.025,5,Color("9b885b"),8)
	b.box(Vector3(.96,.80,.05),Vector3(.10,.025,.055),.007,5,Color("b29b62"))

static func _timber_leaf(b: RefCounted) -> void:
	for i in range(6):
		var x := .075+i*.16
		var h := 1.04+sin(x*PI)*.13
		b.box(Vector3(x,h*.5+.08,0),Vector3(.12,h,.055),.012,3,WOOD.lightened(float(i%3)*.03))
	for y in [.30,.85]: b.box(Vector3(.5,y,-.055),Vector3(1,.085,.055),.009,3,WOOD.darkened(.07))
	b.beam(Vector3(.05,.3,-.08),Vector3(.95,.85,-.08),.035,3,WOOD)
	for y in [.3,.85]: b.box(Vector3(.11,y,.045),Vector3(.23,.035,.03),.005,5,IRON)
	b.box(Vector3(.94,.70,.05),Vector3(.10,.035,.04),.005,5,IRON)
