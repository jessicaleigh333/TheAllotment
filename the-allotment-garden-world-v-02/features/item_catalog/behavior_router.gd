extends RefCounted
## Explicit adapters to existing controllers. Data cannot invoke arbitrary methods.
const Master = preload("res://features/item_catalog/master_catalog.gd")

static func invoke(item_id: String, action: String, target: Object, arguments: Dictionary = {}) -> bool:
	if not is_instance_valid(target): return false
	var catalog = Master.shared()
	var item: Dictionary = catalog.by_id(item_id)
	if item.is_empty() or not action in item.get("behavior_ids",[]): return false
	var source: Script = target.get_script()
	if source == null: return false
	match action:
		"gate.proximity":
			if source.resource_path != "res://assets/garden_art/gate_controller.gd" or not arguments.get("open") is bool: return false
			target.set_open(arguments.open)
			return true
		"market.acquire":
			if source.resource_path != "res://features/market/market_store.gd": return false
			return target.buy(item_id)
		"inventory.retrieve":
			if source.resource_path != "res://features/market/market_store.gd" or not arguments.get("index") is int: return false
			var index: int = arguments.index
			if index < 0 or index >= target.data.placed.size() or target.data.placed[index].id != item_id: return false
			return target.retrieve(index)
		"placement.world":
			if source.resource_path != "res://features/market/garden_placement.gd": return false
			var area: String = str(arguments.get("area","courtyard"))
			if area not in ["garden","courtyard"]: return false
			return target.begin(item_id,area)
	# Scientific, craft, sale, sit, repair, and manual lighting contracts are not executable.
	return false
