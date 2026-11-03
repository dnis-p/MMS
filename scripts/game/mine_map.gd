class_name MineMap
extends RefCounted
## What the map shows: one small texture per chunk of the mine, holding what you have opened or seen.
## Cells are marked when they change and their tile is redrawn a little later, nearest first, within
## a time budget, so digging never waits on the map.

const TILE := Mine.CHUNK
const TILES := Mine.CHUNKS
const CLEAR := 0  # not known: the map shows nothing there

var mine: Mine
var textures: Array[ImageTexture] = []  # null until a tile has something to show
var _dirty := PackedByteArray()
var _queue := PackedInt32Array()
var _ready_at := PackedFloat32Array()  # run time a tile may be redrawn again
var _rock := PackedInt32Array()  # map colour per cube kind, as RGBA8 bytes read little-endian
var _floor := 0
var _wall := 0


func _init(m: Mine) -> void:
	mine = m
	textures.resize(TILES * TILES)
	_dirty.resize(TILES * TILES)
	_ready_at.resize(TILES * TILES)
	var dim: float = Defs.MAP["rock_dim"]
	for d in Defs.CUBES:
		_rock.append(_pack(Color(d.get("color", Color.BLACK)).darkened(dim)))
	_floor = _pack(Defs.MAP["floor"])
	_wall = int(Defs.MAP["wall"] * Mine.STEP)


static func _pack(c: Color) -> int:
	return c.r8 | (c.g8 << 8) | (c.b8 << 16) | (255 << 24)


func mark(c: int) -> void:
	var t := (c % Mine.SIZE) / TILE + (c / Mine.SIZE / TILE) * TILES
	if _dirty[t] == 0:
		_dirty[t] = 1
		_queue.append(t)


## Everything again, as when the fog is switched. `drawn` only redoes tiles that show something.
func mark_all(drawn := false) -> void:
	for t in TILES * TILES:
		if _dirty[t] == 0 and (not drawn or textures[t] != null):
			_dirty[t] = 1
			_queue.append(t)


## Redraws waiting tiles, nearest to `at` first, until the frame's budget is spent.
func update(at: Vector3, now: float) -> void:
	if _queue.is_empty():
		return
	var until := Time.get_ticks_usec() + int(Defs.MAP["budget"] * 1000.0)
	var cx := float(mine.cell_of(at.x)) / TILE
	var cz := float(mine.cell_of(at.z)) / TILE
	while Time.get_ticks_usec() < until:
		var best := -1
		var best_d := INF
		for k in _queue.size():
			var t := _queue[k]
			if _ready_at[t] > now:
				continue
			var d := Vector2(t % TILES + 0.5 - cx, t / TILES + 0.5 - cz).length_squared()
			if d < best_d:
				best_d = d
				best = k
		if best < 0:
			return
		var tile := _queue[best]
		_queue[best] = _queue[_queue.size() - 1]
		_queue.resize(_queue.size() - 1)
		_dirty[tile] = 0
		_ready_at[tile] = now + float(Defs.MAP["every"])
		build(tile)


## What one cell looks like on the map: open ground you know, rock at its edge, or nothing.
func color_of(c: int) -> int:
	var k := mine.kind[c]
	if not Options.fog:
		return _floor if k == 0 else _rock[k]
	var d := mine.known_at(c)
	if k == 0:
		return _floor if d == 0 else CLEAR
	return _rock[k] if d <= _wall else CLEAR


func build(tile: int) -> void:
	var x0 := (tile % TILES) * TILE
	var z0 := (tile / TILES) * TILE
	var px := PackedInt32Array()
	px.resize(TILE * TILE)
	var any := false
	for z in TILE:
		var row := x0 + (z0 + z) * Mine.SIZE
		for x in TILE:
			var col := color_of(row + x)
			px[x + z * TILE] = col
			any = any or col != CLEAR
	if not any and textures[tile] == null:
		return
	var img := Image.create_from_data(TILE, TILE, false, Image.FORMAT_RGBA8, px.to_byte_array())
	if textures[tile] == null:
		textures[tile] = ImageTexture.create_from_image(img)
	else:
		textures[tile].update(img)


func pending() -> int:
	return _queue.size()
