class_name Ui
## Shared UI helpers: one theme for every screen and small builders.

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 24
	t.set_constant("outline_size", "Label", 8)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	t.set_color("font_color", "Label", Color(1, 1, 1))
	var normal := _box(Color(0.12, 0.12, 0.16, 0.92), Color(1, 1, 1, 0.15))
	var hover := _box(Color(0.18, 0.18, 0.24, 0.95), Color(1, 0.8, 0.3, 0.6))
	var pressed := _box(Color(0.25, 0.2, 0.12, 0.95), Color(1, 0.8, 0.3, 1.0))
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	var focus := _box(Color(0, 0, 0, 0), Color(1, 0.85, 0.3, 1.0))
	focus.draw_center = false
	focus.set_border_width_all(6)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", normal)
	t.set_font_size("font_size", "Button", 26)
	t.set_stylebox("panel", "PanelContainer", _box(Color(0.08, 0.08, 0.1, 0.94), Color(1, 1, 1, 0.12)))
	_theme = t
	return t


static func _box(bg: Color, border: Color, radius := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


static func label(text: String, size := 24, color := Color(1, 1, 1)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func bar(fill: Color, height := 22.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, height)
	b.min_value = 0.0
	b.max_value = 1.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(6)
	bg.border_color = Color(1, 1, 1, 0.2)
	bg.set_border_width_all(2)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(6)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## Colored square with a letter, used as a placeholder icon for weapons/passives.
static func icon(color: Color, letter: String, size := 56.0) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	var s := StyleBoxFlat.new()
	s.bg_color = color.darkened(0.35)
	s.border_color = color
	s.set_border_width_all(3)
	s.set_corner_radius_all(int(size * 0.2))
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(letter, int(size * 0.5))
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## Option dictionaries (level-up cards, crate rewards) rendered as a card's contents.
## `compact` is for rows of up to five cards (salvage crate rewards).
static func option_card_content(o: Dictionary, compact := false) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 12)
	var ic := icon(o["color"], String(o["title"]).substr(0, 1), 40.0 if compact else 56.0)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(ic)
	var names := VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := label(o["title"], 20 if compact else 26)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = 150 if compact else 200
	names.add_child(title)
	if String(o.get("level_text", "")) != "":
		var lvl_color := Color(0.3, 1.0, 0.5) if o["level_text"] == "NEW" else Color(1.0, 0.8, 0.3)
		if o["kind"] == "evolve":
			lvl_color = Color(1.0, 0.4, 1.0)
		names.add_child(label(o["level_text"], 17 if compact else 20, lvl_color))
	top.add_child(names)
	v.add_child(top)
	var desc := label(o["desc"], 18 if compact else 22, Color(0.9, 0.9, 0.9))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 180 if compact else 230
	v.add_child(desc)
	if String(o.get("hint", "")) != "":
		var hint := label(o["hint"], 14 if compact else 17, Color(0.5, 0.85, 1.0))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size.x = 180 if compact else 230
		v.add_child(hint)
	return v


## Keyboard focus after `delay` seconds, even while the game is paused.
static func focus_after(c: Control, delay: float) -> void:
	if delay <= 0.0:
		c.grab_focus()
		return
	c.get_tree().create_timer(delay, true).timeout.connect(func():
		if is_instance_valid(c) and c.is_visible_in_tree():
			c.grab_focus())


## The in-game pointer: a ring with a cross, big enough to find on a busy screen.
static func crosshair(color: Color) -> ImageTexture:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for y in 48:
		for x in 48:
			var d := Vector2(x - 23.5, y - 23.5)
			var on := absf(d.length() - 16.0) < 2.0 or (minf(absf(d.x), absf(d.y)) < 1.2 and d.length() > 8.0 and d.length() < 23.0)
			var edge := absf(d.length() - 16.0) < 3.5
			if on:
				img.set_pixel(x, y, color)
			elif edge:
				img.set_pixel(x, y, Color(0, 0, 0, 0.8))
	return ImageTexture.create_from_image(img)
