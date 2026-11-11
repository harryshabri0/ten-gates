extends Node
## P10 World 4 smoke test: level load, ice-speed rule, and snow-locked slots.

var _previous_snapshot: Dictionary = {}

func _enter_tree() -> void:
	_previous_snapshot = SaveManager.get_active_run()
	SaveManager.set_active_run({"level_id": "4-1", "difficulty": "normal", "wave": 1, "gold": 700, "base_hp": 20, "towers": []})

func _ready() -> void:
	await get_tree().process_frame
	var game: Node = $GameRoot
	assert(String(game._current_level.get("level_id", "")) == "4-1", "World 4 level should load through GameController.")
	assert(is_equal_approx(game._world_rules.get_enemy_speed_multiplier(), 1.30), "Ice should increase enemy speed by 30%.")
	assert(game._slot_types.has("locked"), "World 4 layouts should include snow-locked slots.")
	SaveManager.set_active_run(_previous_snapshot)
	print("P10 World 4 smoke test passed.")
	get_tree().quit()
