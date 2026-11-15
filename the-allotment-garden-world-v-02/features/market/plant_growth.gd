extends RefCounted
## Real elapsed days, including offline time; representative ideal-condition schedules.
const STAGES := ["Seed","Sprout","Seedling","Young plant","Mature plant"]
const PLANTS := {
	"sunflower":{"height":1.8,"width":.55,"days":[0,7,14,28,90]},
	"rose":{"height":1.2,"width":1.2,"days":[0,120,180,365,1095]},
	"lavender":{"height":.6,"width":.75,"days":[0,21,60,180,730]},
	"hydrangea":{"height":1.5,"width":1.5,"days":[0,21,60,365,1095]},
	"cosmos":{"height":1.0,"width":.6,"days":[0,10,21,35,90]},
	"daisy":{"height":.7,"width":.6,"days":[0,14,35,90,365]},
	"basil":{"height":.5,"width":.45,"days":[0,7,21,35,56]},
 "climbing_rose":{"height":.70,"width":.60,"days":[0,120,180,365,1095]},
 "clematis":{"height":.55,"width":.50,"days":[0,30,90,180,730]},
 "honeysuckle":{"height":.65,"width":.60,"days":[0,30,90,180,730]},
 "ivy":{"height":.45,"width":.55,"days":[0,28,90,365,1095]},
 "wisteria":{"height":.75,"width":.65,"days":[0,21,90,365,1825]},
}

static func species(id: String) -> String:
	if id == "sunflower_seeds": return "sunflower"
	if id == "basil_seeds": return "basil"
	var base := id.get_slice("@",0)
	return base if PLANTS.has(base) else ""

static func starting_stage(id: String) -> int:
	if id.ends_with("_seeds") or id.ends_with("@seed"): return 0
	if id.ends_with("@seedling"): return 2
	if id.ends_with("@young"): return 3
	return 4

static func starting_age(id: String) -> float:
	var plant := species(id)
	return float(PLANTS[plant].days[starting_stage(id)]) if not plant.is_empty() else 0.0

static func new_record(id: String, now: float) -> Dictionary:
	if species(id).is_empty(): return {}
	return {"started_at":now,"initial_age_days":starting_age(id),"observed_age_days":starting_age(id)}

static func age_days(placement: Dictionary, now: float) -> float:
	var id: String = placement.id
	var plant := species(id)
	if plant.is_empty(): return 0
	# Existing saves without growth metadata represent previously placed mature plants.
	if not placement.has("growth"): return float(PLANTS[plant].days[4])
	var growth: Dictionary = placement.growth
	var elapsed := maxf(0,now-float(growth.started_at))/86400.0
	var age := maxf(float(growth.get("observed_age_days",0)),float(growth.initial_age_days)+elapsed)
	return minf(age,float(PLANTS[plant].days[4]))

static func state(plant: String, age: float) -> Dictionary:
	var info: Dictionary = PLANTS[plant]
	var stage := 0
	for i in range(1,5):
		if age >= float(info.days[i]): stage = i
	var factor := .0
	if stage == 0: factor = .0
	elif stage == 1: factor = lerpf(.025,.08,inverse_lerp(float(info.days[1]),float(info.days[2]),age))
	elif stage == 2: factor = lerpf(.08,.25,inverse_lerp(float(info.days[2]),float(info.days[3]),age))
	elif stage == 3: factor = lerpf(.25,1.0,inverse_lerp(float(info.days[3]),float(info.days[4]),age))
	else: factor = 1.0
	return {"stage":stage,"name":STAGES[stage],"height":.012 if stage == 0 else maxf(.03,float(info.height)*factor),"width":.10 if stage == 0 else maxf(.025,float(info.width)*factor),"age_days":age}

static func valid_record(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["started_at","initial_age_days","observed_age_days"]:
		var number = value.get(key)
		if not (number is int or number is float) or not is_finite(float(number)) or float(number) < 0: return false
	return float(value.started_at) < 100000000000.0 and float(value.initial_age_days) < 100000 and float(value.observed_age_days) < 100000
