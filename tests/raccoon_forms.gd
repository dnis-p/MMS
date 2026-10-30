extends Node3D
## Dev tool: lines up every raccoon form and saves pictures from the side and from the game camera.
## Needs a display:
##   godot --path . res://tests/raccoon_forms.tscn -- --shots=<dir>

var _dir := "user://"
var _cam: Camera3D
var _frames := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--shots="):
			_dir = String(a).trim_prefix("--shots=")
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.72, 0.6, 0.42)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(35), 0)
	sun.light_energy = 1.1
	add_child(sun)
	var color: Color = Defs.CLASSES["raccoon"]["color"]
	for i in Defs.EAT_FORMS.size():
		var body := RaccoonBody.new()
		add_child(body)
		body.build(i, color)
		body.scale = Vector3.ONE * float(Defs.EAT_FORMS[i]["scale"])
		body.position.x = (i - 2) * 7.0
		for g in Defs.EAT_STAGES:
			if i == 4:
				body.graft(g["mutation"]["part"], g["mutation"]["color"])
	_cam = Camera3D.new()
	_cam.fov = 40.0
	add_child(_cam)
	_cam.make_current()
	_view(Vector3(-5, 7, -24))


func _view(from: Vector3) -> void:
	_cam.global_position = from
	_cam.look_at(Vector3(0, 1.8, 0), Vector3.UP)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 10:
		_shot("forms_front")
		_view(Vector3(14, 6, 22))
	elif _frames == 20:
		_shot("forms_back")
		_view(Vector3(0, 30, 9) * 1.0)
	elif _frames == 30:
		_shot("forms_game")
		get_tree().quit()


func _shot(file: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_dir, file])
	print("shot ", file)
