extends Node
## Dev tool: checks the raccoon eat-and-grow rules without a human.
##   godot --headless --path . res://tests/eat_check.tscn

var _main: Node
var _step := "rules"
var _wait := 0.0
var _failed := false
var _food := -1
var _gap := 0.0
var _speed := 0.0


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
	match _step:
		"rules":
			_check_rules(r)
			r.enemies.clear()
			_food = r.enemies.spawn(Enemies.CRAWLER, r.player.global_position + Vector3(6, 0, 0), 1e6)
			_gap = 6.0
			_wait = 0.5
			_step = "flee"
		"flee":
			if _wait <= 0.0:
				var d: float = r.enemies.pos[_food].distance_to(r.player.global_position)
				_check("smaller prey runs away (%.1f m -> %.1f m)" % [_gap, d], d > _gap + 0.5)
				_check_recover(r)
				_wait = Defs.EAT["weak_time"] + 0.3
				_step = "recover"
		"recover":
			if _wait <= 0.0:
				_check("knocked-down prey gets back up", r.enemies.weak[_food] <= 0.0 and r.enemies.hp[_food] > 0.0)
				r.enemies.clear()
				r._grow(24.0)
				_speed = r.player.speed
				Input.action_press("move_right")
				_wait = 1.5
				_step = "grown"
		"grown":
			if _wait <= 0.0:
				Input.action_release("move_right")
				_check("growing does not slow you (%.1f m/s at size %.1f)" % [r.player.velocity.length(), r.body_size], r.body_size > 4.0 and r.player.velocity.length() >= _speed * 0.99)
				_check("the camera zooms out", r.view_zoom > 1.5)
				_check_spawns(r)
				_check_alpha(r)
				_wait = 0.1
				_step = "next_stage"
		"next_stage":
			if _wait <= 0.0:
				r._next_stage()
				_check("sizes carry over and food grows", r.body_size > 4.0 and is_equal_approx(r.food_scale, Defs.EAT["stage_scale"]))
				_check("the mutation stays", r.weapons.owned.has("saws"))
				_check("next stage has its own name", r.biome["name"] == "Back Alley")
				DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.profile_path))
				print("EAT CHECK %s" % ("FAILED" if _failed else "PASSED"))
				get_tree().quit(1 if _failed else 0)


func _check_rules(r: Run) -> void:
	var at := r.player.global_position
	var e := r.enemies
	e.clear()
	var small := e.spawn(Enemies.CRAWLER, at, 1e6)
	var kills := r.kills
	var was_size := r.body_size
	var hp := r.player.hp
	r.on_enemy_contact(small)
	_check("touching smaller prey eats it", not e.is_alive(small) and r.kills == kills + 1)
	_check("eating grows you (%.3f -> %.3f)" % [was_size, r.body_size], r.body_size > was_size)
	_check("eating does not hurt", r.player.hp == hp)
	_check("the body follows the size", is_equal_approx(r.player.radius, r.player.def["size"].z * 0.42 * r.body_size))

	var big := e.spawn(Enemies.BRUTE, at, 1.0)
	_check("bigger food is too big", not e.edible(big))
	r.player.invuln = 0.0
	r.on_enemy_contact(big)
	_check("touching something bigger hurts", r.player.hp < hp and e.is_alive(big))
	r.player.hp = r.player.max_hp
	r.hit_enemy(big, 1e6, Vector3.LEFT, 0.0, false)
	_check("attacks knock it down, they do not kill it", e.is_alive(big) and e.weak[big] > 0.0 and e.edible(big))
	var hits := r.kills
	r.hit_enemy(big, 1e6, Vector3.LEFT, 0.0, false)
	_check("hitting it again does nothing", e.is_alive(big) and r.kills == hits)
	_check("weapons stop aiming at it", e.nearest(at, 50.0) == -1)
	var fed := r.body_size
	r.on_enemy_contact(big)
	_check("a knocked-down brute can be eaten", not e.is_alive(big) and r.body_size > fed)

	var crumb := e.spawn(Enemies.CRAWLER, at + Vector3(30, 0, 0), 1.0)
	r.hit_enemy(crumb, 1e6, Vector3.LEFT, 0.0, false)
	_check("attacks still kill smaller prey", not e.is_alive(crumb))
	r.pickups.clear()


func _check_recover(r: Run) -> void:
	var e := r.enemies
	e.clear()
	_food = e.spawn(Enemies.BRUTE, r.player.global_position + Vector3(40, 0, 0), 1e6)
	r.hit_enemy(_food, 1e9, Vector3.LEFT, 0.0, false)


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


func _check_alpha(r: Run) -> void:
	r._damage_rate = 100.0
	r._spawn_alpha()
	var i := r.alpha
	var e := r.enemies
	_check("the boss spawns in the world", i >= 0 and r.phase == Run.Phase.ROAM and r.boss == null)
	_check("boss HP comes from your damage rate", e.hp[i] == maxf(Defs.EAT["alpha_min_hp"], 100.0 * Defs.EAT["alpha_fight"]))
	_check("the boss is always bigger than you", e.sizes[i] > r.body_size and not e.edible(i))
	r.player.invuln = 0.0
	var hp := r.player.hp
	r.on_enemy_contact(i)
	_check("touching the boss hurts", r.player.hp < hp and e.is_alive(i))
	r.player.hp = r.player.max_hp
	r.hit_enemy(i, 1e9, Vector3.LEFT, 0.0, false)
	_check("the boss goes down but stays alive", e.is_alive(i) and e.edible(i) and r.boss_name().contains("EAT IT"))
	r.on_enemy_contact(i)
	_check("eating the boss ends the stage", r.phase == Run.Phase.FEAST and r.alpha == -1)
	_check("eating the boss gives its mutation", r.weapons.owned.has("saws"))


func _check(what: String, ok: bool) -> void:
	print("%s: %s" % ["ok  " if ok else "FAIL", what])
	_failed = _failed or not ok
