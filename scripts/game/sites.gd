class_name Sites
extends Node3D
## Places in the mine you walk up to use. Lifts take you out with everything you carry: stand on one
## for a moment. They lie on the floor, so the fog hides them until you get there. Shrines offer a
## trade once. Relics are yours for good the moment you touch them.

var run: Run
var lift_t := 0.0  # seconds spent standing on a lift
var nearest_lift := Vector3.ZERO
var _ring_t := 0.0
var _spots: Array = []  # {"pos", "kind", "id", "mesh"}, removed once used


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
	var unfound: Array = Defs.RELICS.keys().filter(func(id): return not Profile.relics.has(id))
	run.shuffle(unfound)
	var shrines: Array = Defs.SHRINES.keys()
	for room in run.mine.rooms:
		var is_shrine: bool = room[1] == "shrine"
		var id: String = shrines[run.rng.randi() % shrines.size()] if is_shrine else unfound.pop_back()
		_add_spot(room[0], room[1], id, Defs.SHRINES[id]["color"] if is_shrine else Color(1.0, 0.9, 0.5))


func _add_spot(p: Vector3, spot_kind: String, id: String, color: Color) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 1.0, 0.9)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	var m := MeshInstance3D.new()
	m.mesh = box
	m.material_override = mat
	m.position = p + Vector3(0, 0.5, 0)
	add_child(m)
	_spots.append({"pos": p, "kind": spot_kind, "id": id, "mesh": m})


func _use_spots(at: Vector3) -> void:
	var near: float = Defs.RUN["site_use"]
	for i in range(_spots.size() - 1, -1, -1):
		var s: Dictionary = _spots[i]
		if Vector2(s["pos"].x - at.x, s["pos"].z - at.z).length() > near:
			continue
		s["mesh"].queue_free()
		run.mine.drop_glint(s["pos"])
		_spots.remove_at(i)
		if s["kind"] == "shrine":
			run.use_shrine(s["id"])
		else:
			run.find_relic(s["id"], s["pos"])


func update(delta: float, at: Vector3) -> void:
	_use_spots(at)
	var best := INF
	for p in run.mine.lifts:
		var d := Vector2(p.x - at.x, p.z - at.z).length_squared()
		if d < best:
			best = d
			nearest_lift = p
	var pad: float = Defs.RUN["lift_pad"]
	if best > pad * pad or run.loot < 1.0 or run.run_time < float(Defs.RUN["lift_from"]):
		lift_t = 0.0
		return
	lift_t += delta
	_ring_t -= delta
	if _ring_t <= 0.0:
		_ring_t = 0.4
		run.fx.ring(nearest_lift, pad, Color(0.3, 1.0, 0.85, 0.9), 0.35)
	if lift_t >= float(Defs.RUN["lift_hold"]):
		run.leave_by_lift()
