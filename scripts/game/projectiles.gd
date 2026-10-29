class_name Projectiles
extends Node3D
## Player bullets/rockets/mines, burning zones and enemy shots, all stored as
## packed arrays and drawn with MultiMeshes (same approach as Enemies).

const BULLET := 0
const ROCKET := 1
const MINE := 2
const FLAG_HOMING := 1
const FLAG_NAPALM := 2
const MAX_DRAW := 512

var run: Node  # Run

var p_kind := PackedInt32Array()
var p_pos := PackedVector3Array()
var p_vel := PackedVector3Array()
var p_dmg := PackedFloat32Array()
var p_aoe := PackedFloat32Array()
var p_life := PackedFloat32Array()
var p_pierce := PackedInt32Array()
var p_last := PackedInt32Array()
var p_target := PackedInt32Array()
var p_flags := PackedInt32Array()

var e_pos := PackedVector3Array()
var e_vel := PackedVector3Array()
var e_dmg := PackedFloat32Array()
var e_life := PackedFloat32Array()
var e_rad := PackedFloat32Array()

var z_pos := PackedVector3Array()
var z_r := PackedFloat32Array()
var z_life := PackedFloat32Array()
var z_tick := PackedFloat32Array()
var z_dps := PackedFloat32Array()

var _mm_bullet: MultiMesh
var _mm_rocket: MultiMesh
var _mm_mine: MultiMesh
var _mm_orb: MultiMesh
var _mm_zone: MultiMesh
var _tmp: Array = []
var _time := 0.0


func _ready() -> void:
	var bullet := BoxMesh.new()
	bullet.size = Vector3(0.14, 0.14, 0.9)
	_mm_bullet = _make_mm(bullet, Color(1.0, 0.9, 0.4), true)
	var rocket := BoxMesh.new()
	rocket.size = Vector3(0.3, 0.3, 0.9)
	_mm_rocket = _make_mm(rocket, Color(1.0, 0.55, 0.2), true)
	var mine := CylinderMesh.new()
	mine.top_radius = 0.35
	mine.bottom_radius = 0.45
	mine.height = 0.25
	mine.radial_segments = 8
	_mm_mine = _make_mm(mine, Color(1, 1, 1), false)
	var orb := SphereMesh.new()
	orb.radius = 0.35
	orb.height = 0.7
	orb.radial_segments = 8
	orb.rings = 4
	_mm_orb = _make_mm(orb, Color(1.0, 0.3, 0.9), true)
	var zone := CylinderMesh.new()
	zone.top_radius = 1.0
	zone.bottom_radius = 1.0
	zone.height = 0.06
	zone.radial_segments = 16
	_mm_zone = _make_mm(zone, Color(1.0, 0.45, 0.1), true, 0.55)


func _make_mm(mesh: Mesh, color: Color, unshaded: bool, alpha := 1.0) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = MAX_DRAW
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(color, alpha)
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-5000, -10, -5000), Vector3(10000, 40, 10000))
	add_child(mmi)
	return mm


func clear() -> void:
	for arr in [p_kind, p_pos, p_vel, p_dmg, p_aoe, p_life, p_pierce, p_last, p_target, p_flags]:
		arr.clear()
	for arr in [e_pos, e_vel, e_dmg, e_life, e_rad, z_pos, z_r, z_life, z_tick, z_dps]:
		arr.clear()
	for mm in [_mm_bullet, _mm_rocket, _mm_mine, _mm_orb, _mm_zone]:
		mm.visible_instance_count = 0


func fire(kind: int, p: Vector3, vel: Vector3, damage: float, life: float, pierce := 0, aoe := 0.0, target := -1, flags := 0) -> void:
	if p_kind.size() >= MAX_DRAW:
		return
	p_kind.append(kind)
	p_pos.append(p)
	p_vel.append(vel)
	p_dmg.append(damage)
	p_aoe.append(aoe)
	p_life.append(life)
	p_pierce.append(pierce)
	p_last.append(-1)
	p_target.append(target)
	p_flags.append(flags)


func enemy_shot(p: Vector3, dir: Vector3, spd: float, damage: float, rad := 0.35, life := 4.0) -> void:
	if e_pos.size() >= MAX_DRAW:
		return
	e_pos.append(p)
	e_vel.append(dir.normalized() * spd)
	e_dmg.append(damage)
	e_life.append(life)
	e_rad.append(rad)


func add_zone(p: Vector3, r: float, dps: float, life: float) -> void:
	if z_pos.size() >= 64:
		return
	z_pos.append(p)
	z_r.append(r)
	z_life.append(life)
	z_tick.append(0.0)
	z_dps.append(dps)


func clear_enemy_shots() -> void:
	for arr in [e_pos, e_vel, e_dmg, e_life, e_rad]:
		arr.clear()


func update(delta: float) -> void:
	_time += delta
	var enemies: Enemies = run.enemies
	for i in range(p_kind.size() - 1, -1, -1):
		var kind := p_kind[i]
		p_life[i] -= delta
		if kind == MINE:
			var armed := p_life[i] < 8.6
			var trigger := p_life[i] <= 0.0
			if armed and not trigger:
				_tmp.clear()
				enemies.query(p_pos[i], 1.3, _tmp)
				trigger = not _tmp.is_empty()
			if trigger:
				run.explode(p_pos[i], p_aoe[i], p_dmg[i], (p_flags[i] & FLAG_NAPALM) != 0)
				_p_remove(i)
			continue
		if kind == ROCKET and (p_flags[i] & FLAG_HOMING) != 0:
			var tgt := p_target[i]
			if not enemies.is_alive(tgt):
				tgt = enemies.nearest(p_pos[i], 22.0)
				p_target[i] = tgt
			if tgt >= 0:
				var spd := p_vel[i].length()
				var want := (enemies.pos[tgt] + Vector3(0, 0.6, 0) - p_pos[i]).normalized() * spd
				p_vel[i] = p_vel[i].lerp(want, minf(1.0, 7.0 * delta)).normalized() * spd
		p_pos[i] += p_vel[i] * delta
		if p_life[i] <= 0.0:
			if kind == ROCKET:
				run.explode(p_pos[i], p_aoe[i], p_dmg[i], false)
			_p_remove(i)
			continue
		_tmp.clear()
		enemies.query(p_pos[i], 0.3 if kind == BULLET else 0.45, _tmp)
		for j in _tmp:
			if j == p_last[i]:
				continue
			if kind == ROCKET:
				run.explode(p_pos[i], p_aoe[i], p_dmg[i], false)
				_p_remove(i)
				break
			run.hit_enemy(j, p_dmg[i], p_vel[i].normalized(), 3.0)
			p_last[i] = j
			p_pierce[i] -= 1
			if p_pierce[i] < 0:
				_p_remove(i)
				break
	_update_enemy_shots(delta)
	_update_zones(delta)
	_render()


func _update_enemy_shots(delta: float) -> void:
	var player: Player = run.player
	var car := player.global_position
	for i in range(e_pos.size() - 1, -1, -1):
		e_life[i] -= delta
		e_pos[i] += e_vel[i] * delta
		var diff := e_pos[i] - car
		var rr := e_rad[i] + player.radius
		if diff.x * diff.x + diff.z * diff.z < rr * rr and player.can_be_hit():
			run.player_hit(e_dmg[i])
			e_life[i] = 0.0
		if e_life[i] <= 0.0:
			_e_remove(i)


func _update_zones(delta: float) -> void:
	for i in range(z_pos.size() - 1, -1, -1):
		z_life[i] -= delta
		z_tick[i] -= delta
		if z_tick[i] <= 0.0:
			z_tick[i] = 0.3
			_tmp.clear()
			run.enemies.query(z_pos[i], z_r[i], _tmp)
			for j in _tmp:
				run.hit_enemy(j, z_dps[i] * 0.3, Vector3.ZERO, 0.0, false)
		if z_life[i] <= 0.0:
			for arr in [z_pos, z_r, z_life, z_tick, z_dps]:
				_swap_remove(arr, i)


func _p_remove(i: int) -> void:
	for arr in [p_kind, p_pos, p_vel, p_dmg, p_aoe, p_life, p_pierce, p_last, p_target, p_flags]:
		_swap_remove(arr, i)


func _e_remove(i: int) -> void:
	for arr in [e_pos, e_vel, e_dmg, e_life, e_rad]:
		_swap_remove(arr, i)


## Packed arrays are shared by reference in Godot 4, so this edits the member in place.
func _swap_remove(arr, i: int) -> void:
	var last: int = arr.size() - 1
	if i != last:
		arr[i] = arr[last]
	arr.resize(last)


func _render() -> void:
	var nb := 0
	var nr := 0
	var nm := 0
	for i in p_kind.size():
		var kind := p_kind[i]
		if kind == MINE:
			var blink := 1.0 if fmod(_time * (8.0 if p_life[i] < 2.0 else 3.0), 1.0) < 0.5 else 0.35
			_mm_mine.set_instance_transform(nm, Transform3D(Basis(), p_pos[i] + Vector3(0, 0.12, 0)))
			_mm_mine.set_instance_color(nm, Color(1.0, 0.2 * blink, 0.15 * blink))
			nm += 1
			continue
		var dir := p_vel[i].normalized()
		var basis := Basis.looking_at(dir, Vector3.UP) if absf(dir.y) < 0.99 else Basis()
		if kind == BULLET:
			_mm_bullet.set_instance_transform(nb, Transform3D(basis, p_pos[i]))
			_mm_bullet.set_instance_color(nb, Color(1, 1, 1))
			nb += 1
		else:
			_mm_rocket.set_instance_transform(nr, Transform3D(basis, p_pos[i]))
			_mm_rocket.set_instance_color(nr, Color(1, 1, 1))
			nr += 1
	_mm_bullet.visible_instance_count = nb
	_mm_rocket.visible_instance_count = nr
	_mm_mine.visible_instance_count = nm
	for i in e_pos.size():
		var s := e_rad[i] / 0.35 * (1.0 + 0.15 * sin(_time * 20.0 + i))
		_mm_orb.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), e_pos[i]))
		_mm_orb.set_instance_color(i, Color(1, 1, 1))
	_mm_orb.visible_instance_count = e_pos.size()
	for i in z_pos.size():
		var r := z_r[i] * (1.0 + 0.06 * sin(_time * 9.0 + i))
		_mm_zone.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(r, 1, r)), z_pos[i] + Vector3(0, 0.05, 0)))
		_mm_zone.set_instance_color(i, Color(1, 1, 1, clampf(z_life[i], 0.0, 1.0)))
	_mm_zone.visible_instance_count = z_pos.size()
