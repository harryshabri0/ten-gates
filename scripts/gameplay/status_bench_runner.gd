extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node = get_parent().get_node("GameRoot")
	var enemy_manager: PrototypeEnemyManager = game.get_node("EnemyManager")
	var status_system: PrototypeStatusSystem = game.get_node("StatusSystem")
	enemy_manager.reset()
	enemy_manager.queue_spawn("swarmling", 120, 0.03)
	for _step: int in 140:
		enemy_manager.tick(1.0 / 30.0)
		status_system.tick(1.0 / 30.0)
	for enemy_index: int in 120:
		status_system.apply_status(enemy_index, "burn", 5.0, 0.25)
		status_system.apply_status(enemy_index, "poison", 5.0, 1.0)
		status_system.apply_status(enemy_index, "slow", 5.0, 0.6)
		status_system.apply_status(enemy_index, "mark", 5.0, 1.2)
	var start_us: int = Time.get_ticks_usec()
	for _step: int in 120:
		enemy_manager.tick(1.0 / 30.0)
		status_system.tick(1.0 / 30.0)
	var elapsed_ms: float = float(Time.get_ticks_usec() - start_us) / 1000.0
	print("STATUS_BENCH 120 enemies / 4 statuses: %.3f ms total, %.3f ms per simulation tick, %.3f ms per status tick" % [elapsed_ms, elapsed_ms / 120.0, status_system.last_tick_ms])
	get_tree().quit()
