extends SceneTree
const Master = preload("res://features/item_catalog/master_catalog.gd")
const Router = preload("res://features/item_catalog/behavior_router.gd")
const Catalog = preload("res://features/market/catalog.gd")
const Store = preload("res://features/market/market_store.gd")
const Gate = preload("res://assets/garden_art/gate_controller.gd")

func _initialize() -> void:
	var master = Master.shared()
	assert(master.error.is_empty(),master.error)
	assert(master.items.size()==263)
	for id in master.items:
		var item: Dictionary = master.by_id(id)
		if item.domain=="shop": assert(JSON.parse_string(JSON.stringify(Catalog.by_id(id)))==item.legacy_shop_data,"Legacy shop data changed: "+id)
	assert(master.by_id(Catalog.ATRIUM.ID).shop_listing.effective_price==Catalog.rune_cost(Catalog.by_id(Catalog.ATRIUM.ID)))
	assert(master.by_id("unknown").is_empty())
	assert(Catalog.by_id("rose@adult").is_empty())
	assert(Catalog.by_id("bench@seed").is_empty())
	assert(Catalog.by_id("rose@seed@young").is_empty())
	assert(master.variants("rose").size()==3)
	assert(master.search("rose","shop:Plants",100).size()>0)
	assert(master.search("", "surface:Borders",100).size()==1)
	assert(master.resolve_asset("unknown").is_empty())
	assert(master.resolve_asset("recipe:bench").available)
	var bench: Dictionary = master.by_id("bench")
	bench.name="mutation"
	assert(master.by_id("bench").name!="mutation","Lookup exposed mutable shared state")
	var file=FileAccess.open("res://data/items/catalog.v1.json",FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	var index=Master.new()
	assert(index.load_data(data))
	var broken=data.duplicate(true)
	broken.schema_version="2"
	assert(not index.load_data(broken) and index.items.size()==263)
	broken=data.duplicate(true);broken.items.append(broken.items[0])
	assert(not index.load_data(broken))
	broken=data.duplicate(true);broken.items[0].asset_bindings=[{"asset_id":"missing"}]
	assert(not index.load_data(broken))
	broken=data.duplicate(true);broken.items[0].parent_id=broken.items[0].item_id
	assert(not index.load_data(broken))
	broken=data.duplicate(true);broken.assets[0].path="../escape.gd"
	assert(not index.load_data(broken))
	broken=data.duplicate(true);broken.items[0].category_id="missing"
	assert(not index.load_data(broken))
	broken=data.duplicate(true);broken.items[0].physical={"dimensions_m":[-1,1,1]}
	assert(not index.load_data(broken))
	assert(Master.load_catalog("user://nonexistent-catalog-test.json").items.is_empty())
	var gate=Gate.new()
	assert(Router.invoke("garden_gate","gate.proximity",gate,{"open":true}) and gate.opened)
	assert(not Router.invoke("bench","gate.proximity",gate,{"open":true}))
	assert(not Router.invoke("bench","furniture.sit",gate))
	assert(not Router.invoke("garden_gate","gate.proximity",gate,{"open":"bad"}))
	gate.free()
	var store=Store.new("user://item-catalog-test-market.json")
	assert(Router.invoke("bench","market.acquire",store))
	assert(store.count("bench")>0)
	var reload=Store.new(store.path)
	assert(reload.count("bench")==store.count("bench"))
	DirAccess.remove_absolute(store.path)
	# A large metadata catalog does not instantiate high-detail assets.
	var large=data.duplicate(true)
	large.items=[]
	for i in range(10000):
		var row=bench.duplicate(true)
		row.item_id="performance:"+str(i)
		row.parent_id=null
		large.items.append(row)
	var started:=Time.get_ticks_msec()
	assert(index.load_data(large))
	for i in range(10000): assert(not index.by_id("performance:"+str(i)).is_empty())
	var elapsed:=Time.get_ticks_msec()-started
	assert(elapsed<5000,"10,000 record validation and indexed lookups exceeded 5 seconds")
	print("PASS: item catalog, all legacy listings, shared references, guarded behaviors, saves, malformed data and 10,000 records; ms=",elapsed)
	quit(0)
