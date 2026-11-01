class_name Run
extends Node3D
## One dig: owns every subsystem and routes events between them (cube hits, pops, XP, level-ups,
## camera, input). A run ends by breaking the Heart, leaving by lift, dying or giving up.

signal exit_to_menu
signal retry_requested

const PENTATONIC := [0, 2, 4, 7, 9]  # any run of these notes sounds good

## All gameplay randomness comes from `rng` so a seed can reproduce a run.
var rng := RandomNumberGenerator.new()
var run_seed := 0  # 0 = pick a random one

var player: Player
var mine: Mine
var debris: Debris
var pickups: Pickups
var tools: Tools
var enemies: Enemies
var traps: Traps
var sites: Sites
var fx: Fx
var bot := Bot.new()
var camera: Camera3D
var hud: Hud
var levelup_ui: LevelUpUI
var overlay: Overlay
var results: Results
var character: Dictionary = Defs.CHARACTERS["digger"]

var level := 1
var xp := 0.0
var xp_next := Defs.xp_to_next(1)
var pending_levelups := 0
var cubes := 0
var kills := 0
var loot := 0.0  # gems carried: only what you bring out counts
var gem_rate := 1.0
var base_hp: float = Defs.DIGGER["hp"]
var hits_taken := 0
var hardness := 1.0  # how much tougher enemies are, from your damage
var crowd := 1.0  # how many more come, from your upgrades
var pace := 1.0
var harm := 1.0
var nudge := 1.0  # how far a hit pushes them
var runners := 0.0  # share of the swarm that are runners
var score := 0
var combo := 0
var combo_timer := 0.0
var best_combo := 0
var frenzy_left := 0.0
var frenzies := 0
var geodes := 0
var relics := 0
var evolutions := 0
var greed_harm := 1.0  # a Greed Shrine's price
var run_time := 0.0
var depth := 0.0
var band := 0
var autotest := false
var god_mode := false
var dead := false
var left := false  # got out alive
var banked := false
var base_time_scale := 1.0

var _modal_open := false
var _paused_by_menu := false
var _note := 0
var _note_timer := 0.0
var _gem_chain := 0
var _gem_chain_timer := 0.0
var _heart_woken := false
var _told := {}  # goals already announced this run
var _goal_timer := 1.0
var _frenzy_rest := 0.0
var _frenzy_base := 0  # the combo the last Frenzy ended on
var _geode_cd := 0.0
var _pops_this_frame := 0
var _big_pop_cd := 0.0
var _scan_timer := 0.0
var _burrow_timer: float = Defs.THREATS["burrow_from"]
var _swarm_timer: float = Defs.THREATS["swarm_from"]
var _horde_timer: float = Defs.THREATS["horde_from"]
var _lamp: OmniLight3D
var _cam_pos := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _kick := Vector3.ZERO
var _hitstop_left := 0.0
var _last_real_us := 0
var aim_point := Vector3.ZERO  # the spot on the rock under the pointer
var _mouse_seen := false  # until the mouse moves, tools point the way you walk


func _ready() -> void:
	character = Defs.CHARACTERS[Profile.character]
	if run_seed != 0:
		rng.seed = run_seed
	else:
		rng.randomize()
		run_seed = rng.seed
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.04, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 0.97, 0.92)
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-60), deg_to_rad(30), 0)
	sun.light_energy = 0.75
	add_child(sun)

	mine = Mine.new()
	mine.run = self
	add_child(mine)
	mine.generate(rng)
	enemies = Enemies.new()
	enemies.run = self
	add_child(enemies)
	enemies.fill_nests()
	traps = Traps.new()
	traps.run = self
	add_child(traps)
	traps.generate(rng)
	debris = Debris.new()
	add_child(debris)
	pickups = Pickups.new()
	pickups.run = self
	add_child(pickups)
	fx = Fx.new()
	add_child(fx)
	sites = Sites.new()
	sites.run = self
	add_child(sites)
	player = Player.new()
	player.color = character["color"]
	player.base_speed *= character.get("speed", 1.0) * (1.0 + Profile.bonus("legs"))
	player.base_pickup *= 1.0 + Profile.bonus("magnet")
	add_child(player)
	tools = Tools.new()
	tools.run = self
	add_child(tools)
	tools.add_tool(character["tool"])
	base_hp = (base_hp + Profile.bonus("health")) * character.get("hp", 1.0)
	gem_rate = character.get("gems", 1.0) * (1.0 + Profile.bonus("greed"))
	_lamp = OmniLight3D.new()
	_lamp.position.y = 3.0
	_lamp.light_color = Color(1.0, 0.85, 0.65)
	_lamp.light_energy = 1.6
	_lamp.omni_range = Defs.WORLD["light"]
	player.add_child(_lamp)
	camera = Camera3D.new()
	camera.fov = Defs.CAMERA["fov"]
	camera.far = 120.0
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
	overlay = Overlay.new()
	ui.add_child(overlay)
	results = Results.new()
	ui.add_child(results)
	results.again_pressed.connect(_new_mine)
	results.menu_pressed.connect(_quit_to_menu)

	apply_boosts()
	player.hp = player.max_hp
	var t := _cam_targets()
	_cam_pos = t[0]
	_cam_look = t[1]
	_place_camera()
	apply_fog()
	Input.set_custom_mouse_cursor(Ui.crosshair(Color(1, 1, 1)), Input.CURSOR_ARROW, Vector2(24, 24))
	hud.show_hint("WASD to move  ·  aim with the mouse  ·  your tools dig by themselves", 6.0)


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	Input.set_custom_mouse_cursor(null)
	if get_tree():
		get_tree().paused = false


func apply_fog() -> void:
	mine.set_fog(Options.fog)
	_lamp.visible = Options.fog
	_scan_timer = 0.0


func _update_light(delta: float) -> void:
	if not Options.fog:
		return
	var at := player.global_position
	mine.light_at(at)
	_lamp.light_energy = 1.6 + sin(run_time * 11.0) * 0.06  # a living flame, barely
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = Defs.WORLD["scan_every"]
		mine.scan_light(at)


func apply_boosts() -> void:
	var extra: float = float(Defs.BOOSTS["tough"]["value"]) * tools.boost("tough")
	player.hp += base_hp + extra - player.max_hp
	player.max_hp = base_hp + extra
	player.speed = player.base_speed * (1.0 + float(Defs.BOOSTS["legs"]["value"]) * tools.boost("legs"))
	player.pickup_radius = player.base_pickup * (1.0 + float(Defs.BOOSTS["magnet"]["value"]) * tools.boost("magnet"))


# --- main loop ---------------------------------------------------------------------

func _process(delta: float) -> void:
	_update_time_scale()
	if dead or left:
		debris.update(delta)
		fx.update(delta)
		_update_camera(delta)
		return
	run_time += delta
	_pops_this_frame = 0
	_big_pop_cd -= delta
	_update_aim()
	player.move(minf(delta, 0.05), _move_input(delta), mine)
	_update_light(delta)
	tools.update(delta)
	mine.update(delta)
	var at := player.global_position
	enemies.update(delta, at, player.radius)
	traps.update(delta, at)
	sites.update(delta, at)
	_update_burrowers(delta)
	_update_swarm(delta)
	debris.update(delta)
	pickups.update(delta)
	fx.update(delta)
	_update_depth()
	_update_chains(delta)
	_update_camera(delta)
	hud.refresh(self)
	_announce_goals(delta)
	if not dead and not left:
		_try_open_modal()


## Points the tools at the mouse. Aiming stays flat, at the height of the rock's top.
func _update_aim() -> void:
	var at := player.global_position
	if autotest:
		bot.aim(self)
	if not _mouse_seen or autotest or character.has("no_aim"):
		aim_point = at + player.heading * 5.0
		return
	var screen := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	aim_point = from + dir * (Mine.HEIGHT - from.y) / minf(dir.y, -0.01)
	aim_point.y = 0.0
	var to := aim_point - Vector3(at.x, 0.0, at.z)
	if to.length_squared() > 0.01:
		player.aiming = true
		player.heading = to.normalized()


## Burrowers keep coming, so no spot stays safe, and they come more often the deeper you are.
func _update_burrowers(delta: float) -> void:
	var t := Defs.THREATS
	_burrow_timer -= delta
	if _burrow_timer > 0.0:
		return
	_burrow_timer = maxf(t["burrow_min"], t["burrow_every"] - band * 2.0)
	for k in 1 + band / 2:
		var a := rng.randf() * TAU
		var p := mine.clamp_inside(player.global_position + Vector3(cos(a), 0, sin(a)) * t["burrow_range"])
		enemies.spawn(Enemies.BURROWER, p, -1, true)


## Enemies scale from what you actually have, not from time, so a strong build meets a strong mine.
func _update_power() -> void:
	var t := Defs.THREATS
	var best := 1.0
	var upgrades := -1  # the starting shovel isn't an upgrade
	for id in tools.order:
		best = maxf(best, tools.power_of(id))
		upgrades += tools.level(id)
	for id in tools.boost_order:
		upgrades += tools.boost(id)
	upgrades = maxi(0, upgrades - t["free_upgrades"])
	hardness = pow(best, t["hard_power"]) * (1.0 + t["tough_per"] * upgrades)
	crowd = 1.0 + t["crowd_per"] * upgrades
	runners = minf(t["runner_per"] * upgrades, t["runner_max"])
	pace = minf(1.0 + t["pace_per"] * upgrades, t["pace_max"])
	harm = (1.0 + t["harm_per"] * upgrades) * greed_harm
	nudge = 1.0 / (1.0 + t["nudge_per"] * upgrades)


## The steady flow of crawlers, and now and then a whole ring of them, as in VS.
func _update_swarm(delta: float) -> void:
	var t := Defs.THREATS
	_update_power()
	_swarm_timer -= delta
	if _swarm_timer <= 0.0:
		_swarm_timer = t["swarm_every"]
		var limit: float = minf((t["swarm_alive"] + t["swarm_alive_ramp"] * run_time) * crowd, t["swarm_max"])
		if enemies.awake_count < limit:
			var a := rng.randf() * TAU
			for k in int((t["swarm_size"] + t["swarm_size_ramp"] * run_time) * crowd):
				_swarm_in(a + rng.randf_range(-0.5, 0.5), t["swarm_range"])
	_horde_timer -= delta
	if _horde_timer <= 0.0:
		_horde_timer = Defs.RUN["heart_horde"] if _heart_woken else t["horde_every"] / sqrt(crowd)
		spawn_horde()


func spawn_horde() -> void:
	var t := Defs.THREATS
	var n := int(minf((t["horde_size"] + t["horde_ramp"] * run_time) * crowd, t["horde_max"]))
	for k in n:
		_swarm_in(TAU * k / n, t["horde_range"] + rng.randf_range(0.0, 3.0))
	overlay.banner("SWARM!", "", Color(1, 0.25, 0.2), 1.2)
	Sfx.play("warn", -6.0, 1.0, true)
	fx.shake(0.25)


func _swarm_in(angle: float, dist: float) -> void:
	var p := mine.clamp_inside(player.global_position + Vector3(cos(angle), 0, sin(angle)) * dist)
	enemies.spawn(Enemies.RUNNER if rng.randf() < runners else Enemies.CRAWLER, p, -1, true, true)


func _update_depth() -> void:
	var at := player.global_position
	at.y = 0.0
	depth = at.length()
	var b := mine.band_at(depth)
	if b > band:
		band = b
		overlay.banner(Defs.BANDS[b]["name"], "", Color(1, 0.85, 0.3), 1.2)
		Sfx.play("reward", -6.0, 0.8, true)


func _update_chains(delta: float) -> void:
	_geode_cd -= delta
	_frenzy_rest -= delta
	if frenzy_left > 0.0:
		frenzy_left -= delta
		if frenzy_left <= 0.0:
			frenzy_left = 0.0
			_frenzy_rest = Defs.FRENZY["rest"]
			_frenzy_base = combo
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
			_frenzy_base = 0
	if _note_timer > 0.0:
		_note_timer -= delta
		if _note_timer <= 0.0:
			_note = 0
	if _gem_chain_timer > 0.0:
		_gem_chain_timer -= delta
		if _gem_chain_timer <= 0.0:
			_gem_chain = 0


# --- cube events ---------------------------------------------------------------------

func on_cube_hit(p: Vector3, k: int) -> void:
	debris.spray(p, Defs.CUBES[k]["color"], 1, player.global_position, 0.5)
	Sfx.play("tick", -13.0, Defs.CUBES[k].get("ring", 1.0))


func on_cube_popped(p: Vector3, k: int, color: Color) -> void:
	var d: Dictionary = Defs.CUBES[k]
	cubes += 1
	combo += 1
	combo_timer = Defs.COMBO_WINDOW
	best_combo = maxi(best_combo, combo)
	_pops_this_frame += 1
	add_score(int(d["score"] * combo_mult()))
	add_xp(d["xp"])
	debris.spray(p, color.lerp(Defs.FRENZY["color"], 0.6) if frenzy_left > 0.0 else color, 5 if _pops_this_frame < 12 else 2, player.global_position)
	_play_note()
	_check_frenzy()
	if d.has("heart"):
		_break_heart(p)
	if d.has("gas"):
		traps.light_gas(p)
	if d.has("geode"):
		_burst_geode(p)
	elif d.has("gem"):
		pickups.drop_gem(p, d["gem"], d["color"])
		debris.spray(p, Color(1, 1, 0.8), 4, p, 1.3)
		Sfx.play("clink", -8.0, 1.0 + minf(combo, 60) * 0.008)
	if _pops_this_frame == Defs.WORLD["big_pop"] and _big_pop_cd <= 0.0:
		_big_pop_cd = Defs.WORLD["big_pop_every"]
		_hitstop(0.03)
		fx.shake(0.25)
		Sfx.play("thud", -6.0)


## Every cube of a geode throws a gem; the first one is the big moment.
func _burst_geode(p: Vector3) -> void:
	var worth: float = Defs.CUBES[Defs.GEODE]["gem"] * (1.0 + Defs.RUN["geode_band"] * mine.band_at(Vector2(p.x, p.z).length()))
	pickups.drop_gem(p, worth, Color.from_hsv(rng.randf(), 0.55, 1.0))
	debris.spray(p, Color(1, 1, 0.8), 6, p, 1.6)
	Sfx.play("clink", -6.0, 1.2 + rng.randf() * 0.6)
	if _geode_cd > 0.0:
		return
	_geode_cd = 0.6
	geodes += 1
	_hitstop(0.05)
	fx.ring(p, 4.0, Color(0.4, 1.0, 0.85, 0.9), 0.35)
	fx.shake(0.3)
	Sfx.play("reward", -5.0, 1.2, true)


func _check_frenzy() -> void:
	if frenzy_fill() < 1.0 or frenzy_left > 0.0 or _frenzy_rest > 0.0:
		return
	frenzy_left = Defs.FRENZY["time"]
	frenzies += 1
	overlay.banner("FRENZY!", "", Defs.FRENZY["color"], 0.8)
	overlay.flash(Color(1.0, 0.8, 0.2, 0.4), 0.4)
	Sfx.play("levelup", -5.0, 1.5, true)
	fx.shake(0.3)


## How close the combo is to the next Frenzy, 1 = there.
func frenzy_fill() -> float:
	return float(combo - _frenzy_base) / float(Defs.FRENZY["at"])


func on_enemy_killed(p: Vector3, t: int) -> void:
	var d := Defs.enemy_def(t)
	kills += 1
	combo += 1
	combo_timer = Defs.COMBO_WINDOW
	best_combo = maxi(best_combo, combo)
	add_score(int(d["score"] * combo_mult()))
	pickups.drop_gem(p, d["gem"], d["color"])
	_play_note()
	_check_frenzy()
	Sfx.play("kill", -10.0)
	if t == Enemies.BRUTE:
		_hitstop(0.05)
		fx.shake(0.3)
		Sfx.play("boom", -6.0)


func on_nest_woken(p: Vector3) -> void:
	fx.ring(p, 3.0, Color(1.0, 0.2, 0.15, 0.8), 0.4)
	Sfx.play("warn", -14.0, 1.6, true)


## The first hit wakes everything nearby.
func on_heart_hit() -> void:
	if _heart_woken:
		return
	_heart_woken = true
	overlay.banner("THE HEART WAKES", "", Color(1, 0.2, 0.45), 1.5)
	spawn_horde()
	_horde_timer = Defs.RUN["heart_horde"]


func _break_heart(p: Vector3) -> void:
	if left or dead:
		return
	left = true
	_hitstop(0.12)
	fx.ring(p, 14.0, Color(1, 0.3, 0.55, 0.9), 0.6)
	fx.shake(0.8)
	Sfx.play("big_boom", 0.0, 0.8, true)
	overlay.banner("HEART BROKEN!", "", Color(1, 0.3, 0.55), 2.0)
	if autotest:
		print("heart broken: t=%.0f level=%d" % [run_time, level])
	get_tree().create_timer(1.8, false, false, true).timeout.connect(_finish.bind("heart"))


func leave_by_lift() -> void:
	if left or dead:
		return
	left = true
	Sfx.play("levelup", -6.0, 1.3, true)
	overlay.banner("OUT!", "", Color(0.3, 1.0, 0.85), 1.0)
	if autotest:
		print("left by lift: t=%.0f level=%d depth=%.0f" % [run_time, level, depth])
	var tw := create_tween()
	tw.tween_property(player, "position:y", 12.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_finish.bind("lift"))


func find_relic(id: String, p: Vector3) -> void:
	var d: Dictionary = Defs.RELICS[id]
	Profile.relics[id] = true
	if d.has("unlock"):
		Profile.unlocked[d["unlock"]] = true
	relics += 1
	Profile.save()  # yours for good, however this run ends
	overlay.banner(d["name"].to_upper(), d["desc"], Color(1.0, 0.9, 0.5), 2.0)
	overlay.flash(Color(1.0, 0.9, 0.5, 0.35), 0.5)
	fx.ring(p, 6.0, Color(1.0, 0.9, 0.5, 0.9), 0.5)
	fx.shake(0.4)
	Sfx.play("levelup", -3.0, 0.8, true)


func on_evolved(title: String) -> void:
	evolutions += 1
	overlay.banner(title.to_upper(), "EVOLVED", Color(1.0, 0.4, 1.0), 1.4)


func use_shrine(id: String) -> void:
	var d: Dictionary = Defs.SHRINES[id]
	_modal_open = true
	get_tree().paused = true
	levelup_ui.open([{"kind": "shrine", "id": id, "title": d["name"], "desc": d["desc"], "hint": "", "level_text": "", "color": d["color"]},
		{"kind": "leave", "id": "", "title": "Walk away", "desc": "Leave it be.", "hint": "", "level_text": "", "color": Color(0.6, 0.6, 0.6)}], 0, func(o: Dictionary):
		if o["kind"] == "shrine":
			take_shrine(id)
		_close_modal(), "A SHRINE")


func take_shrine(id: String) -> void:
	match id:
		"blood":
			player.hp = maxf(1.0, player.hp * 0.5)
			pending_levelups += 2
		"greed":
			gem_rate *= 1.5
			greed_harm = 1.3
		"wind":
			player.base_speed *= 1.2
			base_hp *= 0.75
			apply_boosts()
			player.hp = minf(player.hp, player.max_hp)


func gas_blast(p: Vector3) -> void:
	var t := Defs.THREATS
	var r: float = t["gas_radius"]
	mine.hit_circle(p, r, 1e9, p, Defs.WORLD["blast_wave"], true)
	enemies.hit_circle(p, r, t["gas_hurts_enemies"])
	fx.ring(p, r, Color(0.9, 0.9, 0.3, 0.9), 0.3)
	fx.shake(0.35)
	Sfx.play("boom", -4.0, 1.2)
	var at := player.global_position
	if Vector2(at.x - p.x, at.z - p.z).length() < r:
		player_hit(t["gas_dmg"])


func player_hit(amount: float) -> void:
	if god_mode or dead or left or not player.hurt(amount):
		return
	hits_taken += 1
	fx.shake(0.3)
	hud.damage_flash()
	Sfx.play("hurt", -4.0)
	if player.hp <= 0.0:
		_game_over()


func _game_over() -> void:
	dead = true
	player.visible = false
	Sfx.play("big_boom", 0.0, 1.0, true)
	debris.spray(player.global_position + Vector3(0, 0.8, 0), Defs.DIGGER["color"], 30, player.global_position, 1.3)
	fx.shake(0.8)
	if autotest:
		print("died: t=%.0f level=%d depth=%.0f" % [run_time, level, depth])
	get_tree().create_timer(1.2, false, false, true).timeout.connect(_finish.bind("dead"))


## What share of the gems you carry stays yours.
func keep_share(how: String) -> float:
	return 1.0 if how == "heart" or how == "lift" else float(Defs.RUN["death_keep"]) + Profile.bonus("cover")


func gems_kept(how: String) -> int:
	return int(loot * keep_share(how)) + (int(Defs.RUN["heart_bonus"]) if how == "heart" else 0)


func _run_stats(kept: int, how: String) -> Dictionary:
	return {"runs": 1, "cubes": cubes, "kills": kills, "banked": kept, "band": band, "combo": best_combo, "geodes": geodes,
		"frenzies": frenzies, "relics": relics, "evolutions": evolutions, "lifts": 1 if how == "lift" else 0, "hearts": 1 if how == "heart" else 0}


## Goals are only paid out at the end, but you hear about them the moment you earn them.
func _announce_goals(delta: float) -> void:
	_goal_timer -= delta
	if _goal_timer > 0.0:
		return
	_goal_timer = 1.0
	var now := _run_stats(int(loot * keep_share("quit")), "")
	for g in Defs.GOALS:
		if Profile.done.has(g["id"]) or _told.has(g["id"]) or Profile.with_run(g["stat"], now[g["stat"]]) < g["need"]:
			continue
		_told[g["id"]] = true
		hud.show_hint("GOAL: %s  >  %s" % [g["text"], Defs.reward_text(g)], 4.0)
		Sfx.play("reward", -6.0, 1.3, true)


## Banks the run once, however it ended, and shows what it was worth.
func _finish(how: String) -> void:
	if banked:
		return
	banked = true
	get_tree().paused = true
	var before := Profile.stats.duplicate()
	var kept := gems_kept(how)
	Profile.gems += kept
	Profile.record(_run_stats(kept, how))
	var news := Profile.claim_goals()
	Profile.save()
	if autotest:
		print("finished: %s kept=%d carried=%d t=%.0f goals=%d" % [how, kept, int(loot), run_time, news.size()])
	var title := {"heart": "HEART BROKEN", "lift": "YOU GOT OUT", "dead": "YOU DIED", "quit": "GAVE UP"}
	results.open({"title": title[how], "color": Color(1, 0.35, 0.3) if how == "dead" else Color(1, 0.85, 0.3),
		"lines": ["%s cubes  ·  %d kills  ·  %d m deep  ·  level %d  ·  combo x%d" % [cubes, kills, int(depth), level, best_combo]],
		"carried": int(loot), "kept": kept, "share": keep_share(how), "before": before, "news": news, "bank": Profile.gems})


## Each pop plays the next note of a rising scale, so digging sounds like a run up a keyboard.
func _play_note() -> void:
	var steps := PENTATONIC.size()
	var semitone: int = PENTATONIC[_note % steps] + 12 * (_note / steps)
	Sfx.play("pop", -7.0, pow(2.0, semitone / 12.0), true)
	_note = (_note + 1) % (steps * 3)
	_note_timer = 0.4


func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = Defs.xp_to_next(level)
		pending_levelups += 1


func add_loot(amount: float) -> void:
	loot += amount * gem_rate


func add_score(amount: int) -> void:
	score += amount


func combo_mult() -> float:
	return (1.0 + minf(combo, 300) / 60.0) * (float(Defs.FRENZY["score"]) if frenzy_left > 0.0 else 1.0)


## Called once per frame in which at least one gem was collected; the chime
## climbs in pitch while pickups keep chaining.
func on_gem_collected() -> void:
	_gem_chain = mini(_gem_chain + 1, 30)
	_gem_chain_timer = 0.6
	Sfx.play("pickup", -9.0, 1.0 + _gem_chain * 0.045, true)


## Levelling up blasts the rock around you.
func level_blast() -> void:
	var at := player.global_position
	at.y = 0.0
	var r: float = Defs.WORLD["level_blast"]
	mine.hit_circle(at, r, 1e9, at, Defs.WORLD["blast_wave"], true)
	enemies.hit_circle(at, r, 60.0)
	player.hp = minf(player.max_hp, player.hp + Defs.DIGGER["level_heal"])
	fx.ring(at, r, Color(1.0, 0.9, 0.4, 0.9), 0.4)
	fx.shake(0.4)
	Sfx.play("boom", -5.0, 0.8)


## Array.shuffle() uses the global generator, so seeded code must use this instead.
func shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t


# --- modals ----------------------------------------------------------------------------

func _try_open_modal() -> void:
	if _modal_open or _paused_by_menu or dead or pending_levelups <= 0:
		return
	_modal_open = true
	get_tree().paused = true
	levelup_ui.open(tools.level_up_options(3), level - pending_levelups + 1, func(o: Dictionary):
		tools.apply(o)
		pending_levelups -= 1
		_close_modal()
		level_blast())


func _close_modal() -> void:
	_modal_open = false
	if not _paused_by_menu:
		get_tree().paused = false


func _open_pause() -> void:
	if _modal_open or _paused_by_menu or dead:
		return
	_paused_by_menu = true
	get_tree().paused = true
	_show_pause()


func _show_pause() -> void:
	overlay.show_panel("PAUSED", ["%d cubes  ·  best combo x%d" % [cubes, best_combo]], [["Resume", _resume], [Options.fog_text(), _toggle_fog], ["Give up (keep %d%% of your gems)" % roundi(keep_share("quit") * 100.0), _give_up]])


func _toggle_fog() -> void:
	Options.toggle_fog()
	apply_fog()
	_update_light(0.0)
	_show_pause()


func _resume() -> void:
	_paused_by_menu = false
	if not _modal_open:
		get_tree().paused = false


func _give_up() -> void:
	_paused_by_menu = false
	_finish("quit")


func _new_mine() -> void:
	get_tree().paused = false
	retry_requested.emit()


func _quit_to_menu() -> void:
	get_tree().paused = false
	exit_to_menu.emit()


# --- time feel and camera --------------------------------------------------------------

func _hitstop(duration: float) -> void:
	_hitstop_left = maxf(_hitstop_left, duration)


func _update_time_scale() -> void:
	var now := Time.get_ticks_usec()
	var real := clampf((now - _last_real_us) / 1000000.0, 0.0, 0.1) if _last_real_us > 0 else 0.0
	_last_real_us = now
	if _hitstop_left > 0.0:
		_hitstop_left -= real
		Engine.time_scale = 0.05 if _hitstop_left > 0.0 else base_time_scale
	elif Engine.time_scale != base_time_scale:
		Engine.time_scale = base_time_scale


## A tiny camera punch in the direction of a hit.
func kick(dir: Vector3, amount: float) -> void:
	_kick = (_kick + dir * amount).limit_length(0.2)


func _cam_targets() -> Array:
	var cam := Defs.CAMERA
	var at := player.global_position
	var look: Vector3 = at + player.velocity * cam["lead"]
	if _mouse_seen:
		var ahead := aim_point - at
		ahead.y = 0.0
		look += (ahead * cam["aim_lead"]).limit_length(cam["aim_lead_max"])
	return [look + Vector3(0, cam["up"], cam["back"]), look]


func _update_camera(delta: float) -> void:
	var t := _cam_targets()
	var k := 1.0 - exp(-10.0 * delta)
	_cam_pos = _cam_pos.lerp(t[0], k)
	_cam_look = _cam_look.lerp(t[1], k)
	_kick = _kick.lerp(Vector3.ZERO, 1.0 - exp(-16.0 * delta))
	_place_camera()


func _place_camera() -> void:
	var shake := fx.trauma * fx.trauma
	var off := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake * 0.7 + _kick
	camera.global_position = _cam_pos + off
	camera.look_at(_cam_look + off * 0.5, Vector3.UP)


# --- input -----------------------------------------------------------------------------

func _notification(what: int) -> void:
	# Android back button: toggle the pause menu instead of quitting the app.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_pause()


func _toggle_pause() -> void:
	if _paused_by_menu:
		overlay.hide_panel()
		_resume()
	else:
		_open_pause()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not character.has("no_aim"):
		_mouse_seen = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()


## Screen-relative move direction, in 8 directions.
func _move_input(delta: float) -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.0)
	if autotest:
		v = bot.steer(self, delta)
	return v
