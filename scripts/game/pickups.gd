class_name Pickups
extends Node3D
## Shiny gems dropped by ore. They wait on the floor and fly to you when you get close.

const MAX := 500

var run: Run

var g_pos := PackedVector3Array()
var g_val := PackedInt32Array()
var g_col := PackedColorArray()
var g_pull := PackedFloat32Array()  # 0 = idle, >0 = flying to the digger at this speed
var g_hop := PackedFloat32Array()
var _mm: MultiMesh
var _time := 0.0


func _ready() -> void:
	var gem := SphereMesh.new()
	gem.radius = 0.2
	gem.height = 0.4
	gem.radial_segments = 4
	gem.rings = 2
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = gem
	_mm.instance_count = MAX
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-5000, -10, -5000), Vector3(10000, 40, 10000))
	add_child(mmi)


func drop_gem(p: Vector3, value: int, color: Color) -> void:
	if g_pos.size() >= MAX:
		# Too many on the floor: fold the value into a random existing gem.
		var j := run.rng.randi() % g_pos.size()
		g_val[j] += value
		return
	g_pos.append(Vector3(p.x + run.rng.randf_range(-0.2, 0.2), 0.6, p.z + run.rng.randf_range(-0.2, 0.2)))
	g_val.append(value)
	g_col.append(color.lightened(0.45))
	g_pull.append(0.0)
	g_hop.append(run.rng.randf_range(4.0, 6.0))


func update(delta: float) -> void:
	_time += delta
	var player: Player = run.player
	var at := player.global_position
	var m2 := player.pickup_radius * player.pickup_radius
	var chime := false
	for i in range(g_pos.size() - 1, -1, -1):
		var p := g_pos[i]
		if g_hop[i] != 0.0:
			p.y += g_hop[i] * delta
			g_hop[i] -= 16.0 * delta
			if p.y <= 0.3:
				p.y = 0.3
				g_hop[i] = 0.0
		var diff := at - p
		diff.y = 0.0
		var d2 := diff.length_squared()
		if g_pull[i] == 0.0 and d2 < m2:
			g_pull[i] = 5.0
		var reached := d2 < 0.5
		if g_pull[i] > 0.0:
			g_pull[i] += 40.0 * delta
			var d := sqrt(d2)
			var step := minf(d, (g_pull[i] + player.velocity.length()) * delta)
			if d > 0.001:
				p += diff / d * step
			# Checked after moving: at low frame rates you can outrun a small radius.
			reached = reached or step >= d - 0.7
		if reached:
			run.add_xp(g_val[i])
			chime = true
			for arr in [g_pos, g_val, g_col, g_pull, g_hop]:
				_swap_remove(arr, i)
			continue
		g_pos[i] = p
	if chime:
		run.on_gem_collected()
	_render()


func _swap_remove(arr, i: int) -> void:
	var last: int = arr.size() - 1
	if i != last:
		arr[i] = arr[last]
	arr.resize(last)


func _render() -> void:
	var white := Color(1, 1, 1)
	for i in g_pos.size():
		var s := 1.0 + 0.2 * sin(_time * 7.0 + i)
		_mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, _time * 3.0 + i).scaled(Vector3(s, s, s)), g_pos[i]))
		_mm.set_instance_color(i, g_col[i].lerp(white, 0.5 + 0.5 * sin(_time * 9.0 + i * 2.0)))
	_mm.visible_instance_count = g_pos.size()
