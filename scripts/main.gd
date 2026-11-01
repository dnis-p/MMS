extends Node
## App entry point: registers input actions and switches between menu and runs.
##
## Command-line options (after `--`):
##   --autotest           play unattended (auto-picks upgrades, double speed)
##   --seed=<n>           use this random seed for the run
##   --give=<a,b>         with --autotest, start with these tools at max level; "all" also maxes boosts
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
		start_run()
	else:
		show_menu()


func show_menu() -> void:
	_clear()
	var layer := CanvasLayer.new()
	var menu := Menu.new()
	menu.start_pressed.connect(start_run)
	layer.add_child(menu)
	_set_current(layer)


func start_run() -> void:
	_clear()
	var run := Run.new()
	run.process_mode = Node.PROCESS_MODE_PAUSABLE
	run.run_seed = int(_args.get("seed", "0"))
	if _args.has("autotest"):
		run.autotest = true
		run.base_time_scale = 2.0
	run.exit_to_menu.connect(show_menu)
	run.retry_requested.connect(start_run)
	_set_current(run)
	if _args.has("give"):
		var ids: Array = Defs.TOOLS.keys() if _args["give"] == "all" else Array(String(_args["give"]).split(","))
		for id in ids:
			for k in Defs.MAX_TOOL_LEVEL:
				run.tools.add_tool(id)
		if _args["give"] == "all":
			for id in Defs.BOOSTS:
				for k in Defs.MAX_BOOST_LEVEL:
					run.tools.add_boost(id)


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
			_shot_timer = 1.5
			var img := get_viewport().get_texture().get_image()
			img.save_png("%s/shot_%03d.png" % [_args["shots"], _shot_count])
			_shot_count += 1
	if _args.has("quit-after-sec") and _elapsed >= float(_args["quit-after-sec"]):
		print("AUTOTEST DONE elapsed=%.1f" % _elapsed)
		if _current is Run:
			var r: Run = _current
			print("level=%d cubes=%d kills=%d score=%d best_combo=%d depth=%.0f tools=%d hp=%d hits=%d dead=%s" % [r.level, r.cubes, r.kills, r.score, r.best_combo, r.depth, r.tools.order.size(), r.player.hp, r.hits_taken, r.dead])
		get_tree().quit()


func _setup_input() -> void:
	# Menus use Godot's ui_* actions: arrows, Space and Enter come built in, WASD is added here.
	var nav_keys := {"ui_left": KEY_A, "ui_right": KEY_D, "ui_up": KEY_W, "ui_down": KEY_S}
	for action in nav_keys:
		var nav := InputEventKey.new()
		nav.physical_keycode = nav_keys[action]
		InputMap.action_add_event(action, nav)
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"pause": [KEY_ESCAPE, KEY_P],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
