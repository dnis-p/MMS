class_name Menu
extends Control
## Title screen and camp: pick who digs, spend banked gems, see what is left to do.

signal start_pressed

const SCROLL_SPEED := 500.0

var _root: VBoxContainer
var _scroll: ScrollContainer  # a long list, moved by up and down since nothing in it takes focus


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


func _process(delta: float) -> void:
	if _scroll:
		_scroll.scroll_vertical += roundi(Input.get_axis("ui_up", "ui_down") * SCROLL_SPEED * delta)


func _clear() -> void:
	_scroll = null
	for c in _root.get_children():
		_root.remove_child(c)
		c.queue_free()


func _heading(text: String, size: int, color: Color) -> void:
	var l := Ui.label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(l)


## Deferred so the page is laid out first. The page may have been swapped by then, taking the button with it.
func _focus(b: Button) -> void:
	if is_instance_valid(b) and b.is_inside_tree():
		b.grab_focus()


func _button(text: String, on_press: Callable, height := 56.0, width := 400.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, height)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(on_press)
	return b


func _show_main() -> void:
	_clear()
	_heading("DIG", 80, Color(1.0, 0.65, 0.2))
	_heading("working title  ·  gameplay prototype", 24, Color(0.8, 0.75, 0.7))
	_heading("%d gems banked" % Profile.gems, 26, Color(0.4, 1.0, 0.85))
	var start := _button("Start digging", func():
		Sfx.play("levelup", -6.0, 1.0, true)
		start_pressed.emit(), 70.0)
	_root.add_child(start)
	_root.add_child(_button("How to play", _show_help))
	_root.add_child(_button("Playing as: %s" % Defs.CHARACTERS[Profile.character]["name"], _show_characters))
	_root.add_child(_button("Shop", _show_shop))
	_root.add_child(_button("Goals  (%d/%d)" % [Profile.done.size(), Defs.GOALS.size()], _show_goals))
	# Settings share a row: the page has to fit the 720 high screen, which a wide window doesn't make taller.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var options := _button("Options", _show_options, 48.0, 194.0)
	options.add_theme_font_size_override("font_size", 20)
	row.add_child(options)
	var reset := _button("Reset progress", _show_reset, 48.0, 194.0)
	reset.add_theme_font_size_override("font_size", 20)
	row.add_child(reset)
	_root.add_child(row)
	_focus.call_deferred(start)


func _show_options() -> void:
	_clear()
	_heading("OPTIONS", 56, Color(1.0, 0.85, 0.3))
	var fog := _button(Options.fog_text(), func(): pass)
	fog.pressed.connect(func():
		Options.toggle_fog()
		fog.text = Options.fog_text())
	_root.add_child(fog)
	var opacity := _button(Options.map_text(), func(): pass)
	opacity.pressed.connect(func():
		Options.next_map_opacity()
		opacity.text = Options.map_text())
	_root.add_child(opacity)
	_heading("Map: M or Tab, or Back on a gamepad. Tap it to keep the map open, hold it to peek.", 20, Color(0.8, 0.75, 0.7))
	_heading("Zoom it with the mouse wheel, + and -, or the shoulder buttons.", 20, Color(0.8, 0.75, 0.7))
	var back := _button("Back", _show_main)
	_root.add_child(back)
	_focus.call_deferred(fog)


func _show_reset() -> void:
	_clear()
	_heading("RESET PROGRESS?", 56, Color(1.0, 0.4, 0.3))
	_heading("Banked gems, shop upgrades, unlocks, goals and relics all go back to zero.", 24, Color(0.9, 0.85, 0.8))
	_heading("This can't be undone.", 24, Color(0.9, 0.85, 0.8))
	_root.add_child(_button("Yes, erase it all", func():
		Profile.wipe()
		Sfx.play("thud", -5.0)
		_show_main()))
	var back := _button("Cancel", _show_main)
	_root.add_child(back)
	_focus.call_deferred(back)


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
	_focus.call_deferred(back)


## `bought` keeps the cursor on that row, so buying several levels doesn't mean walking back to it.
func _show_shop(bought := "") -> void:
	_clear()
	_heading("SHOP", 56, Color(1.0, 0.85, 0.3))
	_heading("%d gems banked" % Profile.gems, 26, Color(0.4, 1.0, 0.85))
	var keep: Button = null
	for id in Defs.SHOP:
		var d: Dictionary = Defs.SHOP[id]
		var lvl := Profile.shop_level(id)
		var full: bool = lvl >= d["max"]
		var price := "maxed" if full else "%d gems" % Profile.price(id)
		var b := _button("%s  ·  %s  ·  level %d/%d  ·  %s" % [d["name"], d["desc"], lvl, d["max"], price], func():
			if Profile.buy(id):
				Sfx.play("reward", -5.0, 1.1, true)
				_show_shop(id), 48.0, 900.0)
		b.disabled = full or Profile.gems < Profile.price(id)
		b.add_theme_font_size_override("font_size", 21)  # 7 rows have to fit the 720 high screen
		_root.add_child(b)
		if id == bought and not b.disabled:
			keep = b
	var back := _button("Back", _show_main)
	_root.add_child(back)
	_focus.call_deferred(keep if keep else back)


## A scrolling column under the heading, for pages longer than the screen.
func _scroll_list(separation: int) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 470)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", separation)
	scroll.add_child(list)
	_root.add_child(scroll)
	_scroll = scroll
	return list


func _show_help() -> void:
	_clear()
	_heading("HOW TO PLAY", 56, Color(1.0, 0.85, 0.3))
	var list := _scroll_list(6)
	for part in Help.sections():
		var title := Ui.label(part[0].to_upper(), 26, Color(1.0, 0.65, 0.2))
		if list.get_child_count() > 0:
			title.custom_minimum_size.y = 52  # room above each title after the first
			title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		list.add_child(title)
		for line in part[1]:
			var row := HBoxContainer.new()
			var dot := Ui.label("•", 20, Color(1.0, 0.65, 0.2))
			dot.custom_minimum_size.x = 22
			dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			row.add_child(dot)
			var l := Ui.label(line, 20, Color(0.9, 0.88, 0.85))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
			var gap := Control.new()  # keeps the text off the scroll bar
			gap.custom_minimum_size.x = 14
			row.add_child(gap)
			list.add_child(row)
	var back := _button("Back", _show_main)
	_root.add_child(back)
	_focus.call_deferred(back)


func _show_goals() -> void:
	_clear()
	_heading("GOALS", 56, Color(1.0, 0.85, 0.3))
	var list := _scroll_list(10)
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
	_focus.call_deferred(back)
