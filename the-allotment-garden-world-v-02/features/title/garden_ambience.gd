extends Node
## Original synthesized ambience. No external recordings or licenses required.
var breeze: AudioStreamPlayer
var insects: AudioStreamPlayer
var chimes: AudioStreamPlayer
var rng := RandomNumberGenerator.new()
var chime_delay := 15.0
var volume := 0.55
var muted := false
var insect_season_gain := 0.0

func set_season(season: int, night: float) -> void:
	insect_season_gain = -80.0 if season == 3 else (-9.0 if season == 2 else 0.0)
	insect_season_gain += lerpf(-3.0,0.0,night)
	apply_volume()

func _ready() -> void:
	rng.randomize()
	breeze = _player(_sound(12.0, 0), true)
	insects = _player(_sound(12.0, 1), true)
	chimes = _player(_sound(6.0, 2), false)
	apply_volume()
	breeze.play()
	insects.play()
	chime_delay = rng.randf_range(14.0,24.0)

func _player(stream: AudioStreamWAV, looping: bool) -> AudioStreamPlayer:
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size()/2
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	return player

func apply_volume() -> void:
	if breeze == null: return
	var gain := linear_to_db(maxf(volume,0.0001)) if not muted else -80.0
	breeze.volume_db = gain - 7.0
	insects.volume_db = gain - 15.0 + insect_season_gain
	chimes.volume_db = gain - 12.0

func _exit_tree() -> void:
	for player in [breeze,insects,chimes]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null

func _process(delta: float) -> void:
	chime_delay -= delta
	if chime_delay <= 0:
		if not muted and volume > 0:
			chimes.pitch_scale = rng.randf_range(.92,1.06)
			chimes.play()
		chime_delay = rng.randf_range(22.0,46.0)

func _sound(seconds: float, kind: int) -> AudioStreamWAV:
	const RATE := 16000
	var count := int(seconds*RATE)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var low := 0.0
	for i in range(count):
		var t := float(i)/RATE
		var sample := 0.0
		if kind == 0:
			low = lerpf(low,rng.randf_range(-1,1),.045)
			sample = low*(.30+.12*sin(TAU*t/seconds))
		elif kind == 1:
			var pulse := pow(maxf(0,sin(TAU*2*t)),12.0)
			var phrase := pow(maxf(0,sin(TAU*t/3.0)),3.0)
			sample = .075*pulse*phrase*(sin(TAU*3200*t)+.3*sin(TAU*4100*t))
		else:
			for j in range(4):
				var age := t-float(j)*.48
				if age > 0:
					var frequency: float = [784.0,1046.5,1174.7,1568.0][j]
					sample += .08*(1-exp(-age*90))*exp(-age*1.2)*(sin(TAU*frequency*age)+.25*sin(TAU*frequency*2.76*age))
		var fade := minf(1.0,minf(t/.08,(seconds-t)/.15))
		var value := int(clampf(sample*fade,-1,1)*32767)
		bytes.encode_s16(i*2,value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream
