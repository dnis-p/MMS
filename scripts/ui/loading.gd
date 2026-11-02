class_name Loading
extends Control
## Shown while a new mine is generated.

var _bar: ProgressBar
var _what: Label


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	var bg := ColorRect.new()
	Ui.full_rect(bg)
	bg.color = Color(0.09, 0.07, 0.06)
	add_child(bg)
	var box := VBoxContainer.new()
	Ui.full_rect(box)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	var title := Ui.label("DIG", 72, Color(1.0, 0.65, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_bar = Ui.bar(Color(1.0, 0.65, 0.2), 20)
	_bar.custom_minimum_size.x = 520
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_bar)
	_what = Ui.label("Packing the rock", 24, Color(0.8, 0.75, 0.7))
	_what.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_what)


func show_progress(share: float, what: String) -> void:
	_bar.value = share
	_what.text = what
