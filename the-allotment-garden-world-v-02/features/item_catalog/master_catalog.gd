extends RefCounted
## Metadata-only index. Never loads meshes, scripts or player saves from data paths.
const VERSION := "1.0.0"
const DEFAULT_PATH := "res://data/items/catalog.v1.json"
var items := {}
var assets := {}
var behaviors := {}
var categories := {}
var error := ""
static var _default: RefCounted

static func shared() -> RefCounted:
	if _default == null:
		_default = load_catalog(DEFAULT_PATH)
	return _default

static func index_sources(sources: Array) -> Dictionary:
	var index := {}
	for item in sources:
		if not item is Dictionary or not item.get("id") is String or item.id.is_empty() or index.has(item.id): return {}
		index[item.id] = item.duplicate(true)
	return index

static func load_catalog(path: String) -> RefCounted:
	var result = load("res://features/item_catalog/master_catalog.gd").new()
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > 32000000:
		result.error = "Missing or oversized catalog"
		return result
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		result.error = "Malformed catalog JSON"
		return result
	result.load_data(parser.data)
	return result

func load_data(data: Variant) -> bool:
	# Validate into temporary indexes: a bad replacement cannot destroy a good index.
	if not data is Dictionary or data.get("schema_version") != VERSION:
		error = "Unsupported catalog schema"
		return false
	var new_items := {}
	var new_assets := {}
	var new_behaviors := {}
	var new_categories := {}
	for pair in [["assets","asset_id",new_assets],["behaviors","behavior_id",new_behaviors],["items","item_id",new_items],["categories","category_id",new_categories]]:
		if not data.get(pair[0]) is Array:
			error = "Missing record collection"
			return false
		for record in data[pair[0]]:
			if not record is Dictionary or not record.get(pair[1]) is String or str(record[pair[1]]).is_empty() or pair[2].has(record[pair[1]]):
				error = "Missing or duplicate stable ID"
				return false
			pair[2][record[pair[1]]] = record.duplicate(true)
	for asset in new_assets.values():
		var asset_path: String = str(asset.get("path",""))
		if asset_path.is_empty() or asset_path.is_absolute_path() or asset_path.contains("..") or asset_path.contains(":") or asset_path.contains("\\"):
			error = "Unsafe asset reference"
			return false
	for record in new_items.values():
		if not record.get("name") is String or not record.get("category_id") is String:
			error = "Missing item name/category"
			return false
		if not new_categories.has(record.category_id):
			error = "Unknown category"
			return false
		if not record.get("asset_bindings",[]) is Array or not record.get("behavior_ids",[]) is Array or not record.get("tags",[]) is Array:
			error = "Malformed binding collection"
			return false
		if not record.get("physical",{}) is Dictionary:
			error = "Malformed physical definition"
			return false
		var dimensions: Variant = record.get("physical",{}).get("dimensions_m")
		if dimensions != null:
			if not dimensions is Array or dimensions.size()!=3:
				error = "Malformed metre dimensions"
				return false
			for number in dimensions:
				if not (number is float or number is int) or not is_finite(float(number)) or number <= 0:
					error = "Invalid metre dimensions"
					return false
		if record.get("parent_id") != null and not new_items.has(record.parent_id):
			error = "Unknown variant parent"
			return false
		var seen := {}
		var parent: Variant = record.item_id
		while parent != null:
			if not parent is String or not new_items.has(parent):
				error = "Unknown variant ancestor"
				return false
			if seen.has(parent):
				error = "Variant cycle"
				return false
			seen[parent] = true
			parent = new_items[parent].get("parent_id")
		for binding in record.get("asset_bindings",[]):
			if not binding is Dictionary or not new_assets.has(binding.get("asset_id","")):
				error = "Unknown shared asset"
				return false
		for id in record.get("behavior_ids",[]):
			if not new_behaviors.has(id):
				error = "Unknown behavior"
				return false
	items = new_items
	assets = new_assets
	behaviors = new_behaviors
	categories.clear()
	for record in items.values():
		if not categories.has(record.category_id): categories[record.category_id] = []
		categories[record.category_id].append(record.item_id)
	error = ""
	return true

func by_id(id: String) -> Dictionary:
	return items.get(id,{}).duplicate(true)

func search(query: String = "", category: String = "", limit: int = 100) -> Array:
	var result := []
	if limit <= 0: return result
	var terms := query.to_lower().split(" ",false)
	var candidates: Array = categories.get(category,[]) if not category.is_empty() else items.keys()
	for id in candidates:
		var item: Dictionary = items[id]
		var haystack := (str(item.name)+" "+str(item.get("description",""))+" "+str(item.get("tags",[]))+" "+str(id)).to_lower()
		var matched := true
		for term in terms:
			if not haystack.contains(term): matched = false
		if matched: result.append(item.duplicate(true))
		if result.size() >= limit: break
	return result

func resolve_asset(asset_id: String) -> Dictionary:
	if not assets.has(asset_id): return {}
	var result: Dictionary = assets[asset_id].duplicate(true)
	var path: String = "res://"+str(result.path)
	result["available"] = ResourceLoader.exists(path) or FileAccess.file_exists(path)
	# Caller receives validated metadata, never arbitrary load()/script execution.
	return result

func variants(id: String) -> Array:
	var result := []
	for record in items.values():
		if record.get("parent_id") == id: result.append(record.duplicate(true))
	return result
