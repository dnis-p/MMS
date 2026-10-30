class_name Bot
extends RefCounted
## Plays for --autotest: kites away from nearby enemies, collects gems and crates,
## and in the boss arena uses rings and dashes. Good enough to compare classes,
## not a stand-in for a human.

const DANGER_RANGE := 11.0
const HUNT_RANGE := 25.0
const GEM_RANGE := 30.0
const WALL_RANGE := 25.0
const BEAM_DASH := 4.5

var _near: Array = []
var _time := 0.0


func steer(run: Run, delta: float) -> Vector2:
	_time += delta
	var car := run.player.global_position
	var want := Vector2(cos(_time * 0.23), sin(_time * 0.31)) * 0.25  # slow wander
	var enemies := run.enemies
	var danger := DANGER_RANGE * run.view_zoom
	_near.clear()
	enemies.query(car, danger, _near)
	for i in _near:
		if run.eat_mode and enemies.edible(i):
			continue
		var away := Vector2(car.x - enemies.pos[i].x, car.z - enemies.pos[i].z)
		var d := maxf(away.length(), 0.5)
		want += away / d * (danger - d) / danger * 2.0
	if run.eat_mode:
		want += _toward_food(run, car)
		want += _toward_alpha(run, car)
	want += _toward_pickup(run, car)
	# Saws only reach what is next to the car, so a healthy car goes to the enemies.
	if run.weapons.owned.has("saws") and run.player.hp > run.player.max_hp * 0.5:
		var t := enemies.nearest(car, HUNT_RANGE)
		if t >= 0:
			want += Vector2(enemies.pos[t].x - car.x, enemies.pos[t].z - car.z).normalized() * 2.5
	var map := run.map
	if absf(car.x) > map.half.x - WALL_RANGE:
		want.x -= signf(car.x) * 3.0
	if absf(car.z) > map.half.y - WALL_RANGE:
		want.y -= signf(car.z) * 3.0
	return want


## The closest thing it can eat, with knocked-down prey counting as much closer.
func _toward_food(run: Run, car: Vector3) -> Vector2:
	var enemies := run.enemies
	var best := -1
	var best_d := INF
	for i in enemies.used:
		if enemies.alive[i] == 1 and enemies.edible(i):
			var d2 := car.distance_squared_to(enemies.pos[i]) * (0.2 if enemies.weak[i] > 0.0 else 1.0)
			if d2 < best_d:
				best_d = d2
				best = i
	if best < 0:
		return Vector2.ZERO
	return Vector2(enemies.pos[best].x - car.x, enemies.pos[best].z - car.z).normalized() * 2.5


## Goes for the boss once Frenzy is up, or whenever it is down.
func _toward_alpha(run: Run, car: Vector3) -> Vector2:
	var e := run.enemies
	if run.alpha < 0 or (run.frenzy < 0.4 and e.weak[run.alpha] <= 0.0):
		return Vector2.ZERO
	return Vector2(e.pos[run.alpha].x - car.x, e.pos[run.alpha].z - car.z).normalized() * 5.0


## Bites the boss with Frenzy up and anything else big whenever it can. Returns what to jump at.
func jump_at(run: Run) -> int:
	if run.alpha >= 0 and run.frenzy < 0.4:
		return -1
	return run.enemies.nearest_big(run.player.global_position, run.bite_reach())


func _toward_pickup(run: Run, car: Vector3) -> Vector2:
	var best := Vector3.ZERO
	var best_d := GEM_RANGE * GEM_RANGE
	for g in run.pickups.g_pos:
		var d2 := car.distance_squared_to(g)
		if d2 < best_d:
			best_d = d2
			best = g
	var pull := 1.8
	for c in run.pickups.crates:
		best = c.global_position
		pull = 3.0
		best_d = 1.0
	if best_d >= GEM_RANGE * GEM_RANGE:
		return Vector2.ZERO
	return Vector2(best.x - car.x, best.z - car.z).normalized() * pull


func boss_turn(run: Run) -> void:
	var p := run.player
	var b := run.boss
	if not b:
		return
	if b._attack == "slam" and b._state == "telegraph" and b._slam_rings.has(p.ring_index):
		for r in Player.RINGS.size():
			if not b._slam_rings.has(r):
				run._ring(1 if r > p.ring_index else -1)
				break
	elif run.weapons.owned.has("saws") and p.ring_index > 0 and b._state == "idle":
		run._ring(-1)  # saws only reach the boss from the inner ring
	if b._state != "active":
		return
	if b._attack == "burst":
		var diff := wrapf(b._gap_angle - p.theta, -PI, PI)
		if absf(diff) > 0.15 and signf(diff) != p.circle_dir:
			_dash(run, signf(diff))
	elif b._attack == "sweep":
		var diff := wrapf(b._beam_angle - p.theta, -PI, PI)
		if absf(diff) * p.ring_radius < BEAM_DASH:
			_dash(run, signf(diff))


## `dir` is the circling direction wanted; the dash input is in screen terms.
func _dash(run: Run, dir: float) -> void:
	var p := run.player
	var tangent := Vector3(-sin(p.theta), 0, cos(p.theta))
	run._dash(dir * signf(tangent.dot(run.camera.global_transform.basis.x)))
