extends Node
## Deterministic neighborhood weather, shared by today and the rolling forecast.
signal weather_changed
@export var neighborhood_seed := 20261013
@export var neighborhood_name := "French garden neighborhood"
@export var use_system_clock := true
var simulation_time := 0
var last_hour := -1
const CONDITIONS := ["Sunny", "Partly cloudy", "Cloudy", "Light showers", "Rainy", "Breezy"]

func _ready() -> void:
	_tick()

func _process(_delta: float) -> void:
	_tick()

func timestamp() -> int:
	return int(Time.get_unix_time_from_system()) if use_system_clock else simulation_time

func _tick() -> void:
	var hour := floori(timestamp() / 3600.0)
	if hour != last_hour:
		last_hour = hour
		weather_changed.emit()

func set_simulation_time(value: int) -> void:
	use_system_clock = false
	simulation_time = maxi(0, value)
	_tick()

func daily_weather(day: int) -> Dictionary:
	var random := RandomNumberGenerator.new()
	random.seed = hash("allotment-weather-v1:%d:%d" % [neighborhood_seed, day])
	var date := Time.get_datetime_dict_from_unix_time(day * 86400)
	var month := int(date.month)
	# Temperate seasonal baseline. Temperatures are stored in Celsius.
	var seasonal := 13.0 + 9.0 * cos((float(month) - 7.0) * TAU / 12.0)
	var condition_index := random.randi_range(0, CONDITIONS.size() - 1)
	var high := snappedf(seasonal + random.randf_range(-3.0, 4.0), 0.1)
	var low := snappedf(high - random.randf_range(5.0, 9.0), 0.1)
	var rain_chance: int = [5, 15, 30, 65, 90, 20][condition_index] + random.randi_range(-4, 4)
	var wind := random.randi_range(5, 15) if condition_index != 5 else random.randi_range(18, 29)
	return {"day": day, "date": "%04d-%02d-%02d" % [date.year,date.month,date.day], "weekday": ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][date.weekday], "condition": CONDITIONS[condition_index], "condition_index": condition_index, "high_c": high, "low_c": low, "rain_chance": clampi(rain_chance,0,100), "wind_kmh": wind}

func current_weather() -> Dictionary:
	var now := timestamp()
	var day := floori(now / 86400.0)
	var result := daily_weather(day)
	var hour := fposmod(now / 3600.0,24.0)
	# Daily maximum at 15:00 and minimum at 03:00 (UTC garden clock).
	var warmth := (1.0 + cos((hour - 15.0) * TAU / 24.0)) * 0.5
	result.temperature_c = snappedf(lerpf(result.low_c, result.high_c, warmth),0.1)
	result.clock_label = "%02d:%02d UTC" % [floori(hour),floori(fposmod(now / 60.0,60.0))]
	return result

func forecast(days: int = 5) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var today := floori(timestamp() / 86400.0)
	for offset in range(1, clampi(days,1,14) + 1): result.append(daily_weather(today + offset))
	return result

static func temperature(celsius: float, fahrenheit: bool = true) -> String:
	return "%d°%s" % [roundi(celsius * 9.0 / 5.0 + 32.0 if fahrenheit else celsius), "F" if fahrenheit else "C"]
