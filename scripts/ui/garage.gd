class_name Garage
extends Control
## Permanent upgrades, bought between runs with parts earned in runs.

signal closed

var _parts_label: Label
var _buttons := {}
var _reset: Button
var _reset_armed := false


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	var bg := ColorRect.new()
	Ui.full_rect(bg)
	bg.color = Color(0.09, 0.07, 0.06)
	add_child(bg)
	var root := VBoxContainer.new()
	Ui.full_rect(root)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)
	add_child(root)
	var title := Ui.label("GARAGE", 56, Color(1.0, 0.65, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	_parts_label = Ui.label("", 28, Color(1.0, 0.9, 0.4))
	_parts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_parts_label)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)
	for id in Defs.GARAGE:
		var b := Button.new()
		b.custom_minimum_size = Vector2(540, 88)
		b.pressed.connect(_buy.bind(id))
		grid.add_child(b)
		_buttons[id] = b
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)
	row.add_child(_action("Back", func(): closed.emit()))
	_reset = _action("Reset progress", _press_reset)
	row.add_child(_reset)
	if OS.is_debug_build():
		row.add_child(_action("+500 parts (test)", func():
			Save.add_parts(500)
			_refresh()))
	_refresh()
	_buttons.values()[0].grab_focus.call_deferred()


func _action(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 64)
	b.pressed.connect(callback)
	return b


func _refresh() -> void:
	_parts_label.text = "%d parts" % Save.parts
	for id in _buttons:
		var d: Dictionary = Defs.GARAGE[id]
		var level := Save.garage_level(id)
		var cost := "MAX" if level >= int(d["max"]) else "%d parts" % Save.garage_cost(id)
		_buttons[id].text = "%s  (%d/%d)\n%s  ·  %s" % [d["name"], level, d["max"], d["desc"], cost]


func _buy(id: String) -> void:
	Sfx.play("reward" if Save.buy(id) else "card", -6.0)
	_refresh()


func _press_reset() -> void:
	if _reset_armed:
		Save.reset_profile()
		_reset.text = "Reset progress"
		_reset_armed = false
		_refresh()
	else:
		_reset.text = "Press again to reset"
		_reset_armed = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		closed.emit()
