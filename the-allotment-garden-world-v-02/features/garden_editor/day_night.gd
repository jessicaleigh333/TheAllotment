extends Node
## Reusable lighting/day-night driver. No per-stone lights.
signal phase_changed(night_amount: float)
@export var cycle_enabled := false
@export var cycle_duration_seconds := 600.0
var night_amount := 0.0
var cycle_time := 0.0
var world: Node3D
var catalogs: Array = []
var suns: Array = []
var environments: Array = []

func configure(target: Node3D) -> void:
	world = target
	for child in world.get_children():
		if child is DirectionalLight3D:
			suns.append({"node": child, "energy": child.light_energy, "color": child.light_color})
		if child is WorldEnvironment:
			var env: Environment = child.environment
			environments.append({"resource": env, "energy": env.ambient_light_energy, "color": env.ambient_light_color, "background": env.background_color, "mode": env.background_mode})
	set_night_amount(night_amount)

func register_catalog(catalog) -> void:
	if not catalogs.has(catalog): catalogs.append(catalog)
	catalog.set_night(night_amount)

func _process(delta: float) -> void:
	if cycle_enabled:
		cycle_time = fposmod(cycle_time + delta, maxf(cycle_duration_seconds, 10.0))
		set_night_amount((1.0 - cos(cycle_time / maxf(cycle_duration_seconds, 10.0) * TAU)) * 0.5)

func set_night_amount(amount: float) -> void:
	night_amount = clampf(amount, 0.0, 1.0)
	for catalog in catalogs: catalog.set_night(night_amount)
	for item in suns:
		item.node.light_energy = lerpf(item.energy, 0.07, night_amount)
		item.node.light_color = item.color.lerp(Color("8699d9"), night_amount)
	for item in environments:
		var env: Environment = item.resource
		env.ambient_light_energy = lerpf(item.energy, 0.16, night_amount)
		env.ambient_light_color = item.color.lerp(Color("5b6e9d"), night_amount)
		if item.mode == Environment.BG_COLOR: env.background_color = item.background.lerp(Color("142138"), night_amount)
		# Godot Compatibility does not implement bloom; emission still renders.
		if ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility") != "gl_compatibility":
			env.glow_enabled = true
			env.glow_intensity = 0.8
	if world != null and world.has_node("StorybookBackdrop/Countryside"):
		world.get_node("StorybookBackdrop/Countryside").modulate = Color.WHITE.lerp(Color("354571"), night_amount)
	phase_changed.emit(night_amount)
