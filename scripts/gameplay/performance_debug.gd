extends Node
## P11 integrated smoke coverage for the 200-enemy pool and quality visual budgets.

func _ready() -> void:
	await get_tree().process_frame
	var game: Node = $GameRoot
	Settings.update_preferences({"quality": "low"})
	game._enemy_manager.reset()
	game._enemy_manager.queue_spawn("swarmling", 200, 0.03)
	for _tick: int in 200:
		game._enemy_manager.tick(1.0 / 30.0)
	assert(game._enemy_manager.active_count() == 200, "P11 stress pool must hold 200 active enemies.")
	assert(game._status_system._states.size() == PrototypeEnemyManager.MAX_ENEMIES, "Status pool must match the enemy pool.")
	assert(game._enemy_manager._draw_stride == 3, "Low quality must reduce enemy visual density.")
	assert(game._projectile_pool._draw_stride == 4, "Low quality must reduce projectile visual density.")
	Settings.update_preferences({"quality": "medium"})
	assert(game._enemy_manager._draw_stride == 2, "Medium quality must reduce enemy visual density.")
	assert(game._projectile_pool._draw_stride == 2, "Medium quality must reduce projectile visual density.")
	Settings.update_preferences({"quality": "high"})
	assert(game._enemy_manager._draw_stride == 1, "High quality must render all enemy visuals.")
	assert(game._projectile_pool._draw_stride == 1, "High quality must render all projectile visuals.")
	print("P11 performance smoke test passed: 200 active enemies and quality profiles.")
	get_tree().quit()
