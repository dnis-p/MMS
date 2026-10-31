class_name Debris
extends Node3D
## The bits a broken cube turns into: small chips that fly, bounce on the floor and shrink away.
## A ring buffer of plain arrays, so a huge explosion just recycles the oldest chips.

const MAX := 1600
const SIZE := 0.16
const LIFE := 0.9

var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _life := PackedFloat32Array()
var _color := PackedColorArray()
var _next := 0
var _mm: MultiMesh


func _ready() -> void:
	_pos.resize(MAX)
	_vel.resize(MAX)
	_life.resize(MAX)
	_color.resize(MAX)
	var chip := BoxMesh.new()
	chip.size = Vector3.ONE * SIZE
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = chip
	_mm.instance_count = MAX
	_mm.visible_instance_count = 0
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.7
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-5000, -10, -5000), Vector3(10000, 40, 10000))
	add_child(mmi)


## Throws `n` chips up and away from `from`.
func spray(p: Vector3, color: Color, n: int, from: Vector3, power := 1.0) -> void:
	var out := p - from
	out.y = 0.0
	out = out.normalized()
	for k in n:
		var i := _next
		_next = (_next + 1) % MAX
		_pos[i] = p + Vector3(randf_range(-0.15, 0.15), 0.1, randf_range(-0.15, 0.15))
		_vel[i] = (out * randf_range(1.5, 5.0) + Vector3(randf_range(-2.5, 2.5), randf_range(4.0, 9.0), randf_range(-2.5, 2.5))) * power
		_life[i] = LIFE * randf_range(0.6, 1.2)
		_color[i] = color.lightened(randf_range(0.0, 0.25))


func update(delta: float) -> void:
	var n := 0
	for i in MAX:
		if _life[i] <= 0.0:
			continue
		_life[i] -= delta
		var v := _vel[i]
		v.y -= 30.0 * delta
		var p := _pos[i] + v * delta
		if p.y < 0.08:
			p.y = 0.08
			v = Vector3(v.x * 0.55, -v.y * 0.4, v.z * 0.55)
		_pos[i] = p
		_vel[i] = v
		var s := minf(_life[i] * 3.0, 1.0)
		_mm.set_instance_transform(n, Transform3D(Basis(Vector3(0.6, 0.6, 0.53), i + _life[i] * 9.0).scaled(Vector3(s, s, s)), p))
		_mm.set_instance_color(n, _color[i])
		n += 1
	_mm.visible_instance_count = n


func clear() -> void:
	_life.fill(0.0)
	_mm.visible_instance_count = 0
