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
	_near.clear()
	enemies.query(car, DANGER_RANGE, _near)
	for i in _near:
		var away := Vector2(car.x - enemies.pos[i].x, car.z - enemies.pos[i].z)
		var d := maxf(away.length(), 0.5)
		want += away / d * (DANGER_RANGE - d) / DANGER_RANGE * 2.0
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
