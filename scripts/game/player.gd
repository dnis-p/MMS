class_name Player
extends Node3D
## The player's vehicle: placeholder model, free driving on the map
## and boss-arena driving (auto-circling, dash, ring switching).

const RINGS: Array = Defs.ARENA["rings"]

var class_id := ""
var def: Dictionary
var max_hp := 100.0
var hp := 100.0
var armor := 0.0
var base_speed := 7.0
var speed := 7.0  # base_speed after stage and upgrades; see Run.update_pace
var ram_damage := 20.0
var radius := 1.2
var pickup_radius := Defs.PICKUP_RADIUS
var velocity := Vector3.ZERO
var invuln := 0.0

var heading := Vector3.FORWARD  # where the nose points; stays when the car stops
var move_dir := Vector3.FORWARD  # direction of travel, follows the nose closely
var drive_speed := 0.0
var turn_rate := 6.5
var boost := 1.0  # speed factor while nitro burns

var theta := 0.0
var ring_index := 1
var ring_radius := 10.5
var dash_time := 0.0
var dash_dir := 0.0
var dash_cd := 0.0
var circle_dir := 1.0  # +1 / -1: which way the car circles the boss

var _body: Node3D
var _mats: Array[StandardMaterial3D] = []
var _base_colors: Array[Color] = []
var _hurt_flash := 0.0
var _hardpoints: Array[Vector3] = []
var _weapon_visuals := {}
var _wheel_nodes: Array[Node3D] = []
var _time := 0.0


func setup(id: String) -> void:
	class_id = id
	def = Defs.CLASSES[id]
	max_hp = def["max_hp"]
	hp = max_hp
	armor = def["armor"]
	base_speed = def["speed"]
	speed = base_speed
	turn_rate = def["turn"]
	ram_damage = def["ram"]
	var size: Vector3 = def["size"]
	radius = maxf(size.x, size.z) * 0.42
	_build_model(size, def["color"])


func _build_model(size: Vector3, color: Color) -> void:
	_body = Node3D.new()
	add_child(_body)
	var wheel_r := 0.45 if class_id != "juggernaut" else 0.55
	var hull_y := wheel_r + size.y * 0.5 - 0.1
	_box(Vector3(size.x, size.y, size.z), Vector3(0, hull_y, 0), color)
	# Cabin sits toward the back; the nose is -Z.
	_box(Vector3(size.x * 0.75, size.y * 0.7, size.z * 0.35), Vector3(0, hull_y + size.y * 0.8, size.z * 0.15), color.darkened(0.25))
	_box(Vector3(size.x * 1.05, size.y * 0.35, 0.3), Vector3(0, hull_y - size.y * 0.15, -size.z * 0.5 - 0.1), Color(0.25, 0.25, 0.28))
	match class_id:
		"juggernaut":
			_cylinder(0.55, 0.5, Vector3(0, hull_y + size.y * 0.7, -size.z * 0.1), color.darkened(0.15))
			_box(Vector3(0.25, 0.25, 1.6), Vector3(0, hull_y + size.y * 0.75, -size.z * 0.45), Color(0.2, 0.2, 0.2))
		"interceptor":
			_box(Vector3(size.x * 1.1, 0.1, 0.4), Vector3(0, hull_y + size.y * 0.9, size.z * 0.45), Color(0.1, 0.1, 0.1))
		"warrig":
			_box(Vector3(size.x * 0.95, size.y * 0.9, size.z * 0.45), Vector3(0, hull_y + size.y * 0.55, size.z * 0.25), Color(0.4, 0.38, 0.35))
	var wheel_color := Color(0.1, 0.1, 0.1)
	for zx in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var w := _cylinder(wheel_r, 0.45, Vector3(zx.x * (size.x * 0.5 + 0.1), wheel_r, zx.y * size.z * 0.33), wheel_color)
		w.rotation.z = PI * 0.5
		_wheel_nodes.append(w)
	var top := hull_y + size.y * 0.5
	_hardpoints = [
		Vector3(0, top + size.y * 0.75, size.z * 0.15),
		Vector3(-size.x * 0.4, top, -size.z * 0.3),
		Vector3(size.x * 0.4, top, -size.z * 0.3),
		Vector3(0, top, size.z * 0.45),
		Vector3(-size.x * 0.4, top, size.z * 0.1),
		Vector3(size.x * 0.4, top, size.z * 0.1),
	]


func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.6
	_mats.append(m)
	_base_colors.append(color)
	return m


func _box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _material(color)
	mi.position = at
	_body.add_child(mi)
	return mi


func _cylinder(r: float, h: float, at: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	mesh.radial_segments = 10
	mi.mesh = mesh
	mi.material_override = _material(color)
	mi.position = at
	_body.add_child(mi)
	return mi


## Bolts a little turret onto the next free hardpoint, so the build shows on the car.
func add_weapon_visual(weapon_id: String) -> void:
	if _weapon_visuals.has(weapon_id):
		return
	var slot := _weapon_visuals.size()
	if slot >= _hardpoints.size():
		return
	var color: Color = Defs.WEAPONS[weapon_id]["color"]
	var at := _hardpoints[slot]
	var root := Node3D.new()
	root.position = at
	_body.add_child(root)
	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.28
	bm.bottom_radius = 0.34
	bm.height = 0.3
	bm.radial_segments = 8
	base.mesh = bm
	base.material_override = _material(Color(0.2, 0.2, 0.22))
	base.position.y = 0.15
	root.add_child(base)
	var gun := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.22, 0.22, 0.8)
	gun.mesh = gm
	gun.material_override = _material(color)
	gun.position = Vector3(0, 0.35, -0.3)
	root.add_child(gun)
	_weapon_visuals[weapon_id] = root
	root.scale = Vector3.ONE * 0.01
	var tw := create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func place_on_map() -> void:
	heading = Vector3.FORWARD
	move_dir = heading
	drive_speed = 0.0
	boost = 1.0
	global_position = Vector3.ZERO
	look_at(global_position + heading, Vector3.UP)
	velocity = Vector3.ZERO
	_body.rotation = Vector3.ZERO


## `input` is screen-relative (x right, y down). The nose turns toward it at the class
## turn rate; the car slows in hard turns and brakes to a stop with no input.
func drive(delta: float, input: Vector2, map: Map) -> void:
	_common(delta)
	var d := Defs.DRIVE
	var top := speed * boost
	var target := 0.0
	var turning := 0.0
	if input != Vector2.ZERO:
		var want := Vector3(input.x, 0.0, input.y).normalized()
		var off := heading.signed_angle_to(want, Vector3.UP)
		var step := clampf(off, -turn_rate * delta, turn_rate * delta)
		heading = heading.rotated(Vector3.UP, step).normalized()
		turning = step / maxf(delta, 0.0001)
		target = top * (1.0 - d["turn_slow"] * absf(off) / PI)
	var ramp: float = d["accel_time"] if target > drive_speed else d["brake_time"]
	drive_speed = move_toward(drive_speed, target, top / ramp * delta)
	var slip := move_dir.signed_angle_to(heading, Vector3.UP)
	move_dir = move_dir.rotated(Vector3.UP, slip * (1.0 - exp(-d["grip"] * delta))).normalized()
	var p := map.resolve(global_position + move_dir * drive_speed * delta, radius * 0.75)
	velocity = (p - global_position) / maxf(delta, 0.0001)
	global_position = p
	look_at(p + heading, Vector3.UP)
	_body.rotation.z = lerpf(_body.rotation.z, clampf(turning * d["lean"], -0.2, 0.2), 10.0 * delta)


func arena_speed() -> float:
	return speed * Defs.ARENA["speed_scale"]


func enter_arena(center: Vector3) -> void:
	theta = PI * 0.5
	ring_index = Defs.ARENA["start_ring"]
	ring_radius = RINGS[ring_index]
	dash_time = 0.0
	dash_cd = 0.0
	circle_dir = 1.0
	global_position = center + Vector3(cos(theta), 0, sin(theta)) * ring_radius
	_body.rotation = Vector3.ZERO


func arena_update(delta: float, center: Vector3) -> void:
	_common(delta)
	dash_cd -= delta
	var dtheta := circle_dir * arena_speed() / ring_radius * delta
	if dash_time > 0.0:
		dash_time -= delta
		dtheta += dash_dir * arena_speed() * Defs.ARENA["dash_speed"] / ring_radius * delta
	theta = fmod(theta + dtheta, TAU)
	ring_radius = move_toward(ring_radius, RINGS[ring_index], Defs.ARENA["ring_switch_speed"] * delta)
	var p := center + Vector3(cos(theta), 0, sin(theta)) * ring_radius
	velocity = (p - global_position) / maxf(delta, 0.0001)
	global_position = p
	var tangent := Vector3(-sin(theta), 0, cos(theta)) * signf(dtheta if dtheta != 0.0 else 1.0)
	look_at(p + tangent, Vector3.UP)


## `screen_dir` is +1 for a swipe to the right. The car dashes that way and keeps
## circling that way afterwards. Returns true if the dash happened.
func dash(screen_dir: float, cam_right: Vector3) -> bool:
	if dash_cd > 0.0:
		return false
	var tangent := Vector3(-sin(theta), 0, cos(theta))
	dash_dir = screen_dir * (1.0 if tangent.dot(cam_right) >= 0.0 else -1.0)
	circle_dir = dash_dir
	dash_time = Defs.ARENA["dash_time"]
	dash_cd = Defs.ARENA["dash_cooldown"]
	invuln = maxf(invuln, Defs.ARENA["dash_invuln"])
	return true


func switch_ring(step: int) -> bool:
	var next := clampi(ring_index + step, 0, RINGS.size() - 1)
	if next == ring_index:
		return false
	ring_index = next
	invuln = maxf(invuln, Defs.ARENA["ring_invuln"])
	return true


func can_be_hit() -> bool:
	return invuln <= 0.0


## Applies damage after armor. Returns the damage actually taken.
func hurt(amount: float) -> float:
	if not can_be_hit():
		return 0.0
	var taken := maxf(1.0, amount * (1.0 - minf(Defs.ARMOR_BLOCK_MAX, armor * Defs.ARMOR_BLOCK)))
	hp = maxf(0.0, hp - taken)
	invuln = Defs.HIT_INVULN
	_hurt_flash = 0.15
	return taken


func _common(delta: float) -> void:
	_time += delta
	invuln = maxf(0.0, invuln - delta)
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	var flashing := _hurt_flash > 0.0
	for i in _mats.size():
		_mats[i].albedo_color = Color(1.0, 0.25, 0.2) if flashing else _base_colors[i]
	# Blink while invulnerable so dodges read clearly.
	_body.visible = invuln <= 0.0 or fmod(_time * 20.0, 1.0) < 0.6
	_body.position.y = absf(sin(_time * 18.0)) * 0.04
	for w in _wheel_nodes:
		w.rotate_object_local(Vector3.UP, velocity.length() * delta * 1.5)
