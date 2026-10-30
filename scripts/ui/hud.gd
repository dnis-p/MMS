class_name Hud
extends Control
## In-run heads-up display. Touches pass straight through to the game except
## on the pause button.

signal pause_pressed

var _xp_bar: ProgressBar
var _level_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _progress_bar: ProgressBar
var _progress_label: Label
var _score_label: Label
var _kills_label: Label
var _combo_label: Label
var _combo_sub: Label
var _icons: HBoxContainer
var _passive_icons: HBoxContainer
var _hint: Label
var _vignette: ColorRect
var _fps_label: Label
var _last_combo := 0
var _icon_key := ""
var _boss_mode := -1
var joystick: Joystick
var _redline_bar: ProgressBar
var _redline_label: Label


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	joystick = Joystick.new()
	add_child(joystick)

	_vignette = ColorRect.new()
	Ui.full_rect(_vignette)
	_vignette.color = Color(1, 0, 0, 0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)

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
	hp_stack.custom_minimum_size = Vector2(300, 28)
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
	_passive_icons = HBoxContainer.new()
	_passive_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_passive_icons)

	var center := VBoxContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	center.offset_left = -220
	center.offset_right = 220
	center.offset_top = 24
	add_child(center)
	_progress_label = Ui.label("", 22)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_progress_label)
	_progress_bar = Ui.bar(Color(1.0, 0.7, 0.2), 14)
	center.add_child(_progress_bar)

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
	_kills_label = Ui.label("", 20, Color(0.85, 0.85, 0.85))
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_kills_label)

	var pause := Button.new()
	pause.text = "II"
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

	_redline_bar = Ui.bar(Color(0.3, 0.9, 0.4), 22)
	_redline_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_redline_bar.offset_left = -240
	_redline_bar.offset_right = 240
	_redline_bar.offset_top = -36
	_redline_bar.offset_bottom = -14
	add_child(_redline_bar)
	_redline_label = Ui.label("REDLINE", 16)
	_redline_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_redline_label.offset_left = -240
	_redline_label.offset_right = 240
	_redline_label.offset_top = -38
	_redline_label.offset_bottom = -12
	_redline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_redline_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_redline_label)

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
	_hint.offset_top = -90
	_hint.offset_bottom = -40
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


func refresh(run: Node) -> void:
	var p: Player = run.player
	_hp_bar.value = p.hp / p.max_hp
	_hp_label.text = "%d / %d" % [ceili(p.hp), ceili(p.max_hp)]
	_xp_bar.value = float(run.xp) / float(run.xp_next)
	_level_label.text = "LV %d" % run.level
	_score_label.text = _format(run.score)
	_kills_label.text = "%d kills" % run.kills
	var boss_mode := 1 if run.is_boss_phase() else 0
	if boss_mode != _boss_mode:
		# Theme overrides trigger a relayout, so only touch them when the phase flips.
		_boss_mode = boss_mode
		_progress_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35) if boss_mode else Color(1, 1, 1))
		(_progress_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.95, 0.2, 0.25)
		_progress_bar.visible = boss_mode == 1
	if boss_mode:
		_progress_label.text = run.boss_name()
		_progress_bar.value = run.boss.hp_ratio() if run.boss else 0.0
	else:
		var t := int(run.stage_time)
		_progress_label.text = "STAGE %d  %s   %d:%02d" % [run.stage, run.biome["name"].to_upper(), t / 60, t % 60]
	var meter: float = run.nitro_left / Defs.REDLINE["nitro_time"] if run.nitro_left > 0.0 else run.redline
	_redline_bar.value = meter
	_redline_label.text = "NITRO" if run.nitro_left > 0.0 else "REDLINE"
	(_redline_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(1.0, 0.25, 0.1) if run.nitro_left > 0.0 or meter > 0.8 else (Color(1.0, 0.65, 0.15) if meter > 0.5 else Color(0.3, 0.9, 0.4))
	_fps_label.text = "%d fps · %d enemies" % [Engine.get_frames_per_second(), run.enemies.alive_count]
	var combo: int = run.combo
	if combo >= 5:
		_combo_label.text = "x%d" % combo
		_combo_sub.text = "COMBO  %.1fx score" % run.combo_mult()
		_combo_label.modulate.a = clampf(run.combo_timer / 0.6, 0.0, 1.0)
		_combo_sub.modulate.a = _combo_label.modulate.a
		if combo > _last_combo:
			_combo_label.scale = Vector2.ONE * 1.25
	else:
		_combo_label.text = ""
		_combo_sub.text = ""
	_combo_label.scale = _combo_label.scale.lerp(Vector2.ONE, 0.2)
	_last_combo = combo
	_refresh_icons(run.weapons)


func _refresh_icons(w: Weapons) -> void:
	var key := ""
	for id in w.order:
		key += "%s%d%s," % [id, w.level(id), "e" if w.is_evolved(id) else ""]
	for id in w.passive_order:
		key += "%s%d," % [id, w.passive(id)]
	if key == _icon_key:
		return
	_icon_key = key
	for c in _icons.get_children():
		c.queue_free()
	for c in _passive_icons.get_children():
		c.queue_free()
	for id in w.order:
		var d: Dictionary = Defs.WEAPONS[id]
		var ic := Ui.icon(Color(1.0, 0.4, 1.0) if w.is_evolved(id) else d["color"], "+" if w.is_evolved(id) else str(w.level(id)), 46)
		_icons.add_child(ic)
	for id in w.passive_order:
		_passive_icons.add_child(Ui.icon(Defs.PASSIVES[id]["color"], str(w.passive(id)), 34))


func _format(n: int) -> String:
	var s := str(n)
	var out := ""
	var k := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		k += 1
		if k % 3 == 0 and i > 0:
			out = "," + out
	return out
