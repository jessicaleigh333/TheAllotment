extends RefCounted
## Original metre-scale stems, alternating leaves and species-specific flowers.
const COLORS := {"climbing_rose":Color("d993aa"),"clematis":Color("a17bc3"),"honeysuckle":Color("efdeb1"),"ivy":Color("638356"),"wisteria":Color("b19ad0")}
static func flower(b: RefCounted, plant: String, center: Vector3) -> void:
 if plant == "ivy": return
 var color: Color = COLORS[plant]
 if plant == "wisteria":
  for j in range(7 if b.detail == 0 else 4):
   var r := .055-j*.005
   for side in range(3):
    var a := side*TAU/3+j*.5
    b.petal(center+Vector3(0,-j*.04,0),Vector3(-sin(a),0,cos(a)),Vector3(cos(a),-.7,sin(a)),.065,r,.3,color)
  return
 for i in range(7 if plant == "climbing_rose" else 6):
  var a := i*TAU/(7 if plant == "climbing_rose" else 6)
  var direction := Vector3(cos(a),.18,sin(a))
  b.petal(center,Vector3(-sin(a),0,cos(a)),direction,.075 if plant == "climbing_rose" else .095,.055,.35,color.lightened((i%2)*.07))
 b.beam(center,center+Vector3(0,.018,0),.018,2,Color("d7b65d"),6)

static func trained(b: RefCounted, plant: String, route: PackedVector3Array, reach: float, stage: int) -> void:
 if route.size() < 2 or reach <= 0: return
 var points := PackedVector3Array([route[0]])
 var remaining := reach
 # Resample by real distance so leaves and path tips do not pop with stage changes.
 for i in range(1,route.size()):
  var a: Vector3 = route[i-1]
  var distance := a.distance_to(route[i])
  if distance < .0001: continue
  var used := minf(remaining,distance)
  var steps := maxi(1,ceili(used/.085))
  for j in range(1,steps+1): points.append(a.lerp(route[i],used/distance*j/steps))
  remaining -= used
  if remaining <= .0001: break
 if points.size() < 2: return
 for stem in range(2 if b.detail < 2 else 1):
  var stem_points := PackedVector3Array()
  var radii := PackedFloat32Array()
  for i in range(points.size()):
   stem_points.append(points[i]+Vector3(sin(i*.8+stem*PI)*.025,0,cos(i*.8+stem*PI)*.025))
   radii.append(lerpf(.009,.003,i/float(points.size()-1)))
  b.tube(stem_points,radii,0,Color("667349"),6 if b.detail == 0 else 4)
 var stride: int = [2,3,5][b.detail]
 for i in range(1,points.size(),stride):
  var a := i*2.4
  var dir := Vector3(cos(a),.25,sin(a))
  var center: Vector3 = points[i]
  var green := Color("52774b") if plant == "ivy" else Color("668655")
  b.leaf(center,dir,.16 if stage >= 3 else .09,.075,green.lightened((i%3)*.035),2 if plant == "ivy" else 0)
  b.leaf(center,-dir+Vector3(0,.25,0),.12,.055,green,0)
  var flower_tip := center+dir*.10
  if stage >= 3:
   var shoot := center+dir*.26+Vector3(0,.05,0)
   b.beam(center,shoot,.004,0,Color("667349"),4)
   b.leaf(center.lerp(shoot,.55),dir.rotated(Vector3.UP,1.1),.16,.075,green,2 if plant == "ivy" else 0)
   b.leaf(shoot,dir.rotated(Vector3.UP,-.8),.18,.08,green.lightened(.04),0)
   flower_tip = shoot
  if stage >= (4 if plant == "wisteria" else 3) and i% (stride*3) == 1: flower(b,plant,flower_tip)

static func standalone(b: RefCounted, plant: String, stage: int) -> void:
 if stage == 0:
  b.lathe(PackedVector2Array([Vector2(0,0),Vector2(.05,0),Vector2(.05,.006),Vector2(0,.012)]),Vector3.ZERO,4,Color("69513c"),12)
  return
 var path := PackedVector3Array([Vector3(0,0,0),Vector3(.06,.3,.03),Vector3(-.03,.55,0),Vector3(.08,.7,.03)])
 trained(b,plant,path,1.,stage)
 # A low, self-supporting crown remains at the roots; trained stems use a separate child.
 for side in [-1.,1.]:
  trained(b,plant,PackedVector3Array([Vector3.ZERO,Vector3(side*.12,.22,side*.06),Vector3(side*.24,.4,side*.12)]),.6,stage)
