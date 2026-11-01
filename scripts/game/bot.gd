class_name Bot
extends RefCounted
## Plays for --autotest: walks to a new random spot every few seconds, digging on the way. Good enough
## to exercise the game and watch it, not a stand-in for a human. With --goal=heart it heads for the
## Heart, with --goal=lift it heads for the nearest lift after a while.

const AIM_RANGE := 8.0
const BACK_OFF := 2.5
const LIFT_AFTER := 120.0

var goal := ""
var _target := Vector3.ZERO
var _left := 0.0


func steer(run: Run, delta: float) -> Vector2:
	_left -= delta
	var at := run.player.global_position
	if _left <= 0.0 or at.distance_to(_target) < 2.0:
		_left = 5.0
		var a := run.rng.randf() * TAU
		_target = (at + Vector3(cos(a), 0, sin(a)) * 25.0).limit_length(Mine.SIZE * Mine.CELL * 0.45)
	var i := run.enemies.nearest_awake(at, BACK_OFF)
	if i >= 0:  # gives ground while its tools work
		var away := at - run.enemies.pos[i]
		return Vector2(away.x, away.z).normalized()
	if goal == "heart":
		_target = run.mine.heart_pos
	elif goal == "lift" and run.run_time > LIFT_AFTER:
		_target = run.sites.nearest_lift
	var to := _target - at
	if goal == "lift" and run.run_time > LIFT_AFTER and Vector2(to.x, to.z).length() < 0.8:
		return Vector2.ZERO
	return Vector2(to.x, to.z).normalized()


## Aims at whatever is closest and awake, or the way it walks.
func aim(run: Run) -> void:
	var at := run.player.global_position
	var i := run.enemies.nearest_awake(at, AIM_RANGE)
	run.player.aiming = i >= 0
	if i >= 0:
		var to := run.enemies.pos[i] - at
		to.y = 0.0
		if to.length_squared() > 0.01:
			run.player.heading = to.normalized()
