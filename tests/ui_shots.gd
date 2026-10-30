extends Node
## Dev tool: walks through the menu and every modal screen and saves screenshots.
## Run with a display (e.g. xvfb-run):
##   godot --path . res://tests/ui_shots.tscn -- --shots=<dir>

var _dir := "user://"
var _main: Node
var _t := 0.0
var _step := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--shots="):
			_dir = String(a).trim_prefix("--shots=")
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(delta: float) -> void:
	_t += delta
	var steps := [
		[1.0, func(): _shot("menu")],
		[1.1, func(): _main.show_garage()],
		[1.6, func(): _shot("garage")],
		[1.7, func(): _main.show_menu()],
		[2.0, func(): _main.start_run("juggernaut")],
		[4.0, func(): _run().pending_levelups += 1],
		[3.6, func(): _shot("drive")],
		[5.0, func(): _shot("levelup")],
		[5.2, func(): _run().levelup_ui._pick(_run().weapons.level_up_options(1)[0], true)],
		[6.0, func():
			_run().weapons.add_passive("turbo")
			for k in 4:
				_run().weapons.add_weapon("rockets")
			_run().open_crate(5)],
		[7.0, func(): _shot("crate_rev")],
		[9.5, func(): _shot("crate_result")],
		[9.7, func(): _run().crate_ui._close()],
		[10.5, func(): _run()._open_pause()],
		[11.0, func(): _shot("pause")],
		[11.2, func():
			_run().overlay.hide_panel()
			_run()._resume()],
		[12.0, func():
			_run().pending_levelups = 0
			_run().stage_time = _run().boss_time],
		[17.0, func(): _shot("boss")],
		[17.5, func(): _run().player_hit(9999.0)],
		[20.0, func(): _shot("game_over")],
		[20.5, func(): get_tree().quit()],
	]
	while _step < steps.size() and _t >= steps[_step][0]:
		# Level-ups can pop up between steps; take them so the script stays on track.
		if _step > 8 and _run() and _run().levelup_ui.visible:
			_run().levelup_ui._pick(_run().weapons.level_up_options(1)[0], true)
			return
		steps[_step][1].call()
		_step += 1


func _run() -> Run:
	return _main._current


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_dir, name])
	print("shot ", name)
