extends Node
## Dev tool: checks the digging rules without a human.
##   godot --headless --path . res://tests/dig_check.tscn

var _main: Node
var _failed := false
var _step := "rules"
var _wait := 0.0
var _results: Results
var _at := Vector3.ZERO
var _peak := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Options.fog = false  # set directly, so the player's saved choice stays as it is
	Options.saving = false
	Profile.saving = false
	Profile.reset()
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	Profile.reset()  # the menu just loaded the real save
	_main._clear()
	var r := Run.new()
	r.process_mode = Node.PROCESS_MODE_PAUSABLE
	r.run_seed = 7
	r.instant = true
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
			_check_slots(r)
			_check_dash(r)
			_check_goal(r)
			_check_rewards(r)
			_check_meta(r)
			_check_rooms(r)
			_check_evolutions(r)
			_check_clues(r)
			_check_seams(r)
			_check_timers()
			_check_help()
			_check_map(r)
			_check_full_floor(r)
			_check_bosses(r)
			_check_new_tools(r)
			_check_caves(r)
			_check_wipe()
			_clear_around(r)
			_check_pad(r)
			r.levelup_ui.auto_pick = false
			r.use_shrine("blood")
			_wait = 0.1
			_step = "pad_cards"
		"pad_cards":
			if _wait <= 0.0:
				_check_pad_cards(r)
				r.levelup_ui.auto_pick = true
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
				_start_hitstop(r)
				r._finish("dead")
				_check("the results open at full speed during a hitstop", Engine.time_scale == r.base_time_scale)
				r._finish("dead")
				_check("a run banks its gems once", Profile.gems == 10 and Profile.stat("runs") == 1)
				_results = Results.new()
				add_child(_results)
				_results.size = Vector2(1280, 720)
				_results.open({"title": "TEST", "color": Color.WHITE, "lines": ["a line"], "carried": 9, "kept": 9, "share": 1.0, "before": {}, "news": Defs.GOALS, "bank": 9})
				_wait = 0.1
				_step = "results"
		"results":
			if _wait <= 0.0:
				var buttons := _results._box.get_child(-1)
				_check("every goal at once leaves the results buttons on a small screen", _results._panel.get_global_rect().end.y <= 720.0 and buttons.get_global_rect().end.y <= 720.0 and _results._panel.position.y >= 0.0)
				_check("the goals that don't fit scroll", _results._list.size.y > _results._scroll.size.y)
				_check("focus sits on Dig again", buttons.get_child(0).has_focus())
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
	_check("gas rock is rare (%d)" % m.kind.count(Defs.GAS), m.kind.count(Defs.GAS) > 0 and m.kind.count(Defs.GAS) < 6000)


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


## Living enemies the camera shows any part of (their feet or their top).
func _seen_count(r: Run) -> int:
	var e := r.enemies
	var seen := 0
	for k in e.used:
		if e.is_alive(k):
			for up in [0.0, 0.8]:
				if r.camera.is_position_in_frustum(e.pos[k] + Vector3(0, up, 0)):
					seen += 1
					break
	return seen


func _clear_gems(r: Run) -> void:
	for arr in [r.pickups.g_pos, r.pickups.g_val, r.pickups.g_xp, r.pickups.g_col, r.pickups.g_pull, r.pickups.g_hop]:
		arr.clear()


## With the floor full of gems, a new one still lands where it fell; two far ones merge to make room.
func _check_full_floor(r: Run) -> void:
	_clear_gems(r)
	var pk := r.pickups
	var at := r.player.global_position
	for k in Pickups.MAX:
		pk.drop_gem(at + Vector3(60.0 + k % 40, 0, float(k / 40)), 1.0, Color.WHITE)
	var before := 0.0
	for v in pk.g_val:
		before += v
	var drop := at + Vector3(2, 0, 0)
	pk.drop_gem(drop, 5.0, Color.RED)
	var after := 0.0
	var landed := false
	for i in pk.g_pos.size():
		after += pk.g_val[i]
		landed = landed or (pk.g_val[i] == 5.0 and Vector2(pk.g_pos[i].x - drop.x, pk.g_pos[i].z - drop.z).length() < 0.5)
	_check("a full floor still takes a new gem where it fell", landed and pk.g_pos.size() == Pickups.MAX)
	_check("and keeps the value of the gems it merged (%.0f, then %.0f)" % [before, after], is_equal_approx(after, before + 5.0))
	_clear_gems(r)


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
	var close := e.spawn(Enemies.CRAWLER, Vector3(0, 0, 9), -1, true)
	_check("an enemy on screen counts as seen", _seen_count(r) == 1)
	e.remove(close)
	_check("hordes start off screen (%d seen)" % _seen_count(r), _seen_count(r) == 0)
	var first := e.alive_count
	r._swarm_timer = 999.0
	r._horde_timer = 999.0
	for k in int(Defs.THREATS["horde_gap"] / 0.1) + 1:
		r._update_swarm(0.1)
	_check("a second ring follows (%d then %d)" % [first, e.alive_count], e.alive_count >= first * 2 - 2)
	for k in int(Defs.THREATS["horde_gap"] * Defs.THREATS["horde_waves"] / 0.1):
		r._update_swarm(0.1)
	var waves: int = Defs.THREATS["horde_waves"]
	_check("a horde is %d rings, then it stops (%d)" % [waves, e.alive_count], e.alive_count >= first * waves - 4 and e.alive_count <= first * waves + 4)
	_check("every ring starts off screen", _seen_count(r) == 0)
	e.clear()
	r._swarm_timer = 0.0
	r._update_swarm(0.016)
	r.run_time = 2000.0
	r._burrow_timer = 0.0
	r._update_burrowers(0.016)
	r.run_time = 0.0
	_check("the swarm and burrowers arrive off screen (%d)" % e.alive_count, e.alive_count > 0 and _seen_count(r) == 0)
	r._horde_timer = Defs.THREATS["horde_from"]
	e.clear()
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
	e.fill_near(Vector3.ZERO)
	_check("only nests near you have sleepers (%d)" % e.alive_count, e.alive_count > 0 and e.alive_count < Enemies.SLEEPERS)
	var sleepers := e.alive_count
	for k in Enemies.MAX:
		e.spawn(Enemies.CRAWLER, Vector3(0, 0, 40), 9)
		if e.alive_count >= Enemies.SLEEPERS:
			break
	r.spawn_horde()
	_check("sleeping nests leave room for hordes (%d)" % e.alive_count, sleepers > 0 and e.alive_count >= Enemies.SLEEPERS + 40)
	e.clear()
	e.spawn(Enemies.CRAWLER, Vector3(0, 0, 100), 3)
	e.update(0.016, Vector3.ZERO, p.radius)
	_check("nests you left behind empty out again", e.alive_count == 0)
	e.clear()
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
	_check("the Heart is far from the start", m.heart_pos.length() > 150.0)
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
	_check("the Heart is sealed while guardians live", m.hp[c] == Defs.CUBES[Defs.HEART]["hp"] and not r.heart_woken)
	r.bosses.killed = Defs.BOSSES.size()
	m.strike(c, 1e9, 0.0)
	r.bosses.killed = 0
	r.heart_woken = false
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
	t.update(0.016)
	var long := int(t.size("drill") / Mine.CELL) * Mine.CELL
	_check("the drill's strip covers the 3 cubes across it bites", t._strip.visible and is_equal_approx(t._strip.scale.x, 1.5) and is_equal_approx(t._strip.scale.z, long))
	t.apply({"kind": "evolve", "id": "drill"})
	_check("evolving makes it stronger", t.dmg("drill") > dmg * 1.4 and t.power_of("drill") == power and r.evolutions == 1)
	_check("and it can't evolve twice", not _offers(t, "drill"))
	t.apply({"kind": "evolve", "id": "shovel"})
	_check("the Great Scoop swings all around", t._shovel_arc() == PI)
	t.update(0.016)
	_check("and widens with the Tunnel Borer, to 7 cubes", is_equal_approx(t._strip.scale.x, 3.5))
	t.evolved.clear()
	t._build_slash()
	r.evolutions = 0
	r.mine.update(1.0)


## Nothing points at the Heart: veins lead there, and its beat gets closer.
func _check_clues(r: Run) -> void:
	var m := r.mine
	_check("veins run through the rock (%d)" % m.kind.count(Defs.VEIN), m.kind.count(Defs.VEIN) > 500)
	var near := 0
	var far := 0
	for k in 12:
		var a := TAU * k / 12.0
		for d in [12.0, 60.0]:
			var p: Vector3 = m.heart_pos + Vector3(cos(a), 0, sin(a)) * d
			for x in range(-4, 5):
				for z in range(-4, 5):
					if m.kind_at(p + Vector3(x, 0, z) * Mine.CELL) == Defs.VEIN:
						if d < 20.0:
							near += 1
						else:
							far += 1
	_check("veins get thicker toward the Heart (%d near, %d far)" % [near, far], near > far)
	r._beat_left = 0.0
	r.heart_woken = false
	r._update_heartbeat(0.016, Vector3(9999, 0, 0))
	_check("you can't hear it from far off", is_equal_approx(r._beat_left, 0.5 - 0.016))
	r._beat_left = 0.0
	r._update_heartbeat(0.016, m.heart_pos + Vector3(100, 0, 0))
	var slow := r._beat_left
	r._beat_left = 0.0
	r._update_heartbeat(0.016, m.heart_pos + Vector3(10, 0, 0))
	_check("it beats faster the closer you get (%.2f, then %.2f)" % [slow, r._beat_left], r._beat_left < slow)


## The map shows what you know and nothing more; its button opens it with a tap and peeks with a hold.
func _check_map(r: Run) -> void:
	var m := r.mine
	var map := m.map
	var was := Options.fog
	Options.fog = true
	var at := r.player.global_position
	m.carve(at, 1.0)
	m.scan_light(at)
	var c := m.cell_of(at.x) + m.cell_of(at.z) * Mine.SIZE
	_check("the map shows open ground you have seen", m.known_at(c) == 0 and map.color_of(c) != MineMap.CLEAR)
	var far := c + 400
	while far < c + 600 and m.kind[far] == 0:
		far += 1
	_check("and nothing you haven't (%d)" % m.known_at(far), map.color_of(far) == MineMap.CLEAR)
	Options.fog = false
	_check("without fog it shows the whole mine", map.color_of(far) != MineMap.CLEAR)
	Options.fog = true
	map.mark(c)
	map.update(at, 1e9)
	var tile := (c % Mine.SIZE) / MineMap.TILE + (c / Mine.SIZE / MineMap.TILE) * MineMap.TILES
	_check("the piece you stand on is drawn", map.textures[tile] != null)
	Options.fog = was
	var press := InputEventAction.new()
	press.action = "map"
	press.pressed = true
	var release := InputEventAction.new()
	release.action = "map"
	r.close_map()
	r._unhandled_input(press)
	r._unhandled_input(release)
	_check("a tap opens the full map", r.hud.map_full.visible)
	r._unhandled_input(press)
	r._unhandled_input(release)
	_check("another tap closes it", not r.hud.map_full.visible)
	r._unhandled_input(press)
	r._map_down -= 1000
	var peek := r.hud.map_full.visible
	r._unhandled_input(release)
	_check("holding it shows it until you let go", peek and not r.hud.map_full.visible)
	r._unhandled_input(press)
	r._unhandled_input(release)
	r._freeze()
	get_tree().paused = false
	_check("a menu closes it", not r.hud.map_full.visible)
	var o := Options.map_opacity
	Options.next_map_opacity()
	_check("map opacity steps through its settings (%s)" % Options.map_text(), Options.map_opacity != o)
	Options.map_opacity = o


## The How to play page fills its numbers from Defs, so a broken format would show here.
func _check_help() -> void:
	var parts := Help.sections()
	var lines := 0
	for part in parts:
		for line in part[1]:
			lines += 1 if String(line).length() > 20 else 0
	_check("the How to play page has %d sections and %d lines" % [parts.size(), lines], parts.size() >= 8 and lines > 25)
	var menu := Menu.new()
	add_child(menu)
	menu._show_help()
	_check("the How to play page scrolls, with Back below", menu._scroll != null and menu._root.get_child(menu._root.get_child_count() - 1) is Button)
	# A wide window doesn't make the screen taller than 720, so every page has to fit that without scrolling.
	var screen := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var keys := " ".join(Help.controls().map(func(c): return " ".join(c)))
	_check("the controls name the map keys", keys.contains("M or Tab") and keys.contains("Back"))
	_check("and the dash keys", keys.contains("Space or Shift"))
	for page in ["_show_main", "_show_characters", "_show_shop", "_show_goals", "_show_help", "_show_options", "_show_reset", "_show_controls"]:
		menu.call(page)
		var need := menu._root.get_combined_minimum_size().y
		_check("menu page %s fits the screen (%.0f of %.0f)" % [page.trim_prefix("_show_"), need, screen], need <= screen - 30.0)
	menu.free()  # at once, so its deferred focus grab never lands on later steps


## Countdowns keep the part of a frame past zero, so things fire as often at any frame rate.
func _check_timers() -> void:
	var counts: Array[int] = []
	for fps in [30, 60, 144, 165, 240]:
		var left := 0.0
		var fired := 0
		for f in fps * 10:
			left -= 1.0 / fps
			if left <= 0.0:
				left = Defs.restart(left, 0.065, 1.0 / fps)
				fired += 1
		counts.append(fired)
	_check("a 0.065 s cooldown fires the same at 30 to 240 fps (%s)" % [counts], counts.max() - counts.min() <= 1 and absi(counts[0] - 154) <= 1)
	_check("a tool that waited starts a fresh countdown", is_equal_approx(Defs.restart(-5.0, 0.3, 0.016), 0.3 - 0.016))


func _check_seams(r: Run) -> void:
	var m := r.mine
	_check("fuel seams run through the mine (%d)" % m.kind.count(Defs.FUEL), m.kind.count(Defs.FUEL) > 2000)
	var at := Vector3(0, 0, -4)
	_fill(r, at, 0, 0)
	var cz := m.cell_of(-4.0)
	var first := m.cell_of(-10.0) + cz * Mine.SIZE
	for k in 40:
		_set_cube(m, first + k, Defs.FUEL)
	var mob := r.enemies.spawn(Enemies.CRAWLER, m.pos_of(first + 30), -1, true)
	r.player.invuln = 0.0
	r._burn_idle = 9.0
	r.seams = 0
	var before := r.cubes
	m.strike(first, 1e9, 0.0)
	_check("a fuel seam doesn't burn all at once", r.cubes - before < 5)
	m.update(0.1)
	var part := r.cubes - before
	for k in 60:
		m.update(0.05)
	_check("it burns along its whole length", part < 20 and m.kind[first + 39] == 0 and r.cubes - before >= 40)
	_check("and counts as one seam", r.seams == 1)
	_check("the fire kills what stands by it", not r.enemies.is_alive(mob))
	r.enemies.clear()
	_clear_gems(r)
	r.pending_levelups = 0
	r.combo = 0
	r._frenzy_base = 0
	r.frenzy_left = 0.0
	m.update(1.0)


func _check_caves(r: Run) -> void:
	var m := r.mine
	var e := r.enemies
	var t := r.traps
	_check("loose rock is in the mine (%d)" % m.kind.count(Defs.LOOSE), m.kind.count(Defs.LOOSE) > 300)
	_fill(r, Vector3(0, 0, 8), 16, 0)
	r.player.global_position = Vector3(0, 0, 4)
	r.god_mode = false
	r.player.invuln = 0.0
	r.player.hp = r.player.max_hp
	var at := Vector3(0, 0, 8)
	_fill(r, at, 0, Defs.LOOSE)
	var mob := e.spawn(Enemies.BRUTE, at + Vector3(2, 0, 0), -1, true)
	var boss := e.spawn(Enemies.BORER, at + Vector3(-2, 0, 0), -1, true)
	var c := m.cell_of(at.x) + m.cell_of(at.z) * Mine.SIZE
	m.strike(c, 1e9, 0.0)
	_check("loose rock gives way", m.kind[c] == 0)
	_check("rubble doesn't land at once", m.kind_at(at + Vector3(2, 0, 0)) == 0 and e.is_alive(mob))
	t.update(float(Defs.RUN["cave_warn"]) * 0.5, r.player.global_position)
	_check("nothing falls during the warning", m.kind_at(at) == 0)
	var you := Vector3(0, 0, 4)
	r.crushed = 0
	t.update(float(Defs.RUN["cave_warn"]), you)
	_check("then the tunnel fills with rubble", m.kind_at(at + Vector3(1, 0, 0)) == Defs.RUBBLE and m.kind_at(at + Vector3(0, 0, 3)) == Defs.RUBBLE)
	_check("what stood there is crushed", not e.is_alive(mob) and r.crushed >= 1)
	_check("a boss only takes a hit", e.is_alive(boss) and e.hp[boss] < e.full[boss])
	_check("you get a pocket to stand in", m.kind_at(you) == 0)
	_check("and it hurts if you stayed", r.player.hp < r.player.max_hp)
	_check("beyond the reach nothing changes", m.kind_at(at + Vector3(0, 0, 6)) == 0)
	m.update(1.0)
	_check("all of it has landed", m._fall_c.is_empty())
	var cell := m.cell_of(at.x + 1.0) + m.cell_of(at.z) * Mine.SIZE
	m.strike(cell, r.tools.dmg("shovel") * 2.0, 0.0)
	_check("rubble is weak", m.kind[cell] == 0)
	e.clear()
	_fill(r, Vector3(0, 0, 8), 16, 0)
	var lift: Vector3 = m.lifts[0]
	_fill(r, lift, 12, 0)
	m.collapse(lift, 5.0, Vector3(99, 0, 99), 1.0)
	_check("lifts stay clear", m.kind_at(lift) == 0 and m.kind_at(lift + Vector3(3.5, 0, 0)) == Defs.RUBBLE)
	m.update(1.0)
	_fill(r, lift, 12, 0)
	_clear_gems(r)
	r.god_mode = true
	r.player.global_position = Vector3.ZERO
	r.player.invuln = 0.0
	r.player.hp = r.player.max_hp
	r.pending_levelups = 0
	r.combo = 0
	r._frenzy_base = 0


func _set_cube(m: Mine, c: int, k: int) -> void:
	m.kind[c] = k
	m.hp[c] = float(Defs.CUBES[k].get("hp", 0.0))


func _check_bosses(r: Run) -> void:
	var b := r.bosses
	var e := r.enemies
	_check("the Heart waits for every guardian", b.left() == Defs.BOSSES.size())
	r.run_time = Defs.BOSSES[0]["at"] - 1.0
	b.update(0.016, Vector3.ZERO)
	_check("no boss before its time", b.current < 0)
	r.run_time += 2.0
	b.update(0.016, Vector3.ZERO)
	_check("a boss comes on time", e.is_alive(b.current) and e.etype[b.current] == Enemies.BORER and not b.fight().is_empty())
	_check("a boss arrives off screen", _seen_count(r) == 0)
	var i := b.current
	e.pos[i] = Vector3(10, 0, 0)
	e.update(0.016, Vector3(200, 0, 0), r.player.radius)
	_check("a boss doesn't lose you", e.is_alive(i))
	b.update(0.016, Vector3(200, 0, 0))
	_check("it catches up when you run", Vector2(e.pos[i].x - 200.0, e.pos[i].z).length() < float(Defs.RUN["boss_leash"]))
	e.pos[i] = Vector3(10, 0, 0)
	b._timer = 0.0
	b.update(0.016, Vector3.ZERO)
	_check("the Borer stops to aim", b._state == "aim" and e.speed[i] == 0.0)
	b._timer = 0.0
	b.update(0.016, Vector3.ZERO)
	var from: Vector3 = e.pos[i]
	b.update(0.1, Vector3.ZERO)
	_check("then charges in a line", b._state == "charge" and e.pos[i].x < from.x)
	var levels := r.pending_levelups
	r.run_time = 500.0
	e.hit(i, 1e9, Vector3.ZERO)
	_check("a dead boss pays out", b.killed == 1 and b.current < 0 and r.pending_levelups == levels + int(Defs.RUN["boss_levels"]) and r.pickups.g_pos.size() >= int(Defs.RUN["boss_gems"]))
	b.update(0.016, Vector3.ZERO)
	_check("the next one takes a while", b.current < 0)
	r.run_time += float(Defs.RUN["boss_gap"]) + 1.0
	b.update(0.016, Vector3.ZERO)
	_check("then the Brood comes", e.is_alive(b.current) and e.etype[b.current] == Enemies.BROOD)
	var alive := e.alive_count
	b._timer = 0.0
	b.update(0.016, Vector3.ZERO)
	_check("it drops crawlers", e.alive_count > alive)
	e.hit(b.current, 1e9, Vector3.ZERO)
	_check("with both dead the Heart is open", b.left() == 0 and b.current < 0)
	b.killed = 0
	b._next_at = Defs.BOSSES[0]["at"]
	r.run_time = 0.0
	r.pending_levelups = 0
	r._update_chains(float(Defs.FRENZY["time"]) + 0.1)
	r.combo = 0
	r._frenzy_rest = 0.0
	r._frenzy_base = 0
	r.frenzies = 0
	e.clear()
	_clear_gems(r)
	for k in 12:
		r.traps.update(0.2, Vector3(9999, 0, 0))
	r.mine.update(1.0)
	r.player.invuln = 0.0
	r.player.hp = r.player.max_hp


## Full slots stop new tools and boosts; the Tool Belt adds one of each per level.
func _check_slots(r: Run) -> void:
	var t := r.tools
	var saved := [t.owned.duplicate(true), t.order.duplicate(), t.boosts.duplicate(), t.boost_order.duplicate(), Profile.shop.duplicate(), Profile.unlocked.duplicate()]
	Profile.shop.erase("slots")
	Profile.unlocked["tool:bombs"] = true
	t.owned.clear()
	t.order.clear()
	t.boosts.clear()
	t.boost_order.clear()
	_check("a new profile has %d tool and %d boost slots" % [Defs.SLOTS["tools"], Defs.SLOTS["boosts"]], t.tool_slots() == 4 and t.boost_slots() == 4)
	for id in ["shovel", "drill", "saws"]:
		t.add_tool(id)
	var last := false
	for k in 100:
		for o in t.level_up_options(3):
			last = last or o["hint"] == "Last tool slot"
	_check("a new tool for the fourth slot says it is the last", last)
	t.add_tool("bombs")
	for id in ["haste", "reach", "power", "magnet"]:
		t.add_boost(id)
	var fresh := 0
	for k in 200:
		for o in t.level_up_options(3):
			if o["kind"] in ["tool", "boost"] and o["level_text"] == "NEW":
				fresh += 1
	_check("with every slot full, cards only level up what you hold (%d new)" % fresh, fresh == 0)
	Profile.shop["slots"] = Defs.SHOP["slots"]["max"]
	var boosts := 0
	for k in 200:
		for o in t.level_up_options(3):
			if o["kind"] == "boost" and o["level_text"] == "NEW":
				boosts += 1
	_check("a full Tool Belt makes 6 of each, so new boosts come back", t.tool_slots() == 6 and t.boost_slots() == 6 and boosts > 0)
	_check("the level-up screen says what is free", t.slots_text() == "Tools 4/6  ·  Boosts 4/6")
	t.owned = saved[0]
	t.order = saved[1]
	t.boosts = saved[2]
	t.boost_order = saved[3]
	Profile.shop = saved[4]
	Profile.unlocked = saved[5]
	r.apply_boosts()
	_check_bomb_aim(r)


## Steps the digger, the dash and the horde by hand, so the checks don't depend on frame timing.
func _sim(r: Run, frames: int, input := Vector2.ZERO) -> void:
	var dt := 1.0 / 60.0
	for i in frames:
		r.player.move(dt, input, r.mine)
		r.dash.update(dt)
		r.enemies.update(dt, r.player.global_position, r.player.radius)


## A sturdy crawler that stays awake and in place until the check moves it.
func _dummy(r: Run, at: Vector3) -> int:
	var i := r.enemies.spawn(Enemies.CRAWLER, at, -1, true)
	r.enemies.hp[i] = 1e6
	r.enemies.full[i] = 1e6
	return i


## The Dash Drive: its slot, its upgrade cards, the dash itself, and the decoy clone with its blast.
func _check_dash(r: Run) -> void:
	var d := r.dash
	var p := r.player
	var e := r.enemies
	var t := r.tools
	var saved := [t.owned.duplicate(true), t.order.duplicate()]
	r.god_mode = false
	t.owned.clear()
	t.order.clear()
	t.add_tool("shovel")
	_clear_around(r)
	e.clear()
	p.global_position = Vector3.ZERO
	p.invuln = 0.0
	p.hp = p.max_hp

	var keys: Array = InputMap.action_get_events("dash").filter(func(ev): return ev is InputEventKey).map(func(ev): return (ev as InputEventKey).physical_keycode)
	var pad: Array = InputMap.action_get_events("dash").filter(func(ev): return ev is InputEventJoypadButton).map(func(ev): return (ev as InputEventJoypadButton).button_index)
	_check("Space and Shift dash, and so does the gamepad's A", keys.has(KEY_SPACE) and keys.has(KEY_SHIFT) and pad.has(JOY_BUTTON_A))

	# Slot and cards.
	t.add_tool("drill")
	t.add_tool("saws")
	var card := {}
	for o in t.level_up_options(100):
		if o["kind"] == "dash":
			card = o
	_check("level-ups offer the Dash Drive while a tool slot is free", card.get("id", "") == "dash")
	_check("for the last free slot its card says so", card.get("hint", "") == "Last tool slot")
	t.apply(card)
	_check("taking it fills a tool slot (%s)" % t.slots_text(), d.owned and t.slots_used() == 4 and t.slots_text().begins_with("Tools 4/"))
	var fresh := 0
	for k in 100:
		for o in t.level_up_options(3):
			if o["kind"] in ["tool", "dash"] and o["level_text"] == "NEW" and o["id"] in ["bombs", "dash", "pulse"]:
				fresh += 1
	_check("with the tool slots full no new tool is offered", fresh == 0)
	var mod_new := 0
	for id in Defs.DASH["mods"]:
		if d.mod_option(id, 0)["level_text"] == "NEW":
			mod_new += 1
	_check("a dash upgrade's first level is not marked NEW (%s)" % d.mod_option("length", 0)["level_text"], mod_new == 0)
	var avail := d.available_mods(d.mods)
	_check("the clone's upgrades stay locked until the clone is taken", avail.has("clone") and not avail.has("clone_hp") and not avail.has("clone_boom"))
	t.apply(d.mod_option("clone", 0))
	avail = d.available_mods(d.mods)
	_check("taking the clone unlocks them", not avail.has("clone") and avail.has("clone_hp") and avail.has("clone_boom"))
	var dash_cards := 0
	for k in 100:
		dash_cards = maxi(dash_cards, t.level_up_options(3).filter(func(o): return o["kind"] == "dash").size())
	_check("a level-up never fills all three cards with dash upgrades (%d)" % dash_cards, dash_cards >= 1 and dash_cards <= 2)

	# The dash goes the way you steer, takes time, and nothing touches you.
	var far := d.dash_distance()
	var hp := p.hp
	var near := _dummy(r, Vector3(0.5, 0, 0.9))
	d.cooldown = 0.0
	_check("a dash is ready", d.can_dash())
	Input.action_press("move_right")
	r._try_dash()
	Input.action_release("move_right")
	_check("the dash button goes the way you steer", p.bursting() and not d.can_dash())
	_check("a dash leaves a clone where you stood", d.clone_alive() and d.clone_pos.length() < 0.01)
	_check("and starts the cooldown (%.1f s)" % d.cooldown, is_equal_approx(d.cooldown, d.dash_cooldown()) and d.cooldown_total == d.cooldown)
	var untouchable := true
	var frames := 0
	while p.bursting() and frames < 60:
		_sim(r, 1)
		untouchable = untouchable and p.invuln > 0.0
		frames += 1
	var end := p.global_position
	_check("the dash covers its distance (%.2f of %.2f m)" % [end.x, far], absf(end.x - far) < 0.1 and absf(end.z) < 0.05)
	_check("nothing hurts you during it, even an enemy beside you", untouchable and p.hp == hp)
	_check("the grace lasts a moment after it (%.2f s)" % p.invuln, p.invuln > 0.0 and p.invuln <= float(Defs.DASH["base"]["grace"]))
	e.remove(near)

	# With no input it goes the way you last walked.
	_sim(r, 1, Vector2.LEFT)
	d.cooldown = 0.0
	p.global_position = Vector3(0, 0, 8)
	r._try_dash()
	_sim(r, 30)
	_check("standing still, it goes the way you last walked (%.1f m left)" % -(p.global_position.x), p.global_position.x < -far * 0.9 and absf(p.global_position.z - 8.0) < 0.05)

	# Rock stops it, even at speed.
	p.global_position = Vector3.ZERO
	d.cooldown = 0.0
	_fill(r, Vector3(4, 0, 0), 1, 5)
	d.trigger(Vector3.RIGHT)
	_sim(r, 30)
	var edge: float = r.mine._world(r.mine.cell_of(4.0) - 1) - Mine.CELL * 0.5  # where the block of cubes begins
	var stop := edge - p.radius
	_check("a wall stops the dash (x %.2f, wall at %.2f)" % [p.global_position.x, edge], p.global_position.x <= stop + 0.05 and p.global_position.x > stop - 0.4)
	_fill(r, Vector3(4, 0, 0), 1, 0)

	# The clone: enemies close to it go for it, and it wears down.
	e.clear()
	p.global_position = Vector3.ZERO
	p.invuln = 0.0
	d.cooldown = 0.0
	d.trigger(Vector3.RIGHT)
	while p.bursting():
		_sim(r, 1)
	var at_clone := _dummy(r, d.clone_pos + Vector3(0, 0, 5))
	var at_you := _dummy(r, p.global_position + Vector3(3, 0, 0))
	p.invuln = 0.0
	var before := e.pos[at_clone]
	_sim(r, 1)
	_check("an enemy nearer the clone heads for the clone", absf(e.pos[at_clone].x - before.x) < 0.01 and e.pos[at_clone].z < before.z - 0.02)
	_check("an enemy nearer you still heads for you", e.pos[at_you].x < p.global_position.x + 3.0 - 0.02)
	e.remove(at_you)
	e.remove(at_clone)
	var touching := _dummy(r, d.clone_pos + Vector3(0.6, 0, 0))
	hp = p.hp
	d._gate = 0.0
	_sim(r, 1)
	_check("touching the clone hurts it by the enemy's damage (%.1f of %.1f)" % [d.clone_hp, d.clone_max_hp], is_equal_approx(d.clone_hp, d.clone_max_hp - e.dmg[touching]))
	var after_hit := d.clone_hp
	_sim(r, 5)
	_check("it takes one hit at a time, like you", d.clone_hp == after_hit)
	_sim(r, 10)
	_check("and the next one once the gap is over", d.clone_hp < after_hit)
	_check("the car stays unharmed", p.hp == hp)
	e.remove(touching)
	var wide := d.clone_health()
	t.apply(d.mod_option("clone_hp", 0))
	_check("Reinforced Clone adds 50%% health (%.0f to %.0f)" % [wide, d.clone_health()], is_equal_approx(d.clone_health(), wide * 1.5))
	d._gate = 0.0
	d.hurt_clone(1e6)
	_check("it falls when its health runs out", not d.clone_alive())
	var gone := _dummy(r, d.clone_pos + Vector3(-2, 0, 0))
	_sim(r, 2)
	_check("then the horde turns back to you", not e.decoy_active)
	_check("without the blast it just disappears", e.hp[gone] == 1e6)
	e.remove(gone)

	# The blast.
	e.clear()
	p.global_position = Vector3.ZERO
	d.cooldown = 0.0
	t.apply(d.mod_option("clone_boom", 0))
	d.trigger(Vector3.RIGHT)
	while p.bursting():
		_sim(r, 1)
	var victim := _dummy(r, d.clone_pos + Vector3(2, 0, 0))
	d._gate = 0.0
	d.hurt_clone(1e6)
	_sim(r, 1)
	var blast: float = e.full[victim] - e.hp[victim]
	_check("Volatile Clone explodes when it falls (%.0f damage)" % blast, absf(blast - d.blast_damage()) < 0.5 and blast > 90.0)
	e.remove(victim)
	var first := d.blast_damage()
	var radius := d.blast_radius()
	t.apply(d.mod_option("clone_boom", 1))
	_check("its second level hits 40% harder and wider", is_equal_approx(d.blast_damage(), first * 1.4) and d.blast_radius() > radius * 1.1)
	d.cooldown = 0.0
	d.trigger(Vector3.RIGHT)
	d.clear()
	_check("clearing a clone on purpose does not blow it up", not d.clone_alive())

	# The other mods and what they cost.
	var span := d.dash_distance()
	var wait := d.dash_cooldown()
	t.apply(d.mod_option("length", 0))
	t.apply(d.mod_option("speed", 0))
	t.apply(d.mod_option("recharge", 0))
	_check("Long Dash and Dash Speed lengthen the dash (%.1f to %.1f m)" % [span, d.dash_distance()], is_equal_approx(d.dash_distance(), span * 1.2 * 1.15))
	_check("Quick Recharge shortens the wait (%.2f to %.2f s)" % [wait, d.dash_cooldown()], is_equal_approx(d.dash_cooldown(), wait * 0.85))
	r.dead = true
	_check("a dead digger can't dash", not d.can_dash())
	r.dead = false
	d.give_all()
	r._update_power()
	var crowd := r.crowd
	d.owned = false
	d.mods.clear()
	r._update_power()
	_check("the Dash Drive and its mods count towards the enemies' scaling (crowd %.2f with, %.2f without)" % [crowd, r.crowd], crowd > r.crowd)
	d.owned = true
	r.hud.refresh(r)
	_check("the HUD shows the dash bar once it is held", r.hud._dash_bar.visible)

	# Back to how the other checks expect it.
	d.clear()
	d.owned = false
	d.mods.clear()
	d.cooldown = 0.0
	e.clear()
	p.global_position = Vector3.ZERO
	p.invuln = 0.0
	p.dash_left = 0.0
	t.owned = saved[0]
	t.order = saved[1]
	r.god_mode = true
	r.hud.refresh(r)


## Bombs aim themselves: a close enemy first, else rock, rock ahead first, else nothing.
func _check_bomb_aim(r: Run) -> void:
	var t := r.tools
	var e := r.enemies
	var at := Vector3(0, 0, 0)
	var reach: float = Defs.TOOLS["bombs"]["throw"]
	var steps := int(reach / Mine.CELL) + 2
	_fill(r, at, steps, 0)
	e.clear()
	_check("with nothing in reach, no bomb", t.bomb_target(at, Vector3.RIGHT) == Vector3.INF)
	_fill(r, Vector3(-2, 0, 0), 0, 1)
	_fill(r, Vector3(4, 0, 0), 0, 1)
	var to := t.bomb_target(at, Vector3.RIGHT)
	_check("bombs go at rock ahead before closer rock behind", to.x > 3.0)
	to = t.bomb_target(at, Vector3.UP.cross(Vector3.RIGHT))
	_check("and at the nearest rock when none is ahead", to.x < -1.0)
	var picked := {}
	for k in 4:
		e.spawn(Enemies.CRAWLER, Vector3(0, 0, 2.0 + k), -1, true)
	e.spawn(Enemies.CRAWLER, Vector3(0, 0, reach + 3.0), -1, true)
	for k in 60:
		picked[snappedf(t.bomb_target(at, Vector3.RIGHT).z, 0.5)] = true
	_check("an enemy in reach beats rock, one of the %d closest" % int(Defs.TOOLS["bombs"]["pick"]),
		picked.size() == int(Defs.TOOLS["bombs"]["pick"]) and picked.keys().all(func(z): return z >= 2.0 and z <= 4.0))
	e.clear()
	_fill(r, at, steps, 0)


func _check_new_tools(r: Run) -> void:
	var t := r.tools
	var e := r.enemies
	var m := r.mine
	t.add_tool("spark")
	var a := e.spawn(Enemies.BRUTE, Vector3(3, 0, 0), -1, true)
	var b := e.spawn(Enemies.BRUTE, Vector3(5, 0, 0), -1, true)
	var hp: float = e.hp[b]
	t._spark(m, r.player, Vector3.ZERO)
	_check("sparks jump from enemy to enemy", e.hp[a] < e.full[a] and e.hp[b] < hp)
	e.clear()
	_fill(r, Vector3(3, 0, 0), 3, 5)
	r.player.heading = Vector3.RIGHT
	var cubes := m.kind.count(5)
	for k in 12:
		t._spark(m, r.player, Vector3.ZERO)
	m.update(1.0)
	_check("with no enemies they bite rock", t._spark(m, r.player, Vector3.ZERO) or m.kind.count(5) < cubes)
	_fill(r, Vector3(3, 0, 0), 3, 0)
	t.add_tool("moles")
	_fill(r, Vector3.ZERO, 30, 5)
	for k in 200:
		t._update_moles(0.05, m, Vector3.ZERO)
		t.owned["moles"]["timer"] = 0.0
	m.update(1.0)
	var worn := 0
	for c in range(0, m.hp.size()):
		if m.kind[c] == 5 and m.hp[c] < 40.0:
			worn += 1
	_check("moles bite rock on their own (%d)" % worn, worn > 5 or m.kind.count(0) > 0)
	_fill(r, Vector3.ZERO, 30, 0)
	t.owned.erase("spark")
	t.order.erase("spark")
	t.owned.erase("moles")
	t.order.erase("moles")
	t._update_moles(0.05, m, Vector3.ZERO)
	_clear_gems(r)
	r.pending_levelups = 0
	r.combo = 0
	r._frenzy_base = 0
	m.update(1.0)


## The reset button: the file goes too, and a new start really is empty.
func _check_wipe() -> void:
	Profile.saving = true
	Profile.file = "user://test_profile.cfg"
	Profile.gems = 77
	Profile.shop["power"] = 3
	Profile.save()
	Profile.wipe()
	_check("a reset goes back to zero", Profile.gems == 0 and Profile.shop.is_empty())
	Profile.load_file()
	_check("and stays there after a reload", Profile.gems == 0 and Profile.shop.is_empty() and not FileAccess.file_exists(Profile.file))
	Profile.saving = false
	Profile.file = Profile.PATH
	Profile.reset()


func _offers(t: Tools, id: String) -> bool:
	return t._evolution_options().any(func(o): return o["id"] == id)


func _all_reachable() -> bool:
	var keys: Array = Defs.GOALS.map(func(g): return g.get("unlock", ""))
	for id in Defs.CHARACTERS:
		if Defs.CHARACTERS[id].get("locked", false) and not keys.has("char:" + id):
			return false
	for id in ["bombs", "pulse", "spark", "moles"]:
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
	r.bosses.killed = Defs.BOSSES.size()
	m.strike(c, 1.0, 0.0)
	r.bosses.killed = 0
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
	r.heart_woken = false
	m.heart_left = 1.0
	_clear_gems(r)


func _check_pause(r: Run) -> void:
	r._open_pause()
	_check("the pause menu opens with the fog switch", r._paused_by_menu and r.overlay._panel_root.visible)
	r._show_controls()
	var grid := r.overlay._panel_box.get_children().filter(func(c): return c is GridContainer and not c.is_queued_for_deletion())
	_check("the pause menu shows the controls", grid.size() == 1 and grid[0].get_child_count() == 3 * (Help.controls().size() + 1))
	r._toggle_pause()
	_check("Esc on the controls goes back to the pause menu", r._paused_by_menu and r._pause_page == "" and r.overlay.panel_visible())
	r.overlay.hide_panel()
	r._resume()
	_start_hitstop(r)
	r.pending_levelups = 1
	r._try_open_modal()
	_check("level-up cards open at full speed during a hitstop", r._modal_open and Engine.time_scale == r.base_time_scale)
	r.levelup_ui.visible = false
	r.pending_levelups = 0
	r._close_modal()
	_start_hitstop(r)
	r.use_shrine("blood")
	_check("a shrine opens at full speed during a hitstop", r._modal_open and Engine.time_scale == r.base_time_scale)
	r.levelup_ui.visible = false
	r._close_modal()
	_start_hitstop(r)
	r._open_pause()
	_check("the pause menu opens at full speed during a hitstop", Engine.time_scale == r.base_time_scale)
	r.overlay.hide_panel()
	r._resume()


func _start_hitstop(r: Run) -> void:
	r._hitstop(0.12)
	r._update_time_scale()
	_check("a hitstop slows the game", Engine.time_scale < r.base_time_scale)


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
	var was_pad := Options.pad
	Options.pad = false
	r._mouse_seen = false
	r.player.heading = Vector3.RIGHT
	_mouse_nudge(0.0, -20.0)
	r._update_aim(0.016)
	var reach: float = Defs.AIM["reach"]
	_check("the mouse picks up from where you face", r._aim_offset.x > reach * 0.9 and r.player.heading.x > 0.9 and r.player.aiming)
	_mouse_nudge(0.0, 1000.0)
	r._update_aim(0.016)
	_check("pushing the mouse out keeps the hidden pointer on the ring", is_equal_approx(r._aim_offset.length(), reach) and r.player.heading.z > 0.9)
	_check("the arrow sits on the ring where you aim", r._aim_mark.visible and r._aim_ring.visible
		and is_equal_approx(Vector2(r.aim_point.x, r.aim_point.z).distance_to(Vector2(r.player.global_position.x, r.player.global_position.z)), Defs.AIM["ring"]))
	var aimed := r.player.heading
	r.player.global_position += Vector3(5, 0, 5)
	r._update_aim(0.016)
	_check("walking doesn't turn the mouse's aim", r.player.heading.is_equal_approx(aimed))
	r.player.global_position -= Vector3(5, 0, 5)
	_mouse_nudge(0.0, -2.0 * reach)
	r._update_aim(0.016)
	_check("a push across turns the aim around", r.player.heading.z < -0.9)
	var lean: Vector3 = r._cam_targets()[1] - r.player.global_position - r.player.velocity * Defs.CAMERA["lead"]
	_check("the camera leans a fixed amount the way you aim", lean.is_equal_approx(r.player.heading * Defs.CAMERA["aim_lean"]))
	Options.pad = was_pad
	r._mouse_seen = false
	r.player.aiming = false
	r.player.heading = Vector3.FORWARD


func _pad_axis(axis: JoyAxis, value: float, device := 0) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	ev.device = device
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _pad_button(button: JoyButton) -> void:
	for pressed in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.button_index = button
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()


func _press_key(key: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		ev.keycode = key
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()


func _mouse_nudge(amount: float, down := 0.0) -> void:
	var ev := InputEventMouseMotion.new()
	ev.screen_relative = Vector2(amount, down)
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _check_pad(r: Run) -> void:
	Options.pad = false
	r.player.aiming = false
	_pad_axis(JOY_AXIS_LEFT_X, 0.1)
	_check("a drifting stick doesn't walk or count as a gamepad", r._move_input(0.016) == Vector2.ZERO and not Options.pad)
	_pad_axis(JOY_AXIS_LEFT_X, 0.8)
	_check("the left stick walks", r._move_input(0.016).x > 0.5 and Options.pad)
	_pad_axis(JOY_AXIS_LEFT_X, 0.0)
	_pad_axis(JOY_AXIS_LEFT_Y, 0.8, 1)
	_check("a gamepad in another slot works too", r._move_input(0.016).y > 0.5)
	_pad_axis(JOY_AXIS_LEFT_Y, 0.0, 1)
	_pad_axis(JOY_AXIS_RIGHT_X, 0.1)
	r._update_aim(0.016)
	_check("a drifting right stick doesn't aim", not r.player.aiming and not r._aim_mark.visible)
	_pad_axis(JOY_AXIS_RIGHT_X, -0.9)
	r._update_aim(0.016)
	_check("the right stick aims and shows a target", r.player.aiming and r.player.heading == Vector3.LEFT and r._aim_mark.visible)
	r.player.move(0.016, Vector2.RIGHT, r.mine)
	_check("walking doesn't turn the right stick's aim", r.player.heading == Vector3.LEFT)
	_pad_axis(JOY_AXIS_RIGHT_X, 0.0)
	r._update_aim(0.016)
	_check("letting go keeps the aim a moment", r.player.aiming)
	r._update_aim(Defs.PAD["aim_hold"])
	_check("then tools follow your walk again", not r.player.aiming and not r._aim_mark.visible)
	r.player.move(0.016, Vector2.RIGHT, r.mine)
	_check("a gamepad player with no aim points the way they walk", r.player.heading == Vector3.RIGHT)
	r._mouse_seen = true
	r.player.aiming = true
	r._update_aim(0.016)
	_check("a gamepad takes over from a parked mouse", not r._mouse_seen and not r.player.aiming)
	_mouse_nudge(1.0)
	_check("a nudged desk doesn't take the game off the gamepad", Options.pad)
	_mouse_nudge(50.0)
	_check("moving the mouse takes over from the gamepad", not Options.pad)
	r._mouse_seen = false
	r.player.aiming = false
	_pad_button(JOY_BUTTON_START)
	_check("Start pauses", r._paused_by_menu)
	_pad_button(JOY_BUTTON_START)
	_check("Start resumes", not r._paused_by_menu and not get_tree().paused and not r.overlay.panel_visible())
	_pad_button(JOY_BUTTON_START)
	_pad_button(JOY_BUTTON_B)
	_check("B leaves the pause menu", not r._paused_by_menu and not get_tree().paused and not r.overlay.panel_visible())
	_press_key(KEY_ESCAPE)
	_check("Esc pauses", r._paused_by_menu)
	_press_key(KEY_ESCAPE)
	_check("Esc resumes", not r._paused_by_menu and not get_tree().paused)


## On a shrine's two cards, as walking away changes nothing. Needs a frame after opening, for the
## cards to have a place on screen.
func _check_pad_cards(r: Run) -> void:
	var ui := r.levelup_ui
	var cards := ui._cards.get_children()
	var hp := r.player.hp
	_check("cards open with the first one picked out", cards.size() == 2 and cards[0].has_focus())
	_pad_axis(JOY_AXIS_LEFT_X, 0.8)
	_check("the left stick moves along the cards", cards[1].has_focus())
	_pad_axis(JOY_AXIS_LEFT_X, 0.95)
	_check("holding it moves only one card", cards[1].has_focus())
	_pad_axis(JOY_AXIS_LEFT_X, 0.0)
	_pad_button(JOY_BUTTON_DPAD_LEFT)
	_check("so does the d-pad", cards[0].has_focus())
	_pad_button(JOY_BUTTON_DPAD_RIGHT)
	ui._opened_at -= 1000
	_pad_button(JOY_BUTTON_A)
	_check("A takes the card picked out", not ui.visible and not r._modal_open and r.player.hp == hp)
	Options.pad = false


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
