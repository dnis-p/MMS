extends Node
## Local high-score table. Stand-in for an online leaderboard: the entry shape
## (score, class, stage, kills, date) is what an online backend would receive.

const PATH := "user://scores.cfg"
const MAX_ENTRIES := 10

var scores: Array = []


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		scores = cfg.get_value("leaderboard", "scores", [])


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


func best() -> int:
	return int(scores[0]["score"]) if scores.size() > 0 else 0
