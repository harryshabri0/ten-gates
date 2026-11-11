class_name PrototypeWaveDirector
extends Node
## Reads a level JSON and queues one complete wave at a time.

signal wave_started(number: int)
signal wave_completed(number: int)
signal level_completed()
signal boss_requested(boss_id: String)

var _waves: Array = []
var _next_wave_index: int = 0
var _running_wave: bool = false
var _enemy_manager: Node
var _level_loader: LevelLoader = LevelLoader.new()
var _current_level: Dictionary = {}
var _difficulty: Dictionary = {}

func load_level(path: String, enemy_manager: Node) -> Dictionary:
	_enemy_manager = enemy_manager
	var level: Dictionary = _level_loader.load_json(path)
	return _configure_level(level)

func load_level_id(level_id: String, enemy_manager: Node) -> Dictionary:
	_enemy_manager = enemy_manager
	return _configure_level(_level_loader.load_level(level_id))

func set_difficulty(difficulty: Dictionary) -> void:
	_difficulty = difficulty

func get_current_level() -> Dictionary:
	return _current_level

func _configure_level(level: Dictionary) -> Dictionary:
	if level.is_empty():
		return {}
	_current_level = level
	_waves = Array(level.get("waves", []))
	var extra_waves: int = int(_difficulty.get("extra_waves", 0))
	for extra_index: int in extra_waves:
		if _waves.is_empty():
			break
		var extra_wave: Dictionary = Dictionary(_waves[_waves.size() - 1]).duplicate(true)
		extra_wave["w"] = _waves.size() + 1
		_waves.append(extra_wave)
	_next_wave_index = 0
	_running_wave = false
	return _current_level

func start_next_wave() -> bool:
	if _running_wave or _next_wave_index >= _waves.size():
		return false
	var wave: Dictionary = _waves[_next_wave_index]
	var modifier: String = str(_current_level.get("modifier", ""))
	for group: Dictionary in Array(wave.get("groups", [])):
		if group.has("boss"):
			boss_requested.emit(str(group["boss"]))
			continue
		var interval: float = float(group["interval"])
		if modifier == "fast_waves":
			interval *= 0.70
		_enemy_manager.queue_spawn(str(group["enemy"]), int(group["count"]), interval, bool(group.get("elite", false)) or modifier == "elite_dominant")
	_running_wave = true
	wave_started.emit(_next_wave_index + 1)
	return true

func tick() -> void:
	if not _running_wave or not _enemy_manager.is_idle():
		return
	_running_wave = false
	wave_completed.emit(_next_wave_index + 1)
	_next_wave_index += 1
	if _next_wave_index >= _waves.size():
		level_completed.emit()

func reset() -> void:
	_next_wave_index = 0
	_running_wave = false

func current_wave_number() -> int:
	return _next_wave_index + 1

func restore_at_wave(wave_number: int) -> void:
	_next_wave_index = clampi(wave_number - 1, 0, _waves.size())
	_running_wave = false

func is_running_wave() -> bool:
	return _running_wave

func get_preview(count: int = 3) -> Array[String]:
	var preview: Array[String] = []
	for index: int in range(_next_wave_index, mini(_next_wave_index + count, _waves.size())):
		var wave: Dictionary = _waves[index]
		var parts: Array[String] = []
		for group: Dictionary in Array(wave.get("groups", [])):
			parts.append("%s ×%d" % [String(group.get("enemy", "? ")).capitalize(), int(group.get("count", 0))])
		preview.append("W%d %s" % [int(wave.get("w", index + 1)), ", ".join(parts)])
	return preview

