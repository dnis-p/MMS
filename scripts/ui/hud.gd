class_name Hud
extends Control
## In-run heads-up display. Touches pass straight through to the game except
## on the pause button.

signal pause_pressed

var _xp_bar: ProgressBar
var _level_label: Label
var _depth_label: Label
var _score_label: Label
var _cubes_label: Label
var _combo_label: Label
var _combo_sub: Label
var _icons: HBoxContainer
var _boost_icons: HBoxContainer
var _hint: Label
var _fps_label: Label
var _last_combo := 0
var _icon_key := ""
var joystick: Joystick


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	joystick = Joystick.new()
	add_child(joystick)

	_xp_bar = Ui.bar(Color(0.3, 0.65, 1.0), 16)
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = 16
	add_child(_xp_bar)

	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.position = Vector2(20, 26)
	left.add_theme_constant_override("separation", 6)
	add_child(left)
	_level_label = Ui.label("LV 1", 28, Color(0.6, 0.85, 1.0))
	left.add_child(_level_label)
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
	right.offset_left = -330
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

	_fps_label = Ui.label("", 16, Color(1, 1, 1, 0.6))
	_fps_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_fps_label.offset_left = 12
	_fps_label.offset_top = -30
	_fps_label.offset_right = 200
	_fps_label.offset_bottom = -6
	add_child(_fps_label)

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


func refresh(run: Node) -> void:
	_xp_bar.value = run.xp / run.xp_next
	_level_label.text = "LV %d" % run.level
	_score_label.text = _format(run.score)
	_cubes_label.text = "%s cubes" % _format(run.cubes)
	var t := int(run.run_time)
	_depth_label.text = "%s  ·  %d m   %d:%02d" % [Defs.BANDS[run.band]["name"], int(run.depth), t / 60, t % 60]
	_fps_label.text = "%d fps" % Engine.get_frames_per_second()
	var combo: int = run.combo
	if combo >= 5:
		_combo_label.text = "x%d" % combo
		_combo_sub.text = "COMBO  %.1fx score" % run.combo_mult()
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
