extends Node
## Dev tool: checks the boss arena without a human. Swipes must steer the car the way
## they point, a swipe during the cooldown must be buffered, and every radial burst
## must have a path through it. A bot that only drives (no dash invulnerability) plays
## ATTACKS bursts per class, from wherever the car happens to be.
##   godot --headless --path . res://tests/boss_check.tscn

const ATTACKS := 12
const CLASSES := ["juggernaut", "interceptor", "warrig"]
const REST := 2.5
const TIME_SCALE := 3.0

var _main: Node
var _class_i := -1
var _step := "start"
var _wait := 0.0
var _clock := 0.0
var _bursts := 0
var _hit_bursts := 0
var _hit_this_burst := false
var _last_hp := 0.0
var _last_volleys := 0
var _gaps: Array = []
var _from := Vector3.ZERO
var _failed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _run() -> Run:
	return _main._current if _main._current is Run else null


func _process(delta: float) -> void:
	_clock += delta
	_wait -= delta
	var run := _run()
	if run and run.pending_levelups > 0:
		run.pending_levelups = 0
	match _step:
		"start":
			_class_i += 1
			if _class_i >= CLASSES.size():
				print("BOSS CHECK %s" % ("FAILED" if _failed else "PASSED"))
				get_tree().quit(1 if _failed else 0)
				return
			_main.start_run(CLASSES[_class_i])
			run = _run()
			run.base_time_scale = TIME_SCALE
			run.levelup_ui.auto_pick = true
			run.stage_time = run.boss_time
			_step = "wait_arena"
		"wait_arena":
			if run.phase == Run.Phase.BOSS:
				run.enemies.hp[run.boss.idx] = 1e9
				run.enemies.max_hp[run.boss.idx] = 1e9
				run.player.max_hp = 1e7
				run.player.hp = 1e7
				run.boss._timer = 1e6
				_bursts = 0
				_hit_bursts = 0
				_from = run.player.global_position
				run._dash(1.0)
				_wait = 0.5
				_step = "check_right"
		"check_right":
			if _wait <= 0.0:
				_check("swipe right drives right", _moved_right(run) > 0.5)
				_from = run.player.global_position
				run._dash(-1.0)
				run._dash(-1.0)
				_wait = 0.5
				_step = "check_left"
		"check_left":
			if _wait <= 0.0:
				_check("swipe left drives left", _moved_right(run) < -0.5)
				run._dash(1.0)
				run._dash(-1.0)  # during the cooldown: must fire when it ends
				_wait = 0.7
				_step = "check_buffer"
		"check_buffer":
			if _wait <= 0.0:
				_check("buffered swipe is used", _circle_screen_dir(run) < 0.0)
				_step = "burst"
		"burst":
			_start_burst(run)
			_step = "bursting"
		"bursting":
			_drive(run)
			if run.boss._state == "idle":
				run.boss._timer = 1e6
			if run.boss._state == "idle" and _wait <= -REST:
				_bursts += 1
				_hit_bursts += int(_hit_this_burst)
				if _bursts >= ATTACKS:
					print("%s: %d of %d bursts hit the driving bot" % [CLASSES[_class_i], _hit_bursts, _bursts])
					_check("%s can drive through bursts" % CLASSES[_class_i], _hit_bursts * 4 <= ATTACKS)
					_step = "start"
				else:
					_step = "burst"
			elif run.boss._state != "idle":
				_wait = 0.0


func _start_burst(run: Run) -> void:
	var b: Boss = run.boss
	b._attack = "burst"
	b._state = "telegraph"
	b._timer = Defs.BOSS["burst_telegraph"]
	_hit_this_burst = false
	_last_volleys = 0
	_gaps.clear()
	_last_hp = run.player.hp
	_wait = 0.0


## Steers toward the gap of whichever volley reaches the car next, without dashing.
func _drive(run: Run) -> void:
	var p: Player = run.player
	var b: Boss = run.boss
	if b._gap_placed and b._volleys != _last_volleys:
		_last_volleys = b._volleys
		_gaps.append([b._gap_angle, _clock + p.ring_radius / Defs.BOSS["burst_speed"]])
	while _gaps.size() > 1 and _gaps[0][1] < _clock:
		_gaps.pop_front()
	if not _gaps.is_empty():
		var diff := wrapf(float(_gaps[0][0]) - p.theta, -PI, PI)
		if absf(diff) > 0.12:
			p.circle_dir = signf(diff)
	if p.hp < _last_hp:
		_hit_this_burst = true
		_last_hp = p.hp


func _moved_right(run: Run) -> float:
	return (run.player.global_position - _from).dot(run.camera.global_transform.basis.x)


func _circle_screen_dir(run: Run) -> float:
	var p: Player = run.player
	var tangent := Vector3(-sin(p.theta), 0, cos(p.theta))
	return p.circle_dir * signf(tangent.dot(run.camera.global_transform.basis.x))


func _check(what: String, ok: bool) -> void:
	print("%s: %s" % ["ok  " if ok else "FAIL", what])
	_failed = _failed or not ok
