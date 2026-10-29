extends Node
## Procedural placeholder sound effects. Every sound is synthesized at startup,
## so the prototype ships with zero audio assets. Swap in real samples later by
## replacing entries in `_streams`.

const RATE := 22050
const VOICES := 16

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}
## Minimum milliseconds between two plays of the same sound, to avoid a wall of noise.
var _throttle := {"hit": 35, "shot": 45, "pickup": 30, "kill": 40, "zap": 60, "boom": 70, "saw": 90}
var _rev_player: AudioStreamPlayer
var muted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_build_all()
	_rev_player = AudioStreamPlayer.new()
	_rev_player.stream = _streams["rev"]
	_rev_player.volume_db = -8.0
	add_child(_rev_player)


## Plays a sound. `pitch` multiplies a small random variation unless `exact` is set.
func play(sound: String, volume_db := 0.0, pitch := 1.0, exact := false) -> void:
	if muted or not _streams.has(sound):
		return
	var now := Time.get_ticks_msec()
	if _throttle.has(sound) and now - int(_last_played.get(sound, -100000)) < int(_throttle[sound]):
		return
	_last_played[sound] = now
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[sound]
	p.volume_db = volume_db
	p.pitch_scale = pitch if exact else pitch * randf_range(0.92, 1.08)
	p.play()


func rev_start() -> void:
	if muted:
		return
	_rev_player.pitch_scale = 0.6
	_rev_player.play()


func rev_set(amount: float) -> void:
	_rev_player.pitch_scale = lerpf(0.6, 2.6, clampf(amount, 0.0, 1.0))


func rev_stop() -> void:
	_rev_player.stop()


# --- synthesis -------------------------------------------------------------

func _build_all() -> void:
	_streams["shot"] = _make(0.07, func(t: float, _i: int) -> float:
		return _sq(t, lerpf(900.0, 300.0, t / 0.07)) * 0.35 * _env(t, 0.07))
	_streams["hit"] = _make(0.05, func(t: float, _i: int) -> float:
		return randf_range(-1.0, 1.0) * 0.4 * _env(t, 0.05))
	_streams["kill"] = _make(0.14, func(t: float, _i: int) -> float:
		var f := lerpf(700.0, 160.0, t / 0.14)
		return (sin(TAU * f * t) * 0.5 + randf_range(-1.0, 1.0) * 0.25) * _env(t, 0.14))
	_streams["boom"] = _make_lowpass(0.55, 0.12, func(t: float, _i: int) -> float:
		return randf_range(-1.0, 1.0) * pow(1.0 - t / 0.55, 2.0))
	_streams["big_boom"] = _make_lowpass(1.2, 0.07, func(t: float, _i: int) -> float:
		return (randf_range(-1.0, 1.0) + sin(TAU * 45.0 * t) * 0.6) * pow(1.0 - t / 1.2, 1.6))
	_streams["pickup"] = _make(0.08, func(t: float, _i: int) -> float:
		return sin(TAU * 1250.0 * t) * 0.35 * _env(t, 0.08))
	_streams["zap"] = _make(0.16, func(t: float, _i: int) -> float:
		return (_saw(t, 220.0 + randf() * 400.0) * 0.3 + randf_range(-1.0, 1.0) * 0.2) * _env(t, 0.16))
	_streams["hurt"] = _make(0.22, func(t: float, _i: int) -> float:
		return _sq(t, lerpf(160.0, 70.0, t / 0.22)) * 0.4 * _env(t, 0.22))
	_streams["dash"] = _make_lowpass(0.25, 0.35, func(t: float, _i: int) -> float:
		return randf_range(-1.0, 1.0) * sin(PI * t / 0.25) * 0.8)
	_streams["saw"] = _make(0.1, func(t: float, _i: int) -> float:
		return _saw(t, 520.0) * 0.18 * _env(t, 0.1))
	_streams["card"] = _make(0.05, func(t: float, _i: int) -> float:
		return _sq(t, 1600.0) * 0.2 * _env(t, 0.05))
	_streams["levelup"] = _arpeggio([523.25, 659.25, 783.99, 1046.5], 0.09, 0.25)
	_streams["jackpot"] = _arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0, 2093.0], 0.07, 0.25)
	_streams["reward"] = _arpeggio([783.99, 1174.66], 0.06, 0.25)
	_streams["warn"] = _make(1.6, func(t: float, _i: int) -> float:
		var f := 420.0 + 260.0 * (0.5 + 0.5 * sin(TAU * 1.25 * t))
		return _sq(t, f) * 0.25 * clampf((1.6 - t) * 4.0, 0.0, 1.0))
	_streams["slam"] = _make_lowpass(0.8, 0.06, func(t: float, _i: int) -> float:
		return (sin(TAU * lerpf(90.0, 30.0, t / 0.8) * t) + randf_range(-0.6, 0.6)) * pow(1.0 - t / 0.8, 2.0))
	var rev := _make(0.5, func(t: float, _i: int) -> float:
		return (_saw(t, 80.0) * 0.4 + _sq(t, 160.0) * 0.15) * (0.8 + 0.2 * sin(TAU * 24.0 * t)))
	rev.loop_mode = AudioStreamWAV.LOOP_FORWARD
	rev.loop_end = int(0.5 * RATE)
	_streams["rev"] = rev


func _env(t: float, length: float) -> float:
	var attack := minf(t / 0.004, 1.0)
	return attack * pow(maxf(0.0, 1.0 - t / length), 1.5)


func _sq(t: float, f: float) -> float:
	return 1.0 if fmod(t * f, 1.0) < 0.5 else -1.0


func _saw(t: float, f: float) -> float:
	return fmod(t * f, 1.0) * 2.0 - 1.0


func _make(length: float, gen: Callable) -> AudioStreamWAV:
	var n := int(length * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v := clampf(gen.call(float(i) / RATE, i), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	return _wav(data)


## Same as _make but with a one-pole low-pass filter for rumbly sounds.
func _make_lowpass(length: float, alpha: float, gen: Callable) -> AudioStreamWAV:
	var n := int(length * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var y := 0.0
	for i in n:
		y += alpha * (gen.call(float(i) / RATE, i) - y)
		data.encode_s16(i * 2, int(clampf(y * 2.2, -1.0, 1.0) * 32000.0))
	return _wav(data)


func _arpeggio(notes: Array, step: float, vol: float) -> AudioStreamWAV:
	var length := step * notes.size() + 0.25
	return _make(length, func(t: float, _i: int) -> float:
		var idx := mini(int(t / step), notes.size() - 1)
		var local := t - idx * step
		var tail := 0.25 if idx == notes.size() - 1 else step
		return (_sq(t, notes[idx]) * 0.5 + sin(TAU * notes[idx] * t) * 0.5) * vol * _env(local, tail + 0.02))


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s
