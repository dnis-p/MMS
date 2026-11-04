class_name Player
extends Node3D
## The digger: a neutral placeholder body, no theme yet. Turning and stopping are instant, like a 2D
## game: where you press is where you go, at full speed, on the next frame. Movement and aim are
## separate, as in Enter the Gungeon: `heading` is where the tools point, which is the mouse once
## there is one, and otherwise the way you walk.

const RADIUS := 0.55

var color: Color = Defs.DIGGER["color"]
var speed: float = Defs.DIGGER["speed"]
var base_speed: float = Defs.DIGGER["speed"]
var radius := RADIUS
var pickup_radius: float = Defs.DIGGER["pickup"]
var base_pickup: float = Defs.DIGGER["pickup"]
var velocity := Vector3.ZERO
var heading := Vector3.FORWARD  # stays when you stop, so tools keep working where you face
var aiming := false  # the mouse sets `heading`, moving doesn't
var max_hp: float = Defs.DIGGER["hp"]
var hp: float = Defs.DIGGER["hp"]
var invuln := 0.0
var dash_left := 0.0  # seconds left of the Dash Drive's burst
var last_move := Vector3.FORWARD  # the way you last walked: where a dash goes when you stand still

var _dash_dir := Vector3.FORWARD
var _dash_speed := 0.0
var _body: Node3D
var _tool: Node3D
var _swing_left := 0.0
var _swing_side := 1.0
var _time := 0.0
var _hurt_left := 0.0
var _mats: Array[StandardMaterial3D] = []
var _colors: Array[Color] = []


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	_box(Vector3(0.75, 0.9, 0.6), Vector3(0, 0.55, 0), color, _body)
	_box(Vector3(0.5, 0.42, 0.5), Vector3(0, 1.2, -0.03), color.lightened(0.35), _body)
	_box(Vector3(0.34, 0.12, 0.06), Vector3(0, 1.24, -0.3), Color(0.05, 0.05, 0.06), _body)
	_tool = Node3D.new()
	_tool.position = Vector3(0, 0.85, 0)
	_body.add_child(_tool)
	_box(Vector3(0.09, 0.09, 1.25), Vector3(0, 0, -0.65), Color(0.6, 0.45, 0.28), _tool)
	_box(Vector3(0.42, 0.08, 0.42), Vector3(0, 0, -1.4), Color(0.8, 0.82, 0.86), _tool)


func _box(size: Vector3, at: Vector3, color: Color, parent: Node3D) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	_mats.append(mat)
	_colors.append(color)
	mi.position = at
	parent.add_child(mi)


## `input` is screen-relative (x right, y down). Any strength means full speed.
func move(delta: float, input: Vector2, mine: Mine) -> void:
	_time += delta
	invuln = maxf(0.0, invuln - delta)
	_hurt_left = maxf(0.0, _hurt_left - delta)
	for i in _mats.size():
		_mats[i].albedo_color = Color(1.0, 0.2, 0.15) if _hurt_left > 0.0 else _colors[i]
	_body.visible = invuln <= 0.0 or fmod(_time * 20.0, 1.0) < 0.6  # blink while safe
	velocity = Vector3.ZERO
	var travel := delta
	if input != Vector2.ZERO:
		last_move = Vector3(input.x, 0.0, input.y).normalized()
	if dash_left > 0.0:
		travel = minf(delta, dash_left)
		dash_left -= travel
		velocity = _dash_dir * _dash_speed
		if not aiming:
			heading = _dash_dir
	elif input != Vector2.ZERO:
		velocity = last_move * speed
		if not aiming:
			heading = last_move
	# Small steps, so a fast dash can't skip over a wall of cubes.
	var steps := maxi(1, ceili(velocity.length() * travel / (Mine.CELL * 0.4)))
	var p := global_position
	for k in steps:
		p = mine.resolve(p + velocity * travel / steps, radius)
	global_position = p
	look_at(p + heading, Vector3.UP)
	_body.position.y = absf(sin(_time * 14.0)) * 0.1 if velocity != Vector3.ZERO else 0.0
	_swing_left = maxf(0.0, _swing_left - delta)
	var t := _swing_left / 0.14
	_tool.rotation.y = _swing_side * lerpf(-1.1, 1.1, t) if _swing_left > 0.0 else 0.0
	_body.scale = Vector3(1.0 + 0.15 * t, 1.0 - 0.12 * t, 1.0 + 0.15 * t)


## Takes a hit unless still blinking from the last one. Returns true if it landed.
func hurt(amount: float) -> bool:
	if invuln > 0.0:
		return false
	hp = maxf(0.0, hp - amount)
	invuln = Defs.DIGGER["invuln"]
	_hurt_left = 0.15
	return true


func swing() -> void:
	_swing_left = 0.14
	_swing_side = -_swing_side


func bursting() -> bool:
	return dash_left > 0.0


## Starts the Dash Drive's burst: `dash_speed` m/s along `dir` for `time` seconds, and no hit can land
## for `grace` seconds longer. You can't steer until it ends.
func start_dash(dir: Vector3, dash_speed: float, time: float, grace: float) -> void:
	_dash_dir = dir
	_dash_speed = dash_speed
	dash_left = time
	invuln = maxf(invuln, time + grace)


## Turns this body into a translucent hologram tinted `tint`, for the dash clone. Call it once the
## body is built, that is after it has joined the tree.
func make_ghost(tint: Color) -> void:
	for i in _mats.size():
		var m := _mats[i]
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_colors[i] = Color(_colors[i].lerp(tint, 0.65), 0.5)
		m.albedo_color = _colors[i]


## White flash for the ghost when enemies hit it (a ghost never runs `move`, which does the red flash).
func ghost_flash(on: bool) -> void:
	for i in _mats.size():
		_mats[i].albedo_color = Color(1, 1, 1, 0.85) if on else _colors[i]
