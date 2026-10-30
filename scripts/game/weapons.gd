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
	return float(run.player.def["might"]) * (1.0 + float(Defs.PASSIVES["hot"]["damage"]) * passive("hot"))


func cooldown_mult() -> float:
	return pow(Defs.PASSIVES["turbo"]["cooldown"], passive("turbo"))


func speed_mult() -> float:
	return 1.0 + float(Defs.PASSIVES["nitro"]["speed"]) * passive("nitro")


func area_mult() -> float:
	return 1.0 + float(Defs.PASSIVES["blast"]["area"]) * passive("blast")


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
	var plating: Dictionary = Defs.PASSIVES["plating"]
	p.max_hp = float(p.def["max_hp"]) * (1.0 + float(plating["hp"]) * passive("plating"))
	p.hp += p.max_hp - old_max
	p.armor = float(p.def["armor"]) + float(plating["armor"]) * passive("plating")
	p.pickup_radius = Defs.PICKUP_RADIUS * (1.0 + float(Defs.PASSIVES["magnet"]["range"]) * passive("magnet"))
	run.update_pace()


func apply(option: Dictionary) -> void:
	match option["kind"]:
		"weapon":
			add_weapon(option["id"])
		"passive":
			add_passive(option["id"])
		"evolve":
			evolve(option["id"])
		"heal":
			run.heal(Defs.FILLER_HEAL)
		"score":
			run.add_score(Defs.FILLER_SCORE)


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
		return {"kind": "heal", "id": "", "title": "Field Repair", "desc": "Restore %d HP" % int(Defs.FILLER_HEAL), "hint": "",
			"level_text": "", "color": Color(0.3, 1.0, 0.4)}
	return {"kind": "score", "id": "", "title": "Scrap Haul", "desc": "+%d score" % Defs.FILLER_SCORE, "hint": "",
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
	var d: Dictionary = Defs.WEAPONS["mg"]
	var t := enemies.nearest(origin, d["range"])
	if t < 0:
		return 0.1
	var st := Defs.weapon_stats("mg", lvl, evo)
	var barrels: int = st["barrels"]
	var dir := (enemies.pos[t] + Vector3(0, 0.5, 0) - origin).normalized()
	for b in barrels:
		var spread: float = (b - (barrels - 1) * 0.5) * d["spread"]
		if evo:
			spread += randf_range(-d["evo_jitter"], d["evo_jitter"])
		run.projectiles.fire(Projectiles.BULLET, origin, dir.rotated(Vector3.UP, spread) * d["bullet_speed"], st["dmg"] * dm, d["bullet_life"], st["pierce"])
	Sfx.play("shot", -12.0)
	return st["cd"]


func _fire_rockets(origin: Vector3, lvl: int, evo: bool, dm: float, am: float) -> float:
	var enemies: Enemies = run.enemies
	var d: Dictionary = Defs.WEAPONS["rockets"]
	var st := Defs.weapon_stats("rockets", lvl, evo)
	var aoe: float = st["aoe"] * am
	var fired := false
	for k in st["count"]:
		var t := enemies.random_in_range(origin, d["range"])
		if t < 0:
			break
		var to := (enemies.pos[t] - origin)
		to.y = 0.0
		var side := to.normalized().cross(Vector3.UP) * randf_range(-5.0, 5.0)
		var vel := to.normalized() * 10.0 + Vector3(0, 7.0, 0) + side
		run.projectiles.fire(Projectiles.ROCKET, origin + Vector3(0, 0.4, 0), vel.normalized() * d["rocket_speed"], st["dmg"] * dm, d["rocket_life"], 0, aoe, t, Projectiles.FLAG_HOMING)
		fired = true
	if not fired:
		return 0.2
	Sfx.play("shot", -6.0, 0.6)
	return st["cd"]


func _drop_mines(player: Player, lvl: int, evo: bool, dm: float, am: float) -> float:
	var d: Dictionary = Defs.WEAPONS["mines"]
	var st := Defs.weapon_stats("mines", lvl, evo)
	var from := player.global_position
	from.y = 0.0
	for k in st["count"]:
		var a := randf() * TAU
		var to: Vector3 = run.keep_in_play(from + Vector3(cos(a), 0, sin(a)) * randf_range(d["throw_min"], d["throw_max"]))
		var vel: Vector3 = (to - from) / d["arm_time"]
		run.projectiles.fire(Projectiles.MINE, from, vel, st["dmg"] * dm, d["life"], 0, st["aoe"] * am, -1, Projectiles.FLAG_NAPALM if evo else 0)
	return st["cd"]


func _fire_tesla(origin: Vector3, lvl: int, evo: bool, dm: float) -> float:
	var enemies: Enemies = run.enemies
	var d: Dictionary = Defs.WEAPONS["tesla"]
	var st := Defs.weapon_stats("tesla", lvl, evo)
	var dmg: float = st["dmg"] * dm
	var visited := {}
	var any := false
	for h in st["heads"]:
		var from := origin + Vector3(0, 0.6, 0)
		var t := enemies.nearest(origin, d["range"], visited)
		for c in st["chains"]:
			if t < 0:
				break
			var to: Vector3 = enemies.pos[t] + Vector3(0, 0.6, 0)
			run.fx.bolt(from, to, Color(0.5, 0.85, 1.0) if not evo else Color(0.8, 0.6, 1.0))
			visited[t] = true
			run.hit_enemy(t, dmg, Vector3.ZERO, 0.0)
			any = true
			from = to
			t = enemies.nearest(to, d["chain_range"], visited)
	if not any:
		return 0.2
	Sfx.play("zap", -8.0)
	return st["cd"]


func _pulse_shock(player: Player, lvl: int, evo: bool, dm: float, am: float) -> float:
	var st := Defs.weapon_stats("shock", lvl, evo)
	var r: float = st["radius"] * am
	var c := player.global_position
	_tmp.clear()
	run.enemies.query(c, r, _tmp)
	for j in _tmp:
		var out: Vector3 = run.enemies.pos[j] - c
		out.y = 0.0
		run.hit_enemy(j, st["dmg"] * dm, out.normalized(), st["knock"])
	run.fx.ring(c, r, Color(0.6, 0.5, 1.0, 0.9) if not evo else Color(0.9, 0.85, 1.0, 1.0), 0.3)
	if not _tmp.is_empty():
		Sfx.play("zap", -14.0, 0.5)
	return st["cd"]


func _update_saws(delta: float, player: Player, dm: float, am: float) -> void:
	if not owned.has("saws"):
		return
	var d: Dictionary = Defs.WEAPONS["saws"]
	var st := Defs.weapon_stats("saws", level("saws"), is_evolved("saws"))
	var count: int = st["count"]
	var orbit: float = st["orbit"] * am
	var size: float = st["size"] * am
	var dmg: float = st["dmg"] * dm
	var hit_cd: float = d["hit_cd"]
	var knock: float = d["knock"]
	_saw_angle += st["spin"] * delta
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
			run.enemies.saw_cd[j] = hit_cd
			var out: Vector3 = run.enemies.pos[j] - c
			out.y = 0.0
			run.hit_enemy(j, dmg, out.normalized(), knock)
			hit_any = true
	if hit_any:
		Sfx.play("saw", -10.0)
