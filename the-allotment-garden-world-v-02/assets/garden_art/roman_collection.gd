extends RefCounted
## Original Roman-order garden architecture with flat assembly interfaces.
const Sculpt := preload("res://assets/garden_art/french_collection.gd")
const STONE := Color("c4b99f")
const SIZES := {
 "roman_plinth":Vector3(.9,.22,.9),"attic_column_base":Vector3(.85,.28,.85),
 "plain_column_drum":Vector3(.6,1,.6),"fluted_column_drum":Vector3(.6,1,.6),"short_column_drum":Vector3(.6,.5,.6),
 "doric_capital":Vector3(.9,.3,.9),"ionic_capital":Vector3(1,.4,.8),"corinthian_capital":Vector3(1,.6,1),
 "doric_column":Vector3(.9,3.2,.9),"ionic_column":Vector3(1,3.6,1),"corinthian_column":Vector3(1,4,1),
 "roman_architrave":Vector3(3,.35,.8),"stone_cornice":Vector3(1.2,.25,1.2),"roman_pedestal":Vector3(.8,1,.8)
}
const CATALOG := [
 {"id":"roman_plinth","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.716,"featured":false,"name":"Roman square plinth","description":"A molded square foundation. Stack a base, shaft, capital or sculpture on its flat top."},
 {"id":"attic_column_base","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.681,"featured":false,"name":"Attic-style column base","description":"A square plinth with turned torus and scotia moldings. Fits the shaft sections."},
 {"id":"plain_column_drum","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.504,"featured":false,"name":"Plain column shaft · 1 m","description":"A one-metre cylindrical shaft section with true flat ends for vertical stacking."},
 {"id":"fluted_column_drum","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.504,"featured":true,"name":"Fluted column shaft · 1 m","description":"A one-metre shaft with carved vertical flutes and flat assembly ends."},
 {"id":"short_column_drum","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.504,"featured":false,"name":"Fluted half-shaft · 0.5 m","description":"A half-metre shaft section for choosing the height of a column."},
 {"id":"doric_capital","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.716,"featured":false,"name":"Doric-style capital","description":"A rounded echinus and square abacus. Fits shaft sections and supports a beam or ornament."},
 {"id":"ionic_capital","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.72,"featured":true,"name":"Ionic-style capital","description":"Paired carved volutes beneath a rectangular abacus. Fits the column shafts."},
 {"id":"corinthian_capital","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.787,"featured":false,"name":"Corinthian-style capital","description":"Two tiers of carved acanthus leaves and an open, molded abacus."},
 {"id":"doric_column","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.716,"featured":false,"name":"Complete Doric-style column","description":"A 3.2 m column with base, fluted shaft and Doric capital. Its flat top supports further pieces."},
 {"id":"ionic_column","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.787,"featured":false,"name":"Complete Ionic-style column","description":"A 3.6 m column with a molded base and scroll capital. Can support a beam or decoration."},
 {"id":"corinthian_column","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.787,"featured":true,"name":"Complete Corinthian-style column","description":"A 4 m column with a fluted shaft and carved acanthus capital."},
 {"id":"roman_architrave","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":1.632,"featured":false,"name":"Roman architrave beam","description":"A 3 m molded stone beam. Stack it across two level column tops; it needs support near both ends."},
 {"id":"stone_cornice","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.929,"featured":false,"name":"Carved cornice slab","description":"A flat-topped molded stone slab for building a wider top above a column or pedestal."},
 {"id":"roman_pedestal","category":"Decor","price":0,"icon":0,"family":"Roman building","inspiration":"Roman orders in classical garden architecture","radius":0.646,"featured":false,"name":"Roman panel pedestal","description":"A one-metre stone pedestal with recessed panels and rosettes. Supports sculpture, pots and columns."}
]

static func lathe(b: RefCounted, values: Array, y: float = 0) -> void:
 Sculpt.profile(b,values,Vector3(0,y,0),11,STONE)

static func shaft(b: RefCounted, height: float, y: float, fluted: bool) -> void:
 var points := PackedVector3Array()
 var rows := 9 if b.detail == 0 else 5
 var sides: int = [120,72,48][b.detail]
 for row in range(rows):
  var t := float(row)/(rows-1)
  for column in range(sides+1):
   var a := float(column)*TAU/sides
   var radius := .295+sin(t*PI)*.005
   if fluted: radius -= .018*pow((cos(a*24)+1)*.5,2)*sin(t*PI)
   points.append(Vector3(cos(a)*radius,y+t*height,-sin(a)*radius))
 b.grid(points,rows,sides+1,11,STONE)
 # Flat disks close the shaft without rounded caps or vertical gaps.
 lathe(b,[[0,y],[.295,y]])
 lathe(b,[[.295,y+height],[0,y+height]])

static func base(b: RefCounted, y: float = 0) -> void:
 b.box(Vector3(0,y+.045,0),Vector3(.85,.09,.85),.018,11,STONE)
 lathe(b,[[0,y+.09],[.36,y+.09],[.39,y+.12],[.39,y+.15],[.33,y+.19],[.31,y+.22],[.34,y+.25],[.34,y+.28],[0,y+.28]])

static func capital(b: RefCounted, style: String, y: float) -> void:
 var height := .3 if style == "doric" else (.4 if style == "ionic" else .6)
 lathe(b,[[0,y],[.29,y],[.29,y+.06],[.34,y+.10],[.37,y+height-.10],[0,y+height-.10]])
 var width := .9 if style == "doric" else 1.0
 var depth := .8 if style == "ionic" else width
 b.box(Vector3(0,y+height-.045,0),Vector3(width,.09,depth),.018,11,STONE)
 if style == "ionic":
  for x in [-.32,.32]:
   for z in [-.31,.31]:
    var points := PackedVector3Array()
    var radii := PackedFloat32Array()
    var count := Sculpt.n(35,b)
    for i in range(count):
     var t := float(i)/(count-1)
     var a := t*TAU*1.6
     var r := .14*(1-t*.91)
     points.append(Vector3(x+cos(a)*r,y+.22+sin(a)*r,z))
     radii.append(.018)
    b.tube(points,radii,11,STONE,6)
 elif style == "corinthian":
  for tier in range(2):
   for i in range(Sculpt.n(16,b)):
    var a := (float(i)+tier*.5)*TAU/Sculpt.n(16,b)
    var radial := Vector3(cos(a),0,sin(a))
    var side := Vector3(sin(a),0,-cos(a))
    var points := PackedVector3Array()
    var rows := 9 if b.detail == 0 else 5
    var columns := 5 if b.detail == 0 else 3
    for row in range(rows):
     var t := float(row)/(rows-1)
     var breadth := pow(maxf(.01,sin(t*PI)),.5)*(.78+.22*cos(t*PI*8))
     for column in range(columns):
      var u := float(column)/(columns-1)*2-1
      var center := radial*(.33+tier*.01+.13*t+.03*t*t)+Vector3(0,y+.045+tier*.18+.30*t-.05*t*t,0)
      points.append(center+side*u*.085*breadth+radial*(1-absf(u))*.012*sin(t*PI))
    b.grid(points,rows,columns,11,STONE.lightened(float(i%3)*.025))
    b.beam(radial*(.34+tier*.01)+Vector3(0,y+.06+tier*.18,0),radial*(.47+tier*.01)+Vector3(0,y+.28+tier*.18,0),.008,11,STONE.lightened(.04),5)

static func build(b: RefCounted, id: String) -> void:
 match id:
  "roman_plinth":
   for data in [[.9,.08,0],[.78,.08,.08],[.88,.06,.16]]:
    b.box(Vector3(0,data[2]+data[1]*.5,0),Vector3(data[0],data[1],data[0]),.014,11,STONE)
  "attic_column_base": base(b)
  "plain_column_drum","fluted_column_drum","short_column_drum": shaft(b,.5 if id == "short_column_drum" else 1,0,id != "plain_column_drum")
  "doric_capital","ionic_capital","corinthian_capital": capital(b,id.get_slice("_",0),0)
  "doric_column","ionic_column","corinthian_column":
   var style := id.get_slice("_",0)
   var height: float = SIZES[id].y
   var capital_height := .3 if style == "doric" else (.4 if style == "ionic" else .6)
   base(b)
   shaft(b,height-.28-capital_height,.28,true)
   capital(b,style,height-capital_height)
  "roman_architrave":
   for data in [[.0,.08,3.0,.8],[.08,.18,2.94,.74],[.26,.09,3.0,.8]]:
    b.box(Vector3(0,data[0]+data[1]*.5,0),Vector3(data[2],data[1],data[3]),.012,11,STONE)
   for side in [-1.0,1.0]:
    for i in range(Sculpt.n(21,b)):
     b.box(Vector3(-1.42+float(i)*2.84/maxi(1,Sculpt.n(21,b)-1),.22,side*.39),Vector3(.07,.08,.035),.005,11,STONE.lightened(.04))
  "stone_cornice":
   for data in [[1.0,.07,0],[1.1,.10,.07],[1.2,.08,.17]]:
    b.box(Vector3(0,data[2]+data[1]*.5,0),Vector3(data[0],data[1],data[0]),.018,11,STONE)
  "roman_pedestal":
   b.box(Vector3(0,.5,0),Vector3(.64,.85,.64),.02,11,STONE.darkened(.04))
   for y in [.05,.95]: b.box(Vector3(0,y,0),Vector3(.8,.1,.8),.02,11,STONE)
   for side in [-1.0,1.0]:
    for x in [-.25,.25]: b.box(Vector3(x,.5,side*.33),Vector3(.045,.72,.035),.007,11,STONE)
    Sculpt.rosette(b,Vector3(0,.5,side*.33),.19,STONE,Vector3(0,0,side))

static func collision(id: String) -> Array:
 var size: Vector3 = SIZES[id]
 if id in ["doric_column","ionic_column","corinthian_column"]:
  return [[Vector3(0,size.y*.5,0),Vector3(.6,size.y,.6),"cylinder"],[Vector3(0,.07,0),Vector3(.85,.14,.85),"box"],[Vector3(0,size.y-.06,0),Vector3(size.x,.12,size.z),"box"]]
 if id.ends_with("drum"): return [[Vector3(0,size.y*.5,0),size,"cylinder"]]
 return [[Vector3(0,size.y*.5,0),size,"box"]]
