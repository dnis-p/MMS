class_name Run
extends Node3D
## One dig: owns every subsystem and routes events between them (cube hits, pops, XP, level-ups,
## camera, input). There is no way to lose yet: this prototype is only about digging feeling good.

signal exit_to_menu
signal retry_requested

const STICK_DEADZONE := 18.0
const PENTATONIC := [0, 2, 4, 7, 9]  # any run of these notes sounds good

## All gameplay randomness comes from `rng` so a seed can reproduce a run.
var rng := RandomNumberGenerator.new()
var run_seed := 0  # 0 = pick a random one

var player: Player
var mine: Mine
var debris: Debris
var pickups: Pickups
var tools: Tools
var fx: Fx
var bot := Bot.new()
var camera: Camera3D
var hud: Hud
var levelup_ui: LevelUpUI
var overlay: Overlay

var level := 1
var xp := 0.0
var xp_next := Defs.xp_to_next(1)
var pending_levelups := 0
var cubes := 0
var score := 0
var combo := 0
var combo_timer := 0.0
var best_combo := 0
var run_time := 0.0
var depth := 0.0
var band := 0
var autotest := false
var base_time_scale := 1.0

var _modal_open := false
var _paused_by_menu := false
var _note := 0
var _note_timer := 0.0
var _gem_chain := 0
var _gem_chain_timer := 0.0
var _pops_this_frame := 0
var _cam_pos := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _kick := Vector3.ZERO
var _hitstop_left := 0.0
var _last_real_us := 0
var _stick_index := -1
var _stick_base := Vector2.ZERO
var _stick_dir := Vector2.ZERO


func _ready() -> void:
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
	debris = Debris.new()
	add_child(debris)
	pickups = Pickups.new()
	pickups.run = self
	add_child(pickups)
	fx = Fx.new()
	add_child(fx)
	player = Player.new()
	add_child(player)
	tools = Tools.new()
	tools.run = self
	add_child(tools)
	tools.add_tool("shovel")
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

	var t := _cam_targets()
	_cam_pos = t[0]
	_cam_look = t[1]
	_place_camera()
	hud.show_hint("WASD / arrows or drag to move  ·  your tools dig by themselves", 6.0)


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	Sfx.rev_stop()
	if get_tree():
		get_tree().paused = false


func apply_boosts() -> void:
	player.speed = player.base_speed * (1.0 + float(Defs.BOOSTS["legs"]["value"]) * tools.boost("legs"))
	player.pickup_radius = player.base_pickup * (1.0 + float(Defs.BOOSTS["magnet"]["value"]) * tools.boost("magnet"))


# --- main loop ---------------------------------------------------------------------

func _process(delta: float) -> void:
	_update_time_scale()
	run_time += delta
	_pops_this_frame = 0
	player.move(minf(delta, 0.05), _move_input(delta), mine)
	tools.update(delta)
	mine.update(delta)
	debris.update(delta)
	pickups.update(delta)
	fx.update(delta)
	_update_depth()
	_update_chains(delta)
	_update_camera(delta)
	hud.refresh(self)
	_try_open_modal()


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
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
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
	debris.spray(p, color, 5 if _pops_this_frame < 12 else 2, player.global_position)
	_play_note()
	if d.has("gem") and cubes % int(d.get("gem_every", 1)) == 0:
		pickups.drop_gem(p, d["gem"], d["color"])
		debris.spray(p, Color(1, 1, 0.8), 4, p, 1.3)
		Sfx.play("clink", -8.0, 1.0 + minf(combo, 60) * 0.008)
	fx.shake(0.012)
	if _pops_this_frame == Defs.WORLD["big_pop"]:
		_hitstop(0.03)
		fx.shake(0.15)
		Sfx.play("thud", -6.0)


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


func add_score(amount: int) -> void:
	score += amount


func combo_mult() -> float:
	return 1.0 + minf(combo, 300) / 60.0


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
	mine.hit_circle(at, r, 1e9, at, Defs.WORLD["blast_wave"])
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
	if _modal_open or _paused_by_menu or pending_levelups <= 0:
		return
	_modal_open = true
	_stick_reset()
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
	if _modal_open or _paused_by_menu:
		return
	_paused_by_menu = true
	_stick_reset()
	get_tree().paused = true
	overlay.show_panel("PAUSED", ["%d cubes  ·  best combo x%d" % [cubes, best_combo]], [["Resume", _resume], ["New mine", _new_mine], ["Quit to menu", _quit_to_menu]])


func _resume() -> void:
	_paused_by_menu = false
	if not _modal_open:
		get_tree().paused = false


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
	_kick += dir * amount


func _cam_targets() -> Array:
	var cam := Defs.CAMERA
	var look: Vector3 = player.global_position + player.velocity * cam["lead"]
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		return
	if not get_tree().paused:
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
