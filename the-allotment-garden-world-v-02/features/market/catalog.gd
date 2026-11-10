extends RefCounted
const Growth := preload("res://features/market/plant_growth.gd")
const ATLAS := preload("res://features/market/item_atlas.png")
const BASE_ITEMS := [
	{"id":"garden_gate","name":"Wrought-iron garden gates","category":"Decor","price":0,"icon":8,"radius":1.9,"featured":true,"description":"Paired scrolling iron gates on limestone piers. Opens automatically as the gardener approaches. 3 m wide, 2 m tall."},
	{"id":"timber_gate","name":"Timber garden gates","category":"Decor","price":0,"icon":8,"radius":1.7,"description":"An arched pair of timber gates with metal hinges. Opens as the gardener approaches. 2.4 m wide, 1.3 m tall."},
	{"id":"rock_wall","name":"Rock wall · straight","category":"Decor","price":0,"icon":10,"radius":1.05,"description":"A 2 m limestone and fieldstone border with staggered stones and a coping cap. Place near another wall end to connect."},
	{"id":"rock_wall_corner","name":"Rock wall · corner","category":"Decor","price":0,"icon":10,"radius":1.45,"description":"An L-shaped 2 m corner with capped stone courses. Rotate to turn your border."},
	{"id":"rock_wall_end","name":"Rock wall · end pier","category":"Decor","price":0,"icon":10,"radius":.45,"description":"A 0.6 m square stone end pier, 1.35 m tall. Finish a border or frame an opening."},
	{"id":"sunflower","name":"Sunflower","latin":"Helianthus annuus","category":"Plants","price":25,"icon":0,"radius":.5,"season":"Summer","sun":"Full sun","water":"Moderate","description":"Golden faces and tall stems bring a sunny focal point to a border."},
	{"id":"rose","name":"Rose bush","latin":"Rosa","category":"Plants","price":35,"icon":1,"radius":.75,"season":"Summer","sun":"Full sun","water":"Moderate","description":"Soft pink blooms and rounded foliage for a romantic cottage garden."},
	{"id":"lavender","name":"Lavender","latin":"Lavandula angustifolia","category":"Plants","price":18,"icon":2,"radius":.5,"season":"Summer","sun":"Full sun","water":"Low","description":"Fragrant purple flower spikes suit sunny paths and dry borders."},
	{"id":"hydrangea","name":"Hydrangea","latin":"Hydrangea macrophylla","category":"Plants","price":45,"icon":3,"radius":.9,"season":"Summer","sun":"Part shade","water":"Regular","description":"Clouds of blue-violet flowers make a generous leafy border."},
	{"id":"cosmos","name":"Cosmos","latin":"Cosmos bipinnatus","category":"Plants","price":16,"icon":4,"radius":.5,"season":"Summer–Autumn","sun":"Full sun","water":"Moderate","description":"Airy pink flowers soften informal planting beds."},
	{"id":"daisy","name":"Daisy clump","latin":"Leucanthemum × superbum","category":"Plants","price":12,"icon":5,"radius":.45,"season":"Summer","sun":"Sun / part shade","water":"Moderate","description":"Cheerful white petals and gold centers in a compact perennial clump."},
	{"id":"sunflower_seeds","name":"Sunflower seeds","category":"Seeds","price":6,"icon":6,"radius":.5,"description":"Sow seeds and watch them develop over real days and weeks."},
	{"id":"basil_seeds","name":"Basil seeds","category":"Seeds","price":5,"icon":7,"radius":.3,"description":"Sow sweet basil and watch it develop over real days and weeks."},
	{"id":"rose_arch","name":"Climbing rose arch","category":"Decor","price":125,"icon":8,"radius":1.5,"featured":true,"description":"A timber entrance with climbing foliage and pink roses. Keep room around its posts."},
	{"id":"bench","name":"Garden bench","category":"Decor","price":180,"icon":9,"radius":1.4,"featured":true,"description":"A simple timber bench for a peaceful corner of the garden."},
	{"id":"fountain","name":"Stone garden fountain","category":"Decor","price":350,"icon":10,"radius":1.35,"featured":true,"description":"A tiered stone centerpiece with flowing streams and rippling water."},
	{"id":"lantern","name":"Garden lantern","category":"Decor","price":60,"icon":11,"radius":.35,"description":"A small brass garden lantern with a warm glowing center."},
	{"id":"trellis","name":"Flower trellis","category":"Decor","price":45,"icon":12,"radius":1.0,"featured":true,"description":"A timber lattice with climbing flowers for an informal garden backdrop."},
	{"id":"planter","name":"Terracotta planter","category":"Decor","price":28,"icon":13,"radius":.7,"description":"A warm terracotta pot filled with colorful flowers."},
	{"id":"straw_hat","name":"Flower-trimmed straw hat","category":"Avatar","price":120,"icon":14,"radius":0,"description":"Equip the gardener's existing straw hat and flower band."},
	{"id":"watering_can","name":"Watering can","category":"Tools","price":20,"icon":15,"radius":.5,"description":"A decorative metal watering can. Plant watering gameplay is not connected yet."},
	{"id":"basil","name":"Sweet basil","latin":"Ocimum basilicum","category":"Plants","price":0,"icon":7,"radius":.3,"season":"Summer","sun":"Full sun","water":"Moderate","description":"A leafy culinary herb with branching stems and paired green leaves."},
]

const ITEMS := BASE_ITEMS+preload("res://assets/garden_art/french_collection.gd").CATALOG

static func by_id(id: String) -> Dictionary:
	if id.count("@") > 1: return {}
	var base := id.get_slice("@",0)
	var suffix := id.get_slice("@",1)
	if id.contains("@") and suffix not in ["seed","seedling","young"]: return {}
	for source in ITEMS:
		if source.id != base: continue
		if id.contains("@") and (not Growth.PLANTS.has(base) or source.category != "Plants"): return {}
		var item: Dictionary = source.duplicate(true)
		item.id = id
		var plant := Growth.species(id)
		if not plant.is_empty():
			var stage := Growth.starting_stage(id)
			item.plant = plant
			item.growth_stage = stage
			item.radius = maxf(float(item.radius),float(Growth.PLANTS[plant].width)*.5+.05)
			if id.contains("@"):
				item.name += " · "+Growth.STAGES[stage]
				if stage == 0: item.category = "Seeds"
		return item
	return {}

static func stage_id(id: String, stage: int) -> String:
	var plant := Growth.species(id)
	if plant.is_empty(): return id
	return plant+{0:"@seed",2:"@seedling",3:"@young",4:""}.get(stage,"")

static func icon(item: Dictionary) -> Texture2D:
	if item.id in preload("res://assets/garden_art/garden_boundary.gd").IDS or preload("res://assets/garden_art/french_collection.gd").SIZES.has(item.id):
		return load("res://assets/garden_art/icons/"+str(item.id)+".svg")
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	var cell := Vector2(ATLAS.get_size())/4.0
	texture.region = Rect2(Vector2(int(item.icon)%4,int(item.icon)/4)*cell,cell)
	texture.filter_clip = true
	return texture

static func placeable(item: Dictionary) -> bool:
	return not item.is_empty() and item.get("available",true) and float(item.get("radius",0)) > 0
