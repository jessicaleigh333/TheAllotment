extends Node3D
## Editable half-metre terrain cells, batched by chunk and normalized appearance.
## All mutating entry points require an explicit owner/actor match.
signal changed
signal operation_committed(operation: Dictionary)
const Catalog := preload("res://features/garden_editor/ground_cover/catalog.gd")
const CELL_SIZE := 0.5
const CHUNK_CELLS := 16
const MAX_CELLS := 60000
const MAX_HISTORY := 64
var catalog = Catalog.new()
var cells: Dictionary = {}
var context_id := ""
var actor_id := ""
var owner_id := ""
var world_seed := 0
var scope_bounds := Rect2()
var height_at: Callable
var point_allowed: Callable
var protected_regions: Array[Rect2] = []
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var transaction := false
var before: Dictionary = {}
var chunk_index: Dictionary = {}
var chunk_nodes: Dictionary = {}
var dirty_chunks: Dictionary = {}
var render_pending := false
var revision := 0
var last_error := ""

func configure(context: String, owner: String, actor: String, seed: int, bounds: Rect2, contains_callback: Callable, height_callback: Callable, obstacles: Array[Rect2] = []) -> void:
	context_id = context
	owner_id = owner
	actor_id = actor
	world_seed = seed
	scope_bounds = bounds
	point_allowed = contains_callback
	height_at = height_callback
	protected_regions = obstacles

func can_edit() -> bool:
	return not owner_id.is_empty() and owner_id == actor_id and not context_id.is_empty() and point_allowed.is_valid() and height_at.is_valid()

func _authorize() -> bool:
	if can_edit(): return true
	last_error = "This garden is read-only. Only its owner can landscape it."
	return false

func _key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]

func _coord(key: String) -> Vector2i:
	var parts := key.split(":")
	return Vector2i(int(parts[0]), int(parts[1]))

func _chunk(cell: Vector2i) -> String:
	return "%d:%d" % [floori(float(cell.x) / CHUNK_CELLS), floori(float(cell.y) / CHUNK_CELLS)]

func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE

func _cell_allowed(cell: Vector2i) -> bool:
	var low := Vector2(cell) * CELL_SIZE
	var rect := Rect2(low, Vector2.ONE * CELL_SIZE)
	if not scope_bounds.encloses(rect): return false
	for obstacle in protected_regions:
		if rect.intersects(obstacle, true): return false
	for offset in [Vector2.ZERO, Vector2(CELL_SIZE, 0), Vector2(0, CELL_SIZE), Vector2.ONE * CELL_SIZE, Vector2.ONE * CELL_SIZE * 0.5]:
		var point: Vector2 = low + offset
		if not point_allowed.call(point) or not is_finite(float(height_at.call(point))): return false
	return true

func begin_stroke() -> bool:
	if not _authorize(): return false
	if transaction: return true
	transaction = true
	before.clear()
	last_error = ""
	return true

func _remember(key: String) -> void:
	if not before.has(key): before[key] = cells.get(key, {}).duplicate(true)

func _set_cell(key: String, style: Dictionary) -> void:
	var cell := _coord(key)
	var chunk := _chunk(cell)
	if style.is_empty():
		cells.erase(key)
		if chunk_index.has(chunk): chunk_index[chunk].erase(key)
	else:
		cells[key] = style
		if not chunk_index.has(chunk): chunk_index[chunk] = {}
		chunk_index[chunk][key] = true
	dirty_chunks[chunk] = true
	for neighbor in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]: dirty_chunks[_chunk(cell + neighbor)] = true
	if not render_pending:
		render_pending = true
		call_deferred("flush_meshes")

func apply_shape(shape: Dictionary, appearance: Dictionary, action: String = "paint", border: Dictionary = {}) -> int:
	if not _authorize(): return 0
	var own_transaction := not transaction
	if own_transaction and not begin_stroke(): return 0
	var style := catalog.validate_style(appearance)
	if style.is_empty() and action != "erase":
		last_error = "Unknown material or invalid customization."
		if own_transaction: cancel_stroke()
		return 0
	var border_style := catalog.validate_style(border.get("style", {}))
	var border_width := clampf(float(border.get("width", 0.0)), 0.0, 3.0) if not border_style.is_empty() and action == "paint" else 0.0
	var bounds := _shape_bounds(shape).grow(border_width + CELL_SIZE)
	bounds = bounds.intersection(scope_bounds)
	if not bounds.has_area():
		if own_transaction: commit_stroke()
		return 0
	var low := Vector2i(floori(bounds.position.x / CELL_SIZE), floori(bounds.position.y / CELL_SIZE))
	var high := Vector2i(ceili(bounds.end.x / CELL_SIZE), ceili(bounds.end.y / CELL_SIZE))
	var count := 0
	for x in range(low.x, high.x):
		for y in range(low.y, high.y):
			var cell := Vector2i(x, y)
			var signed_distance := _shape_distance(cell_center(cell), shape)
			if signed_distance > border_width: continue
			if not _cell_allowed(cell): continue
			var key := _key(cell)
			var value: Dictionary = style if signed_distance <= 0.0 else border_style
			if action == "erase":
				if signed_distance > 0.0 or not cells.has(key): continue
				value = {}
			elif action == "recolor":
				if signed_distance > 0.0 or not cells.has(key): continue
				value = cells[key].duplicate(true)
				for field in ["base", "joint", "accent", "roughness", "metallic", "brightness", "saturation", "glow_enabled", "glow_color", "glow_secondary", "glow_intensity", "glow_mode", "glow_palette", "detail_id", "detail_amount"]: value[field] = style[field]
			if value == cells.get(key, {}): continue
			if not value.is_empty() and not cells.has(key) and cells.size() >= MAX_CELLS:
				last_error = "This garden reached its ground-cover limit. Erase an area to make room."
				continue
			_remember(key)
			_set_cell(key, value)
			count += 1
	if own_transaction: commit_stroke()
	return count

func _shape_bounds(shape: Dictionary) -> Rect2:
	var points: Array = shape.get("points", [])
	if points.is_empty(): return Rect2()
	if str(shape.get("type", "")) == "circle" and points.size() > 1:
		var radius: float = points[0].distance_to(points[1])
		return Rect2(points[0] - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	var low: Vector2 = points[0]
	var high := low
	for point in points:
		low = low.min(point)
		high = high.max(point)
	var width := clampf(float(shape.get("width", 1.0)), 0.5, 30.0)
	return Rect2(low, high - low).grow(width / 2.0)

func _shape_distance(point: Vector2, shape: Dictionary) -> float:
	var points: Array = shape.get("points", [])
	if points.is_empty(): return INF
	var radius := clampf(float(shape.get("width", 1.0)), 0.5, 30.0) / 2.0
	match str(shape.get("type", "brush")):
		"rectangle":
			if points.size() < 2: return INF
			var center: Vector2 = (points[0] + points[1]) * 0.5
			var half: Vector2 = (points[1] - points[0]).abs() * 0.5
			var d: Vector2 = (point - center).abs() - half
			return d.max(Vector2.ZERO).length() + minf(maxf(d.x, d.y), 0.0)
		"circle":
			if points.size() > 1: radius = points[0].distance_to(points[1])
			return point.distance_to(points[0]) - radius
		"line", "curve":
			var distance := INF
			for i in range(points.size() - 1):
				distance = minf(distance, point.distance_to(Geometry2D.get_closest_point_to_segment(point, points[i], points[i + 1])))
			return distance - radius
		_: return point.distance_to(points[0]) - radius

func commit_stroke() -> bool:
	if not transaction: return false
	if not _authorize():
		cancel_stroke()
		return false
	transaction = false
	var after: Dictionary = {}
	var prior: Dictionary = {}
	for key in before:
		var value: Dictionary = cells.get(key, {})
		if value != before[key]:
			prior[key] = before[key]
			after[key] = value.duplicate(true)
	before.clear()
	if after.is_empty(): return false
	undo_stack.append({"before": prior, "after": after})
	if undo_stack.size() > MAX_HISTORY: undo_stack.pop_front()
	redo_stack.clear()
	revision += 1
	operation_committed.emit({"context_id": context_id, "actor_id": actor_id, "world_seed": world_seed, "revision": revision, "changes": after.duplicate(true)})
	changed.emit()
	return true

func cancel_stroke() -> void:
	if not transaction: return
	for key in before: _set_cell(key, before[key])
	before.clear()
	transaction = false

func undo() -> bool:
	if not _authorize() or transaction or undo_stack.is_empty(): return false
	var operation: Dictionary = undo_stack.pop_back()
	for key in operation.before: _set_cell(key, operation.before[key])
	redo_stack.append(operation)
	_emit_history_operation(operation.before)
	return true

func redo() -> bool:
	if not _authorize() or transaction or redo_stack.is_empty(): return false
	var operation: Dictionary = redo_stack.pop_back()
	for key in operation.after: _set_cell(key, operation.after[key])
	undo_stack.append(operation)
	_emit_history_operation(operation.after)
	return true

func _emit_history_operation(changes: Dictionary) -> void:
	revision += 1
	operation_committed.emit({"context_id": context_id, "actor_id": actor_id, "world_seed": world_seed, "revision": revision, "changes": changes.duplicate(true)})
	changed.emit()

func sample_style(point: Vector2) -> Dictionary:
	return cells.get(_key(Vector2i(floori(point.x / CELL_SIZE), floori(point.y / CELL_SIZE))), {}).duplicate(true)

func flush_meshes() -> void:
	render_pending = false
	var work := dirty_chunks.keys()
	dirty_chunks.clear()
	for chunk in work:
		if chunk_nodes.has(chunk):
			chunk_nodes[chunk].free()
			chunk_nodes.erase(chunk)
		var keys: Dictionary = chunk_index.get(chunk, {})
		if keys.is_empty(): continue
		var groups: Dictionary = {}
		for key in keys:
			var style: Dictionary = cells[key]
			var material_key := catalog.style_key(style)
			if not groups.has(material_key): groups[material_key] = {"style": style, "keys": []}
			groups[material_key].keys.append(key)
		var group_node := Node3D.new()
		group_node.name = "Chunk_" + str(chunk).replace(":", "_")
		add_child(group_node)
		chunk_nodes[chunk] = group_node
		for group in groups.values():
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for key in group.keys: _add_cell(surface, _coord(key), group.style)
			var mesh := MeshInstance3D.new()
			mesh.mesh = surface.commit()
			mesh.material_override = catalog.material_for(group.style)
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			group_node.add_child(mesh)

func _add_cell(surface: SurfaceTool, cell: Vector2i, style: Dictionary) -> void:
	var low := Vector2(cell) * CELL_SIZE
	var corners := [low, low + Vector2(CELL_SIZE, 0), low + Vector2.ONE * CELL_SIZE, low + Vector2(0, CELL_SIZE)]
	var heights: Array[float] = []
	for corner in corners: heights.append(float(height_at.call(corner)) + 0.025)
	var normal := Vector3(-(heights[1] - heights[0]) / CELL_SIZE, 1.0, -(heights[3] - heights[0]) / CELL_SIZE).normalized()
	surface.set_normal(normal)
	var edge := Color(0, 0, 0, 0)
	edge.r = 0.0 if cells.get(_key(cell + Vector2i.LEFT), {}) == style else 1.0
	edge.g = 0.0 if cells.get(_key(cell + Vector2i.RIGHT), {}) == style else 1.0
	edge.b = 0.0 if cells.get(_key(cell + Vector2i.UP), {}) == style else 1.0
	edge.a = 0.0 if cells.get(_key(cell + Vector2i.DOWN), {}) == style else 1.0
	surface.set_color(edge)
	for index in [0, 1, 2, 0, 2, 3]:
		var point: Vector2 = corners[index]
		surface.set_uv(point)
		surface.add_vertex(Vector3(point.x, heights[index], point.y))

func snapshot() -> Dictionary:
	var styles: Array[Dictionary] = []
	var style_indices: Dictionary = {}
	var records: Array = []
	var sorted_keys := cells.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		var style: Dictionary = cells[key]
		var signature := catalog.style_key(style)
		if not style_indices.has(signature):
			style_indices[signature] = styles.size()
			styles.append(style)
		var coord := _coord(key)
		records.append([coord.x, coord.y, style_indices[signature]])
	return {"schema_version": 1, "context_id": context_id, "owner_id": owner_id, "world_seed": world_seed, "cell_size": CELL_SIZE, "styles": styles, "cells": records}

func restore_snapshot(data: Variant) -> bool:
	if not _authorize() or transaction: return false
	if not data is Dictionary or int(data.get("schema_version", 0)) != 1:
		last_error = "Unsupported ground-cover save format."
		return false
	if data.get("context_id") != context_id or data.get("owner_id") != owner_id or int(data.get("world_seed", -1)) != world_seed or float(data.get("cell_size", 0)) != CELL_SIZE:
		last_error = "This save belongs to a different garden, owner or terrain seed."
		return false
	var records = data.get("cells", [])
	var raw_styles = data.get("styles", [])
	if not records is Array or records.size() > MAX_CELLS or not raw_styles is Array:
		last_error = "Invalid saved ground-cover data."
		return false
	var styles: Array[Dictionary] = []
	for value in raw_styles:
		var normalized := catalog.validate_style(value)
		if normalized.is_empty():
			last_error = "A saved material is unavailable or invalid."
			return false
		styles.append(normalized)
	var restored: Dictionary = {}
	for record in records:
		if not record is Array or record.size() != 3:
			last_error = "Invalid saved cell."
			return false
		for value in record:
			if (not value is int and not value is float) or not is_finite(float(value)) or float(value) != floorf(float(value)) or absf(float(value)) > 10000000.0:
				last_error = "Invalid saved coordinates."
				return false
		var coordinate := Vector2i(int(record[0]), int(record[1]))
		var index := int(record[2])
		if index < 0 or index >= styles.size() or not _cell_allowed(coordinate):
			last_error = "Saved surfaces overlap a protected structure or leave this garden."
			return false
		var key := _key(coordinate)
		if restored.has(key):
			last_error = "Duplicate saved cell."
			return false
		restored[key] = styles[index]
	begin_stroke()
	for key in cells.keys():
		_remember(key)
		_set_cell(key, {})
	for key in restored:
		_remember(key)
		_set_cell(key, restored[key])
	commit_stroke()
	last_error = ""
	return true

func default_save_path() -> String:
	return "user://ground_cover/" + context_id.validate_filename() + ".json"

func save_to(path: String = "") -> bool:
	if not _authorize() or transaction: return false
	if path.is_empty(): path = default_save_path()
	var directory := ProjectSettings.globalize_path(path.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		last_error = "Could not create the save folder."
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Could not write the ground-cover save."
		return false
	file.store_string(JSON.stringify(snapshot()))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path)) != OK:
		last_error = "Could not finish saving. The previous save was preserved."
		return false
	last_error = ""
	return true

func load_from(path: String = "") -> bool:
	if not _authorize(): return false
	if path.is_empty(): path = default_save_path()
	if not FileAccess.file_exists(path):
		last_error = "No saved landscaping exists for this garden yet."
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 32000000:
		last_error = "The landscaping save cannot be read."
		return false
	return restore_snapshot(JSON.parse_string(file.get_as_text()))
