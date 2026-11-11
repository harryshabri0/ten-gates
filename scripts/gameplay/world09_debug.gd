extends Node
## P10 World 9 smoke test: portal pair, Void Tower, and Eclipse Weaver spawn.

var _previous_snapshot: Dictionary = {}

func _enter_tree() -> void:
	_previous_snapshot = SaveManager.get_active_run()
	SaveManager.set_active_run({"level_id": "9-1", "difficulty": "normal", "wave": 1, "gold": 1120, "base_hp": 20, "towers": []})

func _ready() -> void:
	await get_tree().process_frame
	var game: Node = $GameRoot
	assert(String(game._current_level.get("level_id", "")) == "9-1", "World 9 level should load through GameController.")
	assert(game._tower_definitions.has("void_tower"), "Void Tower definition must load for World 9.")
	game._on_wave_started(1)
	assert(is_equal_approx(game._enemy_manager._portal_entry_ratio, 0.25), "First portal entry must come from level data.")
	assert(is_equal_approx(game._enemy_manager._portal_exit_ratio, 0.52), "First portal exit must come from level data.")
	game._on_wave_started(4)
	assert(is_equal_approx(game._enemy_manager._portal_entry_ratio, 0.38), "Portal pair must shift after three waves.")
	game._boss_controller.start_encounter("eclipse_weaver")
	game._enemy_manager.tick(0.1)
	game._boss_controller.tick(0.1)
	assert(game._enemy_manager.find_active_enemy_index("eclipse_weaver") >= 0, "Eclipse Weaver must spawn through BossController.")
	SaveManager.set_active_run(_previous_snapshot)
	print("P10 World 9 smoke test passed.")
	get_tree().quit()
