extends Node
## Player options, kept between sessions.

const PATH := "user://options.cfg"

var fog := true  # dark fog of war: you only see and dig what your light reaches
var map_opacity: float = Defs.MAP["opacity"]  # how solid the full map is over the game
var saving := true  # tests turn this off, so they never touch your options file
var pad := false  # the last input came from a gamepad, not saved


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		fog = cfg.get_value("game", "fog", true)
		map_opacity = cfg.get_value("game", "map_opacity", map_opacity)


func _save() -> void:
	if not saving:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("game", "fog", fog)
	cfg.set_value("game", "map_opacity", map_opacity)
	cfg.save(PATH)


func toggle_fog() -> void:
	fog = not fog
	_save()


func fog_text() -> String:
	return "Fog of war: %s" % ("ON" if fog else "OFF")


## Steps through Defs.MAP.opacities, back to the first after the last.
func next_map_opacity() -> void:
	var steps: Array = Defs.MAP["opacities"]
	var i := 0
	while i < steps.size() and steps[i] <= map_opacity + 0.001:
		i += 1
	map_opacity = steps[i % steps.size()]
	_save()


func map_text() -> String:
	return "Map opacity: %d%%" % roundi(map_opacity * 100.0)


## A buzz in the hands for anything that shakes the screen enough to feel.
func rumble(amount: float) -> void:
	if not pad or amount < Defs.PAD["rumble_from"]:
		return
	for id in Input.get_connected_joypads():
		Input.start_joy_vibration(id, minf(amount * 1.5, 1.0), amount, Defs.PAD["rumble_time"])
