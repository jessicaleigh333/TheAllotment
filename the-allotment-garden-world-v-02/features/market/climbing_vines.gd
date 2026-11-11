extends RefCounted
## Deterministic training from saved positions and biological age, never game time.
const Art := preload("res://assets/garden_art/garden_library.gd")
const Growth := preload("res://features/market/plant_growth.gd")
const Roman := preload("res://assets/garden_art/roman_collection.gd")
const VineArt := preload("res://assets/garden_art/vine_art.gd")
const Builder := preload("res://assets/garden_art/mesh_builder.gd")
const REACH := {"climbing_rose":5.0,"clematis":4.0,"honeysuckle":6.0,"ivy":6.0,"wisteria":8.0}
const SUPPORT_DISTANCE := .85

static func is_vine(id: String) -> bool: return REACH.has(Growth.species(id))

static func column(id: String) -> bool:
 return Roman.SIZES.has(id) and id not in ["roman_architrave","stone_cornice"]

static func routes(id: String) -> Array:
 var result := []
 var width: float = 0
 var height: float = 0
 var depth: float = 0
 match id:
  "trellis": width = 1.5; height = 1.98
  "branch_trellis": width = 1.7; height = 2.15
  "espalier_screen": width = 2.6; height = 2.15
  "rose_arch":
   for side in [-1.,1.]:
    var route := PackedVector3Array([Vector3(side*1.1,.03,.3),Vector3(side*1.1,1.35,.3)])
    for i in range(1,13):
     var a := i*PI/24
     route.append(Vector3(side*cos(a)*1.1,1.35+sin(a)*1.1,.3))
    result.append(route)
   return result
  "rustic_arbor","fairy_light_arbor":
   for side in [-1.,1.]: result.append(PackedVector3Array([Vector3(side*1.1,.03,.28),Vector3(side*1.023,2.3,.28),Vector3(side*.33,2.7,.28),Vector3(0,2.76,.28)]))
   return result
  "moon_arch":
   for side in [-1.,1.]: result.append(PackedVector3Array([Vector3(side*1.18,.03,0),Vector3(side*1.18,1.8,0),Vector3(side*.9,2.38,0),Vector3(side*.35,2.6,0),Vector3(0,2.64,0)]))
   return result
  "vine_pergola": width = 3.6; height = 2.65; depth = 2.5
  "iron_pavilion":
   for i in range(8):
    var a := i*TAU/8
    var route := PackedVector3Array([Vector3(cos(a)*1.8,.03,sin(a)*1.8),Vector3(cos(a)*1.8,2.58,sin(a)*1.8)])
    for j in range(1,10):
     var t := j*PI/18
     route.append(Vector3(cos(a)*1.8*cos(t),2.58+sin(t)*.85,sin(a)*1.8*cos(t)))
    result.append(route)
   return result
  "lantern_picnic_canopy": width = 3.3; height = 2.58; depth = 2.4
  "sheltered_workbench": width = 2.45; height = 2.30; depth = 1.35
  "woodland_potting_station":
   for side in [-1.,1.]: result.append(PackedVector3Array([Vector3(side*1.05,.03,-.35),Vector3(side*1.05,1.65,-.35),Vector3(0,1.65,-.35)]))
   return result
  "branch_fence": width = 1.65; height = 1.12
  "garden_gate": width = 2.55; height = 1.9
  "timber_gate": width = 2.2; height = 1.25
  "rope_beam_swing": return [PackedVector3Array([Vector3(.16,.03,0),Vector3(.16,2.85,0),Vector3(1.8,2.85,0)])]
  "twig_obelisk","willow_teepee_planter":
   for side in [-1.,1.]: result.append(PackedVector3Array([Vector3(side*.40,.03,0),Vector3(side*.22,1.2,0),Vector3(0,2.13,0)]))
   return result
  _:
   if column(id):
    var h: float = Roman.SIZES[id].y
    var path := PackedVector3Array()
    var radius: float = minf(.34,Roman.SIZES[id].x*.42)
    for i in range(25):
     var t := i/24.0
     path.append(Vector3(cos(t*TAU*1.5)*radius,.025+t*(h-.04),sin(t*TAU*1.5)*radius))
    return [path]
   return []
 for z in ([-depth*.5,depth*.5] if depth > 0 else [0.]):
  for side in [-1.,1.]:
   # Stay at the fixed posts; growth overhead never adds player collision.
   var route := PackedVector3Array([Vector3(side*width*.5,.03,z),Vector3(side*width*.5,height*.5,z),Vector3(side*width*.5,height,z),Vector3(0,height,z)])
   if depth > 0:
    route.append(Vector3(0,height,-z))
    route.append(Vector3(side*width*.5,height,-z))
   result.append(route)
 return result

static func fitted_route(id: String, route: PackedVector3Array) -> PackedVector3Array:
 var result := PackedVector3Array()
 var bounds := Art.meshes(id)[0].get_aabb()
 var dimensions: Vector3 = Art.Woodland.SIZES.get(id,Art.Rustic.SIZES.get(id,Art.Enchanted.SIZES.get(id,Art.French.SIZES.get(id,Art.Boundary.SIZES.get(id,Art.SIZES.get(id,Vector3.ONE))))))
 var scale := dimensions/bounds.size
 for point in route: result.append(point*scale-Vector3(0,bounds.position.y*scale.y,0))
 return result

static func world_route(record: Dictionary, route: PackedVector3Array, records: Array) -> PackedVector3Array:
 var result := PackedVector3Array()
 if not column(record.id): route = fitted_route(record.id,route)
 var bottom := float(record.get("ground_y",0))+float(record.get("elevation",0))
 var origin := Vector3(record.x,bottom,record.z)
 if column(record.id):
  # Follow a contiguous, aligned vertical column assembly, not unrelated objects.
  var sections := [record]
  var top: float = bottom+Roman.SIZES[record.id].y
  for step in range(32):
   var next: Dictionary = {}
   for other in records:
    if other.get("area","garden") != record.get("area","garden") or not column(other.id): continue
    var y := float(other.get("ground_y",0))+float(other.get("elevation",0))
    if absf(y-top) < .025 and Vector2(other.x-record.x,other.z-record.z).length() < .08:
     next = other
     break
   if next.is_empty(): break
   sections.append(next)
   top += Roman.SIZES[next.id].y
  var h := minf(24.,top-bottom)
  route = PackedVector3Array()
  for i in range(maxi(12,ceili(h*10))+1):
   var t := i/float(maxi(12,ceili(h*10)))
   var height := .025+t*(h-.04)
   var radius := .34
   for section in sections:
    var low := float(section.get("ground_y",0))+float(section.get("elevation",0))-bottom
    var dimensions: Vector3 = Roman.SIZES[section.id]
    if height >= low-.02 and height <= low+dimensions.y+.02:
     radius = maxf(dimensions.x,dimensions.z)*(.72 if section.id in ["roman_plinth","roman_pedestal","attic_column_base","doric_capital","ionic_capital","corinthian_capital"] else .52)+.015
     if section.id in ["doric_column","ionic_column","corinthian_column"]:
      var local_y := height-low
      radius = .46 if local_y < .28 or local_y > dimensions.y-.4 else .30
     break
   route.append(Vector3(cos(t*h*4)*radius,height,sin(t*h*4)*radius))
 for point in route: result.append(origin+point.rotated(Vector3.UP,float(record.angle)))
 return result

static func root_clear(support: Dictionary, point: Vector3) -> bool:
 var local := (point-Vector3(support.x,0,support.z)).rotated(Vector3.UP,-float(support.angle))
 if support.id in ["trellis","branch_trellis","espalier_screen","branch_fence"]: return absf(local.z) >= .27
 if support.id == "woodland_potting_station": return absf(local.x) > 1.30 or absf(local.z) > .56
 if support.id == "sheltered_workbench": return absf(local.x) > 1.25 or absf(local.z) > .60
 if support.id == "lantern_picnic_canopy": return absf(local.x) > 1.57 or absf(local.z) > 1.35
 if column(support.id): return Vector2(local.x,local.z).length() >= maxf(Roman.SIZES[support.id].x,Roman.SIZES[support.id].z)*.5+.14
 if support.id in ["twig_obelisk","willow_teepee_planter"]: return Vector2(local.x,local.z).length() >= .62
 return true

static func attachment(plant: Dictionary, records: Array) -> Dictionary:
 if not is_vine(plant.id): return {}
 var origin := Vector3(plant.x,float(plant.get("ground_y",0))+float(plant.get("elevation",0)),plant.z)
 var best := INF
 var selected := {}
 for support in records:
  if support.get("area","garden") != plant.get("area","garden"): continue
  if support.get("uid","") == plant.get("uid","plant"): continue
  if Vector2(support.x-origin.x,support.z-origin.z).length_squared() > 16.: continue
  if not root_clear(support,origin): continue
  for route in routes(support.id):
   var path := world_route(support,route,records)
   var distance := Vector2(path[0].x-origin.x,path[0].z-origin.z).length()
   if distance < .30 or distance > SUPPORT_DISTANCE or absf(path[0].y-origin.y) > .20: continue
   # Stable tie breaking follows saved order; unchanged gardens restore identically.
   if distance >= best-.0001: continue
   best = distance
   var full := PackedVector3Array([origin+Vector3(0,.03,0)])
   full.append_array(path)
   selected = {"uid":support.get("uid",""),"path":full,"id":support.id}
 return selected

static func nearby_support(id: String, point: Vector2, ground: float, records: Array, area: String) -> Dictionary:
 return attachment({"id":id,"x":point.x,"z":point.y,"ground_y":ground,"area":area},records)

static func refresh(roots: Dictionary, records: Array) -> void:
 for scope in roots:
  for model in roots[scope].get_children():
   if not model.has_meta("placement_record") or not is_vine(model.item_id): continue
   var record: Dictionary = model.get_meta("placement_record")
   var selected := attachment(record,records)
   var previous: Node = model.get_node_or_null("ClimbingGrowth")
   if selected.is_empty():
    if previous != null: previous.free()
    model.remove_meta("climbing_signature")
    model.remove_meta("climbing_support")
    continue
   var plant := Growth.species(model.item_id)
   var state := Growth.state(plant,model.growth_age_days)
   var fraction := float(state.height)/float(Growth.PLANTS[plant].height) if state.stage > 0 else 0.0
   var length := float(REACH[plant])*fraction
   var signature := var_to_str(selected.path)+"|"+str(floori(length/.02))+"|"+str(state.stage)
   model.set_meta("climbing_support",selected.uid)
   if model.get_meta("climbing_signature","") == signature and previous != null: continue
   if previous != null: previous.free()
   model.set_meta("climbing_signature",signature)
   if state.stage == 0: continue
   var container := Node3D.new()
   container.name = "ClimbingGrowth"
   model.add_child(container)
   var path := PackedVector3Array()
   for point in selected.path: path.append(model.transform.affine_inverse()*point)
   for detail in range(3):
    var b := Builder.new(detail)
    VineArt.trained(b,plant,path,length,state.stage)
    var mesh := MeshInstance3D.new()
    mesh.mesh = b.mesh()
    mesh.visibility_range_begin = [0.,18.,45.][detail]
    mesh.visibility_range_end = [18.,45.,0.][detail]
    container.add_child(mesh)
