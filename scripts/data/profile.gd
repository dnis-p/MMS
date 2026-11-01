class_name Profile
## What carries over between runs: banked gems and lifetime totals, kept in one small save file.

const PATH := "user://profile.cfg"

static var saving := true  # tests and bots play without touching the real save
static var file := PATH
static var gems := 0
static var stats := {}


static func reset() -> void:
	gems = 0
	stats = {}


static func load_file() -> void:
	reset()
	var cfg := ConfigFile.new()
	if cfg.load(file) != OK:
		return
	gems = cfg.get_value("profile", "gems", 0)
	stats = cfg.get_value("profile", "stats", {})


static func save() -> void:
	if not saving:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "gems", gems)
	cfg.set_value("profile", "stats", stats)
	cfg.save(file)


static func stat(id: String) -> int:
	return int(stats.get(id, 0))


## Adds this run's numbers to the totals. Keys in Defs.BEST_STATS keep the best run instead of the sum.
static func record(run_stats: Dictionary) -> void:
	for id in run_stats:
		var v := int(run_stats[id])
		stats[id] = maxi(stat(id), v) if Defs.BEST_STATS.has(id) else stat(id) + v
