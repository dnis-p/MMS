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
var _hint: Label
var _fps_label: Label
var _compass: Control
var _lift_bar: ProgressBar
var _gold: ColorRect
var _frenzy_bar: ProgressBar
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

	_hint = Ui.label("", 28)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -500
	_hint.offset_right = 500
	_hint.offset_top = -70
	_hint.offset_bottom = -20
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)


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


## Two arrows around the digger: where the Heart is, and the nearest way out.
func _draw_compass() -> void:
	if not _run:
		return
	var at: Vector3 = _run.player.global_position
	var heart: float = _run.mine.heart_left
	_arrow(_run.mine.heart_pos - at, Color(1, 0.25, 0.5), "HEART" if heart >= 1.0 else "HEART %d%%" % ceili(heart * 100.0), 170.0)
	_arrow(_run.sites.nearest_lift - at, Color(0.3, 1.0, 0.85), "LIFT", 130.0)


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
	_compass.queue_redraw()
	_lift_bar.visible = run.sites.lift_t > 0.0
	_lift_bar.value = run.sites.lift_t / float(Defs.RUN["lift_hold"])
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
	_refresh_icons(run.tools)


func _refresh_icons(w: Tools) -> void:
	var key := ""
	for id in w.order:
		key += "%s%d," % [id, w.level(id)]
	for id in w.boost_order:
		key += "%s%d," % [id, w.boost(id)]
	if key == _icon_key:
		return
	_icon_key = key
	for c in _icons.get_children():
		c.queue_free()
	for c in _boost_icons.get_children():
		c.queue_free()
	for id in w.order:
		_icons.add_child(Ui.icon(Defs.TOOLS[id]["color"], str(w.level(id)), 34))
	for id in w.boost_order:
		_boost_icons.add_child(Ui.icon(Defs.BOOSTS[id]["color"], str(w.boost(id)), 34))


func _format(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
