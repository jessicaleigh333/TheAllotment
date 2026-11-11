extends RefCounted
## Original woodland gathering/play scenery informed by the owner's screenshots.
const Shape := preload("res://assets/garden_art/french_collection.gd")
const Rustic := preload("res://assets/garden_art/rustic_collection.gd")
const Orbs := preload("res://assets/garden_art/enchanted_collection.gd")
const Builder := preload("res://assets/garden_art/mesh_builder.gd")
const BARK := Color("79624b")
const CUT := Color("c3a477")
const WOOD := Color("a0845e")
const GOLD := Color("e2b66f")
const SIZES := {
 "log_bench":Vector3(2.1,.5,.65),"paddle_back_bench":Vector3(2.1,1.3,.75),"round_log_bench":Vector3(2.1,1.1,.8),"stump_stool":Vector3(.5,.45,.5),
 "branching_picnic_table":Vector3(3.6,.85,3.2),"lantern_picnic_canopy":Vector3(3.6,2.7,2.8),"woodland_potting_station":Vector3(2.5,1.8,.9),"sheltered_workbench":Vector3(2.8,2.8,1.8),
 "tree_trunk_bar":Vector3(3.6,3,3.6),"forest_gathering_deck":Vector3(4,.24,4.9),"stump_balance_trail":Vector3(3,.45,4.8),"log_seesaw":Vector3(3.4,1.1,1.2),"rope_beam_swing":Vector3(4,3.2,1.7)
}
const CATALOG := [
 {"id":"log_bench","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":1.199,"featured":false,"name":"Live-edge stump bench","description":"A broad natural-edge slab on log supports, with visible cut ends and growth rings. Decorative seating."},
 {"id":"paddle_back_bench","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":1.215,"featured":true,"name":"Woodland paddle-back bench","description":"A carved log bench with five paddle-shaped back spindles and branch rails. Decorative seating."},
 {"id":"round_log_bench","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":1.224,"featured":false,"name":"Round-log garden bench","description":"Rounded split-log seats and back rails on four stump legs. Decorative seating."},
 {"id":"stump_stool","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":0.454,"featured":false,"name":"Forest stump stool","description":"A bark-sided stool with a smooth cut top and carved growth rings. Decorative seating."},
 {"id":"branching_picnic_table","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":2.75,"featured":false,"name":"Branching woodland table","description":"An original three-armed timber gathering table with log supports and matching stump seats."},
 {"id":"lantern_picnic_canopy","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":2.38,"featured":true,"name":"Lantern-lit picnic setting","description":"A long table and benches beneath a branch canopy, with warm hanging lanterns that glow at night."},
 {"id":"woodland_potting_station","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":1.429,"featured":false,"name":"Woodland potting station","description":"An outdoor worktable with a shelf, terracotta pots, decorative foliage and hanging hand tools."},
 {"id":"sheltered_workbench","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":1.764,"featured":false,"name":"Sheltered log workbench","description":"A timber workbench under a pitched plank roof with log posts, braces, pots and a tool shelf."},
 {"id":"tree_trunk_bar","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":2.646,"featured":false,"name":"Tree-trunk gathering counter","description":"A freestanding tree-themed counter with its own central trunk and four log stools. Decorative gathering scenery."},
 {"id":"forest_gathering_deck","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":3.263,"featured":true,"name":"Walkable forest gathering deck","description":"A four-metre timber platform with a gentle entry ramp. Walk onto it and build on its flat top."},
 {"id":"stump_balance_trail","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":3.20,"featured":true,"name":"Walkable stump balance trail","description":"Zigzag wooden beams between stump supports, with an entry ramp. Follow the beams using normal walking controls."},
 {"id":"log_seesaw","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":1.903,"featured":false,"name":"Rustic log seesaw display","description":"A complete log seesaw with handles, seats and a pivot support. Decorative; riding is not connected."},
 {"id":"rope_beam_swing","category":"Decor","price":0,"icon":0,"family":"Woodland gathering play inspiration","inspiration":"Owner-shared woodland reference screenshots","radius":2.273,"featured":false,"name":"Woodland rope-swing display","description":"A tall central log with a cross beam and two suspended seats. Decorative; riding is not connected."}
]
const GLOW := {"lantern_picnic_canopy":Vector3(0,2.05,0)}
const TRAIL := [Vector3(-1,.37,-1.85),Vector3(1,.37,-.85),Vector3(-1,.37,.15),Vector3(1,.37,1.15)]

static func block(b: RefCounted, center: Vector3, size: Vector3, rotation: Vector3 = Vector3.ZERO, color: Color = WOOD) -> void:
 var part := Builder.new(b.detail)
 part.box(Vector3.ZERO,size,.015,3,color)
 b.merge(part,Transform3D(Basis.from_euler(rotation),center))

static func disk(b: RefCounted, center: Vector3, normal: Vector3, radius: float) -> void:
 var part := Builder.new(b.detail)
 Shape.profile(part,[[0,0],[radius,0],[radius,.006],[0,.006]],Vector3.ZERO,11,CUT)
 b.merge(part,Transform3D(Basis(Quaternion(Vector3.UP,normal)),center))
 var right := normal.cross(Vector3.FORWARD).normalized()
 if right.length_squared() < .1: right = Vector3.RIGHT
 var up := normal.cross(right).normalized()
 for i in range(1,4):
  var points := PackedVector3Array()
  var radii := PackedFloat32Array()
  var count: int = [25,17,9][b.detail]
  for j in range(count):
   var a := j*TAU/(count-1)
   points.append(center+normal*.008+(right*cos(a)+up*sin(a))*radius*i/4)
   radii.append(.0015)
  b.tube(points,radii,11,CUT.darkened(.16),4)

static func log_piece(b: RefCounted, a: Vector3, end: Vector3, radius: float) -> void:
 var direction := (end-a).normalized()
 b.tube(PackedVector3Array([a,a.lerp(end,.5)+Vector3(.012,0,.009),end]),PackedFloat32Array([radius,radius*1.025,radius*.96]),3,BARK,12)
 disk(b,a-direction*.003,-direction,radius)
 disk(b,end,direction,radius*.96)

static func stool(b: RefCounted, origin: Vector3, height: float = .45, radius: float = .23) -> void:
 log_piece(b,origin+Vector3(0,.01,0),origin+Vector3(0,height-.01,0),radius)

static func plank(b: RefCounted, a: Vector3, end: Vector3, width: float, thickness: float = .08) -> void:
 var direction := (end-a).normalized()
 var rotation := Basis(Quaternion(Vector3.RIGHT,direction)).get_euler()
 block(b,(a+end)*.5,Vector3(a.distance_to(end),thickness,width),rotation)

static func bench(b: RefCounted, type: int) -> void:
 for x in [-.72,.72]:
  for z in [-.20,.20]: stool(b,Vector3(x,0,z),.4,.105)
 if type == 2:
  for z in [-.18,.02,.22]: log_piece(b,Vector3(-1,.43,z),Vector3(1,.43,z),.105)
 else:
  block(b,Vector3(0,.45,0),Vector3(2.1,.10,.60))
  Rustic.branch(b,Vector3(-1.05,.43,-.29),Vector3(1.05,.44,-.29),.035)
  Rustic.branch(b,Vector3(-1.05,.43,.29),Vector3(1.05,.44,.29),.035)
 if type > 0:
  for x in [-.88,.88]: log_piece(b,Vector3(x,.35,-.27),Vector3(x,1.15,-.27),.045)
  if type == 1:
   for i in range(5):
    var x := -.62+i*.31
    Rustic.branch(b,Vector3(x,.5,-.27),Vector3(x,1.12,-.27),.018)
    Orbs.orb(b,Vector3(x,.89,-.27),Vector3(.09,.19,.032),CUT,11)
   Rustic.branch(b,Vector3(-.95,1.18,-.27),Vector3(.95,1.18,-.27),.04)
  else:
   for y in [.76,1.02]: log_piece(b,Vector3(-1,y,-.29),Vector3(1,y,-.29),.08)

static func table(b: RefCounted, length: float = 2.8, width: float = 1.0) -> void:
 for x in [-length*.36,length*.36]:
  for z in [-width*.35,width*.35]: log_piece(b,Vector3(x,0,z),Vector3(x,.72,z),.065)
 for i in range(5): block(b,Vector3(0,.78,-width*.4+i*width*.2),Vector3(length,.08,width*.19))
 for x in [-length*.35,length*.35]: Rustic.branch(b,Vector3(x,0,-width*.3),Vector3(x,.65,width*.3),.035)

static func pot(b: RefCounted, origin: Vector3, scale: float = 1) -> void:
 Shape.profile(b,[[.08,0],[.12,.18],[.13,.20],[.10,.21],[.075,.05],[0,.04]],origin,11,Color("b87e55"),Vector2.ONE*scale)
 for i in range(Shape.n(7,b)): b.leaf(origin+Vector3(0,.16,0),Vector3(cos(i*2.4),.7,sin(i*2.4)),.20,.10,Color("66835a"),1)

static func ramp(b: RefCounted, center: Vector3, width: float, depth: float, height: float) -> void:
 # The visible planks and physics wedge share these endpoints.
 var points := PackedVector3Array([center+Vector3(width*.5,height,-depth*.5),center+Vector3(-width*.5,height,-depth*.5),center+Vector3(width*.5,0,depth*.5),center+Vector3(-width*.5,0,depth*.5)])
 b.grid(points,2,2,3,WOOD)
 for x in [-width*.5,width*.5]: Rustic.branch(b,center+Vector3(x,height-.018,-depth*.5),center+Vector3(x,.018,depth*.5),.008)

static func lantern(b: RefCounted, origin: Vector3) -> void:
 Shape.profile(b,[[0,0],[.10,0],[.10,.04],[.08,.07],[0,.07]],origin,5,Color("88744f"))
 Shape.profile(b,[[0,.25],[.11,.25],[.11,.28],[0,.36]],origin,5,Color("88744f"))
 for x in [-.065,.065]:
  for z in [-.065,.065]: b.beam(origin+Vector3(x,.06,z),origin+Vector3(x,.26,z),.008,5,Color("88744f"),6)
 Orbs.orb(b,origin+Vector3(0,.16,0),Vector3(.065,.09,.065),GOLD,13)
 Shape.ring(b,origin+Vector3(0,.39,0),.06,Vector3.RIGHT,Vector3.UP,.008,5,Color("88744f"))

static func build(b: RefCounted, id: String) -> void:
 match id:
  "log_bench": bench(b,0)
  "paddle_back_bench": bench(b,1)
  "round_log_bench": bench(b,2)
  "stump_stool": stool(b,Vector3.ZERO)
  "branching_picnic_table":
   stool(b,Vector3.ZERO,.73,.24)
   for i in range(3):
    var a := i*TAU/3
    var end := Vector3(cos(a)*1.55,.78,sin(a)*1.55)
    plank(b,Vector3(0,.78,0),end,.58)
    log_piece(b,Vector3(end.x,0,end.z),Vector3(end.x,.72,end.z),.10)
    stool(b,Vector3(cos(a)*1.25,.0,sin(a)*1.25)+Vector3(cos(a+PI/2)*.62,0,sin(a+PI/2)*.62),.44,.23)
  "lantern_picnic_canopy":
   table(b,2.8,1)
   for z in [-.95,.95]:
    block(b,Vector3(0,.44,z),Vector3(2.8,.10,.34))
    for x in [-1.05,1.05]: log_piece(b,Vector3(x,0,z),Vector3(x,.4,z),.08)
   for x in [-1.65,1.65]:
    for z in [-1.2,1.2]: log_piece(b,Vector3(x,0,z),Vector3(x,2.6,z),.055)
   for z in [-1.2,1.2]: log_piece(b,Vector3(-1.7,2.58,z),Vector3(1.7,2.58,z),.04)
   for x in [-1.6,0,1.6]: log_piece(b,Vector3(x,2.58,-1.2),Vector3(x,2.58,1.2),.025)
   for x in [-1.05,0,1.05]:
    Rustic.branch(b,Vector3(x,2.58,0),Vector3(x,2.13,0),.008,Color("8b785a"))
    lantern(b,Vector3(x,1.72,0))
  "woodland_potting_station","sheltered_workbench":
   table(b,2.3,.8)
   for x in [-1.05,1.05]: log_piece(b,Vector3(x,.7,-.35),Vector3(x,1.65,-.35),.05)
   for y in [1.1,1.55]: block(b,Vector3(0,y,-.35),Vector3(2.4,.07,.25))
   for i in range(5): pot(b,Vector3(-.84+i*.42,1.585,-.35))
   for x in [-.5,0,.5]:
    Rustic.branch(b,Vector3(x,1.05,-.22),Vector3(x,1.40,-.22),.012)
    block(b,Vector3(x,1.04,-.22),Vector3(.075,.15,.025),Vector3.ZERO,Color("7d8580"))
   if id == "sheltered_workbench":
    for x in [-1.25,1.25]:
     for z in [-.68,.68]: log_piece(b,Vector3(x,0,z),Vector3(x,2.35,z),.065)
    for side in [-1.0,1.0]:
     for i in range(10):
      var z := -.80+i*.177
      plank(b,Vector3(0,2.74,z),Vector3(side*1.4,2.30,z),.17,.065)
  "tree_trunk_bar":
   log_piece(b,Vector3(0,0,0),Vector3(0,2.9,0),.23)
   for side in [-1.0,1.0]: Rustic.branch(b,Vector3(0,2.1,0),Vector3(side*.55,2.75,.25),.065)
   for side in [-1.0,1.0]:
    block(b,Vector3(side*1.02,.96,0),Vector3(.48,.10,2.5))
    block(b,Vector3(0,.96,side*1.02),Vector3(2.5,.10,.48))
    for i in range(10):
     block(b,Vector3(side*.94,.48,-1.1+i*.245),Vector3(.07,.88,.22),Vector3.ZERO,Color("6d9290") if i%3 == 0 else WOOD)
     block(b,Vector3(-1.1+i*.245,.48,side*.94),Vector3(.22,.88,.07),Vector3.ZERO,Color("6d9290") if i%3 == 0 else WOOD)
   for i in range(4):
    var a := i*TAU/4
    stool(b,Vector3(cos(a)*1.55,0,sin(a)*1.55),.55,.22)
  "forest_gathering_deck":
   for i in range(16): block(b,Vector3(-1.875+i*.25,.20,-.45),Vector3(.245,.08,4))
   for x in [-1.7,1.7]:
    for z in [-2.1,1.2]: stool(b,Vector3(x,0,z),.16,.13)
   ramp(b,Vector3(0,0,2),1.3,.9,.24)
  "stump_balance_trail":
   for p in TRAIL: stool(b,Vector3(p.x,0,p.z),.37,.20)
   for i in range(3): plank(b,TRAIL[i]+Vector3(0,.04,0),TRAIL[i+1]+Vector3(0,.04,0),.28)
   block(b,Vector3(1,.41,1.38),Vector3(.40,.08,.64))
   ramp(b,Vector3(1,0,2.05),.40,.7,.45)
  "log_seesaw":
   log_piece(b,Vector3(0,.25,-.45),Vector3(0,.25,.45),.22)
   block(b,Vector3(0,.65,0),Vector3(3.2,.12,.30),Vector3(0,0,.15))
   for side in [-1.0,1.0]:
    var y: float = .65+side*.20
    block(b,Vector3(side*1.3,y,.0),Vector3(.42,.06,.48),Vector3(0,0,.15))
    Rustic.branch(b,Vector3(side*.96,y,0),Vector3(side*.96,y+.27,0),.025)
    log_piece(b,Vector3(side*.96,y+.27,-.12),Vector3(side*.96,y+.27,.12),.02)
  "rope_beam_swing":
   log_piece(b,Vector3(0,0,0),Vector3(0,3.0,0),.14)
   log_piece(b,Vector3(-1.9,2.9,0),Vector3(1.9,2.9,0),.10)
   for side in [-1.0,1.0]:
    for z in [-.2,.2]: Rustic.branch(b,Vector3(side*1.65,2.85,z*.25),Vector3(side*1.65,.7,z),.012,Color("b8a784"))
    block(b,Vector3(side*1.65,.67,0),Vector3(.48,.07,.55))

static func collision(id: String) -> Array:
 match id:
  "log_bench","paddle_back_bench","round_log_bench": return [[Vector3(0,.43,0),Vector3(2.1,.14,.65),"box"],[Vector3(-.72,.2,0),Vector3(.25,.4,.55),"box"],[Vector3(.72,.2,0),Vector3(.25,.4,.55),"box"]]
  "branching_picnic_table":
   var result := [[Vector3(0,.365,0),Vector3(.48,.73,.48),"cylinder"]]
   for i in range(3):
    var a := i*TAU/3
    var end := Vector3(cos(a)*1.55,.78,sin(a)*1.55)
    result.append([Vector3(end.x*.5,.78,end.z*.5),Vector3(1.55,.08,.58),"box",Vector3(0,-a,0)])
    result.append([Vector3(end.x,.36,end.z),Vector3(.20,.72,.20),"cylinder"])
    result.append([Vector3(cos(a)*1.25+cos(a+PI/2)*.62,.22,sin(a)*1.25+sin(a+PI/2)*.62),Vector3(.46,.44,.46),"cylinder"])
   return result
  "stump_stool": return [[Vector3(0,.225,0),Vector3(.46,.45,.46),"cylinder"]]
  "forest_gathering_deck": return [[Vector3(0,.12,-.45),Vector3(4,.24,4),"box"],[Vector3(0,.12,2),Vector3(1.3,.24,.9),"ramp"]]
  "stump_balance_trail":
   var result := []
   for p in TRAIL: result.append([Vector3(p.x,.185,p.z),Vector3(.4,.37,.4),"cylinder"])
   for i in range(3):
    var direction: Vector3 = TRAIL[i+1]-TRAIL[i]
    result.append([(TRAIL[i]+TRAIL[i+1])*.5+Vector3(0,.04,0),Vector3(direction.length(),.08,.28),"box",Vector3(0,atan2(-direction.z,direction.x),0)])
   result.append([Vector3(1,.41,1.38),Vector3(.40,.08,.64),"box"])
   result.append([Vector3(1,.225,2.05),Vector3(.40,.45,.7),"ramp"])
   return result
  "rope_beam_swing": return [[Vector3(0,1.5,0),Vector3(.28,3,.28),"cylinder"],[Vector3(-1.65,.67,0),Vector3(.48,.07,.55),"box"],[Vector3(1.65,.67,0),Vector3(.48,.07,.55),"box"]]
  "log_seesaw": return [[Vector3(0,.25,0),Vector3(.45,.5,.9),"box"],[Vector3(0,.65,0),Vector3(3.2,.12,.30),"box",Vector3(0,0,.15)]]
  "tree_trunk_bar":
   var result := [[Vector3(0,1.45,0),Vector3(.46,2.9,.46),"cylinder"]]
   for side in [-1,1]:
    result.append([Vector3(side*1.02,.5,0),Vector3(.5,1,2.5),"box"])
    result.append([Vector3(0,.5,side*1.02),Vector3(2.5,1,.5),"box"])
   return result
  _:
   var result := [[Vector3(0,.40,0),Vector3(2.8,.8,1),"box"]]
   if id == "lantern_picnic_canopy":
    for z in [-.95,.95]: result.append([Vector3(0,.44,z),Vector3(2.8,.12,.34),"box"])
    for x in [-1.65,1.65]:
     for z in [-1.2,1.2]: result.append([Vector3(x,1.3,z),Vector3(.14,2.6,.14),"box"])
   if id == "sheltered_workbench":
    for x in [-1.25,1.25]:
     for z in [-.68,.68]: result.append([Vector3(x,1.2,z),Vector3(.16,2.4,.16),"box"])
   return result
