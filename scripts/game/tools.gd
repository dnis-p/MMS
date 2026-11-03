class_name Tools
extends Node3D
## Digging tools work on their own, like Vampire Survivors weapons. Owned tools and boosts, their
## firing, and the level-up choices. All numbers are in Defs.TOOLS and Defs.BOOSTS.

const MAX_BOMBS := 6
const MAX_MOLES := 6
## The drill's strip: an outline of the cells it bites, with chevrons running forward.
const DRILL_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color;
uniform float glow = 0.0;
uniform float len = 4.0;
uniform float wide = 1.5;
uniform float scroll = 0.0;
void fragment() {
	vec2 m = vec2(abs(UV.x - 0.5) * wide, (0.5 - abs(UV.y - 0.5)) * len);  // metres from the centre line, and to the nearest end
	float edge = max(step(wide * 0.5 - 0.08, m.x), step(m.y, 0.08));
	float chevron = fract(UV.y * len / 0.8 - m.x * 0.6 - scroll);
	float dash = smoothstep(0.0, 0.1, chevron) * smoothstep(0.35, 0.25, chevron) * (1.0 - edge);
	float fade = 1.0 - 0.5 * UV.y;
	float light = max(edge, dash);  // outline and chevrons are pale, so they show on orange rock and white flashes
	ALBEDO = mix(tint.rgb * (1.0 - 0.6 * (1.0 - light)), vec3(1.0, 0.95, 0.85), light * (0.5 + 0.3 * glow));
	ALPHA = clamp(tint.a * (0.35 * fade + edge + 0.7 * dash * fade) * (0.7 + 0.3 * glow), 0.0, 1.0);
}
"""

var run: Run
## tool id -> {"level": int, "timer": float}
var owned := {}
var order: Array[String] = []
## boost id -> level
var boosts := {}
var boost_order: Array[String] = []
var evolved := {}  # tool id -> true

var _slash: MeshInstance3D
var _slash_mat: StandardMaterial3D
var _slash_left := 0.0
var _strip: MeshInstance3D
var _strip_mat: ShaderMaterial
var _strip_glow := 0.0
var _strip_scroll := 0.0
var _saws: Array[MeshInstance3D] = []
var _saw_angle := 0.0
var _bombs: Array[MeshInstance3D] = []
var _bomb_from: Array[Vector3] = []
var _bomb_to: Array[Vector3] = []
var _bomb_t: Array[float] = []
var _moles: Array[MeshInstance3D] = []
var _mole_to: Array[Vector3] = []


func _ready() -> void:
	_build_slash()
	_build_strip()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.5
	disc.bottom_radius = 0.5
	disc.height = 0.08
	disc.radial_segments = 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.88, 0.92)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.5, 0.55)
	for i in 6:
		var m := MeshInstance3D.new()
		m.mesh = disc
		m.material_override = mat
		m.visible = false
		add_child(m)
		_saws.append(m)
	var ball := SphereMesh.new()
	ball.radius = 0.3
	ball.height = 0.6
	ball.radial_segments = 8
	ball.rings = 4
	var bomb_mat := StandardMaterial3D.new()
	bomb_mat.albedo_color = Color(0.1, 0.1, 0.12)
	bomb_mat.emission_enabled = true
	bomb_mat.emission = Color(1.0, 0.35, 0.1)
	for i in MAX_BOMBS:
		var m := MeshInstance3D.new()
		m.mesh = ball
		m.material_override = bomb_mat
		m.visible = false
		add_child(m)
		_bombs.append(m)
		_bomb_from.append(Vector3.ZERO)
		_bomb_to.append(Vector3.ZERO)
		_bomb_t.append(-1.0)
	var pup := SphereMesh.new()
	pup.radius = 0.32
	pup.height = 0.5
	pup.radial_segments = 8
	pup.rings = 4
	var mole_mat := StandardMaterial3D.new()
	mole_mat.albedo_color = Defs.TOOLS["moles"]["color"]
	for i in MAX_MOLES:
		var m := MeshInstance3D.new()
		m.mesh = pup
		m.material_override = mole_mat
		m.visible = false
		add_child(m)
		_moles.append(m)
		_mole_to.append(Vector3.ZERO)


func _shovel_arc() -> float:
	return Defs.EVOLUTIONS["shovel"]["arc"] if evolved.has("shovel") else Defs.TOOLS["shovel"]["arc"]


## A flat fan of unit radius, pointing along -Z, spanning the shovel's angle.
func _build_slash() -> void:
	var half := _shovel_arc()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 14
	for k in steps:
		var a := lerpf(-half, half, float(k) / steps)
		var b := lerpf(-half, half, float(k + 1) / steps)
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a), 0, -cos(a)))
		st.add_vertex(Vector3(sin(b), 0, -cos(b)))
	if _slash:
		_slash.mesh = st.commit()
		return
	_slash = MeshInstance3D.new()
	_slash.mesh = st.commit()
	_slash_mat = StandardMaterial3D.new()
	_slash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_slash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_slash_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_slash.material_override = _slash_mat
	_slash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_slash.visible = false
	add_child(_slash)


## A flat rectangle one metre wide and long, from the origin along -Z.
func _build_strip() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
		st.set_uv(v)
		st.add_vertex(Vector3(v.x - 0.5, 0, -v.y))
	_strip = MeshInstance3D.new()
	_strip.mesh = st.commit()
	var shader := Shader.new()
	shader.code = DRILL_SHADER
	_strip_mat = ShaderMaterial.new()
	_strip_mat.shader = shader
	_strip_mat.render_priority = 2  # over the fog, which shares its height
	var c: Color = Defs.TOOLS["drill"]["color"]
	_strip_mat.set_shader_parameter("tint", Color(c, Defs.TOOLS["drill"]["strip"]))
	_strip.material_override = _strip_mat
	_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_strip.visible = false
	add_child(_strip)


# --- stats -------------------------------------------------------------------------

func level(id: String) -> int:
	return int(owned[id]["level"]) if owned.has(id) else 0


func boost(id: String) -> int:
	return int(boosts.get(id, 0))


func _bonus(id: String) -> float:
	return 1.0 + float(Defs.BOOSTS[id]["value"]) * boost(id)


## How much stronger this tool is than at level 1 without boosts. Enemies keep up with this, so what
## you bought in the shop stays an edge.
func power_of(id: String) -> float:
	return (1.0 + Defs.TOOLS[id]["dmg_up"] * (level(id) - 1)) * _bonus("power")


## A stat of a tool at its level with boosts applied. Keys: dmg, size, cd.
func dmg(id: String) -> float:
	var evolution: float = Defs.EVOLUTIONS[id]["dmg"] if evolved.has(id) else 1.0
	return Defs.TOOLS[id]["dmg"] * power_of(id) * evolution * (1.0 + Profile.bonus("power"))


func size(id: String) -> float:
	var t: Dictionary = Defs.TOOLS[id]
	return t["size"] * (1.0 + t["size_up"] * (level(id) - 1)) * _bonus("reach")


func cooldown(id: String) -> float:
	var t: Dictionary = Defs.TOOLS[id]
	return t["cd"] * pow(t["cd_up"], level(id) - 1) * pow(Defs.BOOSTS["haste"]["value"], boost("haste"))


# --- acquiring ---------------------------------------------------------------------

func add_tool(id: String) -> void:
	if owned.has(id):
		owned[id]["level"] = mini(Defs.MAX_TOOL_LEVEL, level(id) + 1)
		return
	owned[id] = {"level": 1, "timer": 0.2}
	order.append(id)


func add_boost(id: String) -> void:
	if boosts.has(id):
		boosts[id] = mini(Defs.MAX_BOOST_LEVEL, boost(id) + 1)
	else:
		boosts[id] = 1
		boost_order.append(id)
	run.apply_boosts()


func apply(option: Dictionary) -> void:
	match option["kind"]:
		"tool":
			add_tool(option["id"])
		"boost":
			add_boost(option["id"])
		"evolve":
			evolved[option["id"]] = true
			_build_slash()
			run.on_evolved(Defs.EVOLUTIONS[option["id"]]["name"])
		"score":
			run.add_score(Defs.FILLER_SCORE)


func level_up_options(n: int) -> Array:
	var pool: Array = []
	for id in Defs.TOOLS:
		if level(id) < Defs.MAX_TOOL_LEVEL and Profile.has_tool(id):
			pool.append(_tool_option(id))
			if owned.has(id):
				pool.append(_tool_option(id))  # favour what you already have
	for id in Defs.BOOSTS:
		if boost(id) < Defs.MAX_BOOST_LEVEL:
			pool.append(_boost_option(id))
	run.shuffle(pool)
	var picked: Array = _evolution_options()
	var seen := {}
	for o in pool:
		var key: String = o["kind"] + o["id"]
		if seen.has(key):
			continue
		seen[key] = true
		picked.append(o)
		if picked.size() >= n:
			break
	if picked.is_empty():
		picked.append({"kind": "score", "id": "", "title": "Lucky Find", "desc": "+%d score" % Defs.FILLER_SCORE, "hint": "",
			"level_text": "", "color": Color(1.0, 0.85, 0.3)})
	return picked


func _evolution_options() -> Array:
	var out: Array = []
	for id in Defs.EVOLUTIONS:
		var e: Dictionary = Defs.EVOLUTIONS[id]
		if not evolved.has(id) and level(id) >= Defs.MAX_TOOL_LEVEL and boost(e["boost"]) >= Defs.EVOLVE_BOOST:
			out.append({"kind": "evolve", "id": id, "title": e["name"], "desc": e["desc"], "hint": "%s + %s" % [Defs.TOOLS[id]["name"], Defs.BOOSTS[e["boost"]]["name"]],
				"level_text": "EVOLUTION", "color": Color(1.0, 0.4, 1.0)})
	return out


func _tool_option(id: String) -> Dictionary:
	var t: Dictionary = Defs.TOOLS[id]
	var lvl := level(id)
	return {"kind": "tool", "id": id, "title": t["name"], "desc": t["desc"] if lvl == 0 else "+%d%% damage, +%d%% size" % [roundi(t["dmg_up"] * 100.0), roundi(t["size_up"] * 100.0)],
		"hint": "", "level_text": "NEW" if lvl == 0 else "Lv %d > %d" % [lvl, lvl + 1], "color": t["color"]}


func _boost_option(id: String) -> Dictionary:
	var b: Dictionary = Defs.BOOSTS[id]
	var lvl := boost(id)
	return {"kind": "boost", "id": id, "title": b["name"], "desc": b["desc"], "hint": "",
		"level_text": "NEW" if lvl == 0 else "Lv %d > %d" % [lvl, lvl + 1], "color": b["color"]}


# --- digging -----------------------------------------------------------------------

func update(delta: float) -> void:
	var mine: Mine = run.mine
	var p: Player = run.player
	var at := p.global_position
	at.y = 0.0
	for id in order:
		var w: Dictionary = owned[id]
		w["timer"] -= delta
		if w["timer"] > 0.0:
			continue
		match id:
			"shovel":
				if _swing(mine, p, at):
					w["timer"] = Defs.restart(w["timer"], cooldown(id), delta)
			"drill":
				w["timer"] = Defs.restart(w["timer"], cooldown(id), delta)
				_drill(mine, p, at)
			"bombs":
				if _throw_bomb(at):
					w["timer"] = Defs.restart(w["timer"], cooldown(id), delta)
			"pulse":
				w["timer"] = Defs.restart(w["timer"], cooldown(id), delta)
				_pulse(mine, at)
			"beam":
				w["timer"] = Defs.restart(w["timer"], cooldown(id), delta)
				_beam(mine, p, at)
			"spark":
				w["timer"] = Defs.restart(w["timer"], cooldown(id) if _spark(mine, p, at) else 0.2, delta)
	_update_saws(delta, mine, at)
	_update_moles(delta, mine, at)
	_update_bombs(delta, mine, at)
	_update_slash(delta, p)
	_update_strip(delta, p)


## The shovel fans out in front of you and only swings when there is something to hit.
func _swing(mine: Mine, p: Player, at: Vector3) -> bool:
	var half := _shovel_arc()
	var r := size("shovel")
	var enemies: Enemies = run.enemies
	if not mine.arc_has_cubes(at, p.heading, r, half) and not enemies.arc_has_enemies(at, p.heading, r, half):
		return false
	mine.hit_arc(at, p.heading, r, half, dmg("shovel"), Defs.WORLD["swing_wave"])
	enemies.hit_arc(at, p.heading, r, half, dmg("shovel"))
	p.swing()
	_slash_left = 0.12
	_slash.visible = true
	_slash.scale = Vector3.ONE * r
	Sfx.play("swing", -9.0)
	run.kick(p.heading, 0.12)
	return true


func _update_slash(delta: float, p: Player) -> void:
	if _slash_left <= 0.0:
		return
	_slash_left -= delta
	_slash.global_position = p.global_position + Vector3(0, Mine.HEIGHT + 0.05, 0)
	_slash.global_rotation = Vector3(0, atan2(-p.heading.x, -p.heading.z), 0)
	_slash_mat.albedo_color = Color(1, 1, 1, 0.6 * maxf(_slash_left, 0.0) / 0.12)
	_slash.visible = _slash_left > 0.0


func _drill(mine: Mine, p: Player, at: Vector3) -> void:
	var from := at + p.heading * 0.5
	var width := _drill_width()
	if mine.hit_line(from, p.heading, size("drill"), width, dmg("drill"), 200.0) + run.enemies.hit_line(from, p.heading, size("drill"), width, dmg("drill")) > 0:
		run.fx.shake(0.015)
		_strip_glow = 1.0


## Half the width of the drill's strip, from the centre line to the last cubes it samples.
func _drill_width() -> float:
	return Defs.EVOLUTIONS["drill"]["width"] if evolved.has("drill") else 0.5


## Lays the strip over the cells the drill bites: hit_line samples every cell along its length and
## ceil(half width / cell) cells to each side, so the strip is half a cell wider on each side and starts half a cell back.
func _update_strip(delta: float, p: Player) -> void:
	_strip.visible = owned.has("drill")
	if not _strip.visible:
		return
	var steps := int(size("drill") / Mine.CELL)
	var wide := (2.0 * ceilf(_drill_width() / Mine.CELL) + 1.0) * Mine.CELL
	var long := steps * Mine.CELL
	_strip_glow = maxf(_strip_glow - delta * 6.0, 0.0)
	_strip_scroll += delta * float(Defs.TOOLS["drill"]["strip_speed"]) * (1.0 + _strip_glow)
	_strip.global_position = p.global_position * Vector3(1, 0, 1) + p.heading * (0.5 - Mine.CELL * 0.5) + Vector3(0, Mine.HEIGHT + 0.04, 0)
	_strip.global_rotation = Vector3(0, atan2(-p.heading.x, -p.heading.z), 0)
	_strip.scale = Vector3(wide, 1, long)
	_strip_mat.set_shader_parameter("glow", _strip_glow)
	_strip_mat.set_shader_parameter("len", long)
	_strip_mat.set_shader_parameter("wide", wide)
	_strip_mat.set_shader_parameter("scroll", _strip_scroll)


func _update_saws(delta: float, mine: Mine, at: Vector3) -> void:
	var lvl := level("saws")
	var count := 0 if lvl == 0 else mini(2 + lvl / 2, _saws.size())
	var t: Dictionary = Defs.TOOLS["saws"]
	var orbit := size("saws")
	_saw_angle += float(t["spin"]) * delta
	var tick := false
	if lvl > 0:
		if owned["saws"]["timer"] <= 0.0:
			owned["saws"]["timer"] = Defs.restart(owned["saws"]["timer"], cooldown("saws"), delta)
			tick = true
	for k in _saws.size():
		var m := _saws[k]
		m.visible = k < count
		if not m.visible:
			continue
		var a := _saw_angle + k * TAU / count
		var c := at + Vector3(cos(a), 0, sin(a)) * orbit
		m.global_position = c + Vector3(0, Mine.HEIGHT + 0.1, 0)
		m.rotation.y += delta * 25.0
		if tick:
			mine.hit_circle(c, t["cut"], dmg("saws"), c)
			run.enemies.hit_circle(c, t["cut"], dmg("saws"))


## Thrown at the rock you aim at, or at rock nearby. Returns false if there is none.
func _throw_bomb(at: Vector3) -> bool:
	var range_m: float = Defs.TOOLS["bombs"]["throw"]
	for k in 9:
		var a := run.rng.randf() * TAU
		var to := at + Vector3(cos(a), 0, sin(a)) * run.rng.randf_range(range_m * 0.5, range_m)
		if k == 0:
			to = at + (run.aim_point - at).limit_length(range_m)
		if run.mine.kind_at(to) == 0 or not run.mine.can_see_at(to):
			continue
		for b in MAX_BOMBS:
			if _bomb_t[b] < 0.0:
				_bomb_from[b] = at + Vector3(0, 1, 0)
				_bomb_to[b] = to
				_bomb_t[b] = 0.0
				_bombs[b].visible = true
				return true
	return false


func _update_bombs(delta: float, mine: Mine, at: Vector3) -> void:
	for b in MAX_BOMBS:
		if _bomb_t[b] < 0.0:
			continue
		_bomb_t[b] += delta / 0.45
		var t := _bomb_t[b]
		if t >= 1.0:
			_bomb_t[b] = -1.0
			_bombs[b].visible = false
			var c := _bomb_to[b]
			var r := size("bombs")
			mine.hit_circle(c, r, dmg("bombs"), c, Defs.WORLD["blast_wave"])
			run.enemies.hit_circle(c, r, dmg("bombs"))
			run.fx.ring(c, r, Color(1.0, 0.65, 0.25, 0.9), 0.3)
			run.fx.shake(0.22 if c.distance_to(at) < 20.0 else 0.05)
			Sfx.play("boom", -7.0)
			if evolved.has("bombs"):
				_cluster(mine, c, r)
			continue
		_bombs[b].global_position = _bomb_from[b].lerp(_bomb_to[b], t) + Vector3(0, sin(t * PI) * 3.5, 0)


func _cluster(mine: Mine, c: Vector3, r: float) -> void:
	var n: int = Defs.EVOLUTIONS["bombs"]["cluster"]
	for k in n:
		var a := TAU * k / n
		var q := c + Vector3(cos(a), 0, sin(a)) * r
		mine.hit_circle(q, r * 0.6, dmg("bombs"), c, Defs.WORLD["blast_wave"])
		run.enemies.hit_circle(q, r * 0.6, dmg("bombs"))
		run.fx.ring(q, r * 0.6, Color(1.0, 0.65, 0.25, 0.9), 0.3)


func _pulse(mine: Mine, at: Vector3) -> void:
	var r := size("pulse")
	var time: float = Defs.TOOLS["pulse"]["ring_time"]
	if mine.hit_ring(at, r, dmg("pulse"), time) + run.enemies.hit_ring(at, r, dmg("pulse"), time) > 0:
		run.fx.ring(at, r, Color(0.6, 0.8, 1.0, 0.9), time)
		run.fx.shake(0.12)
		Sfx.play("thud", -5.0, 1.4)


## Jumps from enemy to enemy, biting the rock under each. With no enemy in reach it bites rock ahead.
func _spark(mine: Mine, p: Player, at: Vector3) -> bool:
	var t: Dictionary = Defs.TOOLS["spark"]
	var e: Enemies = run.enemies
	var reach := size("spark")
	var up := Vector3(0, 0.9, 0)
	var last := at
	var done: Array[int] = []
	var hops: int = (t["hops"] + level("spark") / 2) * (Defs.EVOLUTIONS["spark"]["hops"] if evolved.has("spark") else 1)
	var i := e.nearest_awake(at, reach)
	if i < 0:
		var to := at + p.heading * run.rng.randf_range(reach * 0.3, reach * 0.6)
		if mine.hit_circle(to, t["bite"], dmg("spark"), to) == 0:
			return false
		run.fx.bolt(at + up, to + up, t["color"])
		Sfx.play("zap", -12.0, 1.3)
		return true
	while i >= 0 and done.size() < hops:
		done.append(i)
		var q := e.pos[i]
		run.fx.bolt(last + up, q + up, t["color"])
		mine.hit_circle(q, t["bite"], dmg("spark"), q)
		e.hit(i, dmg("spark"), last)
		last = q
		i = e.nearest_awake(q, reach * 0.6, done)
	Sfx.play("zap", -9.0, 1.3)
	return true


## Moles run to spots around you and bite what they pass, so side tunnels open by themselves.
func _update_moles(delta: float, mine: Mine, at: Vector3) -> void:
	var lvl := level("moles")
	var count := 0
	var tick := false
	if lvl > 0:
		count = mini(1 + lvl / 2 + (Defs.EVOLUTIONS["moles"]["extra"] if evolved.has("moles") else 0), MAX_MOLES)
		if owned["moles"]["timer"] <= 0.0:
			owned["moles"]["timer"] = Defs.restart(owned["moles"]["timer"], cooldown("moles"), delta)
			tick = true
	var t: Dictionary = Defs.TOOLS["moles"]
	var roam := size("moles")
	for k in MAX_MOLES:
		var m := _moles[k]
		m.visible = k < count
		if not m.visible:
			continue
		var p := Vector3(m.position.x, 0, m.position.z)
		if p.distance_to(_mole_to[k]) < 0.5 or _mole_to[k].distance_to(at) > roam * 1.3:
			var a := run.rng.randf() * TAU
			_mole_to[k] = at + Vector3(cos(a), 0, sin(a)) * run.rng.randf_range(roam * 0.4, roam)
			if p.distance_to(at) > roam * 1.5:
				p = at
		p = p.move_toward(_mole_to[k], float(t["speed"]) * delta)
		m.position = p + Vector3(0, Mine.HEIGHT + 0.2, 0)
		if tick:
			mine.hit_circle(p, t["bite"], dmg("moles"), p, 0.0, true)
			run.enemies.hit_circle(p, t["bite"], dmg("moles"))


func _beam(mine: Mine, p: Player, at: Vector3) -> void:
	var length := size("beam")
	if mine.hit_line(at, p.heading, length, 0.6, dmg("beam"), 70.0, true) + run.enemies.hit_line(at, p.heading, length, 0.6, dmg("beam")) > 0:
		run.fx.bolt(at + Vector3(0, 0.9, 0), at + p.heading * length + Vector3(0, 0.9, 0), Color(0.5, 1.0, 0.8))
		run.fx.shake(0.08)
		Sfx.play("zap", -8.0, 0.7)
