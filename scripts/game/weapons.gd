class_name Weapons
extends Node3D
## Owned weapons/passives, their auto-firing behaviour, and upgrade/evolution rolls.

var run: Node  # Run

## weapon id -> {"level": int, "timer": float, "evolved": bool}
var owned := {}
var order: Array[String] = []
## passive id -> level
var passives := {}
var passive_order: Array[String] = []

var _saws: Array[MeshInstance3D] = []
var _saw_angle := 0.0
var _tmp: Array = []
var _mine_side := 1.0


func _ready() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 0.6
	disc.bottom_radius = 0.6
	disc.height = 0.08
	disc.radial_segments = 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.88, 0.92)
	mat.metallic = 0.8
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.4, 0.45)
	for i in 8:
		var m := MeshInstance3D.new()
		m.mesh = disc
		m.material_override = mat
		m.visible = false
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		_saws.append(m)


# --- stats -------------------------------------------------------------------

func passive(id: String) -> int:
	return int(passives.get(id, 0))


func level(id: String) -> int:
	return int(owned[id]["level"]) if owned.has(id) else 0


func is_evolved(id: String) -> bool:
	return owned.has(id) and bool(owned[id]["evolved"])


func damage_mult() -> float:
	return float(run.player.def["might"]) * (1.0 + 0.1 * passive("hot"))


func cooldown_mult() -> float:
	return pow(0.92, passive("turbo"))


func area_mult() -> float:
	return 1.0 + 0.12 * passive("blast")


func display_name(id: String) -> String:
	var d: Dictionary = Defs.WEAPONS[id]
	return d["evo_name"] if is_evolved(id) else d["name"]


# --- acquiring -----------------------------------------------------------------

func add_weapon(id: String) -> void:
	if owned.has(id):
		owned[id]["level"] = mini(Defs.MAX_WEAPON_LEVEL, level(id) + 1)
		return
	owned[id] = {"level": 1, "timer": 0.3, "evolved": false}
	order.append(id)
	run.player.add_weapon_visual(id)


func add_passive(id: String) -> void:
	if passives.has(id):
		passives[id] = mini(Defs.MAX_PASSIVE_LEVEL, passive(id) + 1)
	else:
		passives[id] = 1
		passive_order.append(id)
	_apply_passive_stats()


func evolve(id: String) -> void:
	if owned.has(id):
		owned[id]["evolved"] = true


func can_evolve(id: String) -> bool:
	return owned.has(id) and level(id) >= Defs.MAX_WEAPON_LEVEL and not is_evolved(id) \
		and passives.has(Defs.WEAPONS[id]["evo"])


func _apply_passive_stats() -> void:
	var p: Player = run.player
	var old_max := p.max_hp
	p.max_hp = float(p.def["max_hp"]) * (1.0 + 0.12 * passive("plating"))
	p.hp += p.max_hp - old_max
	p.armor = float(p.def["armor"]) + passive("plating")
	p.pickup_radius = 3.8 * (1.0 + 0.35 * passive("magnet"))


func apply(option: Dictionary) -> void:
	match option["kind"]:
		"weapon":
			add_weapon(option["id"])
		"passive":
			add_passive(option["id"])
		"evolve":
			evolve(option["id"])
		"heal":
			run.heal(40.0)
		"score":
			run.add_score(500)


## Level-up choices: upgrades for owned items plus new items while slots remain.
func level_up_options(n: int) -> Array:
	var pool: Array = []
	for id in order:
		if level(id) < Defs.MAX_WEAPON_LEVEL:
			pool.append(_weapon_option(id))
			pool.append(_weapon_option(id))  # favour what you already have
	if order.size() < Defs.MAX_WEAPON_SLOTS:
		for id in Defs.WEAPONS:
			if not owned.has(id):
				pool.append(_weapon_option(id))
	for id in passive_order:
		if passive(id) < Defs.MAX_PASSIVE_LEVEL:
			pool.append(_passive_option(id))
	if passive_order.size() < Defs.MAX_PASSIVE_SLOTS:
		for id in Defs.PASSIVES:
			if not passives.has(id):
				pool.append(_passive_option(id))
	pool.shuffle()
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
		picked.append(_filler("heal"))
		picked.append(_filler("score"))
	return picked


## Salvage-crate contents: evolutions first, then upgrades of owned items only.
func crate_rewards(count: int) -> Array:
	var rewards: Array = []
	for id in order:
		if rewards.size() < count and can_evolve(id):
			rewards.append({"kind": "evolve", "id": id, "title": Defs.WEAPONS[id]["evo_name"],
				"desc": Defs.WEAPONS[id]["evo_desc"], "level_text": "EVOLVED!", "color": Defs.WEAPONS[id]["color"]})
	var sim := {}
	for id in order:
		sim["w" + id] = level(id)
	for id in passive_order:
		sim["p" + id] = passive(id)
	while rewards.size() < count:
		var choices: Array = []
		for id in order:
			if sim["w" + id] < Defs.MAX_WEAPON_LEVEL:
				choices.append(["w", id])
		for id in passive_order:
			if sim["p" + id] < Defs.MAX_PASSIVE_LEVEL:
				choices.append(["p", id])
		if choices.is_empty():
			rewards.append(_filler("heal" if rewards.size() % 2 == 0 else "score"))
			continue
		var c: Array = choices[randi() % choices.size()]
		var key: String = c[0] + c[1]
		if c[0] == "w":
			var o := _weapon_option(c[1], sim[key])
			sim[key] += 1
			o["level_text"] = "Lv %d" % sim[key]
			rewards.append(o)
		else:
			sim[key] += 1
			var o := _passive_option(c[1])
			o["level_text"] = "Lv %d" % sim[key]
			rewards.append(o)
	return rewards


## `lvl` overrides the current level, for previewing a later upgrade.
func _weapon_option(id: String, lvl := -1) -> Dictionary:
	var d: Dictionary = Defs.WEAPONS[id]
	if lvl < 0:
		lvl = level(id)
	var desc: String = d["desc"] if lvl == 0 else d["up"][lvl]
	var hint := "Evolves with %s" % Defs.PASSIVES[d["evo"]]["name"]
	return {"kind": "weapon", "id": id, "title": d["name"], "desc": desc, "hint": hint,
		"level_text": "NEW" if lvl == 0 else "Lv %d > %d" % [lvl, lvl + 1], "color": d["color"]}


func _passive_option(id: String) -> Dictionary:
	var d: Dictionary = Defs.PASSIVES[id]
	var lvl := passive(id)
	var hint := ""
	for wid in Defs.WEAPONS:
		if Defs.WEAPONS[wid]["evo"] == id:
			hint = "Evolves %s" % Defs.WEAPONS[wid]["name"] if hint == "" else hint + ", " + Defs.WEAPONS[wid]["name"]
	return {"kind": "passive", "id": id, "title": d["name"], "desc": d["desc"], "hint": hint,
		"level_text": "NEW" if lvl == 0 else "Lv %d > %d" % [lvl, lvl + 1], "color": d["color"]}


func _filler(kind: String) -> Dictionary:
	if kind == "heal":
		return {"kind": "heal", "id": "", "title": "Field Repair", "desc": "Restore 40 HP", "hint": "",
			"level_text": "", "color": Color(0.3, 1.0, 0.4)}
	return {"kind": "score", "id": "", "title": "Scrap Haul", "desc": "+500 score", "hint": "",
		"level_text": "", "color": Color(1.0, 0.85, 0.3)}


# --- firing --------------------------------------------------------------------

func update(delta: float) -> void:
	var player: Player = run.player
	var origin := player.global_position + Vector3(0, 0.9, 0)
	var dm := damage_mult()
	var cdm := cooldown_mult()
	var am := area_mult()
	for id in order:
		var w: Dictionary = owned[id]
		w["timer"] -= delta
		if id == "saws":
			continue
		if w["timer"] > 0.0:
			continue
		var lvl: int = w["level"]
		var evo: bool = w["evolved"]
		var cd := 1.0
		match id:
			"mg":
				cd = _fire_mg(origin, lvl, evo, dm)
			"rockets":
				cd = _fire_rockets(origin, lvl, evo, dm, am)
			"mines":
				cd = _drop_mines(player, lvl, evo, dm, am)
			"tesla":
				cd = _fire_tesla(origin, lvl, evo, dm)
			"shock":
				cd = _pulse_shock(player, lvl, evo, dm, am)
		w["timer"] = cd * cdm if cd > 0.15 or evo else cd
	_update_saws(delta, player, dm, am)


func _fire_mg(origin: Vector3, lvl: int, evo: bool, dm: float) -> float:
	var enemies: Enemies = run.enemies
	var t := enemies.nearest(origin, 20.0)
	if t < 0:
		return 0.1
	var dmg := (16.0 if evo else 8.0 * (1.4 if lvl >= 2 else 1.0)) * dm
	var barrels := 2 if evo else 1 + int(lvl >= 3) + int(lvl >= 5)
	var pierce := 3 if evo else int(lvl >= 5)
	var dir := (enemies.pos[t] + Vector3(0, 0.5, 0) - origin).normalized()
	for b in barrels:
		var spread := (b - (barrels - 1) * 0.5) * 0.12
		if evo:
			spread += randf_range(-0.08, 0.08)
		run.projectiles.fire(Projectiles.BULLET, origin, dir.rotated(Vector3.UP, spread) * 36.0, dmg, 0.7, pierce)
	Sfx.play("shot", -12.0)
	if evo:
		return 0.07
	return 0.42 * (0.7 if lvl >= 4 else 1.0)


func _fire_rockets(origin: Vector3, lvl: int, evo: bool, dm: float, am: float) -> float:
	var enemies: Enemies = run.enemies
	var count := 4 if evo else 1 + int(lvl >= 3) + int(lvl >= 5)
	var dmg := (34.0 if evo else 22.0 * (1.3 if lvl >= 2 else 1.0)) * dm
	var aoe := (3.2 if evo else 2.4 * (1.25 if lvl >= 4 else 1.0)) * am
	var fired := false
	for k in count:
		var t := enemies.random_in_range(origin, 22.0)
		if t < 0:
			break
		var to := (enemies.pos[t] - origin)
		to.y = 0.0
		var side := to.normalized().cross(Vector3.UP) * randf_range(-5.0, 5.0)
		var vel := to.normalized() * 10.0 + Vector3(0, 7.0, 0) + side
		run.projectiles.fire(Projectiles.ROCKET, origin + Vector3(0, 0.4, 0), vel.normalized() * 16.0, dmg, 2.2, 0, aoe, t, Projectiles.FLAG_HOMING)
		fired = true
	if not fired:
		return 0.2
	Sfx.play("shot", -6.0, 0.6)
	if evo:
		return 0.75
	return 1.7 - (0.4 if lvl >= 5 else 0.0)


func _drop_mines(player: Player, lvl: int, evo: bool, dm: float, am: float) -> float:
	var count := 2 if evo or lvl >= 5 else 1
	var dmg := (45.0 if evo else 30.0 * (1.4 if lvl >= 2 else 1.0)) * dm
	var aoe := 2.6 * (1.3 if lvl >= 4 else 1.0) * am * (1.2 if evo else 1.0)
	var back := -player.velocity.normalized() if player.velocity.length() > 0.5 else Vector3.BACK
	var right := back.cross(Vector3.UP)
	for k in count:
		_mine_side = -_mine_side
		var p := player.global_position + back * 2.0 + right * _mine_side * randf_range(0.5, 2.5)
		p.y = 0.0
		run.projectiles.fire(Projectiles.MINE, p, Vector3.ZERO, dmg, 9.0, 0, aoe, -1, Projectiles.FLAG_NAPALM if evo else 0)
	if evo:
		return 0.8
	return 0.95 if lvl >= 3 else 1.3


func _fire_tesla(origin: Vector3, lvl: int, evo: bool, dm: float) -> float:
	var enemies: Enemies = run.enemies
	var chains := 12 if evo else 3 + (2 if lvl >= 2 else 0) + (3 if lvl >= 5 else 0)
	var dmg := (24.0 if evo else 14.0 * (1.4 if lvl >= 3 else 1.0)) * dm
	var heads := 2 if evo else 1
	var visited := {}
	var any := false
	for h in heads:
		var from := origin + Vector3(0, 0.6, 0)
		var t := enemies.nearest(origin, 14.0, visited)
		for c in chains:
			if t < 0:
				break
			var to: Vector3 = enemies.pos[t] + Vector3(0, 0.6, 0)
			run.fx.bolt(from, to, Color(0.5, 0.85, 1.0) if not evo else Color(0.8, 0.6, 1.0))
			visited[t] = true
			run.hit_enemy(t, dmg, Vector3.ZERO, 0.0)
			any = true
			from = to
			t = enemies.nearest(to, 6.5, visited)
	if not any:
		return 0.2
	Sfx.play("zap", -8.0)
	if evo:
		return 0.55
	return 1.1 if lvl >= 4 else 1.5


func _pulse_shock(player: Player, lvl: int, evo: bool, dm: float, am: float) -> float:
	var r := (6.5 if evo else 3.2 * (1.3 if lvl >= 2 else 1.0) * (1.3 if lvl >= 5 else 1.0)) * am
	var dmg := (20.0 if evo else 7.0 * (1.5 if lvl >= 3 else 1.0) * (1.3 if lvl >= 5 else 1.0)) * dm
	var knock := 14.0 if evo else 6.0
	var c := player.global_position
	_tmp.clear()
	run.enemies.query(c, r, _tmp)
	for j in _tmp:
		var out: Vector3 = run.enemies.pos[j] - c
		out.y = 0.0
		run.hit_enemy(j, dmg, out.normalized(), knock)
	run.fx.ring(c, r, Color(0.6, 0.5, 1.0, 0.9) if not evo else Color(0.9, 0.85, 1.0, 1.0), 0.3)
	if not _tmp.is_empty():
		Sfx.play("zap", -14.0, 0.5)
	if evo:
		return 0.8
	return 0.9 if lvl >= 4 else 1.2


func _update_saws(delta: float, player: Player, dm: float, am: float) -> void:
	if not owned.has("saws"):
		return
	var lvl := level("saws")
	var evo := is_evolved("saws")
	var count := 6 if evo else 2 + int(lvl >= 3) + int(lvl >= 5)
	var orbit := (4.4 if evo else 2.7 + (0.8 if lvl >= 4 else 0.0)) * am
	var spin := 4.5 if evo else (4.0 if lvl >= 5 else 3.0)
	var dmg := (22.0 if evo else 9.0 * (1.4 if lvl >= 2 else 1.0)) * dm
	var size := (1.6 if evo else 1.0) * am
	_saw_angle += spin * delta
	var c := player.global_position
	var hit_any := false
	for k in _saws.size():
		var m := _saws[k]
		if k >= count:
			m.visible = false
			continue
		var a := _saw_angle + k * TAU / count
		var p := c + Vector3(cos(a), 0.0, sin(a)) * orbit + Vector3(0, 0.7, 0)
		m.visible = true
		m.global_position = p
		m.rotation.y += delta * 25.0
		m.scale = Vector3(size, 1.0, size)
		_tmp.clear()
		run.enemies.query(p, 0.6 * size, _tmp)
		for j in _tmp:
			if run.enemies.saw_cd[j] > 0.0:
				continue
			run.enemies.saw_cd[j] = 0.35
			var out: Vector3 = run.enemies.pos[j] - c
			out.y = 0.0
			run.hit_enemy(j, dmg, out.normalized(), 3.0)
			hit_any = true
	if hit_any:
		Sfx.play("saw", -10.0)
