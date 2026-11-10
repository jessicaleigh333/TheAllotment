extends RefCounted
## Geometry-only assembly rules; heights are metres above each saved ground surface.
const Roman := preload("res://assets/garden_art/roman_collection.gd")
const French := preload("res://assets/garden_art/french_collection.gd")
const Old := preload("res://assets/garden_art/garden_boundary.gd")
const Growth := preload("res://features/market/plant_growth.gd")
const MAX_HEIGHT := 24.0
const EPS := .018

static func size(id: String) -> Vector3:
 if Roman.SIZES.has(id): return Roman.SIZES[id]
 if French.SIZES.has(id): return French.SIZES[id]
 if Old.SIZES.has(id): return Old.SIZES[id]
 var plant := Growth.species(id)
 if not plant.is_empty():
  var p: Dictionary = Growth.PLANTS[plant]
  return Vector3(p.width,p.height,p.width)
 return {"bench":Vector3(1.8,.9,.65),"rose_arch":Vector3(2.4,2.5,.7),"fountain":Vector3(2.2,2,2.2),"lantern":Vector3(.22,.45,.22),"trellis":Vector3(1.6,2,.25),"planter":Vector3(.55,.75,.55),"watering_can":Vector3(.65,.4,.28)}.get(id,Vector3.ONE)

static func top(id: String) -> Dictionary:
 if id in ["plain_column_drum","fluted_column_drum","short_column_drum"]: return {"half":Vector2(.30,.30),"round":true}
 if id == "attic_column_base": return {"half":Vector2(.34,.34),"round":true}
 if Roman.SIZES.has(id):
  var dimensions: Vector3 = Roman.SIZES[id]
  return {"half":Vector2(dimensions.x,dimensions.z)*.5,"round":false}
 if id == "rock_wall_end": return {"half":Vector2(.30,.30),"round":false}
 return {}

static func foot(id: String) -> Dictionary:
 if id.ends_with("_drum"): return {"half":Vector2(.30,.30),"round":true}
 if id.ends_with("_capital"): return {"half":Vector2(.285,.285),"round":true}
 if id == "attic_column_base": return {"half":Vector2(.425,.425),"round":false}
 if id in ["doric_column","ionic_column","corinthian_column"]: return {"half":Vector2(.425,.425),"round":false}
 if id == "stone_cornice": return {"half":Vector2(.42,.42),"round":false}
 if Roman.SIZES.has(id):
  var dimensions: Vector3 = Roman.SIZES[id]
  return {"half":Vector2(dimensions.x,dimensions.z)*.5,"round":false}
 var radius: float = {"anduze_jar":.22,"clay_bowl":.22,"glazed_olive_pot":.22,"stone_urn":.24,"stone_dove":.22,"botanical_medallion":.22,"garden_muse_bust":.25,"armillary_sphere":.25,"garden_sundial":.25,"lantern":.11,"planter":.20,"watering_can":.16}.get(id,0.0)
 if radius > 0: return {"half":Vector2(radius,radius),"round":true}
 if id in ["stone_trough","carved_square_pot"]:
  var dimensions: Vector3 = French.SIZES[id]
  return {"half":Vector2(dimensions.x,dimensions.z)*.5,"round":false}
 return {}

static func can_stack(id: String) -> bool: return not foot(id).is_empty()
static func elevation(record: Dictionary) -> float: return float(record.get("elevation",0.0))
static func bottom_y(record: Dictionary) -> float: return float(record.get("ground_y",0.0))+elevation(record)
static func top_y(record: Dictionary) -> float: return bottom_y(record)+size(record.id).y

static func inside(id: String, point: Vector2, center: Vector2, angle: float, margin: float = EPS) -> bool:
 var surface := top(id)
 if surface.is_empty(): return false
 var local := (point-center).rotated(angle)
 var half: Vector2 = surface.half
 if surface.round: return local.length() <= half.x+margin
 return absf(local.x) <= half.x+margin and absf(local.y) <= half.y+margin

static func contact_points(id: String) -> Array:
 if id == "roman_architrave": return [Vector2(-1.10,0),Vector2(1.10,0)]
 var shape := foot(id)
 if shape.is_empty(): return []
 var half: Vector2 = shape.half
 var points := [Vector2.ZERO]
 if shape.round:
  for i in range(12): points.append(Vector2(cos(i*TAU/12),sin(i*TAU/12))*half.x)
 else:
  for x in [-1,0,1]:
   for z in [-1,0,1]: points.append(Vector2(x*half.x,z*half.y))
 return points

static func supports_for(id: String, point: Vector2, angle: float, y: float, records: Array, area: String) -> Array:
 if not can_stack(id): return []
 var used := []
 for local in contact_points(id):
  var contact: Vector2 = point+local.rotated(-angle)
  var found := false
  for parent in records:
   if parent.get("area","garden") != area or not parent.has("uid") or absf(top_y(parent)-y) > EPS: continue
   if inside(parent.id,contact,Vector2(parent.x,parent.z),parent.angle):
    if not used.has(parent.uid): used.append(parent.uid)
    found = true
    break
  if not found: return []
 return used

static func valid_graph(records: Array) -> bool:
 var seen := {}
 for index in range(records.size()):
  var record: Dictionary = records[index]
  if record.has("uid"):
   if not record.uid is String or record.uid.length() != 24 or not record.uid.is_valid_hex_number() or seen.has(record.uid): return false
   seen[record.uid] = index
  var height := elevation(record)
  if not is_finite(height) or height < 0 or height+size(record.id).y > MAX_HEIGHT: return false
  var ground := float(record.get("ground_y",0.0))
  if not is_finite(ground) or absf(ground) > 100: return false
  var parents = record.get("supports",[])
  if not parents is Array or parents.size() > 16: return false
  if height == 0:
   if not parents.is_empty(): return false
   continue
  if parents.is_empty() or not record.has("uid") or not record.has("ground_y"): return false
  var unique := {}
  for parent in parents:
   if not parent is String or not seen.has(parent) or seen[parent] >= index or unique.has(parent): return false
   unique[parent] = true
  var parent_records := []
  for parent in parents: parent_records.append(records[seen[parent]])
  var needed := supports_for(record.id,Vector2(record.x,record.z),record.angle,bottom_y(record),parent_records,record.get("area","garden"))
  needed.sort()
  var provided: Array = parents.duplicate()
  provided.sort()
  if needed.is_empty() or provided != needed: return false
 return true


static func volume_overlap(id: String, point: Vector2, angle: float, other_id: String, other: Vector2, other_angle: float) -> bool:
 var a := [Vector2.RIGHT.rotated(-angle),Vector2.DOWN.rotated(-angle)]
 var b := [Vector2.RIGHT.rotated(-other_angle),Vector2.DOWN.rotated(-other_angle)]
 var a_size := size(id)
 var b_size := size(other_id)
 for axis in a+b:
  var radius_a: float = absf(axis.dot(a[0]))*a_size.x*.5+absf(axis.dot(a[1]))*a_size.z*.5
  var radius_b: float = absf(axis.dot(b[0]))*b_size.x*.5+absf(axis.dot(b[1]))*b_size.z*.5
  if absf((other-point).dot(axis)) >= radius_a+radius_b+.025: return false
 return true
