extends SubViewportContainer
## Actual shader renders, not placeholder catalog swatches. Each viewport renders once.
var view: SubViewport
var tile: MeshInstance3D
var catalog
var appearance: Dictionary = {}

func setup(material_catalog, style: Dictionary, dimensions: Vector2i = Vector2i(92, 78)) -> void:
	catalog = material_catalog
	custom_minimum_size = Vector2(dimensions)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	view = SubViewport.new()
	view.size = dimensions
	view.own_world_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(view)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.9
	camera.position = Vector3(2.8, 4.0, 3.4)
	view.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("ede4ce")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff1d5")
	env.ambient_light_energy = 0.8
	environment.environment = env
	view.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-65, -30, 0)
	light.light_energy = 0.7
	view.add_child(light)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.UP)
	surface.set_color(Color(0, 0, 0, 0))
	for point in [Vector2(-1.5, -1.5), Vector2(1.5, -1.5), Vector2(1.5, 1.5), Vector2(-1.5, -1.5), Vector2(1.5, 1.5), Vector2(-1.5, 1.5)]:
		surface.set_uv(point)
		surface.add_vertex(Vector3(point.x, 0, point.y))
	tile = MeshInstance3D.new()
	tile.mesh = surface.commit()
	view.add_child(tile)
	set_style(style)

func set_style(style: Dictionary) -> void:
	appearance = style.duplicate(true)
	tile.material_override = catalog.material_for(appearance)
	view.render_target_update_mode = SubViewport.UPDATE_ONCE

func refresh() -> void:
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
