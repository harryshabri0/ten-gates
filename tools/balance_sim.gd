extends SceneTree
## P12 no-render balance simulator. It deliberately reads only game data so it can run in CI.

const RUNS_PER_STRATEGY: int = 10
const STRATEGIES = ["balanced", "splash_control", "elite_focus"]
const MODE_TARGETS: Dictionary = {"easy": 0.90, "normal": 0.65, "hard": 0.35}
const BOSS_TARGETS: Dictionary = {"easy": 0.80, "normal": 0.50, "hard": 0.20}
const TOWER_UNLOCKS: Dictionary = {
	"archer": 1, "cannon": 1, "barracks": 1, "ice": 1, "arcane": 1,
	"poison_lab": 3, "tesla": 3, "skyfang": 4, "coin_tower": 4,
	"ballista": 5, "fire_tower": 6, "mechanic_workshop": 7,
	"war_totem": 8, "void_tower": 9
}

var _enemies: Dictionary = {}
var _bosses: Dictionary = {}
var _towers: Dictionary = {}
var _difficulties: Dictionary = {}
var _rows: PackedStringArray = PackedStringArray()
var _summaries: Array[Dictionary] = []
var _missing_levels: PackedStringArray = PackedStringArray()

func _init() -> void:
	_load_definitions()
	_rows.append("level_id,mode,strategy,seed,won,remaining_hp,seconds,loss_wave,target_win_rate,is_boss_level")
	for world: int in range(1, 11):
		for number: int in range(1, 11):
			var path: String = "res://data/levels/world%02d/level%02d.json" % [world, number]
			if not FileAccess.file_exists(path):
				_missing_levels.append("%d-%d" % [world, number])
				continue
			var level: Dictionary = _load_json(path)
			if level.is_empty():
				push_error("balance_sim: invalid level data at %s" % path)
				continue
			_run_level(level, world, number)
	_write_csv()
	_write_report()
	print("balance_sim: %d simulations across %d level/mode summaries. CSV: res://reports/balance_sim_results.csv" % [_rows.size() - 1, _summaries.size()])
	if not _missing_levels.is_empty():
		print("balance_sim: missing campaign levels: %s" % ", ".join(_missing_levels))
	quit(0)

func _run_level(level: Dictionary, world: int, number: int) -> void:
	var level_id: String = String(level.get("level_id", "%d-%d" % [world, number]))
	var is_boss: bool = _contains_boss(level)
	for mode: String in MODE_TARGETS.keys():
		var outcomes: Array[Dictionary] = []
		for strategy_index: int in STRATEGIES.size():
			var strategy: String = STRATEGIES[strategy_index]
			for seed_index: int in RUNS_PER_STRATEGY:
				var seed: int = world * 100000 + number * 1000 + strategy_index * 100 + seed_index
				var outcome: Dictionary = _simulate(level, world, mode, strategy, seed)
				outcomes.append(outcome)
				_rows.append("%s,%s,%s,%d,%d,%d,%.2f,%d,%.2f,%d" % [
					level_id, mode, strategy, seed, 1 if bool(outcome["won"]) else 0,
					int(outcome["remaining_hp"]), float(outcome["seconds"]), int(outcome["loss_wave"]),
					_target_for(mode, is_boss), 1 if is_boss else 0
				])
		_summaries.append(_summarize(level_id, mode, outcomes, is_boss))

func _simulate(level: Dictionary, world: int, mode: String, strategy: String, seed: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	var difficulty: Dictionary = Dictionary(_difficulties.get(mode, {}))
	var hp_multiplier: float = float(difficulty.get("enemy_hp_multiplier", 1.0))
	var speed_multiplier: float = float(difficulty.get("enemy_speed_multiplier", 1.0))
	var bounty_multiplier: float = float(difficulty.get("bounty_multiplier", 1.0))
	var base_hp: float = float(difficulty.get("base_hp", level.get("base_hp", 20)))
	var gold: float = float(level.get("starting_gold", 500)) * float(difficulty.get("starting_gold_multiplier", 1.0))
	var spent: float = 0.0
	var seconds: float = 0.0
	var loss_wave: int = 0
	var waves: Array = Array(level.get("waves", [])).duplicate(true)
	var modifier: String = str(level.get("modifier", ""))
	if int(difficulty.get("extra_waves", 0)) > 0 and not waves.is_empty():
		for extra: int in int(difficulty.get("extra_waves", 0)):
			waves.append(Dictionary(waves[waves.size() - 1]).duplicate(true))
	for wave_index: int in waves.size():
		var wave: Dictionary = Dictionary(waves[wave_index])
		var available: float = maxf(0.0, gold - spent)
		spent += available * 0.82
		var power: float = spent * _strategy_efficiency(world, strategy) * rng.randf_range(0.92, 1.08)
		power *= _modifier_power(modifier)
		var wave_pressure: float = 0.0
		var leak_damage: float = 0.0
		var spawn_seconds: float = 0.0
		var bounty: float = 0.0
		for group: Dictionary in Array(wave.get("groups", [])):
			var group_result: Dictionary = _group_result(group, hp_multiplier, speed_multiplier, strategy)
			var pressure: float = float(group_result["pressure"])
			var group_window: float = float(group_result["window"])
			var count: int = int(group_result["count"])
			var weight: float = float(group_result["weight"])
			wave_pressure += pressure
			spawn_seconds = maxf(spawn_seconds, group_window)
			var share: float = pressure / maxf(1.0, wave_pressure)
			var clear_capacity: float = power * group_window * _strategy_match(group, strategy)
			if clear_capacity < pressure:
				leak_damage += ceil((pressure - clear_capacity) / maxf(1.0, pressure) * float(count) * weight * (0.55 + share))
			if modifier != "gold_scarce":
				bounty += float(group_result["bounty"]) * bounty_multiplier
		var clear_seconds: float = wave_pressure / maxf(1.0, power)
		seconds += maxf(spawn_seconds, clear_seconds)
		base_hp -= leak_damage
		if base_hp <= 0.0:
			loss_wave = wave_index + 1
			break
		gold += bounty
	return {"won": base_hp > 0.0, "remaining_hp": maxi(0, roundi(base_hp)), "seconds": seconds, "loss_wave": loss_wave}

func _group_result(group: Dictionary, hp_multiplier: float, speed_multiplier: float, strategy: String) -> Dictionary:
	var unit_id: String = String(group.get("boss", group.get("enemy", "")))
	var unit: Dictionary = Dictionary(_bosses.get(unit_id, _enemies.get(unit_id, {})))
	var count: int = 1 if group.has("boss") else int(group.get("count", 0))
	var hp: float = float(unit.get("hp", 100.0)) * hp_multiplier
	var speed: float = float(unit.get("speed", 50.0)) * speed_multiplier
	var armor: float = float(unit.get("armor", 0.0))
	var resist: float = maxf(float(unit.get("physical_resist", 0.0)), float(unit.get("magic_resist", 0.0)))
	var defense: float = 1.0 + armor / 170.0 + resist * 0.50
	var is_boss: bool = group.has("boss")
	var pressure: float = float(count) * hp * defense * (1.0 + speed / 240.0)
	if is_boss:
		pressure *= 1.30
	var interval: float = float(group.get("interval", 0.65))
	var window: float = (28.0 if is_boss else 15.0) + maxf(1.0, interval * float(maxi(0, count - 1)))
	var bounty: float = float(count) * float(unit.get("bounty", 0))
	return {"pressure": pressure, "window": window, "count": count, "weight": float(unit.get("leak_weight", 1)), "bounty": bounty, "strategy": strategy}

func _strategy_efficiency(world: int, strategy: String) -> float:
	var efficiency_total: float = 0.0
	var matches: int = 0
	for tower_id: String in _towers.keys():
		if int(TOWER_UNLOCKS.get(tower_id, 10)) > world:
			continue
		var tower: Dictionary = Dictionary(_towers[tower_id])
		if not _strategy_accepts(tower, strategy):
			continue
		var dps: float = _tower_dps(tower)
		if dps <= 0.0:
			continue
		efficiency_total += dps / maxf(1.0, float(tower.get("base_cost", 100)) * 6.8)
		matches += 1
	if matches == 0:
		return 0.08
	return efficiency_total / float(matches)

func _strategy_accepts(tower: Dictionary, strategy: String) -> bool:
	var role: String = String(tower.get("role", ""))
	var element: String = String(tower.get("element", ""))
	match strategy:
		"splash_control": return role in ["area", "control", "block", "support"] or element in ["fire", "ice", "poison", "lightning"]
		"elite_focus": return role in ["single_target", "damage"] or element in ["magic", "arcane", "physical"]
		_: return role != "economy"

func _tower_dps(tower: Dictionary) -> float:
	var final_level: Dictionary = {}
	var branches: Dictionary = Dictionary(tower.get("branches", {}))
	for branch_id: String in branches.keys():
		var levels: Array = Array(Dictionary(branches[branch_id]).get("levels", []))
		if levels.size() >= 2:
			var candidate: Dictionary = Dictionary(levels[levels.size() - 1])
			if float(candidate.get("damage", 0.0)) > float(final_level.get("damage", 0.0)):
				final_level = candidate
	if final_level.is_empty():
		var base_levels: Array = Array(tower.get("levels", []))
		if not base_levels.is_empty():
			final_level = Dictionary(base_levels[base_levels.size() - 1])
	var shots: float = float(final_level.get("multishot", 1))
	var dps: float = float(final_level.get("damage", 0.0)) * shots / maxf(0.1, float(final_level.get("interval", 1.0)))
	if float(final_level.get("splash", 0.0)) > 0.0:
		dps *= 1.55
	return dps

func _strategy_match(group: Dictionary, strategy: String) -> float:
	var is_boss: bool = group.has("boss")
	var count: int = 1 if is_boss else int(group.get("count", 0))
	match strategy:
		"splash_control": return 1.35 if count >= 10 else 0.82
		"elite_focus": return 1.28 if is_boss or count <= 4 else 0.76
		_: return 1.0

func _modifier_power(modifier: String) -> float:
	match modifier:
		"fog": return 0.85
		"tower_limited": return 0.78
		"fast_waves": return 0.88
		"elite_dominant": return 0.86
		"gold_scarce": return 0.90
		_: return 1.0

func _summarize(level_id: String, mode: String, outcomes: Array[Dictionary], is_boss: bool) -> Dictionary:
	var wins: int = 0
	var hp_total: float = 0.0
	var seconds_total: float = 0.0
	var loss_waves: Dictionary = {}
	for outcome: Dictionary in outcomes:
		if bool(outcome["won"]):
			wins += 1
		hp_total += float(outcome["remaining_hp"])
		seconds_total += float(outcome["seconds"])
		var loss_wave: int = int(outcome["loss_wave"])
		if loss_wave > 0:
			loss_waves[loss_wave] = int(loss_waves.get(loss_wave, 0)) + 1
	var dominant_loss_wave: int = 0
	var max_losses: int = 0
	for wave: int in loss_waves.keys():
		if int(loss_waves[wave]) > max_losses:
			max_losses = int(loss_waves[wave])
			dominant_loss_wave = wave
	return {"level_id": level_id, "mode": mode, "runs": outcomes.size(), "wins": wins, "win_rate": float(wins) / float(outcomes.size()), "avg_hp": hp_total / float(outcomes.size()), "avg_seconds": seconds_total / float(outcomes.size()), "loss_wave": dominant_loss_wave, "target": _target_for(mode, is_boss), "is_boss": is_boss}

func _target_for(mode: String, is_boss: bool) -> float:
	return float(BOSS_TARGETS[mode] if is_boss else MODE_TARGETS[mode])

func _contains_boss(level: Dictionary) -> bool:
	for wave: Dictionary in Array(level.get("waves", [])):
		for group: Dictionary in Array(wave.get("groups", [])):
			if group.has("boss"):
				return true
	return false

func _load_definitions() -> void:
	_difficulties = _load_json("res://data/difficulty.json")
	_enemies = _load_directory("res://data/enemies")
	_bosses = _load_directory("res://data/bosses")
	_towers = _load_directory("res://data/towers")

func _load_directory(path: String) -> Dictionary:
	var result: Dictionary = {}
	for filename: String in DirAccess.get_files_at(path):
		if not filename.ends_with(".json"):
			continue
		var definition: Dictionary = _load_json("%s/%s" % [path, filename])
		var id: String = String(definition.get("id", ""))
		if not id.is_empty():
			result[id] = definition
	return result

func _load_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	return Dictionary(json.data)

func _write_csv() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var file: FileAccess = FileAccess.open("res://reports/balance_sim_results.csv", FileAccess.WRITE)
	file.store_string("\n".join(_rows) + "\n")

func _write_report() -> void:
	var lines: PackedStringArray = PackedStringArray([
		"# P12 balance simulation report", "",
		"This deterministic, no-render model runs three fixed strategies (balanced, splash/control, and elite focus) across ten seeds each. It is a tuning signal based on game data, not a substitute for device playtests.", "",
		"| Level | Mode | Win rate | Target | Avg HP | Avg time | Dominant loss wave | Recommendation |",
		"| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |"
	])
	for summary: Dictionary in _summaries:
		var recommendation: String = _recommendation(summary)
		lines.append("| %s | %s | %.0f%% | %.0f%% | %.1f | %.1fs | %d | %s |" % [summary["level_id"], summary["mode"], float(summary["win_rate"]) * 100.0, float(summary["target"]) * 100.0, float(summary["avg_hp"]), float(summary["avg_seconds"]), int(summary["loss_wave"]), recommendation])
	if not _missing_levels.is_empty():
		lines.append("")
		lines.append("## Release blocker")
		lines.append("Missing level data: %s. The campaign currently has 94/100 level files, so it does not meet the PRD's 100-level release criterion." % ", ".join(_missing_levels))
	var file: FileAccess = FileAccess.open("res://reports/balance_sim_report.md", FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")

func _recommendation(summary: Dictionary) -> String:
	var delta: float = float(summary["win_rate"]) - float(summary["target"])
	if absf(delta) <= 0.10:
		return "Within the ±10-point review band."
	var parts: PackedStringArray = String(summary["level_id"]).split("-")
	if parts.size() != 2:
		return "Review this result manually."
	var world: int = int(parts[0])
	var number: int = int(parts[1])
	var level: Dictionary = _load_json("res://data/levels/world%02d/level%02d.json" % [world, number])
	var waves: Array = Array(level.get("waves", []))
	if waves.is_empty():
		return "Review this result manually."
	var wave_index: int = clampi(maxi(1, int(summary["loss_wave"])) - 1, 0, waves.size() - 1)
	var wave: Dictionary = Dictionary(waves[wave_index])
	var strongest_group: Dictionary = {}
	var strongest_pressure: float = -1.0
	for group: Dictionary in Array(wave.get("groups", [])):
		var unit_id: String = str(group.get("boss", group.get("enemy", "")))
		var unit: Dictionary = Dictionary(_bosses.get(unit_id, _enemies.get(unit_id, {})))
		var count: int = 1 if group.has("boss") else int(group.get("count", 0))
		var pressure: float = float(count) * float(unit.get("hp", 0.0))
		if pressure > strongest_pressure:
			strongest_pressure = pressure
			strongest_group = group
	if strongest_group.is_empty():
		return "Review the groups in wave %d manually." % (wave_index + 1)
	var unit_id: String = str(strongest_group.get("boss", strongest_group.get("enemy", "")))
	if strongest_group.has("boss"):
		var boss: Dictionary = Dictionary(_bosses.get(unit_id, {}))
		var hp: float = float(boss.get("hp", 0.0))
		var proposed_hp: int = roundi(hp * (1.12 if delta > 0.0 else 0.90))
		return "data/bosses/%s.json: HP %d -> %d." % [unit_id, roundi(hp), proposed_hp]
	var count: int = int(strongest_group.get("count", 0))
	var proposed_count: int = maxi(1, ceili(float(count) * (1.12 if delta > 0.0 else 0.90)))
	return "data/levels/world%02d/level%02d.json, wave %d: %s count %d -> %d." % [world, number, wave_index + 1, unit_id, count, proposed_count]
