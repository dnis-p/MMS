class_name Tools
extends Node3D
## Digging tools work on their own, like Vampire Survivors weapons. Owned tools and boosts, their
## firing, and the level-up choices. All numbers are in Defs.TOOLS and Defs.BOOSTS.

const MAX_BOMBS := 6

var run: Run
## tool id -> {"level": int, "timer": float}
var owned := {}
var order: Array[String] = []
## boost id -> level
var boosts := {}
var boost_order: Array[String] = []

var _slash: MeshInstance3D
var _slash_mat: StandardMaterial3D
var _slash_left := 0.0
var _saws: Array[MeshInstance3D] = []
var _saw_angle := 0.0
var _bombs: Array[MeshInstance3D] = []
var _bomb_from: Array[Vector3] = []
var _bomb_to: Array[Vector3] = []
var _bomb_t: Array[float] = []
var _drill_left := 0.0
var _drill_sound := false


func _ready() -> void:
	_build_slash()
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


## A flat fan of unit radius, pointing along -Z, spanning the shovel's angle.
func _build_slash() -> void:
	var half: float = Defs.TOOLS["shovel"]["arc"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 14
	for k in steps:
		var a := lerpf(-half, half, float(k) / steps)
		var b := lerpf(-half, half, float(k + 1) / steps)
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a), 0, -cos(a)))
		st.add_vertex(Vector3(sin(b), 0, -cos(b)))
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


# --- stats -------------------------------------------------------------------------

func level(id: String) -> int:
	return int(owned[id]["level"]) if owned.has(id) else 0


func boost(id: String) -> int:
	return int(boosts.get(id, 0))


func _bonus(id: String) -> float:
	return 1.0 + float(Defs.BOOSTS[id]["value"]) * boost(id)


## A stat of a tool at its level with boosts applied. Keys: dmg, size, cd.
func dmg(id: String) -> float:
	var t: Dictionary = Defs.TOOLS[id]
	return t["dmg"] * (1.0 + t["dmg_up"] * (level(id) - 1)) * _bonus("power")


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
		"score":
			run.add_score(Defs.FILLER_SCORE)


func level_up_options(n: int) -> Array:
	var pool: Array = []
	for id in Defs.TOOLS:
		if level(id) < Defs.MAX_TOOL_LEVEL:
			pool.append(_tool_option(id))
			if owned.has(id):
				pool.append(_tool_option(id))  # favour what you already have
	for id in Defs.BOOSTS:
		if boost(id) < Defs.MAX_BOOST_LEVEL:
			pool.append(_boost_option(id))
	run.shuffle(pool)
	var picked: Array = []
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
					w["timer"] = cooldown(id)
			"drill":
				w["timer"] = cooldown(id)
				_drill(mine, p, at)
			"bombs":
				if _throw_bomb(at):
					w["timer"] = cooldown(id)
			"pulse":
				w["timer"] = cooldown(id)
				_pulse(mine, at)
			"beam":
				w["timer"] = cooldown(id)
				_beam(mine, p, at)
	_update_saws(delta, mine, at)
	_update_bombs(delta, mine, at)
	_update_slash(delta, p)
	_drill_left -= delta
	if _drill_sound != (_drill_left > 0.0):
		_drill_sound = not _drill_sound
		if _drill_sound:
			Sfx.rev_start()
			Sfx.rev_set(0.5)
		else:
			Sfx.rev_stop()


## The shovel fans out in front of you and only swings when there is something to hit.
func _swing(mine: Mine, p: Player, at: Vector3) -> bool:
	var half: float = Defs.TOOLS["shovel"]["arc"]
	var r := size("shovel")
	if not mine.arc_has_cubes(at, p.heading, r, half):
		return false
	mine.hit_arc(at, p.heading, r, half, dmg("shovel"), Defs.WORLD["swing_wave"])
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
	var hit := mine.hit_line(at + p.heading * 0.5, p.heading, size("drill"), 0.5, dmg("drill"), 200.0)
	if hit > 0:
		_drill_left = 0.12
		run.fx.shake(0.015)


func _update_saws(delta: float, mine: Mine, at: Vector3) -> void:
	var lvl := level("saws")
	var count := 0 if lvl == 0 else mini(2 + lvl / 2, _saws.size())
	var t: Dictionary = Defs.TOOLS["saws"]
	var orbit := size("saws")
	_saw_angle += float(t["spin"]) * delta
	var tick := false
	if lvl > 0:
		if owned["saws"]["timer"] <= 0.0:
			owned["saws"]["timer"] = cooldown("saws")
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


## Thrown at solid rock nearby. Returns false if there is none.
func _throw_bomb(at: Vector3) -> bool:
	var range_m: float = Defs.TOOLS["bombs"]["throw"]
	for k in 8:
		var a := run.rng.randf() * TAU
		var to := at + Vector3(cos(a), 0, sin(a)) * run.rng.randf_range(range_m * 0.5, range_m)
		if run.mine.kind_at(to) == 0:
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
			run.fx.ring(c, r, Color(1.0, 0.65, 0.25, 0.9), 0.3)
			run.fx.shake(0.22 if c.distance_to(at) < 20.0 else 0.05)
			Sfx.play("boom", -7.0)
			continue
		_bombs[b].global_position = _bomb_from[b].lerp(_bomb_to[b], t) + Vector3(0, sin(t * PI) * 3.5, 0)


func _pulse(mine: Mine, at: Vector3) -> void:
	var r := size("pulse")
	if mine.hit_circle(at, r, dmg("pulse"), at, Defs.WORLD["blast_wave"]) > 0:
		run.fx.ring(at, r, Color(0.6, 0.8, 1.0, 0.9), 0.35)
		run.fx.shake(0.12)
		Sfx.play("thud", -5.0, 1.4)


func _beam(mine: Mine, p: Player, at: Vector3) -> void:
	var length := size("beam")
	if mine.hit_line(at, p.heading, length, 0.6, dmg("beam"), 70.0) > 0:
		run.fx.bolt(at + Vector3(0, 0.9, 0), at + p.heading * length + Vector3(0, 0.9, 0), Color(0.5, 1.0, 0.8))
		run.fx.shake(0.08)
		Sfx.play("zap", -8.0, 0.7)
