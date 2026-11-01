class_name Mine
extends Node3D
## The world: one flat layer of small cubes. Cubes are plain data in packed arrays and are drawn with
## one MultiMesh per chunk, so a hit only touches the cubes it changes. Hits can be queued with a
## delay, which is what makes a swing or a chain reaction ripple outward instead of popping at once.
## Fog of war lives here too. Open cells you have broken or seen stay known for good, and a dark sheet
## just above the rock covers everything else in rings that thicken with distance from them, whatever
## is underneath. Tools can only hit cubes near enough to what you know.

const CELL := 0.5
const SIZE := 320  # cubes per side
const CHUNK := 32
const HEIGHT := 0.7
const FLASH := 0.13  # seconds a hit cube stays white and shaking
const FADE := 8  # how far a cell of the fog map moves per sight update, so the rings glide instead of jump
const FOG_SHADER := """
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;
uniform sampler2D fog_map : filter_nearest, repeat_disable;
uniform float bands[8];
uniform float band_width = 1.3;
uniform float rim = 0.7;
uniform float cube_steps = 25.5;
uniform vec3 digger;
uniform float light = 10.0;
uniform float world_size = 160.0;
uniform float cell = 0.5;
uniform float tint = 0.1;
uniform float dim = 0.4;
uniform float haze = 0.15;
uniform vec3 dark_color : source_color;
uniform vec3 tint_color : source_color;
uniform vec3 haze_color : source_color;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 center = (floor(wpos.xz / cell) + 0.5) * cell;  // everything per cube, so the fog follows the grid
	float cubes = texture(fog_map, center / world_size + 0.5).r * cube_steps;
	float fog = bands[min(int(max(cubes + 0.01 - rim, 0.0) / band_width), 7)];
	float d = distance(center, digger.xz);
	float clear = (1.0 - fog) * (1.0 - dim * smoothstep(light * 0.45, light, d));
	float cool = tint * min(fog * 4.0, 1.0);
	float dust = haze * smoothstep(light * 0.15, light, d) * (1.0 - fog);
	ALPHA = 1.0 - clear * (1.0 - cool - dust);
	ALBEDO = (dark_color * (1.0 - clear) + clear * (tint_color * cool + haze_color * dust)) / max(ALPHA, 0.001);
}
"""
## World-anchored dirt, so the ground visibly slides past as you move: stains, grain and stones that
## catch the light of the digger's lamp.
const FLOOR_SHADER := """
shader_type spatial;
uniform vec3 dirt_color : source_color;
uniform vec3 stain_color : source_color;
uniform vec3 stone_color : source_color;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 p = floor(wpos.xz * 8.0) / 8.0;  // chunky, to go with the cubes
	float stains = smoothstep(0.35, 0.65, noise(p * 0.5) * 0.65 + noise(p * 1.6) * 0.35);
	float grain = hash(p);
	vec3 color = mix(dirt_color, stain_color, stains) * (0.82 + 0.36 * grain);
	color *= 1.0 - 0.5 * step(abs(noise(p * 0.8 + 3.0) - 0.5), 0.016);  // cracks
	vec2 cell = floor(p / 1.3);
	vec2 at = p / 1.3 - cell - 0.25 - 0.5 * vec2(hash(cell), hash(cell + 7.0));
	float pick = hash(cell + 3.0);
	float size = (0.05 + 0.15 * pick * pick) * step(0.3, hash(cell + 5.0));
	float bent = length(at) + (noise(p * 5.0 + cell) - 0.5) * 0.1;
	float stone = step(bent, size);
	color *= 1.0 - 0.5 * step(length(at - vec2(0.0, 0.04)), size);
	color = mix(color, stone_color * (0.85 + 0.3 * grain - 2.0 * at.y), stone);
	ALBEDO = color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.2;
	NORMAL_MAP = vec3(at / max(size, 0.001) * 0.4 * stone + 0.5, 1.0);
}
"""
const HIDDEN := Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3.ZERO)
const STEP := 10  # one cube of distance in the fog map, straight; a diagonal costs 14, about the true distance
const DIAGONAL := 14
const AROUND: Array[int] = [-1, 1, -SIZE, SIZE, -SIZE - 1, -SIZE + 1, SIZE - 1, SIZE + 1]

var run: Run
var nests: Array = []  # [center, radius] of each pocket that holds sleeping enemies
var heart_pos := Vector3.ZERO
var heart_left := 1.0  # share of health left in the Heart's weakest cube
var lifts: Array[Vector3] = []
var kind := PackedByteArray()  # index into Defs.CUBES, 0 = empty
var hp := PackedFloat32Array()
var _color := PackedColorArray()
var _heat := PackedFloat32Array()
var _hot := PackedInt32Array()
var _mm: Array[MultiMesh] = []
var _hp_of: Array[float] = []
var _q_time := PackedFloat32Array()
var _q_cell := PackedInt32Array()
var _q_dmg := PackedFloat32Array()
var _known := PackedByteArray()  # how far a cell is from anything you know, in STEPs; 0 = known
var _shown := PackedByteArray()  # the same as drawn, moving toward _known
var _fresh := PackedInt32Array()  # newly known cells whose surroundings aren't updated yet
var _moving := PackedInt32Array()  # cells where _shown hasn't caught up
var _farthest: int = int((Defs.WORLD["fog_rim"] + Defs.WORLD["fog_band"] * 7.0 + 1.0) * STEP)
var _reach: int = int(Defs.WORLD["fog_reach"] * STEP)
var _fog_image: Image
var _fog_texture: ImageTexture
var _fog: MeshInstance3D
var _fog_mat: ShaderMaterial


func _ready() -> void:
	kind.resize(SIZE * SIZE)
	hp.resize(SIZE * SIZE)
	_color.resize(SIZE * SIZE)
	_heat.resize(SIZE * SIZE)
	for d in Defs.CUBES:
		_hp_of.append(float(d.get("hp", 0.0)))
	var cube := BoxMesh.new()
	cube.size = Vector3(CELL, HEIGHT, CELL)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.8
	var chunks := SIZE / CHUNK
	var span := CHUNK * CELL
	for z in chunks:
		for x in chunks:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.mesh = cube
			mm.instance_count = CHUNK * CHUNK
			_mm.append(mm)
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.material_override = mat
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.custom_aabb = AABB(Vector3.ZERO, Vector3(span, HEIGHT + 1.0, span))
			mmi.position = Vector3((x - chunks * 0.5) * span, 0, (z - chunks * 0.5) * span)
			add_child(mmi)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2.ONE * (SIZE * CELL + 40.0)
	var floor_shader := Shader.new()
	floor_shader.code = FLOOR_SHADER
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = floor_shader
	floor_mat.set_shader_parameter("dirt_color", Color(0.17, 0.125, 0.1))
	floor_mat.set_shader_parameter("stain_color", Color(0.095, 0.075, 0.07))
	floor_mat.set_shader_parameter("stone_color", Color(0.25, 0.22, 0.2))
	var plane := MeshInstance3D.new()
	plane.mesh = floor_mesh
	plane.material_override = floor_mat
	add_child(plane)
	_build_fog()


## A sheet level with the top of the rock: it covers the rock, the floor and whatever lies on it, so
## nothing else needs to know about the fog.
func _build_fog() -> void:
	_known.resize(SIZE * SIZE)
	_shown.resize(SIZE * SIZE)
	forget()
	_fog_image = Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_R8, _shown)
	_fog_texture = ImageTexture.create_from_image(_fog_image)
	var w := Defs.WORLD
	var shader := Shader.new()
	shader.code = FOG_SHADER
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = shader
	_fog_mat.set_shader_parameter("fog_map", _fog_texture)
	_fog_mat.set_shader_parameter("bands", PackedFloat32Array(w["fog_bands"]))
	_fog_mat.set_shader_parameter("band_width", w["fog_band"])
	_fog_mat.set_shader_parameter("rim", w["fog_rim"])
	_fog_mat.set_shader_parameter("cube_steps", 255.0 / STEP)
	_fog_mat.set_shader_parameter("light", w["light"])
	_fog_mat.set_shader_parameter("world_size", SIZE * CELL)
	_fog_mat.set_shader_parameter("cell", CELL)
	_fog_mat.set_shader_parameter("tint", w["fog_tint"])
	_fog_mat.set_shader_parameter("dim", w["fog_dim"])
	_fog_mat.set_shader_parameter("haze", w["haze"])
	_fog_mat.set_shader_parameter("dark_color", Color8(3, 6, 12))
	_fog_mat.set_shader_parameter("tint_color", Color8(80, 125, 190))
	_fog_mat.set_shader_parameter("haze_color", Color(0.3, 0.24, 0.2))
	var sheet := PlaneMesh.new()
	sheet.size = Vector2.ONE * (SIZE * CELL + 60.0)
	_fog = MeshInstance3D.new()
	_fog.mesh = sheet
	_fog.material_override = _fog_mat
	_fog.position.y = HEIGHT + 0.02
	_fog.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fog)
	_fog.visible = Options.fog


func generate(rng: RandomNumberGenerator) -> void:
	var warp := _noise(rng, 0.03)
	var grain := _noise(rng, 0.13)
	var caves := _noise(rng, 0.07)
	var ore := _noise(rng, 0.22)
	for z in SIZE:
		for x in SIZE:
			var c := x + z * SIZE
			var p := Vector2(_world(x), _world(z))
			var k := _pick(x, z, p, warp, grain, caves, ore)
			kind[c] = k
			hp[c] = _hp_of[k]
			_heat[c] = 0.0
	_hot.clear()
	_q_time.clear()
	_q_cell.clear()
	_q_dmg.clear()
	_scatter_geodes(rng)
	_scatter_gas(rng)
	_dig_nests(rng)
	_open_lifts(rng)
	_place_heart(rng)
	forget()
	for c in SIZE * SIZE:
		_color[c] = _tint(c)
		hp[c] *= 0.75 + 0.5 * fmod(c * 0.7548776662, 1.0)  # so one swing doesn't pop a whole flat front
		_draw_cube(c)


func _noise(rng: RandomNumberGenerator, frequency: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.seed = rng.randi()
	n.frequency = frequency
	return n


func _pick(x: int, z: int, p: Vector2, warp: FastNoiseLite, grain: FastNoiseLite, caves: FastNoiseLite, ore: FastNoiseLite) -> int:
	var w := Defs.WORLD
	if x < 2 or z < 2 or x >= SIZE - 2 or z >= SIZE - 2:
		return Defs.BEDROCK
	var dist := p.length()
	if dist < w["start_clear"]:
		return 0
	if caves.get_noise_2dv(p) > w["cave_at"]:
		return 0
	var band := band_at(dist + warp.get_noise_2dv(p) * w["band_warp"])
	var b: Dictionary = Defs.BANDS[band]
	if ore.get_noise_2dv(p) > w["ore_at"]:
		return b["ore"]
	return b["rock"][0 if grain.get_noise_2dv(p) < 0.0 else 1]


## Blobs of crystal, which go off as one chain reaction.
func _scatter_geodes(rng: RandomNumberGenerator) -> void:
	var w := Defs.WORLD
	for k in w["geodes"]:
		var a := rng.randf() * TAU
		var dist := rng.randf_range(w["start_clear"] * 2.0, SIZE * CELL * 0.48)
		var cx := cell_of(cos(a) * dist)
		var cz := cell_of(sin(a) * dist)
		var r := rng.randi_range(w["geode_min"], w["geode_max"])
		for z in range(cz - r, cz + r + 1):
			for x in range(cx - r, cx + r + 1):
				var c := x + z * SIZE
				if x >= 2 and z >= 2 and x < SIZE - 2 and z < SIZE - 2 and Vector2i(x - cx, z - cz).length_squared() <= r * r + rng.randi_range(-3, 3):
					kind[c] = Defs.CRYSTAL
					hp[c] = _hp_of[Defs.CRYSTAL]


## Small blobs that pass for plain rock until you know the colour.
func _scatter_gas(rng: RandomNumberGenerator) -> void:
	var t := Defs.THREATS
	for k in t["gas_blobs"]:
		var a := rng.randf() * TAU
		var dist := rng.randf_range(t["safe_start"], SIZE * CELL * 0.48)
		var cx := cell_of(cos(a) * dist)
		var cz := cell_of(sin(a) * dist)
		var r := rng.randi_range(1, 2)
		for z in range(cz - r, cz + r + 1):
			for x in range(cx - r, cx + r + 1):
				var c := x + z * SIZE
				if kind[c] != 0 and kind[c] != Defs.BEDROCK:
					kind[c] = Defs.GAS
					hp[c] = _hp_of[Defs.GAS]


func _dig_nests(rng: RandomNumberGenerator) -> void:
	var t := Defs.THREATS
	nests.clear()
	for k in t["nests"]:
		var a := rng.randf() * TAU
		var dist := rng.randf_range(t["safe_start"], SIZE * CELL * 0.46)
		var center := Vector3(cos(a) * dist, 0, sin(a) * dist)
		var r := rng.randf_range(t["nest_min"], t["nest_max"])
		nests.append([center, r])
		var cells := ceili(r / CELL)
		var cx := cell_of(center.x)
		var cz := cell_of(center.z)
		for z in range(cz - cells, cz + cells + 1):
			for x in range(cx - cells, cx + cells + 1):
				if Vector2i(x - cx, z - cz).length_squared() <= cells * cells:
					kind[x + z * SIZE] = 0


## One lift in the middle, the rest in small pockets spread around the mine.
func _open_lifts(rng: RandomNumberGenerator) -> void:
	var r := Defs.RUN
	lifts.clear()
	lifts.append(Vector3(0, 0, 2.6))
	var n: int = r["lifts"]
	for k in n:
		var a := TAU * k / n + rng.randf_range(-0.3, 0.3)
		var p := Vector3(cos(a), 0, sin(a)) * lerpf(r["lift_min"], r["lift_max"], (k % 3) / 2.0)
		_stamp(p, 4, 0)
		lifts.append(p)


func _place_heart(rng: RandomNumberGenerator) -> void:
	var a := rng.randf() * TAU
	heart_pos = Vector3(cos(a), 0, sin(a)) * Defs.RUN["heart_dist"]
	_stamp(heart_pos, Defs.RUN["heart_r"], Defs.HEART)


## Fills a round patch with one kind of cube.
func _stamp(center: Vector3, cells: int, k: int) -> void:
	var cx := cell_of(center.x)
	var cz := cell_of(center.z)
	for z in range(cz - cells, cz + cells + 1):
		for x in range(cx - cells, cx + cells + 1):
			if Vector2i(x - cx, z - cz).length_squared() <= cells * cells:
				var c := x + z * SIZE
				kind[c] = k
				hp[c] = _hp_of[k]


## Removes rock without it counting as your digging, for things that tunnel.
func carve(p: Vector3, r: float) -> void:
	for z in range(cell_of(p.z - r), cell_of(p.z + r) + 1):
		for x in range(cell_of(p.x - r), cell_of(p.x + r) + 1):
			if x < 2 or z < 2 or x >= SIZE - 2 or z >= SIZE - 2:
				continue
			var c := x + z * SIZE
			var k := kind[c]
			if k != 0 and k != Defs.BEDROCK and k != Defs.HEART:
				kind[c] = 0
				_draw_cube(c)
				run.debris.spray(pos_of(c), _color[c], 1, pos_of(c), 0.6)


func band_at(dist: float) -> int:
	return clampi(int(dist / Defs.WORLD["band_width"]), 0, Defs.BANDS.size() - 1)


# --- fog of war ----------------------------------------------------------------------

func set_fog(on: bool) -> void:
	_fog.visible = on


## Back to knowing nothing: fog everywhere.
func forget() -> void:
	_known.fill(_farthest)
	_shown.fill(_farthest)
	_fresh.clear()
	_moving.clear()


## Near enough to what you know to see and dig.
func can_see(c: int) -> bool:
	return not Options.fog or _known[c] < _reach


func can_see_at(p: Vector3) -> bool:
	var x := cell_of(p.x)
	var z := cell_of(p.z)
	return x >= 0 and z >= 0 and x < SIZE and z < SIZE and can_see(x + z * SIZE)


## Whether this spot itself has been opened or seen, not just lies near something that has.
func has_seen_at(p: Vector3) -> bool:
	var x := cell_of(p.x)
	var z := cell_of(p.z)
	return x >= 0 and z >= 0 and x < SIZE and z < SIZE and _known[x + z * SIZE] == 0


func light_at(p: Vector3) -> void:
	_fog_mat.set_shader_parameter("digger", p)


func _learn(c: int) -> void:
	if _known[c] == 0:
		return
	if _shown[c] == _known[c]:
		_moving.append(c)
	_known[c] = 0
	_fresh.append(c)


## Spreads what was just learned through the fog map, over rock and unseen caves alike. Cells only ever
## get closer to what you know, so this stops where nothing changes and a pop costs only a few cells.
func _spread_known() -> void:
	var head := 0
	while head < _fresh.size():
		var c := _fresh[head]
		head += 1
		var x := c % SIZE
		var z := c / SIZE
		if x < 1 or z < 1 or x >= SIZE - 1 or z >= SIZE - 1:
			continue
		var d := int(_known[c])
		for k in 8:
			var n: int = c + AROUND[k]
			var nd := d + (STEP if k < 4 else DIAGONAL)
			if nd < _known[n]:
				if _shown[n] == _known[n]:
					_moving.append(n)
				_known[n] = nd
				_fresh.append(n)
	_fresh.clear()


## Casts rays out from `from`: open ground in sight becomes known. They stop at rock, so what lies
## behind a wall stays unknown until you dig to it.
func scan_light(from: Vector3) -> void:
	var cx := cell_of(from.x)
	var cz := cell_of(from.z)
	var r := int(Defs.WORLD["light"] / CELL)
	var rays := ceili(TAU * r * 1.6)
	for k in rays:
		var a := TAU * k / rays
		var dx := cos(a)
		var dz := sin(a)
		var x := cx + 0.5
		var z := cz + 0.5
		for step in r:
			var ix := int(x)
			var iz := int(z)
			if ix < 0 or iz < 0 or ix >= SIZE or iz >= SIZE:
				break
			var c := ix + iz * SIZE
			if kind[c] != 0:
				break
			_learn(c)
			x += dx
			z += dz
	_spread_known()
	_draw_fog()


## Lets the drawn fog catch up, which is what makes the rings glide outward as you dig.
func _draw_fog() -> void:
	if _moving.is_empty():
		return
	for k in range(_moving.size() - 1, -1, -1):
		var c := _moving[k]
		_shown[c] = maxi(_shown[c] - FADE, _known[c])
		if _shown[c] == _known[c]:
			_moving[k] = _moving[_moving.size() - 1]
			_moving.resize(_moving.size() - 1)
	_fog_image.set_data(SIZE, SIZE, false, Image.FORMAT_R8, _shown)
	_fog_texture.update(_fog_image)


# --- coordinates -----------------------------------------------------------------

func _world(i: int) -> float:
	return (i - SIZE * 0.5 + 0.5) * CELL


func cell_of(v: float) -> int:
	return floori(v / CELL + SIZE * 0.5)


func pos_of(c: int) -> Vector3:
	return Vector3(_world(c % SIZE), HEIGHT * 0.5, _world(c / SIZE))


func clamp_inside(p: Vector3) -> Vector3:
	var edge := SIZE * CELL * 0.5 - 2.0
	return Vector3(clampf(p.x, -edge, edge), 0.0, clampf(p.z, -edge, edge))


func kind_at(p: Vector3) -> int:
	var x := cell_of(p.x)
	var z := cell_of(p.z)
	return kind[x + z * SIZE] if x >= 0 and z >= 0 and x < SIZE and z < SIZE else Defs.BEDROCK


# --- drawing -----------------------------------------------------------------------

func _tint(c: int) -> Color:
	var base: Color = Defs.CUBES[kind[c]].get("color", Color.BLACK)
	var j := fmod(c * 0.61803398875, 1.0)
	return base.lightened(j * 0.14) if j > 0.5 else base.darkened(j * 0.16)


func _draw_cube(c: int) -> void:
	var x := c % SIZE
	var z := c / SIZE
	var mm := _mm[x / CHUNK + (z / CHUNK) * (SIZE / CHUNK)]
	var i := (x % CHUNK) + (z % CHUNK) * CHUNK
	if kind[c] == 0:
		mm.set_instance_transform(i, HIDDEN)
		return
	mm.set_instance_transform(i, _rest(x, z))
	mm.set_instance_color(i, _worn(c))


func _rest(x: int, z: int) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3((x % CHUNK + 0.5) * CELL, HEIGHT * 0.5, (z % CHUNK + 0.5) * CELL))


## Damaged cubes stay darker, so you can see what is about to go.
func _worn(c: int) -> Color:
	return _color[c].darkened(clampf(1.0 - hp[c] / _hp_of[kind[c]], 0.0, 1.0) * 0.45)


func update(delta: float) -> void:
	if not _fresh.is_empty():
		_spread_known()
	for i in range(_q_time.size() - 1, -1, -1):
		_q_time[i] -= delta
		if _q_time[i] > 0.0:
			continue
		var c := _q_cell[i]
		var dmg := _q_dmg[i]
		var last := _q_time.size() - 1
		_q_time[i] = _q_time[last]
		_q_cell[i] = _q_cell[last]
		_q_dmg[i] = _q_dmg[last]
		_q_time.resize(last)
		_q_cell.resize(last)
		_q_dmg.resize(last)
		_apply(c, dmg)
	for i in range(_hot.size() - 1, -1, -1):
		var c := _hot[i]
		_heat[c] -= delta
		if _heat[c] <= 0.0 or kind[c] == 0:
			_heat[c] = 0.0
			_hot[i] = _hot[_hot.size() - 1]
			_hot.resize(_hot.size() - 1)
			_draw_cube(c)
			continue
		_draw_hot(c)


## Flashes white and rattles while the hit wears off.
func _draw_hot(c: int) -> void:
	var t := _heat[c] / FLASH
	var x := c % SIZE
	var z := c / SIZE
	var mm := _mm[x / CHUNK + (z / CHUNK) * (SIZE / CHUNK)]
	var i := (x % CHUNK) + (z % CHUNK) * CHUNK
	var form := _rest(x, z)
	var shake: float = Defs.WORLD["shake"] * t
	form.origin += Vector3(randf_range(-shake, shake), shake * 1.5, randf_range(-shake, shake))
	form.basis = Basis.IDENTITY.scaled(Vector3.ONE * (1.0 + 0.18 * t))
	mm.set_instance_transform(i, form)
	mm.set_instance_color(i, _worn(c).lerp(Color.WHITE, minf(t * 1.6, 1.0)))


# --- hitting -------------------------------------------------------------------------

## Damages one cube `delay` seconds from now.
func strike(c: int, dmg: float, delay: float) -> void:
	if kind[c] == 0:
		return
	if delay <= 0.0:
		_apply(c, dmg)
		return
	_q_time.append(delay)
	_q_cell.append(c)
	_q_dmg.append(dmg)


func _apply(c: int, dmg: float) -> void:
	var k := kind[c]
	if k == 0 or k == Defs.BEDROCK:
		return
	if k == Defs.HEART:
		dmg = minf(dmg, Defs.RUN["heart_hit"])
		heart_left = minf(heart_left, clampf((hp[c] - dmg) / _hp_of[k], 0.0, 1.0))
		run.on_heart_hit()
	hp[c] -= dmg
	if hp[c] <= 0.0:
		_pop(c)
		return
	if _heat[c] <= 0.0:
		_hot.append(c)
	_heat[c] = FLASH
	run.on_cube_hit(pos_of(c), k)


func _pop(c: int) -> void:
	var k := kind[c]
	kind[c] = 0
	_draw_cube(c)
	_learn(c)
	run.on_cube_popped(pos_of(c), k, _color[c])
	if Defs.CUBES[k].get("chain", false):
		for n in [c - 1, c + 1, c - SIZE, c + SIZE, c - SIZE - 1, c - SIZE + 1, c + SIZE - 1, c + SIZE + 1]:
			if kind[n] == k:
				strike(n, 1e9, Defs.WORLD["chain_delay"])


## Hits every cube in the circle. `wave` is how fast (m/s) the hit spreads from `from`; 0 = at once.
## Returns how many cubes were in it. `in_dark` also hits cubes you can't see.
func hit_circle(center: Vector3, r: float, dmg: float, from: Vector3, wave := 0.0, in_dark := false) -> int:
	var count := 0
	var r2 := r * r
	for z in range(maxi(cell_of(center.z - r), 0), mini(cell_of(center.z + r), SIZE - 1) + 1):
		var wz := _world(z)
		for x in range(maxi(cell_of(center.x - r), 0), mini(cell_of(center.x + r), SIZE - 1) + 1):
			var c := x + z * SIZE
			if kind[c] == 0 or not (in_dark or can_see(c)):
				continue
			var wx := _world(x)
			if (wx - center.x) * (wx - center.x) + (wz - center.z) * (wz - center.z) <= r2:
				count += 1
				strike(c, dmg, Vector2(wx - from.x, wz - from.z).length() / wave if wave > 0.0 else 0.0)
	return count


## Hits every cube inside a Fx ring of this radius and duration, each one as the ring reaches it.
## Seen or not: this goes through the fog.
func hit_ring(center: Vector3, r: float, dmg: float, duration: float) -> int:
	var count := 0
	for z in range(maxi(cell_of(center.z - r), 0), mini(cell_of(center.z + r), SIZE - 1) + 1):
		var dz := _world(z) - center.z
		for x in range(maxi(cell_of(center.x - r), 0), mini(cell_of(center.x + r), SIZE - 1) + 1):
			var c := x + z * SIZE
			if kind[c] == 0:
				continue
			var dx := _world(x) - center.x
			var d := sqrt(dx * dx + dz * dz)
			if d <= r:
				count += 1
				strike(c, dmg, Fx.ring_arrival(d, r, duration))
	return count


## Hits every cube in the fan: within `r` of `from`, within `half_angle` of `dir`.
func hit_arc(from: Vector3, dir: Vector3, r: float, half_angle: float, dmg: float, wave: float) -> int:
	return _arc(from, dir, r, half_angle, dmg, wave, true)


func arc_has_cubes(from: Vector3, dir: Vector3, r: float, half_angle: float) -> bool:
	return _arc(from, dir, r, half_angle, 0.0, 0.0, false) > 0


func _arc(from: Vector3, dir: Vector3, r: float, half_angle: float, dmg: float, wave: float, hit: bool) -> int:
	var count := 0
	var r2 := r * r
	var limit := cos(half_angle)
	for z in range(maxi(cell_of(from.z - r), 0), mini(cell_of(from.z + r), SIZE - 1) + 1):
		var dz := _world(z) - from.z
		for x in range(maxi(cell_of(from.x - r), 0), mini(cell_of(from.x + r), SIZE - 1) + 1):
			var c := x + z * SIZE
			if kind[c] == 0 or kind[c] == Defs.BEDROCK or not can_see(c):
				continue
			var dx := _world(x) - from.x
			var d2 := dx * dx + dz * dz
			if d2 > r2 or (d2 > 0.25 and dx * dir.x + dz * dir.z < limit * sqrt(d2)):
				continue
			count += 1
			if not hit:
				return count
			strike(c, dmg, sqrt(d2) / wave)
	return count


## Hits a straight strip of cubes and returns how many. `in_dark` also hits cubes you can't see.
func hit_line(from: Vector3, dir: Vector3, length: float, half_width: float, dmg: float, wave: float, in_dark := false) -> int:
	var count := 0
	var side := Vector3(-dir.z, 0, dir.x)
	var steps := int(length / CELL)
	var across := ceili(half_width / CELL)
	for s in steps:
		var along := s * CELL
		for w in range(-across, across + 1):
			var p := from + dir * along + side * (w * CELL)
			var x := cell_of(p.x)
			var z := cell_of(p.z)
			if x < 0 or z < 0 or x >= SIZE or z >= SIZE:
				continue
			var c := x + z * SIZE
			if kind[c] != 0 and (in_dark or can_see(c)):
				count += 1
				strike(c, dmg, along / wave)
	return count


# --- collision -----------------------------------------------------------------------

## Pushes a circle out of the cubes it overlaps.
func resolve(p: Vector3, r: float) -> Vector3:
	for k in 2:
		for z in range(cell_of(p.z - r), cell_of(p.z + r) + 1):
			for x in range(cell_of(p.x - r), cell_of(p.x + r) + 1):
				if x < 0 or z < 0 or x >= SIZE or z >= SIZE or kind[x + z * SIZE] == 0:
					continue
				var wx := _world(x)
				var wz := _world(z)
				var near := Vector2(clampf(p.x, wx - CELL * 0.5, wx + CELL * 0.5), clampf(p.z, wz - CELL * 0.5, wz + CELL * 0.5))
				var away := Vector2(p.x, p.z) - near
				var d2 := away.length_squared()
				if d2 <= 0.000001:  # pushed right inside a cube: out by the side it is nearest
					away = Vector2(p.x - wx, p.z - wz)
					p.x = wx + signf(away.x) * (CELL * 0.5 + r) if absf(away.x) >= absf(away.y) else p.x
					p.z = wz + signf(away.y) * (CELL * 0.5 + r) if absf(away.x) < absf(away.y) else p.z
				elif d2 < r * r:
					var d := sqrt(d2)
					p.x += away.x / d * (r - d)
					p.z += away.y / d * (r - d)
	return p
