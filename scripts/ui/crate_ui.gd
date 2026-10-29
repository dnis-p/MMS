class_name CrateUI
extends Control
## "Redline" salvage crate: instead of a slot machine, the engine revs and a
## tachometer needle decides the haul. Green = 1 item, orange = 3, redline = 5.

const ZONES := [[0.0, 0.6, Color(0.3, 0.9, 0.4), "x1"], [0.6, 0.9, Color(1.0, 0.6, 0.15), "x3"], [0.9, 1.0, Color(1.0, 0.2, 0.2), "x5"]]
const ARC_START := PI * 150.0 / 180.0
const ARC_END := PI * 390.0 / 180.0

var _gauge: Control
var _result_label: Label
var _rewards_box: HBoxContainer
var _continue: Label
var _callback: Callable
var _rewards: Array = []
var _value := 0.0
var _target := 0.5
var _t := 0.0
var _phase := ""
var _can_close := false
var auto_close := false


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	Ui.full_rect(dim)
	dim.color = Color(0, 0, 0, 0.7)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var v := VBoxContainer.new()
	Ui.full_rect(v)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var title := Ui.label("SALVAGE CRATE", 44, Color(1.0, 0.8, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_gauge = Control.new()
	_gauge.custom_minimum_size = Vector2(420, 250)
	_gauge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.draw.connect(_draw_gauge)
	v.add_child(_gauge)
	_result_label = Ui.label("", 52)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.custom_minimum_size.y = 64
	_result_label.pivot_offset = Vector2(640, 32)
	v.add_child(_result_label)
	_rewards_box = HBoxContainer.new()
	_rewards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_rewards_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rewards_box.add_theme_constant_override("separation", 10)
	_rewards_box.custom_minimum_size.y = 170
	v.add_child(_rewards_box)
	_continue = Ui.label("Tap to continue", 26, Color(0.8, 0.8, 0.8))
	_continue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_continue)


func open(count: int, rewards: Array, callback: Callable) -> void:
	_callback = callback
	_rewards = rewards
	match count:
		1:
			_target = randf_range(0.2, 0.55)
		3:
			_target = randf_range(0.64, 0.87)
		_:
			_target = randf_range(0.92, 0.985)
	_value = 0.0
	_t = 0.0
	_phase = "rev"
	_can_close = false
	_result_label.text = ""
	_continue.visible = false
	for c in _rewards_box.get_children():
		c.queue_free()
	visible = true
	Sfx.rev_start()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	match _phase:
		"rev":
			# Two blips of the throttle, then a long pull toward the result.
			if _t < 0.5:
				_value = sin(_t / 0.5 * PI) * 0.45
			elif _t < 1.0:
				_value = sin((_t - 0.5) / 0.5 * PI) * 0.7
			elif _t < 2.0:
				var k := (_t - 1.0) / 1.0
				_value = lerpf(0.0, _target, 1.0 - pow(1.0 - k, 3.0))
			else:
				_value = _target
				_phase = "result"
				_t = 0.0
				_show_result()
			Sfx.rev_set(_value)
		"result":
			_value = _target + sin(_t * 40.0) * 0.008 * maxf(0.0, 1.0 - _t)
		"done":
			_value = _target + sin(_t * 40.0) * 0.004
	_gauge.queue_redraw()


func _show_result() -> void:
	Sfx.rev_stop()
	var n := _rewards.size()
	var jackpot := n >= 5
	_result_label.text = "REDLINE! x%d" % n if jackpot else "x%d" % n
	_result_label.add_theme_color_override("font_color", ZONES[2][2] if jackpot else (ZONES[1][2] if n >= 3 else ZONES[0][2]))
	_result_label.scale = Vector2.ONE * 1.6
	var tw := create_tween()
	tw.tween_property(_result_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("jackpot" if jackpot else "levelup", -2.0, 1.0, true)
	for i in n:
		tw.tween_callback(_reveal.bind(_rewards[i]))
		tw.tween_interval(0.28)
	tw.tween_callback(func():
		_phase = "done"
		_can_close = true
		_continue.visible = true
		if auto_close:
			_close())


func _reveal(o: Dictionary) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 150)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(Ui.option_card_content(o, true))
	_rewards_box.add_child(card)
	card.pivot_offset = Vector2(100, 75)
	card.scale = Vector2.ONE * 0.3
	var tw := card.create_tween()
	tw.tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("jackpot" if o["kind"] == "evolve" else "reward", -4.0, 1.0 + _rewards_box.get_child_count() * 0.08, true)


func _gui_input(event: InputEvent) -> void:
	if not _can_close:
		return
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
	if tapped:
		accept_event()
		_close()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and _can_close and event.is_pressed():
		_close()


func _close() -> void:
	if not visible:
		return
	visible = false
	_can_close = false
	_callback.call(_rewards)


func _draw_gauge() -> void:
	var c := Vector2(_gauge.size.x * 0.5, _gauge.size.y * 0.78)
	var r := 170.0
	_gauge.draw_circle(c, r + 18.0, Color(0.06, 0.06, 0.08))
	for z in ZONES:
		var a0 := lerpf(ARC_START, ARC_END, z[0])
		var a1 := lerpf(ARC_START, ARC_END, z[1])
		_gauge.draw_arc(c, r, a0, a1, 32, z[2], 22.0, true)
	for k in 11:
		var a := lerpf(ARC_START, ARC_END, k / 10.0)
		var dir := Vector2(cos(a), sin(a))
		_gauge.draw_line(c + dir * (r - 24.0), c + dir * (r - 6.0), Color(1, 1, 1, 0.8), 3.0)
	var font := get_theme_default_font()
	for z in ZONES:
		var a := lerpf(ARC_START, ARC_END, (z[0] + z[1]) * 0.5)
		var p := c + Vector2(cos(a), sin(a)) * (r - 52.0) - Vector2(18, -8)
		_gauge.draw_string(font, p, z[3], HORIZONTAL_ALIGNMENT_CENTER, 40, 24, z[2])
	var na := lerpf(ARC_START, ARC_END, clampf(_value, 0.0, 1.0))
	var tip := c + Vector2(cos(na), sin(na)) * (r - 10.0)
	_gauge.draw_line(c, tip, Color(1, 0.95, 0.85), 6.0, true)
	_gauge.draw_circle(c, 16.0, Color(0.85, 0.2, 0.15))
	_gauge.draw_string(font, c + Vector2(-60, 48), "RPM x1000", HORIZONTAL_ALIGNMENT_CENTER, 120, 18, Color(1, 1, 1, 0.6))
