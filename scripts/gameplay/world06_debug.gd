extends Node
## P10 World 6 smoke test: eruption reroute, marked slots, Fire Tower, and Ignis armor.

var _previous_snapshot: Dictionary = {}

func _enter_tree() -> void:
	_previous_snapshot = SaveManager.get_active_run()
	SaveManager.set_active_run({"level_id": "6-1", "difficulty": "normal", "wave": 1, "gold": 840, "base_hp": 20, "towers": []})

func _ready() -> void:
	await get_tree().process_frame
	var game: Node = $GameRoot
	assert(String(game._current_level.get("level_id", "")) == "6-1", "World 6 level should load through GameController.")
	assert(game._tower_definitions.has("fire_tower"), "Fire Tower definition must load for World 6.")
	var original_path: PackedVector2Array = game._path_points.duplicate()
	game._world_rules.tick(45.0)
	assert(game._world_rules.is_eruption_active(), "Volcano eruption must activate after 45 seconds.")
	assert(game._world_rules.get_eruption_slots().size() == 2, "Eruption must mark two slots.")
	assert(game._path_points != original_path, "Lava must temporarily route enemies along the alternate path.")
	game._world_rules.tick(6.0)
	assert(not game._world_rules.is_eruption_active(), "Eruption must end after 6 seconds.")
	assert(game._path_points == original_path, "Main path must reopen after lava cools.")
	game._boss_controller.start_encounter("ignis")
	game._enemy_manager.tick(0.1)
	game._boss_controller.tick(0.1)
	var ignis_index: int = game._enemy_manager.find_active_enemy_index("ignis")
	assert(ignis_index >= 0, "Ignis must spawn through BossController.")
	assert(is_equal_approx(float(game._enemy_manager._enemies[ignis_index]["armor"]), 90.0), "Ignis must start with three armor plates.")
	game._boss_controller.force_phase(2)
	game._boss_controller.tick(0.1)
	assert(is_equal_approx(float(game._enemy_manager._enemies[ignis_index]["armor"]), 60.0), "Ignis must shed one armor plate in phase two.")
	SaveManager.set_active_run(_previous_snapshot)
	print("P10 World 6 smoke test passed.")
	get_tree().quit()
