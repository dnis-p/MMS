class_name Pickups
extends Node3D
## Shiny gems dropped by ore. They wait on the floor and fly to you when you get close. Each one
## has a star on top that twinkles and shows through rock, so a gem in a side tunnel still catches
## the eye.

const MAX := 1500
const DRAW_RANGE := 45.0  # gems further away are off screen

var run: Run

var g_pos := PackedVector3Array()
var g_val := PackedFloat32Array()
var g_col := PackedColorArray()
var g_pull := PackedFloat32Array()  # 0 = idle, >0 = flying to the digger at this speed
var g_hop := PackedFloat32Array()
var _mm: MultiMesh
var _stars: MultiMesh
var _star_basis: Basis
var _time := 0.0


func _ready() -> void:
	var gem := SphereMesh.new()
	gem.radius = 0.26
	gem.height = 0.52
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
	_build_stars()


func _build_stars() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 1.5
	_stars = MultiMesh.new()
	_stars.transform_format = MultiMesh.TRANSFORM_3D
	_stars.use_colors = true
	_stars.mesh = quad
	_stars.instance_count = MAX
	_stars.visible_instance_count = 0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.no_depth_test = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _star_texture()
	mat.render_priority = 5
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _stars
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-5000, -10, -5000), Vector3(10000, 40, 10000))
	add_child(mmi)
	# The camera never turns, so one tilt keeps every star facing it.
	var cam := Defs.CAMERA
	var to_cam := Vector3(0, cam["up"], cam["back"]).normalized()
	_star_basis = Basis(Vector3.RIGHT, to_cam.cross(Vector3.RIGHT), to_cam)


## A soft glow with four thin rays.
func _star_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5) / 32.0
			var fade := maxf(0.0, 1.0 - d.length())
			var rays := pow(maxf(0.0, 1.0 - absf(d.x) * 14.0), 2.0) + pow(maxf(0.0, 1.0 - absf(d.y) * 14.0), 2.0)
			var a := clampf(fade * fade * fade * 0.8 + rays * fade, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func drop_gem(p: Vector3, value: float, color: Color) -> void:
	if g_pos.size() >= MAX:
		# Too many on the floor: fold the value into a random existing gem.
		var j := run.rng.randi() % g_pos.size()
		g_val[j] += value
		return
	g_pos.append(Vector3(p.x + run.rng.randf_range(-0.2, 0.2), 0.9, p.z + run.rng.randf_range(-0.2, 0.2)))
	g_val.append(value)
	g_col.append(color)
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
			if p.y <= 0.5:
				p.y = 0.5
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
			run.debris.spray(p, g_col[i], 3, p, 0.7)
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
	var at := run.player.global_position
	var far := DRAW_RANGE * DRAW_RANGE
	var n := 0
	for i in g_pos.size():
		var p := g_pos[i]
		if at.distance_squared_to(p) > far:
			continue
		var big := 1.0 + minf(g_val[i], 8.0) * 0.1
		var s := big * (1.0 + 0.15 * sin(_time * 7.0 + i))
		_mm.set_instance_transform(n, Transform3D(Basis(Vector3.UP, _time * 3.0 + i).scaled(Vector3(s, s, s)), p))
		_mm.set_instance_color(n, g_col[i].lerp(white, 0.1 + 0.1 * sin(_time * 9.0 + i * 2.0)))
		var twinkle := pow(absf(sin(_time * 3.5 + i * 1.7)), 6.0)
		var size := big * (0.55 + 0.75 * twinkle)
		var turn := Basis(_star_basis.z, _time * 0.8 + i)
		_stars.set_instance_transform(n, Transform3D((turn * _star_basis).scaled(Vector3(size, size, size)), p))
		_stars.set_instance_color(n, g_col[i].lerp(white, twinkle * twinkle * 0.5) * 0.5)
		n += 1
	_mm.visible_instance_count = n
	_stars.visible_instance_count = n
