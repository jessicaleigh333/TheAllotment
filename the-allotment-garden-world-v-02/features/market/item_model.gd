extends Node3D
## Shared UV-mapped art meshes; size and growth are independent of mesh detail.
@export var item_id := "rose"
@export var growth_age_days := -1.0
@export var blossom_tint := Color.WHITE
const Growth := preload("res://features/market/plant_growth.gd")
const Art := preload("res://assets/garden_art/garden_library.gd")
var current_stage := 4

func _ready() -> void:
 rebuild(growth_age_days)

func rebuild(age: float = -1.0) -> void:
 for child in get_children(): child.free()
 var plant := Growth.species(item_id)
 var dimensions: Vector3
 if not plant.is_empty():
  if age < 0: age = Growth.starting_age(item_id)
  growth_age_days = age
  var state := Growth.state(plant,age)
  current_stage = state.stage
  dimensions = Vector3(state.width,state.height,state.width)
  Art.attach(self,plant,current_stage,blossom_tint)
 else:
  Art.attach(self,item_id)
  dimensions = Art.Woodland.SIZES.get(item_id,Art.Rustic.SIZES.get(item_id,Art.Enchanted.SIZES.get(item_id,Art.Roman.SIZES.get(item_id,Art.French.SIZES.get(item_id,Art.Boundary.SIZES.get(item_id,Art.SIZES.get(item_id,Vector3.ONE)))))))
 _fit_dimensions(dimensions)
 if Art.Enchanted.SIZES.has(item_id) or item_id == "fairy_light_arbor" or Art.Woodland.GLOW.has(item_id):
  var effect := preload("res://assets/garden_art/enchanted_glow.gd").new()
  effect.name = "EnchantedGlow"
  effect.item_id = item_id
  effect.position = Art.Woodland.GLOW.get(item_id,Art.Enchanted.ANCHORS.get(item_id,Vector3(0,2,.30)))
  add_child(effect)
 if not plant.is_empty() and current_stage == 0:
  var marker := Label3D.new()
  marker.text = plant.capitalize()+" · Seed"
  marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  marker.pixel_size = .002
  marker.position.y = .18
  add_child(marker)

func mesh_bounds() -> AABB:
 var bounds := AABB()
 var first := true
 for mesh in find_children("*","MeshInstance3D",true,false):
  var local: AABB = (global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
  bounds = local if first else bounds.merge(local)
  first = false
 return bounds

func _fit_dimensions(target: Vector3) -> void:
 var bounds := mesh_bounds()
 if minf(bounds.size.x,minf(bounds.size.y,bounds.size.z)) <= 0: return
 var geometry := Node3D.new()
 geometry.name = "Geometry"
 var children := get_children()
 add_child(geometry)
 for child in children:
  if child is Node3D: child.reparent(geometry,true)
 geometry.scale = target/bounds.size
 geometry.position.y = -bounds.position.y*geometry.scale.y
