class_name Player
extends Node3D
## The digger: a neutral placeholder body, no theme yet. Turning and stopping are instant, like a 2D
## game: where you press is where you go, at full speed, on the next frame.

const RADIUS := 0.55

var speed: float = Defs.DIGGER["speed"]
var base_speed: float = Defs.DIGGER["speed"]
var radius := RADIUS
var pickup_radius: float = Defs.DIGGER["pickup"]
var base_pickup: float = Defs.DIGGER["pickup"]
var velocity := Vector3.ZERO
var heading := Vector3.FORWARD  # stays when you stop, so tools keep working where you face

var _body: Node3D
var _tool: Node3D
var _swing_left := 0.0
var _swing_side := 1.0
var _time := 0.0


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var color: Color = Defs.DIGGER["color"]
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
	mi.position = at
	parent.add_child(mi)


## `input` is screen-relative (x right, y down). Any strength means full speed.
func move(delta: float, input: Vector2, mine: Mine) -> void:
	_time += delta
	velocity = Vector3.ZERO
	if input != Vector2.ZERO:
		heading = Vector3(input.x, 0.0, input.y).normalized()
		velocity = heading * speed
	var p := mine.resolve(global_position + velocity * delta, radius)
	global_position = p
	look_at(p + heading, Vector3.UP)
	_body.position.y = absf(sin(_time * 14.0)) * 0.1 if velocity != Vector3.ZERO else 0.0
	_swing_left = maxf(0.0, _swing_left - delta)
	var t := _swing_left / 0.14
	_tool.rotation.y = _swing_side * lerpf(-1.1, 1.1, t) if _swing_left > 0.0 else 0.0
	_body.scale = Vector3(1.0 + 0.15 * t, 1.0 - 0.12 * t, 1.0 + 0.15 * t)


func swing() -> void:
	_swing_left = 0.14
	_swing_side = -_swing_side
