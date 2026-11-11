extends SceneTree
## P10 data validation for the currently produced campaign content.

func _init() -> void:
	var failures: Array[String] = []
	for world: int in [2, 3, 4, 5, 6, 7, 8, 9, 10]:
		for number: int in 10:
			var level_path: String = "res://data/levels/world%02d/level%02d.json" % [world, number + 1]
			var level: Dictionary = _read_json(level_path, failures)
			if level.is_empty():
				continue
			if String(level.get("level_id", "")) != "%d-%d" % [world, number + 1]:
				failures.append("Wrong level_id in %s" % level_path)
			if Array(level.get("waves", [])).is_empty():
				failures.append("No waves in %s" % level_path)
			var layout_path: String = String(level.get("layout_data", ""))
			var layout: Dictionary = _read_json(layout_path, failures)
			if not layout.is_empty() and (Array(layout.get("path", [])).size() < 2 or Array(layout.get("slots", [])).size() < 8):
				failures.append("Invalid layout shape: %s" % layout_path)
	for boss_path: String in ["res://data/bosses/scarab_queen.json", "res://data/bosses/khepri.json", "res://data/bosses/swamp_witch.json", "res://data/bosses/mother_hydra.json", "res://data/bosses/ice_guardian.json", "res://data/bosses/glacier_titan.json", "res://data/bosses/bone_colossus.json", "res://data/bosses/morthal.json", "res://data/bosses/lava_brute.json", "res://data/bosses/ignis.json", "res://data/bosses/siege_walker.json", "res://data/bosses/overseer_automaton.json", "res://data/bosses/harpy_matron.json", "res://data/bosses/zephyra.json", "res://data/bosses/mirror_shade.json", "res://data/bosses/eclipse_weaver.json", "res://data/bosses/dread_sovereign.json"]:
		var boss: Dictionary = _read_json(boss_path, failures)
		if boss.is_empty() or Array(boss.get("phases", [])).is_empty():
			failures.append("Boss phases missing: %s" % boss_path)
	for asset_path: String in ["res://data/towers/ballista.json", "res://data/enemies/wraith.json", "res://data/enemies/necro_acolyte.json", "res://data/enemies/morthal_phylactery.json", "res://data/towers/fire_tower.json", "res://data/enemies/infiltrator.json", "res://data/enemies/magma_golem.json", "res://data/enemies/bomber_imp.json", "res://data/towers/mechanic_workshop.json", "res://data/enemies/machine_soldier.json", "res://data/enemies/swarm_drone.json", "res://data/enemies/tesla_bot.json", "res://data/enemies/repair_bot.json", "res://data/towers/war_totem.json", "res://data/enemies/sky_carrier.json", "res://data/towers/void_tower.json", "res://data/enemies/void_walker.json", "res://data/enemies/void_leech.json", "res://data/enemies/eclipse_clone.json", "res://data/enemies/demon_berserker.json", "res://data/enemies/dread_echo.json"]:
		var asset: Dictionary = _read_json(asset_path, failures)
		if asset.is_empty() or String(asset.get("id", "")).is_empty():
			failures.append("Asset id missing: %s" % asset_path)
	if failures.is_empty():
		print("validate_data: Worlds 2-10 passed (90 levels, 36 layouts, 17 bosses).")
		quit(0)
	else:
		for issue: String in failures:
			push_error(issue)
		quit(1)

func _read_json(path: String, failures: Array[String]) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		failures.append("Missing JSON: %s" % path)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var json: JSON = JSON.new()
	if file == null or json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		failures.append("Invalid JSON: %s" % path)
		return {}
	return Dictionary(json.data)

