class_name Overlay
extends Control
## Banners, screen flashes and simple modal panels (pause, stage clear, game over).

var _banner: Label
var _banner_sub: Label
var _flash: ColorRect
var _panel_root: Control
var _panel_box: VBoxContainer


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_flash = ColorRect.new()
	Ui.full_rect(_flash)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_banner = Ui.label("", 72, Color(1, 0.85, 0.3))
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.offset_left = -640
	_banner.offset_right = 640
	_banner.offset_top = -150
	_banner.offset_bottom = -60
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.pivot_offset = Vector2(640, 45)
	_banner.add_theme_constant_override("outline_size", 14)
	add_child(_banner)
	_banner_sub = Ui.label("", 32)
	_banner_sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner_sub.offset_left = -640
	_banner_sub.offset_right = 640
	_banner_sub.offset_top = -60
	_banner_sub.offset_bottom = -10
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_banner_sub)

	_panel_root = Control.new()
	Ui.full_rect(_panel_root)
	_panel_root.visible = false
	add_child(_panel_root)
	var dim := ColorRect.new()
	Ui.full_rect(dim)
	dim.color = Color(0, 0, 0, 0.65)
	_panel_root.add_child(dim)
	var center := CenterContainer.new()
	Ui.full_rect(center)
	_panel_root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	_panel_box = VBoxContainer.new()
	_panel_box.add_theme_constant_override("separation", 14)
	_panel_box.custom_minimum_size = Vector2(520, 0)
	panel.add_child(_panel_box)


func banner(text: String, sub := "", color := Color(1, 0.85, 0.3), duration := 2.2) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner_sub.text = sub
	_banner.modulate.a = 1.0
	_banner_sub.modulate.a = 1.0
	_banner.scale = Vector2(2.2, 2.2)
	var tw := create_tween()
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(duration)
	tw.set_parallel()
	tw.tween_property(_banner, "modulate:a", 0.0, 0.5)
	tw.tween_property(_banner_sub, "modulate:a", 0.0, 0.5)


func flash(color: Color, duration := 0.5) -> void:
	_flash.color = color
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, duration)


## `buttons` is an Array of [label, Callable] pairs.
func show_panel(title: String, lines: Array, buttons: Array, title_color := Color(1, 0.85, 0.3)) -> void:
	for c in _panel_box.get_children():
		c.queue_free()
	var t := Ui.label(title, 48, title_color)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_box.add_child(t)
	for line in lines:
		var l := Ui.label(String(line), 26, Color(0.9, 0.9, 0.9))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_panel_box.add_child(l)
	for b in buttons:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(0, 76)
		var cb: Callable = b[1]
		btn.pressed.connect(func():
			hide_panel()
			cb.call())
		_panel_box.add_child(btn)
	_panel_root.visible = true


func hide_panel() -> void:
	_panel_root.visible = false


func panel_visible() -> bool:
	return _panel_root.visible
