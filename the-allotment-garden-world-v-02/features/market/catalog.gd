extends RefCounted
const ATLAS := preload("res://features/market/item_atlas.png")
const ITEMS := [
	{"id":"sunflower","name":"Sunflower","latin":"Helianthus annuus","category":"Plants","price":25,"icon":0,"radius":.5,"season":"Summer","sun":"Full sun","water":"Moderate","description":"Golden faces and tall stems bring a sunny focal point to a border."},
	{"id":"rose","name":"Rose bush","latin":"Rosa","category":"Plants","price":35,"icon":1,"radius":.75,"season":"Summer","sun":"Full sun","water":"Moderate","description":"Soft pink blooms and rounded foliage for a romantic cottage garden."},
	{"id":"lavender","name":"Lavender","latin":"Lavandula angustifolia","category":"Plants","price":18,"icon":2,"radius":.5,"season":"Summer","sun":"Full sun","water":"Low","description":"Fragrant purple flower spikes suit sunny paths and dry borders."},
	{"id":"hydrangea","name":"Hydrangea","latin":"Hydrangea macrophylla","category":"Plants","price":45,"icon":3,"radius":.9,"season":"Summer","sun":"Part shade","water":"Regular","description":"Clouds of blue-violet flowers make a generous leafy border."},
	{"id":"cosmos","name":"Cosmos","latin":"Cosmos bipinnatus","category":"Plants","price":16,"icon":4,"radius":.5,"season":"Summer–Autumn","sun":"Full sun","water":"Moderate","description":"Airy pink flowers soften informal planting beds."},
	{"id":"daisy","name":"Daisy clump","latin":"Leucanthemum × superbum","category":"Plants","price":12,"icon":5,"radius":.45,"season":"Summer","sun":"Sun / part shade","water":"Moderate","description":"Cheerful white petals and gold centers in a compact perennial clump."},
	{"id":"sunflower_seeds","name":"Sunflower seeds","category":"Seeds","price":6,"icon":6,"radius":0,"available":false,"description":"Seed packets will become available when seed growing is ready."},
	{"id":"basil_seeds","name":"Basil seeds","category":"Seeds","price":5,"icon":7,"radius":0,"available":false,"description":"Seed packets will become available when seed growing is ready."},
	{"id":"rose_arch","name":"Climbing rose arch","category":"Decor","price":125,"icon":8,"radius":1.5,"featured":true,"description":"A timber entrance with climbing foliage and pink roses. Keep room around its posts."},
	{"id":"bench","name":"Garden bench","category":"Decor","price":180,"icon":9,"radius":1.4,"featured":true,"description":"A simple timber bench for a peaceful corner of the garden."},
	{"id":"fountain","name":"Stone garden fountain","category":"Decor","price":350,"icon":10,"radius":1.35,"featured":true,"description":"A tiered stone centerpiece with a still blue basin. Decorative; water effects are not included."},
	{"id":"lantern","name":"Garden lantern","category":"Decor","price":60,"icon":11,"radius":.35,"description":"A small brass garden lantern with a warm glowing center."},
	{"id":"trellis","name":"Flower trellis","category":"Decor","price":45,"icon":12,"radius":1.0,"featured":true,"description":"A timber lattice with climbing flowers for an informal garden backdrop."},
	{"id":"planter","name":"Terracotta planter","category":"Decor","price":28,"icon":13,"radius":.7,"description":"A warm terracotta pot filled with colorful flowers."},
	{"id":"straw_hat","name":"Flower-trimmed straw hat","category":"Avatar","price":120,"icon":14,"radius":0,"description":"Equip the gardener's existing straw hat and flower band."},
	{"id":"watering_can","name":"Watering can","category":"Tools","price":20,"icon":15,"radius":.5,"description":"A decorative metal watering can. Plant watering gameplay is not connected yet."},
]

static func by_id(id: String) -> Dictionary:
	for item in ITEMS:
		if item.id == id: return item
	return {}

static func icon(item: Dictionary) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	var cell := Vector2(ATLAS.get_size())/4.0
	texture.region = Rect2(Vector2(int(item.icon)%4,int(item.icon)/4)*cell,cell)
	texture.filter_clip = true
	return texture

static func placeable(item: Dictionary) -> bool:
	return not item.is_empty() and item.get("available",true) and float(item.get("radius",0)) > 0
