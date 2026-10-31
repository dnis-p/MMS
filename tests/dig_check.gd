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
	_check("no enemies or health yet", not ("hp" in r.player))


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
