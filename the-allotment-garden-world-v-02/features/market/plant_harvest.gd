extends RefCounted
## Local prototype yields are game tuning. Growth remains on the real UTC clock.
const Growth := preload("res://features/market/plant_growth.gd")
const INTERVAL_SECONDS := 14 * 86400
const CROPS := {
	"basil": {"name": "Basil sprig", "quantity": 3, "runes": 2},
	"cosmos": {"name": "Cosmos stem", "quantity": 2, "runes": 3},
}

static func status(placement: Dictionary, now: int) -> String:
	var species := Growth.species(placement.id)
	if not CROPS.has(species):
		return "A harvest is unavailable for this plant."
	if not placement.has("growth"):
		return "Replant this older specimen to start tracking harvest time."
	if Growth.state(species, Growth.age_days(placement, now)).stage < 4:
		return "Harvest opens at full size."
	var last := maxf(float(placement.growth.started_at), float(placement.get("last_harvested_at", 0)))
	var remaining := last + INTERVAL_SECONDS - now
	if remaining > 0:
		return "Harvest in about %d real days." % ceili(remaining / 86400.0)
	return ""
