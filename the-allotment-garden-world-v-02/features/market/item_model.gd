extends "res://scripts/world.gd"
## Reusable ground-pivot prototype meshes; illustrations remain art references.
@export var item_id := "rose"
@export var growth_age_days := -1.0
const Growth := preload("res://features/market/plant_growth.gd")
var current_stage := 4

func _ready() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	rebuild(growth_age_days)

func rebuild(age: float = -1.0) -> void:
	for child in get_children(): child.free()
	var original_id := item_id
	var plant := Growth.species(item_id)
	var dimensions := Vector3.ZERO
	if not plant.is_empty():
		if age < 0: age = Growth.starting_age(item_id)
		growth_age_days = age
		var state := Growth.state(plant,age)
		current_stage = state.stage
		dimensions = Vector3(state.width,state.height,state.width)
		if current_stage < 4:
			_build_immature(plant,state)
			_fit_dimensions(dimensions)
			return
		item_id = plant
	_build_mature()
	item_id = original_id
	if not plant.is_empty(): _fit_dimensions(dimensions)
	else:
		var sizes := {"bench":Vector3(1.8,.9,.65),"rose_arch":Vector3(2.4,2.5,.7),"fountain":Vector3(2.2,2.0,2.2),"lantern":Vector3(.22,.45,.22),"trellis":Vector3(1.6,2,.25),"planter":Vector3(.55,.75,.55),"watering_can":Vector3(.65,.4,.28),"straw_hat":Vector3(.42,.16,.42)}
		if sizes.has(item_id): _fit_dimensions(sizes[item_id])

func _build_mature() -> void:
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
		"basil":
			for branch in range(5):
				var a := float(branch)*TAU/5
				var p := Vector3(cos(a)*.12,0,sin(a)*.12)
				_cylinder(p+Vector3(0,.23,0),.018,.46,Color("5b8150"),self)
				for j in range(4):
					for side in [-1.0,1.0]:
						var leaf := _ellipsoid(p+Vector3(side*.09,.12+float(j)*.085,0),Vector3(.11,.035,.06),Color("6c944e"))
						leaf.rotation.z = side*.25
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

func _build_immature(plant: String, state: Dictionary) -> void:
	if int(state.stage) == 0:
		_ellipsoid(Vector3(0,.006,0),Vector3(.05,.006,.05),Color("66503a"))
		var marker := Label3D.new()
		marker.text = plant.capitalize()+" · Seed"
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.pixel_size = .002
		marker.position.y = .18
		marker.no_depth_test = false
		add_child(marker)
		return
	var h: float = state.height
	_cylinder(Vector3(0,h*.45,0),maxf(.002,h*.025),h*.9,Color("587b49"),self)
	var leaves := 2 if int(state.stage) == 1 else (4 if int(state.stage) == 2 else 10)
	for i in range(leaves):
		var a := float(i)*2.4
		var y := h*(.25+.65*float(i)/maxf(1,leaves-1))
		var size := h*(.26 if int(state.stage) < 3 else .18)
		var leaf := _ellipsoid(Vector3(cos(a)*size*.55,y,sin(a)*size*.55),Vector3(size,size*.18,size*.5),Color("719555"))
		leaf.rotation.y = -a
	if int(state.stage) == 3 and plant != "basil":
		_ellipsoid(Vector3(0,h,0),Vector3(h*.055,h*.075,h*.055),Color("63864e"))

func mesh_bounds() -> AABB:
	var bounds := AABB()
	var first := true
	for mesh in find_children("*","MeshInstance3D",true,false):
		var box: AABB = mesh.get_aabb()
		var transform: Transform3D = global_transform.affine_inverse()*mesh.global_transform
		var local: AABB = transform*box
		bounds = local if first else bounds.merge(local)
		first = false
	return bounds

func _fit_dimensions(target: Vector3) -> void:
	var bounds := mesh_bounds()
	if bounds.size.x <= 0 or bounds.size.y <= 0 or bounds.size.z <= 0: return
	var factor := target/bounds.size
	var children := get_children()
	var geometry := Node3D.new()
	geometry.name = "Geometry"
	add_child(geometry)
	for child in children:
		if child is Node3D and not child is Label3D: child.reparent(geometry,true)
	geometry.scale = factor
	geometry.position.y = -bounds.position.y*factor.y

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
	var first_petals := get_child_count()
	for i in range(petals):
		var a := float(i)*TAU/petals
		var petal := _ellipsoid(head+Vector3(cos(a)*radius,0,sin(a)*radius),Vector3(radius*.7,.045,radius*.3),color)
		petal.rotation.y = -a
	_ellipsoid(head+Vector3(0,.025,0),Vector3(radius*.55,.07,radius*.55),Color("70513a") if item_id == "sunflower" else Color("d7ac48"))
	if item_id == "sunflower":
		var turn := Transform3D(Basis(Vector3.RIGHT,PI/2),head)*Transform3D(Basis.IDENTITY,-head)
		for i in range(first_petals,get_child_count()): get_child(i).transform = turn*get_child(i).transform

func _rosette(p: Vector3, radius: float) -> void:
	for i in range(8):
		var a := float(i)*2.4
		var r := radius*(1.0-float(i)*.075)
		_ellipsoid(p+Vector3(cos(a)*r*.4,float(i)*.012,sin(a)*r*.4),Vector3(r,.055,r*.65),Color("d68da3") if i%2 == 0 else Color("e9afba"))

func _process(_delta: float) -> void:
	pass

func _unhandled_input(_event: InputEvent) -> void:
	pass
