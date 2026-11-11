extends SceneTree
## Deterministic no-render pressure estimate for World 8; P12 replaces this with battle bots.

func _init() -> void:
	var loader: LevelLoader = LevelLoader.new()
	var mode_multiplier: Dictionary = {"easy": 0.75, "normal": 1.0, "hard": 1.35}
	for mode: String in mode_multiplier.keys():
		var wins: int = 0
		for level_number: int in 10:
			var level: Dictionary = loader.load_level("8-%d" % (level_number + 1))
			var pressure: float = 0.0
			for wave: Dictionary in Array(level.get("waves", [])):
				for group: Dictionary in Array(wave.get("groups", [])):
					pressure += 1600.0 if group.has("boss") else {"sky_carrier": 62.0, "swarm_drone": 25.0}.get(String(group.get("enemy", "")), 0.0) * float(group.get("count", 0))
			if float(level.get("starting_gold", 0)) * 4.4 / float(mode_multiplier[mode]) >= pressure:
				wins += 1
		print("World8 %s heuristic win rate: %d%% (%d/10)" % [mode.capitalize(), wins * 10, wins])
	quit(0)
