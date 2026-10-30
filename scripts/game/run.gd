class_name Run
extends Node3D
## One playthrough: stage after stage on an open map (free driving, hordes, level-ups)
## followed by a ring-arena boss. Owns every subsystem and routes events
## between them (damage, kills, XP, crates, modals, camera, input).

signal exit_to_menu
signal retry_requested(class_id: String)

enum Phase { ROAM, BOSS_INTRO, BOSS, CLEAR, DEAD, FEAST }

const ARENA_CENTER := Vector3(0, 0, 4000)
const STICK_DEADZONE := 18.0

var class_id := ""
var stage := 1
var biome: Dictionary
var phase := Phase.ROAM
var stage_time := 0.0
var boss_window: Array = Defs.BOSS_WINDOW.duplicate()
var boss_time := 0.0  # when the boss turns up this stage, rolled from boss_window
var elite_times: Array = Defs.SPAWN["elite_times"].duplicate()
var horde_times: Array = Defs.SPAWN["horde_times"].duplicate()
## All gameplay randomness comes from `rng` so a seed can reproduce a run's rolls;
## screen shake and particles keep using the global generator.
var rng := RandomNumberGenerator.new()
var run_seed := 0  # 0 = pick a random one

var player: Player
var map: Map
var bot := Bot.new()
var enemies: Enemies
var projectiles: Projectiles
var pickups: Pickups
var weapons: Weapons
var fx: Fx
var boss: Boss
var camera: Camera3D
var hud: Hud
var levelup_ui: LevelUpUI
var crate_ui: CrateUI
var overlay: Overlay

var level := 1
var xp := 0
var xp_next := Defs.xp_to_next(1)
var pending_levelups := 0
var kills := 0
var score := 0
var combo := 0
var combo_timer := 0.0
var best_combo := 0

var autotest := false
var god_mode := false
var base_time_scale := 1.0

var _env: Environment
var _sun: DirectionalLight3D
var _modal_queue: Array = []
var _modal_open := false
var _paused_by_menu := false
var _spawn_acc := 0.0
var _cluster_center := Vector3.ZERO
var _cluster_timer := 0.0
var _next_elite := 0
var _next_horde := 0
var _gem_chain := 0
var _gem_chain_timer := 0.0
var _phase_timer := 0.0
var _cam_pos := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _cam_radial := Vector3.BACK
var _slowmo_left := 0.0
var _hitstop_left := 0.0
var _last_real_us := 0
var _clear_ready := false
var _score_saved := false
var redline := 0.0
var garage_damage := 1.0
var parts_earned := 0
var _xp_mult := 1.0
var _xp_frac := 0.0
var _revives := 0
var _run_parts_done := false
var nitro_left := 0.0
var _nitro_fx := 0.0
var _skipped := false  # jumped to a boss: the run stays off the leaderboard
var _touch_index := -1
var _touch_start := Vector2.ZERO
var _touch_start_ms := 0
var _touch_swiped := false
var _stick_index := -1
var _stick_base := Vector2.ZERO
var _stick_dir := Vector2.ZERO
var _dash_buffer := 0.0
var _dash_buffer_dir := 0.0
var _tmp: Array = []
var eat_mode := false  # creature classes grow by eating, see Defs.EAT
var body_size := 1.0
var body_mass := 1.0
var food_scale := 1.0
var view_zoom := 1.0
var alpha := -1  # enemy slot of the stage boss in eat mode
var frenzy := 0.0
var hungriest := 1.0  # autotest report: lowest hunger bar of the run, 0-1
var longest_fast := 0.0  # autotest report: most seconds between two meals
var _last_meal := 0.0
var _alpha_born := 0.0
var _frenzy_hold := 0.0
var _frenzied := false  # the full-Frenzy banner already showed
var _bite_cd := 0.0
var _chain_left := 0.0  # after a meal the next pounce may go any way
var _seek := 0.0
var _sniff := 0.0
var _scent := -1  # nearest food
var _prey := -1  # what the pounce in progress is aimed at
var _biting := false  # the lunge in progress ends in a bite, not a bounce
var _herd_timer := 0.0
var _threat_timer := 0.0
var _hungry_tick := 0.0
var _starved := false


func _ready() -> void:
	if run_seed != 0:
		rng.seed = run_seed
	else:
		rng.randomize()
		run_seed = rng.seed
	eat_mode = Defs.CLASSES[class_id].get("creature", false)
	if eat_mode and boss_window == Defs.BOSS_WINDOW:
		boss_window = Defs.EAT["boss_window"].duplicate()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_energy = 0.6
	_env.fog_enabled = true
	_env.fog_density = 0.012
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(35), 0)
	_sun.light_energy = 1.1
	_sun.shadow_enabled = false
	add_child(_sun)

	map = Map.new()
	add_child(map)
	enemies = Enemies.new()
	enemies.run = self
	add_child(enemies)
	projectiles = Projectiles.new()
	projectiles.run = self
	add_child(projectiles)
	pickups = Pickups.new()
	pickups.run = self
	add_child(pickups)
	fx = Fx.new()
	add_child(fx)
	player = Player.new()
	add_child(player)
	player.setup(class_id)
	_apply_garage()
	weapons = Weapons.new()
	weapons.run = self
	add_child(weapons)
	if player.def["weapon"] != "":
		weapons.add_weapon(player.def["weapon"])
	camera = Camera3D.new()
	camera.fov = Defs.MAP_CAMERA["fov"]
	camera.far = 260.0
	add_child(camera)
	camera.make_current()

	var ui := CanvasLayer.new()
	add_child(ui)
	hud = Hud.new()
	ui.add_child(hud)
	hud.pause_pressed.connect(_open_pause)
	levelup_ui = LevelUpUI.new()
	levelup_ui.auto_pick = autotest
	ui.add_child(levelup_ui)
	crate_ui = CrateUI.new()
	crate_ui.auto_close = autotest
	ui.add_child(crate_ui)
	overlay = Overlay.new()
	ui.add_child(overlay)

	_start_stage()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	Sfx.rev_stop()
	if get_tree():
		get_tree().paused = false


# --- stage flow ------------------------------------------------------------------

func _garage(id: String) -> float:
	return Save.garage_level(id) * float(Defs.GARAGE[id]["value"])


## Bots skip this so balance checks always measure the base game.
func _apply_garage() -> void:
	if autotest:
		return
	var p := player
	p.base_hp *= 1.0 + _garage("hull")
	p.max_hp = p.base_hp
	p.hp = p.max_hp
	p.base_armor += _garage("armor")
	p.armor = p.base_armor
	p.base_pickup *= 1.0 + _garage("magnet")
	p.pickup_radius = p.base_pickup
	p.base_speed *= 1.0 + _garage("engine")
	garage_damage = 1.0 + _garage("guns")
	_xp_mult = 1.0 + _garage("xp")
	redline = _garage("redline")
	_revives = Save.garage_level("revive")


func _earn_parts(amount: int) -> void:
	if autotest or amount <= 0:
		return
	parts_earned += amount
	Save.add_parts(amount)


## Pays for the kills and stages of a finished run, once.
func _finish_run() -> void:
	if _run_parts_done:
		return
	_run_parts_done = true
	_earn_parts(kills / Defs.PARTS["per_kills"] + stage * Defs.PARTS["stage"])


func _start_stage() -> void:
	biome = Defs.biome(stage)
	if eat_mode:
		biome = biome.duplicate()
		biome["name"] = _eat_stage(stage)["name"]
		biome["boss"] = _eat_stage(stage)["boss"]
		# Capped so the smallest food always fits your mouth, or you would starve.
		food_scale = minf(pow(Defs.EAT["stage_scale"], stage - 1), body_size * 0.9 / float(Defs.EAT_FOOD[0]["size"]))
		alpha = -1
		frenzy = 0.0
		_bite_cd = 0.0
		_chain_left = 0.0
		_scent = -1
		_prey = -1
		player.end_lunge()
	_apply_biome()
	update_pace()
	map.build(biome, rng)
	map.visible = true
	enemies.walls = map
	boss_time = rng.randf_range(boss_window[0], boss_window[1])
	enemies.clear()
	projectiles.clear()
	pickups.clear()
	fx.clear()
	if boss:
		boss.queue_free()
		boss = null
	phase = Phase.ROAM
	stage_time = 0.0
	_spawn_acc = 0.0
	_next_elite = 0
	_next_horde = 0
	player.place_on_map()
	_snap_camera_map()
	overlay.banner("STAGE %d" % stage, String(biome["name"]).to_upper(), Color(1, 0.85, 0.3), 1.8)
	if stage == 1:
		var hint := "WASD / arrows or drag to drive  ·  weapons fire on their own"
		if eat_mode:
			hint = "Steer at prey: you pounce and bite by yourself  ·  keep eating or you starve"
		hud.show_hint(hint, 6.0)
	if eat_mode:
		_last_meal = 0.0
		_herd_timer = Defs.EAT["herd_every"]
		_threat_timer = Defs.EAT["threat_every"]
		_spawn_herd(player.global_position + player.heading * 20.0)
		for k in Defs.EAT["start_herds"]:
			_spawn_herd(offscreen_point())


func _apply_biome() -> void:
	_env.background_color = biome["sky"]
	_env.fog_light_color = biome["fog"]
	_env.ambient_light_color = Color(biome["sky"]).lerp(Color(1, 1, 1), 0.5)
	_sun.light_color = Color(1, 0.95, 0.85) if biome["props"] != "neon" else Color(0.7, 0.6, 1.0)


func _start_boss_intro() -> void:
	phase = Phase.BOSS_INTRO
	_end_nitro()
	_phase_timer = 2.6
	overlay.banner("%s INCOMING" % String(biome["boss"]), "", Color(1, 0.3, 0.25), 1.8)
	Sfx.play("warn", -4.0, 1.0, true)
	pickups.vacuum = true
	# Clear the map with a satisfying chain of pops; the XP still drops and gets vacuumed.
	for i in enemies.used:
		if enemies.alive[i] == 1:
			_kill(i, false)
	projectiles.clear_enemy_shots()


func _enter_arena() -> void:
	phase = Phase.BOSS
	overlay.flash(Color(1, 1, 1, 0.9), 0.6)
	_collect_all_gems()
	enemies.clear()
	projectiles.clear()
	pickups.clear()
	map.visible = false
	enemies.walls = null
	_stick_reset()
	boss = Boss.new()
	add_child(boss)
	boss.setup(self, ARENA_CENTER, biome, stage)
	player.enter_arena(ARENA_CENTER)
	_snap_camera_arena()
	hud.show_hint("Swipe ← → to dash through attacks  ·  swipe ↑ ↓ to switch rings", 5.0)


## Vehicle speed from stage and upgrades; enemies keep pace by the same factor.
func update_pace() -> void:
	var pace := Defs.stage_speed_mult(stage) * weapons.speed_mult()
	if eat_mode:
		pace *= 1.0 + (_target_zoom() - 1.0) * Defs.EAT["pace_zoom"]
	player.speed = player.base_speed * pace
	enemies.speed_mult = pace


func _collect_all_gems() -> void:
	for i in pickups.g_val.size():
		if pickups.g_kind[i] == Pickups.GEM:
			add_xp(pickups.g_val[i])


func _on_boss_killed(p: Vector3) -> void:
	phase = Phase.CLEAR
	boss.die()
	_celebrate(p, "%s DESTROYED" % String(biome["boss"]), "")


## Ends the stage: the last enemies pop, then a crate and the stage-clear panel.
func _celebrate(p: Vector3, title: String, subtitle: String) -> void:
	add_score(Defs.BOSS_KILL_SCORE * stage)
	_earn_parts(Defs.PARTS["boss"] * stage)
	_slowmo(1.4, 0.3)
	fx.shake(1.0)
	Sfx.play("big_boom", 0.0, 1.0, true)
	for i in enemies.used:
		if enemies.alive[i] == 1:
			_kill(i, false)
	projectiles.clear_enemy_shots()
	for k in 6:
		var off := Vector3(randf_range(-2, 2), randf_range(0.5, 3.5), randf_range(-2, 2))
		get_tree().create_timer(0.12 * k, false, false, true).timeout.connect(func():
			fx.burst(p + off, Color(1, 0.6, 0.2), 24, 1.8)
			fx.ring(p, 6.0 + k, Color(1, 0.8, 0.3, 0.9), 0.5)
			Sfx.play("boom", -2.0))
	overlay.banner(title, subtitle, Color(1, 0.85, 0.3), 2.0)
	_clear_ready = false
	get_tree().create_timer(1.6, false, false, true).timeout.connect(func():
		pickups.vacuum = true
		pickups.drop_crate(player.global_position + player.velocity.normalized() * 3.0, 3)
		_clear_ready = true)
	_modal_queue.append({"kind": "clear"})


func _next_stage() -> void:
	stage += 1
	player.hp = minf(player.max_hp, player.hp + player.max_hp * Defs.STAGE_CLEAR_HEAL)
	_start_stage()


func _game_over() -> void:
	if phase == Phase.DEAD:
		return
	phase = Phase.DEAD
	if autotest and eat_mode:
		print("%s: t=%.0f alpha_hp=%.2f alpha_for=%.0f level=%d" % ["starved" if _starved else "eaten", stage_time, boss_ratio() if alpha >= 0 else -1.0, stage_time - _alpha_born if alpha >= 0 else 0.0, level])
	_slowmo(1.2, 0.25)
	fx.burst(player.global_position + Vector3(0, 1, 0), Color(1, 0.5, 0.2), 28, 2.0)
	fx.shake(1.0)
	Sfx.play("big_boom", 0.0, 1.0, true)
	player.visible = false
	var rank := _save_score()
	_finish_run()
	get_tree().create_timer(1.3, false, false, true).timeout.connect(func():
		var lines := [
			"Score  %d" % score,
			"Stage %d  ·  Level %d  ·  %d kills" % [stage, level, kills],
			"Best combo  x%d" % best_combo,
			"+%d parts" % parts_earned if parts_earned > 0 else "",
			"Size %.1f" % body_size if eat_mode else "",
			("New #%d on the local leaderboard!" % rank) if rank > 0 else "",
		]
		get_tree().paused = true
		overlay.show_panel(("STARVED" if _starved else "EATEN") if eat_mode else "WRECKED", lines, [["Retry", _retry], ["Main Menu", _quit_to_menu]], Color(1, 0.35, 0.3)))


## Records the run once, however it ends. Returns the leaderboard rank (0 = none).
func _save_score() -> int:
	if _score_saved or score <= 0 or autotest or _skipped:
		return 0
	_score_saved = true
	return Save.submit(score, class_id, stage, kills)


func _retry() -> void:
	get_tree().paused = false
	retry_requested.emit(class_id)


func _quit_to_menu() -> void:
	_save_score()
	_finish_run()
	get_tree().paused = false
	exit_to_menu.emit()


# --- main loop ---------------------------------------------------------------

func _process(delta: float) -> void:
	_update_time_scale(delta)
	match phase:
		Phase.ROAM:
			stage_time += delta
			if eat_mode:
				_hunt(delta)
			else:
				player.drive(delta, _move_input(delta), map)
				_update_redline(delta)
			_director(delta)
			if stage_time >= boss_time:
				if eat_mode:
					_spawn_alpha()
				else:
					_start_boss_intro()
		Phase.FEAST:
			player.drive(delta, _move_input(delta), map)
		Phase.BOSS_INTRO:
			player.drive(delta, _move_input(delta), map)
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_enter_arena()
		Phase.BOSS, Phase.CLEAR:
			player.arena_update(delta, ARENA_CENTER)
			if autotest:
				bot.boss_turn(self)
			if _dash_buffer > 0.0:
				_dash_buffer -= delta
				if player.dash_cd <= 0.0:
					_dash_buffer = 0.0
					_dash(_dash_buffer_dir)
			if boss:
				boss.update(delta)
		Phase.DEAD:
			pass
	if phase != Phase.DEAD:
		enemies.update(delta, player.global_position, player.velocity, player.radius)
		weapons.update(delta)
		projectiles.update(delta)
		pickups.update(delta)
	fx.update(delta)
	_update_combo(delta)
	if phase == Phase.ROAM or phase == Phase.BOSS_INTRO or phase == Phase.FEAST:
		_update_camera_map(delta)
	elif phase != Phase.DEAD:
		_update_camera_arena(delta)
	map.follow(_cam_look)
	hud.refresh(self)
	_try_open_modal()


## One frame of the creature: hunger, Frenzy and scent, then the pounce in progress or a run.
func _hunt(delta: float) -> void:
	var e := Defs.EAT
	var p := player
	_starve(delta)
	if phase == Phase.DEAD:
		return
	if _frenzy_hold > 0.0:
		_frenzy_hold -= delta
	else:
		frenzy = maxf(0.0, frenzy - e["frenzy_drain"] * delta)
		_frenzied = _frenzied and frenzy > 0.5
	_chain_left -= delta
	if p.lunge_left > 0.0:
		if _biting and enemies.is_alive(_prey):
			p.lunge_to = enemies.pos[_prey]
		if p.lunge_step(delta, map) and _biting:
			_chomp()
		return
	_bite_cd -= delta
	_sniff -= delta
	if _sniff <= 0.0:
		_sniff = 0.1
		_scent = enemies.nearest_food(p.global_position)
	var to_food := Vector3.ZERO
	var scent := false
	if enemies.is_alive(_scent) and enemies.edible(_scent):
		to_food = enemies.pos[_scent] - p.global_position
		to_food.y = 0.0
		scent = to_food.length() < e["scent_range"] * view_zoom and to_food.dot(p.heading) > to_food.length() * e["ahead"]
		var show := to_food.length() > bite_reach()
		to_food = to_food.normalized() if show else Vector3.ZERO
	p.set_scent(to_food, view_zoom)
	p.boost = (1.0 + e["frenzy_speed"] * frenzy) * (1.0 + (e["scent_boost"] if scent else 0.0))
	p.drive(delta, _move_input(delta), map)
	if _bite_cd > 0.0:
		return
	_seek -= delta
	if _seek > 0.0:
		return
	_seek = 0.05
	var i := enemies.bite_target(p.global_position, p.heading, bite_reach(), _chain_left > 0.0)
	if i >= 0:
		_pounce(i)


## Hunger is your health: it drains all the time and only food refills it.
func _starve(delta: float) -> void:
	if god_mode:
		return
	var e := Defs.EAT
	var drain: float = (e["hunger_drain"] + e["hunger_stage"] * (stage - 1)) * pow(Defs.PASSIVES["gut"]["hunger"], weapons.passive("gut"))
	player.hp -= drain * delta
	if autotest:
		hungriest = minf(hungriest, player.hp / player.max_hp)
	if player.hp < player.max_hp * 0.25:
		_hungry_tick -= delta
		if _hungry_tick <= 0.0:
			_hungry_tick = 0.8
			hud.damage_flash()
	if player.hp > 0.0:
		return
	player.hp = 0.0
	if _revives > 0:
		_revive()
	else:
		_starved = true
		_game_over()


func _pounce(i: int) -> void:
	_prey = i
	_biting = true
	player.set_scent(Vector3.ZERO, 1.0)
	var stop: float = 0.0 if enemies.edible(i) else enemies.radius[i] + player.radius * 0.5
	player.lunge(enemies.pos[i], Defs.EAT["lunge_time"], stop)
	Sfx.play("dash", -10.0, 1.5)


func bite_radius() -> float:
	var e := Defs.EAT
	var jaws: float = Defs.PASSIVES["jaws"]["bite"] * weapons.passive("jaws")
	return e["bite_radius"] * body_size * (1.0 + jaws) * (1.0 + e["frenzy_bite"] * frenzy)


func bite_reach() -> float:
	var e := Defs.EAT
	var legs: float = Defs.PASSIVES["legs"]["reach"] * weapons.passive("legs")
	return e["reach"] * (1.0 + (body_size - 1.0) * e["reach_grow"]) * (1.0 + legs)


## What a bite tears off something bigger, before Frenzy.
func plain_bite() -> float:
	var fangs: float = Defs.PASSIVES["fangs"]["tear"] * weapons.passive("fangs")
	return Defs.EAT["bite_dmg"] * body_size * (1.0 + fangs) * garage_damage


## The pounce lands: everything around is eaten or loses a chunk, all at once.
func _chomp() -> void:
	var e := Defs.EAT
	var at := player.global_position
	var r := bite_radius()
	_tmp.clear()
	enemies.query(at, r, _tmp)
	var eaten := 0
	var big := -1
	var downed := false
	for j in _tmp:
		if not enemies.is_alive(j):
			continue
		if enemies.edible(j):
			eaten += 1
			_kill(j, enemies.weak[j] > 0.0, true)
		else:
			big = j
			downed = _tear(j) or downed
	if phase != Phase.ROAM:
		return
	fx.ring(at, r, Color(1.0, 0.2, 0.15, 0.9), 0.2)
	Sfx.play("chomp", -3.0, 1.1 - minf(body_size, 8.0) * 0.05 + frenzy * 0.15, true)
	fx.shake(0.08 + 0.02 * mini(eaten, 10))
	if eaten >= 5:
		_hitstop(0.035)
		fx.burst(at + Vector3(0, 1, 0), Color(1.0, 0.25, 0.2), 20, 1.2 + body_size * 0.3)
		Sfx.play("big_boom", -14.0, 1.6, true)
	player.gulp()
	_bite_cd = e["bite_cd"]
	if eaten > 0 or downed:
		_bite_cd = 0.0
		_seek = 0.0
		_chain_left = e["chain_time"]
	elif big < 0:
		_bite_cd *= 0.5
	if big >= 0 and not downed:
		_bounce(enemies.pos[big])


## Bites something too big to swallow. Returns true if that dropped it.
func _tear(i: int) -> bool:
	var amount := plain_bite() * (1.0 + Defs.EAT["frenzy_tear"] * frenzy)
	enemies.hp[i] -= amount
	enemies.flash[i] = 0.1
	fx.number(enemies.pos[i], amount, frenzy > 0.75)
	fx.burst(enemies.pos[i] + Vector3(0, 0.5, 0), Color(0.8, 0.1, 0.1), 10, 1.0 + enemies.sizes[i] * 0.2)
	if enemies.hp[i] > 0.0:
		return false
	_knock_down(i)
	return true


## Biting something big throws you back off it, so hit-and-run needs no input.
func _bounce(from: Vector3) -> void:
	var e := Defs.EAT
	var away := player.global_position - from
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = -player.heading
	_biting = false
	player.lunge(player.global_position + away.normalized() * e["bounce"] * (1.0 + (body_size - 1.0) * e["reach_grow"]), e["bounce_time"], 0.0, false)


func _feed(d: Dictionary) -> void:
	var e := Defs.EAT
	longest_fast = maxf(longest_fast, stage_time - _last_meal)
	_last_meal = stage_time
	player.hp = minf(player.max_hp, player.hp + sqrt(float(d["xp"])) * e["meal"])
	var was := frenzy
	frenzy = minf(1.0, frenzy + e["frenzy_gain"])
	_frenzy_hold = e["frenzy_hold"] * (1.0 + Defs.PASSIVES["rage"]["hold"] * weapons.passive("rage"))
	if frenzy >= 1.0 and was < 1.0 and not _frenzied:
		_frenzied = true
		overlay.banner("FRENZY!", "", Color(1.0, 0.25, 0.15), 0.7)
		Sfx.play("reward", -6.0, 0.7, true)


func _update_redline(delta: float) -> void:
	var r := Defs.REDLINE
	if nitro_left > 0.0:
		nitro_left -= delta
		_nitro_fx -= delta
		if _nitro_fx <= 0.0:
			_nitro_fx = 0.05
			fx.burst(player.global_position + Vector3(0, 0.4, 0), Color(1.0, 0.55, 0.15), 4, 0.5)
		if nitro_left <= 0.0:
			_end_nitro()
		return
	if player.velocity.length() >= player.speed * r["min_speed"]:
		redline = minf(1.0, redline + r["fill"] * delta)
	else:
		redline = maxf(0.0, redline - r["drain"] * delta)
	if redline >= 1.0:
		_start_nitro()


func _start_nitro() -> void:
	nitro_left = Defs.REDLINE["nitro_time"]
	player.nitro = true
	player.boost = Defs.REDLINE["nitro_speed"]
	overlay.banner("NITRO!", "", Color(1.0, 0.5, 0.15), 0.8)
	Sfx.play("big_boom", -8.0, 1.5, true)
	fx.shake(0.4)


func _end_nitro() -> void:
	if not player.nitro:
		return
	nitro_left = 0.0
	player.nitro = false
	player.boost = 1.0
	redline = Defs.REDLINE["after_nitro"]


func _director(delta: float) -> void:
	if eat_mode:
		_director_eat(delta)
		return
	var sp := Defs.SPAWN
	var t := stage_time
	var sm := Defs.stage_spawn_mult(stage) * Defs.level_spawn_mult(level)
	var hm: float = enemy_hp_mult() * (1.0 + sp["hp_ramp"] * t / float(boss_window[1]))
	_cluster_timer -= delta
	if _cluster_timer <= 0.0:
		_cluster_timer = sp["cluster_every"]
		_cluster_center = offscreen_point()
	# Killing fast brings more enemies; falling behind does not snowball into a pile-up.
	var target := mini(Defs.MAX_ALIVE, int((sp["alive_base"] + t * sp["alive_ramp"]) * sm))
	_spawn_acc += delta * (sp["rate_base"] + t * sp["rate_ramp"]) * sm
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		if enemies.alive_count >= target:
			_spawn_acc = 0.0
			break
		var roll := rng.randf()
		var runner_w: float = 0.0 if t < sp["runner_from"] else sp["runner_weight"] + t * sp["runner_ramp"]
		var spitter_w: float = 0.0 if t < sp["spitter_from"] else sp["spitter_weight"] + t * sp["spitter_ramp"]
		if roll < spitter_w:
			enemies.spawn(Enemies.SPITTER, offscreen_point(), hm)
		elif roll < spitter_w + runner_w:
			enemies.spawn(Enemies.RUNNER, offscreen_point(), hm)
		else:
			var j: float = sp["cluster_jitter"] * food_scale
			enemies.spawn(Enemies.CRAWLER, _cluster_center + Vector3(rng.randf_range(-j, j), 0, rng.randf_range(-j, j)), hm)
	if _next_horde < horde_times.size() and t >= horde_times[_next_horde]:
		_next_horde += 1
		_spawn_horde(hm, sm)
	if _next_elite < elite_times.size() and t >= elite_times[_next_elite]:
		_next_elite += 1
		enemies.spawn(Enemies.BRUTE, offscreen_point(), hm)
		overlay.banner("ELITE!", "Bring it down and eat it for a crate" if eat_mode else "Destroy it for a salvage crate", Color(1.0, 0.75, 0.2), 1.4)
		Sfx.play("warn", -10.0, 1.4, true)


## Creatures don't get waves: herds wander in to be hunted, and threats come for you.
func _director_eat(delta: float) -> void:
	var e := Defs.EAT
	var t := stage_time
	_herd_timer -= delta
	if _herd_timer <= 0.0:
		_herd_timer = e["herd_every"] / (1.0 + e["herd_ramp"] * t)
		var at := offscreen_point()
		if alpha >= 0 and rng.randf() < 0.5:  # bosses bring food, which charges your bites
			var a := rng.randf() * TAU
			at = map.clamp_inside(enemies.pos[alpha] + Vector3(cos(a), 0, sin(a)) * 16.0 * view_zoom, 3.0)
		_spawn_herd(at)
	_threat_timer -= delta
	if _threat_timer <= 0.0:
		_threat_timer = e["threat_every"]
		if enemies.threat_count < e["threat_base"] + e["threat_ramp"] * t:
			_spawn_threat()
	if _next_elite < elite_times.size() and t >= elite_times[_next_elite]:
		_next_elite += 1
		var i := enemies.spawn(Enemies.BRUTE, offscreen_point())
		if i >= 0:
			_make_big(i, body_size * e["elite_size"], e["elite_bites"])
			enemies.elite[i] = 1
		overlay.banner("ELITE!", "Bite it down and eat it for a crate", Color(1.0, 0.75, 0.2), 1.4)
		Sfx.play("warn", -10.0, 1.4, true)


## Mostly the biggest food you can eat, sometimes something smaller.
func _spawn_herd(at: Vector3) -> void:
	if enemies.alive_count >= Defs.MAX_ALIVE:
		return
	var t := next_food() - 1 if next_food() >= 0 else Defs.EAT_FOOD.size() - 1
	if t > 0 and rng.randf() > 0.65:
		t = rng.randi_range(0, t - 1)
	t = maxi(t, 0)
	var f: Dictionary = Defs.EAT_FOOD[t]
	var n := int(f["herd"] * Defs.stage_spawn_mult(stage) * Defs.level_spawn_mult(level))
	var spread: float = Defs.EAT["herd_spread"] * f["size"] * food_scale * sqrt(float(n))
	var angle := rng.randf() * TAU
	for k in n:
		var a := rng.randf() * TAU
		var i := enemies.spawn(t, map.clamp_inside(at + Vector3(cos(a), 0, sin(a)) * spread * sqrt(rng.randf()) * 0.5, 3.0))
		if i >= 0:
			enemies.herd[i] = angle


## The next food you can't eat yet, or a brute once everything is food.
func _spawn_threat() -> void:
	var e := Defs.EAT
	var t := next_food()
	var i := enemies.spawn(t if t >= 0 else Enemies.BRUTE, offscreen_point())
	if i >= 0:
		_make_big(i, enemies.sizes[i] if t >= 0 else body_size * e["elite_size"], e["threat_bites"])
		enemies.speed[i] *= e["threat_speed"]
		enemies.dmg[i] *= e["threat_dmg"]


## `bites` counts plain bites at your size right now.
func _make_big(i: int, size: float, bites: float) -> void:
	enemies.set_body(i, size)
	enemies.hp[i] = bites * plain_bite()
	enemies.max_hp[i] = enemies.hp[i]


func enemy_hp_mult() -> float:
	return Defs.stage_hp_mult(stage) * Defs.level_hp_mult(level)


## Where a ray from the car in direction `d` leaves the screen, plus a margin.
func _screen_edge(d: Vector3) -> Vector3:
	var sp := Defs.SPAWN
	var side: float = sp["screen_side"] * get_viewport().get_visible_rect().size.aspect()
	var vertical: float = sp["screen_down"] if d.z > 0.0 else sp["screen_up"]
	return player.global_position + d * minf(side / maxf(absf(d.x), 0.01), vertical / maxf(absf(d.z), 0.01)) * view_zoom


## A spot just off screen and inside the map, usually in the direction of travel.
func offscreen_point() -> Vector3:
	var sp := Defs.SPAWN
	for k in 6:
		var a := rng.randf() * TAU
		if k == 0 and player.velocity.length_squared() > 0.25 and rng.randf() < sp["ahead_chance"]:
			a = atan2(player.heading.z, player.heading.x) + rng.randf_range(-sp["ahead_spread"], sp["ahead_spread"])
		var p := _screen_edge(Vector3(cos(a), 0, sin(a)))
		if map.contains(p, 3.0):
			return p
	return map.clamp_inside(_screen_edge(Vector3(cos(rng.randf() * TAU), 0, sin(rng.randf() * TAU)).normalized()), 3.0)


func _spawn_horde(hm: float, sm: float) -> void:
	overlay.banner("HORDE!", "", Color(0.6, 1.0, 0.3), 1.0)
	Sfx.play("warn", -8.0, 0.8, true)
	var n := int(Defs.SPAWN["horde_count"] * sm)
	for k in n:
		var a := TAU * k / n
		enemies.spawn(Enemies.CRAWLER, map.clamp_inside(_screen_edge(Vector3(cos(a), 0, sin(a))), 3.0), hm)


# --- combat events -----------------------------------------------------------

func hit_enemy(i: int, amount: float, knock_dir: Vector3, knock_force: float, show_number := true) -> void:
	if not enemies.is_alive(i) or enemies.weak[i] > 0.0:
		return
	var crit := rng.randf() < Defs.CRIT_CHANCE
	if crit:
		amount *= Defs.CRIT_MULT
	enemies.hp[i] -= amount
	enemies.flash[i] = 0.08
	var t := enemies.etype[i]
	if knock_force > 0.0:
		knock_dir.y = 0.0
		var push: Vector3 = knock_dir * knock_force * Defs.enemy_def(t)["knock"]
		enemies.knock[i] = (enemies.knock[i] + push).limit_length(Defs.KNOCK["max"])
	if show_number:
		fx.number(enemies.pos[i], amount, crit)
	Sfx.play("hit", -16.0)
	if enemies.hp[i] <= 0.0:
		if eat_mode and not enemies.can_swallow(i):
			_knock_down(i)
		else:
			_kill(i, true)


## What is bigger than you doesn't die at 0 HP: it drops and waits to be eaten.
func _knock_down(i: int) -> void:
	var e := Defs.EAT
	enemies.weaken(i, e["weak_time"] * (2.0 if i == alpha else 1.0))
	fx.ring(enemies.pos[i], enemies.radius[i] * 2.0, Color(1.0, 0.85, 0.2, 0.9), 0.4)
	Sfx.play("reward", -8.0, 1.2)
	if i == alpha:
		overlay.banner("EAT IT!", "", Color(1.0, 0.85, 0.2), 1.0)
		fx.shake(0.4)


func _spawn_alpha() -> void:
	boss_time = INF
	var e := Defs.EAT
	var i := enemies.spawn(Enemies.BRUTE, offscreen_point())
	if i < 0:
		return
	alpha = i
	_alpha_born = stage_time
	_make_big(i, body_size * e["alpha_size"], e["alpha_bites"])
	enemies.speed[i] = e["alpha_speed"]
	enemies.dmg[i] = e["alpha_dmg"]
	enemies.attack_cd[i] = e["alpha_lunge_every"]
	overlay.banner("%s INCOMING" % String(biome["boss"]), "Eat to fill Frenzy, then bite it down", Color(1, 0.3, 0.25), 1.8)
	Sfx.play("warn", -4.0, 1.0, true)


func _on_alpha_eaten(p: Vector3) -> void:
	alpha = -1
	phase = Phase.FEAST
	player.end_lunge()
	player.boost = 1.0
	player.set_scent(Vector3.ZERO, 1.0)
	if autotest:
		print("alpha eaten: stage=%d t=%.0f fight=%.1f size=%.1f level=%d hp=%d" % [stage, stage_time, stage_time - _alpha_born, body_size, level, player.hp])
	var m: Dictionary = _eat_stage(stage)["mutation"]
	for k in 2:
		weapons.add_passive(m["trait"])
	player.add_mutation(m["part"], m["color"])
	_celebrate(p, "%s EATEN" % String(biome["boss"]), "Mutation: %s  ·  %s" % [m["name"], m["desc"]])


func _eat_stage(n: int) -> Dictionary:
	return Defs.EAT_STAGES[(n - 1) % Defs.EAT_STAGES.size()]


## The first kind of food still too big to eat, or -1 when everything is food.
func next_food() -> int:
	for t in Defs.EAT_FOOD.size():
		if Defs.EAT_FOOD[t]["size"] * food_scale >= body_size:
			return t
	return -1


## 0-1 progress toward being able to eat the next kind of food.
func food_progress() -> float:
	var t := next_food()
	if t < 0:
		return 1.0
	var from: float = Defs.EAT_FOOD[t - 1]["size"] * food_scale if t > 0 else 0.0
	return clampf((body_size - from) / (Defs.EAT_FOOD[t]["size"] * food_scale - from), 0.0, 1.0)


func food_text() -> String:
	var t := next_food()
	if t < 0:
		return "SIZE %.1f  ·  EVERYTHING IS FOOD" % body_size
	return "SIZE %.1f  ·  NEXT: %s" % [body_size, Defs.EAT_FOOD[t]["name"]]


func _grow(mass: float) -> void:
	var was := next_food()
	body_mass += mass
	body_size = sqrt(body_mass)
	player.set_body_size(body_size)
	update_pace()
	if next_food() != was:
		overlay.banner("%s ARE FOOD NOW" % Defs.EAT_FOOD[was]["name"], "", Color(0.5, 1.0, 0.4), 1.2)
		if autotest:
			print("food: stage=%d t=%.0f %s size=%.1f" % [stage, stage_time, Defs.EAT_FOOD[was]["name"], body_size])
		Sfx.play("reward", -3.0, 0.9, true)
		fx.ring(player.global_position, player.radius * 4.0, Color(0.5, 1.0, 0.4, 0.9), 0.5)
	var form := player.form
	while form + 1 < Defs.EAT_FORMS.size() and body_size >= Defs.EAT_FORMS[form + 1]["size"]:
		form += 1
	if form != player.form:
		_evolve(form)


func _evolve(form: int) -> void:
	player.set_form(form)
	overlay.banner("EVOLVED", String(Defs.EAT_FORMS[form]["name"]).to_upper(), Color(1.0, 0.35, 0.2), 1.6)
	if autotest:
		print("form: stage=%d t=%.0f %s size=%.1f" % [stage, stage_time, Defs.EAT_FORMS[form]["name"], body_size])
	Sfx.play("big_boom", -6.0, 0.8, true)
	Sfx.play("reward", -3.0, 0.6, true)
	fx.shake(0.6)
	fx.ring(player.global_position, player.radius * 6.0, Color(1.0, 0.3, 0.2, 0.9), 0.6)
	fx.burst(player.global_position + Vector3(0, 1, 0), Color(0.9, 0.1, 0.1), 40, 1.5 + body_size * 0.4)
	_slowmo(0.5, 0.35)


func _kill(i: int, drops: bool, eaten := false) -> void:
	var t := enemies.etype[i]
	var d := Defs.enemy_def(t)
	var p := enemies.pos[i]
	var was_alpha := i == alpha
	var bite := enemies.sizes[i]
	var was_elite := enemies.elite[i] == 1
	enemies.remove(i)
	kills += 1
	combo += 1
	combo_timer = Defs.COMBO_WINDOW
	best_combo = maxi(best_combo, combo)
	add_score(int(d["score"] * combo_mult()))
	fx.burst(p + Vector3(0, 0.5, 0), d["color"], 16 if t >= Enemies.BRUTE else 10)
	Sfx.play("kill", -10.0, 1.0 + minf(combo, 40) * 0.012)
	if t == Enemies.BOSS:
		_on_boss_killed(p)
		return
	if eaten:
		fx.burst(p + Vector3(0, 0.5, 0), d["color"], 14, 1.0 + bite * 0.3)
		Sfx.play("pickup", -6.0, 0.8 + minf(combo, 40) * 0.02)
		fx.shake(0.04 + 0.03 * bite)
		add_xp(d["xp"] * Defs.EAT["xp"])
		_feed(d)
		_grow(bite * bite * Defs.EAT["growth"] / food_scale)
		if was_alpha:
			_on_alpha_eaten(p)
			return
	else:
		pickups.drop_gem(p, d["xp"])
	if not drops:
		return
	if rng.randf() < Defs.REPAIR_CHANCE:
		pickups.drop_repair(p)
	if t == Enemies.BRUTE and (was_elite or not eat_mode):
		fx.shake(0.35)
		_hitstop(0.07)
		Sfx.play("boom", -2.0)
		if phase == Phase.ROAM:
			pickups.drop_crate(map.clamp_inside(p, 3.0))
		else:
			pickups.drop_crate(player.global_position)


func explode(p: Vector3, r: float, amount: float, napalm: bool) -> void:
	_tmp.clear()
	enemies.query(p, r, _tmp)
	for j in _tmp:
		var out: Vector3 = enemies.pos[j] - p
		out.y = 0.0
		hit_enemy(j, amount, out.normalized(), Defs.KNOCK["blast"])
	fx.burst(p, Color(1.0, 0.6, 0.2), 16, 1.3)
	fx.ring(p, r, Color(1.0, 0.65, 0.25, 0.9), 0.3)
	Sfx.play("boom", -8.0)
	fx.shake(0.06)
	if napalm:
		var mines: Dictionary = Defs.WEAPONS["mines"]
		projectiles.add_zone(p, r * mines["napalm_radius"], mines["napalm_dps"] * weapons.damage_mult(), mines["napalm_life"])


func on_enemy_contact(i: int) -> void:
	if eat_mode:
		if enemies.edible(i):
			_kill(i, enemies.weak[i] > 0.0, true)
		elif player.can_be_hit():
			player_hit(enemies.dmg[i])
		return
	if enemies.ram_cd[i] <= 0.0 and enemies.etype[i] != Enemies.BOSS:
		enemies.ram_cd[i] = Defs.RAM_COOLDOWN
		var away := enemies.pos[i] - player.global_position
		away.y = 0.0
		var spd := clampf(player.velocity.length() / player.speed, 0.6, 1.0)
		var r := Defs.REDLINE
		var power: float = (1.0 + r["ram_bonus"] * redline) * (r["nitro_ram"] if player.nitro else 1.0)
		hit_enemy(i, player.ram_damage * spd * power, away.normalized(), Defs.KNOCK["ram"])
	if enemies.is_alive(i) and player.can_be_hit():
		player_hit(enemies.dmg[i])


func player_hit(amount: float) -> void:
	if god_mode or phase == Phase.DEAD or phase == Phase.CLEAR or phase == Phase.FEAST:
		return
	var taken := player.hurt(amount * Defs.stage_dmg_mult(stage) * Defs.level_dmg_mult(level))
	if taken <= 0.0:
		return
	redline = maxf(0.0, redline - Defs.REDLINE["hit_loss"])
	fx.shake(0.3)
	hud.damage_flash()
	Sfx.play("hurt", -4.0)
	if player.hp <= 0.0:
		if _revives > 0:
			_revive()
		else:
			_game_over()


func _revive() -> void:
	_revives -= 1
	player.hp = player.max_hp * float(Defs.GARAGE["revive"]["value"])
	player.invuln = 2.0
	overlay.banner("SECOND STOMACH!" if eat_mode else "SPARE ENGINE!", "", Color(0.4, 1.0, 0.5), 1.0)
	Sfx.play("reward", -2.0, 0.8, true)
	fx.shake(0.5)


func add_xp(amount: float) -> void:
	_xp_frac += amount * _xp_mult
	var whole := int(_xp_frac)
	_xp_frac -= whole
	xp += whole
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = Defs.xp_to_next(level)
		pending_levelups += 1


func heal(amount: float) -> void:
	player.hp = minf(player.max_hp, player.hp + amount)
	fx.burst(player.global_position + Vector3(0, 1.2, 0), Color(0.3, 1.0, 0.4), 12, 0.7)
	Sfx.play("reward", -6.0, 1.3)


func add_score(amount: int) -> void:
	score += amount


func combo_mult() -> float:
	return 1.0 + minf(combo, 200) / 50.0


## Called once per frame in which at least one gem was collected; the chime
## climbs in pitch while pickups keep chaining.
func on_gem_collected() -> void:
	_gem_chain = mini(_gem_chain + 1, 30)
	_gem_chain_timer = 0.6
	Sfx.play("pickup", -9.0, 1.0 + _gem_chain * 0.045, true)


func open_crate(guaranteed: int) -> void:
	var roll := rng.randf()
	var count := 1
	if guaranteed >= 5:
		count = 5
	elif guaranteed >= 3:
		count = 5 if roll < 0.3 else 3
	else:
		count = 5 if roll < 0.08 else (3 if roll < 0.4 else 1)
	_modal_queue.push_front({"kind": "crate", "count": count})
	fx.burst(player.global_position + Vector3(0, 1.5, 0), Color(1, 0.8, 0.3), 24, 1.5)


func _update_combo(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
	if _gem_chain_timer > 0.0:
		_gem_chain_timer -= delta
		if _gem_chain_timer <= 0.0:
			_gem_chain = 0


func is_boss_phase() -> bool:
	return phase == Phase.BOSS or phase == Phase.CLEAR


## Array.shuffle() uses the global generator, so seeded code must use this instead.
func shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t


## Keeps a thrown object on the map, or on the arena floor during a boss fight.
func keep_in_play(p: Vector3) -> Vector3:
	if not is_boss_phase():
		return map.clamp_inside(p, 1.0)
	return ARENA_CENTER + (p - ARENA_CENTER).limit_length(Defs.ARENA["floor_radius"])


func boss_name() -> String:
	if alpha >= 0 and enemies.weak[alpha] > 0.0:
		return "%s IS DOWN: EAT IT!" % String(biome["boss"])
	return String(biome["boss"])


func boss_ratio() -> float:
	if alpha >= 0:
		return enemies.hp[alpha] / enemies.max_hp[alpha]
	return boss.hp_ratio() if boss else 0.0


# --- modals (level-up, crate, stage clear) -------------------------------------

func _try_open_modal() -> void:
	if _modal_open or _paused_by_menu or phase == Phase.DEAD:
		return
	if _modal_queue.is_empty() and pending_levelups > 0 and phase != Phase.BOSS_INTRO:
		_modal_queue.append({"kind": "levelup"})
	if _modal_queue.is_empty():
		return
	var m: Dictionary = _modal_queue[0]
	# The stage-clear panel waits for the boss crate and any pending level-ups.
	if m["kind"] == "clear":
		if not _clear_ready or not pickups.crates.is_empty():
			return
		_collect_all_gems()
		pickups.clear()
		if pending_levelups > 0:
			_modal_queue.push_front({"kind": "levelup"})
			m = _modal_queue[0]
	_modal_queue.pop_front()
	_modal_open = true
	_stick_reset()
	get_tree().paused = true
	match m["kind"]:
		"levelup":
			levelup_ui.open(weapons.level_up_options(3), level - pending_levelups + 1, func(o: Dictionary):
				weapons.apply(o)
				pending_levelups -= 1
				_close_modal())
		"crate":
			crate_ui.open(m["count"], weapons.crate_rewards(m["count"]), func(rewards: Array):
				for r in rewards:
					weapons.apply(r)
				_close_modal())
		"clear":
			var next: Dictionary = _eat_stage(stage + 1) if eat_mode else Defs.biome(stage + 1)
			overlay.show_panel("STAGE %d CLEAR" % stage, [
				"Score  %d" % score,
				"Level %d  ·  %d kills  ·  best combo x%d" % [level, kills, best_combo],
				"Next: %s (harder)" % next["name"],
			], [["Drive on", func():
				_close_modal()
				_next_stage()], ["Main Menu", _quit_to_menu]])
			if autotest:
				get_tree().create_timer(0.5, true).timeout.connect(func():
					overlay.hide_panel()
					_close_modal()
					_next_stage())


func _close_modal() -> void:
	_modal_open = false
	if not _paused_by_menu:
		get_tree().paused = false


func _open_pause() -> void:
	if _modal_open or phase == Phase.DEAD or _paused_by_menu:
		return
	_paused_by_menu = true
	_stick_reset()
	get_tree().paused = true
	var buttons := [["Resume", _resume]]
	if phase == Phase.ROAM and alpha < 0:
		buttons.append(["Skip to boss (test)", func():
			_resume()
			_skipped = true
			stage_time = boss_time])
	buttons.append(["Quit to menu", _quit_to_menu])
	overlay.show_panel("PAUSED", ["Stage %d  ·  %s" % [stage, biome["name"]]], buttons)


func _resume() -> void:
	_paused_by_menu = false
	if not _modal_open:
		get_tree().paused = false


# --- time feel -----------------------------------------------------------------

func _hitstop(duration: float) -> void:
	_hitstop_left = maxf(_hitstop_left, duration)


func _slowmo(duration: float, time_scale: float) -> void:
	_slowmo_left = duration
	Engine.time_scale = time_scale * base_time_scale


func _update_time_scale(_delta: float) -> void:
	# Hitstop/slow-mo count down in real time so they end on schedule.
	var now := Time.get_ticks_usec()
	var real := clampf((now - _last_real_us) / 1000000.0, 0.0, 0.1) if _last_real_us > 0 else 0.0
	_last_real_us = now
	if _hitstop_left > 0.0:
		_hitstop_left -= real
		Engine.time_scale = 0.05 if _hitstop_left > 0.0 else base_time_scale
	elif _slowmo_left > 0.0:
		_slowmo_left -= real
		if _slowmo_left <= 0.0:
			Engine.time_scale = base_time_scale
	elif Engine.time_scale != base_time_scale:
		Engine.time_scale = base_time_scale


# --- camera ------------------------------------------------------------------------

func _map_cam_targets() -> Array:
	var cam := Defs.MAP_CAMERA
	var car := player.global_position
	var look: Vector3 = car + player.velocity * cam["lead"]
	return [look + Vector3(0, cam["up"], cam["back"]) * view_zoom, look]


func _snap_camera_map() -> void:
	var t := _map_cam_targets()
	_cam_pos = t[0]
	_cam_look = t[1]
	_place_camera()


func _target_zoom() -> float:
	return 1.0 + (body_size - 1.0) * Defs.EAT["zoom"]


func _update_camera_map(delta: float) -> void:
	if eat_mode:
		view_zoom = lerpf(view_zoom, _target_zoom(), 1.0 - exp(-3.0 * delta))
		_env.fog_density = 0.003 / view_zoom  # sand-coloured fog washes out who is who
	var t := _map_cam_targets()
	var k := 1.0 - exp(-8.0 * delta)
	_cam_pos = _cam_pos.lerp(t[0], k)
	_cam_look = _cam_look.lerp(t[1], k)
	_place_camera()


func _arena_cam_targets() -> Array:
	var radial := player.global_position - ARENA_CENTER
	radial.y = 0.0
	radial = radial.normalized()
	var pos := ARENA_CENTER + radial * (player.ring_radius + 10.0) + Vector3.UP * 12.0
	var look := ARENA_CENTER + radial * (player.ring_radius * 0.3)
	return [pos, look]


func _snap_camera_arena() -> void:
	var t := _arena_cam_targets()
	_cam_pos = t[0]
	_cam_look = t[1]
	_place_camera()


func _update_camera_arena(delta: float) -> void:
	var t := _arena_cam_targets()
	var k := 1.0 - exp(-8.0 * delta)
	_cam_pos = _cam_pos.lerp(t[0], k)
	_cam_look = _cam_look.lerp(t[1], k)
	_place_camera()


func _place_camera() -> void:
	var shake := fx.trauma * fx.trauma
	var off := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake * 0.9
	camera.global_position = _cam_pos + off
	camera.look_at(_cam_look + off * 0.5, Vector3.UP)


# --- input ---------------------------------------------------------------------------

func _notification(what: int) -> void:
	# Android back button: toggle the pause menu instead of quitting the app.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _paused_by_menu:
			overlay.hide_panel()
			_resume()
		else:
			_open_pause()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _paused_by_menu:
			overlay.hide_panel()
			_resume()
		else:
			_open_pause()
		return
	if get_tree().paused:
		return
	if is_boss_phase():
		_boss_input(event)
	elif phase == Phase.ROAM or phase == Phase.BOSS_INTRO or phase == Phase.FEAST:
		_stick_input(event)


## Screen-relative move direction. Keys give 8 directions, the stick any angle.
func _move_input(delta: float) -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.0)
	if autotest:
		v = bot.steer(self, delta)
	elif _stick_dir != Vector2.ZERO:
		v = _stick_dir
	return v


func _stick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _stick_index == -1:
			_stick_start(event.index, event.position)
		elif not event.pressed and event.index == _stick_index:
			_stick_reset()
	elif event is InputEventScreenDrag:
		if _stick_index == -1:
			_stick_start(event.index, event.position)
		if event.index == _stick_index:
			var d: Vector2 = event.position - _stick_base
			_stick_base = event.position - d.limit_length(Joystick.RADIUS)
			_stick_dir = d if d.length() > STICK_DEADZONE else Vector2.ZERO
			hud.joystick.show_at(_stick_base, event.position)


func _stick_start(index: int, at: Vector2) -> void:
	_stick_index = index
	_stick_base = at
	_stick_dir = Vector2.ZERO
	hud.joystick.show_at(at, at)


func _stick_reset() -> void:
	_stick_index = -1
	_stick_dir = Vector2.ZERO
	hud.joystick.visible = false


func _boss_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		_dash(-1.0)
	elif event.is_action_pressed("move_right"):
		_dash(1.0)
	elif event.is_action_pressed("move_up"):
		_ring(-1)
	elif event.is_action_pressed("move_down"):
		_ring(1)
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_touch_start = event.position
			_touch_start_ms = Time.get_ticks_msec()
			_touch_swiped = false
		elif not event.pressed and event.index == _touch_index:
			if not _touch_swiped and Time.get_ticks_msec() - _touch_start_ms < 250:
				var width := get_viewport().get_visible_rect().size.x
				_dash(-1.0 if event.position.x < width * 0.5 else 1.0)
			_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _touch_index and not _touch_swiped:
		var d: Vector2 = event.position - _touch_start
		if d.length() > 50.0:
			_touch_swiped = true
			if absf(d.x) > absf(d.y):
				_dash(signf(d.x))
			else:
				_ring(-1 if d.y < 0.0 else 1)


func _dash(dir: float) -> void:
	if phase != Phase.BOSS:
		return
	if player.dash(dir, camera.global_transform.basis.x):
		Sfx.play("dash", -4.0)
		fx.burst(player.global_position + Vector3(0, 0.5, 0), Color(0.8, 0.9, 1.0), 10, 0.6)
	else:
		# Swiped during the cooldown: dash as soon as it ends instead of dropping the input.
		_dash_buffer = Defs.ARENA["dash_buffer"]
		_dash_buffer_dir = dir


func _ring(step: int) -> void:
	if phase != Phase.BOSS:
		return
	if player.switch_ring(step):
		Sfx.play("dash", -8.0, 1.4)
