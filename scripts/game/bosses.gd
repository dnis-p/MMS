class_name Bosses
extends Node3D
## Guardians that come for you on a timer, as in VS, and seal the Heart until they are dead. Each one
## is a big enemy from the Enemies pool, so every tool hits it the usual way; this adds its routine on
## top. Numbers are in Defs.BOSSES.

var run: Run
var killed := 0
var current := -1  # its slot in Enemies, -1 = none out

var _next_at: float = Defs.BOSSES[0]["at"]
var _timer := 0.0
var _state := "chase"
var _dir := Vector3.ZERO
var _speed := 0.0
var _flicker := 0.0


func left() -> int:
	return Defs.BOSSES.size() - killed


## What the health bar shows: [name, share left], or nothing when no fight is on.
func fight() -> Array:
	if current >= 0:
		return [Defs.BOSSES[killed]["name"], run.enemies.hp[current] / run.enemies.full[current]]
	if run.heart_woken:
		return ["THE HEART", run.mine.heart_left]
	return []


func update(delta: float, at: Vector3) -> void:
	if current < 0:
		if left() > 0 and run.run_time >= _next_at:
			_arrive(at)
		return
	var e := run.enemies
	var to := at - e.pos[current]
	to.y = 0.0
	if to.length() > float(Defs.RUN["boss_leash"]):
		var back := run.offscreen(at, atan2(-to.z, -to.x), 0.0, float(Defs.RUN["boss_range"]))
		e.pos[current] = back if back != Vector3.INF else at - to.normalized() * float(Defs.RUN["boss_range"])
	_timer -= delta
	if Defs.BOSSES[killed]["enemy"] == "borer":
		_borer(delta, to)
	elif _timer <= 0.0:
		_brood(at, delta)


func _arrive(at: Vector3) -> void:
	var b: Dictionary = Defs.BOSSES[killed]
	var p := Vector3.INF
	for tries in 8:
		if p == Vector3.INF:
			p = run.offscreen(at, run.rng.randf() * TAU, 0.0, float(Defs.RUN["boss_range"]))
	if p == Vector3.INF:  # hemmed in by the mine's edge
		_next_at = run.run_time + 1.0
		return
	current = run.enemies.spawn(Defs.ENEMY_ORDER.find(b["enemy"]), p, -1, true, true)
	if current < 0:  # the pool is full: try again in a moment
		_next_at = run.run_time + 1.0
		return
	var d: Dictionary = Defs.ENEMIES[b["enemy"]]
	run.enemies.hp[current] = d["hp"] * run.hardness  # the mine's depth doesn't count: you meet it wherever you are
	run.enemies.full[current] = run.enemies.hp[current]
	run.enemies.dmg[current] = d["dmg"] * run.harm
	_speed = run.enemies.speed[current]
	_state = "chase"
	_timer = b["every"]
	run.overlay.banner(b["name"], "", Color(1, 0.3, 0.25), 2.0)
	run.overlay.flash(Color(1, 0.2, 0.1, 0.25), 0.5)
	run.fx.shake(0.5)
	Sfx.play("warn", -3.0, 0.7, true)
	if run.autotest:
		print("boss: %s t=%.0f level=%d hp=%.0f" % [b["name"], run.run_time, run.level, run.enemies.hp[current]])


## Stops, marks the line, then charges down it. Sidestep and it hits nothing.
func _borer(delta: float, to: Vector3) -> void:
	var b: Dictionary = Defs.BOSSES[0]
	var e := run.enemies
	match _state:
		"chase":
			if _timer <= 0.0:
				_state = "aim"
				_timer = Defs.restart(_timer, b["aim"], delta)
				_dir = to.normalized()
				e.speed[current] = 0.0
				Sfx.play("warn", -8.0, 1.4, true)
		"aim":
			_flicker -= delta
			if _flicker <= 0.0:
				_flicker = Defs.restart(_flicker, 0.1, delta)
				var from: Vector3 = e.pos[current] + Vector3(0, 0.8, 0)
				run.fx.bolt(from, from + _dir * float(b["charge"]) * float(b["charge_time"]), Color(1.0, 0.25, 0.1))
			if _timer <= 0.0:
				_state = "charge"
				_timer = Defs.restart(_timer, b["charge_time"], delta)
				Sfx.play("boom", -6.0, 0.7)
		"charge":
			e.pos[current] = run.mine.clamp_inside(e.pos[current] + _dir * float(b["charge"]) * delta)
			run.mine.carve(e.pos[current], e.radius[current] + 0.4)
			run.fx.shake(0.15)
			if _timer <= 0.0:
				_state = "chase"
				_timer = Defs.restart(_timer, b["every"], delta)
				e.speed[current] = _speed


## Throws gas bombs at you, and drops crawlers around itself.
func _brood(at: Vector3, delta: float) -> void:
	var b: Dictionary = Defs.BOSSES[1]
	var e := run.enemies
	_timer = Defs.restart(_timer, b["every"], delta)
	for k in b["lob"]:
		var a := run.rng.randf() * TAU
		run.traps.light_gas(at + Vector3(cos(a), 0, sin(a)) * (0.0 if k == 0 else run.rng.randf_range(3.0, 7.0)))
	var n: int = b["brood"]
	for k in n:
		var a := TAU * k / n
		e.spawn(Enemies.CRAWLER, e.pos[current] + Vector3(cos(a), 0, sin(a)) * (e.radius[current] + 1.0), -1, true, true)
	run.fx.ring(e.pos[current], 5.0, Color(0.9, 0.3, 0.7, 0.8), 0.4)
	Sfx.play("warn", -10.0, 0.9, true)


func on_killed(p: Vector3) -> void:
	var r := Defs.RUN
	var b: Dictionary = Defs.BOSSES[killed]
	var color: Color = Defs.ENEMIES[b["enemy"]]["color"]
	killed += 1
	current = -1
	if left() > 0:
		_next_at = maxf(Defs.BOSSES[killed]["at"], run.run_time + float(r["boss_gap"]))
	for k in r["boss_gems"]:
		var a := run.rng.randf() * TAU
		run.pickups.drop_gem(p + Vector3(cos(a), 0, sin(a)) * run.rng.randf_range(0.5, 3.0), r["boss_gem"], color.lerp(Color.WHITE, 0.4))
	run.pending_levelups += r["boss_levels"]
	run.boss_down(p, "THE HEART IS OPEN" if left() == 0 else "")
