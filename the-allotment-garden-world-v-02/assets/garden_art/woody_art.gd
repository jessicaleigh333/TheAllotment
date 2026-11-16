extends RefCounted
## Stage-specific original woody architecture; native leaf lengths do not scale with tree height.
const Data := preload("res://features/market/woody_growth.gd")
const GREEN := Color("557b48")
const BARK := Color("796046")

static func crown(b: RefCounted, center: Vector3, extent: Vector3, leaves: int, leaf_length: float, oak: bool) -> void:
 var rows: int = [9,6,4][b.detail]
 var columns: int = [17,13,9][b.detail]
 var points := PackedVector3Array()
 for row in range(rows):
  var latitude := row*PI/(rows-1)
  for column in range(columns):
   var a := column*TAU/(columns-1)
   var wave := .90+.07*sin(a*5+latitude*3)+.03*cos(a*9-latitude*7)
   points.append(center+Vector3(cos(a)*sin(latitude)*extent.x*wave,cos(latitude)*extent.y,sin(a)*sin(latitude)*extent.z*wave))
 b.grid(points,rows,columns,0,GREEN.darkened(.08))
 var count := maxi(6,roundi(leaves*[1.,.48,.20][b.detail]))
 for i in range(count):
  var y := 1.-2.*(i+.5)/count
  var a := i*2.39996
  var direction := Vector3(sqrt(1-y*y)*cos(a),y,sqrt(1-y*y)*sin(a))
  var origin := center+direction*extent*.94
  b.leaf(origin,Vector3(cos(a+.8),.2+sin(i)*.3,sin(a+.8)),leaf_length,leaf_length*(.55 if oak else .42),GREEN.lightened((i%4)*.025),1 if oak else 2)

static func shoot(b: RefCounted, id: String, stage: int, origin: Vector3, h: float, w: float, trunk: float) -> void:
 var leafy := stage >= 2
 var ends := PackedVector3Array([origin,origin+Vector3(0,h*.45,0),origin+Vector3(h*.025,h*.88,0)])
 b.tube(ends,PackedFloat32Array([trunk*.65,trunk*.45,trunk*.18]),0,BARK,10 if b.detail == 0 else 6)
 if stage == 1:
  for side in [-1.,1.]: b.leaf(origin+Vector3(0,h*.62,0),Vector3(side,.35,0),h*.40,w*.35,GREEN,1 if id == "tree" else 0)
  return
 if not leafy: return
 var branches := 3 if stage == 2 else (6 if stage == 3 else 10)
 for i in range(branches):
  var a := i*2.4
  var y := h*(.25+.42*i/branches)
  var end := origin+Vector3(cos(a)*w*.35,h*(.55+.24*(i%3)/2),sin(a)*w*.35)
  b.beam(origin+Vector3(0,y,0),end,maxf(.001,trunk*.18),0,BARK,6)
  if stage >= 3 and id == "tree":
   for side in [-1.,1.]:
    b.beam(end,end+Vector3(cos(a+side*.6)*w*.12,h*.11,sin(a+side*.6)*w*.12),trunk*.07,0,BARK,5)
 if id == "tree":
  var count := 1 if stage == 2 else (3 if stage == 3 else 5)
  for i in range(count):
   var a := i*2.4
   var center := origin+Vector3(cos(a)*w*.20,h*(.67+.055*(i%3)),sin(a)*w*.20)
   crown(b,center,Vector3(w*.28,h*.25,w*.28),70 if stage == 2 else 150,.08 if stage == 2 else .12,true)
 elif id == "cypress":
  for i in range(3 if stage == 2 else 6):
   var t := i/float(2 if stage == 2 else 5)
   var width := w*(.46-.30*t)
   crown(b,origin+Vector3(0,h*(.24+.60*t),0),Vector3(width,h*.18,width),55,.045 if stage == 2 else .08,false)
 else:
  for i in range(1 if stage == 2 else 3):
   var a := i*2.4
   crown(b,origin+Vector3(cos(a)*w*.12,h*.57,sin(a)*w*.12),Vector3(w*.38,h*.44,w*.38),(20 if stage == 2 else 35) if id == "hedge" else (65 if stage == 2 else 110),.025,false)

static func build(b: RefCounted, id: String, stage: int, growth_state: Dictionary = {}) -> void:
 var profile: Dictionary = Data.PROFILES[id]
 var h: float = growth_state.get("height",profile.heights[stage])
 var w: float = growth_state.get("width",profile.widths[stage])
 var count := 5 if id == "hedge" else 1
 for i in range(count):
  var origin := Vector3(0,0,(i-2)*.35 if id == "hedge" else 0.)
  if stage == 0:
   var color := Color("9b784d") if id == "tree" else Color("74623e")
   b.lathe(PackedVector2Array([Vector2(0,0),Vector2(w*.35,.001),Vector2(w*.50,h*.45),Vector2(w*.28,h),Vector2(0,h)]),origin,0,color,12)
   if id == "tree": b.lathe(PackedVector2Array([Vector2(0,h*.15),Vector2(w*.40,h*.15),Vector2(w*.40,h*.37),Vector2(0,h*.37)]),origin,0,BARK,12)
  else: shoot(b,id,stage,origin,h,w,growth_state.get("trunk",profile.trunks[stage]))
