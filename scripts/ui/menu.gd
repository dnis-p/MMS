class_name Menu
extends Control
## Title screen: class select, garage and the local leaderboard.

signal class_chosen(class_id: String)
signal garage_pressed


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	var bg := ColorRect.new()
	Ui.full_rect(bg)
	bg.color = Color(0.09, 0.07, 0.06)
	add_child(bg)
	var stripes := ColorRect.new()
	stripes.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	stripes.offset_top = -10
	stripes.color = Color(0.9, 0.55, 0.15)
	add_child(stripes)

	var root := VBoxContainer.new()
	Ui.full_rect(root)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Ui.label("MMS", 64, Color(1.0, 0.65, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 16)
	root.add_child(title)
	var pick := Ui.label("Choose your ride", 30)
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(pick)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 22)
	root.add_child(cards)
	for id in Defs.CLASSES:
		if not Defs.CLASSES[id].get("creature", false):
			cards.add_child(_class_card(id))

	var raccoon := Button.new()
	raccoon.text = "Play the Raccoon (hunt and evolve prototype)"
	raccoon.custom_minimum_size = Vector2(620, 60)
	raccoon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	raccoon.pressed.connect(func():
		Sfx.play("levelup", -6.0, 1.0, true)
		class_chosen.emit("raccoon"))
	root.add_child(raccoon)
	raccoon.grab_focus.call_deferred()

	var garage := Button.new()
	garage.text = "Garage  ·  %d parts" % Save.parts
	garage.custom_minimum_size = Vector2(400, 60)
	garage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	garage.pressed.connect(func(): garage_pressed.emit())
	root.add_child(garage)

	var board := Ui.label(_leaderboard_text(), 20, Color(0.85, 0.85, 0.85))
	board.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(board)


func _class_card(id: String) -> Button:
	var d: Dictionary = Defs.CLASSES[id]
	var b := Button.new()
	b.custom_minimum_size = Vector2(330, 292)
	var v := VBoxContainer.new()
	Ui.full_rect(v)
	v.offset_left = 18
	v.offset_right = -18
	v.offset_top = 14
	v.offset_bottom = -14
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 6)
	b.add_child(v)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 12)
	top.add_child(Ui.icon(d["color"], String(d["name"]).substr(0, 1), 60))
	var names := VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(Ui.label(d["name"], 30))
	names.add_child(Ui.label(d["tagline"], 20, Color(1.0, 0.8, 0.4)))
	top.add_child(names)
	v.add_child(top)
	v.add_child(_stat("Hull", d["max_hp"] / 150.0, Color(0.9, 0.3, 0.3)))
	v.add_child(_stat("Armor", (d["armor"] + 0.5) / 2.5, Color(0.6, 0.6, 0.7)))
	v.add_child(_stat("Speed", d["speed"] / 13.0, Color(0.3, 0.8, 1.0)))
	v.add_child(_stat("Ram", d["ram"] / 35.0, Color(1.0, 0.6, 0.2)))
	var desc := Ui.label(d["desc"], 19, Color(0.85, 0.85, 0.85))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)
	b.pressed.connect(func():
		Sfx.play("levelup", -6.0, 1.0, true)
		class_chosen.emit(id))
	return b


func _stat(stat_name: String, value: float, color: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Ui.label(stat_name, 18, Color(0.8, 0.8, 0.8))
	l.custom_minimum_size.x = 70
	h.add_child(l)
	var bar := Ui.bar(color, 14)
	bar.value = clampf(value, 0.05, 1.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(bar)
	return h


func _leaderboard_text() -> String:
	if Save.scores.is_empty():
		return "LOCAL LEADERBOARD — no runs yet"
	var lines: Array[String] = ["LOCAL LEADERBOARD"]
	for i in mini(2, Save.scores.size()):
		var e: Dictionary = Save.scores[i]
		var cname: String = Defs.CLASSES.get(e["class"], {"name": "?"})["name"]
		lines.append("%d.  %d   %s  ·  stage %d  ·  %d kills" % [i + 1, int(e["score"]), cname, int(e["stage"]), int(e["kills"])])
	return "\n".join(lines)
