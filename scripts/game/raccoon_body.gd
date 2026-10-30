class_name RaccoonBody
extends Node3D
## The creature's placeholder model: one static low-poly body per form in Defs.EAT_FORMS,
## built from primitives. The nose is -Z and the feet stand on y = 0. Boss parts are grafted on
## at the form's anchors, so they survive evolving.

const SKIN := Color(0.68, 0.38, 0.38)
const BONE := Color(0.86, 0.8, 0.66)
const GORE := Color(0.5, 0.05, 0.08)
const EYE := Color(1.0, 0.12, 0.08)

var mats: Array[StandardMaterial3D] = []
var colors: Array[Color] = []
var _anchors := {}  # part -> [position, size]
var _by_color := {}


func build(form: int, fur: Color) -> void:
	match form:
		0: _raccoon(fur)
		1: _mangy(fur)
		2: _ghoul(fur)
		3: _were(fur)
		_: _abomination(fur)


## Bolts what a boss gave on to the body, so a run shows on the character.
func graft(part: String, color: Color) -> void:
	var at: Vector3 = _anchors[part][0]
	var s: float = _anchors[part][1]
	match part:
		"tail":
			for side in [-1.0, 1.0]:
				_spike(at + Vector3(side * 0.12, 0, -0.3) * s, at + Vector3(side * 0.55, 0.3, 1.2) * s, 0.2 * s, color)
		"jaws":
			for side in [-1.0, 1.0]:
				_spike(at + Vector3(side * 0.3, 0, 0.3) * s, at + Vector3(side * 0.42, -0.1, -0.9) * s, 0.2 * s, color)
		"spikes":
			for k in 5:
				var z: float = (0.8 - 0.4 * k) * s
				_spike(at + Vector3(0, 0, z), at + Vector3(0, 0.9 * s, z + 0.15 * s), 0.13 * s, color)
		"horns":
			for side in [-1.0, 1.0]:
				_spike(at + Vector3(side * 0.28, 0, 0) * s, at + Vector3(side * 0.6, 1.0, 0.25) * s, 0.16 * s, color)


# --- forms ---------------------------------------------------------------------

func _raccoon(fur: Color) -> void:
	var dark := fur.darkened(0.65)
	var light := fur.lightened(0.3)
	_ball(Vector3(1.1, 0.85, 1.7), Vector3(0, 0.62, 0.1), fur)
	_ball(Vector3(1.2, 0.9, 1.0), Vector3(0, 0.66, 0.6), fur)
	_ball(Vector3(0.9, 0.72, 0.85), Vector3(0, 0.85, -0.85), light)
	_ball(Vector3(0.38, 0.3, 0.55), Vector3(0, 0.72, -1.3), light)
	_ball(Vector3(0.16, 0.14, 0.16), Vector3(0, 0.78, -1.58), Color(0.04, 0.04, 0.04))
	_block(Vector3(0.95, 0.2, 0.3), Vector3(0, 0.95, -1.1), dark)  # bandit mask
	for side in [-1.0, 1.0]:
		_spike(Vector3(side * 0.3, 1.05, -0.72), Vector3(side * 0.42, 1.5, -0.65), 0.17, dark)
		_bone(Vector3(side * 0.45, 0.5, -0.4), Vector3(side * 0.45, 0.06, -0.45), 0.13, dark)
		_bone(Vector3(side * 0.48, 0.5, 0.7), Vector3(side * 0.48, 0.06, 0.65), 0.15, dark)
	_ringed_tail(Vector3(0, 0.8, 1.05), Vector3(0, 1.3, 2.5), 0.3, dark, light)
	_anchors = {"tail": [Vector3(0, 1.1, 1.8), 0.9], "jaws": [Vector3(0, 0.66, -1.35), 0.8],
		"spikes": [Vector3(0, 1.0, 0.25), 0.8], "horns": [Vector3(0, 1.15, -0.8), 0.8]}


## Reared up and hunched, knuckles on the ground. The mange shows bare skin.
func _mangy(fur: Color) -> void:
	var dark := fur.darkened(0.65)
	var light := fur.lightened(0.25)
	var hips := Vector3(0, 0.95, 0.4)
	var neck := Vector3(0, 1.8, -0.3)
	_bone(hips, neck, 0.56, fur)
	_ball(Vector3(1.4, 0.95, 1.0), Vector3(0, 1.75, -0.2), fur)
	_ball(Vector3(0.5, 0.35, 0.55), Vector3(0.35, 1.95, 0.05), SKIN)  # mange
	_ball(Vector3(0.45, 0.3, 0.5), Vector3(-0.3, 1.4, 0.45), SKIN)
	_head(Vector3(0, 2.0, -0.85), 1.0, light, dark, 0.3)
	for side in [-1.0, 1.0]:
		_leg(Vector3(side * 0.42, 0.95, 0.45), side * 0.52, 0.2, dark)
		_arm(Vector3(side * 0.7, 1.75, -0.3), Vector3(side * 0.95, 1.05, -0.3), Vector3(side * 0.78, 0.2, -0.8), 0.17, dark, 0.3)
	_ringed_tail(Vector3(0, 0.85, 0.85), Vector3(0, 0.75, 2.2), 0.27, dark, light)
	_anchors = {"tail": [Vector3(0, 0.85, 1.5), 0.9], "jaws": [Vector3(0, 1.75, -1.3), 0.9],
		"spikes": [Vector3(0, 2.05, 0.1), 0.8], "horns": [Vector3(0, 2.4, -0.8), 0.9]}


## Gaunt and tall: ribs and spine through the skin, arms too long, the jaw hanging open.
func _ghoul(fur: Color) -> void:
	var hide := fur.lerp(SKIN, 0.55)
	var dark := fur.darkened(0.6)
	var hips := Vector3(0, 1.35, 0.25)
	var neck := Vector3(0, 2.55, -0.45)
	_bone(hips, neck, 0.38, hide)
	_ball(Vector3(1.25, 0.75, 0.8), Vector3(0, 2.4, -0.3), hide)
	for k in 4:  # ribs wrap the back, where the camera sees them
		var t := 0.25 + 0.17 * k
		var c := hips.lerp(neck, t) + Vector3(0, 0.08, 0.3)
		_bone(c + Vector3(-0.42, -0.2, -0.05), c + Vector3(0, 0.08, 0.1), 0.05, BONE)
		_bone(c + Vector3(0.42, -0.2, -0.05), c + Vector3(0, 0.08, 0.1), 0.05, BONE)
	for k in 6:  # spine
		var c := hips.lerp(neck, k / 5.0) + Vector3(0, 0.3, 0.3)
		_spike(c, c + Vector3(0, 0.3, 0.2), 0.08, BONE)
	_head(Vector3(0, 2.75, -1.05), 1.0, hide, dark, 0.5)
	for side in [-1.0, 1.0]:
		_leg(Vector3(side * 0.35, 1.35, 0.3), side * 0.5, 0.14, hide)
		_arm(Vector3(side * 0.65, 2.45, -0.4), Vector3(side * 1.35, 1.5, -0.1), Vector3(side * 1.15, 0.45, -1.1), 0.12, hide, 0.6)
	var a := Vector3(0, 1.2, 0.6)
	_bone(a, a + Vector3(0, -0.5, 1.5), 0.1, hide)
	_ball(Vector3.ONE * 0.26, a + Vector3(0, -0.5, 1.5), dark)
	_anchors = {"tail": [Vector3(0, 0.9, 1.5), 0.8], "jaws": [Vector3(0, 2.4, -1.5), 1.0],
		"spikes": [Vector3(0, 2.55, 0.1), 0.8], "horns": [Vector3(0, 3.15, -1.0), 1.0]}


## The werewolf: huge chest and shoulders over a narrow waist, mane and a long snout.
func _were(fur: Color) -> void:
	var dark := fur.darkened(0.6)
	var light := fur.lightened(0.22)
	var hips := Vector3(0, 1.5, 0.3)
	_bone(hips, Vector3(0, 2.4, 0.05), 0.5, fur)
	_ball(Vector3(2.5, 1.7, 1.5), Vector3(0, 2.75, -0.15), fur)
	_ball(Vector3(1.5, 1.0, 0.7), Vector3(0, 2.6, -0.8), light)  # chest
	for k in 7:  # mane
		var a := -1.2 + 0.4 * k
		var c := Vector3(sin(a) * 0.9, 3.2 - absf(sin(a)) * 0.35, 0.05 + cos(a) * 0.3)
		_spike(c, c + Vector3(sin(a) * 0.5, 0.45, 0.65), 0.2, dark)
	_head(Vector3(0, 3.3, -1.0), 1.25, light, dark, 0.35)
	for side in [-1.0, 1.0]:
		_leg(Vector3(side * 0.5, 1.5, 0.35), side * 0.7, 0.28, dark)
		_ball(Vector3.ONE * 1.05, Vector3(side * 1.4, 3.05, -0.1), fur)
		_arm(Vector3(side * 1.45, 2.95, -0.1), Vector3(side * 1.85, 1.9, 0.0), Vector3(side * 1.6, 0.85, -0.85), 0.3, dark, 0.5)
	_ringed_tail(Vector3(0, 1.35, 0.8), Vector3(0, 1.0, 2.6), 0.4, dark, light)
	_anchors = {"tail": [Vector3(0, 1.2, 1.8), 1.3], "jaws": [Vector3(0, 2.95, -1.65), 1.25],
		"spikes": [Vector3(0, 3.35, 0.45), 1.1], "horns": [Vector3(0, 3.75, -0.95), 1.25]}


## Nothing raccoon left but the mask and the tail. Lopsided on purpose: one arm has eaten the
## rest of the body, there is one grafted arm, and tumours glow through the hump.
func _abomination(fur: Color) -> void:
	var hide := fur.lerp(SKIN, 0.3).darkened(0.15)
	var dark := fur.darkened(0.65)
	_ball(Vector3(3.2, 2.7, 2.9), Vector3(-0.1, 2.9, 0.2), hide)
	_ball(Vector3(2.0, 1.5, 1.6), Vector3(-0.7, 3.7, 0.5), fur)
	_ball(Vector3(1.6, 1.3, 1.5), Vector3(0, 1.5, 0.4), dark)
	for k in 5:  # bone plates down the back
		var z := 1.4 - 0.55 * k
		var y := 3.7 + 0.5 * sin(k * 0.9)
		_spike(Vector3(0.3, y, z), Vector3(0.4, y + 0.85, z + 0.3), 0.32, BONE)
	for at in [Vector3(1.0, 3.5, 1.0), Vector3(-1.45, 2.9, 1.0), Vector3(0.5, 2.6, 1.5)]:
		_glow_ball(Vector3.ONE * 0.55, at, Color(0.9, 0.2, 0.1))
	_head(Vector3(0, 3.0, -1.5), 1.4, hide, dark, 0.55, 5)
	# The arm that ate the body.
	var fist := Vector3(2.5, 0.85, -1.5)
	_ball(Vector3.ONE * 1.5, Vector3(1.95, 3.55, -0.1), fur)
	_bone(Vector3(1.95, 3.5, -0.1), Vector3(2.85, 2.2, -0.2), 0.62, hide)
	_bone(Vector3(2.85, 2.2, -0.2), fist, 0.78, hide)
	_ball(Vector3(1.9, 1.5, 1.9), fist, dark)
	for k in 4:
		var a := -0.9 + 0.6 * k
		_spike(fist + Vector3(sin(a) * 0.6, -0.2, -0.6), fist + Vector3(sin(a) * 1.0, -0.75, -1.5), 0.2, BONE)
	_spike(Vector3(2.8, 2.6, -0.1), Vector3(3.8, 3.0, 0.3), 0.3, BONE)
	# The other arm stayed small, and one more was grafted on behind it.
	_arm(Vector3(-1.4, 3.3, -0.2), Vector3(-1.85, 2.2, -0.1), Vector3(-1.5, 1.2, -0.9), 0.24, dark, 0.45)
	_arm(Vector3(-1.2, 3.9, 1.0), Vector3(-2.3, 4.5, 0.8), Vector3(-2.7, 3.4, -0.2), 0.16, SKIN, 0.35)
	_ball(Vector3(0.6, 0.35, 0.6), Vector3(-1.2, 3.9, 1.0), GORE)  # the seam
	for side in [-1.0, 1.0]:
		_leg(Vector3(side * 0.75, 1.5, 0.5), side * 1.0, 0.4, dark)
	_ringed_tail(Vector3(0, 1.5, 1.6), Vector3(0.3, 0.9, 3.4), 0.48, dark, fur.lightened(0.2))
	_spike(Vector3(0.3, 1.1, 3.2), Vector3(0.35, 0.8, 4.2), 0.26, BONE)
	_anchors = {"tail": [Vector3(0.2, 1.3, 2.5), 1.6], "jaws": [Vector3(0, 2.5, -2.3), 1.5],
		"spikes": [Vector3(-0.8, 4.3, 0.3), 1.2], "horns": [Vector3(0, 3.55, -1.4), 1.5]}


# --- body parts ----------------------------------------------------------------

## Head, bandit mask, ears, eyes and a snout. `gape`: how far the jaw hangs open.
func _head(at: Vector3, s: float, hide: Color, dark: Color, gape: float, eyes := 2) -> void:
	_ball(Vector3(0.95, 0.75, 0.9) * s, at, hide)
	_block(Vector3(1.0, 0.2, 0.32) * s, at + Vector3(0, 0.12, -0.3) * s, dark)  # mask
	_ball(Vector3(0.5, 0.3, 0.75) * s, at + Vector3(0, 0.0, -0.6) * s, hide)  # upper snout
	_ball(Vector3(0.16, 0.13, 0.16) * s, at + Vector3(0, 0.08, -0.95) * s, Color(0.04, 0.04, 0.04))
	var jaw := at + Vector3(0, -0.15 - gape * 0.45, -0.45) * s
	_ball(Vector3(0.42, 0.18, 0.7) * s, jaw, hide.darkened(0.2))
	_ball(Vector3(0.36, 0.2, 0.5) * s, at + Vector3(0, -0.15 - gape * 0.2, -0.42) * s, GORE)  # mouth
	for k in 4:  # fangs
		var x := (-0.17 + 0.113 * k) * s
		_spike(at + Vector3(x, -0.12, -0.78) * s, at + Vector3(x, -0.12 - gape * 0.35 - 0.08, -0.78) * s, 0.035 * s, BONE)
		_spike(jaw + Vector3(x, 0.02, -0.28 * s), jaw + Vector3(x, 0.02 + (gape * 0.25 + 0.08) * s, -0.3 * s), 0.03 * s, BONE)
	for side in [-1.0, 1.0]:
		_spike(at + Vector3(side * 0.32, 0.25, 0.1) * s, at + Vector3(side * 0.46, 0.72, 0.2) * s, 0.16 * s, dark)
		_glow_ball(Vector3.ONE * 0.13 * s, at + Vector3(side * 0.24, 0.17, -0.42) * s, EYE)
	if eyes > 2:  # the extra ones crowd the forehead
		for k in eyes - 2:
			_glow_ball(Vector3.ONE * 0.1 * s, at + Vector3(-0.17 + 0.17 * k, 0.33, -0.34) * s, EYE)


## Backward-bending leg of something that walks on its toes.
func _leg(hip: Vector3, x: float, r: float, color: Color) -> void:
	var knee := Vector3(x, hip.y * 0.62, hip.z - 0.42)
	var ankle := Vector3(x, hip.y * 0.3, hip.z + 0.1)
	var toe := Vector3(x, 0.06, hip.z - 0.3)
	_bone(hip, knee, r, color)
	_bone(knee, ankle, r * 0.7, color)
	_bone(ankle, toe, r * 0.55, color)


func _arm(shoulder: Vector3, elbow: Vector3, hand: Vector3, r: float, color: Color, claw: float) -> void:
	_bone(shoulder, elbow, r, color)
	_bone(elbow, hand, r * 0.85, color)
	var along := (hand - elbow).normalized()
	for k in 3:
		var side := Vector3(-0.5 + 0.5 * k, 0, 0) * r * 2.2
		_spike(hand + side, hand + side + along * claw + Vector3(0, -0.05, -claw * 0.6), r * 0.32, BONE)


func _ringed_tail(from: Vector3, to: Vector3, r: float, dark: Color, light: Color) -> void:
	for k in 6:
		var t := k / 5.0
		var w := r * (1.0 - 0.45 * absf(t - 0.4))
		_ball(Vector3.ONE * w * 2.0, from.lerp(to, t), dark if k % 2 == 0 else light)


# --- primitives ----------------------------------------------------------------

func _material(color: Color) -> StandardMaterial3D:
	if _by_color.has(color):
		return _by_color[color]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.75
	mats.append(m)
	colors.append(color)
	_by_color[color] = m
	return m


func _add(mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _sphere() -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = 0.5
	m.height = 1.0
	m.radial_segments = 8
	m.rings = 4
	return m


func _ball(size: Vector3, at: Vector3, color: Color) -> void:
	_add(_sphere(), at, _material(color)).scale = size


func _glow_ball(size: Vector3, at: Vector3, color: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.5
	_add(_sphere(), at, m).scale = size


func _block(size: Vector3, at: Vector3, color: Color) -> void:
	var m := BoxMesh.new()
	m.size = size
	_add(m, at, _material(color))


## A limb between two points.
func _bone(a: Vector3, b: Vector3, r: float, color: Color) -> void:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(a.distance_to(b) + r * 2.0, r * 2.0 + 0.01)
	m.radial_segments = 6
	m.rings = 2
	_aim(_add(m, (a + b) * 0.5, _material(color)), a, b)


## A cone from base `a` to tip `b`: ears, claws, fangs, spikes.
func _spike(a: Vector3, b: Vector3, r: float, color: Color) -> void:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = r
	m.height = a.distance_to(b)
	m.radial_segments = 5
	m.rings = 1
	_aim(_add(m, (a + b) * 0.5, _material(color)), a, b)


## Turns a mesh's Y axis along a -> b.
func _aim(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var y := (b - a).normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	mi.basis = Basis(x, y, x.cross(y))
