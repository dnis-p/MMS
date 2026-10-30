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
	Save.profile_path = "user://profile_shots.cfg"  # the walkthrough ends in a game over
	Save.load_profile()
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
		[20.5, func(): _main.start_run("raccoon")],
		[20.6, func(): _run().god_mode = true],
		[22.5, func(): _shot("raccoon_start")],
		[22.6, func():
			_run()._grow(8.0)
			for k in 12:
				_run().enemies.spawn(k % 4, _run().player.global_position + Vector3(cos(k) * 16.0, 0, sin(k) * 12.0), 1e6)],
		[25.0, func(): _shot("raccoon_grown")],
		[25.2, func(): _run()._spawn_alpha()],
		[27.9, func():
			_run()._mouse_seen = true
			get_viewport().warp_mouse(get_viewport().get_visible_rect().size * 0.5 + Vector2(240, -120))],
		[28.0, func(): _shot("raccoon_boss")],
		[28.1, func(): _run().hit_enemy(_run().alpha, 1e9, Vector3.LEFT, 0.0, false)],
		[28.6, func(): _shot("raccoon_boss_down")],
		[28.7, func():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.profile_path))
			get_tree().quit()],
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
