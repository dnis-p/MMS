class_name Pickups
extends Node3D
## Scrap (XP) gems, repair kits and salvage crates.

const MAX := 400
const GEM := 0
const REPAIR := 1
const DESPAWN_DIST := 70.0  # gems left this far behind are lost

var run: Run

var g_pos := PackedVector3Array()
var g_val := PackedInt32Array()
var g_kind := PackedInt32Array()
var g_pull := PackedFloat32Array()  # 0 = idle, >0 = flying to the car at this speed
var g_hop := PackedFloat32Array()
var crates: Array[Node3D] = []
var vacuum := false
var _mm_gem: MultiMesh
var _mm_repair: MultiMesh
var _time := 0.0


func _ready() -> void:
	var gem := SphereMesh.new()
	gem.radius = 0.28
	gem.height = 0.56
	gem.radial_segments = 4
	gem.rings = 2
	_mm_gem = _make_mm(gem)
	var kit := BoxMesh.new()
	kit.size = Vector3(0.6, 0.4, 0.6)
	_mm_repair = _make_mm(kit)


func _make_mm(mesh: Mesh) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = MAX
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-5000, -10, -5000), Vector3(10000, 40, 10000))
	add_child(mmi)
	return mm


func clear() -> void:
	for arr in [g_pos, g_val, g_kind, g_pull, g_hop]:
		arr.clear()
	for c in crates:
		c.queue_free()
	crates.clear()
	vacuum = false


func drop_gem(p: Vector3, value: int) -> void:
	if g_pos.size() >= MAX:
		# Too many on the field: fold the value into a random existing gem.
		var j := run.rng.randi() % g_pos.size()
		g_val[j] += value
		return
	g_pos.append(Vector3(p.x + run.rng.randf_range(-0.3, 0.3), 0.3, p.z + run.rng.randf_range(-0.3, 0.3)))
	g_val.append(value)
	g_kind.append(GEM)
	g_pull.append(0.0)
	g_hop.append(run.rng.randf_range(3.0, 5.0))


func drop_repair(p: Vector3) -> void:
	if g_pos.size() >= MAX:
		return
	g_pos.append(Vector3(p.x, 0.3, p.z))
	g_val.append(Defs.REPAIR_HEAL)
	g_kind.append(REPAIR)
	g_pull.append(0.0)
	g_hop.append(5.0)


func drop_crate(p: Vector3, guaranteed := 0) -> void:
	var crate := Node3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.4, 1.0, 1.0)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.75, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.1)
	mat.emission_energy_multiplier = 0.8
	mi.material_override = mat
	crate.add_child(mi)
	var band := MeshInstance3D.new()
	var band_mesh := BoxMesh.new()
	band_mesh.size = Vector3(1.45, 0.2, 1.05)
	band.mesh = band_mesh
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.25, 0.2, 0.15)
	band.material_override = band_mat
	crate.add_child(band)
	crate.set_meta("guaranteed", guaranteed)
	crate.set_meta("age", 0.0)
	add_child(crate)
	crate.global_position = Vector3(p.x, 14.0, p.z)
	crates.append(crate)


func update(delta: float) -> void:
	_time += delta
	var player: Player = run.player
	var car := player.global_position
	var magnet := player.pickup_radius
	var m2 := magnet * magnet
	var chime := false
	for i in range(g_pos.size() - 1, -1, -1):
		var p := g_pos[i]
		if g_hop[i] != 0.0:
			p.y += g_hop[i] * delta
			g_hop[i] -= 14.0 * delta
			if p.y <= 0.3:
				p.y = 0.3
				g_hop[i] = 0.0
		var diff := car - p
		diff.y = 0.0
		var d2 := diff.length_squared()
		if g_pull[i] == 0.0 and (d2 < m2 or vacuum):
			g_pull[i] = 4.0
		var reached := d2 < 1.0
		if g_pull[i] > 0.0:
			g_pull[i] += (60.0 if vacuum else 35.0) * delta
			var d := sqrt(d2)
			var step := minf(d, (g_pull[i] + player.velocity.length()) * delta)
			if d > 0.001:
				p += diff / d * step
			# Checked after moving: at low frame rates the car can outrun a 1 m radius.
			reached = reached or step >= d - 1.0
		elif d2 > DESPAWN_DIST * DESPAWN_DIST:
			for arr in [g_pos, g_val, g_kind, g_pull, g_hop]:
				_swap_remove(arr, i)
			continue
		if reached:
			if g_kind[i] == GEM:
				run.add_xp(g_val[i])
				chime = true
			else:
				run.heal(g_val[i])
			for arr in [g_pos, g_val, g_kind, g_pull, g_hop]:
				_swap_remove(arr, i)
			continue
		g_pos[i] = p
	if chime:
		run.on_gem_collected()
	_update_crates(delta, car)
	_render()


func _update_crates(delta: float, car: Vector3) -> void:
	for i in range(crates.size() - 1, -1, -1):
		var c := crates[i]
		var age: float = c.get_meta("age") + delta
		c.set_meta("age", age)
		var p := c.global_position
		p.y = maxf(0.6 + absf(sin(age * 3.0)) * 0.3, p.y - 30.0 * delta)
		c.global_position = p
		c.rotation.y += delta * 1.5
		var diff := car - p
		diff.y = 0.0
		if vacuum and age > 0.6:
			c.global_position += diff.normalized() * minf(diff.length(), 25.0 * delta)
		if diff.length() < 3.0 and age > 0.4:
			crates.remove_at(i)
			run.open_crate(int(c.get_meta("guaranteed")))
			c.queue_free()
		elif diff.length() > 90.0:
			crates.remove_at(i)
			c.queue_free()


func _swap_remove(arr, i: int) -> void:
	var last: int = arr.size() - 1
	if i != last:
		arr[i] = arr[last]
	arr.resize(last)


func _render() -> void:
	var ng := 0
	var nr := 0
	for i in g_pos.size():
		var basis := Basis(Vector3.UP, _time * 3.0 + i)
		if g_kind[i] == REPAIR:
			_mm_repair.set_instance_transform(nr, Transform3D(basis, g_pos[i]))
			_mm_repair.set_instance_color(nr, Color(0.3, 1.0, 0.4))
			nr += 1
			continue
		var v := g_val[i]
		var col := Color(0.3, 0.7, 1.0)
		var s := 1.0
		if v >= 10:
			col = Color(1.0, 0.3, 0.35)
			s = 1.6
		elif v >= 3:
			col = Color(0.35, 1.0, 0.5)
			s = 1.25
		_mm_gem.set_instance_transform(ng, Transform3D(basis.scaled(Vector3(s, s, s)), g_pos[i]))
		_mm_gem.set_instance_color(ng, col)
		ng += 1
	_mm_gem.visible_instance_count = ng
	_mm_repair.visible_instance_count = nr
