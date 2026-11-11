extends Node
## P10 World 8 smoke test: air wind, floating island slots, Totem, and Zephyra.

var _previous_snapshot: Dictionary = {}

func _enter_tree() -> void:
	_previous_snapshot = SaveManager.get_active_run()
	SaveManager.set_active_run({"level_id": "8-1", "difficulty": "normal", "wave": 1, "gold": 1020, "base_hp": 20, "towers": []})

func _ready() -> void:
	await get_tree().process_frame
	var game: Node = $GameRoot
	assert(String(game._current_level.get("level_id", "")) == "8-1", "World 8 level should load through GameController.")
	assert(game._tower_definitions.has("war_totem"), "War Totem definition must load for World 8.")
	assert(is_equal_approx(game._world_rules.get_air_speed_multiplier(), 1.20), "Sky wind must accelerate air enemies by 20%.")
	var initial_slot: Vector2 = game._slot_positions[0]
	game._on_wave_started(4)
	assert(game._slot_positions[0] != initial_slot, "Floating island slots must shift every three waves.")
	game._boss_controller.start_encounter("zephyra")
	game._enemy_manager.tick(0.1)
	game._boss_controller.tick(0.1)
	var zephyra_index: int = game._enemy_manager.find_active_enemy_index("zephyra")
	assert(zephyra_index >= 0 and bool(game._enemy_manager._enemies[zephyra_index]["anti_air_only"]), "Zephyra must initially require anti-air targeting.")
	SaveManager.set_active_run(_previous_snapshot)
	print("P10 World 8 smoke test passed.")
	get_tree().quit()
