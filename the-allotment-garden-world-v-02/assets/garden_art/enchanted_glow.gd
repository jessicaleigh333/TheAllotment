extends Node3D
## One soft halo and one shadow-free, globally budgeted light per decorated object.
const Builder := preload("res://assets/garden_art/mesh_builder.gd")
const Collection := preload("res://assets/garden_art/enchanted_collection.gd")
static var textures := {}
var halo: Sprite3D
var lamp: OmniLight3D
var item_id := ""
var phase := 0.0

func _ready() -> void:
 add_to_group("enchanted_garden_fx")
 var color: Color = Collection.COLORS.get(item_id,Color("e2b66f"))
 var key := color.to_html()
 if not textures.has(key):
  var gradient := Gradient.new()
  gradient.offsets = PackedFloat32Array([0,.22,1])
  gradient.colors = PackedColorArray([Color(color,.28),Color(color,.12),Color(color,0)])
  var texture := GradientTexture2D.new()
  texture.width = 64
  texture.height = 64
  texture.gradient = gradient
  texture.fill = GradientTexture2D.FILL_RADIAL
  texture.fill_from = Vector2(.5,.5)
  texture.fill_to = Vector2(1,.5)
  textures[key] = texture
 halo = Sprite3D.new()
 halo.name = "SoftNightHalo"
 halo.texture = textures[key]
 halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 var diameter := 1.8 if item_id in ["enchanted_tree","moon_arch","fairy_ring"] else 1.0
 halo.pixel_size = diameter/64
 halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 halo.visibility_range_end = 35
 var material := StandardMaterial3D.new()
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
 material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
 material.vertex_color_use_as_albedo = true
 material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
 material.albedo_texture = textures[key]
 halo.material_override = material
 add_child(halo)
 lamp = OmniLight3D.new()
 lamp.name = "BudgetedGlowLight"
 lamp.light_color = color
 lamp.omni_range = 2.8 if item_id in ["enchanted_tree","moon_arch","fairy_well","fairy_light_arbor"] else 1.8
 lamp.omni_attenuation = 1.8
 lamp.shadow_enabled = false
 add_child(lamp)
 set_phase(Builder.night_amount,false)

func eligible() -> bool:
 return is_visible_in_tree() and not get_parent().get_meta("placement_preview",false)

func set_phase(value: float, illuminate: bool = false) -> void:
 phase = clampf(value,0,1) if eligible() else 0.0
 if is_instance_valid(halo):
  halo.modulate = Color(1,1,1,phase)
  halo.visible = phase > .01
 if is_instance_valid(lamp):
  lamp.light_energy = phase*.8 if illuminate else 0.0
  lamp.visible = illuminate and phase > .01
