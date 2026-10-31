class_name Menu
extends Control
## Title screen.

signal start_pressed


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
	var title := Ui.label("DIG", 96, Color(1.0, 0.65, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 16)
	root.add_child(title)
	var sub := Ui.label("working title  ·  gameplay prototype", 24, Color(0.8, 0.75, 0.7))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)
	var start := Button.new()
	start.text = "Start digging"
	start.custom_minimum_size = Vector2(400, 70)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(func():
		Sfx.play("levelup", -6.0, 1.0, true)
		start_pressed.emit())
	root.add_child(start)
	start.grab_focus.call_deferred()
