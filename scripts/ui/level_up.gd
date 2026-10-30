class_name LevelUpUI
extends Control
## Pick-1-of-3 upgrade cards. Runs while the tree is paused.

const INPUT_GRACE := 0.35  # ignore taps right after opening so steering can't mis-pick

var _cards: HBoxContainer
var _title: Label
var _callback: Callable
var _opened_at := 0
var auto_pick := false


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	Ui.full_rect(dim)
	dim.color = Color(0, 0, 0, 0.6)
	add_child(dim)
	var v := VBoxContainer.new()
	Ui.full_rect(v)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 24)
	add_child(v)
	_title = Ui.label("LEVEL UP!", 56, Color(1.0, 0.85, 0.3))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 24)
	v.add_child(_cards)


func open(options: Array, level: int, callback: Callable) -> void:
	_callback = callback
	_opened_at = Time.get_ticks_msec()
	_title.text = "LEVEL %d!" % level
	for c in _cards.get_children():
		c.queue_free()
	visible = true
	Sfx.play("levelup", -4.0, 1.0, true)
	var first: Button = null
	for i in options.size():
		var o: Dictionary = options[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(320, 330)
		var content := Ui.option_card_content(o)
		Ui.full_rect(content)
		content.offset_left = 18
		content.offset_right = -18
		b.add_child(content)
		b.pressed.connect(_pick.bind(o))
		_cards.add_child(b)
		if not first:
			first = b
		b.modulate.a = 0.0
		b.pivot_offset = b.custom_minimum_size * 0.5
		b.scale = Vector2.ONE * 0.6
		var tw := b.create_tween().set_parallel()
		tw.tween_property(b, "modulate:a", 1.0, 0.18).set_delay(0.06 * i)
		tw.tween_property(b, "scale", Vector2.ONE, 0.3).set_delay(0.06 * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		b.mouse_entered.connect(func(): Sfx.play("card", -14.0))
	if not options.is_empty():
		first.grab_focus()
	if auto_pick:
		get_tree().create_timer(0.4, true).timeout.connect(func(): _pick(options[0], true))


func _pick(o: Dictionary, forced := false) -> void:
	if not visible:
		return
	if not forced and Time.get_ticks_msec() - _opened_at < INPUT_GRACE * 1000.0:
		return
	visible = false
	Sfx.play("reward", -6.0)
	_callback.call(o)
