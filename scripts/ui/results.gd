class_name Results
extends Control
## The end of a run: what you kept, counted up, then the goals you moved closer to, then what you
## unlocked. Everything fills in order so there is something to watch. Runs while the tree is paused.

signal again_pressed
signal menu_pressed

const BARS := 3
const MARGIN := 48.0  # kept free around the panel
const MIN_LIST := 120.0

var _panel: PanelContainer
var _box: VBoxContainer
var _gems: Label
var _scroll: ScrollContainer
var _list: VBoxContainer


func _ready() -> void:
	theme = Ui.theme()
	Ui.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	Ui.full_rect(dim)
	dim.color = Color(0, 0, 0, 0.7)
	add_child(dim)
	var center := CenterContainer.new()
	Ui.full_rect(center)
	add_child(center)
	_panel = PanelContainer.new()
	center.add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_box.custom_minimum_size = Vector2(640, 0)
	_panel.add_child(_box)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.focus_mode = Control.FOCUS_NONE
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	_scroll.add_child(_list)
	resized.connect(_fit)


func _process(delta: float) -> void:
	if visible:
		_scroll.scroll_vertical += roundi(Input.get_axis("ui_up", "ui_down") * Menu.SCROLL_SPEED * delta)


## The list takes what the rest leaves, so the buttons stay on screen however many goals a run finishes.
func _fit() -> void:
	var rest := _panel.get_combined_minimum_size().y - _scroll.custom_minimum_size.y
	_scroll.custom_minimum_size.y = minf(_list.get_combined_minimum_size().y, maxf(size.y - rest - MARGIN, MIN_LIST))


## `r` keys: title, color, lines, carried, kept, share, before (stats at the start of the run), news
## (goals completed), and bank (gems banked now).
func open(r: Dictionary) -> void:
	visible = true
	_box.add_child(_center(Ui.label(r["title"], 48, r["color"])))
	for line in r["lines"]:
		_box.add_child(_center(Ui.label(line, 22, Color(0.85, 0.85, 0.85))))
	_gems = _center(Ui.label("+0 gems", 44, Color(0.4, 1.0, 0.85)))
	_box.add_child(_gems)
	var note := "all %d carried" % r["carried"] if r["share"] >= 1.0 else "%d%% of %d carried" % [roundi(r["share"] * 100.0), r["carried"]]
	_box.add_child(_center(Ui.label("%s  ·  %d in the bank" % [note, r["bank"]], 20, Color(0.8, 0.8, 0.8))))
	_box.add_child(_scroll)
	var delay := 0.3
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_method(_count.bind(int(r["kept"])), 0.0, 1.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	delay += 1.1
	for g in r["news"]:
		delay = _add_news(g, delay)
	for g in Profile.closest_goals(BARS):
		delay = _add_bar(g, r["before"], delay)
	_add_buttons()
	_fit.call_deferred()


func _count(t: float, total: int) -> void:
	_gems.text = "+%d gems" % roundi(total * t)
	if t < 1.0:
		Sfx.play("pickup", -16.0, 1.0 + t)


func _center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## A bar that starts at the old total and fills to the new one.
func _add_bar(g: Dictionary, before: Dictionary, delay: float) -> float:
	var need := float(g["need"])
	var now := Profile.stat(g["stat"])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var text := Ui.label("%s  (%d/%d)" % [g["text"], mini(now, g["need"]), g["need"]], 18, Color(0.9, 0.9, 0.9))
	text.custom_minimum_size.x = 400
	row.add_child(text)
	var bar := Ui.bar(Color(1.0, 0.75, 0.25), 16)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.value = minf(int(before.get(g["stat"], 0)) / need, 1.0)
	row.add_child(bar)
	_list.add_child(row)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(_scroll.ensure_control_visible.bind(row))
	tw.tween_property(bar, "value", minf(now / need, 1.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return delay + 0.25


## A finished goal lands with a pop, and says what it gave.
func _add_news(g: Dictionary, delay: float) -> float:
	var l := _center(Ui.label("%s  >  %s" % [g["text"], Defs.reward_text(g)], 24, Color(1.0, 0.85, 0.3)))
	l.modulate.a = 0.0
	_list.add_child(l)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func():
		Sfx.play("reward", -5.0, 1.0, true)
		_scroll.ensure_control_visible(l))
	tw.tween_property(l, "modulate:a", 1.0, 0.2)
	return delay + 0.45


func _add_buttons() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var again := _button("Dig again", again_pressed)
	row.add_child(again)
	row.add_child(_button("Camp", menu_pressed))
	_box.add_child(row)
	again.grab_focus()


func _button(text: String, pressed: Signal) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 70)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func(): pressed.emit())
	return b
