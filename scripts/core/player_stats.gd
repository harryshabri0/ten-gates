extends Node
## Persistent player-facing totals displayed on the title screen.

signal changed

var _data: Dictionary = {}
var _dirty: bool = false
var _save_elapsed: float = 0.0

func _ready() -> void:
	_data = SaveManager.get_section("statistics")
	for key: String in ["kills", "damage", "towers_built", "waves_cleared", "gold_earned"]:
		_data[key] = int(_data.get(key, 0))

func _process(delta: float) -> void:
	if not _dirty:
		return
	_save_elapsed += delta
	if _save_elapsed >= 2.0:
		flush()

func record_kill(bounty: int) -> void:
	_data["kills"] = int(_data["kills"]) + 1
	_data["gold_earned"] = int(_data["gold_earned"]) + maxi(0, bounty)
	_mark_changed()

func record_damage(amount: float) -> void:
	_data["damage"] = int(_data["damage"]) + maxi(0, roundi(amount))
	_mark_changed()

func record_tower_built() -> void:
	_data["towers_built"] = int(_data["towers_built"]) + 1
	_mark_changed()

func record_wave_cleared() -> void:
	_data["waves_cleared"] = int(_data["waves_cleared"]) + 1
	_mark_changed()

func summary_text() -> String:
	return "KILLS  %s\nDAMAGE  %s\nTOWERS BUILT  %s\nWAVES CLEARED  %s\nGOLD EARNED  %s" % [
		_format(int(_data.get("kills", 0))), _format(int(_data.get("damage", 0))),
		_format(int(_data.get("towers_built", 0))), _format(int(_data.get("waves_cleared", 0))),
		_format(int(_data.get("gold_earned", 0)))
	]

func flush() -> void:
	if not _dirty:
		return
	SaveManager.set_section("statistics", _data, true)
	_dirty = false
	_save_elapsed = 0.0

func _mark_changed() -> void:
	_dirty = true
	_save_elapsed = 0.0
	changed.emit()

func _format(value: int) -> String:
	return "%d" % value
