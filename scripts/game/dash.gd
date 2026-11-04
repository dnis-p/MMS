class_name Dash
extends Node3D
## The Dash Drive: a tool-slot item you press (Space, Shift or the gamepad's A) for a short, untouchable
## burst of speed the way you move. It levels up like a tool, one card per level, and each level adds the
## steps `Defs.DASH.levels` gives it. From level 3 each dash leaves a decoy where you stood: enemies attack
## it until it falls, and from level 5 it explodes. All numbers are in `Defs.DASH`.

var run: Run
var owned := false
var lvl := 0  # 0 until you take it
var mods := {}  # steps of each stat that the levels so far add up to, as Defs.DASH.levels says
var cooldown := 0.0
var cooldown_total := 1.0  # what the last dash set, for the HUD's bar
var clone_pos := Vector3.ZERO
var clone_hp := 0.0
var clone_max_hp := 0.0

var _root: Node3D
var _clone: Player
var _bar: MeshInstance3D
var _life := 0.0
var _gate := 0.0
var _flash := 0.0
var _fallen := false  # its health ran out: the next update removes it and sets off the blast


# --- upgrades ------------------------------------------------------------------------

func level(id: String) -> int:
	return int(mods.get(id, 0))


static func max_level() -> int:
	return Defs.DASH["levels"].size()


## What this adds to the count that enemies scale with: one per level, like a tool.
func upgrades() -> int:
	return lvl


## Sets the level and adds up the steps of every level up to it.
func set_level(n: int) -> void:
	lvl = clampi(n, 0, max_level())
	owned = lvl > 0
	mods.clear()
	for k in lvl:
		var add: Dictionary = Defs.DASH["levels"][k]["add"]
		for id in add:
			mods[id] = level(id) + int(add[id])


func acquire() -> void:
	if owned:
		return
	set_level(1)
	cooldown = 0.0
	run.hud.show_hint("%s to dash the way you move" % ("A" if Options.pad else "Space or Shift"), 5.0)


## The top level, for bots and checks.
func give_all() -> void:
	set_level(max_level())


## The card for the next level, or {} at the top. Level 1 is the one that fills a tool slot, so only it
## says NEW; the rest read like a tool's levels.
func option() -> Dictionary:
	if lvl >= max_level():
		return {}
	var d := Defs.DASH
	if lvl == 0:
		return {"kind": "dash", "id": "dash", "title": d["name"], "desc": d["desc"], "hint": d["hint"],
			"level_text": "NEW", "color": d["color"]}
	return {"kind": "dash", "id": "dash", "title": d["name"], "desc": d["levels"][lvl]["desc"], "hint": "",
		"level_text": "Lv %d > %d" % [lvl, lvl + 1], "color": d["color"]}


func apply(_option: Dictionary) -> void:
	if lvl == 0:
		acquire()
	else:
		set_level(lvl + 1)


# --- stats ---------------------------------------------------------------------------

func dash_speed() -> float:
	return float(Defs.DASH["base"]["speed"]) * (1.0 + float(Defs.DASH["step"]["speed"]) * level("speed"))


func dash_time() -> float:
	return float(Defs.DASH["base"]["time"]) * (1.0 + float(Defs.DASH["step"]["length"]) * level("length"))


func dash_distance() -> float:
	return dash_speed() * dash_time()


func dash_cooldown() -> float:
	return float(Defs.DASH["base"]["cooldown"]) * (1.0 - float(Defs.DASH["step"]["recharge"]) * level("recharge"))


func clone_health() -> float:
	return run.player.max_hp * float(Defs.DASH["clone"]["hp_frac"]) * (1.0 + float(Defs.DASH["step"]["clone_hp"]) * level("clone_hp"))


func blast_damage() -> float:
	var c: Dictionary = Defs.DASH["clone"]
	return float(c["boom_dmg"]) * (1.0 + float(c["boom_dmg_up"]) * (level("clone_boom") - 1)) * run.tools.damage_mult()


func blast_radius() -> float:
	var c: Dictionary = Defs.DASH["clone"]
	return float(c["boom_radius"]) * (1.0 + float(c["boom_radius_up"]) * (level("clone_boom") - 1)) * run.tools.size_mult()


# --- dashing -------------------------------------------------------------------------

func can_dash() -> bool:
	return owned and cooldown <= 0.0 and not run.dead and not run.left and not run.player.bursting()


## Dashes toward `dir` (flat, any length), or the way you last walked when it is zero.
## Returns false if the dash is not ready.
func trigger(dir: Vector3) -> bool:
	if not can_dash():
		return false
	var p := run.player
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		dir = p.last_move
	dir = dir.normalized()
	if level("clone") > 0:
		_spawn_clone()
	p.start_dash(dir, dash_speed(), dash_time(), Defs.DASH["base"]["grace"])
	cooldown_total = dash_cooldown()
	cooldown = cooldown_total
	Sfx.play("dash", -4.0)
	run.fx.burst(p.global_position + Vector3(0, 0.5, 0), Color(0.6, 0.95, 1.0), 14, 0.8)
	run.fx.shake(0.12)
	return true


func update(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	var e := run.enemies
	if _clone == null:
		e.decoy_active = false
		return
	_life -= delta
	_gate = maxf(0.0, _gate - delta)
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			_clone.ghost_flash(false)
	if _fallen or _life <= 0.0:
		clear(true)
		e.decoy_active = false
		return
	_root.visible = _life > 1.5 or fmod(_life * 8.0, 1.0) < 0.6  # blinks when about to expire
	e.decoy_active = true
	e.decoy_pos = clone_pos
	e.decoy_radius = run.player.radius
	e.decoy_taunt = Defs.DASH["clone"]["taunt"]


# --- the clone -----------------------------------------------------------------------

func clone_alive() -> bool:
	return _clone != null and not _fallen


func _spawn_clone() -> void:
	clear(true)  # a clone still standing pops before the next one appears
	var p := run.player
	clone_pos = p.global_position
	clone_pos.y = 0.0
	clone_max_hp = clone_health()
	clone_hp = clone_max_hp
	_life = Defs.DASH["clone"]["life"]
	_gate = 0.0
	_flash = 0.0
	_fallen = false
	_root = Node3D.new()
	add_child(_root)
	_root.global_position = clone_pos
	_clone = Player.new()
	_clone.color = p.color
	_root.add_child(_clone)
	_clone.make_ghost(Defs.DASH["color"])
	_clone.look_at(clone_pos + p.heading, Vector3.UP)
	_bar = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.4, 0.08, 0.14)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 1.0, 1.0)
	_bar.mesh = mesh
	_bar.material_override = mat
	_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar.position = Vector3(0, 2.4, 0)
	_root.add_child(_bar)
	run.fx.ring(clone_pos, 1.8, Color(0.4, 0.95, 1.0, 0.9), 0.35)


## Enemies reached the clone. Their damage already scales with your build and depth, as it does on you.
func hurt_clone(amount: float) -> void:
	if not clone_alive() or _gate > 0.0:
		return
	_gate = Defs.DASH["clone"]["hit_gate"]
	clone_hp -= amount
	_flash = 0.08
	_clone.ghost_flash(true)
	var ratio := clampf(clone_hp / clone_max_hp, 0.0, 1.0)
	_bar.scale.x = maxf(ratio, 0.001)
	_bar.position.x = -0.7 * (1.0 - ratio)
	Sfx.play("hit", -14.0, 0.7)
	if clone_hp <= 0.0:
		_fallen = true


## Removes the clone. With `pop` it explodes if it carries the blast mod.
func clear(pop := false) -> void:
	if _root == null:
		return
	var at := clone_pos
	_root.queue_free()
	_root = null
	_clone = null
	_bar = null
	_fallen = false
	run.debris.spray(at + Vector3(0, 0.8, 0), Defs.DASH["color"], 12, at, 1.0)
	if pop and level("clone_boom") > 0:
		var r := blast_radius()
		var d := blast_damage()
		run.mine.hit_circle(at, r, d, at, Defs.WORLD["blast_wave"])
		run.enemies.hit_circle(at, r, d)
		run.fx.ring(at, r, Color(0.5, 1.0, 1.0, 0.9), 0.4)
		run.fx.shake(0.22)
		Sfx.play("boom", -7.0)
