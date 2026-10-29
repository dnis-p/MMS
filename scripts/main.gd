extends Node
## App entry point: registers input actions and switches between menu and runs.
##
## Command-line options (after `--`):
##   --autotest           play a run unattended (auto-picks upgrades, short stages)
##   --class=<id>         class for --autotest (juggernaut, interceptor, warrig)
##   --fair               with --autotest, normal rules: no god mode or pre-levelled build
##   --shots=<dir>        with --autotest, save screenshots into <dir>
##   --quit-after-sec=<n> with --autotest, quit after n seconds

var _current: Node
var _args := {}
var _shot_timer := 0.0
var _shot_count := 0
var _elapsed := 0.0


func _ready() -> void:
	# Keeps the autotest clock and screenshots running while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	for a in OS.get_cmdline_user_args():
		var kv := String(a).trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	if _args.has("autotest"):
		start_run(String(_args.get("class", "warrig")))
	else:
		show_menu()


func show_menu() -> void:
	_clear()
	var layer := CanvasLayer.new()
	var menu := Menu.new()
	menu.class_chosen.connect(start_run)
	layer.add_child(menu)
	_set_current(layer)


func start_run(class_id: String) -> void:
	_clear()
	var run := Run.new()
	run.class_id = class_id
	run.process_mode = Node.PROCESS_MODE_PAUSABLE
	var fair := _args.has("fair")
	if _args.has("autotest"):
		run.autotest = true
		run.base_time_scale = 2.0
		if not fair:
			run.god_mode = true
			run.road_duration = 40.0
			run.elite_times = [8.0, 25.0]
			run.horde_times = [14.0]
	run.exit_to_menu.connect(show_menu)
	run.retry_requested.connect(start_run)
	_set_current(run)
	if run.autotest and not fair:
		# Pre-level a build so evolutions and every weapon get exercised.
		for id in Defs.WEAPONS:
			run.weapons.add_weapon(id)
			for k in 4:
				run.weapons.add_weapon(id)
		for id in Defs.PASSIVES:
			run.weapons.add_passive(id)


func _set_current(n: Node) -> void:
	_current = n
	add_child(n)


func _clear() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	if _current and is_instance_valid(_current):
		_current.queue_free()
	_current = null


func _process(delta: float) -> void:
	if not _args.has("autotest"):
		return
	_elapsed += delta / maxf(Engine.time_scale, 0.01)
	if _args.has("shots"):
		_shot_timer -= delta / maxf(Engine.time_scale, 0.01)
		if _shot_timer <= 0.0:
			_shot_timer = 3.0
			var img := get_viewport().get_texture().get_image()
			img.save_png("%s/shot_%03d.png" % [_args["shots"], _shot_count])
			_shot_count += 1
	var dead: bool = _current is Run and _current.phase == Run.Phase.DEAD
	if dead or (_args.has("quit-after-sec") and _elapsed >= float(_args["quit-after-sec"])):
		print("AUTOTEST DONE elapsed=%.1f" % _elapsed)
		if _current is Run:
			var r: Run = _current
			print("stage=%d level=%d kills=%d score=%d phase=%d enemies=%d" % [r.stage, r.level, r.kills, r.score, r.phase, r.enemies.alive_count])
		get_tree().quit()


func _setup_input() -> void:
	var map := {
		"steer_left": [KEY_A, KEY_LEFT],
		"steer_right": [KEY_D, KEY_RIGHT],
		"ring_in": [KEY_W, KEY_UP],
		"ring_out": [KEY_S, KEY_DOWN],
		"pause": [KEY_ESCAPE, KEY_P],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
