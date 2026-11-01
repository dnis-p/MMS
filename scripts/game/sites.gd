class_name Sites
extends Node3D
## Places in the mine you walk up to use. Lifts take you out with everything you carry: stand on one
## for a moment. They lie on the floor, so the fog hides them until you get there.

var run: Run
var lift_t := 0.0  # seconds spent standing on a lift
var nearest_lift := Vector3.ZERO
var _ring_t := 0.0


func _ready() -> void:
	var pad := CylinderMesh.new()
	pad.top_radius = Defs.RUN["lift_pad"]
	pad.bottom_radius = Defs.RUN["lift_pad"]
	pad.height = 0.1
	pad.radial_segments = 16
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.5, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.8)
	mat.emission_energy_multiplier = 0.6
	for p in run.mine.lifts:
		var m := MeshInstance3D.new()
		m.mesh = pad
		m.material_override = mat
		m.position = p + Vector3(0, 0.06, 0)
		add_child(m)


func update(delta: float, at: Vector3) -> void:
	var best := INF
	for p in run.mine.lifts:
		var d := Vector2(p.x - at.x, p.z - at.z).length_squared()
		if d < best:
			best = d
			nearest_lift = p
	var pad: float = Defs.RUN["lift_pad"]
	if best > pad * pad or run.loot < 1.0:
		lift_t = 0.0
		return
	lift_t += delta
	_ring_t -= delta
	if _ring_t <= 0.0:
		_ring_t = 0.4
		run.fx.ring(nearest_lift, pad, Color(0.3, 1.0, 0.85, 0.9), 0.35)
	if lift_t >= float(Defs.RUN["lift_hold"]):
		run.leave_by_lift()
