class_name Map
extends Node3D
## One stage's open map: a walled rectangle with themed ground, optional roads
## (decoration only), small solid obstacles and buildings or cliffs as the outer
## walls. Nothing inside the walls is tall enough to hide the car or enemies.

const CELL := 4.0  # obstacle lookup grid; each obstacle fills its cell and the 8 around it
const ROAD_HALF_WIDTH := 5.5
const CENTER_CLEAR := 14.0  # no obstacles this close to where the car starts
const ROAD_CLEAR := 9.0
const WALL_SEGMENT := 8.0
const WALL_DEPTH := 6.0
const SOUTH_WALL_HEIGHT := 1.4  # the camera looks over this side, so it must stay low

var half := Vector2(150, 150)
var _ground: MeshInstance3D
var _cols := 0
var _rows := 0
var _solid := PackedInt32Array()  # cell -> obstacle index, -1 when free
var _ox := PackedFloat32Array()
var _oz := PackedFloat32Array()
var _or := PackedFloat32Array()
var _road_cells := PackedByteArray()  # 1 = road nearby, keep obstacles out

const ROAD_SHADER := """
shader_type spatial;
uniform vec4 road_color : source_color;
uniform vec4 line_color : source_color;
uniform vec4 edge_color : source_color;
void fragment() {
	float u = UV.x;
	float v = UV.y;
	vec3 c = road_color.rgb;
	float grit = fract(sin(dot(floor(vec2(u * 30.0, v * 3.0)), vec2(12.9898, 78.233))) * 43758.5453);
	c *= 0.92 + 0.08 * grit;
	float edge = clamp(step(u, 0.035) + step(0.965, u), 0.0, 1.0);
	float dash = step(abs(u - 0.5), 0.012) * step(fract(v * 0.1), 0.5);
	c = mix(c, edge_color.rgb, edge);
	c = mix(c, line_color.rgb, dash);
	ALBEDO = c;
	EMISSION = line_color.rgb * dash * 0.6;
	ROUGHNESS = 0.9;
}
"""

const GROUND_SHADER := """
shader_type spatial;
uniform vec4 color_a : source_color;
uniform vec4 color_b : source_color;
uniform vec4 grid_color : source_color;
uniform vec4 outer_color : source_color;
uniform float grid_strength = 0.0;
uniform vec2 half_size = vec2(150.0, 150.0);
varying vec3 wpos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = mod(wpos.xz + 2048.0, 4096.0);
	float n = noise(p * 0.07) * 0.6 + noise(p * 0.4) * 0.4;
	vec3 c = mix(color_a.rgb, color_b.rgb, n);
	vec2 g = abs(fract(p / 6.0) - 0.5);
	float line = step(0.47, max(g.x, g.y)) * grid_strength;
	float outside = clamp(step(half_size.x, abs(wpos.x)) + step(half_size.y, abs(wpos.z)), 0.0, 1.0);
	ALBEDO = mix(mix(c, grid_color.rgb, line), outer_color.rgb, outside);
	EMISSION = grid_color.rgb * line * 0.8 * (1.0 - outside);
	ROUGHNESS = 1.0;
}
"""


func build(biome: Dictionary, rng: RandomNumberGenerator) -> void:
	for c in get_children():
		c.queue_free()
	var h: Array = biome["half"]
	half = Vector2(h[0], h[1])
	_cols = int(half.x * 2.0 / CELL) + 1
	_rows = int(half.y * 2.0 / CELL) + 1
	_solid.resize(_cols * _rows)
	_solid.fill(-1)
	_ox.clear()
	_oz.clear()
	_or.clear()
	_road_cells.resize(_cols * _rows)
	_road_cells.fill(0)
	_build_roads(biome, rng)
	_build_ground(biome)
	var theme := _theme(String(biome["props"]))
	_scatter_obstacles(theme, int(biome["solids"]), rng)
	_scatter_decor(theme, int(biome["decor"]), rng)
	_build_walls(theme, rng)


func follow(target: Vector3) -> void:
	if _ground:
		_ground.global_position = Vector3(snappedf(target.x, 4.0), -0.02, snappedf(target.z, 4.0))


func contains(p: Vector3, margin: float) -> bool:
	return absf(p.x) <= half.x - margin and absf(p.z) <= half.y - margin


func clamp_inside(p: Vector3, margin: float) -> Vector3:
	p.x = clampf(p.x, -half.x + margin, half.x - margin)
	p.z = clampf(p.z, -half.y + margin, half.y - margin)
	return p


## Pushes a circle of radius `r` out of the walls and any obstacle it overlaps.
func resolve(p: Vector3, r: float) -> Vector3:
	p.x = clampf(p.x, -half.x + r, half.x - r)
	p.z = clampf(p.z, -half.y + r, half.y - r)
	var o := _solid[_cell(p.x, p.z)]
	if o < 0:
		return p
	var dx := p.x - _ox[o]
	var dz := p.z - _oz[o]
	var min_d := _or[o] + r
	var d2 := dx * dx + dz * dz
	if d2 >= min_d * min_d or d2 < 0.0001:
		return p
	var d := sqrt(d2)
	p.x = _ox[o] + dx / d * min_d
	p.z = _oz[o] + dz / d * min_d
	return p


func _cell(x: float, z: float) -> int:
	return _cell_at(int((x + half.x) / CELL), int((z + half.y) / CELL))


func _cell_at(col: int, row: int) -> int:
	return clampi(row, 0, _rows - 1) * _cols + clampi(col, 0, _cols - 1)


func _build_roads(biome: Dictionary, rng: RandomNumberGenerator) -> void:
	match String(biome["roads"]):
		"winding":
			_road_strip(_winding_road(rng), biome)
		"grid":
			for k in [-0.5, 0.0, 0.5]:
				var x: float = half.x * k
				var z: float = half.y * k
				_road_strip(PackedVector3Array([Vector3(x, 0, -half.y), Vector3(x, 0, half.y)]), biome)
				_road_strip(PackedVector3Array([Vector3(-half.x, 0, z), Vector3(half.x, 0, z)]), biome)


func _winding_road(rng: RandomNumberGenerator) -> PackedVector3Array:
	var curve := Curve3D.new()
	curve.bake_interval = 2.0
	var step := 45.0
	var z := rng.randf_range(-half.y * 0.4, half.y * 0.4)
	var x := -half.x
	while x < half.x + step:
		var dir := Vector3(1, 0, 0)
		curve.add_point(Vector3(x, 0, z), -dir * step * 0.35, dir * step * 0.35)
		z = clampf(z + rng.randf_range(-30.0, 30.0), -half.y * 0.7, half.y * 0.7)
		x += step
	return curve.get_baked_points()


func _road_strip(points: PackedVector3Array, biome: Dictionary) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var travelled := 0.0
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var side := (b - a).normalized().cross(Vector3.UP) * ROAD_HALF_WIDTH
		var seg := a.distance_to(b)
		_quad(st, a - side, a + side, b - side, b + side, travelled, travelled + seg)
		travelled += seg
		var steps := int(seg / 6.0) + 1
		for k in steps:
			var at := a.lerp(b, float(k) / steps)
			_mark_road(at.x, at.z)
	st.generate_normals()
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = ROAD_SHADER
	mat.shader = shader
	mat.set_shader_parameter("road_color", biome["road"])
	mat.set_shader_parameter("line_color", biome["line"])
	mat.set_shader_parameter("edge_color", biome["edge"])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.position.y = 0.02
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _quad(st: SurfaceTool, l0: Vector3, r0: Vector3, l1: Vector3, r1: Vector3, v0: float, v1: float) -> void:
	# Two triangles, wound clockwise seen from above (Godot's front-face order).
	st.set_uv(Vector2(0, v0)); st.add_vertex(l0)
	st.set_uv(Vector2(0, v1)); st.add_vertex(l1)
	st.set_uv(Vector2(1, v0)); st.add_vertex(r0)
	st.set_uv(Vector2(1, v0)); st.add_vertex(r0)
	st.set_uv(Vector2(0, v1)); st.add_vertex(l1)
	st.set_uv(Vector2(1, v1)); st.add_vertex(r1)


func _build_ground(biome: Dictionary) -> void:
	_ground = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(420, 420)
	_ground.mesh = plane
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = GROUND_SHADER
	mat.shader = shader
	mat.set_shader_parameter("color_a", biome["ground_a"])
	mat.set_shader_parameter("color_b", biome["ground_b"])
	mat.set_shader_parameter("grid_color", biome["grid_color"])
	mat.set_shader_parameter("grid_strength", biome["grid"])
	mat.set_shader_parameter("outer_color", Color(biome["ground_b"]).darkened(0.6))
	mat.set_shader_parameter("half_size", half)
	_ground.material_override = mat
	_ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ground)


func _mark_road(x: float, z: float) -> void:
	var col := int((x + half.x) / CELL)
	var row := int((z + half.y) / CELL)
	var reach := ceili((ROAD_HALF_WIDTH + ROAD_CLEAR) / CELL)
	for dc in range(-reach, reach + 1):
		for dr in range(-reach, reach + 1):
			_road_cells[_cell_at(col + dc, row + dr)] = 1


func _near_road(x: float, z: float) -> bool:
	return _road_cells[_cell(x, z)] == 1


## Small solid things the car and enemies go around, spaced so the map stays open.
func _scatter_obstacles(theme: Dictionary, count: int, rng: RandomNumberGenerator) -> void:
	var kinds: Array = theme["obstacles"]
	var placed: Array = []
	for kind in kinds:
		placed.append({"mesh": kind["mesh"], "emissive": kind.get("emissive", false), "transforms": [], "colors": []})
	var margin := CELL * 2.0
	for n in count:
		for attempt in 6:
			var x := rng.randf_range(-half.x + margin, half.x - margin)
			var z := rng.randf_range(-half.y + margin, half.y - margin)
			if Vector2(x, z).length() < CENTER_CLEAR or not _cells_free(x, z) or _near_road(x, z):
				continue
			var k := rng.randi() % kinds.size()
			var kind: Dictionary = kinds[k]
			var size: float = rng.randf_range(0.8, 1.2)
			var sc: Vector3 = kind["scale"] * size
			_add_obstacle(x, z, float(kind["radius"]) * size)
			placed[k]["transforms"].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(sc), Vector3(x, sc.y * 0.5, z)))
			placed[k]["colors"].append(_pick_color(kind, rng))
			break
	for p in placed:
		_add_multimesh(p["mesh"], p["transforms"], p["colors"], p["emissive"])


func _scatter_decor(theme: Dictionary, count: int, rng: RandomNumberGenerator) -> void:
	var kind: Dictionary = theme["decor"]
	var transforms: Array = []
	var colors: Array = []
	for n in count:
		var at := Vector3(rng.randf_range(-half.x, half.x), 0.02, rng.randf_range(-half.y, half.y))
		var sc: Vector3 = kind["scale"] * rng.randf_range(0.6, 1.6)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(sc), at))
		colors.append(_pick_color(kind, rng))
	_add_multimesh(kind["mesh"], transforms, colors, kind.get("emissive", false))


func _cells_free(x: float, z: float) -> bool:
	var col := int((x + half.x) / CELL)
	var row := int((z + half.y) / CELL)
	for dc in range(-1, 2):
		for dr in range(-1, 2):
			if _solid[_cell_at(col + dc, row + dr)] >= 0:
				return false
	return true


func _add_obstacle(x: float, z: float, r: float) -> void:
	var index := _ox.size()
	_ox.append(x)
	_oz.append(z)
	_or.append(r)
	var col := int((x + half.x) / CELL)
	var row := int((z + half.y) / CELL)
	for dc in range(-1, 2):
		for dr in range(-1, 2):
			_solid[_cell_at(col + dc, row + dr)] = index


## Buildings or cliffs just outside the limits. The north side can be tall because
## the camera looks toward it; the south side stays low so it never hides the car.
func _build_walls(theme: Dictionary, rng: RandomNumberGenerator) -> void:
	var wall: Dictionary = theme["wall"]
	var heights: Array = wall["height"]
	var transforms: Array = []
	var colors: Array = []
	for side in ["north", "south", "east", "west"]:
		var along_x: bool = side == "north" or side == "south"
		var span: float = half.x + WALL_DEPTH if along_x else half.y
		var at := -span
		while at < span:
			var h: float = SOUTH_WALL_HEIGHT if side == "south" else rng.randf_range(heights[0], heights[1])
			var seg := rng.randf_range(WALL_SEGMENT * 0.8, WALL_SEGMENT * 1.3)
			var out: float = (half.y if along_x else half.x) + WALL_DEPTH * 0.5
			var sign_out := -1.0 if side == "north" or side == "west" else 1.0
			var pos := Vector3(at + seg * 0.5, h * 0.5, sign_out * out) if along_x else Vector3(sign_out * out, h * 0.5, at + seg * 0.5)
			var sc := Vector3(seg + 0.4, h, WALL_DEPTH) if along_x else Vector3(WALL_DEPTH, h, seg + 0.4)
			transforms.append(Transform3D(Basis().scaled(sc), pos))
			colors.append(_pick_color(wall, rng))
			at += seg
	_add_multimesh(wall["mesh"], transforms, colors, wall.get("emissive", false))


func _pick_color(kind: Dictionary, rng: RandomNumberGenerator) -> Color:
	var col: Color = kind["colors"][rng.randi() % kind["colors"].size()]
	return col.lightened(rng.randf_range(0.0, 0.1))


func _add_multimesh(mesh: Mesh, transforms: Array, colors: Array, emissive: bool) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	if emissive:
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 0.25
		mat.emission = Color(1, 1, 1)
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## Per-biome look. Obstacles stay under about 2.5 m so they never cover the action;
## anything big belongs in "wall". All meshes are unit sized and scaled from here.
func _theme(theme: String) -> Dictionary:
	var box := BoxMesh.new()
	var rock := SphereMesh.new()
	rock.radial_segments = 6
	rock.rings = 3
	var spike := PrismMesh.new()
	var cyl := CylinderMesh.new()
	cyl.radial_segments = 6
	cyl.height = 1.0
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.5
	var flat := CylinderMesh.new()
	flat.radial_segments = 8
	flat.height = 0.04
	flat.top_radius = 0.5
	flat.bottom_radius = 0.5
	match theme:
		"neon":
			return {
				"obstacles": [
					{"mesh": box, "scale": Vector3(2.8, 1.4, 2.8), "radius": 1.8,
						"colors": [Color(0.15, 0.1, 0.25), Color(0.1, 0.12, 0.2), Color(0.2, 0.1, 0.2)]},
					{"mesh": cyl, "scale": Vector3(1.2, 2.5, 1.2), "radius": 0.7, "emissive": true,
						"colors": [Color(0.1, 1.0, 0.95), Color(1.0, 0.2, 0.75), Color(1.0, 0.85, 0.2)]},
				],
				"decor": {"mesh": flat, "scale": Vector3(3, 1, 3), "emissive": true,
					"colors": [Color(0.15, 0.5, 0.5), Color(0.5, 0.12, 0.4)]},
				"wall": {"mesh": box, "height": [12.0, 26.0], "emissive": true,
					"colors": [Color(0.13, 0.08, 0.22), Color(0.08, 0.1, 0.2), Color(0.18, 0.08, 0.2)]},
			}
		"frost":
			return {
				"obstacles": [
					{"mesh": spike, "scale": Vector3(2.4, 2.4, 2.4), "radius": 1.2,
						"colors": [Color(0.7, 0.85, 1.0), Color(0.85, 0.95, 1.0), Color(0.55, 0.7, 0.9)]},
					{"mesh": rock, "scale": Vector3(3.6, 1.3, 3.6), "radius": 1.7,
						"colors": [Color(0.95, 0.97, 1.0)]},
				],
				"decor": {"mesh": flat, "scale": Vector3(5, 1, 5), "colors": [Color(0.8, 0.88, 0.98)]},
				"wall": {"mesh": box, "height": [6.0, 12.0],
					"colors": [Color(0.75, 0.86, 0.98), Color(0.62, 0.76, 0.92), Color(0.88, 0.94, 1.0)]},
			}
		"toxic":
			return {
				"obstacles": [
					{"mesh": cyl, "scale": Vector3(2.4, 2.2, 2.4), "radius": 1.2,
						"colors": [Color(0.25, 0.2, 0.12), Color(0.3, 0.25, 0.15)]},
					{"mesh": rock, "scale": Vector3(3.2, 1.2, 3.2), "radius": 1.6,
						"colors": [Color(0.3, 0.32, 0.2), Color(0.25, 0.3, 0.16)]},
				],
				"decor": {"mesh": flat, "scale": Vector3(5, 1, 5),
					"colors": [Color(0.3, 0.46, 0.12), Color(0.24, 0.4, 0.1)]},
				"wall": {"mesh": rock, "height": [7.0, 13.0],
					"colors": [Color(0.22, 0.2, 0.14), Color(0.18, 0.22, 0.12)]},
			}
		_:
			return {
				"obstacles": [
					{"mesh": rock, "scale": Vector3(3.4, 2.0, 3.4), "radius": 1.7,
						"colors": [Color(0.55, 0.35, 0.22), Color(0.45, 0.3, 0.2), Color(0.62, 0.42, 0.28)]},
					{"mesh": box, "scale": Vector3(3.2, 1.2, 1.8), "radius": 1.7,
						"colors": [Color(0.35, 0.22, 0.16), Color(0.42, 0.34, 0.3)]},
					{"mesh": cyl, "scale": Vector3(1.0, 2.5, 1.0), "radius": 0.6,
						"colors": [Color(0.3, 0.55, 0.25), Color(0.25, 0.45, 0.2)]},
				],
				"decor": {"mesh": flat, "scale": Vector3(4, 1, 4), "colors": [Color(0.66, 0.46, 0.28), Color(0.56, 0.38, 0.24)]},
				"wall": {"mesh": rock, "height": [7.0, 14.0],
					"colors": [Color(0.5, 0.33, 0.22), Color(0.42, 0.28, 0.2), Color(0.58, 0.4, 0.27)]},
			}
