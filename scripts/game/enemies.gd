class_name Enemies
extends Node3D
## Horde storage. Enemies are plain data in packed arrays (no nodes, no physics)
## and are drawn with one MultiMesh per type, which keeps hundreds of enemies
## cheap on phones. A uniform grid answers "who is near this point?".

const MAX := 700
const CELL := 3.0
const CRAWLER := 0
const RUNNER := 1
const SPITTER := 2
const BRUTE := 3
const BOSS := 4
const DESPAWN_DIST := 62.0

var run: Node  # Run

var used := 0  # high-water mark of slots
var alive_count := 0
var alive := PackedByteArray()
var etype := PackedInt32Array()
var pos := PackedVector3Array()
var hp := PackedFloat32Array()
var max_hp := PackedFloat32Array()
var speed := PackedFloat32Array()
var radius := PackedFloat32Array()
var dmg := PackedFloat32Array()
var flash := PackedFloat32Array()
var knock := PackedVector3Array()
var saw_cd := PackedFloat32Array()
var ram_cd := PackedFloat32Array()
var attack_cd := PackedFloat32Array()
var yaw := PackedFloat32Array()
var _free: Array[int] = []
var _grid := {}
var _mm: Array[MultiMesh] = []
var _type_color: Array[Color] = []
var _type_scale: Array[float] = []
var _time := 0.0


func _ready() -> void:
	alive.resize(MAX)
	etype.resize(MAX)
	pos.resize(MAX)
	hp.resize(MAX)
	max_hp.resize(MAX)
	speed.resize(MAX)
	radius.resize(MAX)
	dmg.resize(MAX)
	flash.resize(MAX)
	knock.resize(MAX)
	saw_cd.resize(MAX)
	ram_cd.resize(MAX)
	attack_cd.resize(MAX)
	yaw.resize(MAX)
	for t in Defs.ENEMY_ORDER.size():
		var d := Defs.enemy_def(t)
		_type_color.append(d["color"])
		_type_scale.append(d["scale"])
	_mm.append(_make_mm(_crawler_mesh()))
	_mm.append(_make_mm(_runner_mesh()))
	_mm.append(_make_mm(_spitter_mesh()))
	_mm.append(_make_mm(_brute_mesh()))


func _make_mm(mesh: Mesh) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = MAX
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.7
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Enemies spread over a large area; skip per-frame AABB culling.
	mmi.custom_aabb = AABB(Vector3(-5000, -10, -5000), Vector3(10000, 40, 10000))
	add_child(mmi)
	return mm


func _crawler_mesh() -> Mesh:
	var m := SphereMesh.new()
	m.radius = 0.55
	m.height = 0.8
	m.radial_segments = 8
	m.rings = 4
	return m


func _runner_mesh() -> Mesh:
	var m := PrismMesh.new()
	m.size = Vector3(0.9, 0.9, 1.4)
	return m


func _spitter_mesh() -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.25
	m.bottom_radius = 0.6
	m.height = 1.5
	m.radial_segments = 8
	return m


func _brute_mesh() -> Mesh:
	var m := BoxMesh.new()
	m.size = Vector3(1.1, 1.0, 1.1)
	return m


func clear() -> void:
	for i in used:
		alive[i] = 0
	used = 0
	alive_count = 0
	_free.clear()
	_grid.clear()
	for mm in _mm:
		mm.visible_instance_count = 0


func spawn(type_id: int, p: Vector3, hp_mult := 1.0) -> int:
	var i: int
	if not _free.is_empty():
		i = _free.pop_back()
	elif used < MAX:
		i = used
		used += 1
	else:
		return -1
	var d := Defs.enemy_def(type_id)
	alive[i] = 1
	etype[i] = type_id
	pos[i] = Vector3(p.x, 0.0, p.z)
	hp[i] = d["hp"] * hp_mult
	max_hp[i] = hp[i]
	speed[i] = d["speed"] * randf_range(0.9, 1.1)
	radius[i] = d["radius"]
	dmg[i] = d["dmg"]
	flash[i] = 0.0
	knock[i] = Vector3.ZERO
	saw_cd[i] = 0.0
	ram_cd[i] = 0.0
	attack_cd[i] = randf_range(1.0, 2.5)
	yaw[i] = 0.0
	alive_count += 1
	return i


func remove(i: int) -> void:
	if alive[i] == 0:
		return
	alive[i] = 0
	alive_count -= 1
	_free.append(i)


func is_alive(i: int) -> bool:
	return i >= 0 and i < used and alive[i] == 1


func update(delta: float, car: Vector3, car_vel: Vector3, car_radius: float) -> void:
	_time += delta
	_rebuild_grid()
	for i in used:
		if alive[i] == 0:
			continue
		var t := etype[i]
		if flash[i] > 0.0:
			flash[i] -= delta
		saw_cd[i] -= delta
		ram_cd[i] -= delta
		if t == BOSS:
			continue
		var p := pos[i]
		var to := car - p
		to.y = 0.0
		var d := to.length()
		if d > DESPAWN_DIST:
			remove(i)
			continue
		var dir := to / d if d > 0.001 else Vector3.ZERO
		var v := dir * speed[i]
		if t == SPITTER:
			attack_cd[i] -= delta
			if d < 11.0:
				# Keep pace with the car at range and lob shots.
				v = car_vel * 0.95 + dir * (1.5 if d > 8.0 else -2.0)
				if attack_cd[i] <= 0.0:
					attack_cd[i] = randf_range(2.0, 2.8)
					run.projectiles.enemy_shot(p + Vector3(0, 0.8, 0), dir, 9.0, dmg[i])
		var k := knock[i]
		if k != Vector3.ZERO:
			v += k
			knock[i] = k.move_toward(Vector3.ZERO, 40.0 * delta)
		p += v * delta + _separation(i, p) * delta
		pos[i] = p
		if d > 0.001:
			yaw[i] = atan2(dir.x, dir.z)
		if d < radius[i] + car_radius:
			run.on_enemy_contact(i)
	_render()


func _separation(i: int, p: Vector3) -> Vector3:
	var key := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
	var cell: Array = _grid.get(key, [])
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
			# Heavier enemies shove lighter ones.
			push += diff / dd * (min_d - dd) * 6.0 * (radius[j] / ri)
		checks += 1
		if checks >= 5:
			break
	return push


func _rebuild_grid() -> void:
	_grid.clear()
	for i in used:
		if alive[i] == 0:
			continue
		var p := pos[i]
		var key := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
		var cell = _grid.get(key)
		if cell == null:
			_grid[key] = [i]
		else:
			cell.append(i)


## Appends alive enemies whose body overlaps the circle (center, r) to `out`.
func query(center: Vector3, r: float, out: Array) -> void:
	var reach := r + 3.0  # covers the largest enemy radius (the boss)
	var x0 := floori((center.x - reach) / CELL)
	var x1 := floori((center.x + reach) / CELL)
	var z0 := floori((center.z - reach) / CELL)
	var z1 := floori((center.z + reach) / CELL)
	for gx in range(x0, x1 + 1):
		for gz in range(z0, z1 + 1):
			var cell = _grid.get(Vector2i(gx, gz))
			if cell == null:
				continue
			for j in cell:
				if alive[j] == 0:
					continue
				var diff := pos[j] - center
				var rr := r + radius[j]
				if diff.x * diff.x + diff.z * diff.z <= rr * rr:
					out.append(j)


func nearest(center: Vector3, max_r: float, exclude := {}) -> int:
	var best := -1
	var best_d := max_r * max_r
	for i in used:
		if alive[i] == 0 or exclude.has(i):
			continue
		var diff := pos[i] - center
		var d2 := diff.x * diff.x + diff.z * diff.z - radius[i] * radius[i]
		if d2 < best_d:
			best_d = d2
			best = i
	return best


func random_in_range(center: Vector3, max_r: float) -> int:
	var picks: Array[int] = []
	var r2 := max_r * max_r
	for i in used:
		if alive[i] == 0:
			continue
		var diff := pos[i] - center
		if diff.x * diff.x + diff.z * diff.z < r2:
			picks.append(i)
	return picks[randi() % picks.size()] if not picks.is_empty() else -1


func _render() -> void:
	var counts := [0, 0, 0, 0]
	var white := Color(1, 1, 1)
	for i in used:
		if alive[i] == 0:
			continue
		var t := etype[i]
		if t >= _mm.size():
			continue
		var s := _type_scale[t]
		var p := pos[i]
		var bob := absf(sin(_time * 12.0 + i)) * 0.25 if t != BRUTE else absf(sin(_time * 5.0 + i)) * 0.15
		var lift := 0.4 * s
		if t == BRUTE:
			lift = 0.5 * s
		elif t == RUNNER:
			lift = 0.45 * s
		elif t == SPITTER:
			lift = 0.75 * s
		var basis := Basis(Vector3.UP, yaw[i]).scaled(Vector3(s, s, s))
		if flash[i] > 0.0:
			basis = basis.scaled(Vector3(1.15, 0.85, 1.15))
		var k: int = counts[t]
		_mm[t].set_instance_transform(k, Transform3D(basis, Vector3(p.x, lift + bob, p.z)))
		_mm[t].set_instance_color(k, white if flash[i] > 0.0 else _type_color[t])
		counts[t] = k + 1
	for t in _mm.size():
		_mm[t].visible_instance_count = counts[t]
