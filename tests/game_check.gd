extends Node
## Dev tool: checks combat, keyboard menus, Redline and the Garage without a human.
## Uses a throwaway profile, so real progress is never touched.
##   godot --headless --path . res://tests/game_check.tscn

var _main: Node
var _step := "targets"
var _wait := 0.0
var _failed := false
var _options: Array = []
var _picked := ""
var _hp := 0.0
var _a := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Save.profile_path = "user://profile_check.cfg"
	Save.reset_profile()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	_new_run("interceptor")


func _new_run(class_id: String) -> void:
	_main._clear()
	var r := Run.new()
	r.class_id = class_id
	r.process_mode = Node.PROCESS_MODE_PAUSABLE
	_main._set_current(r)
	r.boss_time = 1e6
	r.map._solid.fill(-1)


func _run() -> Run:
	return _main._current if _main._current is Run else null


func _process(delta: float) -> void:
	_wait -= delta
	var r := _run()
	if r:
		r.stage_time = 0.0
		if _step != "menu_open" and _step != "menu_pick":
			r.pending_levelups = 0
	match _step:
		"targets":
			_check_mg_aim(r)
			_check_rockets(r)
			_check_mines(r)
			_step = "menu_open"
		"menu_open":
			if not get_tree().paused:
				r.enemies.clear()
				r.levelup_ui.open([_option("a"), _option("b"), _option("c")], 2, func(o: Dictionary):
					_picked = o["id"]
					r._close_modal())
				get_tree().paused = true
				_wait = 0.5
				_step = "menu_pick"
		"menu_pick":
			if _wait <= 0.0:
				_tap("ui_right")
				_tap("ui_accept")
				_wait = 0.2
				_step = "menu_check"
		"menu_check":
			if _wait <= 0.0:
				_check("keyboard picks the second card", _picked == "b")
				get_tree().paused = false
				_check_turning(r)
				Input.action_press("move_right")
				_wait = 3.0
				_a = 0.0
				_step = "redline_fill"
		"redline_fill":
			if _wait <= 0.0:
				_check("driving fills Redline (%.2f)" % r.redline, r.redline > 0.15)
				r.redline = 0.6
				_a = r.redline
				r.player.invuln = 0.0
				r.player_hit(1.0)
				_check("a hit drops Redline", r.redline <= _a - Defs.REDLINE["hit_loss"] + 0.001)
				r.redline = 0.999
				r.player.invuln = 0.0
				_wait = 0.3
				_step = "nitro"
		"nitro":
			if _wait <= 0.0:
				_check("full Redline starts nitro", r.nitro_left > 0.0 and r.player.nitro)
				_check("nitro raises speed (%.1f)" % r.player.velocity.length(), r.player.velocity.length() > r.player.speed * 1.15)
				_hp = r.player.hp
				r.player.invuln = 0.0
				r.player_hit(50.0)
				_check("nitro blocks hits", r.player.hp == _hp)
				_wait = Defs.REDLINE["nitro_time"]
				_step = "nitro_end"
		"nitro_end":
			if _wait <= 0.0:
				_check("nitro ends and meter resets", not r.player.nitro and r.redline < 0.5)
				Input.action_release("move_right")
				_wait = 1.0
				_step = "drain"
		"drain":
			if _wait <= 0.0:
				_check("stopping drains Redline", r.redline < 0.1)
				_check_garage()
				_step = "done"
		"done":
			DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.profile_path))
			print("GAME CHECK %s" % ("FAILED" if _failed else "PASSED"))
			get_tree().quit(1 if _failed else 0)


func _option(id: String) -> Dictionary:
	return {"kind": "score", "id": id, "title": id, "desc": "", "hint": "", "level_text": "", "color": Color.WHITE}


func _tap(action: String) -> void:
	for pressed in [true, false]:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = pressed
		get_viewport().push_input(e)


func _check_mg_aim(r: Run) -> void:
	r.enemies.clear()
	r.projectiles.clear()
	var t := r.enemies.spawn(Enemies.RUNNER, Vector3(0, 0, -14), 1e6)
	r.enemies.vel[t] = Vector3(10, 0, 0)
	var origin := Vector3(0, 0.9, 0)
	r.weapons._fire_mg(origin, 5, false, 1.0)
	var pr := r.projectiles
	var hit_all := pr.p_kind.size() == 3
	for i in pr.p_kind.size():
		# Where the target will be when this bullet has covered the distance to it.
		var time: float = pr.p_pos[i].distance_to(r.enemies.pos[t]) / pr.p_vel[i].length()
		var bullet: Vector3 = pr.p_pos[i] + pr.p_vel[i] * time
		var enemy: Vector3 = r.enemies.pos[t] + r.enemies.vel[t] * time
		if Vector2(bullet.x - enemy.x, bullet.z - enemy.z).length() > 1.0:
			hit_all = false
	_check("all MG barrels lead a moving target", hit_all)
	r.projectiles.clear()


func _check_rockets(r: Run) -> void:
	r.enemies.clear()
	var far := r.enemies.spawn(Enemies.CRAWLER, Vector3(0, 0, -18), 1e6)
	var mid := r.enemies.spawn(Enemies.CRAWLER, Vector3(0, 0, -11), 1e6)
	var near := r.enemies.spawn(Enemies.CRAWLER, Vector3(0, 0, -6), 1e6)
	r.projectiles.clear()
	r.weapons._fire_rockets(Vector3.ZERO, 5, false, 1.0, 1.0)
	var t := r.projectiles.p_target
	_check("rockets take the closest enemies in order", t.size() == 3 and t[0] == near and t[1] == mid and t[2] == far)
	r.projectiles.clear()
	r.enemies.clear()
	near = r.enemies.spawn(Enemies.CRAWLER, Vector3(0, 0, -6), 1e6)
	r.weapons._fire_rockets(Vector3.ZERO, 5, false, 1.0, 1.0)
	t = r.projectiles.p_target
	_check("spare rockets go to the closest enemy", t.size() == 3 and t[0] == near and t[1] == near and t[2] == near)


func _check_mines(r: Run) -> void:
	r.enemies.clear()
	r.projectiles.clear()
	r.enemies.spawn(Enemies.CRAWLER, Vector3(0, 0, -15), 1e6)
	var near := r.enemies.spawn(Enemies.CRAWLER, Vector3(8, 0, 0), 1e6)
	r.player.global_position = Vector3.ZERO
	r.weapons._drop_mines(r.player, 1, false, 1.0, 1.0)
	var land := r.projectiles.p_vel[0] * Defs.WEAPONS["mines"]["arm_time"]
	_check("mines land on the closest enemy", land.distance_to(r.enemies.pos[near]) < 0.5)
	r.projectiles.clear()


func _check_turning(r: Run) -> void:
	var p := r.player
	p.heading = Vector3.FORWARD
	p.drive(1.0 / 60.0, Vector2.DOWN, r.map)
	var turned := rad_to_deg(Vector3.FORWARD.angle_to(p.heading))
	_check("turning is gradual (%.1f degrees in one frame)" % turned, turned > 0.5 and turned < 15.0)
	p.global_position = Vector3.ZERO
	p.place_on_map()


func _check_garage() -> void:
	Save.reset_profile()
	_check("cannot buy without parts", not Save.buy("hull"))
	Save.add_parts(500)
	_check("buying spends parts", Save.buy("hull") and Save.parts == 460)
	_check("next level costs more", Save.garage_cost("hull") == 80)
	Save.buy("revive")
	Save.load_profile()
	_check("progress survives a reload", Save.garage_level("hull") == 1 and Save.garage_level("revive") == 1 and Save.parts == 160)
	_new_run("warrig")
	var r := _run()
	var hp: float = Defs.CLASSES["warrig"]["max_hp"] * 1.05
	_check("garage raises HP", is_equal_approx(r.player.max_hp, hp))
	r.weapons.add_passive("plating")
	_check("passives build on the garage", is_equal_approx(r.player.max_hp, hp * (1.0 + Defs.PASSIVES["plating"]["hp"])))
	r.player.invuln = 0.0
	r.player_hit(1e6)
	_check("spare engine revives once", r.phase != Run.Phase.DEAD and r.player.hp > 0.0)
	r.player.invuln = 0.0
	r.player_hit(1e6)
	_check("second death ends the run", r.phase == Run.Phase.DEAD)
	_check("a finished run earns parts", r.parts_earned >= Defs.PARTS["stage"] and Save.parts > 160)
	var before := Save.parts
	r._finish_run()
	_check("a run pays only once", Save.parts == before)
	Save.scores.clear()


func _check(what: String, ok: bool) -> void:
	print("%s: %s" % ["ok  " if ok else "FAIL", what])
	_failed = _failed or not ok
