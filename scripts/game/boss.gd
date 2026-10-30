class_name Boss
extends Node3D
## Boss arena: the car circles the boss on one of three rings. Every attack is
## designed around the ring: radial bursts (find the gap or dash), ring slams
## (switch rings), sweeping beams (dash through) and summoned adds.

const ATTACKS := ["burst", "slam", "sweep", "summon"]
const BEAM_LENGTH := 17.0
const BEAM_HALF_WIDTH := 0.75

var run: Node  # Run
var idx := -1
var center := Vector3.ZERO
var stage := 1
var color := Color.WHITE
var dead := false

var _state := "idle"
var _attack := ""
var _last_attack := ""
var _timer: float = Defs.BOSS["first_attack"]
var _volleys := 0
var _gap_angle := 0.0
var _gap_placed := false
var _slam_rings: Array[int] = []
var _beam_angle := 0.0
var _beam_dir := 1.0
var _beam_left := 0.0
var _time := 0.0

var _model: Node3D
var _mats: Array[StandardMaterial3D] = []
var _base_colors: Array[Color] = []
var _eye_mat: StandardMaterial3D
var _ring_mats: Array[StandardMaterial3D] = []
var _ring_base := Color(1, 1, 1, 0.35)
var _beam_pivot: Node3D
var _beam_mat: StandardMaterial3D


func setup(p_run: Node, p_center: Vector3, biome: Dictionary, p_stage: int) -> void:
	run = p_run
	center = p_center
	stage = p_stage
	color = biome["boss_color"]
	_build_arena(biome)
	_build_model()
	_build_beam()
	idx = run.enemies.spawn(Enemies.BOSS, center, Defs.stage_hp_mult(stage) * (1.0 + Defs.BOSS["hp_stage"] * (stage - 1)))


func hp_ratio() -> float:
	if not run.enemies.is_alive(idx):
		return 0.0
	return run.enemies.hp[idx] / run.enemies.max_hp[idx]


func _build_arena(biome: Dictionary) -> void:
	var floor_mi := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = Defs.ARENA["floor_radius"]
	disk.bottom_radius = disk.top_radius + 0.3
	disk.height = 0.1
	disk.radial_segments = 48
	floor_mi.mesh = disk
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(biome["road"]).darkened(0.1)
	floor_mi.material_override = fm
	floor_mi.position = center + Vector3(0, 0.0, 0)
	add_child(floor_mi)
	for r in Player.RINGS:
		var mi := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = r - 0.12
		torus.outer_radius = r + 0.12
		torus.rings = 64
		torus.ring_segments = 4
		mi.mesh = torus
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = _ring_base
		mi.material_override = m
		mi.position = center + Vector3(0, 0.08, 0)
		mi.scale = Vector3(1, 0.2, 1)
		add_child(mi)
		_ring_mats.append(m)
	var pillar := BoxMesh.new()
	pillar.size = Vector3(1.2, 3.5, 1.2)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(biome["edge"])
	for k in 20:
		var a := TAU * k / 20.0
		var mi := MeshInstance3D.new()
		mi.mesh = pillar
		mi.material_override = pm
		mi.position = center + Vector3(cos(a), 0, sin(a)) * 18.0 + Vector3(0, 1.75, 0)
		add_child(mi)


func _build_model() -> void:
	_model = Node3D.new()
	_model.position = center
	add_child(_model)
	_part(_cyl(2.4, 2.8, 2.0), Vector3(0, 1.4, 0), color)
	_part(_box(Vector3(3.0, 1.4, 2.2)), Vector3(0, 3.4, 0), color.darkened(0.3))
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		var spike := _part(_cyl(0.0, 0.4, 2.0), Vector3(cos(a) * 1.8, 3.4, sin(a) * 1.8), Color(0.2, 0.2, 0.2))
		spike.rotation = Vector3(sin(a) * 0.9, 0, -cos(a) * 0.9)
	var eye := MeshInstance3D.new()
	eye.mesh = _box(Vector3(1.8, 0.4, 0.3))
	_eye_mat = StandardMaterial3D.new()
	_eye_mat.albedo_color = Color(1, 0.2, 0.1)
	_eye_mat.emission_enabled = true
	_eye_mat.emission = Color(1, 0.2, 0.1)
	_eye_mat.emission_energy_multiplier = 2.0
	eye.material_override = _eye_mat
	eye.position = Vector3(0, 3.5, -1.15)
	_model.add_child(eye)


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 12
	return m


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _part(mesh: Mesh, at: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	mi.material_override = m
	mi.position = at
	_model.add_child(mi)
	_mats.append(m)
	_base_colors.append(c)
	return mi


func _build_beam() -> void:
	_beam_pivot = Node3D.new()
	add_child(_beam_pivot)
	_beam_pivot.global_position = center + Vector3(0, 0.6, 0)
	var mi := MeshInstance3D.new()
	mi.mesh = _box(Vector3(BEAM_HALF_WIDTH * 2.0, 0.8, BEAM_LENGTH))
	mi.position = Vector3(0, 0, -BEAM_LENGTH * 0.5 - 1.5)
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = _beam_mat
	_beam_pivot.add_child(mi)
	_beam_pivot.visible = false


func update(delta: float) -> void:
	_time += delta
	if dead:
		return
	var enemies: Enemies = run.enemies
	var flashing: bool = enemies.is_alive(idx) and enemies.flash[idx] > 0.0
	for i in _mats.size():
		_mats[i].albedo_color = Color(1, 1, 1) if flashing else _base_colors[i]
	var player: Player = run.player
	var to_player := player.global_position - center
	_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-to_player.x, -to_player.z), 3.0 * delta)
	var squash := 1.0 + (0.06 if flashing else 0.0)
	_model.scale = Vector3(squash, 1.0 / squash, squash)
	var enraged: bool = hp_ratio() < Defs.BOSS["enrage_at"]
	_eye_mat.emission_energy_multiplier = 2.0 + (2.0 + sin(_time * 12.0) * 1.5 if enraged else 0.0)
	match _state:
		"idle":
			_timer -= delta * (Defs.BOSS["enrage_rush"] if enraged else 1.0)
			if _timer <= 0.0:
				_start_attack(enraged)
		"telegraph":
			_telegraph(delta, enraged)
		"active":
			_active(delta, enraged)


func _start_attack(enraged: bool) -> void:
	var choices := ATTACKS.duplicate()
	choices.erase(_last_attack)
	_attack = choices[randi() % choices.size()]
	_last_attack = _attack
	_state = "telegraph"
	match _attack:
		"burst":
			_timer = Defs.BOSS["burst_telegraph"]
		"slam":
			_timer = Defs.BOSS["slam_telegraph"]
			_slam_rings.clear()
			_slam_rings.append(run.player.ring_index)
			if enraged:
				var other: int = (run.player.ring_index + 1 + randi() % 2) % Player.RINGS.size()
				_slam_rings.append(other)
			Sfx.play("warn", -10.0, 1.6, true)
		"sweep":
			_timer = Defs.BOSS["sweep_telegraph"]
			_beam_dir = -run.player.circle_dir  # sweep against the car's travel so the player must dash through
			_beam_angle = run.player.theta + PI
			_beam_left = TAU * Defs.BOSS["sweep_turns"]
			_beam_pivot.visible = true
			_set_beam(_beam_angle)
			_beam_mat.albedo_color = Color(1, 0.2, 0.2, 0.25)
		"summon":
			_timer = Defs.BOSS["summon_telegraph"]


func _telegraph(delta: float, enraged: bool) -> void:
	_timer -= delta
	match _attack:
		"burst":
			var s := 1.0 + sin(_time * 30.0) * 0.05
			_model.scale = Vector3(s, s, s)
		"slam":
			var on := fmod(_time * 8.0, 1.0) < 0.5
			for r in _slam_rings:
				_ring_mats[r].albedo_color = Color(1, 0.15, 0.1, 0.95) if on else Color(1, 0.5, 0.2, 0.5)
		"sweep":
			_beam_mat.albedo_color.a = 0.15 + 0.15 * absf(sin(_time * 14.0))
	if _timer > 0.0:
		return
	_state = "active"
	match _attack:
		"burst":
			_volleys = Defs.BOSS["burst_volleys_enraged"] if enraged else Defs.BOSS["burst_volleys"]
			_gap_placed = false
			_timer = 0.0
		"slam":
			_do_slam()
		"sweep":
			_beam_mat.albedo_color = Color(1, 0.35, 0.25, 0.9)
			Sfx.play("zap", -2.0, 0.4, true)
		"summon":
			_do_summon(enraged)


func _active(delta: float, enraged: bool) -> void:
	match _attack:
		"burst":
			_timer -= delta
			if _timer <= 0.0:
				_fire_burst(enraged)
				_volleys -= 1
				_timer = Defs.BOSS["burst_interval_enraged"] if enraged else Defs.BOSS["burst_interval"]
				if _volleys <= 0:
					_end_attack()
		"sweep":
			var speed: float = Defs.BOSS["sweep_speed_enraged"] if enraged else Defs.BOSS["sweep_speed"]
			var step := speed * delta
			_beam_angle += _beam_dir * step
			_beam_left -= step
			_set_beam(_beam_angle)
			_check_beam_hit()
			if _beam_left <= 0.0:
				_beam_pivot.visible = false
				_end_attack()
		_:
			_end_attack()


func _end_attack() -> void:
	_state = "idle"
	_timer = Defs.BOSS["rest_enraged"] if hp_ratio() < Defs.BOSS["enrage_at"] else Defs.BOSS["rest"]
	for m in _ring_mats:
		m.albedo_color = _ring_base


func _fire_burst(enraged: bool) -> void:
	var b := Defs.BOSS
	var n: int = b["burst_shots_enraged"] if enraged else b["burst_shots"]
	var gap: int = b["burst_gap"]
	var spd: float = b["burst_speed_enraged"] if enraged else b["burst_speed"]
	if not _gap_placed:
		# The shots take r / spd to reach ring r, in which the car covers speed / spd radians
		# on any ring. Later gaps stay close to the first so there is always a path through.
		_gap_placed = true
		var reach: float = run.player.speed / spd * b["burst_reach"]
		_gap_angle = run.player.theta + randf_range(-reach, reach)
	else:
		_gap_angle += randf_range(-b["burst_drift"], b["burst_drift"])
	var offset: float = _gap_angle - (gap - 1) * 0.5 * TAU / n
	var dmg: float = b["burst_dmg"] * _dmg_mult()
	for k in n:
		if k < gap:
			continue
		var a := offset + TAU * k / n
		run.projectiles.enemy_shot(center + Vector3(0, 1.0, 0), Vector3(cos(a), 0, sin(a)), spd, dmg, b["burst_shot_radius"], b["burst_life"])
	Sfx.play("shot", -4.0, 0.45)
	run.fx.shake(0.08)


func _do_slam() -> void:
	var player: Player = run.player
	var dmg: float = Defs.BOSS["slam_dmg"] * _dmg_mult()
	for r in _slam_rings:
		var rr: float = Player.RINGS[r]
		for k in 12:
			var a := TAU * k / 12.0 + _time
			run.fx.burst(center + Vector3(cos(a), 0.3, sin(a)) * rr, Color(1, 0.5, 0.2), 8, 1.2)
		if absf(player.ring_radius - rr) < Defs.BOSS["slam_width"] and player.can_be_hit():
			run.player_hit(dmg)
	Sfx.play("slam", 0.0)
	run.fx.shake(0.5)
	_end_attack()


func _do_summon(enraged: bool) -> void:
	var hm := Defs.stage_hp_mult(stage)
	var n: int = Defs.BOSS["summon_count_enraged"] if enraged else Defs.BOSS["summon_count"]
	for k in n:
		var a := randf() * TAU
		run.enemies.spawn(Enemies.CRAWLER if k % 3 != 0 else Enemies.RUNNER, center + Vector3(cos(a), 0, sin(a)) * Defs.ARENA["summon_radius"], hm)
	run.fx.ring(center, 16.0, Color(0.8, 0.3, 1.0, 0.8), 0.6)
	Sfx.play("warn", -12.0, 2.0, true)
	_end_attack()


func _dmg_mult() -> float:
	return 1.0 + Defs.BOSS["dmg_stage"] * (stage - 1)


func _set_beam(angle: float) -> void:
	var dir := Vector3(cos(angle), 0, sin(angle))
	_beam_pivot.look_at(_beam_pivot.global_position + dir, Vector3.UP)


func _check_beam_hit() -> void:
	var player: Player = run.player
	var diff := wrapf(player.theta - _beam_angle, -PI, PI)
	if absf(diff) * player.ring_radius < BEAM_HALF_WIDTH + player.radius * 0.6 and player.can_be_hit():
		run.player_hit(Defs.BOSS["sweep_dmg"] * _dmg_mult())


func die() -> void:
	dead = true
	_beam_pivot.visible = false
	for m in _ring_mats:
		m.albedo_color = _ring_base
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.4, 0.1, 1.4), 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
