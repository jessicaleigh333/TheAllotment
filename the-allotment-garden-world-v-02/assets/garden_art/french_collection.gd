extends RefCounted
## Original French-garden-inspired designs, not replicas of historical objects.
const Boundary := preload("res://assets/garden_art/garden_boundary.gd")
const STONE := Color("c5b69a")
const CLAY := Color("b77e57")
const GREEN := Color("54734e")
const METAL := Color("4e6a5c")
const GOLD := Color("ac9360")
const SIZES := {
 "chateau_gate":Vector3(3,2.4,.6),"potager_gate":Vector3(2.4,1.5,.4),
 "limestone_wall":Vector3(2,1.2,.45),"fieldstone_wall":Vector3(2,1.15,.5),"ivy_wall":Vector3(2,1.4,.6),"stone_balustrade":Vector3(2,.95,.45),
 "anduze_jar":Vector3(.8,1,.8),"clay_bowl":Vector3(.8,.4,.8),"glazed_olive_pot":Vector3(.65,.85,.65),"stone_urn":Vector3(.85,1.15,.85),"stone_trough":Vector3(1.5,.5,.65),"carved_square_pot":Vector3(.75,.75,.75),
 "stone_dove":Vector3(.65,1.15,.65),"botanical_medallion":Vector3(.8,1.5,.55),"garden_muse_bust":Vector3(.75,1.7,.6),"armillary_sphere":Vector3(1,1.85,1),"garden_sundial":Vector3(.8,1.2,.8),
 "vine_pergola":Vector3(4,2.9,3),"iron_pavilion":Vector3(4,3.6,4),"espalier_screen":Vector3(2.8,2.3,.6),"wall_fountain":Vector3(1.6,2.2,1),"stone_alcove":Vector3(3,2.8,1.3)
}
const GATES := {"chateau_gate":"garden_gate","potager_gate":"timber_gate"}
const ALIASES := {"chateau_gate":"garden_gate","potager_gate":"timber_gate","limestone_wall":"rock_wall","fieldstone_wall":"rock_wall","ivy_wall":"rock_wall","stone_balustrade":"rock_wall"}
const CATALOG := [
 {"id":"chateau_gate","category":"Decor","price":0,"icon":0,"radius":1.9,"featured":true,"name":"Château scroll gates","family":"Gates & walls","inspiration":"Formal French gardens","description":"Opening iron double gates with gilded botanical crests and stone finials."},
 {"id":"potager_gate","category":"Decor","price":0,"icon":0,"radius":1.7,"featured":false,"name":"Potager lattice gates","family":"Gates & walls","inspiration":"Villandry potager traditions","description":"Opening painted timber gates with open diamond lattice and floral hardware."},
 {"id":"limestone_wall","category":"Decor","price":0,"icon":0,"radius":1.125,"featured":false,"name":"Formal limestone wall","family":"Gates & walls","inspiration":"French formal garden enclosures","description":"Dressed limestone courses, recessed panels and a molded coping."},
 {"id":"fieldstone_wall","category":"Decor","price":0,"icon":0,"radius":1.131,"featured":false,"name":"Rustic fieldstone wall","family":"Gates & walls","inspiration":"French country gardens","description":"Uneven rounded fieldstones with varied colors, recessed mortar and broad capstones."},
 {"id":"ivy_wall","category":"Decor","price":0,"icon":0,"radius":1.144,"featured":false,"name":"Ivy-covered garden wall","family":"Gates & walls","inspiration":"Romantic French gardens","description":"Stonework softened by branching ivy, climbing stems and shaped leaves."},
 {"id":"stone_balustrade","category":"Decor","price":0,"icon":0,"radius":1.125,"featured":false,"name":"Stone balustrade","family":"Gates & walls","inspiration":"Formal French terraces","description":"Turned stone balusters between molded rails. Connect with the wall pieces."},
 {"id":"anduze_jar","category":"Decor","price":0,"icon":0,"radius":0.666,"featured":false,"name":"Garland terracotta jar","family":"Pots & planters","inspiration":"Anduze pottery traditions","description":"An open clay jar with a rolled lip, handles, garlands and applied medallions."},
 {"id":"clay_bowl","category":"Decor","price":0,"icon":0,"radius":0.666,"featured":false,"name":"Fluted clay bowl","family":"Pots & planters","inspiration":"French courtyard pottery","description":"A low open terracotta bowl with a fluted body and small turned foot."},
 {"id":"glazed_olive_pot","category":"Decor","price":0,"icon":0,"radius":0.56,"featured":false,"name":"Olive-glazed pot","family":"Pots & planters","inspiration":"Southern French gardens","description":"An open olive-green glazed vessel with a pale rim and vertical ribs."},
 {"id":"stone_urn","category":"Decor","price":0,"icon":0,"radius":0.701,"featured":true,"name":"Classical stone urn","family":"Pots & planters","inspiration":"Versailles formal vocabulary","description":"An open gadrooned urn with a turned pedestal and curled handles."},
 {"id":"stone_trough","category":"Decor","price":0,"icon":0,"radius":0.917,"featured":false,"name":"Carved stone trough","family":"Pots & planters","inspiration":"French country courtyards","description":"An open rectangular stone planter with thick rims, feet and floral reliefs."},
 {"id":"carved_square_pot","category":"Decor","price":0,"icon":0,"radius":0.63,"featured":false,"name":"Rosette stone planter","family":"Pots & planters","inspiration":"Formal French parterres","description":"An open square stone planter with molded bands and botanical medallions."},
 {"id":"stone_dove","category":"Decor","price":0,"icon":0,"radius":0.56,"featured":false,"name":"Carved dove sculpture","family":"Sculptures","inspiration":"French garden sculpture","description":"An original carved bird with layered wing feathers, perched on a stone plinth."},
 {"id":"botanical_medallion","category":"Decor","price":0,"icon":0,"radius":0.585,"featured":false,"name":"Botanical relief stele","family":"Sculptures","inspiration":"Botanical garden ornament","description":"An original raised floral medallion on a slender stone pedestal."},
 {"id":"garden_muse_bust","category":"Decor","price":0,"icon":0,"radius":0.58,"featured":true,"name":"Garden muse bust","family":"Sculptures","inspiration":"Classical French garden sculpture","description":"An original softly stylized bust with carved features, gathered hair and draped shoulders."},
 {"id":"armillary_sphere","category":"Decor","price":0,"icon":0,"radius":0.807,"featured":false,"name":"Bronze armillary sphere","family":"Sculptures","inspiration":"French formal garden instruments","description":"Crossing bronze rings, an arrow axis and a marked equatorial band on a stone pedestal."},
 {"id":"garden_sundial","category":"Decor","price":0,"icon":0,"radius":0.666,"featured":false,"name":"Stone garden sundial","family":"Sculptures","inspiration":"French château gardens","description":"A decorative engraved dial and raised bronze gnomon on a fluted pedestal."},
 {"id":"vine_pergola","category":"Decor","price":0,"icon":0,"radius":2.6,"featured":true,"name":"Climbing-vine pergola","family":"Structures","inspiration":"Giverny garden compositions","description":"A full-size painted timber pergola with open rafters, cross braces and climbing foliage."},
 {"id":"iron_pavilion","category":"Decor","price":0,"icon":0,"radius":2.928,"featured":false,"name":"Iron garden pavilion","family":"Structures","inspiration":"French garden gazebos","description":"A walk-through eight-post pavilion with a curved open dome, finial and climbing vines."},
 {"id":"espalier_screen","category":"Decor","price":0,"icon":0,"radius":1.532,"featured":false,"name":"Potager espalier screen","family":"Structures","inspiration":"Villandry potager traditions","description":"A timber support with tiered trained branches, leaves and decorative fruit."},
 {"id":"wall_fountain","category":"Decor","price":0,"icon":0,"radius":1.043,"featured":false,"name":"Rosette wall fountain","family":"Structures","inspiration":"French courtyard waterworks","description":"A carved stone backing, bronze spout and open basin with moving water."},
 {"id":"stone_alcove","category":"Decor","price":0,"icon":0,"radius":1.735,"featured":false,"name":"Stone garden alcove","family":"Structures","inspiration":"French bosquet retreats","description":"An open-front stone arch with recessed backing, side pilasters and a built-in bench."}
]

static func n(high: int, b: RefCounted) -> int:
 return maxi(3,int(high*[1.0,.58,.27][b.detail]))

static func ring(b: RefCounted, center: Vector3, radius: float, right: Vector3, up: Vector3, thickness: float, role: int = 5, color: Color = GOLD) -> void:
 var points := PackedVector3Array()
 var radii := PackedFloat32Array()
 for i in range(n(49,b)):
  var a := float(i)*TAU/(n(49,b)-1)
  points.append(center+(right*cos(a)+up*sin(a))*radius)
  radii.append(thickness)
 b.tube(points,radii,role,color,8)

static func oval(b: RefCounted, center: Vector3, size: Vector3, color: Color = STONE, role: int = 11) -> void:
 var points := PackedVector3Array()
 var rows := n(15,b)
 var columns := n(29,b)
 for row in range(rows):
  var t := float(row)*PI/(rows-1)
  for column in range(columns):
   var a := float(column)*TAU/(columns-1)
   points.append(center+Vector3(cos(a)*sin(t)*size.x,cos(t)*size.y,sin(a)*sin(t)*size.z))
 b.grid(points,rows,columns,role,color)

static func profile(b: RefCounted, values: Array, center: Vector3 = Vector3.ZERO, role: int = 11, color: Color = STONE, stretch: Vector2 = Vector2.ONE) -> void:
 var data := PackedVector2Array()
 for p in values: data.append(Vector2(p[0],p[1]))
 b.lathe(data,center,role,color,40,stretch)

static func rosette(b: RefCounted, center: Vector3, radius: float, color: Color = STONE, front: Vector3 = Vector3.FORWARD) -> void:
 var right := Vector3.RIGHT
 var up := front.cross(right).normalized()
 for i in range(n(13,b)):
  var a := float(i)*TAU/n(13,b)
  var direction := right*cos(a)+up*sin(a)
  b.petal(center, direction.cross(front),direction,radius,radius*.40,.17,color,11)
 oval(b,center+front*.014,Vector3(radius*.13,radius*.13,.02),color.darkened(.06))

static func vine(b: RefCounted, a: Vector3, end: Vector3, spread: float = .23) -> void:
 var points := PackedVector3Array()
 var radii := PackedFloat32Array()
 var count := n(18,b)
 for i in range(count):
  var t := float(i)/(count-1)
  var p := a.lerp(end,t)+Vector3(sin(t*TAU*2)*.07,0,cos(t*TAU*2)*.05)
  points.append(p)
  radii.append(.013*(1-t*.7))
  b.leaf(p,Vector3(cos(i*2.4),.2,sin(i*2.4)),spread,spread*.6,GREEN.lightened(float(i%4)*.025),1)
 b.tube(points,radii,0,Color("647c4a"),6)

static func pedestal(b: RefCounted, height: float = 1, width: float = .5) -> void:
 profile(b,[[0,0],[width*.5,0],[width*.5,.08],[width*.43,.12],[width*.30,.16],[width*.25,height-.16],[width*.43,height-.12],[width*.45,height],[0,height]])
 for i in range(n(16,b)):
  var a := float(i)*TAU/n(16,b)
  b.beam(Vector3(cos(a)*width*.255,.20,sin(a)*width*.255),Vector3(cos(a)*width*.255,height-.2,sin(a)*width*.255),.008,11,STONE.darkened(.035),5)

static func build(b: RefCounted, id: String) -> void:
 if id in GATES:
  Boundary.build(b,GATES[id])
  if id == "chateau_gate":
   for side in [-1.0,1.0]:
    profile(b,[[0,2],[.12,2],[.14,2.05],[.09,2.12],[.12,2.21],[0,2.37]],Vector3(side*1.275,0,0))
  else:
   for side in [-1.0,1.0]: rosette(b,Vector3(side*1.1,1.2,.13),.10,GOLD,Vector3.BACK)
 elif id in ["chateau_gate_leaf","potager_gate_leaf"]: _gate_leaf(b,id)
 elif id in ["limestone_wall","fieldstone_wall","ivy_wall","stone_balustrade"]: _wall(b,id)
 elif id in ["anduze_jar","clay_bowl","glazed_olive_pot","stone_urn","stone_trough","carved_square_pot"]: _pot(b,id)
 elif id in ["stone_dove","botanical_medallion","garden_muse_bust","armillary_sphere","garden_sundial"]: _sculpture(b,id)
 else: _structure(b,id)

static func _gate_leaf(b: RefCounted, id: String) -> void:
 Boundary.build(b,"iron_gate_leaf" if id == "chateau_gate_leaf" else "timber_gate_leaf")
 if id == "chateau_gate_leaf":
  ring(b,Vector3(.53,1.02,.025),.16,Vector3.RIGHT,Vector3.UP,.008)
  rosette(b,Vector3(.53,1.02,.04),.13,GOLD,Vector3.BACK)
  for i in range(3):
   var x := .25+i*.26
   b.petal(Vector3(x,1.7,.015),Vector3.RIGHT,Vector3.UP,.20,.08,.12,GOLD,5)
 else:
  for i in range(6):
   var x := float(i)*.18
   b.beam(Vector3(x,.34,.07),Vector3(minf(1,x+.5),.84,.07),.012,3,Color("6a8973"),6)
   b.beam(Vector3(x,.84,.08),Vector3(minf(1,x+.5),.34,.08),.012,3,Color("6a8973"),6)

static func _wall(b: RefCounted, id: String) -> void:
 if id == "stone_balustrade":
  for y in [.08,.85]: b.box(Vector3(0,y,0),Vector3(2,.16,.45),.025,11,STONE)
  for i in range(9):
   var x := -.88+i*.22
   profile(b,[[0,.16],[.065,.16],[.065,.22],[.04,.27],[.08,.41],[.065,.51],[.03,.57],[.045,.72],[.065,.77],[0,.77]],Vector3(x,0,0))
  return
 if id == "fieldstone_wall":
  b.box(Vector3(0,.5,0),Vector3(1.95,1,.14),.025,11,Color("8d856e"))
  for row in range(4):
   var count := 5+row%2
   for i in range(count):
    var x := -1+(i+.5)*2/count
    var y := .13+row*.245+.015*sin(i*4+row)
    oval(b,Vector3(x,y,0),Vector3(1.04/count,.14+.018*cos(i*3),.26+.025*sin(i+row)),STONE.darkened(float((i+row)%4)*.055))
  b.box(Vector3(0,1.07,0),Vector3(2,.15,.50),.045,11,STONE)
  return
 Boundary.build(b,"rock_wall")
 if id == "limestone_wall":
  for x in [-.88,.88]:
   b.box(Vector3(x,.5,0),Vector3(.20,1,.45),.02,11,STONE.lightened(.08))
  for y in [.12,.85,1.13]: b.box(Vector3(0,y,0),Vector3(2,.07,.47),.015,11,STONE.lightened(.1))
  for side in [-1.0,1.0]: rosette(b,Vector3(0,.52,side*.23),.19,STONE,Vector3(0,0,side))
 else:
  for x in [-.8,-.25,.35,.8]: vine(b,Vector3(x,.05,.25),Vector3(x*.65,1.35,.25),.20)

static func _pot(b: RefCounted, id: String) -> void:
 if id in ["stone_trough","carved_square_pot"]:
  var width := 1.5 if id == "stone_trough" else .75
  var depth := .65 if id == "stone_trough" else .75
  var height := .5 if id == "stone_trough" else .75
  b.box(Vector3(0,.08,0),Vector3(width,.12,depth),.025,11,STONE)
  for side in [-1.0,1.0]:
   b.box(Vector3(0,height*.5,side*(depth*.5-.06)),Vector3(width,height-.12,.12),.025,11,STONE)
   b.box(Vector3(side*(width*.5-.06),height*.5,0),Vector3(.12,height-.12,depth-.20),.025,11,STONE)
   b.box(Vector3(0,height-.03,side*(depth*.5-.05)),Vector3(width+.025,.09,.14),.02,11,STONE.lightened(.08))
   b.box(Vector3(side*(width*.5-.05),height-.03,0),Vector3(.14,.09,depth),.02,11,STONE.lightened(.08))
   rosette(b,Vector3(0,height*.52,side*(depth*.5+.008)),.13 if width < 1 else .17,STONE,Vector3(0,0,side))
  for x in [-width*.32,width*.32]: b.box(Vector3(x,.025,0),Vector3(.18,.05,depth*.65),.015,11,STONE)
  return
 if id == "stone_urn":
  profile(b,[[0,0],[.24,0],[.24,.08],[.16,.12],[.11,.35],[.18,.42],[.30,.52],[.34,.75],[.32,.94],[.38,1],[.38,1.06],[.31,1.06],[.28,.92],[.28,.75],[.22,.6],[0,.56]])
  for side in [-1.0,1.0]: ring(b,Vector3(side*.33,.83,0),.13,Vector3.RIGHT,Vector3.UP,.025,11,STONE)
  for i in range(n(24,b)):
   var a := float(i)*TAU/n(24,b)
   b.beam(Vector3(cos(a)*.19,.47,sin(a)*.19),Vector3(cos(a)*.32,.78,sin(a)*.32),.014,11,STONE.lightened(.03),6)
  return
 if id == "clay_bowl":
  profile(b,[[0,0],[.20,0],[.22,.06],[.18,.09],[.25,.15],[.39,.29],[.40,.35],[.37,.39],[.33,.39],[.34,.32],[.23,.19],[0,.12]],Vector3.ZERO,11,CLAY)
  for i in range(n(24,b)):
   var a := float(i)*TAU/n(24,b)
   b.beam(Vector3(cos(a)*.24,.15,sin(a)*.24),Vector3(cos(a)*.38,.32,sin(a)*.38),.008,11,CLAY.lightened(.08),5)
  return
 var glazed := id == "glazed_olive_pot"
 var color := Color("698260") if glazed else CLAY
 profile(b,[[0,0],[.22,0],[.23,.08],[.20,.12],[.29,.28],[.34,.50],[.31,.76],[.35,.83],[.35,.91],[.30,.94],[.28,.88],[.28,.79],[.28,.51],[.23,.30],[0,.15]],Vector3.ZERO,12 if glazed else 11,color)
 for i in range(n(24 if glazed else 16,b)):
  var a := float(i)*TAU/n(24 if glazed else 16,b)
  if glazed:
   b.beam(Vector3(cos(a)*.24,.2,sin(a)*.24),Vector3(cos(a)*.32,.66,sin(a)*.32),.007,12,color.lightened(.08),5)
  else:
   var points := PackedVector3Array()
   var radii := PackedFloat32Array()
   for j in range(9):
    var t := float(j)/8
    var angle := a+t*TAU/16
    points.append(Vector3(cos(angle)*.344,.64-sin(t*PI)*.09,sin(angle)*.344))
    radii.append(.012)
   b.tube(points,radii,11,CLAY.lightened(.15),6)
 if not glazed:
  for side in [-1.0,1.0]:
   ring(b,Vector3(side*.32,.72,0),.10,Vector3.RIGHT,Vector3.UP,.024,11,CLAY)
  for z in [-.345,.345]: rosette(b,Vector3(0,.58,z),.10,CLAY.lightened(.10),Vector3(0,0,signf(z)))

static func _sculpture(b: RefCounted, id: String) -> void:
 if id == "stone_dove":
  pedestal(b,.65,.44)
  oval(b,Vector3(0,.86,0),Vector3(.20,.16,.25))
  oval(b,Vector3(0,1.02,.15),Vector3(.11,.12,.12))
  b.tube(PackedVector3Array([Vector3(0,1,.23),Vector3(0,.99,.36)]),PackedFloat32Array([.04,0]),11,STONE,8)
  for side in [-1.0,1.0]:
   oval(b,Vector3(side*.09,1.04,.21),Vector3(.015,.015,.012),STONE.darkened(.22))
   for i in range(n(10,b)):
    var t := float(i)/n(10,b)
    b.petal(Vector3(side*.12,.91-t*.025,.06),Vector3(0,1,0),Vector3(side*(.2+t*.2),-.12,-.9+t*.2).normalized(),.24+t*.05,.06,.15,STONE.lightened(t*.05),11)
  for i in range(5): b.petal(Vector3(0,.83,-.15),Vector3.RIGHT,Vector3((i-2)*.15,0,-1).normalized(),.22,.05,.12,STONE,11)
 elif id == "botanical_medallion":
  pedestal(b,.85,.44)
  oval(b,Vector3(0,1.2,0),Vector3(.4,.4,.08))
  rosette(b,Vector3(0,1.2,.08),.32,STONE.lightened(.08),Vector3.BACK)
  ring(b,Vector3(0,1.2,.08),.36,Vector3.RIGHT,Vector3.UP,.015,11,STONE)
 elif id == "garden_muse_bust":
  pedestal(b,.85,.5)
  oval(b,Vector3(0,1.02,0),Vector3(.35,.19,.19))
  profile(b,[[.10,1.03],[.09,1.28],[.065,1.31],[0,1.31]])
  oval(b,Vector3(0,1.45,0),Vector3(.145,.21,.155))
  for side in [-1.0,1.0]:
   oval(b,Vector3(side*.145,1.43,0),Vector3(.027,.055,.025))
   oval(b,Vector3(side*.065,1.48,.145),Vector3(.040,.016,.009),STONE.darkened(.07))
   b.beam(Vector3(side*.035,1.51,.144),Vector3(side*.10,1.51,.13),.009,11,STONE)
  b.tube(PackedVector3Array([Vector3(0,1.51,.14),Vector3(0,1.43,.195),Vector3(0,1.41,.17)]),PackedFloat32Array([.018,.025,.019]),11,STONE,8)
  b.beam(Vector3(-.042,1.365,.14),Vector3(.042,1.365,.14),.010,11,STONE.darkened(.035))
  for i in range(n(18,b)):
   var a := float(i)*TAU/n(18,b)
   oval(b,Vector3(cos(a)*.13,1.60+sin(a)*.04,sin(a)*.11-.04),Vector3(.055,.05,.05),STONE.darkened(.045))
  oval(b,Vector3(0,1.52,-.16),Vector3(.1,.11,.09))
  for i in range(9):
   var x := -.28+i*.07
   b.tube(PackedVector3Array([Vector3(x,1.12,.13),Vector3(x*.7,1.02,.18),Vector3(x*.4,.90,.12)]),PackedFloat32Array([.012,.015,.008]),11,STONE.lightened(.05),6)
 elif id == "armillary_sphere":
  pedestal(b,1.05,.50)
  var center := Vector3(0,1.43,0)
  ring(b,center,.40,Vector3.RIGHT,Vector3.UP,.019)
  ring(b,center,.40,Vector3.BACK,Vector3.UP,.019)
  ring(b,center,.43,Vector3.RIGHT,Vector3(0,.4,.9165),.035)
  ring(b,center,.39,Vector3.RIGHT,Vector3.BACK,.012)
  b.beam(center+Vector3(0,-.45,-.15),center+Vector3(0,.45,.15),.015,5,GOLD)
  for i in range(n(24,b)):
   var a := float(i)*TAU/n(24,b)
   var p := center+(Vector3.RIGHT*cos(a)+Vector3(0,.4,.9165)*sin(a))*.43
   b.beam(p,p+Vector3(0,.035,0),.007,5,GOLD.darkened(.15),5)
  b.tube(PackedVector3Array([center+Vector3(0,.45,.15),center+Vector3(0,.53,.18)]),PackedFloat32Array([.04,0]),5,GOLD,8)
 else:
  pedestal(b,1,.50)
  profile(b,[[0,1],[.40,1],[.4,1.06],[0,1.06]])
  ring(b,Vector3(0,1.067,0),.34,Vector3.RIGHT,Vector3.BACK,.006)
  for i in range(24):
   var a := float(i)*TAU/24
   b.beam(Vector3(cos(a)*.28,1.07,sin(a)*.28),Vector3(cos(a)*.33,1.07,sin(a)*.33),.004,5,GOLD,4)
  b.grid(PackedVector3Array([Vector3(0,1.07,-.20),Vector3(0,1.07,.19),Vector3(0,1.30,-.20),Vector3(0,1.07,.19)]),2,2,5,GOLD)

static func _structure(b: RefCounted, id: String) -> void:
 if id == "vine_pergola":
  for x in [-1.8,1.8]:
   for z in [-1.25,1.25]:
    b.box(Vector3(x,1.3,z),Vector3(.16,2.6,.16),.025,3,METAL)
    b.beam(Vector3(x,2.1,z),Vector3(x-signf(x)*.45,2.65,z),.045,3,METAL)
    b.beam(Vector3(x,2.1,z),Vector3(x,2.65,z-signf(z)*.45),.045,3,METAL)
    vine(b,Vector3(x,0,z+.1),Vector3(x,2.8,z+.1),.27)
   b.box(Vector3(x,2.65,0),Vector3(.18,.22,3),.02,3,METAL)
  for z in [-1.25,1.25]: b.box(Vector3(0,2.65,z),Vector3(4,.20,.14),.02,3,METAL)
  for i in range(9): b.box(Vector3(-2+i*.5,2.8,0),Vector3(.10,.16,3),.015,3,METAL)
  for z in [-.8,.6]: vine(b,Vector3(-1.8,2.85,z),Vector3(1.8,2.85,z),.30)
 elif id == "iron_pavilion":
  for i in range(8):
   var a := float(i)*TAU/8
   var p := Vector3(cos(a)*1.8,0,sin(a)*1.8)
   profile(b,[[.12,0],[.12,.12],[.065,.16],[.045,2.55],[.10,2.58],[0,2.58]],p,5,METAL)
   var points := PackedVector3Array()
   var radii := PackedFloat32Array()
   for j in range(n(18,b)):
    var t := float(j)/(n(18,b)-1)
    points.append(Vector3(cos(a)*1.8*cos(t*PI/2),2.58+sin(t*PI/2)*.85,sin(a)*1.8*cos(t*PI/2)))
    radii.append(.025)
   b.tube(points,radii,5,METAL,8)
   if i%2 == 0: vine(b,p,p+Vector3(0,2.6,0),.26)
  for y in [2.45,2.58]: ring(b,Vector3(0,y,0),1.82,Vector3.RIGHT,Vector3.BACK,.035,5,METAL)
  ring(b,Vector3(0,3.05,0),1.45,Vector3.RIGHT,Vector3.BACK,.016,5,METAL)
  profile(b,[[0,3.4],[.10,3.4],[.07,3.52],[0,3.65]],Vector3.ZERO,5,GOLD)
 elif id == "espalier_screen":
  for x in [-1.3,0,1.3]: b.box(Vector3(x,1.15,0),Vector3(.10,2.3,.10),.018,3,METAL)
  for y in [.35,.9,1.45,2]: b.beam(Vector3(-1.4,y,0),Vector3(1.4,y,0),.015,5,GOLD.darkened(.2),6)
  b.beam(Vector3(0,0,.08),Vector3(0,2.1,.08),.035,0,Color("7a6447"))
  for y in [.4,.95,1.5]:
   for side in [-1.0,1.0]:
    var end := Vector3(side*1.25,y+.3,.10)
    b.tube(PackedVector3Array([Vector3(0,y,.08),Vector3(side*.35,y+.23,.1),end]),PackedFloat32Array([.025,.019,.009]),0,Color("7a6447"),7)
    vine(b,Vector3(side*.2,y+.15,.1),end,.17)
    for i in range(n(6,b)): oval(b,Vector3(side*(.35+i*.15),y+.21,.19),Vector3(.045,.05,.045),Color("bf9a51"),12)
 elif id == "wall_fountain":
  b.box(Vector3(0,1,-.28),Vector3(1.35,2,.18),.045,11,STONE)
  for x in [-.62,.62]: b.box(Vector3(x,1,-.15),Vector3(.15,2,.22),.025,11,STONE)
  for y in [.12,1.9]: b.box(Vector3(0,y,-.20),Vector3(1.55,.16,.35),.035,11,STONE)
  rosette(b,Vector3(0,1.47,-.10),.33,STONE.lightened(.08),Vector3.BACK)
  profile(b,[[0,0],[.49,0],[.49,.15],[.66,.28],[.72,.45],[.72,.55],[.66,.58],[.61,.49],[.5,.29],[0,.18]],Vector3(0,0,.25),11,STONE,Vector2(1,.65))
  profile(b,[[0,.49],[.61,.49]],Vector3(0,0,.25),9,Color("65a9a5"),Vector2(1,.65))
  b.beam(Vector3(0,1.38,-.1),Vector3(0,1.38,.25),.035,5,GOLD)
  b.tube(PackedVector3Array([Vector3(0,1.38,.25),Vector3(0,1.16,.31),Vector3(0,.51,.33)]),PackedFloat32Array([.015,.014,.018]),9,Color("75b7b1"),6)
 elif id == "stone_alcove":
  b.box(Vector3(0,1.05,-.40),Vector3(2.8,2.1,.18),.03,11,STONE.darkened(.08))
  for x in [-1.25,1.25]:
   b.box(Vector3(x,1.15,0),Vector3(.32,2.3,.65),.035,11,STONE)
   for y in [.1,2.14]: b.box(Vector3(x,y,0),Vector3(.42,.18,.75),.025,11,STONE.lightened(.08))
  for i in range(15):
   var a := float(i)*PI/14
   var p := Vector3(cos(a)*1.25,2.0+sin(a)*.65,0)
   b.box(p,Vector3(.27,.27,.7),.03,11,STONE.lightened(float(i%3)*.025))
  b.box(Vector3(0,.47,-.08),Vector3(2,.14,.6),.03,11,STONE)
  for x in [-.75,.75]: b.box(Vector3(x,.22,-.1),Vector3(.20,.44,.4),.025,11,STONE)
  rosette(b,Vector3(0,1.55,-.29),.3,STONE.lightened(.08),Vector3.BACK)

static func collision(id: String) -> Array:
 var size: Vector3 = SIZES.get(id,Vector3.ONE)
 match id:
  "vine_pergola":
   var result := []
   for x in [-1.8,1.8]:
    for z in [-1.25,1.25]: result.append([Vector3(x,1.3,z),Vector3(.18,2.6,.18),"box"])
   return result
  "iron_pavilion":
   var result := []
   for i in range(8):
    var a := i*TAU/8
    result.append([Vector3(cos(a)*1.8,1.25,sin(a)*1.8),Vector3(.16,2.5,.16),"cylinder"])
   return result
  "stone_alcove": return [[Vector3(0,1.05,-.4),Vector3(2.8,2.1,.18),"box"],[Vector3(-1.25,1.15,0),Vector3(.32,2.3,.65),"box"],[Vector3(1.25,1.15,0),Vector3(.32,2.3,.65),"box"],[Vector3(0,.47,-.08),Vector3(2,.14,.6),"box"]]
  "wall_fountain": return [[Vector3(0,1,-.28),Vector3(1.35,2,.2),"box"],[Vector3(0,.27,.25),Vector3(1.4,.54,.75),"box"]]
  "espalier_screen": return [[Vector3(0,1.15,0),Vector3(2.8,2.3,.22),"box"]]
  "stone_trough","carved_square_pot": return [[Vector3(0,size.y*.5,0),size,"box"]]
  _: return [[Vector3(0,minf(.5,size.y*.5),0),Vector3(size.x,minf(1,size.y),size.z),"cylinder"]]
