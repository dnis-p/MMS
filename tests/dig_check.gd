extends Node
## Dev tool: checks the digging rules without a human.
##   godot --headless --path . res://tests/dig_check.tscn

var _main: Node
var _failed := false
var _step := "rules"
var _wait := 0.0
var _at := Vector3.ZERO
var _peak := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Options.fog = false  # set directly, so the player's saved choice stays as it is
	Profile.saving = false
	Profile.reset()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	_main._clear()
	var r := Run.new()
	r.process_mode = Node.PROCESS_MODE_PAUSABLE
	r.run_seed = 7
	_main._set_current(r)
	r.levelup_ui.auto_pick = true
	r.god_mode = true  # the threats have their own checks
	r.enemies.clear()


func _process(delta: float) -> void:
	_wait -= delta
	var r: Run = _main._current
	if r == null or r.player == null:
		return
	match _step:
		"rules":
			_check_world(r)
			_check_shovel(r)
			_check_hits(r)
			_check_chain(r)
			_check_threats(r)
			_check_fog(r)
			_check_pause(r)
			_check_tools(r)
			_check_goal(r)
			_check_rewards(r)
			_check_meta(r)
			_check_rooms(r)
			_check_evolutions(r)
			_clear_around(r)
			Input.action_press("move_right")
			_wait = 0.1
			_step = "right"
		"right":
			if _wait <= 0.0:
				_check("moving is at full speed at once", is_equal_approx(r.player.velocity.length(), r.player.speed))
				Input.action_release("move_right")
				Input.action_press("move_left")
				_step = "left"
				_wait = -1.0
				_at = r.player.global_position
				r.player.move(0.016, Vector2.LEFT, r.mine)
				_check("turning is instant", r.player.heading == Vector3.LEFT and r.player.velocity == Vector3.LEFT * r.player.speed)
				Input.action_release("move_left")
				r.player.move(0.016, Vector2.ZERO, r.mine)
				_check("stopping is instant", r.player.velocity == Vector3.ZERO)
				_check_walls(r)
				_check_aim(r)
				_max_everything(r)
				_wait = 4.0
				_step = "late"
		"late":
			r.pending_levelups = 0
			_peak = maxf(_peak, r.fx.trauma)
			if _wait <= 0.0:
				_check("every tool at max shakes no harder than a level-up (peak %.2f)" % _peak, _peak <= 0.41)
				_step = "gem"
		"gem":
			if _wait <= 0.0:
				r.player.global_position = Vector3.ZERO
				r.tools.owned.clear()
				r.tools.order.clear()
				_clear_gems(r)
				r.pickups.drop_gem(r.player.global_position, 999, Color.WHITE)
				_wait = 0.8
				_at = Vector3(r.level, 0, 0)
				_step = "gem_end"
		"gem_end":
			if _wait <= 0.0:
				_check("gems fly to you and give XP", not r.pickups.g_val.has(999) and r.pending_levelups + r.level > int(_at.x))
				r.god_mode = false
				r.player.invuln = 0.0
				r.player.hp = 1.0
				r.player_hit(50.0)
				_check("running out of health ends the run", r.dead)
				r.loot = 21.0
				r._finish("dead")
				r._finish("dead")
				_check("a run banks its gems once", Profile.gems == 10 and Profile.stat("runs") == 1)
				print("DIG CHECK %s" % ("FAILED" if _failed else "PASSED"))
				get_tree().quit(1 if _failed else 0)


func _max_everything(r: Run) -> void:
	for id in Defs.TOOLS:
		for k in Defs.MAX_TOOL_LEVEL:
			r.tools.add_tool(id)
	for id in Defs.BOOSTS:
		for k in Defs.MAX_BOOST_LEVEL:
			r.tools.add_boost(id)
	r.fx.trauma = 0.0


func _clear_around(r: Run) -> void:
	r.mine.hit_circle(Vector3.ZERO, 8.0, 1e9, Vector3.ZERO)
	r.pending_levelups = 0


## Fills a square with one kind of cube.
func _fill(r: Run, center: Vector3, half: int, k: int) -> void:
	var m := r.mine
	var cx := m.cell_of(center.x)
	var cz := m.cell_of(center.z)
	for z in range(cz - half, cz + half + 1):
		for x in range(cx - half, cx + half + 1):
			var c := x + z * Mine.SIZE
			m.kind[c] = k
			m.hp[c] = float(Defs.CUBES[k].get("hp", 0.0))
			m._draw_cube(c)


func _check_world(r: Run) -> void:
	var m := r.mine
	_check("the world has cubes", m.kind.count(0) < Mine.SIZE * Mine.SIZE * 0.5)
	_check("you start in the open", m.kind_at(Vector3.ZERO) == 0)
	_check("the edge is bedrock", m.kind[0] == Defs.BEDROCK)
	var kinds := {}
	for i in range(0, m.kind.size(), 3):
		kinds[m.kind[i]] = true
	_check("ore and crystal exist", kinds.has(9) and kinds.has(Defs.CRYSTAL))
	_check("there are nests of sleepers", m.nests.size() > 10)
	_check("gas rock is rare (%d)" % m.kind.count(Defs.GAS), m.kind.count(Defs.GAS) > 0 and m.kind.count(Defs.GAS) < 1200)


func _check_shovel(r: Run) -> void:
	var m := r.mine
	_fill(r, Vector3(0, 0, -3), 6, 1)
	r.player.heading = Vector3.FORWARD
	r.player.global_position = Vector3(0, 0, 0)
	var before := r.cubes
	var cells := m.hit_arc(Vector3.ZERO, Vector3.FORWARD, r.tools.size("shovel"), Defs.TOOLS["shovel"]["arc"], 1e9, 1e6)
	m.update(0.01)
	_check("one swing of the starter shovel hits many cubes (%d)" % cells, cells >= 10)
	_check("all of them pop", r.cubes - before == cells)
	_fill(r, Vector3(0, 0, -3), 6, 0)


func _check_hits(r: Run) -> void:
	var m := r.mine
	var p := Vector3(0, 0, -2)
	_fill(r, p, 0, 5)
	var c := m.cell_of(p.x) + m.cell_of(p.z) * Mine.SIZE
	m.strike(c, 1.0, 0.0)
	_check("a hit cube survives and heats up", m.kind[c] == 5 and m._heat[c] > 0.0)
	m.update(1.0)
	_check("the flash wears off", m._hot.is_empty())
	m.strike(c, 3.0, 0.1)
	_check("a delayed hit waits", m.hp[c] == 39.0)
	m.update(0.2)
	_check("a delayed hit lands", m.hp[c] == 36.0)
	for k in [9, 10, 11, 12]:
		_fill(r, p, 0, k)
		var gems := r.pickups.g_pos.size()
		m.strike(c, 1e9, 0.0)
		_check("%s always drops a gem" % Defs.CUBES[k]["name"], r.pickups.g_pos.size() == gems + 1)
	_fill(r, p, 0, Defs.BEDROCK)
	m.strike(c, 1e9, 0.0)
	_check("bedrock can't break", m.kind[c] == Defs.BEDROCK)
	_fill(r, p, 0, 0)


func _check_chain(r: Run) -> void:
	var m := r.mine
	var p := Vector3(0, 0, -4)
	_fill(r, p, 3, Defs.CRYSTAL)
	var before := r.cubes
	m.strike(m.cell_of(p.x) + m.cell_of(p.z) * Mine.SIZE, 1e9, 0.0)
	_check("crystal doesn't all go at once", r.cubes - before < 5)
	for k in 30:
		m.update(0.03)
	_check("crystal chains through the whole blob (%d)" % (r.cubes - before), r.cubes - before == 49)
	_check("every crystal drops a gem (%d)" % r.pickups.g_pos.size(), r.pickups.g_pos.size() >= 49)
	_clear_gems(r)


func _clear_gems(r: Run) -> void:
	for arr in [r.pickups.g_pos, r.pickups.g_val, r.pickups.g_col, r.pickups.g_pull, r.pickups.g_hop]:
		arr.clear()


func _check_threats(r: Run) -> void:
	var e := r.enemies
	var m := r.mine
	var p := r.player
	r.god_mode = false
	p.global_position = Vector3.ZERO
	var near := Vector3(0.7, 0, 0)
	var i := e.spawn(Enemies.CRAWLER, near, -1, true)
	e.update(0.016, Vector3.ZERO, p.radius)
	_check("an enemy touching you hurts", p.hp < p.max_hp)
	var hp := p.hp
	e.update(0.016, Vector3.ZERO, p.radius)
	_check("you can't be hit twice in a row", p.hp == hp)
	p.invuln = 0.0
	p.hp = p.max_hp
	_check("the shovel sees enemies", e.arc_has_enemies(Vector3.ZERO, Vector3.RIGHT, 2.4, 1.15))
	e.hit_arc(Vector3.ZERO, Vector3.RIGHT, 2.4, 1.15, 1e6)
	_check("tools kill enemies", not e.is_alive(i) and r.kills == 1)
	_check("kills drop a gem", not r.pickups.g_pos.is_empty())
	_clear_gems(r)
	var a := e.spawn(Enemies.CRAWLER, Vector3(0, 0, -30), 5)
	var b := e.spawn(Enemies.CRAWLER, Vector3(1, 0, -30), 5)
	var c := e.spawn(Enemies.BRUTE, Vector3(-1, 0, -30), 5)
	e.update(0.016, Vector3.ZERO, p.radius)
	var at: Vector3 = e.pos[a]
	e.update(0.3, Vector3.ZERO, p.radius)
	_check("a nest sleeps while you are away", e.awake[a] == 0 and e.pos[a] == at)
	e.hit(a, 1.0, Vector3.ZERO)
	_check("hitting one wakes its whole nest", e.awake[b] == 1 and e.awake[c] == 1)
	e.clear()
	r.spawn_horde()
	var sides := [0, 0, 0, 0]
	for k in e.used:
		var q := Vector2(e.pos[k].x, e.pos[k].z)
		sides[(1 if q.x > 0.0 else 0) + (2 if q.y > 0.0 else 0)] += 1
	_check("a horde comes from every side (%s)" % str(sides), e.alive_count >= 40 and sides.min() >= 8)
	_check("hordes start out of reach", e.nearest_awake(Vector3.ZERO, 10.0) == -1)
	_fill(r, Vector3(1.6, 0, 0), 2, 7)
	var swarm := e.spawn(Enemies.CRAWLER, Vector3(1.6, 0, 0), -1, true, true)
	for k in 3:
		e.update(0.15, Vector3.ZERO, p.radius)
	_check("the swarm digs through rock", m.kind_at(e.pos[swarm]) == 0)
	p.invuln = 0.0
	p.hp = p.max_hp
	_fill(r, Vector3(1.6, 0, 0), 2, 0)
	e.clear()
	var one := e.spawn(Enemies.CRAWLER, Vector3(1.5, 0, 0), -1, true)
	e.hit(one, r.tools.dmg("shovel"), Vector3.ZERO)
	_check("one shovel hit pops a crawler", not e.is_alive(one))
	_clear_gems(r)
	_fill(r, Vector3(4, 0, 0), 2, 7)
	var mole := e.spawn(Enemies.BURROWER, Vector3(5, 0, 0), -1, true)
	var before := m.kind[m.cell_of(5.0) + m.cell_of(0.0) * Mine.SIZE]
	for k in 5:
		e.update(0.05, Vector3.ZERO, p.radius)
	_check("burrowers tunnel through rock", before == 7 and m.kind_at(e.pos[mole]) == 0)
	e.clear()
	_fill(r, Vector3(4, 0, 0), 2, 0)
	var crawl := e.spawn(Enemies.CRAWLER, Vector3(5, 0, 0), -1, true)
	_fill(r, Vector3(3, 0, 0), 2, 7)
	for k in 90:
		e.update(0.016, Vector3.ZERO, p.radius)
	_check("other enemies are stopped by rock", e.pos[crawl].x > 3.5)
	e.clear()
	_fill(r, Vector3(3, 0, 0), 2, 0)
	_check_traps(r)
	_check_scaling(r)
	p.invuln = 0.0
	p.hp = p.max_hp
	r.god_mode = true


func _check_scaling(r: Run) -> void:
	var e := r.enemies
	var t := r.tools
	r._update_power()
	var weak := e.spawn(Enemies.CRAWLER, Vector3(5, 0, 0))
	var hp: float = e.hp[weak]
	_check("a starter shovel pops a crawler", t.dmg("shovel") >= hp)
	var crowd := r.crowd
	for id in Defs.TOOLS:
		for k in Defs.MAX_TOOL_LEVEL:
			t.add_tool(id)
	for id in Defs.BOOSTS:
		for k in Defs.MAX_BOOST_LEVEL:
			t.add_boost(id)
	r._update_power()
	var strong := e.spawn(Enemies.CRAWLER, Vector3(5, 0, 0))
	_check("enemies get tougher as you do (%.0f -> %.0f)" % [hp, e.hp[strong]], e.hp[strong] > hp * 5.0)
	_check("more of them come", r.crowd > crowd * 2.0 and r.runners > 0.2)
	var hits: float = e.hp[strong] / t.dmg("shovel")
	_check("a maxed shovel still kills one fast (%.1f hits)" % hits, hits <= 5.0)
	e.pos[weak] = Vector3.ZERO
	e.clear()
	t.owned.clear()
	t.order.clear()
	t.boosts.clear()
	t.boost_order.clear()
	t.add_tool("shovel")
	r.apply_boosts()
	r._update_power()


func _check_traps(r: Run) -> void:
	var p := r.player
	var t := r.traps
	var m := r.mine
	p.invuln = 0.0
	p.hp = p.max_hp
	t._at.clear()
	t._pos.clear()
	t._beat.clear()
	var cycle: float = Defs.THREATS["spike_cycle"]
	t.add_plate(Vector3(0.5, 0, 0.5), cycle - t._time - fmod(0.0, 1.0) - 0.1)
	_check("a spike plate goes up on its beat", t.height(0) >= 1.0)
	t.update(0.0, Vector3(0.5, 0, 0.5))
	_check("raised spikes hurt", p.hp < p.max_hp)
	p.invuln = 0.0
	p.hp = p.max_hp
	t._beat[0] = cycle * 0.5 - t._time
	t._beat[0] = 0.0 - t._time
	_check("lowered spikes are safe", t.height(0) == 0.0)
	t.update(0.0, Vector3(0.5, 0, 0.5))
	_check("walking on them does nothing", p.hp == p.max_hp)
	t._at.clear()
	t._pos.clear()
	t._beat.clear()
	_fill(r, Vector3(2, 0, 0), 1, Defs.GAS)
	var c := m.cell_of(2.0) + m.cell_of(0.0) * Mine.SIZE
	var mob := r.enemies.spawn(Enemies.BRUTE, Vector3(2.5, 0, 0), -1, true)
	m.strike(c, 1e9, 0.0)
	_check("gas rock doesn't blow at once", p.hp == p.max_hp)
	for k in 8:
		m.update(0.03)
	t.update(float(Defs.THREATS["gas_fuse"]) + 0.01, Vector3.ZERO)
	_check("gas rock blows after its fuse and hurts you", p.hp < p.max_hp)
	_check("the blast also hits enemies", not r.enemies.is_alive(mob))
	_check("and clears the rock", m.kind_at(Vector3(3.5, 0, 0)) == 0 or m.kind_at(Vector3(2, 0, 0)) == 0)
	_clear_gems(r)
	p.invuln = 0.0
	p.hp = p.max_hp
	r.mine.update(1.0)


func _check_fog(r: Run) -> void:
	var m := r.mine
	Options.fog = true
	r.apply_fog()
	m.forget()
	_fill(r, Vector3(0, 0, 0), 60, 1)
	_fill(r, Vector3.ZERO, 6, 0)
	r.player.global_position = Vector3.ZERO
	m.scan_light(Vector3.ZERO)
	var edge := m.cell_of(0.0) + m.cell_of(-3.25) * Mine.SIZE  # the first cube of the wall
	_check("you know the open floor you can see", m.has_seen_at(Vector3(1, 0, 1)) and m.can_see_at(Vector3(1, 0, 1)))
	_check("rock is never known by itself", m._known[edge] > 0 and m.kind[edge] != 0)
	_check("you can see a little into rock", m.can_see(edge) and m.can_see(edge - Mine.SIZE * 5))
	_check("the fog thickens going in", m._known[edge] < m._known[edge - Mine.SIZE * 3] and m._known[edge - Mine.SIZE * 3] < m._known[edge - Mine.SIZE * 6])
	_check("you can't see deep into rock", not m.can_see(edge - Mine.SIZE * 9))
	_fill(r, Vector3(0, 0, -6), 1, 0)
	m.scan_light(Vector3.ZERO)
	_check("a wall hides the cave behind it", not m.has_seen_at(Vector3(0, 0, -6)))
	_check("the fog covers a cave just like rock", m.can_see_at(Vector3(0, 0, -6)) == m.can_see(edge - Mine.SIZE * 5))
	_check("a cave out of sight doesn't wake its nest", not m.has_seen_at(Vector3(0, 0, -6)))
	var dug := edge
	m.hit_circle(m.pos_of(dug), 0.3, 1e9, m.pos_of(dug))
	m.update(0.0)
	_check("a broken cube clears its fog at once", m._known[dug] == 0 and m._known[dug - Mine.SIZE] == Mine.STEP)
	for k in 40:
		m.scan_light(Vector3.ZERO)
	_check("the drawn fog catches up", m._moving.is_empty() and m._shown == m._known)
	_check("the fog stays gone behind you", m.has_seen_at(Vector3(1, 0, 1)))
	r.player.global_position = Vector3(20, 0, 20)
	m.scan_light(Vector3(20, 0, 20))
	_check("even from far away", m.has_seen_at(Vector3(1, 0, 1)))
	r.player.global_position = Vector3.ZERO
	var far := Vector3(0, 0, 25)
	_fill(r, far, 1, 1)
	var c := m.cell_of(far.x) + m.cell_of(far.z) * Mine.SIZE
	_check("tools can't reach what you can't see", m.hit_circle(far, 2.0, 1e9, far) == 0 and m.kind[c] == 1)
	_check("a level-up blast still reaches into the dark", m.hit_circle(far, 2.0, 1e9, far, 0.0, true) > 0 and m.kind[c] == 0)
	m.update(0.0)
	_check("rock broken in the dark clears its fog", m._known[c] == 0)
	_fill(r, far, 1, 1)
	m.forget()
	_check("the beam goes through the fog", m.hit_line(far + Vector3(0, 0, -3), Vector3.BACK, 6.0, 0.6, 1e9, 1e6, true) > 0)
	m.update(0.1)
	_check("it breaks what it hits there", m.kind[c] == 0)
	_fill(r, far, 1, 1)
	_check("the pulse goes through the fog", m.hit_ring(far, 2.0, 1e9, 0.01) > 0)
	m.update(0.1)
	_check("it breaks what it hits there", m.kind[c] == 0)
	Options.fog = false
	r.apply_fog()
	_fill(r, far, 1, 1)
	_check("with fog off you can hit anything", m.hit_circle(far, 2.0, 1e9, far) > 0)
	_fill(r, Vector3.ZERO, 60, 0)


## The world's goal and the two ways out, without ending this run.
func _check_goal(r: Run) -> void:
	var m := r.mine
	_check("the Heart is out near the edge", m.heart_pos.length() > 60.0)
	_check("every run has lifts, one by the start", m.lifts.size() > 5 and m.lifts[0].length() < 3.5)
	_check("a lift keeps all you carry, dying keeps half", r.keep_share("lift") == 1.0 and r.keep_share("dead") == 0.5)
	r.loot = 100.5
	_check("gems kept round down, the Heart pays a bonus", r.gems_kept("dead") == 50 and r.gems_kept("heart") == 100 + int(Defs.RUN["heart_bonus"]))
	r.loot = 0.0
	var at := Vector3(2, 0, 0)
	_fill(r, at, 0, Defs.HEART)
	var c := m.cell_of(at.x) + m.cell_of(at.z) * Mine.SIZE
	r.overlay.hide_panel()
	m.strike(c, 1e9, 0.0)
	_check("nothing breaks a Heart cube in one hit", m.kind[c] == Defs.HEART and m.heart_left < 1.0 and m.hp[c] == Defs.CUBES[Defs.HEART]["hp"] - Defs.RUN["heart_hit"])
	m.carve(at, 0.3)
	_check("tunnelling enemies can't eat the Heart", m.kind[c] == Defs.HEART)
	r.enemies.clear()
	_fill(r, at, 0, 0)
	m.heart_left = 1.0
	Profile.record({"cubes": 10, "band": 3})
	Profile.record({"cubes": 5, "band": 1})
	_check("totals add up, bests stay best", Profile.stat("cubes") == 15 and Profile.stat("band") == 3)
	Profile.gems = 42
	Profile.saving = true
	Profile.file = "user://test_profile.cfg"
	Profile.save()
	Profile.reset()
	Profile.load_file()
	_check("the profile survives a save and load", Profile.gems == 42 and Profile.stat("cubes") == 15)
	DirAccess.remove_absolute(Profile.file)
	Profile.saving = false
	Profile.file = Profile.PATH
	Profile.reset()


## Shop, goals, unlocks and characters. Works on the profile, then leaves it empty again.
func _check_meta(r: Run) -> void:
	for o in r.tools.level_up_options(9):
		_check("%s is not locked" % o["title"], o["kind"] != "tool" or Profile.has_tool(o["id"]))
	Profile.unlocked["tool:beam"] = true
	var seen := false
	for k in 40:
		for o in r.tools.level_up_options(3):
			seen = seen or o["id"] == "beam"
	_check("an unlocked tool joins the level-ups", seen)
	Profile.reset()
	_check("you can't buy what you can't pay for", not Profile.buy("power") and Profile.shop_level("power") == 0)
	Profile.gems = 1000
	var first := Profile.price("power")
	var dmg := r.tools.dmg("shovel")
	_check("buying spends gems", Profile.buy("power") and Profile.gems == 1000 - first)
	_check("each level costs more", Profile.price("power") > first)
	_check("shop damage counts", r.tools.dmg("shovel") > dmg)
	r._update_power()
	var hardness := r.hardness
	Profile.shop["power"] = 5
	r._update_power()
	_check("enemies don't catch up with what you bought", r.hardness == hardness)
	_check("a maxed upgrade can't be bought", not Profile.buy("power"))
	Profile.shop["cover"] = 2
	_check("insurance keeps more", is_equal_approx(r.keep_share("dead"), 0.62) and r.keep_share("lift") == 1.0)
	Profile.reset()
	Profile.record({"lifts": 1, "band": 3})
	var news := Profile.claim_goals()
	_check("finished goals are paid once", news.size() == 2 and Profile.claim_goals().is_empty())
	_check("goals unlock things", Profile.has_tool("bombs") and Profile.has_character("prospector") and not Profile.has_character("rig"))
	Profile.record({"geodes": 5})
	var bank := Profile.gems
	Profile.claim_goals()
	_check("goals can pay gems", Profile.gems > bank)
	_check("every locked thing has a way to get it", _all_reachable())
	_check("the nearest goals come first", Profile.closest_goals(1)[0]["id"] != "heart")
	Profile.reset()


func _check_rooms(r: Run) -> void:
	var m := r.mine
	_check("the mine has vaults and rooms", m.kind.count(Defs.VAULT) > 100 and m.rooms.size() == int(Defs.RUN["shrines"]) + int(Defs.RUN["relic_rooms"]))
	var hp := r.player.max_hp
	r.gem_rate = 1.0
	r.take_shrine("greed")
	r.take_shrine("wind")
	_check("shrines give and take", r.gem_rate == 1.5 and r.greed_harm == 1.3 and r.player.max_hp < hp and r.player.base_speed > float(Defs.DIGGER["speed"]))
	r._update_power()
	_check("greed makes enemies hit harder", r.harm >= 1.3)
	r.gem_rate = 1.0
	r.greed_harm = 1.0
	r.base_hp = Defs.DIGGER["hp"]
	r.player.base_speed = Defs.DIGGER["speed"]
	r.apply_boosts()
	r.player.hp = r.player.max_hp
	var levels := r.pending_levelups
	r.take_shrine("blood")
	_check("the Blood Shrine trades health for upgrades", r.player.hp == r.player.max_hp * 0.5 and r.pending_levelups == levels + 2)
	r.pending_levelups = 0
	r.player.hp = r.player.max_hp
	r.find_relic("lens", Vector3.ZERO)
	_check("a relic unlocks for good", Profile.relics.has("lens") and Profile.has_tool("beam") and r.relics == 1)
	r.find_relic("charm", Vector3.ZERO)
	_check("a relic can add a bonus", Profile.bonus("health") == 25.0)
	r.relics = 0
	Profile.reset()
	var glints := m.glint_pos.size()
	var spot: Vector3 = m.rooms[0][0]
	m.drop_glint(spot)
	_check("a used room stops sparkling", m.glint_pos.size() == glints - 1)
	var count := r.sites._spots.size()
	_check("every room has its site", count == m.rooms.size())


func _check_evolutions(r: Run) -> void:
	var t := r.tools
	var dmg := t.dmg("drill") if t.owned.has("drill") else 0.0
	for k in Defs.MAX_TOOL_LEVEL:
		t.add_tool("drill")
	t.boosts.erase("haste")
	t.boost_order.erase("haste")
	_check("no evolution without its boost", t._evolution_options().is_empty() or not _offers(t, "drill"))
	for k in Defs.EVOLVE_BOOST:
		t.add_boost("haste")
	_check("a maxed tool plus its boost can evolve", _offers(t, "drill"))
	dmg = t.dmg("drill")
	var power := t.power_of("drill")
	var first: Dictionary = t.level_up_options(3)[0]
	_check("the evolution is always offered", first["kind"] == "evolve")
	t.evolved.clear()
	t.apply({"kind": "evolve", "id": "drill"})
	_check("evolving makes it stronger", t.dmg("drill") > dmg * 1.4 and t.power_of("drill") == power and r.evolutions == 1)
	_check("and it can't evolve twice", not _offers(t, "drill"))
	t.apply({"kind": "evolve", "id": "shovel"})
	_check("the Great Scoop swings all around", t._shovel_arc() == PI)
	t.update(0.016)
	t.evolved.clear()
	t._build_slash()
	r.evolutions = 0
	r.mine.update(1.0)


func _offers(t: Tools, id: String) -> bool:
	return t._evolution_options().any(func(o): return o["id"] == id)


func _all_reachable() -> bool:
	var keys: Array = Defs.GOALS.map(func(g): return g.get("unlock", ""))
	for id in Defs.CHARACTERS:
		if Defs.CHARACTERS[id].get("locked", false) and not keys.has("char:" + id):
			return false
	for id in ["bombs", "pulse"]:
		if not keys.has("tool:" + id):
			return false
	return true


func _check_rewards(r: Run) -> void:
	var m := r.mine
	r.combo = 0
	r.frenzy_left = 0.0
	r._frenzy_rest = 0.0
	r._frenzy_base = 0
	_check("geodes are in the world and sparkle", m.kind.count(Defs.GEODE) > 100 and m.glint_pos.size() >= int(Defs.RUN["geodes"]))
	var at := Vector3(0, 0, -4)
	_fill(r, at, 2, Defs.GEODE)
	var c := m.cell_of(at.x) + m.cell_of(at.z) * Mine.SIZE
	_clear_gems(r)
	r.geodes = 0
	m.strike(c, 1.0, 0.0)
	_check("a geode has a hard shell", m.kind[c] == Defs.GEODE)
	m.strike(c, 1e9, 0.0)
	for k in 40:
		m.update(0.03)
	_check("a geode bursts as one, into many gems (%d)" % r.pickups.g_pos.size(), r.pickups.g_pos.size() == 25 and m.kind[c] == 0)
	_check("and counts once", r.geodes == 1)
	_clear_gems(r)
	r.combo = 0
	r.frenzies = 0
	r._frenzy_rest = 0.0
	_fill(r, at, 0, 7)
	m.strike(c, 1.0, 0.0)
	_check("rock takes normal damage before a Frenzy", m.kind[c] == 7)
	r.combo = int(Defs.FRENZY["at"]) - 1
	var mult := r.combo_mult()
	r.on_enemy_killed(Vector3(30, 0, 30), Enemies.CRAWLER)
	_check("a long combo starts a Frenzy", r.frenzy_left > 0.0 and r.frenzies == 1)
	_check("score doubles during it", r.combo_mult() > mult * 1.9)
	m.strike(c, 1.0, 0.0)
	_check("in a Frenzy any hit pops a cube", m.kind[c] == 0)
	_fill(r, at, 0, Defs.HEART)
	m.strike(c, 1.0, 0.0)
	_check("but not the Heart", m.kind[c] == Defs.HEART)
	r.enemies.clear()
	_fill(r, at, 0, 0)
	r._update_chains(float(Defs.FRENZY["time"]) + 0.1)
	_check("a Frenzy ends", r.frenzy_left == 0.0)
	r.combo = 5000
	r._check_frenzy()
	_check("and doesn't restart right away", r.frenzy_left == 0.0)
	r._frenzy_rest = 0.0
	r._frenzy_base = r.combo
	r._check_frenzy()
	_check("the next one takes a new long combo", r.frenzy_left == 0.0)
	r.combo = 0
	r._heart_woken = false
	m.heart_left = 1.0
	_clear_gems(r)


func _check_pause(r: Run) -> void:
	r._open_pause()
	_check("the pause menu opens with the fog switch", r._paused_by_menu and r.overlay._panel_root.visible)
	r.overlay.hide_panel()
	r._resume()


func _check_pulse(r: Run) -> void:
	var m := r.mine
	var at := Vector3.ZERO
	var r_size := r.tools.size("pulse")
	var time: float = Defs.TOOLS["pulse"]["ring_time"]
	_fill(r, Vector3(0, 0, -2), 0, 1)
	_fill(r, Vector3(0, 0, -4.5), 0, 1)
	var near := m.cell_of(0.0) + m.cell_of(-2.0) * Mine.SIZE
	var far := m.cell_of(0.0) + m.cell_of(-4.5) * Mine.SIZE
	_check("cubes wait for the pulse ring (%d)" % m.hit_ring(at, r_size, 1e9, time), m.kind[near] == 1 and m.kind[far] == 1)
	var near_time := Fx.ring_arrival(2.0, r_size, time)
	var far_time := Fx.ring_arrival(4.5, r_size, time)
	m.update(near_time - 0.02)
	_check("the ring reaches near cubes first", m.kind[near] == 1)
	m.update(0.04)
	_check("near cubes break as it passes (%.3f s)" % near_time, m.kind[near] == 0 and m.kind[far] == 1)
	m.update(far_time - near_time - 0.04)
	_check("far cubes are still waiting", m.kind[far] == 1)
	m.update(0.04)
	_check("far cubes break as it passes (%.3f s)" % far_time, m.kind[far] == 0)
	_check("the ring's timing matches its growth", absf(Fx.ring_arrival(r_size, r_size, time) - time) < 0.001 and Fx.ring_arrival(0.2, r_size, time) == 0.0)


func _check_tools(r: Run) -> void:
	var t := r.tools
	var options := t.level_up_options(3)
	_check("level-ups offer three choices", options.size() == 3)
	var dmg := t.dmg("shovel")
	t.add_tool("shovel")
	_check("levels raise a tool", t.dmg("shovel") > dmg)
	for id in Defs.TOOLS:
		t.add_tool(id)
	for id in Defs.BOOSTS:
		t.add_boost(id)
	_check("every tool can be owned", t.order.size() == Defs.TOOLS.size())
	r.mine.update(1.0)
	_check_pulse(r)
	t.update(0.016)
	t.update(0.5)
	r.level_blast()
	_check("all tools run", true)
	r.mine.update(1.0)


## With a mouse, you can walk one way and dig another.
func _check_aim(r: Run) -> void:
	var m := r.mine
	r.player.global_position = Vector3.ZERO
	r.player.aiming = true
	r.player.heading = Vector3.RIGHT
	r.player.move(0.016, Vector2.LEFT, m)
	_check("moving doesn't turn your aim", r.player.heading == Vector3.RIGHT and r.player.velocity.x < 0.0)
	_fill(r, Vector3(1.5, 0, 0), 1, 1)
	_fill(r, Vector3(-1.5, 0, 0), 1, 1)
	r.player.global_position = Vector3.ZERO
	r.tools._swing(m, r.player, Vector3.ZERO)
	m.update(1.0)
	var right := m.cell_of(1.5) + m.cell_of(0.0) * Mine.SIZE
	_check("tools dig where you aim, not where you walk", m.kind[right] == 0 or m.hp[right] < 10.0)
	_check("the rock behind you stays", m.kind_at(Vector3(-1.5, 0, 0)) == 1 and m.hp[m.cell_of(-1.5) + m.cell_of(0.0) * Mine.SIZE] == 10.0)
	_fill(r, Vector3(1.5, 0, 0), 1, 0)
	_fill(r, Vector3(-1.5, 0, 0), 1, 0)
	r.player.aiming = false
	r._mouse_seen = true
	r.player.heading = Vector3.ZERO
	r._update_aim()
	_check("the mouse sets your aim", r.player.aiming and r.player.heading.is_normalized() and r.aim_point.y == 0.0)
	r._mouse_seen = false
	r.player.aiming = false
	r.player.heading = Vector3.FORWARD


func _check_walls(r: Run) -> void:
	_fill(r, Vector3(2, 0, 0), 1, 7)
	r.player.global_position = Vector3(0, 0, 0)
	for k in 60:
		r.player.move(0.016, Vector2.RIGHT, r.mine)
	_check("rock stops you (x=%.2f)" % r.player.global_position.x, r.player.global_position.x < 1.5)
	_fill(r, Vector3(2, 0, 0), 1, 0)


func _check(what: String, ok: bool) -> void:
	print("%s: %s" % ["ok  " if ok else "FAIL", what])
	_failed = _failed or not ok
