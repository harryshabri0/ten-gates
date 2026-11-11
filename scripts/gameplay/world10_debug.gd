extends Node
var _previous_snapshot: Dictionary = {}
func _enter_tree() -> void:
	_previous_snapshot = SaveManager.get_active_run()
	SaveManager.set_active_run({"level_id":"10-1","difficulty":"normal","wave":1,"gold":1250,"base_hp":20,"towers":[]})
func _ready() -> void:
	await get_tree().process_frame
	var game: Node = $GameRoot
	assert(String(game._current_level.get("level_id", "")) == "10-1", "World 10 remix level should load.")
	assert(String(game._current_level.get("world_rule", {}).get("id", "")) == "desert_sandstorm", "10-1 must remix a prior world rule.")
	game._boss_controller.start_encounter("dread_sovereign")
	game._enemy_manager.tick(0.1)
	game._boss_controller.tick(0.1)
	assert(game._enemy_manager.find_active_enemy_index("dread_sovereign") >= 0, "Dread Sovereign must spawn.")
	SaveManager.set_active_run(_previous_snapshot)
	print("P10 World 10 smoke test passed.")
	get_tree().quit()
