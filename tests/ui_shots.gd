extends Node
## Temporary: saves pictures of the menu screens and the results screen.

var _step := 0
var _wait := 0.6
var _menu: Menu
var _dir := ""


func _ready() -> void:
	_dir = OS.get_cmdline_user_args()[0]
	Profile.saving = false
	Profile.reset()
	Profile.gems = 640
	Profile.record({"lifts": 1, "band": 3, "cubes": 9000, "kills": 1100, "geodes": 3, "banked": 900, "frenzies": 2, "runs": 3, "combo": 1800})
	Profile.claim_goals()
	Profile.shop["power"] = 2
	var layer := CanvasLayer.new()
	_menu = Menu.new()
	layer.add_child(_menu)
	add_child(layer)


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_dir, name])


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = 0.5
	match _step:
		0:
			_shot("menu")
			_menu._show_shop()
		1:
			_shot("shop")
			_menu._show_goals()
		2:
			_shot("goals")
			_menu._show_characters()
		3:
			_shot("characters")
			var layer := CanvasLayer.new()
			add_child(layer)
			var r := Results.new()
			layer.add_child(r)
			var before := Profile.stats.duplicate()
			Profile.record({"cubes": 6000, "kills": 700, "geodes": 2, "banked": 737, "frenzies": 1})
			var news := Profile.claim_goals()
			r.open({"title": "YOU GOT OUT", "color": Color(1, 0.85, 0.3), "lines": ["6,040 cubes  ·  729 kills  ·  22 m deep  ·  level 13  ·  combo x3149"],
				"carried": 737, "kept": 737, "share": 1.0, "before": before, "news": news, "bank": Profile.gems})
			_wait = 4.0
		4:
			_shot("results")
			get_tree().quit()
	_step += 1
