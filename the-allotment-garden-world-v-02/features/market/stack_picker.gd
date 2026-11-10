extends RefCounted
const Rules := preload("res://features/market/stack_rules.gd")

static func pick(camera: Camera3D, screen: Vector2, root: Node3D, id: String, angle: float, records: Array, area: String, sample_height: Callable) -> Dictionary:
 if not Rules.can_stack(id): return {}
 var inverse := root.global_transform.affine_inverse()
 var origin: Vector3 = inverse*camera.project_ray_origin(screen)
 var direction: Vector3 = inverse.basis*camera.project_ray_normal(screen)
 if absf(direction.y) < .00001: return {}
 var nearest := INF
 var result := {}
 for parent in records:
  if parent.get("area","garden") != area or Rules.top(parent.id).is_empty(): continue
  var y := Rules.top_y(parent)
  var along := (y-origin.y)/direction.y
  if along <= 0 or along >= nearest: continue
  var hit := origin+direction*along
  var center := Vector2(parent.x,parent.z)
  if not Rules.inside(parent.id,Vector2(hit.x,hit.z),center,parent.angle,.20): continue
  var first_point := center
  var surface := Rules.top(parent.id)
  var half: Vector2 = surface.half
  if id != "roman_architrave" and maxf(half.x,half.y) > .75:
   var local := (Vector2(hit.x,hit.z)-center).rotated(parent.angle)
   local = Vector2(snappedf(local.x,.1),snappedf(local.y,.1))
   if half.x < .5: local.x = 0
   if half.y < .5: local.y = 0
   first_point = center+local.rotated(-float(parent.angle))
  var solutions := [{"point":first_point,"angle":angle}]
  if id == "roman_architrave":
   for other in records:
    if other.get("area","garden") != area or other.get("uid","") == parent.get("uid","") or Rules.top(other.id).is_empty(): continue
    if absf(Rules.top_y(other)-y) > Rules.EPS: continue
    var offset := Vector2(other.x,other.z)-center
    if offset.length() < 1.5 or offset.length() > 3.05: continue
    solutions.append({"point":center+offset*.5,"angle":atan2(-offset.y,offset.x)})
  for solution in solutions:
   var point: Vector2 = solution.point
   var ground: float = sample_height.call(point)
   if not is_finite(ground): continue
   var parents := Rules.supports_for(id,point,solution.angle,y,records,area)
   if parents.is_empty(): continue
   result = {"point":point,"elevation":y-ground,"angle":solution.angle,"supports":parents}
   nearest = along
   break
 return result
