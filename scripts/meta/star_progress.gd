class_name StarProgress
extends RefCounted
## P5 in-memory record. SaveManager will persist this structure in P8.

var total_skill_points: int = 0
var best_stars: Dictionary = {}

func evaluate(result: Dictionary, difficulty: Dictionary, challenge: Dictionary) -> int:
	var stars: int = 1 if bool(result.get("won", false)) else 0
	if stars == 0:
		return 0
	if float(result.get("base_hp_ratio", 0.0)) >= 0.50:
		stars += 1
	if _challenge_complete(result, challenge):
		stars += 1
	return mini(stars, int(difficulty.get("max_stars", 3)))

func record(level_id: String, stars: int) -> int:
	var previous: int = int(best_stars.get(level_id, 0))
	var delta: int = maxi(0, stars - previous)
	if delta > 0:
		best_stars[level_id] = stars
		total_skill_points += delta
	return delta

func spend_skill_points(cost: int) -> bool:
	if cost <= 0 or total_skill_points < cost:
		return false
	total_skill_points -= cost
	return true

func _challenge_complete(result: Dictionary, challenge: Dictionary) -> bool:
	match String(challenge.get("type", "")):
		"no_leak": return int(result.get("leaks", 0)) == 0
		"tower_limit": return int(result.get("tower_count", 0)) <= int(challenge.get("max_towers", 0))
		"no_active_skill": return int(result.get("active_skill_uses", 0)) == 0
		"no_tower": return not Array(result.get("tower_ids", [])).has(String(challenge.get("tower_id", "")))
		_: return false

