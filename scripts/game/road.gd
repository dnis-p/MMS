class_name Road
extends Node3D
## The predetermined path for one stage: a meandering spline, a road mesh along
## it, roadside props, and a ground plane that follows the camera.

const HALF_WIDTH := 5.5
const LENGTH := 1900.0
const SEGMENT := 45.0

var curve := Curve3D.new()
var length := 0.0
var _ground: MeshInstance3D
var _ground_mat: ShaderMaterial

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
uniform float grid_strength = 0.0;
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
	vec2 p = mod(wpos.xz, 4096.0);
	float n = noise(p * 0.07) * 0.6 + noise(p * 0.4) * 0.4;
	vec3 c = mix(color_a.rgb, color_b.rgb, n);
	vec2 g = abs(fract(p / 6.0) - 0.5);
	float line = step(0.47, max(g.x, g.y)) * grid_strength;
	ALBEDO = mix(c, grid_color.rgb, line);
	EMISSION = grid_color.rgb * line * 0.8;
	ROUGHNESS = 1.0;
}
"""


func build(biome: Dictionary, rng: RandomNumberGenerator) -> void:
	for c in get_children():
		c.queue_free()
	_build_curve(rng)
	_build_road_mesh(biome)
	_build_ground(biome)
	_build_props(biome, rng)


func point_at(s: float) -> Vector3:
	return curve.sample_baked(clampf(s, 0.0, length))


func forward_at(s: float) -> Vector3:
	var a := point_at(s - 1.0)
	var b := point_at(s + 1.0)
	var f := b - a
	f.y = 0.0
	return f.normalized() if f.length_squared() > 0.0001 else Vector3.FORWARD


func follow(target: Vector3) -> void:
	if _ground:
		_ground.global_position = Vector3(snappedf(target.x, 4.0), -0.02, snappedf(target.z, 4.0))


func _build_curve(rng: RandomNumberGenerator) -> void:
	curve = Curve3D.new()
	curve.bake_interval = 0.5
	var p := Vector3.ZERO
	var heading := 0.0
	var count := int(LENGTH / SEGMENT) + 2
	for i in count:
		var dir := Vector3(sin(heading), 0.0, -cos(heading))
		curve.add_point(p, -dir * SEGMENT * 0.35, dir * SEGMENT * 0.35)
		p += dir * SEGMENT
		# The first stretch is straight so the stage starts calmly.
		if i > 1:
			heading = clampf(heading + rng.randf_range(-0.4, 0.4), -0.9, 0.9)
	length = curve.get_baked_length()


func _build_road_mesh(biome: Dictionary) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 2.0
	var s := 0.0
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var prev_v := 0.0
	var first := true
	while s <= length:
		var c := point_at(s)
		var right := forward_at(s).cross(Vector3.UP).normalized()
		var l := c - right * HALF_WIDTH + Vector3(0, 0.02, 0)
		var r := c + right * HALF_WIDTH + Vector3(0, 0.02, 0)
		if not first:
			_quad(st, prev_l, prev_r, l, r, prev_v, s)
		prev_l = l
		prev_r = r
		prev_v = s
		first = false
		s += step
	st.generate_normals()
	var mesh := st.commit()
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = ROAD_SHADER
	mat.shader = shader
	mat.set_shader_parameter("road_color", biome["road"])
	mat.set_shader_parameter("line_color", biome["line"])
	mat.set_shader_parameter("edge_color", biome["edge"])
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
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
	_ground_mat = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = GROUND_SHADER
	_ground_mat.shader = shader
	_ground_mat.set_shader_parameter("color_a", biome["ground_a"])
	_ground_mat.set_shader_parameter("color_b", biome["ground_b"])
	_ground_mat.set_shader_parameter("grid_color", biome["grid_color"])
	_ground_mat.set_shader_parameter("grid_strength", biome["grid"])
	_ground.material_override = _ground_mat
	_ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ground)


## Roadside decoration. Each biome gets two prop shapes scattered along both sides.
func _build_props(biome: Dictionary, rng: RandomNumberGenerator) -> void:
	var kinds := _prop_kinds(String(biome["props"]))
	for kind in kinds:
		var transforms: Array[Transform3D] = []
		var colors: Array[Color] = []
		var s := 0.0
		while s < length:
			s += rng.randf_range(kind["spacing"] * 0.5, kind["spacing"] * 1.5)
			var side := -1.0 if rng.randf() < 0.5 else 1.0
			var dist := HALF_WIDTH + rng.randf_range(kind["near"], kind["far"])
			var c := point_at(s)
			var right := forward_at(s).cross(Vector3.UP).normalized()
			var sc: Vector3 = kind["scale"] * rng.randf_range(0.6, 1.5)
			if kind.get("tall", false):
				sc.y *= rng.randf_range(0.6, 2.5)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(sc)
			var t := Transform3D(basis, c + right * side * dist + Vector3(0, sc.y * 0.5 * kind["lift"], 0))
			transforms.append(t)
			var col: Color = kind["colors"][rng.randi() % kind["colors"].size()]
			colors.append(col.lightened(rng.randf_range(-0.1, 0.1)))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = kind["mesh"]
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i])
			mm.set_instance_color(i, colors[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.85
		if kind.get("emissive", false):
			mat.emission_enabled = true
			mat.emission_energy_multiplier = 0.25
			mat.emission = Color(1, 1, 1)
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)


func _prop_kinds(theme: String) -> Array:
	var box := BoxMesh.new()
	var rock := SphereMesh.new()
	rock.radial_segments = 6
	rock.rings = 3
	var spike := PrismMesh.new()
	var cyl := CylinderMesh.new()
	cyl.radial_segments = 6
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.45
	match theme:
		"neon":
			return [
				{"mesh": box, "spacing": 9.0, "near": 6.0, "far": 30.0, "scale": Vector3(5, 10, 5), "tall": true, "lift": 1.0,
					"colors": [Color(0.15, 0.1, 0.25), Color(0.1, 0.12, 0.2), Color(0.2, 0.1, 0.2)]},
				{"mesh": cyl, "spacing": 14.0, "near": 1.5, "far": 2.5, "scale": Vector3(0.5, 5, 0.5), "lift": 1.0, "emissive": true,
					"colors": [Color(0.1, 1.0, 0.95), Color(1.0, 0.2, 0.75), Color(1.0, 0.85, 0.2)]},
			]
		"frost":
			return [
				{"mesh": spike, "spacing": 7.0, "near": 3.0, "far": 30.0, "scale": Vector3(1.5, 4, 1.5), "tall": true, "lift": 1.0,
					"colors": [Color(0.7, 0.85, 1.0), Color(0.85, 0.95, 1.0), Color(0.55, 0.7, 0.9)]},
				{"mesh": rock, "spacing": 10.0, "near": 2.0, "far": 25.0, "scale": Vector3(2.5, 1.2, 2.5), "lift": 0.5,
					"colors": [Color(0.95, 0.97, 1.0)]},
			]
		"toxic":
			return [
				{"mesh": cyl, "spacing": 8.0, "near": 3.0, "far": 28.0, "scale": Vector3(1.0, 6, 1.0), "tall": true, "lift": 1.0,
					"colors": [Color(0.25, 0.2, 0.12), Color(0.3, 0.25, 0.15)]},
				{"mesh": rock, "spacing": 9.0, "near": 2.0, "far": 25.0, "scale": Vector3(2.5, 0.6, 2.5), "lift": 0.3, "emissive": true,
					"colors": [Color(0.5, 1.0, 0.1), Color(0.35, 0.8, 0.1)]},
			]
		_:
			return [
				{"mesh": rock, "spacing": 7.0, "near": 2.0, "far": 30.0, "scale": Vector3(2.2, 1.6, 2.2), "lift": 0.5,
					"colors": [Color(0.55, 0.35, 0.22), Color(0.45, 0.3, 0.2), Color(0.62, 0.42, 0.28)]},
				{"mesh": cyl, "spacing": 12.0, "near": 2.0, "far": 25.0, "scale": Vector3(0.9, 3.5, 0.9), "tall": true, "lift": 1.0,
					"colors": [Color(0.3, 0.55, 0.25), Color(0.25, 0.45, 0.2)]},
			]
