extends Node
## Dev tool: checks open-world rules without a human, on every biome. Movement is
## 8 directions at full speed, the car and enemies respect walls and obstacles,
## spawns are off screen and the boss time is inside its window.
##   godot --headless --path . res://tests/map_check.tscn

const STAGES := [1, 2, 3, 4]

var _main: Node
var _stage_i := -1
var _step := "next"
var _wait := 0.0
var _from := Vector3.ZERO
var _failed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _run() -> Run:
	return _main._current if _main._current is Run else null


func _process(delta: float) -> void:
	_wait -= delta
	var r := _run()
	if r:
		r.pending_levelups = 0
		r.boss_time = 9999.0
	match _step:
		"next":
			_stage_i += 1
			if _stage_i >= STAGES.size():
				print("MAP CHECK %s" % ("FAILED" if _failed else "PASSED"))
				get_tree().quit(1 if _failed else 0)
				return
			_main._clear()
			r = Run.new()
			r.class_id = "warrig"
			r.stage = STAGES[_stage_i]
			r.god_mode = true
			r.process_mode = Node.PROCESS_MODE_PAUSABLE
			_main._set_current(r)
			print("--- stage %d: %s" % [r.stage, r.biome["name"]])
			_check("boss time %.0f s is in the window" % r.boss_time, r.boss_time >= Defs.BOSS_WINDOW[0] and r.boss_time <= Defs.BOSS_WINDOW[1])
			_check_stick(r)
			_wait = 0.2
			_step = "straight"
		"straight":
			if _wait <= 0.0:
				_from = r.player.global_position
				Input.action_press("move_right")
				_wait = 0.5
				_step = "straight_end"
		"straight_end":
			if _wait <= 0.0:
				var moved := r.player.global_position - _from
				_check("right moves +x only at speed", moved.x > 0.0 and absf(moved.z) < 0.01 and absf(moved.length() / _elapsed_of(r) - 1.0) < 0.2)
				Input.action_press("move_up")
				_from = r.player.global_position
				_wait = 0.5
				_step = "diagonal_end"
		"diagonal_end":
			if _wait <= 0.0:
				var moved := r.player.global_position - _from
				_check("diagonal is 45 degrees", absf(absf(moved.x) - absf(moved.z)) < 0.2 and moved.z < 0.0)
				_check("diagonal keeps speed", absf(moved.length() / _elapsed_of(r) - 1.0) < 0.2)
				Input.action_release("move_right")
				Input.action_release("move_up")
				_wait = 0.1
				_step = "stopped"
		"stopped":
			if _wait <= 0.0:
				_from = r.player.global_position
				_wait = 0.2
				_step = "stopped_end"
		"stopped_end":
			if _wait <= 0.0:
				_check("no input stops the car", r.player.global_position.distance_to(_from) < 0.01)
				_check_wall(r)
				_check_obstacle(r)
				_check_spawns(r)
				_wait = 12.0
				_step = "enemies"
		"enemies":
			if _wait <= 0.0:
				_check_enemies(r)
				_step = "next"


func _elapsed_of(r: Run) -> float:
	return r.player.speed * 0.5


func _check_stick(r: Run) -> void:
	r._stick_dir = Vector2(1.0, 0.35)
	_check("stick snaps to 8 directions", r._move_input(0.0).is_equal_approx(Vector2.RIGHT))
	r._stick_dir = Vector2(1.0, 0.8)
	_check("stick snaps to diagonals", r._move_input(0.0).is_equal_approx(Vector2(1, 1).normalized()))
	r._stick_dir = Vector2.ZERO


func _check_wall(r: Run) -> void:
	var m := r.map
	var far := Vector3(m.half.x + 40.0, 0, -m.half.y - 40.0)
	var p := m.resolve(far, 1.0)
	_check("walls stop the car", absf(p.x) <= m.half.x - 1.0 + 0.001 and absf(p.z) <= m.half.y - 1.0 + 0.001)


func _check_obstacle(r: Run) -> void:
	var m := r.map
	_check("map has obstacles", m._ox.size() > 30)
	var clear := true
	for i in m._ox.size():
		var at := Vector3(m._ox[i] + 0.1, 0, m._oz[i])
		var out := m.resolve(at, 1.0)
		if Vector2(out.x - m._ox[i], out.z - m._oz[i]).length() < m._or[i] + 0.99:
			clear = false
		if Vector2(m._ox[i], m._oz[i]).length() < Map.CENTER_CLEAR:
			clear = false
	_check("obstacles push out and keep the start clear (%d)" % m._ox.size(), clear)


func _check_spawns(r: Run) -> void:
	var size := get_viewport().get_visible_rect().size
	var on_screen := 0
	var outside := 0
	for k in 300:
		var p := r.offscreen_point()
		var s := r.camera.unproject_position(p)
		if Rect2(Vector2.ZERO, size).has_point(s):
			on_screen += 1
		if not r.map.contains(p, 0.0):
			outside += 1
	_check("spawns are off screen (%d of 300 visible)" % on_screen, on_screen == 0)
	_check("spawns are inside the map", outside == 0)


func _check_enemies(r: Run) -> void:
	var e := r.enemies
	var bad := 0
	var seen := 0
	for i in e.used:
		if e.alive[i] == 1:
			seen += 1
			if not r.map.contains(e.pos[i], 0.0):
				bad += 1
	_check("%d enemies all inside the map" % seen, seen > 0 and bad == 0)


func _check(what: String, ok: bool) -> void:
	print("%s: %s" % ["ok  " if ok else "FAIL", what])
	_failed = _failed or not ok
