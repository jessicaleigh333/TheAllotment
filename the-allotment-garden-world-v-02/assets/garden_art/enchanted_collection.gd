extends RefCounted
## Original cozy witch / fairy decorations. Emissive trim uses material role 13.
const Shape := preload("res://assets/garden_art/french_collection.gd")
const WOOD := Color("6e5967")
const IRON := Color("404956")
const GOLD := Color("b99a64")
const CYAN := Color("57e7d9")
const PINK := Color("ed77cf")
const VIOLET := Color("a98aff")
const MINT := Color("8beac2")
const SIZES := {
 "glow_mushrooms":Vector3(.9,.7,.9),"fairy_mushroom_house":Vector3(1,1.1,1),"fairy_ring":Vector3(2.4,.5,2.4),"crystal_cluster":Vector3(.8,1.2,.8),
 "moon_lantern":Vector3(.6,1.8,.5),"witch_cauldron":Vector3(.9,.85,.85),"witch_hat_planter":Vector3(.8,.7,.8),"spellbook_pedestal":Vector3(.7,1.2,.65),
 "crescent_moon_statue":Vector3(.9,1.8,.55),"fairy_door":Vector3(.55,.8,.25),"enchanted_tree":Vector3(2.4,3,2.4),"star_mobile":Vector3(.7,1.7,.7),
 "rune_obelisk":Vector3(.65,1.9,.65),"lotus_lamp":Vector3(.7,.45,.7),"firefly_jar":Vector3(.35,.6,.35),"fairy_well":Vector3(1.6,1.9,1.4),
 "moon_arch":Vector3(2.8,3,.8),"potion_shelf":Vector3(1.1,1.6,.5)
}
const CATALOG := [
 {"id":"glow_mushrooms","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.716,"featured":false,"name":"Neon toadstool cluster","description":"Three sculpted mushrooms with luminous gills and glowing cap freckles."},
 {"id":"fairy_mushroom_house","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.787,"featured":true,"name":"Fairy mushroom cottage","description":"A tiny mushroom home with an arched door, chimney, garden steps and softly glowing windows."},
 {"id":"fairy_ring","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":1.777,"featured":false,"name":"Moonlit fairy ring","description":"A circle of tiny glowing mushrooms with an open centre and two entrance gaps."},
 {"id":"crystal_cluster","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.646,"featured":true,"name":"Twilight crystal cluster","description":"Faceted amethyst and mint crystals, with luminous edges on a dark stone base."},
 {"id":"moon_lantern","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.471,"featured":false,"name":"Crescent lantern post","description":"A curled iron post carrying a crescent moon and a suspended violet lantern."},
 {"id":"witch_cauldron","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.699,"featured":true,"name":"Starlight garden cauldron","description":"A three-legged garden cauldron with moon handles, luminous potion and floating bubbles."},
 {"id":"witch_hat_planter","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.646,"featured":false,"name":"Witch-hat flower planter","description":"An upturned hat planter with a starry ribbon, curled brim and decorative flowers."},
 {"id":"spellbook_pedestal","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.558,"featured":false,"name":"Moon spellbook pedestal","description":"An open carved garden spellbook with embossed pages and softly glowing star motifs."},
 {"id":"crescent_moon_statue","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.607,"featured":false,"name":"Crescent moon sculpture","description":"A gilded crescent on a stone plinth, edged with soft cyan light."},
 {"id":"fairy_door","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.382,"featured":false,"name":"Secret fairy door","description":"A tiny standalone arched door with curled hinges, a moon knocker and illuminated trim."},
 {"id":"enchanted_tree","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":1.777,"featured":false,"name":"Star-blossom enchanted tree","description":"A twisting small tree with purple leaves, star charms and glowing blossom orbs."},
 {"id":"star_mobile","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.575,"featured":false,"name":"Garden star mobile","description":"A freestanding curved hanger with suspended moons and luminous stars."},
 {"id":"rune_obelisk","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.54,"featured":false,"name":"Glowing garden sigil stone","description":"An original decorative stone obelisk with invented botanical sigils traced in neon."},
 {"id":"lotus_lamp","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.575,"featured":false,"name":"Fairy lotus lamp","description":"Layered pink-violet petals shelter a luminous turquoise centre."},
 {"id":"firefly_jar","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.327,"featured":false,"name":"Firefly lantern jar","description":"A ribbed lantern jar with a loop handle and tiny floating lights inside."},
 {"id":"fairy_well","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":1.143,"featured":false,"name":"Wishing-star fairy well","description":"A low stone wishing well, a timber canopy, suspended bucket and glowing water."},
 {"id":"moon_arch","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":1.536,"featured":true,"name":"Moon-and-stars garden arch","description":"A walk-through iron arch with crescent crest, climbing leaves and suspended star lights."},
 {"id":"potion_shelf","category":"Decor","price":0,"icon":0,"family":"Witchy fairy night glow","inspiration":"Whimsical storybook moon gardens","radius":0.684,"featured":false,"name":"Witch's garden potion shelf","description":"A freestanding timber shelf with glowing glass-like bottles, herb bundles and a tiny spell label."}
]
const COLORS := {"glow_mushrooms":MINT,"fairy_mushroom_house":PINK,"fairy_ring":CYAN,"crystal_cluster":VIOLET,"moon_lantern":VIOLET,"witch_cauldron":MINT,"witch_hat_planter":PINK,"spellbook_pedestal":VIOLET,"crescent_moon_statue":CYAN,"fairy_door":PINK,"enchanted_tree":VIOLET,"star_mobile":GOLD,"rune_obelisk":CYAN,"lotus_lamp":PINK,"firefly_jar":MINT,"fairy_well":CYAN,"moon_arch":VIOLET,"potion_shelf":PINK}
# Local, fitted metre-space anchors for halos and one budgeted pool of light per object.
const ANCHORS := {"glow_mushrooms":Vector3(0,.4,0),"fairy_mushroom_house":Vector3(0,.48,.3),"fairy_ring":Vector3(0,.18,0),"crystal_cluster":Vector3(0,.7,0),"moon_lantern":Vector3(0,1.10,0),"witch_cauldron":Vector3(0,.65,0),"witch_hat_planter":Vector3(0,.45,0),"spellbook_pedestal":Vector3(0,1.1,0),"crescent_moon_statue":Vector3(0,1.2,0),"fairy_door":Vector3(0,.42,.1),"enchanted_tree":Vector3(0,2,0),"star_mobile":Vector3(0,1.15,0),"rune_obelisk":Vector3(0,1.15,.25),"lotus_lamp":Vector3(0,.22,0),"firefly_jar":Vector3(0,.3,0),"fairy_well":Vector3(0,.3,0),"moon_arch":Vector3(0,2.45,0),"potion_shelf":Vector3(0,.95,.10)}
const FEET := {"glow_mushrooms":.25,"crystal_cluster":.3,"witch_hat_planter":.25,"spellbook_pedestal":.25,"crescent_moon_statue":.25,"lotus_lamp":.22,"firefly_jar":.14,"rune_obelisk":.28}

static func orb(b: RefCounted, center: Vector3, size: Vector3, color: Color, role: int = 13) -> void:
 var small := maxf(size.x,maxf(size.y,size.z)) < .065
 var rows: int = ([5,4,3] if small else [9,6,4])[b.detail]
 var columns: int = ([9,7,5] if small else [17,11,7])[b.detail]
 var points := PackedVector3Array()
 for row in range(rows):
  var t := float(row)*PI/(rows-1)
  for column in range(columns):
   var a := float(column)*TAU/(columns-1)
   points.append(center+Vector3(cos(a)*sin(t)*size.x,cos(t)*size.y,sin(a)*sin(t)*size.z))
 b.grid(points,rows,columns,role,color)

static func line(b: RefCounted, points: Array, radius: float, color: Color, role: int = 13) -> void:
 var path := PackedVector3Array()
 var radii := PackedFloat32Array()
 for p in points:
  path.append(p)
  radii.append(radius)
 b.tube(path,radii,role,color,7)

static func star(b: RefCounted, center: Vector3, radius: float, color: Color = GOLD, glowing: bool = true) -> void:
 var outline := []
 for i in range(11):
  var a := float(i)*TAU/10+PI*.5
  var r := radius if i%2 == 0 else radius*.44
  outline.append(center+Vector3(cos(a)*r,sin(a)*r,0))
 var points := PackedVector3Array()
 for p in outline:
  points.append(center)
  points.append(p)
 b.grid(points,outline.size(),2,5,color)
 if glowing: line(b,outline,.009,color)

static func moon(b: RefCounted, center: Vector3, radius: float, color: Color = GOLD) -> void:
 var outer := []
 var inner := []
 var points := PackedVector3Array()
 var count := Shape.n(39,b)
 for i in range(count):
  var a := -PI*.5+float(i)*PI/(count-1)
  var p := center+Vector3(-cos(a)*radius,sin(a)*radius,0)
  var q := center+Vector3(-cos(a)*radius*.42,sin(a)*radius,0)
  points.append(p)
  points.append(q)
  outer.append(p+Vector3(0,0,.015))
  inner.append(q+Vector3(0,0,.015))
 b.grid(points,count,2,5,color)
 line(b,outer,.012,CYAN)
 line(b,inner,.008,VIOLET)

static func mushroom(b: RefCounted, origin: Vector3, scale: float, color: Color) -> void:
 var stem := [[0,0],[.10,0],[.075,.10],[.06,.35],[.09,.44],[0,.44]]
 for point in stem: point[1] *= scale
 Shape.profile(b,stem,origin,11,Color("d7cbb0"),Vector2.ONE*scale)
 # Shape profile y is scaled explicitly for each mushroom.
 var cap := [[0,.68],[.10,.66],[.22,.58],[.35,.44],[.36,.40],[.28,.38],[.15,.42],[0,.44]]
 for point in cap: point[1] *= scale
 Shape.profile(b,cap,origin,12,color,Vector2.ONE*scale)
 Shape.ring(b,origin+Vector3(0,.40*scale,0),.30*scale,Vector3.RIGHT,Vector3.BACK,.014,13,MINT)
 for i in range(Shape.n(12,b)):
  var a := float(i)*2.4
  var r := (.10+.12*absf(sin(i*1.7)))*scale
  orb(b,origin+Vector3(cos(a)*r,(.66-(r/scale-.10)*.6667)*scale+.006,sin(a)*r),Vector3(.025,.015,.025)*scale,Color("c5f6e6"),13)

static func crystal(b: RefCounted, origin: Vector3, height: float, radius: float, color: Color) -> void:
 var points := PackedVector3Array()
 for row in range(3):
  var y: float = [0.0,height*.76,height][row]
  var r := radius if row < 2 else .002
  for i in range(7):
   var a := i*TAU/6
   points.append(origin+Vector3(cos(a)*r,y,-sin(a)*r))
 b.grid(points,3,7,12,color.darkened(.25))
 for i in range(6):
  var a := i*TAU/6
  var base := origin+Vector3(cos(a)*radius,0,-sin(a)*radius)
  var shoulder := base+Vector3(0,height*.76,0)
  line(b,[base,shoulder,origin+Vector3(0,height,0)],.009,color)

static func door(b: RefCounted, origin: Vector3, width: float, height: float) -> void:
 for i in range(7):
  var x := (float(i)/6-.5)*width
  var top := height*.7+sqrt(maxf(0,1-pow(x/(width*.51),2)))*height*.3
  b.box(origin+Vector3(x,top*.5,0),Vector3(width/7*.91,top,.065),.01,3,WOOD)
 var curve := [origin+Vector3(-width*.55,0,.05),origin+Vector3(-width*.55,height*.7,.05)]
 for i in range(19):
  var a := PI-float(i)*PI/18
  curve.append(origin+Vector3(cos(a)*width*.55,height*.7+sin(a)*height*.33,.05))
 curve.append(origin+Vector3(width*.55,0,.05))
 line(b,curve,.014,PINK)
 orb(b,origin+Vector3(width*.26,height*.38,.07),Vector3(.025,.025,.02),GOLD,5)
 for y in [.18,.5]: b.box(origin+Vector3(-width*.32,height*y,.055),Vector3(width*.25,.025,.025),.006,5,GOLD)

static func bottle(b: RefCounted, origin: Vector3, height: float, color: Color) -> void:
 Shape.profile(b,[[0,0],[.075,0],[.09,.05],[.09,height*.55],[.045,height*.7],[.025,height*.75],[.025,height],[0,height]],origin,12,color.darkened(.25))
 Shape.profile(b,[[0,.04],[.08,.04],[.08,height*.5],[0,height*.5]],origin,13,color)
 b.box(origin+Vector3(0,height+.02,0),Vector3(.065,.05,.065),.008,3,Color("9f825b"))

static func build(b: RefCounted, id: String) -> void:
 match id:
  "glow_mushrooms":
   Shape.profile(b,[[0,0],[.40,0],[.43,.04],[.35,.08],[0,.08]],Vector3.ZERO,11,Color("776b89"))
   for i in range(3): mushroom(b,Vector3(cos(i*2.4)*.18,.06,sin(i*2.4)*.18),.65 if i else 1, VIOLET if i%2 else Color("bd7db8"))
  "fairy_mushroom_house":
   Shape.profile(b,[[0,0],[.29,0],[.32,.08],[.26,.7],[.32,.78],[0,.8]],Vector3.ZERO,11,Color("dac8ab"))
   Shape.profile(b,[[0,1.08],[.12,1.05],[.32,.96],[.5,.78],[.48,.71],[.32,.75],[0,.78]],Vector3.ZERO,12,Color("a775bb"))
   Shape.ring(b,Vector3(0,.76,0),.43,Vector3.RIGHT,Vector3.BACK,.014,13,PINK)
   door(b,Vector3(0,.04,.285),.25,.44)
   for x in [-.20,.20]:
    orb(b,Vector3(x,.50,.20),Vector3(.065,.08,.025),GOLD,5)
    orb(b,Vector3(x,.50,.23),Vector3(.045,.06,.02),PINK,13)
   b.box(Vector3(.19,.96,-.1),Vector3(.10,.25,.10),.015,11,Color("bda98f"))
   for i in range(3): b.box(Vector3(0,.025+i*.022,.34+i*.06),Vector3(.30,.05,.12),.015,11,Color("a69b8c"))
   for i in range(Shape.n(16,b)):
    var a := i*2.4
    var r := .12+.20*absf(sin(i*3.1))
    orb(b,Vector3(cos(a)*r,1.05-(r-.12)*.45+.006,sin(a)*r),Vector3(.035,.015,.035),MINT,13)
  "fairy_ring":
   for i in range(12):
    if i in [3,9]: continue
    var a := i*TAU/12
    mushroom(b,Vector3(cos(a),0,sin(a)),.35,CYAN if i%2 else PINK)
  "crystal_cluster":
   Shape.profile(b,[[0,0],[.38,0],[.40,.05],[.32,.11],[0,.11]],Vector3.ZERO,11,Color("5d536b"))
   for i in range(5):
    var a := i*2.4
    crystal(b,Vector3(cos(a)*i*.055,.07,sin(a)*i*.055),1.0-i*.14,.13 if i else .16,VIOLET if i%2 else CYAN)
  "moon_lantern":
   line(b,[Vector3(-.18,0,0),Vector3(-.18,1.55,0),Vector3(-.1,1.72,0),Vector3(.12,1.76,0),Vector3(.23,1.61,0),Vector3(.17,1.52,0)],.027,IRON,5)
   moon(b,Vector3(.20,1.27,0),.24)
   Shape.profile(b,[[.13,.65],[.14,.70],[.10,.73],[.10,1.04],[.15,1.07],[0,1.17]],Vector3(.12,0,0),5,GOLD)
   orb(b,Vector3(.12,.86,0),Vector3(.085,.16,.085),VIOLET,13)
   line(b,[Vector3(.12,1.17,0),Vector3(.12,1.52,0)],.010,GOLD,5)
  "witch_cauldron":
   Shape.profile(b,[[0,.13],[.22,.13],[.36,.28],[.39,.51],[.34,.69],[.37,.72],[.37,.76],[.30,.76],[.30,.67],[.32,.49],[.27,.32],[0,.22]],Vector3.ZERO,5,IRON)
   Shape.profile(b,[[0,.65],[.30,.65]],Vector3.ZERO,13,MINT)
   for i in range(3):
    var a := i*TAU/3
    line(b,[Vector3(cos(a)*.27,.24,sin(a)*.27),Vector3(cos(a)*.32,.04,sin(a)*.32)],.04,IRON,5)
   for side in [-1.0,1.0]: Shape.ring(b,Vector3(side*.36,.58,0),.09,Vector3.RIGHT,Vector3.UP,.022,5,GOLD)
   for i in range(4): orb(b,Vector3(sin(i*2.4)*.17,.69+i*.035,cos(i*2.4)*.12),Vector3.ONE*(.035+i*.006),MINT if i%2 else PINK,13)
   star(b,Vector3(0,.46,.36),.10,GOLD,false)
  "witch_hat_planter":
   Shape.profile(b,[[0,0],[.12,0],[.20,.17],[.30,.37],[.40,.40],[.4,.44],[.32,.46],[.29,.38],[.22,.20],[0,.08]],Vector3.ZERO,6,Color("746087"))
   Shape.ring(b,Vector3(0,.39,0),.34,Vector3.RIGHT,Vector3.BACK,.017,13,PINK)
   for i in range(7):
    var a := i*2.4
    var p := Vector3(cos(a)*.17,.38,sin(a)*.17)
    b.leaf(p,Vector3(cos(a),.6,sin(a)),.2,.10,Color("6d9e78"),1)
    for j in range(5):
     var t := j*TAU/5
     b.petal(p+Vector3(0,.12,0),Vector3(-sin(t),0,cos(t)),Vector3(cos(t),.2,sin(t)),.10,.05,.15,PINK if i%2 else VIOLET,2)
   star(b,Vector3(0,.23,.26),.06,GOLD,false)
  "spellbook_pedestal":
   Shape.pedestal(b,.83,.5)
   for side in [-1.0,1.0]:
    var points := PackedVector3Array([Vector3(0,.94,-.24),Vector3(side*.32,1.03,-.24),Vector3(0,.94,.24),Vector3(side*.32,1.03,.24)])
    b.grid(points,2,2,6,Color("e5d5b7"))
    for i in range(5): line(b,[Vector3(side*.06,.97,-.15+i*.067),Vector3(side*.26,1.028,-.15+i*.067)],.004,VIOLET)
    line(b,[Vector3(0,.92,-.27),Vector3(side*.35,1.01,-.27),Vector3(side*.35,1.01,.27),Vector3(0,.92,.27)],.018,Color("6c4778"),6)
   star(b,Vector3(.18,1.04,.04),.07,PINK)
  "crescent_moon_statue":
   Shape.pedestal(b,.65,.5)
   moon(b,Vector3(.23,1.17,0),.59)
   star(b,Vector3(.28,1.18,.03),.13,PINK)
  "fairy_door":
   b.box(Vector3(0,.04,0),Vector3(.55,.08,.25),.02,11,Color("8b7d95"))
   door(b,Vector3(0,.08,0),.45,.65)
   moon(b,Vector3(.05,.47,.09),.08)
  "enchanted_tree":
   line(b,[Vector3(0,0,0),Vector3(-.14,.65,0),Vector3(.08,1.4,0),Vector3(-.05,2.3,0)],.09,WOOD,3)
   for i in range(9):
    var a := i*2.4
    var end := Vector3(cos(a)*(.6+i%3*.2),1.6+i%4*.23,sin(a)*(.6+i%3*.2))
    line(b,[Vector3(0,1.0+i*.07,0),end*.8+Vector3(0,.1,0),end],.035,WOOD,3)
    for j in range(Shape.n(12,b)):
     var t := float(j)/Shape.n(12,b)
     var p := end*.7+Vector3(0,.4,0).lerp(end*.3,t)
     b.leaf(p,Vector3(cos(j*2.4),.35,sin(j*2.4)),.30,.14,Color("8c78a8"),1)
    orb(b,end,Vector3.ONE*.055,VIOLET if i%2 else PINK,13)
    if i%3 == 0: star(b,end-Vector3(0,.18,0),.07,CYAN)
  "star_mobile":
   Shape.profile(b,[[0,0],[.22,0],[.20,.06],[0,.08]],Vector3.ZERO,11,Color("76697f"))
   line(b,[Vector3(-.14,.04,0),Vector3(-.14,1.45,0),Vector3(-.05,1.62,0),Vector3(.22,1.62,0)],.02,IRON,5)
   for i in range(3):
    var x := -.02+i*.13
    var y := 1.35-i*.19
    line(b,[Vector3(x,1.59,0),Vector3(x,y,0)],.006,GOLD,5)
    star(b,Vector3(x,y-.1,0),.10,PINK if i%2 else CYAN)
  "rune_obelisk":
   Shape.profile(b,[[0,0],[.32,0],[.32,.12],[.23,.17],[.20,1.57],[0,1.86]],Vector3.ZERO,11,Color("686579"),Vector2.ONE)
   for side in [-1.0,1.0]:
    for i in range(4):
     var y := .4+i*.3
     var z: float = side*.22
     line(b,[Vector3(-.10,y+.08,z),Vector3(0,y+.17,z),Vector3(.10,y+.08,z),Vector3(0,y,z),Vector3(-.10,y+.08,z)],.009,CYAN)
     line(b,[Vector3(0,y-.04,z),Vector3(0,y+.21,z)],.007,VIOLET)
  "lotus_lamp":
   Shape.profile(b,[[0,0],[.21,0],[.23,.08],[0,.1]],Vector3.ZERO,11,Color("796a91"))
   for tier in range(2):
    for i in range(Shape.n(12,b)):
     var a := (float(i)+tier*.5)*TAU/Shape.n(12,b)
     b.petal(Vector3(0,.10+tier*.04,0),Vector3(-sin(a),0,cos(a)),Vector3(cos(a),.3,sin(a)),.34-tier*.06,.16,.48,PINK if tier else VIOLET,12)
   orb(b,Vector3(0,.2,0),Vector3(.11,.12,.11),CYAN,13)
  "firefly_jar":
   # Open iron cage/ribs suggest transparent glass without costly overlapping transparent shells.
   Shape.profile(b,[[0,0],[.13,0],[.15,.04],[.14,.09],[0,.09]],Vector3.ZERO,5,GOLD)
   for i in range(8):
    var a := i*TAU/8
    line(b,[Vector3(cos(a)*.13,.06,sin(a)*.13),Vector3(cos(a)*.15,.24,sin(a)*.15),Vector3(cos(a)*.11,.44,sin(a)*.11)],.006,GOLD,5)
   Shape.ring(b,Vector3(0,.44,0),.12,Vector3.RIGHT,Vector3.BACK,.012,5,GOLD)
   Shape.ring(b,Vector3(0,.51,0),.09,Vector3.RIGHT,Vector3.UP,.009,5,GOLD)
   for i in range(7): orb(b,Vector3(sin(i*2.4)*.08,.13+i*.035,cos(i*2.4)*.08),Vector3.ONE*.018,MINT if i%2 else PINK,13)
  "fairy_well":
   Shape.profile(b,[[.52,0],[.65,0],[.65,.43],[.70,.48],[.70,.57],[.53,.57],[.51,.44],[.51,0]],Vector3.ZERO,11,Color("82758f"))
   Shape.profile(b,[[0,.28],[.51,.28]],Vector3.ZERO,13,CYAN)
   for side in [-1.0,1.0]: b.box(Vector3(side*.59,.98,0),Vector3(.10,1.5,.10),.015,3,WOOD)
   for side in [-1.0,1.0]:
    b.grid(PackedVector3Array([Vector3(0,1.85,-.55),Vector3(0,1.85,.55),Vector3(side*.78,1.48,-.55),Vector3(side*.78,1.48,.55)]),2,2,3,WOOD)
    line(b,[Vector3(0,1.85,side*.56),Vector3(-.78,1.48,side*.56)],.014,PINK)
   b.beam(Vector3(-.6,1.12,0),Vector3(.6,1.12,0),.04,3,Color("aa8f78"))
   line(b,[Vector3(0,1.12,0),Vector3(0,.7,0)],.008,GOLD,5)
   Shape.profile(b,[[.10,.54],[.13,.72],[.10,.73],[.08,.69],[0,.57]],Vector3.ZERO,5,GOLD)
   star(b,Vector3(0,1.53,.04),.14,CYAN)
  "moon_arch":
   for side in [-1.0,1.0]:
    line(b,[Vector3(side*1.18,0,0),Vector3(side*1.18,1.8,0),Vector3(side*.90,2.38,0),Vector3(side*.35,2.60,0),Vector3(0,2.64,0)],.045,IRON,5)
    Shape.vine(b,Vector3(side*1.18,.10,.06),Vector3(side*1.18,1.9,.06),.22)
    for i in range(3):
     var x: float = side*(.35+i*.28)
     var y := 2.45-i*.16
     line(b,[Vector3(x,y+.13,0),Vector3(x,y,0)],.006,GOLD,5)
     star(b,Vector3(x,y-.08,0),.09,PINK if i%2 else CYAN)
   moon(b,Vector3(.16,2.73,0),.26)
  "potion_shelf":
   for x in [-.49,.49]: b.box(Vector3(x,.8,0),Vector3(.10,1.6,.10),.018,3,WOOD)
   for y in [.12,.66,1.19,1.55]: b.box(Vector3(0,y,0),Vector3(1.1,.08,.42),.018,3,WOOD)
   for shelf in range(2):
    for i in range(4): bottle(b,Vector3(-.36+i*.24,.17+shelf*.54,0),.30+(i%2)*.08,[PINK,CYAN,VIOLET,MINT][i])
   star(b,Vector3(0,1.40,.02),.10,GOLD)

static func collision(id: String) -> Array:
 var dimensions: Vector3 = SIZES[id]
 match id:
  "moon_arch": return [[Vector3(-1.18,1.05,0),Vector3(.16,2.1,.35),"box"],[Vector3(1.18,1.05,0),Vector3(.16,2.1,.35),"box"]]
  "fairy_ring":
   var result := []
   for i in range(12):
    if i in [3,9]: continue
    var a := i*TAU/12
    result.append([Vector3(cos(a),.115,sin(a)),Vector3(.25,.23,.25),"cylinder"])
   return result
  "enchanted_tree": return [[Vector3(0,1.15,0),Vector3(.3,2.3,.3),"cylinder"]]
  "potion_shelf": return [[Vector3(0,.8,0),dimensions,"box"]]
  "fairy_door": return [[Vector3(0,.4,0),dimensions,"box"]]
  "moon_lantern","star_mobile": return [[Vector3(-.14,dimensions.y*.5,0),Vector3(.13,dimensions.y,.13),"cylinder"]]
  "fairy_well": return [[Vector3(0,.28,0),Vector3(1.4,.56,1.4),"cylinder"]]
  _: return [[Vector3(0,minf(dimensions.y,.9)*.5,0),Vector3(dimensions.x,minf(dimensions.y,.9),dimensions.z),"cylinder"]]
