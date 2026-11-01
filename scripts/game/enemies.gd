class_name Enemies
extends Node3D
## Enemies are plain data in packed arrays, drawn with one MultiMesh per type, like the cubes. Most
## sleep in nests until you can see them; then the whole nest wakes and comes for you, stopped by
## rock like you are. Burrowers and the swarm dig their way through it. Awake enemies in the dark show
## only their eyes.

const MAX := 1500
const SLEEPERS := 640  # nests stop filling here, so the swarm and hordes always have room
const CELL := 1.5
const CRAWLER := 0
const BRUTE := 1
const BURROWER := 2
const RUNNER := 3
const DRAW_RANGE := 32.0
const FORGET_RANGE := 70.0

var run: Run

var used := 0
var alive_count := 0
var awake_count := 0
var alive := PackedByteArray()
var awake := PackedByteArray()
var digs := PackedByteArray()  # goes through rock instead of being stopped by it
var etype := PackedInt32Array()
var nest := PackedInt32Array()  # -1 = on its own
var pos := PackedVector3Array()
var hp := PackedFloat32Array()
var speed := PackedFloat32Array()
var radius := PackedFloat32Array()
var dmg := PackedFloat32Array()
var flash := PackedFloat32Array()
var knock := PackedVector3Array()
var yaw := PackedFloat32Array()
var _free: Array[int] = []
var _grid := {}
var _mm: Array[MultiMesh] = []
var _eyes: MultiMesh
var _colors: Array[Color] = []
var _wake_left := 0.0
var _carve_left := 0.0
var _frame := 0
var _time := 0.0
var _q_time := PackedFloat32Array()
var _q_slot := PackedInt32Array()
var _q_dmg := PackedFloat32Array()


func _ready() -> void:
	for arr in [alive, awake, digs, etype, nest, pos, hp, speed, radius, dmg, flash, knock, yaw]:
		arr.resize(MAX)
	for id in Defs.ENEMY_ORDER:
		_colors.append(Defs.ENEMIES[id]["color"])
	var crawler := SphereMesh.new()
	crawler.radius = 0.5
	crawler.height = 0.7
	crawler.radial_segments = 8
	crawler.rings = 4
	var brute := BoxMesh.new()
	var burrower := PrismMesh.new()
	burrower.size = Vector3(0.9, 0.7, 1.0)
	var runner := SphereMesh.new()
	runner.radius = 0.5
	runner.height = 0.55
	runner.radial_segments = 6
	runner.rings = 3
	for mesh in [crawler, brute, burrower, runner]:
		_mm.append(_make_mm(mesh, false))
	var eye := SphereMesh.new()
	eye.radius = 0.09
	eye.height = 0.18
	eye.radial_segments = 6
	eye.rings = 3
	_eyes = _make_mm(eye, true)


func _make_mm(mesh: Mesh, glow: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = MAX * 2 if glow else MAX
	mm.visible_instance_count = 0
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	if glow:  # eyes show through the fog
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.no_depth_test = true
		mat.render_priority = 6
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-5000, -10, -5000), Vector3(10000, 40, 10000))
	add_child(mmi)
	return mm


func clear() -> void:
	for i in used:
		alive[i] = 0
	used = 0
	alive_count = 0
	_free.clear()
	_q_time.clear()
	_q_slot.clear()
	_q_dmg.clear()


func spawn(type_id: int, p: Vector3, nest_id := -1, is_awake := false, digger := false) -> int:
	var i: int
	if not _free.is_empty():
		i = _free.pop_back()
	elif used < MAX:
		i = used
		used += 1
	else:
		return -1
	alive[i] = 1
	awake[i] = 1 if is_awake else 0
	digs[i] = 1 if digger or type_id == BURROWER else 0
	etype[i] = type_id
	nest[i] = nest_id
	pos[i] = Vector3(p.x, 0.0, p.z)
	radius[i] = Defs.enemy_def(type_id)["radius"]
	_scale_up(i)
	flash[i] = 0.0
	knock[i] = Vector3.ZERO
	yaw[i] = run.rng.randf() * TAU
	alive_count += 1
	return i


## Fills every nest in the mine with sleepers; deeper nests hold more, and brutes.
func fill_nests() -> void:
	var t := Defs.THREATS
	for n in run.mine.nests.size():
		var c: Vector3 = run.mine.nests[n][0]
		var r: float = run.mine.nests[n][1]
		var band := run.mine.band_at(Vector2(c.x, c.z).length())
		var count: int = t["nest_size"] + t["nest_band"] * band
		for k in count:
			if used >= SLEEPERS:
				return
			var a := run.rng.randf() * TAU
			var at := c + Vector3(cos(a), 0, sin(a)) * r * 0.7 * sqrt(run.rng.randf())
			spawn(BRUTE if k == 0 and band >= t["brutes_from"] else CRAWLER, at, n)


## Sets its stats from how deep it is and how strong you are right now.
func _scale_up(i: int) -> void:
	var d: Dictionary = Defs.enemy_def(etype[i])
	var t := Defs.THREATS
	var band := run.mine.band_at(Vector2(pos[i].x, pos[i].z).length())
	hp[i] = d["hp"] * (1.0 + t["hp_band"] * band) * run.hardness
	speed[i] = d["speed"] * run.pace * run.rng.randf_range(0.9, 1.1)
	dmg[i] = d["dmg"] * (1.0 + t["dmg_band"] * band) * run.harm


func is_alive(i: int) -> bool:
	return i >= 0 and i < used and alive[i] == 1


# --- moving ------------------------------------------------------------------------

func update(delta: float, at: Vector3, player_radius: float) -> void:
	_time += delta
	_frame += 1
	_rebuild_grid()
	_run_queue(delta)
	var mine := run.mine
	var t := Defs.THREATS
	var decay: float = t["knock_decay"]
	_wake_left -= delta
	var look := _wake_left <= 0.0
	if look:
		_wake_left = t["wake_every"]
	_carve_left -= delta
	var carve := _carve_left <= 0.0
	if carve:
		_carve_left = t["carve_every"]
	var up := 0
	for i in used:
		if alive[i] == 0:
			continue
		if flash[i] > 0.0:
			flash[i] -= delta
		var p := pos[i]
		var to := at - p
		to.y = 0.0
		var d := to.length()
		if awake[i] == 0:
			if look and (mine.has_seen_at(p) if Options.fog else d < t["wake_range"]):
				_wake_nest(i)
			continue
		if d > FORGET_RANGE:
			remove(i)
			continue
		up += 1
		var dir := to / d if d > 0.001 else Vector3.ZERO
		var v := dir * speed[i] * (1.0 - clampf(knock[i].length() * 0.2, 0.0, 0.8))
		if knock[i] != Vector3.ZERO:
			v += knock[i]
			knock[i] = knock[i].move_toward(Vector3.ZERO, decay * delta)
		p += (v + _separation(i, p)) * delta
		if digs[i] == 1:
			if carve:
				mine.carve(p, radius[i] + 0.2)
		elif (i + _frame) & 1 == 0:
			p = mine.resolve(p, radius[i])
		p.y = 0.0
		pos[i] = p
		if d > 0.001:
			yaw[i] = atan2(dir.x, dir.z)
		if d < radius[i] + player_radius:
			run.player_hit(dmg[i])
	awake_count = up
	_render(at)


func _wake_nest(i: int) -> void:
	var n := nest[i]
	if n < 0:
		awake[i] = 1
		return
	for j in used:
		if alive[j] == 1 and nest[j] == n and awake[j] == 0:
			awake[j] = 1
			var left := hp[j] / _full_hp(j)  # a sleeper you already hit stays hurt
			_scale_up(j)
			hp[j] *= left
	run.on_nest_woken(pos[i])


## What a sleeper's health was when it was put in the nest, at the start of the run.
func _full_hp(i: int) -> float:
	var band := run.mine.band_at(Vector2(pos[i].x, pos[i].z).length())
	return Defs.enemy_def(etype[i])["hp"] * (1.0 + Defs.THREATS["hp_band"] * band)


func _separation(i: int, p: Vector3) -> Vector3:
	var cell: Array = _grid.get(Vector2i(floori(p.x / CELL), floori(p.z / CELL)), [])
	var push := Vector3.ZERO
	var checks := 0
	var ri := radius[i]
	for j in cell:
		if j == i:
			continue
		var diff := p - pos[j]
		var min_d := ri + radius[j]
		var d2 := diff.x * diff.x + diff.z * diff.z
		if d2 < min_d * min_d and d2 > 0.0001:
			var dd := sqrt(d2)
			push += diff / dd * (min_d - dd) * 6.0 * (radius[j] / ri)  # heavier ones shove lighter ones
		checks += 1
		if checks >= 5:
			break
	return push


func _rebuild_grid() -> void:
	_grid.clear()
	for i in used:
		if alive[i] == 0 or awake[i] == 0:
			continue
		var key := Vector2i(floori(pos[i].x / CELL), floori(pos[i].z / CELL))
		var cell = _grid.get(key)
		if cell == null:
			_grid[key] = [i]
		else:
			cell.append(i)


# --- getting hit -----------------------------------------------------------------------

func hit(i: int, amount: float, from: Vector3) -> void:
	if not is_alive(i):
		return
	var was_asleep := awake[i] == 0
	hp[i] -= amount
	flash[i] = 0.09
	var away := pos[i] - from
	away.y = 0.0
	knock[i] = (knock[i] + away.normalized() * Defs.THREATS["knock"] * float(Defs.enemy_def(etype[i])["knock"]) * run.nudge).limit_length(Defs.THREATS["knock_max"])
	run.debris.spray(pos[i] + Vector3(0, 0.3, 0), _colors[etype[i]], 2, from, 0.6)
	Sfx.play("hit", -12.0)
	if hp[i] <= 0.0:
		_die(i)
	elif was_asleep:
		_wake_nest(i)


func _die(i: int) -> void:
	var p := pos[i] + Vector3(0, 0.3, 0)
	var t := etype[i]
	var was_awake := awake[i] == 1
	var n := nest[i]
	remove(i)
	run.debris.spray(p, _colors[t], 14 if t == BRUTE else 8, p, 1.1)
	run.on_enemy_killed(p, t)
	if not was_awake and n >= 0:
		for j in used:
			if alive[j] == 1 and nest[j] == n:
				_wake_nest(j)
				break


func remove(i: int) -> void:
	if alive[i] == 0:
		return
	alive[i] = 0
	alive_count -= 1
	_free.append(i)


func _strike(i: int, amount: float, delay: float) -> void:
	_q_time.append(delay)
	_q_slot.append(i)
	_q_dmg.append(amount)


func _run_queue(delta: float) -> void:
	for k in range(_q_time.size() - 1, -1, -1):
		_q_time[k] -= delta
		if _q_time[k] > 0.0:
			continue
		var i := _q_slot[k]
		var amount := _q_dmg[k]
		var last := _q_time.size() - 1
		_q_time[k] = _q_time[last]
		_q_slot[k] = _q_slot[last]
		_q_dmg[k] = _q_dmg[last]
		_q_time.resize(last)
		_q_slot.resize(last)
		_q_dmg.resize(last)
		if is_alive(i):
			hit(i, amount, run.player.global_position)


func _in_circle(i: int, center: Vector3, r: float) -> bool:
	var rr := r + radius[i]
	var dx := pos[i].x - center.x
	var dz := pos[i].z - center.z
	return dx * dx + dz * dz <= rr * rr


func hit_circle(center: Vector3, r: float, amount: float) -> int:
	var count := 0
	for i in used:
		if alive[i] == 1 and _in_circle(i, center, r):
			count += 1
			hit(i, amount, center)
	return count


## Hits each enemy in a Fx ring as the ring reaches it.
func hit_ring(center: Vector3, r: float, amount: float, duration: float) -> int:
	var count := 0
	for i in used:
		if alive[i] == 1 and _in_circle(i, center, r):
			count += 1
			var d := Vector2(pos[i].x - center.x, pos[i].z - center.z).length()
			_strike(i, amount, Fx.ring_arrival(d, r, duration))
	return count


func _in_arc(i: int, from: Vector3, dir: Vector3, r: float, limit: float) -> bool:
	var dx := pos[i].x - from.x
	var dz := pos[i].z - from.z
	var d := sqrt(dx * dx + dz * dz)
	return d <= r + radius[i] and (d < radius[i] + 0.3 or dx * dir.x + dz * dir.z >= limit * d)


func arc_has_enemies(from: Vector3, dir: Vector3, r: float, half_angle: float) -> bool:
	var limit := cos(half_angle)
	for i in used:
		if alive[i] == 1 and _in_arc(i, from, dir, r, limit):
			return true
	return false


func hit_arc(from: Vector3, dir: Vector3, r: float, half_angle: float, amount: float) -> int:
	var count := 0
	var limit := cos(half_angle)
	for i in used:
		if alive[i] == 1 and _in_arc(i, from, dir, r, limit):
			count += 1
			hit(i, amount, from)
	return count


func hit_line(from: Vector3, dir: Vector3, length: float, half_width: float, amount: float) -> int:
	var count := 0
	for i in used:
		if alive[i] == 0:
			continue
		var diff := pos[i] - from
		diff.y = 0.0
		var along := diff.dot(dir)
		if along >= 0.0 and along <= length and absf(diff.dot(Vector3(-dir.z, 0, dir.x))) <= half_width + radius[i]:
			count += 1
			hit(i, amount, from)
	return count


## The closest enemy awake within `r`, or -1.
func nearest_awake(center: Vector3, r: float) -> int:
	var best := -1
	var best_d := r * r
	for i in used:
		if alive[i] == 1 and awake[i] == 1:
			var d2 := center.distance_squared_to(pos[i])
			if d2 < best_d:
				best_d = d2
				best = i
	return best


# --- drawing ---------------------------------------------------------------------------

func _render(at: Vector3) -> void:
	var counts := [0, 0, 0, 0]
	var eyes := 0
	var far := DRAW_RANGE * DRAW_RANGE
	var white := Color(1, 1, 1)
	var red := Color(1.0, 0.1, 0.05)
	for i in used:
		if alive[i] == 0:
			continue
		var p := pos[i]
		if at.distance_squared_to(p) > far:
			continue
		var t := etype[i]
		var s := radius[i] * 2.0
		var lift := 0.35 * s if t != BRUTE else 0.5 * s
		var seen := run.mine.can_see_at(p)
		if seen:
			var bob := absf(sin(_time * 11.0 + i)) * 0.12 if awake[i] == 1 else 0.0
			var form := Basis(Vector3.UP, yaw[i]).scaled(Vector3(s, s, s))
			if flash[i] > 0.0:
				form = form.scaled(Vector3(1.2, 0.8, 1.2))
			var k: int = counts[t]
			_mm[t].set_instance_transform(k, Transform3D(form, Vector3(p.x, lift + bob, p.z)))
			_mm[t].set_instance_color(k, white if flash[i] > 0.0 else _colors[t])
			counts[t] = k + 1
		if awake[i] == 1 and (seen or etype[i] != BRUTE or fmod(_time, 1.0) < 0.9):
			var face := Vector3(sin(yaw[i]), 0.0, cos(yaw[i]))
			var side := Vector3(face.z, 0.0, -face.x) * s * 0.2
			var eye := Vector3(p.x, lift + s * 0.2, p.z) + face * s * 0.42
			for sign in [-1.0, 1.0]:
				_eyes.set_instance_transform(eyes, Transform3D(Basis.IDENTITY, eye + side * sign))
				_eyes.set_instance_color(eyes, red)
				eyes += 1
	for t in _mm.size():
		_mm[t].visible_instance_count = counts[t]
	_eyes.visible_instance_count = eyes
