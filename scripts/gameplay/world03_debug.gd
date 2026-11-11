extends Node
## P10 World 3 smoke test: normal level load, mud rule, and bridge route switch.

var _previous_snapshot: Dictionary = {}

func _enter_tree() -> void:
	_previous_snapshot = SaveManager.get_active_run()
	SaveManager.set_active_run({"level_id": "3-1", "difficulty": "normal", "wave": 1, "gold": 620, "base_hp": 20, "towers": []})

func _ready() -> void:
	await get_tree().process_frame
	var game: Node = $GameRoot
	assert(String(game._current_level.get("level_id", "")) == "3-1", "World 3 level should load through GameController.")
	assert(is_equal_approx(game._world_rules.get_enemy_speed_multiplier(), 0.80), "Mud must slow enemy movement by 20%.")
	assert(game._world_rules.has_bridge_lever(), "Swamp level should expose the bridge lever.")
	assert(game._world_rules.toggle_bridge(), "Bridge lever should switch the active path.")
	assert(game._path_points[2].y > 600.0, "Alternate bridge route should replace the active path.")
	SaveManager.set_active_run(_previous_snapshot)
	print("P10 World 3 smoke test passed.")
	get_tree().quit()
