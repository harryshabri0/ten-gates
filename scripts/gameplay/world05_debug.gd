extends Node
## P10 World 5 smoke test: level load and the data-driven day/night rule.

var _previous_snapshot: Dictionary = {}

func _enter_tree() -> void:
	_previous_snapshot = SaveManager.get_active_run()
	SaveManager.set_active_run({"level_id": "5-1", "difficulty": "normal", "wave": 1, "gold": 760, "base_hp": 20, "towers": []})

func _ready() -> void:
	await get_tree().process_frame
	var game: Node = $GameRoot
	assert(String(game._current_level.get("level_id", "")) == "5-1", "World 5 level should load through GameController.")
	assert(not game._world_rules.is_night(), "Graveyard must start in daylight.")
	assert(is_zero_approx(game._world_rules.get_enemy_regen_percent()), "Enemies must not regenerate during daylight.")
	game._world_rules.tick(20.0)
	assert(game._world_rules.is_night(), "Graveyard must switch to night after one cycle.")
	assert(is_equal_approx(game._world_rules.get_enemy_regen_percent(), 0.01), "Night must regenerate 1% max HP per second.")
	assert(game._tower_definitions.has("ballista"), "Ballista definition must load for World 5.")
	game._boss_controller.start_encounter("morthal")
	game._enemy_manager.tick(0.1)
	game._boss_controller.tick(0.1)
	game._enemy_manager.tick(0.0)
	assert(game._enemy_manager.count_active_enemy_id("morthal_phylactery") == 3, "Morthal must spawn three phylactery pillars.")
	var morthal_index: int = game._enemy_manager.find_active_enemy_index("morthal")
	assert(not game._enemy_manager.is_targetable(morthal_index), "Morthal must be protected while phylacteries exist.")
	for phylactery_index: int in game._enemy_manager.get_targets_in_radius(game._enemy_manager.get_enemy_position(morthal_index), 1.0, 10):
		if game._enemy_manager.is_enemy_active(phylactery_index) and phylactery_index != morthal_index:
			game._enemy_manager.damage_enemy(phylactery_index, 10000.0)
	game._boss_controller.tick(0.1)
	assert(game._enemy_manager.is_targetable(morthal_index), "Morthal must become targetable after every phylactery is destroyed.")
	SaveManager.set_active_run(_previous_snapshot)
	print("P10 World 5 smoke test passed.")
	get_tree().quit()
