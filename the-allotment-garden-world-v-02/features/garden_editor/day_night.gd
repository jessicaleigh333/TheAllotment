extends Node
## Shared day/night lighting, garden-clock following, and a bounded decor light pool.
signal phase_changed(night_amount: float)
const Builder := preload("res://assets/garden_art/mesh_builder.gd")
const Calendar := preload("res://features/title/title_calendar.gd")
const MAX_DECOR_LIGHTS := 6
@export var cycle_enabled := false
@export var cycle_duration_seconds := 600.0
var night_amount := 0.0
var cycle_time := 0.0
var world: Node3D
var catalogs: Array = []
var suns: Array = []
var environments: Array = []
var weather_clock
var manual_override := false
var last_minute := -1
var effect_timer := 0.0

func configure(target: Node3D) -> void:
 world = target
 suns.clear()
 environments.clear()
 for child in world.get_children():
  if child is DirectionalLight3D:
   suns.append({"node":child,"energy":child.light_energy,"color":child.light_color})
  if child is WorldEnvironment:
   var env: Environment = child.environment
   var sky_material: Material = env.sky.sky_material if env.sky != null else null
   var sky_energy: float = sky_material.energy_multiplier if sky_material is PanoramaSkyMaterial else 1.0
   environments.append({"resource":env,"energy":env.ambient_light_energy,"color":env.ambient_light_color,"background":env.background_color,"mode":env.background_mode,"source":env.ambient_light_source,"sky_material":sky_material,"sky_energy":sky_energy})
 _apply_night(night_amount)

func follow_garden_clock(provider) -> void:
 weather_clock = provider
 if provider != null and not provider.weather_changed.is_connected(_clock_changed): provider.weather_changed.connect(_clock_changed)
 resume_clock()

func resume_clock() -> void:
 manual_override = false
 last_minute = -1
 _clock_changed()

func _clock_changed() -> void:
 if weather_clock == null or manual_override: return
 var timestamp: int = weather_clock.timestamp()
 last_minute = floori(timestamp/60.0)
 _apply_night(Calendar.night_for_hour(fposmod(timestamp/3600.0,24.0)))

func register_catalog(catalog) -> void:
 if not catalogs.has(catalog): catalogs.append(catalog)
 catalog.set_night(night_amount)

func _process(delta: float) -> void:
 if cycle_enabled:
  cycle_time = fposmod(cycle_time+delta,maxf(cycle_duration_seconds,10.0))
  _apply_night((1-cos(cycle_time/maxf(cycle_duration_seconds,10.0)*TAU))*.5)
 elif weather_clock != null and not manual_override and floori(weather_clock.timestamp()/60.0) != last_minute:
  _clock_changed()
 effect_timer += delta
 if effect_timer >= .5:
  effect_timer = 0
  update_decor_lights()

func set_night_amount(amount: float) -> void:
 manual_override = true
 _apply_night(amount)

func _apply_night(amount: float) -> void:
 night_amount = clampf(amount,0,1)
 Builder.set_night(night_amount)
 for catalog in catalogs: catalog.set_night(night_amount)
 for item in suns:
  item.node.light_energy = lerpf(item.energy,.07,night_amount)
  item.node.light_color = item.color.lerp(Color("8699d9"),night_amount)
 for item in environments:
  var env: Environment = item.resource
  env.ambient_light_energy = lerpf(item.energy,.18,night_amount)
  env.ambient_light_color = item.color.lerp(Color("7185b0"),night_amount)
  env.ambient_light_source = item.source if night_amount < .001 else Environment.AMBIENT_SOURCE_COLOR
  if item.mode == Environment.BG_COLOR: env.background_color = item.background.lerp(Color("10172b"),night_amount)
  if item.sky_material is PanoramaSkyMaterial: item.sky_material.energy_multiplier = lerpf(item.sky_energy,.05,night_amount)
  if ProjectSettings.get_setting("rendering/renderer/rendering_method","gl_compatibility") != "gl_compatibility":
   env.glow_enabled = true
   env.glow_intensity = .65
 if world != null and world.has_node("StorybookBackdrop/Countryside"):
  world.get_node("StorybookBackdrop/Countryside").modulate = Color.WHITE.lerp(Color("253452"),night_amount)
 update_decor_lights()
 phase_changed.emit(night_amount)

func update_decor_lights() -> void:
 if world == null or not world.is_inside_tree(): return
 var camera := world.get_viewport().get_camera_3d()
 var nearest := []
 for effect in get_tree().get_nodes_in_group("enchanted_garden_fx"):
  effect.set_phase(night_amount,false)
  if camera == null or night_amount <= .01 or not effect.eligible() or effect.get_world_3d() != world.get_world_3d(): continue
  var distance: float = camera.global_position.distance_squared_to(effect.global_position)
  if distance < 24*24: nearest.append({"effect":effect,"distance":distance})
 nearest.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.distance < b.distance)
 for i in range(mini(MAX_DECOR_LIGHTS,nearest.size())): nearest[i].effect.set_phase(night_amount,true)
