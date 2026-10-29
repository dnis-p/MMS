class_name Fx
extends Node3D
## Juice: pooled particle bursts, floating damage numbers, shock rings,
## lightning bolts and screen-shake trauma.

const BURSTS := 28
const NUMBERS := 40
const RINGS := 12
const BOLT_SEGMENTS := 256

var trauma := 0.0
var _bursts: Array[CPUParticles3D] = []
var _next_burst := 0
var _numbers: Array[Label3D] = []
var _number_life: Array[float] = []
var _number_vel: Array[Vector3] = []
var _next_number := 0
var _rings: Array[MeshInstance3D] = []
var _ring_life: Array[float] = []
var _ring_len: Array[float] = []
var _ring_r: Array[float] = []
var _next_ring := 0
var _bolts: MultiMesh
var _bolt_a := PackedVector3Array()
var _bolt_b := PackedVector3Array()
var _bolt_life := PackedFloat32Array()
var _bolt_color: Array[Color] = []


func _ready() -> void:
	var cube := BoxMesh.new()
	cube.size = Vector3(0.22, 0.22, 0.22)
	var part_mat := StandardMaterial3D.new()
	part_mat.vertex_color_use_as_albedo = true
	part_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cube.material = part_mat
	for i in BURSTS:
		var p := CPUParticles3D.new()
		p.emitting = false
		p.one_shot = true
		p.explosiveness = 0.95
		p.amount = 14
		p.lifetime = 0.55
		p.mesh = cube
		p.direction = Vector3.UP
		p.spread = 80.0
		p.initial_velocity_min = 4.0
		p.initial_velocity_max = 9.0
		p.gravity = Vector3(0, -22, 0)
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.4
		p.damping_min = 1.0
		p.damping_max = 3.0
		p.local_coords = false
		add_child(p)
		_bursts.append(p)
	for i in NUMBERS:
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.font_size = 64
		l.outline_size = 14
		l.pixel_size = 0.01
		l.render_priority = 10
		l.outline_render_priority = 9
		l.visible = false
		add_child(l)
		_numbers.append(l)
		_number_life.append(0.0)
		_number_vel.append(Vector3.ZERO)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 4
	for i in RINGS:
		var m := MeshInstance3D.new()
		m.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.visible = false
		add_child(m)
		_rings.append(m)
		_ring_life.append(0.0)
		_ring_len.append(1.0)
		_ring_r.append(1.0)
	var seg := BoxMesh.new()
	seg.size = Vector3(0.12, 0.12, 1.0)
	_bolts = MultiMesh.new()
	_bolts.transform_format = MultiMesh.TRANSFORM_3D
	_bolts.use_colors = true
	_bolts.mesh = seg
	_bolts.instance_count = BOLT_SEGMENTS
	_bolts.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _bolts
	var bmat := StandardMaterial3D.new()
	bmat.vertex_color_use_as_albedo = true
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmi.material_override = bmat
	mmi.custom_aabb = AABB(Vector3(-5000, -10, -5000), Vector3(10000, 40, 10000))
	add_child(mmi)


func clear() -> void:
	for l in _numbers:
		l.visible = false
	for r in _rings:
		r.visible = false
	_bolt_a.clear()
	_bolt_b.clear()
	_bolt_life.clear()
	_bolt_color.clear()
	trauma = 0.0


func burst(p: Vector3, color: Color, amount := 14, power := 1.0) -> void:
	var b := _bursts[_next_burst]
	_next_burst = (_next_burst + 1) % BURSTS
	b.global_position = p
	b.amount = amount
	b.color = color
	b.initial_velocity_min = 4.0 * power
	b.initial_velocity_max = 9.0 * power
	b.restart()


func number(p: Vector3, value: float, crit := false) -> void:
	var l := _numbers[_next_number]
	_number_life[_next_number] = 0.65
	_number_vel[_next_number] = Vector3(randf_range(-1.0, 1.0), 4.0, 0.0)
	_next_number = (_next_number + 1) % NUMBERS
	l.text = str(int(round(value))) + ("!" if crit else "")
	l.modulate = Color(1.0, 0.85, 0.2) if crit else Color(1, 1, 1)
	l.outline_modulate = Color(0.6, 0.1, 0.0) if crit else Color(0, 0, 0)
	l.font_size = 88 if crit else 60
	l.global_position = p + Vector3(randf_range(-0.3, 0.3), 1.4, 0)
	l.scale = Vector3.ONE * 1.6
	l.visible = true


func ring(p: Vector3, radius: float, color: Color, duration := 0.35) -> void:
	var m := _rings[_next_ring]
	_ring_life[_next_ring] = duration
	_ring_len[_next_ring] = duration
	_ring_r[_next_ring] = radius
	_next_ring = (_next_ring + 1) % RINGS
	(m.material_override as StandardMaterial3D).albedo_color = color
	m.global_position = p + Vector3(0, 0.25, 0)
	m.scale = Vector3.ONE * 0.2
	m.visible = true


func bolt(a: Vector3, b: Vector3, color := Color(0.6, 0.9, 1.0)) -> void:
	# Split the line into jagged pieces so it reads as lightning.
	var pieces := 4
	var prev := a
	for k in range(1, pieces + 1):
		var t := float(k) / pieces
		var next := a.lerp(b, t)
		if k < pieces:
			next += Vector3(randf_range(-0.5, 0.5), randf_range(-0.2, 0.4), randf_range(-0.5, 0.5))
		if _bolt_a.size() < BOLT_SEGMENTS:
			_bolt_a.append(prev)
			_bolt_b.append(next)
			_bolt_life.append(0.14)
			_bolt_color.append(color)
		prev = next


func shake(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


func update(delta: float) -> void:
	trauma = maxf(0.0, trauma - delta * 1.8)
	for i in NUMBERS:
		if _number_life[i] <= 0.0:
			continue
		_number_life[i] -= delta
		var l := _numbers[i]
		l.global_position += _number_vel[i] * delta
		_number_vel[i].y -= 9.0 * delta
		var s := lerpf(1.0, 1.6, clampf((_number_life[i] - 0.5) / 0.15, 0.0, 1.0))
		l.scale = Vector3.ONE * s
		l.modulate.a = clampf(_number_life[i] / 0.25, 0.0, 1.0)
		l.outline_modulate.a = l.modulate.a
		if _number_life[i] <= 0.0:
			l.visible = false
	for i in RINGS:
		if _ring_life[i] <= 0.0:
			continue
		_ring_life[i] -= delta
		var m := _rings[i]
		var t := 1.0 - _ring_life[i] / _ring_len[i]
		var r := lerpf(0.2, _ring_r[i], 1.0 - pow(1.0 - t, 3.0))
		m.scale = Vector3(r, 1.0, r)
		var mat := m.material_override as StandardMaterial3D
		mat.albedo_color.a = 1.0 - t
		if _ring_life[i] <= 0.0:
			m.visible = false
	for i in range(_bolt_life.size() - 1, -1, -1):
		_bolt_life[i] -= delta
		if _bolt_life[i] <= 0.0:
			var last := _bolt_life.size() - 1
			_bolt_a[i] = _bolt_a[last]
			_bolt_b[i] = _bolt_b[last]
			_bolt_life[i] = _bolt_life[last]
			_bolt_color[i] = _bolt_color[last]
			_bolt_a.resize(last)
			_bolt_b.resize(last)
			_bolt_life.resize(last)
			_bolt_color.resize(last)
	for i in _bolt_a.size():
		var a := _bolt_a[i]
		var b := _bolt_b[i]
		var d := b - a
		var seg_len := d.length()
		var basis := Basis.looking_at(d / seg_len, Vector3.UP) if seg_len > 0.01 and absf(d.y / seg_len) < 0.99 else Basis()
		basis = Basis(basis.x, basis.y, basis.z * maxf(seg_len, 0.01))
		_bolts.set_instance_transform(i, Transform3D(basis, (a + b) * 0.5))
		_bolts.set_instance_color(i, _bolt_color[i].lightened(_bolt_life[i] * 2.0))
	_bolts.visible_instance_count = _bolt_a.size()
