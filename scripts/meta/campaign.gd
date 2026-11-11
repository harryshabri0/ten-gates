class_name Campaign
extends RefCounted
## Ten-world progression and the PRD's sequential/boss/star gates.

const WORLD_COUNT: int = 10
const LEVELS_PER_WORLD: int = 10
const STARS_TO_UNLOCK_NEXT_WORLD: int = 15
const WORLD_NAMES: PackedStringArray = ["Hutan Gerbang", "Gurun Sunscar", "Rawa Beracun", "Puncak Es", "Kuburan Terlupakan", "Gunung Berapi", "Kota Uap", "Pulau Langit", "Void Rift", "Citadel Raja Iblis"]

var _levels: Dictionary = {}

func load_data(data: Dictionary) -> void:
	_levels = Dictionary(data.get("levels", {})).duplicate(true)

func to_data() -> Dictionary:
	return {"levels": _levels.duplicate(true)}

func record_result(world: int, level: int, mode: String, stars: int, crown: bool = false, best_time_seconds: float = 0.0) -> int:
	if not _is_valid_level(world, level):
		return 0
	var key: String = _level_key(world, level)
	var entry: Dictionary = Dictionary(_levels.get(key, {"modes": {}, "best_stars": 0, "boss_defeated": false}))
	var modes: Dictionary = Dictionary(entry.get("modes", {}))
	var mode_entry: Dictionary = Dictionary(modes.get(mode, {}))
	var capped: int = mini(stars, 2 if mode == "easy" else 3)
	var previous: int = int(mode_entry.get("stars", 0))
	mode_entry["stars"] = maxi(previous, capped)
	if mode == "hard" and crown:
		mode_entry["crown"] = true
	if best_time_seconds > 0.0:
		var prior_time: float = float(mode_entry.get("best_time_seconds", 0.0))
		mode_entry["best_time_seconds"] = best_time_seconds if prior_time <= 0.0 else minf(prior_time, best_time_seconds)
	modes[mode] = mode_entry
	entry["modes"] = modes
	var old_best: int = int(entry.get("best_stars", 0))
	var best: int = 0
	for saved_mode: Dictionary in modes.values():
		best = maxi(best, int(saved_mode.get("stars", 0)))
	entry["best_stars"] = best
	if level == LEVELS_PER_WORLD:
		entry["boss_defeated"] = true
	_levels[key] = entry
	return maxi(0, best - old_best)

func get_level_stars(world: int, level: int) -> int:
	return int(Dictionary(_levels.get(_level_key(world, level), {})).get("best_stars", 0))

func get_world_stars(world: int) -> int:
	var total: int = 0
	for level: int in LEVELS_PER_WORLD:
		total += get_level_stars(world, level + 1)
	return total

func is_level_unlocked(world: int, level: int) -> bool:
	if not _is_valid_level(world, level):
		return false
	if level > 1:
		return get_level_stars(world, level - 1) > 0
	if world == 1:
		return true
	return is_world_unlocked(world)

func is_world_unlocked(world: int) -> bool:
	if world < 1 or world > WORLD_COUNT:
		return false
	if world == 1:
		return true
	var boss: Dictionary = Dictionary(_levels.get(_level_key(world - 1, LEVELS_PER_WORLD), {}))
	return bool(boss.get("boss_defeated", false)) and get_world_stars(world - 1) >= STARS_TO_UNLOCK_NEXT_WORLD

func highest_completed_world() -> int:
	var completed: int = 0
	for world: int in WORLD_COUNT:
		var boss: Dictionary = Dictionary(_levels.get(_level_key(world + 1, LEVELS_PER_WORLD), {}))
		if bool(boss.get("boss_defeated", false)):
			completed = world + 1
	return completed

func get_total_skill_points() -> int:
	var total: int = 0
	for entry: Dictionary in _levels.values():
		total += int(entry.get("best_stars", 0))
	return mini(total, 300)

func get_world_name(world: int) -> String:
	return WORLD_NAMES[world - 1] if world >= 1 and world <= WORLD_NAMES.size() else "Unknown Gate"

func _is_valid_level(world: int, level: int) -> bool:
	return world >= 1 and world <= WORLD_COUNT and level >= 1 and level <= LEVELS_PER_WORLD

func _level_key(world: int, level: int) -> String:
	return "%d-%d" % [world, level]
