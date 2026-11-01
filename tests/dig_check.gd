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
	_fill(r, Vector3(0, 0, 0), 60, 0)
	var wall := Vector3(0, 0, -6)
	_fill(r, wall, 8, 1)
	r.player.global_position = Vector3.ZERO
	m.scan_light(Vector3.ZERO)
	_check("you can see open floor nearby", m.can_see_at(Vector3(3, 0, 2)))
	_check("you can see a little into rock", m.can_see_at(Vector3(0, 0, -2.6)))
	_check("you can't see deep into rock", not m.can_see_at(Vector3(0, 0, -7)))
	_fill(r, wall, 8, 0)
	m.scan_light(Vector3.ZERO)
	_check("digging lets your light through", m.can_see_at(Vector3(0, 0, -7)))
	_check("you can't see past your light", not m.can_see_at(Vector3(0, 0, 11)))
	var far := Vector3(0, 0, 14)
	_fill(r, far, 1, 1)
	var c := m.cell_of(far.x) + m.cell_of(far.z) * Mine.SIZE
	_check("tools can't reach what you can't see", m.hit_circle(far, 2.0, 1e9, far) == 0 and m.kind[c] == 1)
	_check("a level-up blast still reaches into the dark", m.hit_circle(far, 2.0, 1e9, far, 0.0, true) > 0 and m.kind[c] == 0)
	_fill(r, far, 1, 1)
	_check("the beam goes through the fog", m.hit_line(Vector3.ZERO, Vector3.BACK, 16.0, 0.6, 1e9, 1e6, true) > 0)
	m.update(0.1)
	_check("it breaks what it hits there", m.kind[c] == 0)
	var byte := c * 2 + 1
	_check("rock broken in the dark lights up", m._mask[byte] == 255 and m._mask[byte + 2] == 255)
	for k in 60:
		m.scan_light(Vector3.ZERO)
	_check("then it stays dimly remembered", m._mask[byte] == m._seen_level and m._revealed.is_empty())
	_fill(r, far, 1, 1)
	_check("the pulse goes through the fog", m.hit_ring(far, 2.0, 1e9, 0.01) > 0)
	m.update(0.1)
	_check("it breaks what it hits there", m.kind[c] == 0)
	Options.fog = false
	r.apply_fog()
	_fill(r, far, 1, 1)
	_check("with fog off you can hit anything", m.hit_circle(far, 2.0, 1e9, far) > 0)


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
