extends RefCounted
## Original models informed by the owner's two Campsite board screenshots.
const Orbs := preload("res://assets/garden_art/enchanted_collection.gd")
const Shape := preload("res://assets/garden_art/french_collection.gd")
const WOOD := Color("977653")
const WILLOW := Color("b49a72")
const GREEN := Color("5d814e")
const GOLD := Color("e2b66f")
const SIZES := {
 "branch_trellis":Vector3(2,2.2,.4),"twig_obelisk":Vector3(1.1,2.2,1.1),"willow_basket_planter":Vector3(1.1,.4,1.1),"willow_teepee_planter":Vector3(1.1,2.2,1.1),
 "rustic_arbor":Vector3(2.6,2.8,.8),"branch_gate":Vector3(2.4,1.7,.45),"branch_fence":Vector3(2,1.2,.35),"wooden_clothes_airer":Vector3(1.8,1.7,1.2),
 "garden_chess_set":Vector3(4.8,.7,4.8),"grass_stone_checkerboard":Vector3(4.8,.025,4.8),"backyard_bowling_lane":Vector3(1.5,.45,6),"formal_parterre":Vector3(4.8,.8,4.8),"fairy_light_arbor":Vector3(2.6,2.8,.8)
}
const ALIASES := {"branch_gate":"timber_gate","branch_fence":"rock_wall"}
const GATES := {"branch_gate":"timber_gate"}
const CATALOG := [
 {"id":"branch_trellis","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":1.1,"featured":false,"name":"Woven-branch trellis","description":"Irregular branch posts and a diamond lattice, with cord lashings and climbing leaves."},
 {"id":"twig_obelisk","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":0.858,"featured":false,"name":"Twig climbing obelisk","description":"A full-size triangular climbing support with bent branch crossbars and tied joints."},
 {"id":"willow_basket_planter","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":0.858,"featured":false,"name":"Woven willow garden basket","description":"An open round planter with upright stakes, interlaced willow and a rolled rim."},
 {"id":"willow_teepee_planter","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":0.858,"featured":true,"name":"Willow basket teepee planter","description":"A woven circular planter with a tied climbing cone and decorative leafy shoots."},
 {"id":"rustic_arbor","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":1.44,"featured":false,"name":"Rustic branch arbor","description":"An open garden entrance built from curving branches and interlaced twigs."},
 {"id":"branch_gate","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":1.7,"featured":true,"name":"Rustic twig garden gates","description":"Opening double gates with crooked branches and rope joints. Opens as the gardener approaches."},
 {"id":"branch_fence","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":1.095,"featured":false,"name":"Rustic woven branch fence","description":"A two-metre garden fence with irregular uprights and woven cross branches. Ends connect to boundary pieces."},
 {"id":"wooden_clothes_airer","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":1.162,"featured":false,"name":"Garden quilt-drying rack","description":"A folding wooden rack with cross rails and an original patchwork quilt draped across it."},
 {"id":"garden_chess_set","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":3.474,"featured":true,"name":"Giant garden chess display","description":"A 4.8 m board with 32 modeled pieces. A decorative garden set; chess moves are not a gameplay system yet."},
 {"id":"grass_stone_checkerboard","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":3.474,"featured":false,"name":"Grass and stone checkerboard","description":"Stone squares form a 4.8 m checkerboard. Place on grass so the open squares show the existing lawn."},
 {"id":"backyard_bowling_lane","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":3.172,"featured":false,"name":"Backyard bowling display","description":"A six-metre wooden lane with side rails, ten pins and two bowls. Decorative; bowling gameplay is not connected."},
 {"id":"formal_parterre","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":3.474,"featured":false,"name":"Formal garden parterre module","description":"Four edged planting compartments, clipped greenery and small flowers around an open cross path."},
 {"id":"fairy_light_arbor","category":"Decor","price":0,"icon":0,"family":"Rustic campsite board inspiration","inspiration":"Owner-shared Campsite Pinterest screenshots","radius":1.44,"featured":true,"name":"Fairy-lit woodland arbor","description":"A branch arbor with climbing foliage and warm string lights that glow at night."}
]

static func oval(b: RefCounted, center: Vector3, size: Vector3, color: Color) -> void:
 Orbs.orb(b,center,size,color,11)

static func branch(b: RefCounted, a: Vector3, end: Vector3, radius: float = .025, color: Color = WOOD) -> void:
 var mid := a.lerp(end,.52)+Vector3(.025*sin(a.y*3+end.x),.02*cos(end.z*3),.025*cos(a.x*2+end.y))
 b.tube(PackedVector3Array([a,mid,end]),PackedFloat32Array([radius,radius*.9,radius*.72]),3,color,8)

static func tie(b: RefCounted, center: Vector3, radius: float = .045) -> void:
 for y in [-.018,.0,.018]: Shape.ring(b,center+Vector3(0,y,0),radius,Vector3.RIGHT,Vector3.BACK,.006,7,WILLOW.lightened(.12))

static func basket(b: RefCounted) -> void:
 for i in range(18):
  var a := i*TAU/18
  branch(b,Vector3(cos(a)*.46,0,sin(a)*.46),Vector3(cos(a)*.53,.38,sin(a)*.53),.013,WILLOW.darkened(.12))
 for row in range(Shape.n(18,b)):
  var y := .025+row*.34/maxi(1,Shape.n(18,b)-1)
  var points := PackedVector3Array()
  var radii := PackedFloat32Array()
  var count: int = [109,73,37][b.detail]
  for i in range(count):
   var a := i*TAU/(count-1)
   var r := .46+y*.18+.026*cos(a*9+row*PI)
   points.append(Vector3(cos(a)*r,y,sin(a)*r))
   radii.append(.010)
  b.tube(points,radii,3,WILLOW.lightened(float(row%3)*.035),6)
 Shape.ring(b,Vector3(0,.38,0),.53,Vector3.RIGHT,Vector3.BACK,.022,3,WILLOW)
 # Recessed earth remains visible through the open rim.
 Shape.profile(b,[[0,.03],[.455,.03],[0,.05]],Vector3.ZERO,11,Color("62503c"))

static func cone(b: RefCounted, y: float = 0, leafy: bool = false) -> void:
 for i in range(6):
  var a := i*TAU/6
  branch(b,Vector3(cos(a)*.48,y,sin(a)*.48),Vector3(cos(a)*.07,y+1.85,sin(a)*.07),.022)
  if leafy and i%2 == 0: Shape.vine(b,Vector3(cos(a)*.43,y+.08,sin(a)*.43),Vector3(cos(a)*.11,y+1.45,sin(a)*.11),.13)
 for height in [.35,.80,1.25,1.70]:
  var r: float = .48*(1-height/2)
  Shape.ring(b,Vector3(0,y+height,0),r,Vector3.RIGHT,Vector3.BACK,.012,3,WOOD)
 tie(b,Vector3(0,y+1.72,0),.12)

static func arbor(b: RefCounted, lights: bool) -> void:
 for x in [-1.1,1.1]:
  for z in [-.28,.28]:
   branch(b,Vector3(x,0,z),Vector3(x*.93,2.3,z),.055)
   branch(b,Vector3(x*.93,2.3,z),Vector3(x*.30,2.70,z),.045)
   branch(b,Vector3(x*.30,2.70,z),Vector3(0,2.76,z),.035)
   branch(b,Vector3(x,1.3,z),Vector3(x*.9,1.6,z+.12),.022)
  Shape.vine(b,Vector3(x,.1,.3),Vector3(x*.95,2.2,.3),.24)
 for i in range(8):
  var x := -1.12+i*.32
  var y := 2.7-absf(x)*.30
  branch(b,Vector3(x,y,-.4),Vector3(x+.05,y+.04,.4),.020)
  tie(b,Vector3(x,y,.28),.032)
 if lights:
  var wire := PackedVector3Array()
  var radii := PackedFloat32Array()
  for i in range(25):
   var t := float(i)/24
   wire.append(Vector3(-1.15+t*2.3,2.20-.24*sin(t*PI),.32))
   radii.append(.006)
  b.tube(wire,radii,5,Color("4e5245"),5)
  for i in range(13):
   var t := (float(i)+.5)/13
   var pos := Vector3(-1.15+t*2.3,2.16-.24*sin(t*PI),.32)
   Shape.profile(b,[[.012,0],[.024,-.03],[.021,-.06],[0,-.075]],pos,13,GOLD)

static func leaf_gate(b: RefCounted) -> void:
 for x in [.025,.98]: branch(b,Vector3(x,.1,0),Vector3(x,1.35-(x*.16),0),.026)
 for y in [.25,.75,1.15]: branch(b,Vector3(.01,y,0),Vector3(1,y-.05,0),.024)
 for i in range(5):
  var x := .14+i*.17
  branch(b,Vector3(x,.15,.01),Vector3(x+.025,1.35-.12*x,.01),.014)
  tie(b,Vector3(x,.74,.01),.026)
 branch(b,Vector3(.05,.25,-.03),Vector3(.98,1.15,-.03),.022)

static func chess_piece(b: RefCounted, origin: Vector3, kind: int, color: Color, facing: float = 1.0) -> void:
 var height: float = [.30,.48,.49,.54,.62,.66][kind]
 Shape.profile(b,[[0,0],[.16,0],[.16,.04],[.13,.065],[.11,.10],[.075,height*.62],[.12,height*.70],[.12,height*.76],[.08,height*.8],[0,height*.8]],origin,11,color)
 if kind == 0: oval(b,origin+Vector3(0,.26,0),Vector3.ONE*.075,color)
 elif kind == 1:
  # Carved stylized knight: long neck, muzzle, mane and ears.
  oval(b,origin+Vector3(0,.35,0),Vector3(.08,.14,.07),color)
  oval(b,origin+Vector3(0,.45,.045*facing),Vector3(.07,.075,.11),color)
  for x in [-.04,.04]: b.beam(origin+Vector3(x,.46,.015*facing),origin+Vector3(x,.54,.02*facing),.018,11,color,6)
 elif kind == 2:
  Shape.profile(b,[[0,.34],[.13,.34],[.13,.45],[0,.45]],origin,11,color)
  for i in range(6):
   var a := i*TAU/6
   b.box(origin+Vector3(cos(a)*.105,.48,sin(a)*.105),Vector3(.065,.07,.065),.008,11,color)
 elif kind == 3:
  Shape.profile(b,[[0,.39],[.07,.39],[.09,.45],[.04,.54],[0,.58]],origin,11,color)
 elif kind == 4:
  for i in range(7):
   var a := i*TAU/7
   b.beam(origin+Vector3(cos(a)*.07,.47,sin(a)*.07),origin+Vector3(cos(a)*.10,.59,sin(a)*.10),.018,11,color,6)
  oval(b,origin+Vector3(0,.61,0),Vector3.ONE*.04,color)
 else:
  b.beam(origin+Vector3(0,.46,0),origin+Vector3(0,.66,0),.02,11,color,6)
  b.beam(origin+Vector3(-.07,.61,0),origin+Vector3(.07,.61,0),.02,11,color,6)

static func board(b: RefCounted, chess: bool) -> void:
 for x in range(8):
  for z in range(8):
   if not chess and (x+z)%2 == 1: continue
   var color := (Color("68645c") if (x+z)%2 == 0 else Color("bdb59e")) if chess else (Color("bdb59e") if (x+z)%2 == 0 else Color("67805c"))
   b.box(Vector3(-2.1+x*.6,.006,-2.1+z*.6),Vector3(.595,.012,.595),.004,11,color)
 if chess:
  for side in [-1,1]:
   var color := Color("d6c8aa") if side == -1 else Color("6a5544")
   for i in range(8):
    var x := -2.1+i*.6
    chess_piece(b,Vector3(x,.012,side*1.5),0,color)
    chess_piece(b,Vector3(x,.012,side*2.1),[2,1,3,4,5,3,1,2][i],color,-float(side))

static func build(b: RefCounted, id: String) -> void:
 match id:
  "branch_trellis":
   for x in [-.85,.85]: branch(b,Vector3(x,0,0),Vector3(x+.03,2.2,.02),.05)
   for i in range(6):
    var y := .15+i*.34
    branch(b,Vector3(-.88,y,-.02),Vector3(.88,minf(2.13,y+.65),.02),.018)
    branch(b,Vector3(.88,y,.03),Vector3(-.88,minf(2.13,y+.65),.03),.018)
   Shape.vine(b,Vector3(-.65,.05,.04),Vector3(.55,1.95,.06),.19)
  "twig_obelisk": cone(b)
  "willow_basket_planter": basket(b)
  "willow_teepee_planter": basket(b); cone(b,.32,true)
  "rustic_arbor","fairy_light_arbor": arbor(b,id == "fairy_light_arbor")
  "branch_gate":
   for side in [-1.0,1.0]:
    branch(b,Vector3(side*1.1,0,0),Vector3(side*1.1,1.65,0),.075)
    branch(b,Vector3(side*1.1,1.20,0),Vector3(side*.96,1.7,.12),.025)
  "branch_gate_leaf": leaf_gate(b)
  "branch_fence":
   for x in [-.95,.95]: branch(b,Vector3(x,0,0),Vector3(x,1.2,0),.045)
   for i in range(9):
    var x := -.85+i*.21
    branch(b,Vector3(x,.05,.03*sin(i)),Vector3(x+.03,1.05+.1*sin(i),0),.02)
   for y in [.22,.60,.95]: branch(b,Vector3(-1,y,0),Vector3(1,y+.03,.02),.025)
  "wooden_clothes_airer":
   for side in [-1.0,1.0]:
    branch(b,Vector3(side*.68,0,-.5),Vector3(side*.68,1.65,.28),.025)
    branch(b,Vector3(side*.68,0,.5),Vector3(side*.68,1.65,-.28),.025)
   for y in [.35,.75,1.15,1.58]:
    for z in [-.28,.28]: branch(b,Vector3(-.78,y,z),Vector3(.78,y,z),.018,WILLOW)
   # A quilt follows a smooth fold over the upper rail; patches are actual colored cloth surfaces.
   for row in range(5):
    for column in range(7):
     var points := PackedVector3Array()
     for v in [0.0,1.0]:
      for u in [0.0,1.0]:
       var t: float = (row+v)/5.0
       points.append(Vector3(-.70+(column+u)*.20,1.62-sin(t*PI/2)*.72,.28-t*.22))
     b.grid(points,2,2,6,[Color("a85969"),Color("c9b19a"),Color("5e7d78"),Color("7e6f91")][(row+column*2)%4])
  "garden_chess_set","grass_stone_checkerboard": board(b,id == "garden_chess_set")
  "backyard_bowling_lane":
   for i in range(7): b.box(Vector3(-.64+i*.21,.008,0),Vector3(.20,.016,6),.006,3,WOOD.lightened(float(i%3)*.03))
   for side in [-1.0,1.0]: b.box(Vector3(side*.72,.065,0),Vector3(.06,.13,6),.008,3,WOOD)
   for row in range(4):
    for i in range(row+1):
     Shape.profile(b,[[0,0],[.055,0],[.07,.04],[.065,.12],[.025,.22],[.045,.29],[.035,.34],[0,.35]],Vector3((i-row*.5)*.20,.016,-2.0-row*.22),11,Color("ddd2b8"))
   for x in [-.25,.25]: oval(b,Vector3(x,.10,2),Vector3.ONE*.1,Color("647f88"))
  "formal_parterre":
   for x in [-1.4,1.4]:
    for z in [-1.4,1.4]:
     b.box(Vector3(x,.035,z),Vector3(1.75,.07,1.75),.02,11,Color("b4a485"))
     b.box(Vector3(x,.09,z),Vector3(1.50,.10,1.50),.02,11,Color("675744"))
     for side in [-1,1]:
      for i in range(Shape.n(5,b)):
       var t := -.69+i*1.38/maxi(1,Shape.n(5,b)-1)
       oval(b,Vector3(x+t,.26,z+side*.69),Vector3(.19,.20,.14),GREEN)
       oval(b,Vector3(x+side*.69,.26,z+t),Vector3(.14,.20,.19),GREEN)
     for i in range(Shape.n(5,b)):
      var a := i*2.4
      var p := Vector3(x+cos(a)*.35,.28,z+sin(a)*.35)
      b.beam(p-Vector3(0,.15,0),p,.007,0,GREEN)
      for j in range(5):
       var angle := j*TAU/5
       b.petal(p,Vector3(-sin(angle),0,cos(angle)),Vector3(cos(angle),.3,sin(angle)),.11,.08,.12,Color("b96b8b"),2)
   for x in [-2.2,2.2]:
    for z in [-2.2,2.2]: oval(b,Vector3(x,.43,z),Vector3(.20,.34,.20),GREEN.darkened(.04))

static func collision(id: String) -> Array:
 match id:
  "branch_gate": return [[Vector3(-1.1,.8,0),Vector3(.18,1.6,.18),"box"],[Vector3(1.1,.8,0),Vector3(.18,1.6,.18),"box"]]
  "rustic_arbor","fairy_light_arbor": return [[Vector3(-1.1,1.1,0),Vector3(.20,2.2,.65),"box"],[Vector3(1.1,1.1,0),Vector3(.20,2.2,.65),"box"]]
  "grass_stone_checkerboard": return []
  "garden_chess_set":
   var result := []
   for side in [-1,1]:
    for i in range(8):
     for z in [1.5,2.1]: result.append([Vector3(-2.1+i*.6,.16,z*side),Vector3(.26,.32,.26),"cylinder"])
   return result
  "backyard_bowling_lane": return [[Vector3(-.72,.065,0),Vector3(.06,.13,6),"box"],[Vector3(.72,.065,0),Vector3(.06,.13,6),"box"]]
  "formal_parterre":
   var result := []
   for x in [-1.4,1.4]:
    for z in [-1.4,1.4]: result.append([Vector3(x,.22,z),Vector3(1.75,.44,1.75),"box"])
   return result
  _:
   var dimensions: Vector3 = SIZES[id]
   return [[Vector3(0,dimensions.y*.5,0),dimensions,"cylinder" if id in ["twig_obelisk","willow_basket_planter","willow_teepee_planter"] else "box"]]
