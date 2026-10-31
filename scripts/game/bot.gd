class_name Bot
extends RefCounted
## Plays for --autotest: walks to a new random spot every few seconds, digging on the way. Good enough
## to exercise the game and watch it, not a stand-in for a human.

var _target := Vector3.ZERO
var _left := 0.0


func steer(run: Run, delta: float) -> Vector2:
	_left -= delta
	var at := run.player.global_position
	if _left <= 0.0 or at.distance_to(_target) < 2.0:
		_left = 5.0
		var a := run.rng.randf() * TAU
		_target = (at + Vector3(cos(a), 0, sin(a)) * 25.0).limit_length(Mine.SIZE * Mine.CELL * 0.45)
	var to := _target - at
	return Vector2(to.x, to.z).normalized()
