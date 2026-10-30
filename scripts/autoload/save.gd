extends Node
## Everything kept between runs, all behind this one script so an online backend can
## replace it later. Local high-score table: the entry shape (score, class, stage, kills,
## date) is what an online backend would receive. Profile: parts and garage upgrades.

const PATH := "user://scores.cfg"
const MAX_ENTRIES := 10
const PROFILE_VERSION := 1

var scores: Array = []
var parts := 0
var garage := {}  # upgrade id -> level; ids missing here are level 0
var profile_path := "user://profile.cfg"


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		scores = cfg.get_value("leaderboard", "scores", [])
	load_profile()


## Returns the 1-based rank of the new entry, or 0 if it didn't make the table.
func submit(score: int, class_id: String, stage: int, kills: int) -> int:
	var entry := {
		"score": score, "class": class_id, "stage": stage, "kills": kills,
		"date": Time.get_date_string_from_system(),
	}
	scores.append(entry)
	scores.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)
	var cfg := ConfigFile.new()
	cfg.set_value("leaderboard", "scores", scores)
	cfg.save(PATH)
	return scores.find(entry) + 1


func load_profile() -> void:
	var cfg := ConfigFile.new()
	var ok := cfg.load(profile_path) == OK
	parts = cfg.get_value("profile", "parts", 0) if ok else 0
	garage = cfg.get_value("profile", "garage", {}) if ok else {}


func save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "version", PROFILE_VERSION)
	cfg.set_value("profile", "parts", parts)
	cfg.set_value("profile", "garage", garage)
	cfg.save(profile_path)


func add_parts(amount: int) -> void:
	parts += amount
	save_profile()


func garage_level(id: String) -> int:
	return int(garage.get(id, 0))


func garage_cost(id: String) -> int:
	return int(Defs.GARAGE[id]["cost"]) * (garage_level(id) + 1)


## Returns true if the upgrade was bought.
func buy(id: String) -> bool:
	var cost := garage_cost(id)
	if garage_level(id) >= int(Defs.GARAGE[id]["max"]) or parts < cost:
		return false
	parts -= cost
	garage[id] = garage_level(id) + 1
	save_profile()
	return true


func reset_profile() -> void:
	parts = 0
	garage = {}
	save_profile()


func best() -> int:
	return int(scores[0]["score"]) if scores.size() > 0 else 0
