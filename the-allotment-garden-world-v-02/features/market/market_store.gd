extends RefCounted
## Atomic local economy/inventory/placement snapshot. No real-money purchases.
const Stack := preload("res://features/market/stack_rules.gd")
const Growth := preload("res://features/market/plant_growth.gd")
const Catalog := preload("res://features/market/catalog.gd")
const Profiles := preload("res://features/profiles/local_profiles.gd")
const STARTING_RUNES := 1250
var path: String
var data := {"version":1,"runes":STARTING_RUNES,"owned":{},"favorites":[],"placed":[]}
var last_error := ""
var readable := true

func _init(save_path: String = "") -> void:
	path = Profiles.save_root()+"market.json" if save_path.is_empty() else save_path
	if not FileAccess.file_exists(path): return
	var file := FileAccess.open(path,FileAccess.READ)
	var parser := JSON.new()
	if file == null or file.get_length() > 2000000:
		readable = false
	elif parser.parse(file.get_as_text()) != OK or not _valid(parser.data):
		readable = false
	else:
		data = parser.data
	if not readable: last_error = "Your market save could not be read. It has been kept unchanged."

func _valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != 1: return false
	if not _whole(value.get("runes"),0,10000000): return false
	if not value.get("owned") is Dictionary or not value.get("placed") is Array or not value.get("favorites") is Array: return false
	if value.placed.size() > 500 or value.favorites.size() > 6: return false
	var bag = value.get("bag_growth",{})
	if not bag is Dictionary: return false
	for id in bag:
		if Growth.species(id).is_empty() or not bag[id] is Array or bag[id].size() > int(value.owned.get(id,0)): return false
		for age in bag[id]:
			if not (age is int or age is float) or not is_finite(float(age)) or age < 0 or age >= 100000: return false
	for id in value.owned:
		if Catalog.by_id(id).is_empty() or not _whole(value.owned[id],0,999): return false
	var seen := {}
	for id in value.favorites:
		if not id is String or Catalog.by_id(id).is_empty() or seen.has(id): return false
		seen[id] = true
	for placement in value.placed:
		if not placement is Dictionary or not Catalog.placeable(Catalog.by_id(str(placement.get("id","")))): return false
		if placement.get("area","garden") not in ["garden","courtyard"]: return false
		if placement.has("growth") and (Growth.species(placement.id).is_empty() or not Growth.valid_record(placement.growth)): return false
		for key in ["elevation","ground_y"]:
			if placement.has(key):
				var value_at_key = placement[key]
				if not (value_at_key is int or value_at_key is float) or not is_finite(float(value_at_key)): return false
		for key in ["x","z","angle"]:
			var n = placement.get(key)
			if not (n is int or n is float) or not is_finite(float(n)) or absf(float(n)) > 1000: return false
	return Stack.valid_graph(value.placed)

func _whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

func count(id: String) -> int:
	return int(data.owned.get(id,0))

func total_owned(id: String) -> int:
	var total := count(id)
	for placement in data.placed:
		if placement.id == id: total += 1
	return total

func buy(id: String) -> bool:
	var item := Catalog.by_id(id)
	if item.is_empty() or not item.get("available",true): return _fail("This item is not available yet.")
	if count(id) >= 999: return _fail("Your backpack has enough of this item.")
	var next := data.duplicate(true)
	next.owned[id] = count(id)+1
	return _commit(next)

func favorite(id: String) -> bool:
	if Catalog.by_id(id).is_empty(): return false
	var next := data.duplicate(true)
	if next.favorites.has(id): next.favorites.erase(id)
	elif next.favorites.size() < 6: next.favorites.append(id)
	else: return _fail("Your six common-item slots are full. Unpin one first.")
	return _commit(next)

func place(id: String, point: Vector2, angle: float, area: String = "garden", elevation: float = 0.0, supports: Array = [], ground_y: float = 0.0) -> bool:
	if not Catalog.placeable(Catalog.by_id(id)): return _fail("Choose a plant or decoration.")
	if data.placed.size() >= 500: return _fail("This local garden has reached its item limit.")
	var next := data.duplicate(true)
	next.owned[id] = maxi(0,count(id)-1)
	var placement := {"id":id,"x":point.x,"z":point.y,"angle":angle,"area":area,"uid":Crypto.new().generate_random_bytes(12).hex_encode(),"ground_y":ground_y}
	if elevation > 0:
		placement.elevation = elevation
		placement.supports = supports.duplicate()
	var growth := Growth.new_record(id,Time.get_unix_time_from_system())
	var bag: Dictionary = next.get("bag_growth",{}).duplicate(true)
	if not growth.is_empty() and bag.has(id) and not bag[id].is_empty():
		growth.initial_age_days = bag[id].pop_front()
		growth.observed_age_days = growth.initial_age_days
	next.bag_growth = bag
	if not growth.is_empty(): placement.growth = growth
	next.placed.append(placement)
	return _commit(next)

func ensure_placement_ids(sample_ground: Callable) -> bool:
	var next: Dictionary = data.duplicate(true)
	var changed := false
	for record in next.placed:
		if not record.has("uid"):
			record.uid = Crypto.new().generate_random_bytes(12).hex_encode()
			changed = true
		if not record.has("ground_y"):
			record.ground_y = sample_ground.call(record)
			changed = true
	return _commit(next) if changed else readable

func retrieve(index: int) -> bool:
	if index < 0 or index >= data.placed.size(): return false
	var uid: String = data.placed[index].get("uid","")
	for record in data.placed:
		if not uid.is_empty() and record.get("supports",[]).has(uid):
			return _fail("Remove the pieces above this support first.")
	var id: String = data.placed[index].id
	var plant := Growth.species(id)
	var age := -1.0
	if not plant.is_empty():
		age = Growth.age_days(data.placed[index],Time.get_unix_time_from_system())
		var stage: int = Growth.state(plant,age).stage
		# Bag stacks preserve the achieved stage; young plants never become mature on pickup.
		id = Catalog.stage_id(id,stage if stage != 1 else 0)
	if count(id) >= 999: return _fail("This backpack stack is full.")
	var next := data.duplicate(true)
	next.placed.remove_at(index)
	next.owned[id] = count(id)+1
	if age >= 0:
		next.bag_growth = next.get("bag_growth",{}).duplicate(true)
		if not next.bag_growth.has(id): next.bag_growth[id] = []
		next.bag_growth[id].append(age)
	return _commit(next)

func _fail(message: String) -> bool:
	last_error = message
	return false

func _commit(next: Dictionary) -> bool:
	if not readable: return false
	if not _valid(next): return _fail("The change could not be saved.")
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir())) != OK: return _fail("The save folder could not be created.")
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return _fail("Your purchase could not be saved. No Runes were spent.")
	file.store_string(JSON.stringify(next))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path)) != OK:
		return _fail("The change could not be saved. Your previous save is unchanged.")
	data = next
	last_error = ""
	return true
