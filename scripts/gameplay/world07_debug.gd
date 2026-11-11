extends Node
## P10 World 7 smoke test: conveyor route, speed states, workshop, and Overseer spawn.

var _previous_snapshot: Dictionary = {}

func _enter_tree() -> void:
	_previous_snapshot = SaveManager.get_active_run()
	SaveManager.set_active_run({"level_id": "7-1", "difficulty": "normal", "wave": 1, "gold": 930, "base_hp": 20, "towers": []})

func _ready() -> void:
	await get_tree().process_frame
	var game: Node = $GameRoot
	assert(String(game._current_level.get("level_id", "")) == "7-1", "World 7 level should load through GameController.")
	assert(game._tower_definitions.has("mechanic_workshop"), "Mechanic Workshop definition must load for World 7.")
	assert(is_equal_approx(game._world_rules.get_enemy_speed_multiplier(), 1.20), "Short conveyor route must speed enemies by 20%.")
	var short_path: PackedVector2Array = game._path_points.duplicate()
	assert(game._world_rules.toggle_bridge(), "Clockwork gate must be switchable.")
	assert(is_equal_approx(game._world_rules.get_enemy_speed_multiplier(), 0.80), "Long conveyor route must slow enemies by 20%.")
	assert(game._path_points != short_path, "Clockwork gate must redirect to the long route.")
	game._boss_controller.start_encounter("overseer_automaton")
	game._enemy_manager.tick(0.1)
	game._boss_controller.tick(0.1)
	assert(game._enemy_manager.find_active_enemy_index("overseer_automaton") >= 0, "Overseer must spawn through BossController.")
	SaveManager.set_active_run(_previous_snapshot)
	print("P10 World 7 smoke test passed.")
	get_tree().quit()
