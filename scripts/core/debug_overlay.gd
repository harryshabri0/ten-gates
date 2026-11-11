extends CanvasLayer
## Development-only instrumentation. It intentionally samples frame metrics.

@onready var _metrics: Label = $Panel/Metrics

var _enemy_count: int = 0
var _projectile_count: int = 0

func _ready() -> void:
	_enemy_count = GameState.active_enemy_count
	_projectile_count = GameState.active_projectile_count
	GameState.enemy_count_changed.connect(_on_enemy_count_changed)
	GameState.projectile_count_changed.connect(_on_projectile_count_changed)
	_refresh_metrics()

func _process(_delta: float) -> void:
	_refresh_metrics()

func _on_enemy_count_changed(value: int) -> void:
	_enemy_count = value

func _on_projectile_count_changed(value: int) -> void:
	_projectile_count = value

func _refresh_metrics() -> void:
	var fps: float = Engine.get_frames_per_second()
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var status_system: PrototypeStatusSystem = get_tree().get_first_node_in_group("status_system") as PrototypeStatusSystem
	var status_line: String = "Status: --"
	if status_system != null:
		status_line = "Status: %d • %.3f ms" % [status_system.active_status_count, status_system.last_tick_ms]
	_metrics.text = "FPS: %d\nQuality: %s\nEnemies: %d\nProjectiles: %d\nDraw calls: %d\n%s" % [roundi(fps), Settings.quality.capitalize(), _enemy_count, _projectile_count, draw_calls, status_line]

