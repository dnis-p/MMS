class_name Profile
## What carries over between runs: banked gems, shop levels, unlocks, finished goals, relics and
## lifetime totals, kept in one small save file.

const PATH := "user://profile.cfg"

static var saving := true  # tests and bots play without touching the real save
static var file := PATH
static var gems := 0
static var character := "digger"
static var stats := {}
static var shop := {}  # shop id -> level
static var unlocked := {}  # "tool:bombs" or "char:rig" -> true
static var done := {}  # goal id -> true
static var relics := {}  # relic id -> true


static func reset() -> void:
	gems = 0
	character = "digger"
	stats = {}
	shop = {}
	unlocked = {}
	done = {}
	relics = {}


static func load_file() -> void:
	reset()
	var cfg := ConfigFile.new()
	if cfg.load(file) != OK:
		return
	gems = cfg.get_value("profile", "gems", 0)
	character = cfg.get_value("profile", "character", "digger")
	stats = cfg.get_value("profile", "stats", {})
	shop = cfg.get_value("profile", "shop", {})
	unlocked = cfg.get_value("profile", "unlocked", {})
	done = cfg.get_value("profile", "done", {})
	relics = cfg.get_value("profile", "relics", {})


static func save() -> void:
	if not saving:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "gems", gems)
	cfg.set_value("profile", "character", character)
	cfg.set_value("profile", "stats", stats)
	cfg.set_value("profile", "shop", shop)
	cfg.set_value("profile", "unlocked", unlocked)
	cfg.set_value("profile", "done", done)
	cfg.set_value("profile", "relics", relics)
	cfg.save(file)


static func stat(id: String) -> int:
	return int(stats.get(id, 0))


## Totals with this run's numbers added. Keys in Defs.BEST_STATS keep the best run instead of the sum.
static func with_run(id: String, v: int) -> int:
	return maxi(stat(id), v) if Defs.BEST_STATS.has(id) else stat(id) + v


static func record(run_stats: Dictionary) -> void:
	for id in run_stats:
		stats[id] = with_run(id, int(run_stats[id]))


# --- goals and unlocks ---------------------------------------------------------------

## Pays out every goal that is now met and returns them, for the results screen.
static func claim_goals() -> Array:
	var news: Array = []
	for g in Defs.GOALS:
		if done.has(g["id"]) or stat(g["stat"]) < g["need"]:
			continue
		done[g["id"]] = true
		gems += int(g.get("gems", 0))
		if g.has("unlock"):
			unlocked[g["unlock"]] = true
		news.append(g)
	return news


## The unfinished goals nearest to done.
static func closest_goals(n: int) -> Array:
	var open: Array = Defs.GOALS.filter(func(g): return not done.has(g["id"]))
	open.sort_custom(func(a, b): return float(stat(a["stat"])) / a["need"] > float(stat(b["stat"])) / b["need"])
	return open.slice(0, n)


static func has_tool(id: String) -> bool:
	return not Defs.TOOLS[id].get("locked", false) or unlocked.has("tool:" + id)


static func has_character(id: String) -> bool:
	return not Defs.CHARACTERS[id].get("locked", false) or unlocked.has("char:" + id)


static func unlock_all() -> void:
	for id in Defs.TOOLS:
		unlocked["tool:" + id] = true
	for id in Defs.CHARACTERS:
		unlocked["char:" + id] = true


# --- shop ----------------------------------------------------------------------------

static func shop_level(id: String) -> int:
	return int(shop.get(id, 0))


static func price(id: String) -> int:
	var d: Dictionary = Defs.SHOP[id]
	return roundi(d["cost"] * pow(d["grow"], shop_level(id)))


static func buy(id: String) -> bool:
	if shop_level(id) >= Defs.SHOP[id]["max"] or gems < price(id):
		return false
	gems -= price(id)
	shop[id] = shop_level(id) + 1
	save()
	return true


## The permanent bonus for one shop id, from the shop and from relics you have found.
static func bonus(id: String) -> float:
	var total := float(Defs.SHOP[id]["value"]) * shop_level(id)
	for r in relics:
		if Defs.RELICS[r].get("bonus", "") == id:
			total += float(Defs.RELICS[r]["value"])
	return total
