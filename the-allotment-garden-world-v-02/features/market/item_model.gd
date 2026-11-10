extends "res://scripts/world.gd"
## Reusable ground-pivot prototype meshes; illustrations remain art references.
@export var item_id := "rose"

func _ready() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	match item_id:
		"sunflower": _bloom(Vector3.ZERO,1.7,Color("e9b844"),12,.32)
		"cosmos", "daisy":
			for i in range(5):
				var a := float(i)*TAU/5
				_bloom(Vector3(cos(a)*.22,0,sin(a)*.22),.7+float(i%3)*.14,Color("d88da9") if item_id == "cosmos" else Color("fff1cf"),8 if item_id == "cosmos" else 12,.15)
		"rose", "hydrangea":
			for i in range(5):
				var a := float(i)*TAU/5
				_ellipsoid(Vector3(cos(a)*.3,.45,sin(a)*.3),Vector3(.42,.45,.4),Color("537650"))
			for i in range(7):
				var a := float(i)*2.4
				var p := Vector3(cos(a)*.42,.75+float(i%3)*.13,sin(a)*.42)
				if item_id == "rose": _rosette(p,.18)
				else:
					for j in range(12):
						var b := float(j)*2.4
						_ellipsoid(p+Vector3(cos(b)*.16,sin(float(j)*1.7)*.13,sin(b)*.16),Vector3.ONE*.09,Color("a49ccf") if j%2 == 0 else Color("829fce"))
		"lavender":
			for i in range(12):
				var a := float(i)*2.4
				var p := Vector3(cos(a)*.27,0,sin(a)*.27)
				var h := .55+float(i%4)*.1
				_cylinder(p+Vector3(0,h/2,0),.018,h,Color("647d52"),self)
				_ellipsoid(p+Vector3(0,.2,0),Vector3(.10,.25,.07),Color("69815a"))
				for j in range(5): _ellipsoid(p+Vector3(0,h+float(j)*.045,0),Vector3(.045,.045,.045),Color("9b82b8"))
		"rose_arch":
			_arch(self,Vector3.ZERO)
			for i in range(7): _rosette(Vector3(-1.1+float(i)*.36,2.92,.15),.13)
		"bench":
			for x in [-1.0,1.0]:
				for z in [-.32,.32]: _box(Vector3(x,.3,z),Vector3(.12,.6,.12),Color("72533d"),self)
			for z in [-.3,0,.3]: _box(Vector3(0,.65,z),Vector3(2.35,.12,.22),Color("ad8a60"),self)
			for y in [.95,1.2]: _box(Vector3(0,y,-.37),Vector3(2.3,.15,.10),Color("ad8a60"),self)
			for x in [-1.0,1.0]: _box(Vector3(x,1,-.37),Vector3(.1,.7,.1),Color("72533d"),self)
		"fountain":
			_cylinder(Vector3(0,.18,0),1.1,.36,Color("b6a58c"),self)
			_cylinder(Vector3(0,.37,0),.96,.04,Color("789eaa"),self)
			_cylinder(Vector3(0,.8,0),.19,1.4,Color("b6a58c"),self)
			_cylinder(Vector3(0,1.25,0),.65,.16,Color("c5b499"),self)
			_cylinder(Vector3(0,1.35,0),.56,.025,Color("789eaa"),self)
			_cylinder(Vector3(0,1.85,0),.35,.12,Color("c5b499"),self)
			_ball(Vector3(0,2,0),.12,Color("c5b499"),self)
		"lantern":
			_box(Vector3(0,.08,0),Vector3(.4,.16,.4),Color("826340"),self)
			var glass := _box(Vector3(0,.38,0),Vector3(.30,.42,.30),Color("f8d58a"),self)
			var material := glass.material_override as StandardMaterial3D
			material.emission_enabled = true
			material.emission = Color("e6ad54")
			for x in [-.18,.18]:
				for z in [-.18,.18]: _box(Vector3(x,.4,z),Vector3(.035,.55,.035),Color("826340"),self)
			_box(Vector3(0,.7,0),Vector3(.42,.12,.42),Color("826340"),self)
		"trellis":
			for x in [-.8,.8]: _box(Vector3(x,1.15,0),Vector3(.11,2.3,.11),Color("a48661"),self)
			for y in [.4,.8,1.2,1.6,2]: _box(Vector3(0,y,0),Vector3(1.6,.06,.06),Color("a48661"),self)
			for x in [-.4,0,.4]: _box(Vector3(x,1.15,0),Vector3(.05,1.9,.05),Color("a48661"),self)
			for i in range(6):
				var p := Vector3(sin(float(i))*.5,.5+float(i)*.25,.1)
				_ellipsoid(p,Vector3(.22,.25,.12),Color("57784c"))
				_rosette(p+Vector3(0,.07,.12),.12)
		"planter": _round_planter(self,Vector3.ZERO,0)
		"watering_can":
			_cylinder(Vector3(0,.3,0),.28,.55,Color("859893"),self)
			var spout := _box(Vector3(.38,.43,0),Vector3(.55,.10,.10),Color("859893"),self)
			spout.rotation.z = .6
			for x in [-.27,.27]: _box(Vector3(x,.65,0),Vector3(.06,.4,.08),Color("859893"),self)
			_box(Vector3(0,.85,0),Vector3(.6,.06,.08),Color("859893"),self)
		"straw_hat":
			_cylinder(Vector3(0,.13,0),.65,.07,Color("cba76a"),self)
			_cylinder(Vector3(0,.31,0),.36,.32,Color("cba76a"),self)
			_cylinder(Vector3(0,.22,0),.37,.08,Color("b78683"),self)

func _ellipsoid(p: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	node.scale = size
	node.position = p
	node.material_override = _material(color)
	add_child(node)
	return node

func _bloom(p: Vector3, height: float, color: Color, petals: int, radius: float) -> void:
	_cylinder(p+Vector3(0,height/2,0),.025,height,Color("577c49"),self)
	for side in [-1.0,1.0]:
		var leaf := _ellipsoid(p+Vector3(side*.13,height*.5,0),Vector3(.19,.06,.11),Color("638a51"))
		leaf.rotation.z = side*.4
	var head := p+Vector3(0,height,0)
	for i in range(petals):
		var a := float(i)*TAU/petals
		var petal := _ellipsoid(head+Vector3(cos(a)*radius,0,sin(a)*radius),Vector3(radius*.7,.045,radius*.3),color)
		petal.rotation.y = -a
	_ellipsoid(head+Vector3(0,.025,0),Vector3(radius*.55,.07,radius*.55),Color("70513a") if item_id == "sunflower" else Color("d7ac48"))

func _rosette(p: Vector3, radius: float) -> void:
	for i in range(8):
		var a := float(i)*2.4
		var r := radius*(1.0-float(i)*.075)
		_ellipsoid(p+Vector3(cos(a)*r*.4,float(i)*.012,sin(a)*r*.4),Vector3(r,.055,r*.65),Color("d68da3") if i%2 == 0 else Color("e9afba"))

func _process(_delta: float) -> void:
	pass

func _unhandled_input(_event: InputEvent) -> void:
	pass
