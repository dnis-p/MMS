extends Node
## Player options, kept between sessions.

const PATH := "user://options.cfg"

var fog := true  # dark fog of war: you only see and dig what your light reaches


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
