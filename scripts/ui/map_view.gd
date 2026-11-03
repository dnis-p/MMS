class_name MapView
extends Control
## The map, drawn from MineMap's tiles: a minimap in the corner, or over the whole screen at
## Options.map_opacity, with the digger on the map sitting right on the digger in the game.

const LIFT := Color(0.3, 1.0, 0.85)
const BOSS := Color(1.0, 0.3, 0.3)
const BACK := Color(0.05, 0.04, 0.035, 0.85)

var run: Node
var full := false
var zoom: int = Defs.MAP["zoom"]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func zoom_by(step: int) -> void:
	zoom = clampi(zoom + step, 0, Defs.MAP["zooms"].size() - 1)


## Pixels per cube.
func scale_now() -> float:
	if full:
		return float(Defs.MAP["zooms"][zoom])
	return size.x * Mine.CELL / (2.0 * float(Defs.MAP["mini_range"]))


## Where the digger is drawn on this control.
func center_now() -> Vector2:
	if full:
		return run.camera.unproject_position(run.player.global_position) - global_position
	return size * 0.5


func _draw() -> void:
	if run == null or run.player == null or run.mine == null:
		return
	var at: Vector3 = run.player.global_position
	var me := Vector2(at.x, at.z) / Mine.CELL + Vector2.ONE * Mine.SIZE * 0.5
	var s := scale_now()
	var center := center_now()
	var view := Rect2(Vector2.ZERO, size)
	if full:
		draw_rect(view, Color(0, 0, 0, Options.map_opacity * float(Defs.MAP["shade"])))
	else:
		draw_rect(view, BACK)
	var tint := Color(1, 1, 1, Options.map_opacity if full else 1.0)
	var map: MineMap = run.mine.map
	for t in map.textures.size():
		var tex := map.textures[t]
		if tex == null:
			continue
		var corner := Vector2(t % MineMap.TILES, t / MineMap.TILES) * MineMap.TILE
		var r := Rect2(center + (corner - me) * s, Vector2.ONE * MineMap.TILE * s)
		if r.intersects(view):
			draw_texture_rect(tex, r, false, tint)
	var spot := func(p: Vector3) -> Vector2:
		return center + (Vector2(p.x, p.z) / Mine.CELL + Vector2.ONE * Mine.SIZE * 0.5 - me) * s
	for l in run.mine.lifts:
		if not Options.fog or run.mine.has_seen_at(l):
			var p: Vector2 = spot.call(l)
			draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), LIFT)
			draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), Color.BLACK, false, 1.5)
	if run.bosses.current >= 0:
		var b: Vector2 = spot.call(run.enemies.pos[run.bosses.current])
		draw_circle(b, 7.0, BOSS)
		draw_arc(b, 7.0, 0.0, TAU, 20, Color.BLACK, 1.5)
	_draw_digger(center, run.player.heading)
	if not full:
		draw_rect(view, Color(1, 1, 1, 0.45), false, 2.0)


## An arrow pointing where the digger faces.
func _draw_digger(at: Vector2, heading: Vector3) -> void:
	var dir := Vector2(heading.x, heading.z).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var side := dir.orthogonal()
	var tip := PackedVector2Array([at + dir * 10.0, at + side * 6.5 - dir * 6.0, at - side * 6.5 - dir * 6.0])
	draw_colored_polygon(tip, Defs.DIGGER["color"].lightened(0.5))
	tip.append(tip[0])
	draw_polyline(tip, Color.BLACK, 2.0)
