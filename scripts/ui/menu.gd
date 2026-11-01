class_name Menu
extends Control
## Title screen and camp: pick who digs, spend banked gems, see what is left to do.

signal start_pressed

var _root: VBoxContainer


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	var bg := ColorRect.new()
	Ui.full_rect(bg)
	bg.color = Color(0.09, 0.07, 0.06)
	add_child(bg)
	_root = VBoxContainer.new()
	Ui.full_rect(_root)
	_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_root.add_theme_constant_override("separation", 14)
	add_child(_root)
	_show_main()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_show_main()


func _clear() -> void:
	for c in _root.get_children():
		_root.remove_child(c)
		c.queue_free()


func _heading(text: String, size: int, color: Color) -> void:
	var l := Ui.label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(l)


func _button(text: String, on_press: Callable, height := 56.0, width := 400.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, height)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(on_press)
	return b


func _show_main() -> void:
	_clear()
	_heading("DIG", 96, Color(1.0, 0.65, 0.2))
	_heading("working title  ·  gameplay prototype", 24, Color(0.8, 0.75, 0.7))
	_heading("%d gems banked" % Profile.gems, 26, Color(0.4, 1.0, 0.85))
	var start := _button("Start digging", func():
		Sfx.play("levelup", -6.0, 1.0, true)
		start_pressed.emit(), 70.0)
	_root.add_child(start)
	_root.add_child(_button("Playing as: %s" % Defs.CHARACTERS[Profile.character]["name"], _show_characters))
	_root.add_child(_button("Shop", _show_shop))
	_root.add_child(_button("Goals  (%d/%d)" % [Profile.done.size(), Defs.GOALS.size()], _show_goals))
	var fog := _button(Options.fog_text(), func(): pass)
	fog.pressed.connect(func():
		Options.toggle_fog()
		fog.text = Options.fog_text())
	_root.add_child(fog)
	start.grab_focus.call_deferred()


func _show_characters() -> void:
	_clear()
	_heading("WHO DIGS?", 56, Color(1.0, 0.85, 0.3))
	var first: Button = null
	for id in Defs.CHARACTERS:
		var d: Dictionary = Defs.CHARACTERS[id]
		var open := Profile.has_character(id)
		var mark := "> " if id == Profile.character else ""
		var b := _button("%s%s: %s" % [mark, d["name"], d["desc"]] if open else "Locked: %s" % Defs.goal_for("char:" + id), func():
			Profile.character = id
			Profile.save()
			_show_characters(), 60.0, 900.0)
		b.disabled = not open
		_root.add_child(b)
		if open and not first:
			first = b
	var back := _button("Back", _show_main)
	_root.add_child(back)
	back.grab_focus.call_deferred()


func _show_shop() -> void:
	_clear()
	_heading("SHOP", 56, Color(1.0, 0.85, 0.3))
	_heading("%d gems banked" % Profile.gems, 26, Color(0.4, 1.0, 0.85))
	for id in Defs.SHOP:
		var d: Dictionary = Defs.SHOP[id]
		var lvl := Profile.shop_level(id)
		var full: bool = lvl >= d["max"]
		var price := "maxed" if full else "%d gems" % Profile.price(id)
		var b := _button("%s  ·  %s  ·  level %d/%d  ·  %s" % [d["name"], d["desc"], lvl, d["max"], price], func():
			if Profile.buy(id):
				Sfx.play("reward", -5.0, 1.1, true)
				_show_shop(), 54.0, 900.0)
		b.disabled = full or Profile.gems < Profile.price(id)
		_root.add_child(b)
	var back := _button("Back", _show_main)
	_root.add_child(back)
	back.grab_focus.call_deferred()


func _show_goals() -> void:
	_clear()
	_heading("GOALS", 56, Color(1.0, 0.85, 0.3))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 470)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	_root.add_child(scroll)
	for g in Defs.GOALS:
		var done := Profile.done.has(g["id"])
		var now := mini(Profile.stat(g["stat"]), g["need"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var text := Ui.label("%s  >  %s" % [g["text"], Defs.reward_text(g)], 20, Color(0.5, 1.0, 0.6) if done else Color(0.9, 0.9, 0.9))
		text.custom_minimum_size.x = 620
		row.add_child(text)
		var bar := Ui.bar(Color(0.4, 0.9, 0.5) if done else Color(1.0, 0.75, 0.25), 16)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.value = float(now) / float(g["need"])
		row.add_child(bar)
		list.add_child(row)
	var back := _button("Back", _show_main)
	_root.add_child(back)
	back.grab_focus.call_deferred()
