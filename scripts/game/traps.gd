class_name Traps
extends Node3D
## Things in the mine that hurt without being alive. Spike plates lie on the floor, often under rock,
## and go up and down on a beat you can read. Gas rock looks like rock and blows a short moment after
## it breaks, which hurts you and anything else nearby. Pale loose rock brings the roof of the mine
## down a moment after it breaks: rubble fills the tunnels around it and crushes what stands there.

const MAX_SPIKES := 3000
const MAX_FUSES := 10
const DRAW_RANGE := 26.0
const CONES := 4
const MAX_CAVES := 4

var run: Run
var _pos := PackedVector3Array()
var _beat := PackedFloat32Array()  # where in the up-and-down cycle this plate starts
var _at := {}  # metre cell -> plate
var _plates: MultiMesh
var _spikes: MultiMesh
var _fuse_mesh: Array[MeshInstance3D] = []
var _fuse_pos: Array[Vector3] = []
var _fuse_left: Array[float] = []
var _cave_pos: Array[Vector3] = []
var _cave_left: Array[float] = []
var _cave_mesh: Array[MeshInstance3D] = []
var _time := 0.0


func _ready() -> void:
	var plate := BoxMesh.new()
	plate.size = Vector3(0.92, 0.04, 0.92)
	_plates = _make_mm(plate, MAX_SPIKES)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.14
	cone.height = 0.6
	cone.radial_segments = 5
	cone.rings = 1
	_spikes = _make_mm(cone, MAX_SPIKES * CONES)
	var ball := SphereMesh.new()
	ball.radius = 0.5
	ball.height = 1.0
	ball.radial_segments = 8
	ball.rings = 4
	for i in MAX_FUSES:
		var m := MeshInstance3D.new()
		m.mesh = ball
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.visible = false
		add_child(m)
		_fuse_mesh.append(m)
		_fuse_pos.append(Vector3.ZERO)
		_fuse_left.append(0.0)
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.radial_segments = 32
	disc.rings = 1
	for i in MAX_CAVES:
		var m := MeshInstance3D.new()
		m.mesh = disc
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.visible = false
		add_child(m)
		_cave_mesh.append(m)
		_cave_left.append(0.0)
		_cave_pos.append(Vector3.ZERO)


func _make_mm(mesh: Mesh, count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	mm.visible_instance_count = 0
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-5000, -10, -5000), Vector3(10000, 40, 10000))
	add_child(mmi)
	return mm


## Patches of plates, none near the start.
func generate(rng: RandomNumberGenerator) -> void:
	var t := Defs.THREATS
	var world := Mine.SIZE * Mine.CELL * 0.48
	for k in t["spike_patches"]:
		var at := run.mine._spot(rng, t["safe_start"], world)
		var cx := roundi(at.x)
		var cz := roundi(at.z)
		var size: int = rng.randi_range(1, 3)
		var beat := rng.randf() * float(t["spike_cycle"])
		for z in range(-size, size + 1):
			for x in range(-size, size + 1):
				if _pos.size() < MAX_SPIKES and rng.randf() < 0.7:
					add_plate(Vector3(cx + x + 0.5, 0, cz + z + 0.5), beat)


func add_plate(p: Vector3, beat: float) -> void:
	_at[Vector2i(floori(p.x), floori(p.z))] = _pos.size()
	_pos.append(p)
	_beat.append(beat)


## 0 = down, 1 = up and dangerous. A plate rises a little as a warning first.
func height(i: int) -> float:
	var t := Defs.THREATS
	var phase := fmod(_time + _beat[i], t["spike_cycle"])
	var up_from: float = t["spike_cycle"] - t["spike_up"]
	var warn: float = t["spike_warn"]
	if phase >= up_from:
		return 1.0
	return 0.3 if phase >= up_from - warn else 0.0


func update(delta: float, at: Vector3) -> void:
	_time += delta
	_update_fuses(delta)
	_update_caves(delta, at)
	var mine := run.mine
	var plate = _at.get(Vector2i(floori(at.x), floori(at.z)))
	if plate != null and height(plate) >= 1.0 and mine.kind_at(at) == 0:
		run.player_hit(Defs.THREATS["spike_dmg"])
	var n := 0
	var cones := 0
	var far := DRAW_RANGE * DRAW_RANGE
	var dark := Color(0.28, 0.08, 0.08)
	var steel := Color(0.8, 0.82, 0.86)
	for i in _pos.size():
		var p := _pos[i]
		if at.distance_squared_to(p) > far or mine.kind_at(p) != 0:
			continue
		_plates.set_instance_transform(n, Transform3D(Basis.IDENTITY, p + Vector3(0, 0.02, 0)))
		_plates.set_instance_color(n, dark)
		n += 1
		var h := height(i)
		if h <= 0.0:
			continue
		for k in CONES:
			var o := Vector3(-0.22 + 0.44 * (k % 2), 0.3 * h - 0.3 + 0.3, -0.22 + 0.44 * (k / 2))
			_spikes.set_instance_transform(cones, Transform3D(Basis.IDENTITY.scaled(Vector3(1, h, 1)), p + o))
			_spikes.set_instance_color(cones, steel)
			cones += 1
	_plates.visible_instance_count = n
	_spikes.visible_instance_count = cones


## Loose rock broke here. One cave-in covers a whole patch of it.
func start_cave_in(p: Vector3) -> void:
	var spot := -1
	var r := Defs.RUN
	for i in MAX_CAVES:
		if _cave_left[i] > 0.0:
			if p.distance_to(_cave_pos[i]) < r["cave_r"]:
				return
		elif spot < 0:
			spot = i
	if spot < 0:
		return
	_cave_left[spot] = r["cave_warn"]
	_cave_pos[spot] = Vector3(p.x, 0, p.z)
	var m := _cave_mesh[spot]
	m.position = Vector3(p.x, Mine.HEIGHT + 0.05, p.z)
	m.scale = Vector3(r["cave_r"], 1.0, r["cave_r"])
	m.visible = true
	if p.distance_to(run.player.global_position) < 30.0:
		run.fx.shake(0.3)
		Sfx.play("thud", -3.0, 0.45, true)


## The warning: a shadow on the ground and dust raining down, then the rubble.
func _update_caves(delta: float, at: Vector3) -> void:
	var r := Defs.RUN
	for i in MAX_CAVES:
		if _cave_left[i] <= 0.0:
			continue
		_cave_left[i] -= delta
		var k := 1.0 - _cave_left[i] / float(r["cave_warn"])
		(_cave_mesh[i].material_override as StandardMaterial3D).albedo_color = Color(0.1, 0.05, 0.02, 0.15 + 0.3 * k + 0.1 * sin(k * 40.0))
		var a := run.rng.randf() * TAU
		var dust := _cave_pos[i] + Vector3(cos(a), 2.5, sin(a)) * run.rng.randf_range(0.0, float(r["cave_r"]))
		run.debris.spray(dust, Color(0.5, 0.45, 0.4), 3, dust, 0.5)
		if _cave_left[i] <= 0.0:
			_cave_mesh[i].visible = false
			run.cave_in(_cave_pos[i], at)


## Gas rock broke here. One fuse covers a whole pocket of it.
func light_gas(p: Vector3) -> void:
	var spot := -1
	for i in MAX_FUSES:
		if _fuse_left[i] > 0.0:
			if p.distance_to(_fuse_pos[i]) < Defs.THREATS["gas_merge"]:
				return
		elif spot < 0:
			spot = i
	if spot < 0:
		return
	_fuse_left[spot] = Defs.THREATS["gas_fuse"]
	_fuse_pos[spot] = Vector3(p.x, 0.4, p.z)
	_fuse_mesh[spot].global_position = _fuse_pos[spot]
	_fuse_mesh[spot].visible = true
	Sfx.play("fuse", -5.0)


func _update_fuses(delta: float) -> void:
	var t := Defs.THREATS
	for i in MAX_FUSES:
		if _fuse_left[i] <= 0.0:
			continue
		_fuse_left[i] -= delta
		var k := 1.0 - _fuse_left[i] / float(t["gas_fuse"])
		var m := _fuse_mesh[i]
		m.scale = Vector3.ONE * lerpf(0.6, float(t["gas_radius"]) * 2.0, k * k)
		var blink := 0.5 + 0.5 * sin(k * k * 60.0)
		(m.material_override as StandardMaterial3D).albedo_color = Color(1.0, 0.75 * blink, 0.1, 0.18 + 0.2 * blink)
		if _fuse_left[i] <= 0.0:
			m.visible = false
			run.gas_blast(_fuse_pos[i])
