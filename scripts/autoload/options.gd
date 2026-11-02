extends Node
## Player options, kept between sessions.

const PATH := "user://options.cfg"

var fog := true  # dark fog of war: you only see and dig what your light reaches
var pad := false  # the last input came from a gamepad, not saved


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		fog = cfg.get_value("game", "fog", true)


func toggle_fog() -> void:
	fog = not fog
	var cfg := ConfigFile.new()
	cfg.set_value("game", "fog", fog)
	cfg.save(PATH)


func fog_text() -> String:
	return "Fog of war: %s" % ("ON" if fog else "OFF")


## A buzz in the hands for anything that shakes the screen enough to feel.
func rumble(amount: float) -> void:
	if not pad or amount < Defs.PAD["rumble_from"]:
		return
	for id in Input.get_connected_joypads():
		Input.start_joy_vibration(id, minf(amount * 1.5, 1.0), amount, Defs.PAD["rumble_time"])
