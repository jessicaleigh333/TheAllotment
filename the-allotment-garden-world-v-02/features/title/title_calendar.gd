extends RefCounted
const SEASONS := ["Spring","Summer","Autumn","Winter"]

static func season_for_month(month: int, southern: bool = false) -> int:
	# Meteorological seasons: March/June/September/December boundaries.
	var season := posmod((clampi(month,1,12)+9)/3,4)
	return posmod(season+2,4) if southern else season

static func night_for_hour(hour: float) -> float:
	if hour < 6.0 or hour >= 20.0: return 1.0
	if hour < 8.0: return 1.0-smoothstep(6.0,8.0,hour)
	if hour < 18.0: return 0.0
	return smoothstep(18.0,20.0,hour)
