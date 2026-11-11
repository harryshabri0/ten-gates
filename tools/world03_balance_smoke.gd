extends SceneTree
## Deterministic no-render pressure estimate for World 3; P12 replaces this with battle bots.

func _init() -> void:
	var loader: LevelLoader = LevelLoader.new()
	var mode_multiplier: Dictionary = {"easy": 0.75, "normal": 1.0, "hard": 1.35}
	for mode: String in mode_multiplier.keys():
		var wins: int = 0
		for level_number: int in 10:
			var level: Dictionary = loader.load_level("3-%d" % (level_number + 1))
			var pressure: float = 0.0
			for wave: Dictionary in Array(level.get("waves", [])):
				for group: Dictionary in Array(wave.get("groups", [])):
					if group.has("boss"):
						pressure += 670.0
					else:
						var weight: float = {"swamp_shaman": 22.0, "spore_splitter": 21.0, "poison_spitter": 20.0}.get(String(group.get("enemy", "")), 0.0)
						pressure += weight * float(group.get("count", 0))
			var capacity: float = float(level.get("starting_gold", 0)) * 4.8 / float(mode_multiplier[mode])
			if capacity >= pressure:
				wins += 1
		print("World3 %s heuristic win rate: %d%% (%d/10)" % [mode.capitalize(), wins * 10, wins])
	quit(0)
