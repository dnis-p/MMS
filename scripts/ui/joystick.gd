class_name Joystick
extends Control
## Floating virtual stick drawn where a touch (or mouse drag) starts.

const RADIUS := 90.0

var _base := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	Ui.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_at(base: Vector2, knob: Vector2) -> void:
	_base = base
	_knob = knob
	visible = true
	queue_redraw()


func _draw() -> void:
	draw_arc(_base, RADIUS, 0.0, TAU, 40, Color(1, 1, 1, 0.35), 4.0, true)
	draw_circle(_knob, 34.0, Color(1, 1, 1, 0.3))
