extends Node
## Dev tool: checks the raccoon hunting rules without a human.
##   godot --headless --path . res://tests/eat_check.tscn

var _main: Node
var _step := "rules"
var _wait := 0.0
var _failed := false
var _food := -1
var _gap := 0.0
var _speed := 0.0
var _spot := Vector3.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Save.profile_path = "user://profile_check.cfg"
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	_main._clear()
	var r := Run.new()
	r.class_id = "raccoon"
	r.autotest = true  # no garage, no leaderboard; the bot is replaced below
	r.process_mode = Node.PROCESS_MODE_PAUSABLE
	_main._set_current(r)
	r.autotest = false
	r.boss_time = 1e6
	r.elite_times = []
	r.map._solid.fill(-1)
	r.levelup_ui.auto_pick = true
	r.crate_ui.auto_close = true


func _run() -> Run:
	return _main._current if _main._current is Run else null


func _process(delta: float) -> void:
	_wait -= delta
	var r := _run()
	if r == null:
		return
	r.pending_levelups = 0
	r.stage_time = minf(r.stage_time, 1.0)
	r._herd_timer = 1e6
	r._threat_timer = 1e6
	if r.phase == Run.Phase.ROAM and _step != "grown":
		r.player.hp = r.player.max_hp
	match _step:
		"rules":
			_check_rules(r)
			r.enemies.clear()
			r.player.end_lunge()
			r._bite_cd = 0.0
			r.player.heading = Vector3.FORWARD
			_food = r.enemies.spawn(Enemies.CRAWLER, r.player.global_position + Vector3.FORWARD * 6.0, 1e6)
			r.frenzy = 0.0
			_wait = 0.4
			_step = "pounce"
		"pounce":
			if _wait <= 0.0:
				_check("prey ahead gets pounced on with no input", not r.enemies.is_alive(_food) and r.frenzy > 0.0)
				r.enemies.clear()
				_food = r.enemies.spawn(Enemies.CRAWLER, r.player.global_position + Vector3.BACK * 15.0, 1e6)
				_gap = 15.0
				_wait = 0.5
				_step = "flee"
		"flee":
			if _wait <= 0.0:
				var d: float = r.enemies.pos[_food].distance_to(r.player.global_position)
				_check("prey runs from far away (%.1f m -> %.1f m)" % [_gap, d], d > _gap + 0.5)
				r.enemies.clear()
				_food = r.enemies.spawn(Enemies.CRAWLER, r.player.global_position + Vector3(60, 0, 0), 1e6)
				_spot = r.enemies.pos[_food]
				_wait = 0.5
				_step = "wander"
		"wander":
			if _wait <= 0.0:
				var moved: float = r.enemies.pos[_food].distance_to(_spot)
				_check("calm prey out of range just wanders (%.2f m)" % moved, moved > 0.1 and moved < r.enemies.speed[_food] * 0.3)
				r.enemies.clear()
				r.player.hp = r.player.max_hp
				var hp := r.player.hp
				r._starve(1.0)
				_check("hunger drains while you stand around", r.player.hp < hp)
				r._grow(24.0)
				_speed = r.player.speed
				Input.action_press("move_right")
				_wait = 1.5
				_step = "grown"
		"grown":
			if _wait <= 0.0:
				Input.action_release("move_right")
				_check("growing does not slow you (%.1f m/s at size %.1f)" % [r.player.velocity.length(), r.body_size], r.body_size > 4.0 and r.player.velocity.length() >= _speed * 0.99)
				_check("everyone speeds up with the zoom", r.player.speed > r.player.base_speed * 1.5 and r.enemies.speed_mult > 1.5)
				_check("the camera zooms out", r.view_zoom > 1.5)
				_check("growing evolves the body", r.player.form >= 2 and r.player._model.get_child_count() > 20)
				_check_spawns(r)
				_check_threats(r)
				_check_alpha(r)
				_wait = 0.1
				_step = "next_stage"
		"next_stage":
			if _wait <= 0.0:
				r._next_stage()
				_check("sizes carry over and food grows", r.body_size > 4.0 and is_equal_approx(r.food_scale, Defs.EAT["stage_scale"]))
				_check("the graft stays", r.player._grafts.size() == 1)
				_check("next stage has its own name", r.biome["name"] == "Back Alley")
				_check("a new stage brings herds to hunt", r.enemies.alive_count > 10)
				r.body_size = 1.0
				r.stage = 6
				r._start_stage()
				_check("the smallest food always fits", r.enemies.can_swallow(0))
				r.player.hp = 0.1
				r._starve(1.0)
				_check("starving ends the run", r.phase == Run.Phase.DEAD and r._starved)
				DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.profile_path))
				print("EAT CHECK %s" % ("FAILED" if _failed else "PASSED"))
				get_tree().quit(1 if _failed else 0)


func _check_rules(r: Run) -> void:
	var at := r.player.global_position
	var e := r.enemies
	_check("no guns to start with", r.weapons.order.is_empty())
	var options := r.weapons.level_up_options(3)
	var traits := true
	for o in options:
		traits = traits and o["kind"] == "passive" and Defs.PASSIVES[o["id"]].get("creature", false)
	_check("level-ups offer creature traits only", options.size() == 3 and traits)
	e.clear()
	var small := e.spawn(Enemies.CRAWLER, at, 1e6)
	var kills := r.kills
	var was_size := r.body_size
	r.player.hp = 50.0
	r.on_enemy_contact(small)
	_check("touching smaller prey eats it", not e.is_alive(small) and r.kills == kills + 1)
	_check("eating grows you (%.3f -> %.3f)" % [was_size, r.body_size], r.body_size > was_size)
	_check("eating refills hunger", r.player.hp > 50.0)
	_check("the body follows the size", is_equal_approx(r.player.radius, r.player.def["size"].z * 0.42 * r.body_size))

	for k in 6:
		e.spawn(Enemies.CRAWLER, at + Vector3(cos(k) * 1.5, 0, sin(k) * 1.5), 1e6)
	e._rebuild_grid()
	kills = r.kills
	r._bite_cd = 1.0
	r._chomp()
	_check("one bite eats everything around it (%d)" % (r.kills - kills), r.kills == kills + 6)
	_check("a meal resets the pounce, any direction", r._bite_cd == 0.0 and r._chain_left > 0.0)
	r.frenzy = 0.0
	var plain := r.bite_radius()
	r.frenzy = 1.0
	_check("Frenzy widens the bite", r.bite_radius() > plain)
	r.frenzy = 0.0

	var big := e.spawn(Enemies.BRUTE, at + Vector3(1, 0, 0), 1.0)
	r._make_big(big, 5.0, 1.9)
	_check("bigger food is too big", not e.edible(big))
	r.player.hp = 50.0
	r.player.invuln = 0.0
	r.on_enemy_contact(big)
	_check("touching something bigger hurts", r.player.hp < 50.0 and e.is_alive(big))
	r.player.invuln = 0.0
	e._rebuild_grid()
	var hp: float = e.hp[big]
	r._chomp()
	_check("a bite tears a chunk off it", e.hp[big] < hp and e.is_alive(big) and not e.edible(big))
	_check("biting something big bounces you off it", r.player.lunge_left > 0.0 and r._bite_cd > 0.0)
	_check("you can't be hit during a lunge", not r.player.can_be_hit())
	r.player.end_lunge()
	e._rebuild_grid()
	r._chomp()
	r.player.end_lunge()
	_check("the second bite drops it", e.is_alive(big) and e.weak[big] > 0.0 and e.edible(big))
	var fed := r.body_size
	e._rebuild_grid()
	r._chomp()
	r.player.end_lunge()
	_check("a dropped brute can be eaten", not e.is_alive(big) and r.body_size > fed)
	_check("a plain brute drops no crate", r.pickups.crates.is_empty())
	r.pickups.clear()


func _check_spawns(r: Run) -> void:
	var near := 999.0
	for k in 100:
		near = minf(near, r.offscreen_point().distance_to(r.player.global_position))
	_check("spawns stay off screen when zoomed out (%.0f m)" % near, near > 26.0 * r.view_zoom * 0.95)
	var far := r.enemies.spawn(Enemies.CRAWLER, r.offscreen_point(), 1.0)
	var spot: Vector3 = r.enemies.pos[far]
	r.enemies.update(0.0, r.player.global_position, Vector3.ZERO, r.player.radius)
	_check("zoomed-out spawns are not thrown back", r.enemies.pos[far].distance_to(spot) < 1.0)
	r.enemies.clear()


func _check_threats(r: Run) -> void:
	var e := r.enemies
	r._spawn_threat()
	var ok := e.alive_count == 1 and e.sizes[0] > r.body_size and not e.edible(0)
	_check("threats are always bigger than you", ok)
	e.clear()
	r._spawn_herd(r.player.global_position + Vector3(30, 0, 0))
	_check("herds come as a group of food", e.alive_count >= 3 and e.edible(0))
	e.clear()


func _check_alpha(r: Run) -> void:
	r._spawn_alpha()
	var i := r.alpha
	var e := r.enemies
	_check("the boss spawns in the world", i >= 0 and r.phase == Run.Phase.ROAM and r.boss == null)
	_check("boss HP counts in bites", is_equal_approx(e.hp[i], Defs.EAT["alpha_bites"] * r.plain_bite()))
	_check("the boss is always bigger than you", e.sizes[i] > r.body_size and not e.edible(i))
	r.player.invuln = 0.0
	r.player.hp = r.player.max_hp
	var hp := r.player.hp
	r.on_enemy_contact(i)
	_check("touching the boss hurts", r.player.hp < hp and e.is_alive(i))
	r.frenzy = 0.0
	var before: float = e.hp[i]
	r._tear(i)
	var plain: float = before - e.hp[i]
	r.frenzy = 1.0
	before = e.hp[i]
	r._tear(i)
	_check("Frenzy tears bigger chunks (%.0f -> %.0f)" % [plain, before - e.hp[i]], before - e.hp[i] > plain * 2.0)
	r.frenzy = 0.0
	e.hp[i] = 1.0
	_check("at 0 HP the boss goes down but stays alive", r._tear(i) and e.is_alive(i) and e.edible(i) and r.boss_name().contains("EAT IT"))
	r.on_enemy_contact(i)
	_check("eating the boss ends the stage", r.phase == Run.Phase.FEAST and r.alpha == -1)
	_check("eating the boss gives its trait and part", r.weapons.passive("jaws") == 2 and r.player._grafts.size() == 1)


func _check(what: String, ok: bool) -> void:
	print("%s: %s" % ["ok  " if ok else "FAIL", what])
	_failed = _failed or not ok
