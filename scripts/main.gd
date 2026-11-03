extends Node
## App entry point: registers input actions and switches between menu and runs.
##
## Command-line options (after `--`):
##   --autotest           play unattended (auto-picks upgrades, double speed)
##   --seed=<n>           use this random seed for the run
##   --give=<a,b>         with --autotest, start with these tools at max level; "all" also maxes boosts
##   --shots=<dir>        with --autotest, save screenshots into <dir>
##   --map                with --autotest, keep the full map open, for screenshots of it
##   --goal=<heart|lift>  with --autotest, go for the Heart, or leave by lift after a while
##   --char=<id>          with --autotest, dig as this character
##   --unlocked           with --autotest, everything is unlocked
##   --shop=<n>           with --autotest, every shop upgrade is at level n
##   --god                with --autotest, the bot can't die, to measure a whole run
##   --near-heart         with --autotest, start most of the way to the Heart
##   --boss-at=<s>        with --autotest, the first boss comes at this time
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
		Profile.saving = false
		if _args.has("unlocked"):
			Profile.unlock_all()
		Profile.character = _args.get("char", "digger")
		for id in Defs.SHOP:
			Profile.shop[id] = mini(int(_args.get("shop", "0")), Defs.SHOP[id]["max"])
		start_run()
	else:
		Profile.load_file()
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
	var screen := CanvasLayer.new()
	var loading := Loading.new()
	screen.add_child(loading)
	add_child(screen)
	var run := Run.new()
	run.load_progress.connect(loading.show_progress)
	run.loaded.connect(screen.queue_free)
	run.process_mode = Node.PROCESS_MODE_PAUSABLE
	run.run_seed = int(_args.get("seed", "0"))
	if _args.has("autotest"):
		run.autotest = true
		run.base_time_scale = 2.0
		run.bot.goal = _args.get("goal", "")
		run.god_mode = _args.has("god")
	run.exit_to_menu.connect(show_menu)
	run.retry_requested.connect(start_run)
	_set_current(run)
	if not run.ready_to_play:
		await run.loaded
	if _args.has("near-heart"):
		run.player.global_position = run.mine.heart_pos * 0.7
		run.mine.hit_circle(run.player.global_position, 3.0, 1e9, run.player.global_position, 0.0, true)
	if _args.has("boss-at"):
		run.bosses._next_at = float(_args["boss-at"])
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
	if _args.has("map") and _current is Run and _current.hud:
		_current.hud.map_full.visible = true
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
			print("level=%d cubes=%d kills=%d score=%d best_combo=%d depth=%.0f tools=%d hp=%d hits=%d dead=%s gems=%d frenzies=%d geodes=%d relics=%d evolutions=%d" % [r.level, r.cubes, r.kills, r.score, r.best_combo, r.depth, r.tools.order.size(), r.player.hp, r.hits_taken, r.dead, int(r.loot), r.frenzies, r.geodes, r.relics, r.evolutions])
		get_tree().quit()


## Whichever was used last counts: a gamepad hides the pointer, moving the mouse brings it back.
func _input(event: InputEvent) -> void:
	var pad := Options.pad
	if event is InputEventMouseMotion:
		pad = pad and event.screen_relative.length() < Defs.PAD["mouse_wake"]
	elif event is InputEventJoypadButton:
		pad = true
	elif event is InputEventJoypadMotion and event.axis <= JOY_AXIS_RIGHT_Y:
		pad = pad or absf(event.axis_value) > Defs.PAD["stick_wake"]
	if pad != Options.pad:
		Options.pad = pad
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if pad else Input.MOUSE_MODE_VISIBLE


func _setup_input() -> void:
	# Menus use Godot's ui_* actions: arrows, Space and Enter come built in, as do the left stick and
	# d-pad. WASD and the gamepad's A and B are added here.
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
		"map": [KEY_M, KEY_TAB],
		"map_zoom_in": [KEY_EQUAL, KEY_KP_ADD],
		"map_zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT],
		"aim_left": [],
		"aim_right": [],
		"aim_up": [],
		"aim_down": [],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	var buttons := {
		"ui_accept": JOY_BUTTON_A,
		"ui_cancel": JOY_BUTTON_B,
		"pause": JOY_BUTTON_START,
		"map": JOY_BUTTON_BACK,
		"map_zoom_in": JOY_BUTTON_RIGHT_SHOULDER,
		"map_zoom_out": JOY_BUTTON_LEFT_SHOULDER,
		"move_left": JOY_BUTTON_DPAD_LEFT,
		"move_right": JOY_BUTTON_DPAD_RIGHT,
		"move_up": JOY_BUTTON_DPAD_UP,
		"move_down": JOY_BUTTON_DPAD_DOWN,
	}
	for action in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = buttons[action]
		ev.device = -1  # any gamepad, whichever slot it landed in
		InputMap.action_add_event(action, ev)
	var wheel := {"map_zoom_in": MOUSE_BUTTON_WHEEL_UP, "map_zoom_out": MOUSE_BUTTON_WHEEL_DOWN}
	for action in wheel:
		var ev := InputEventMouseButton.new()
		ev.button_index = wheel[action]
		InputMap.action_add_event(action, ev)
	var sticks := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0],
		"move_down": [JOY_AXIS_LEFT_Y, 1.0],
		"aim_left": [JOY_AXIS_RIGHT_X, -1.0],
		"aim_right": [JOY_AXIS_RIGHT_X, 1.0],
		"aim_up": [JOY_AXIS_RIGHT_Y, -1.0],
		"aim_down": [JOY_AXIS_RIGHT_Y, 1.0],
	}
	for action in sticks:
		var ev := InputEventJoypadMotion.new()
		ev.axis = sticks[action][0]
		ev.axis_value = sticks[action][1]
		ev.device = -1
		InputMap.action_add_event(action, ev)
