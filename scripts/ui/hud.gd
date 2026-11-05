class_name Hud
extends Control
## In-run heads-up display.

signal pause_pressed

var _xp_bar: ProgressBar
var _level_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _vignette: ColorRect
var _depth_label: Label
var _score_label: Label
var _cubes_label: Label
var _combo_label: Label
var _combo_sub: Label
var _icons: HBoxContainer
var _boost_icons: HBoxContainer
var _dash_bar: ProgressBar  # the Dash Drive's cooldown, once you hold it
var _dash_label: Label
var _dash_text := ""
var _dash_ready := false
var _goals_box: PanelContainer  # the objectives panel: the goals you are closest to, counting this run
var _goal_rows: Array = []  # per row: [row, text label, count label, bar]
var _goals_next := 0.0  # run time of the next refresh
var _map_rows: Array = []  # the map rows: guardians and the Heart
var _side_title: Label
var _hint: Label
var _fps_label: Label
var _compass: Control
var _lift_bar: ProgressBar
var _boss_bar: ProgressBar
var _boss_label: Label
var _gold: ColorRect
var _frenzy_bar: ProgressBar
var map_full: MapView  # over the whole screen while the map button says so
var minimap: MapView
var _run: Node
var _last_combo := 0
var _icon_key := ""


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_vignette = ColorRect.new()
	Ui.full_rect(_vignette)
	_vignette.color = Color(1, 0, 0, 0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)

	_gold = ColorRect.new()
	Ui.full_rect(_gold)
	_gold.color = Color(1.0, 0.75, 0.15, 0.0)
	_gold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gold)

	map_full = MapView.new()
	map_full.full = true
	Ui.full_rect(map_full)
	map_full.visible = false
	add_child(map_full)

	var mini: float = Defs.MAP["mini_size"]
	minimap = MapView.new()
	minimap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	minimap.offset_left = -18.0 - mini
	minimap.offset_right = -18.0
	minimap.offset_top = -18.0 - mini
	minimap.offset_bottom = -18.0
	add_child(minimap)

	_xp_bar = Ui.bar(Color(0.3, 0.65, 1.0), 16)
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = 16
	add_child(_xp_bar)

	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.position = Vector2(20, 26)
	left.add_theme_constant_override("separation", 6)
	add_child(left)
	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_label = Ui.label("LV 1", 28, Color(0.6, 0.85, 1.0))
	_level_label.custom_minimum_size.x = 86
	hp_row.add_child(_level_label)
	var hp_stack := Control.new()
	hp_stack.custom_minimum_size = Vector2(260, 28)
	hp_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar = Ui.bar(Color(0.9, 0.2, 0.2), 28)
	Ui.full_rect(_hp_bar)
	hp_stack.add_child(_hp_bar)
	_hp_label = Ui.label("", 20)
	Ui.full_rect(_hp_label)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_stack.add_child(_hp_label)
	hp_row.add_child(hp_stack)
	left.add_child(hp_row)
	_icons = HBoxContainer.new()
	_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_icons)
	_boost_icons = HBoxContainer.new()
	_boost_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_boost_icons)
	_build_goals(left)

	_depth_label = Ui.label("", 22)
	_depth_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_depth_label.offset_left = -220
	_depth_label.offset_right = 220
	_depth_label.offset_top = 24
	_depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_depth_label)

	var right := VBoxContainer.new()
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -500
	right.offset_right = -100
	right.offset_top = 24
	add_child(right)
	_score_label = Ui.label("0", 34, Color(1.0, 0.9, 0.4))
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_score_label)
	_cubes_label = Ui.label("", 20, Color(0.85, 0.85, 0.85))
	_cubes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_cubes_label)

	var pause := Button.new()
	pause.text = "II"
	pause.focus_mode = Control.FOCUS_NONE
	pause.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause.offset_left = -88
	pause.offset_right = -18
	pause.offset_top = 26
	pause.offset_bottom = 96
	pause.pressed.connect(func(): pause_pressed.emit())
	add_child(pause)

	_combo_label = Ui.label("", 64, Color(1.0, 0.85, 0.3))
	_combo_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_combo_label.offset_left = -260
	_combo_label.offset_right = -30
	_combo_label.offset_top = -60
	_combo_label.offset_bottom = 10
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_label.pivot_offset = Vector2(200, 35)
	add_child(_combo_label)
	_combo_sub = Ui.label("", 22, Color(1.0, 0.85, 0.3))
	_combo_sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_combo_sub.offset_left = -260
	_combo_sub.offset_right = -30
	_combo_sub.offset_top = 10
	_combo_sub.offset_bottom = 40
	_combo_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_combo_sub)

	_frenzy_bar = Ui.bar(Defs.FRENZY["color"], 12)
	_frenzy_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_frenzy_bar.offset_left = -230
	_frenzy_bar.offset_right = -30
	_frenzy_bar.offset_top = 44
	_frenzy_bar.offset_bottom = 56
	_frenzy_bar.visible = false
	add_child(_frenzy_bar)

	_fps_label = Ui.label("", 16, Color(1, 1, 1, 0.6))
	_fps_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_fps_label.offset_left = 12
	_fps_label.offset_top = -30
	_fps_label.offset_right = 200
	_fps_label.offset_bottom = -6
	add_child(_fps_label)

	_dash_bar = Ui.bar(Defs.DASH["color"], 20)
	_dash_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_dash_bar.offset_left = 12
	_dash_bar.offset_right = 172
	_dash_bar.offset_top = -62
	_dash_bar.offset_bottom = -42
	_dash_bar.visible = false
	add_child(_dash_bar)
	_dash_label = Ui.label("", 15)
	_dash_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_dash_label.offset_left = 12
	_dash_label.offset_right = 172
	_dash_label.offset_top = -64
	_dash_label.offset_bottom = -40
	_dash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dash_label.visible = false
	add_child(_dash_label)

	_compass = Control.new()
	Ui.full_rect(_compass)
	_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass.draw.connect(_draw_compass)
	add_child(_compass)

	_lift_bar = Ui.bar(Color(0.3, 1.0, 0.85), 18)
	_lift_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_lift_bar.offset_left = -120
	_lift_bar.offset_right = 120
	_lift_bar.offset_top = 70
	_lift_bar.offset_bottom = 88
	_lift_bar.visible = false
	add_child(_lift_bar)

	_boss_label = Ui.label("", 22, Color(1.0, 0.45, 0.4))
	_boss_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_label.offset_left = -220
	_boss_label.offset_right = 220
	_boss_label.offset_top = 56
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_boss_label)
	_boss_bar = Ui.bar(Color(1.0, 0.3, 0.3), 16)
	_boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_bar.offset_left = -220
	_boss_bar.offset_right = 220
	_boss_bar.offset_top = 86
	_boss_bar.offset_bottom = 102
	add_child(_boss_bar)

	_hint = Ui.label("", 28)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -400  # clear of the minimap on the narrowest screen
	_hint.offset_right = 400
	_hint.offset_top = -120
	_hint.offset_bottom = -20
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_hint)


## The objectives panel, under the tool and boost boxes. The top part is what finishes the map and is always
## there: the guardians, then the Heart. Below it, the side goals nearest to done come and go.
func _build_goals(parent: Control) -> void:
	var o := Defs.OBJECTIVES
	_goals_box = PanelContainer.new()
	_goals_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goals_box.custom_minimum_size.x = o["width"]
	_goals_box.visible = false
	var back := StyleBoxFlat.new()
	back.bg_color = o["bg"]
	back.set_corner_radius_all(10)
	back.content_margin_left = 12
	back.content_margin_right = 12
	back.content_margin_top = 8
	back.content_margin_bottom = 10
	_goals_box.add_theme_stylebox_override("panel", back)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 5)
	_goals_box.add_child(box)
	box.add_child(Ui.label("MAIN GOALS", 15, o["map_color"]))
	for i in 2:
		_map_rows.append(_goal_row(box, o["map_color"]))
	_side_title = Ui.label("SIDE GOALS", 15, Color(1.0, 0.65, 0.2))
	box.add_child(_side_title)
	for i in int(o["shown"]):
		_goal_rows.append(_goal_row(box, Color(1.0, 0.75, 0.25)))
	parent.add_child(_goals_box)


## A line with the goal's text and its count, and a thin bar under it. Returns [row, text, count, bar].
func _goal_row(parent: Control, fill: Color) -> Array:
	var row := VBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 2)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := Ui.label("", 18, Color(0.92, 0.9, 0.85))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.clip_text = true
	line.add_child(text)
	var count := Ui.label("", 18, Color(1.0, 0.85, 0.35))
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(count)
	row.add_child(line)
	var bar := Ui.bar(fill, 8)
	row.add_child(bar)
	parent.add_child(row)
	return [row, text, count, bar]


func _set_goal_row(parts: Array, text: String, count: String, share: float) -> void:
	if parts[1].text != text:
		parts[1].text = text
	if parts[2].text != count:
		parts[2].text = count
	parts[3].value = share


## The map rows and the side goals nearest to done, counting this run so far, a few times a second. The side
## goals leave the panel once this run has met them. The whole panel hides while the full map is open.
func _refresh_goals(run: Node) -> void:
	_goals_box.visible = not map_full.visible
	if run.run_time < _goals_next:
		return
	_goals_next = run.run_time + float(Defs.OBJECTIVES["every"])
	var total: int = Defs.BOSSES.size()
	var down: int = run.bosses.killed
	_set_goal_row(_map_rows[0], "Defeat the guardians", "%d / %d" % [down, total], float(down) / total)
	var heart := "Break the Heart"
	if run.bosses.left() > 0:
		_set_goal_row(_map_rows[1], heart, "SEALED", 0.0)
	elif not run.heart_woken:
		_set_goal_row(_map_rows[1], heart, "OPEN", 0.0)
	else:
		var hurt: float = 1.0 - run.mine.heart_left
		_set_goal_row(_map_rows[1], heart, "%d%%" % roundi(hurt * 100.0), hurt)
	var live: Dictionary = run.live_stats()
	var goals := Profile.closest_goals(_goal_rows.size(), live)
	_side_title.visible = not goals.is_empty()
	for i in _goal_rows.size():
		var parts: Array = _goal_rows[i]
		parts[0].visible = i < goals.size()
		if i >= goals.size():
			continue
		var g: Dictionary = goals[i]
		var need := int(g["need"])
		var got := mini(Profile.goal_total(g, live), need)
		_set_goal_row(parts, g["text"], "%s / %s" % [_format(got), _format(need)], float(got) / need)


func show_hint(text: String, duration := 4.0) -> void:
	_hint.text = text
	_hint.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(duration)
	tw.tween_property(_hint, "modulate:a", 0.0, 0.8)


func damage_flash() -> void:
	_vignette.color = Color(1, 0, 0, 0.28)
	var tw := create_tween()
	tw.tween_property(_vignette, "color:a", 0.0, 0.35)


## One beat of the Heart, stronger the closer you are.
func heart_pulse(near: float) -> void:
	_vignette.color = Color(1, 0.1, 0.4, 0.02 + 0.09 * near)
	var tw := create_tween()
	tw.tween_property(_vignette, "color:a", 0.0, 0.3)


## Arrows around the digger: the nearest way out, and a boss that is out of sight.
func _draw_compass() -> void:
	if not _run:
		return
	var at: Vector3 = _run.player.global_position
	_arrow(_run.sites.nearest_lift - at, Color(0.3, 1.0, 0.85), "LIFT", 130.0)
	if _run.bosses.current >= 0:
		var to: Vector3 = _run.enemies.pos[_run.bosses.current] - at
		if to.length() > 14.0:
			_arrow(to, Color(1.0, 0.3, 0.3), "BOSS", 170.0)


func _arrow(to: Vector3, color: Color, text: String, r: float) -> void:
	var dir := Vector2(to.x, to.z)
	if dir.length() < 2.0:
		return
	var d := dir.normalized()
	var mid := _compass.size * 0.5 + d * r
	var side := Vector2(-d.y, d.x)
	_compass.draw_colored_polygon(PackedVector2Array([mid + d * 16.0, mid + side * 10.0, mid - side * 10.0]), color)
	var font := ThemeDB.fallback_font
	var line := "%s %d m" % [text, int(dir.length())]
	_compass.draw_string_outline(font, mid - d * 8.0 + Vector2(-50, -14), line, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 15, 5, Color(0, 0, 0, 0.8))
	_compass.draw_string(font, mid - d * 8.0 + Vector2(-50, -14), line, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 15, color)


func refresh(run: Node) -> void:
	_run = run
	map_full.run = run
	minimap.run = run
	minimap.visible = not map_full.visible
	_compass.queue_redraw()
	_lift_bar.visible = run.sites.lift_t > 0.0
	_lift_bar.value = run.sites.lift_t / float(Defs.RUN["lift_hold"])
	var fight: Array = run.bosses.fight()
	_boss_bar.visible = not fight.is_empty()
	_boss_label.visible = _boss_bar.visible
	if _boss_bar.visible:
		_boss_label.text = fight[0]
		_boss_bar.value = fight[1]
	var p: Player = run.player
	_hp_bar.value = p.hp / p.max_hp
	_hp_label.text = "%d / %d" % [ceili(p.hp), ceili(p.max_hp)]
	_xp_bar.value = run.xp / run.xp_next
	_level_label.text = "LV %d" % run.level
	_score_label.text = _format(run.score)
	_cubes_label.text = "%s gems  ·  %s cubes  ·  %d kills" % [_format(int(run.loot)), _format(run.cubes), run.kills]
	var t := int(run.run_time)
	_depth_label.text = "%s  ·  %d m   %d:%02d" % [Defs.BANDS[run.band]["name"], int(run.depth), t / 60, t % 60]
	_fps_label.text = "%d fps" % Engine.get_frames_per_second()
	var combo: int = run.combo
	var frenzy: float = run.frenzy_left
	_gold.color.a = 0.1 + 0.05 * sin(run.run_time * 14.0) if frenzy > 0.0 else 0.0
	_frenzy_bar.visible = frenzy > 0.0 or combo >= 5
	_frenzy_bar.value = frenzy / float(Defs.FRENZY["time"]) if frenzy > 0.0 else run.frenzy_fill()
	if combo >= 5:
		_combo_label.text = "x%d" % combo
		_combo_sub.text = "FRENZY  %.1fx score" % run.combo_mult() if frenzy > 0.0 else "COMBO  %.1fx score" % run.combo_mult()
		_combo_label.modulate.a = clampf(run.combo_timer / 0.5, 0.0, 1.0)
		_combo_sub.modulate.a = _combo_label.modulate.a
		if combo > _last_combo:
			_combo_label.scale = Vector2.ONE * 1.2
	else:
		_combo_label.text = ""
		_combo_sub.text = ""
	_combo_label.scale = _combo_label.scale.lerp(Vector2.ONE, 0.2)
	_last_combo = combo
	_refresh_dash(run.dash)
	_refresh_icons(run.tools)
	_refresh_goals(run)


## A bar that fills while the dash recharges, with the key to press once it is ready.
func _refresh_dash(d: Dash) -> void:
	_dash_bar.visible = d.owned
	_dash_label.visible = d.owned
	if not d.owned:
		return
	var usable := d.cooldown <= 0.0
	_dash_bar.value = 1.0 if usable else 1.0 - d.cooldown / d.cooldown_total
	var text := "DASH  [%s]" % ("A" if Options.pad else "Space") if usable else "DASH  %.1f" % d.cooldown
	if text != _dash_text:
		_dash_text = text
		_dash_label.text = text
	if usable != _dash_ready:
		_dash_ready = usable
		(_dash_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Defs.DASH["color"] if usable else Color(0.2, 0.45, 0.5)


func _refresh_icons(w: Tools) -> void:
	var key := ""
	for id in w.order:
		key += "%s%d," % [id, w.level(id)]
	key += "dash%d," % w.run.dash.lvl
	for id in w.boost_order:
		key += "%s%d," % [id, w.boost(id)]
	key += "%d/%d" % [w.tool_slots(), w.boost_slots()]
	if key == _icon_key:
		return
	_icon_key = key
	for c in _icons.get_children():
		c.queue_free()
	for c in _boost_icons.get_children():
		c.queue_free()
	for id in w.order:
		_icons.add_child(Ui.icon(Defs.TOOLS[id]["color"], str(w.level(id)), 34))
	if w.run.dash.owned:
		_icons.add_child(Ui.icon(Defs.DASH["color"], "D%d" % w.run.dash.lvl, 34))
	for id in w.boost_order:
		_boost_icons.add_child(Ui.icon(Defs.BOOSTS[id]["color"], str(w.boost(id)), 34))
	# Free slots show as empty boxes, so you can see how much room is left.
	for k in w.tool_slots() - w.slots_used():
		_icons.add_child(_empty_slot())
	for k in w.boost_slots() - w.boost_order.size():
		_boost_icons.add_child(_empty_slot())


func _empty_slot() -> Panel:
	var p := Ui.icon(Color(0.45, 0.45, 0.5), "", 34)
	p.modulate.a = 0.45
	return p


func _format(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
