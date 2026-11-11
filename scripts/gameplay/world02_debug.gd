extends Node
## P10 World 2 smoke test: loads 2-1 through the normal controller and advances its rule.

var _previous_snapshot: Dictionary = {}

func _enter_tree() -> void:
	_previous_snapshot = SaveManager.get_active_run()
	SaveManager.set_active_run({"level_id": "2-1", "difficulty": "normal", "wave": 1, "gold": 560, "base_hp": 20, "towers": []})

func _ready() -> void:
	await get_tree().process_frame
	var game: Node = $GameRoot
	assert(String(game._current_level.get("level_id", "")) == "2-1", "World 2 level should load through GameController.")
	assert(game._slot_positions.size() >= 8, "World 2 layout should supply build slots.")
	game._world_rules.tick(30.0)
	assert(is_equal_approx(game._world_rules.get_tower_range_multiplier(), 0.75), "Sandstorm should reduce range to 75%.")
	game._world_rules.tick(8.1)
	assert(is_equal_approx(game._world_rules.get_tower_range_multiplier(), 1.0), "Sandstorm should restore range.")
	SaveManager.set_active_run(_previous_snapshot)
	print("P10 World 2 smoke test passed.")
	get_tree().quit()
