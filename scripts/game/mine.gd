class_name Mine
extends Node3D
## The world: one flat layer of small cubes. Cubes are plain data in packed arrays and are drawn with
## one MultiMesh per chunk, so a hit only touches the cubes it changes. Hits can be queued with a
## delay, which is what makes a swing or a chain reaction ripple outward instead of popping at once.
## Fog of war lives here too: rays from the digger decide what is lit, which fills a mask that a dark
## sheet just above the rock turns into darkness, and tools can only hit lit cubes.

const CELL := 0.5
const SIZE := 320  # cubes per side
const CHUNK := 32
const HEIGHT := 0.7
const FLASH := 0.13  # seconds a hit cube stays white and shaking
const FADE := 110  # how much of the 0-255 mask a cell changes per sight update, so edges fade in
const REVEAL_FADE := 5  # the same for rock lit up by breaking in the dark, which fades much slower
const FOG_SHADER := """
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;
uniform sampler2D mask : filter_linear, repeat_disable;
uniform vec3 digger;
uniform float light = 10.0;
uniform float world_size = 160.0;
uniform float haze = 0.4;
uniform vec3 dark_color : source_color;
uniform vec3 haze_color : source_color;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 seen = texture(mask, wpos.xz / world_size + 0.5).rg;
	float d = distance(wpos.xz, digger.xz);
	float lit = seen.r * (1.0 - smoothstep(light * 0.5, light, d));
	float see = max(lit, seen.g * seen.g * seen.g);
	float air = smoothstep(light * 0.15, light, d) * haze * step(0.001, see);
	ALBEDO = mix(dark_color, haze_color, see);
	ALPHA = 1.0 - see * (1.0 - air);
}
"""
const HIDDEN := Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3.ZERO)

var run: Run
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
var _lit := PackedInt32Array()  # the scan a cell was last lit in
var _scan := 0
var _mask := PackedByteArray()  # two bytes per cell: lit now, how bright it stays once seen
var _seen_level := 0  # that second byte for a place you remember; drawn cubed, see FOG_SHADER
var _revealed := PackedInt32Array()  # cells above that level, fading back down to it
var _mask_image: Image
var _mask_texture: ImageTexture
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
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.13, 0.1, 0.09)
	floor_mat.roughness = 1.0
	var plane := MeshInstance3D.new()
	plane.mesh = floor_mesh
	plane.material_override = floor_mat
	add_child(plane)
	_build_fog()


## A sheet level with the top of the rock: it covers the rock, the floor and whatever lies on it, so
## nothing else needs to know about the fog.
func _build_fog() -> void:
	_lit.resize(SIZE * SIZE)
	_mask.resize(SIZE * SIZE * 2)
	_mask_image = Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_RG8, _mask)
	_mask_texture = ImageTexture.create_from_image(_mask_image)
	var w := Defs.WORLD
	var shader := Shader.new()
	shader.code = FOG_SHADER
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = shader
	_fog_mat.set_shader_parameter("mask", _mask_texture)
	_fog_mat.set_shader_parameter("light", w["light"])
	_fog_mat.set_shader_parameter("world_size", SIZE * CELL)
	_seen_level = int(pow(w["memory"], 1.0 / 3.0) * 255.0)
	_fog_mat.set_shader_parameter("haze", w["haze"])
	_fog_mat.set_shader_parameter("dark_color", Color(0.012, 0.01, 0.014))
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


func band_at(dist: float) -> int:
	return clampi(int(dist / Defs.WORLD["band_width"]), 0, Defs.BANDS.size() - 1)


# --- fog of war ----------------------------------------------------------------------

func set_fog(on: bool) -> void:
	_fog.visible = on


func can_see(c: int) -> bool:
	return not Options.fog or _lit[c] == _scan


func can_see_at(p: Vector3) -> bool:
	var x := cell_of(p.x)
	var z := cell_of(p.z)
	return x >= 0 and z >= 0 and x < SIZE and z < SIZE and can_see(x + z * SIZE)


func light_at(p: Vector3) -> void:
	_fog_mat.set_shader_parameter("digger", p)


## Lights up one cell from afar: whatever breaks in the dark shows you what it opened.
func _reveal(c: int) -> void:
	var i := c * 2 + 1
	if _mask[i] <= _seen_level:
		_revealed.append(c)
	_mask[i] = 255


## Casts rays out from `from`. Light gets a few cubes into rock and then stops, so you can see into
## the wall in front of you and down open caves, but not through the mountain.
func scan_light(from: Vector3) -> void:
	_scan += 1
	var cx := cell_of(from.x)
	var cz := cell_of(from.z)
	var r := int(Defs.WORLD["light"] / CELL)
	var into: int = Defs.WORLD["see_into"]
	var rays := ceili(TAU * r * 1.6)
	for k in rays:
		var a := TAU * k / rays
		var dx := cos(a)
		var dz := sin(a)
		var x := cx + 0.5
		var z := cz + 0.5
		var solid := 0
		for step in r:
			var ix := int(x)
			var iz := int(z)
			if ix < 0 or iz < 0 or ix >= SIZE or iz >= SIZE:
				break
			var c := ix + iz * SIZE
			_lit[c] = _scan
			if kind[c] != 0:
				solid += 1
				if solid > into:
					break
			x += dx
			z += dz
	_paint_mask(cx, cz, r + 4)


func _paint_mask(cx: int, cz: int, r: int) -> void:
	for z in range(maxi(cz - r, 0), mini(cz + r, SIZE - 1) + 1):
		for x in range(maxi(cx - r, 0), mini(cx + r, SIZE - 1) + 1):
			var c := x + z * SIZE
			var i := c * 2
			var lit := _lit[c] == _scan
			var v := _mask[i]
			_mask[i] = mini(v + FADE, 255) if lit else maxi(v - FADE, 0)
			if lit and _mask[i + 1] < _seen_level:
				_mask[i + 1] = _seen_level
	for k in range(_revealed.size() - 1, -1, -1):
		var i := _revealed[k] * 2 + 1
		_mask[i] = maxi(_mask[i] - REVEAL_FADE, _seen_level)
		if _mask[i] == _seen_level:
			_revealed[k] = _revealed[_revealed.size() - 1]
			_revealed.resize(_revealed.size() - 1)
	_mask_image.set_data(SIZE, SIZE, false, Image.FORMAT_RG8, _mask)
	_mask_texture.update(_mask_image)


# --- coordinates -----------------------------------------------------------------

func _world(i: int) -> float:
	return (i - SIZE * 0.5 + 0.5) * CELL


func cell_of(v: float) -> int:
	return floori(v / CELL + SIZE * 0.5)


func pos_of(c: int) -> Vector3:
	return Vector3(_world(c % SIZE), HEIGHT * 0.5, _world(c / SIZE))


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
	hp[c] -= dmg
	if Options.fog and not can_see(c):
		_reveal(c)
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
	if Options.fog and not can_see(c):
		for n in [c - 1, c + 1, c - SIZE, c + SIZE, c - SIZE - 1, c - SIZE + 1, c + SIZE - 1, c + SIZE + 1]:
			_reveal(n)
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
				if d2 < r * r and d2 > 0.000001:
					var d := sqrt(d2)
					p.x += away.x / d * (r - d)
					p.z += away.y / d * (r - d)
	return p
