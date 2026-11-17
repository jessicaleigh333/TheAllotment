extends RefCounted
## Sizes are metres; ages are actual elapsed days. Intermediate knots are explicit calibrations.
const YEAR := 365.25
const LEGACY_IDS := ["sunflower","rose","lavender","hydrangea","cosmos","daisy","basil","climbing_rose","clematis","honeysuckle","ivy","wisteria"]
const PROFILES := {
 "tree":{"name":"English oak","scientific_name":"Quercus robur","height":20.0,"width":16.0,"depth":16.0,"days":[0.,42.,365.25,1826.25,18262.5],"heights":[.025,.08,.40,2.0,20.0],"widths":[.025,.065,.22,1.0,16.0],"depths":[.025,.065,.22,1.0,16.0],"trunks":[0.,.003,.012,.065,.70],"names":["Acorn","Sprout","Seedling","Sapling","Mature tree"],"references":["https://www.rhs.org.uk/plants/14294/quercus-robur/details"],"basis":"20 m height / 16 m crown at 50 real years: representative within RHS mature size/time ranges; intermediate knots and germination are calibrated examples, not measured universal rates."},
 "cypress":{"name":"Italian cypress","scientific_name":"Cupressus sempervirens","height":15.0,"width":3.0,"depth":3.0,"days":[0.,35.,365.25,1826.25,10957.5],"heights":[.008,.045,.25,1.8,15.0],"widths":[.008,.035,.10,.40,3.0],"depths":[.008,.035,.10,.40,3.0],"trunks":[0.,.002,.008,.04,.35],"names":["Seed","Sprout","Seedling","Young tree","Mature tree"],"references":["https://www.rhs.org.uk/plants/5079/cupressus-sempervirens/details"],"basis":"15 m height / 3 m spread at 30 real years: representative within RHS size/time ranges; intermediate knots and germination are calibrated examples."},
 "shrub":{"name":"Common box shrub","scientific_name":"Buxus sempervirens","height":5.0,"width":5.0,"depth":5.0,"days":[0.,90.,365.25,1095.75,7305.0],"heights":[.004,.025,.15,.60,5.0],"widths":[.004,.025,.15,.55,5.0],"depths":[.004,.025,.15,.55,5.0],"trunks":[0.,.001,.004,.015,.12],"names":["Seed","Sprout","Seedling","Young shrub","Mature shrub"],"references":["https://www.rhs.org.uk/plants/2579/buxus-sempervirens/details"],"basis":"Untrimmed 5 m shrub at 20 real years: representative within RHS size/time ranges; intermediate knots and germination are calibrated examples."},
 "hedge":{"name":"Dwarf-box hedge · five plants","scientific_name":"Buxus sempervirens 'Suffruticosa'","height":1.0,"width":1.5,"depth":2.9,"days":[0.,90.,365.25,1095.75,3652.5],"heights":[.004,.025,.10,.40,1.0],"widths":[.004,.025,.15,.55,1.5],"depths":[1.404,1.425,1.55,1.95,2.9],"trunks":[0.,.001,.003,.010,.045],"names":["Seed row","Sprouts","Hedge seedlings","Young hedge","Established hedge"],"references":["https://www.rhs.org.uk/plants/99372/buxus-sempervirens-suffruticosa/details","https://www.rhs.org.uk/plants/box/growing-guide"],"basis":"Five dwarf-box plants, 0.35 m apart; individual mature height 1 m / spread 1.5 m at 10 real years. Group length 2.9 m includes fixed 1.4 m spacing. RHS supports mature dimensions, timeframe and 30–40 cm hedge spacing; intermediate knots and germination are calibrated."}
}

static func valid_profile(profile: Dictionary) -> bool:
 for key in ["name","scientific_name","basis"]:
  if not profile.get(key) is String or profile[key].is_empty(): return false
 var days = profile.get("days")
 if not days is Array or days.size() != 5 or days[0] != 0: return false
 for key in ["heights","widths","depths","trunks","names"]:
  if not profile.get(key) is Array or profile[key].size() != 5: return false
 for value in profile.names:
  if not value is String or value.is_empty(): return false
 for key in ["days","heights","widths","depths","trunks"]:
  var previous := -1.
  for value in profile[key]:
   if not (value is float or value is int) or not is_finite(float(value)) or value < 0 or value < previous: return false
   if key == "days" and value <= previous: return false
   previous = float(value)
 for key in ["height","width","depth"]:
  var value = profile.get(key)
  if not (value is float or value is int) or not is_finite(float(value)) or value <= 0: return false
 if profile.height != profile.heights[4] or profile.width != profile.widths[4] or profile.depth != profile.depths[4]: return false
 if not profile.get("references") is Array or profile.references.is_empty(): return false
 for url in profile.references:
  if not url is String or not url.begins_with("https://"): return false
 return true

static func state(profile: Dictionary, age: float) -> Dictionary:
 age = clampf(age,0,float(profile.days[4]))
 var stage := 0
 for i in range(1,5):
  if age >= float(profile.days[i]): stage = i
 var progress := 0. if stage == 4 else inverse_lerp(float(profile.days[stage]),float(profile.days[stage+1]),age)
 var result := {"stage":stage,"name":profile.names[stage],"age_days":age}
 for pair in [["height","heights"],["width","widths"],["depth","depths"],["trunk","trunks"]]:
  result[pair[0]] = float(profile[pair[1]][stage]) if stage == 4 else lerpf(float(profile[pair[1]][stage]),float(profile[pair[1]][stage+1]),progress)
 # A planted seed remains a seed-sized object until germination, not a slowly expanding seed.
 if stage == 0:
  for pair in [["height","heights"],["width","widths"],["depth","depths"],["trunk","trunks"]]: result[pair[0]] = profile[pair[1]][0]
 return result

static func collisions(id: String, value: Dictionary) -> Array:
 if value.stage < 2: return []
 if id in ["tree","cypress"]: return [[Vector3(0,value.height*.35,0),Vector3(value.trunk,value.height*.70,value.trunk),"cylinder"]]
 if value.height < .35: return []
 return [[Vector3(0,value.height*.5,0),Vector3(value.width*.82,value.height,value.depth*.90),"box"]]
