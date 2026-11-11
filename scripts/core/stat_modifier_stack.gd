class_name StatModifierStack
extends RefCounted
## Small data-driven stat stack: percentage modifiers multiply, flat modifiers add.

var _percent: Dictionary = {}
var _flat: Dictionary = {}

func clear() -> void:
	_percent.clear()
	_flat.clear()

func add_percent(stat: String, source: String, value: float) -> void:
	if not _percent.has(stat):
		_percent[stat] = {}
	_percent[stat][source] = value

func add_flat(stat: String, source: String, value: float) -> void:
	if not _flat.has(stat):
		_flat[stat] = {}
	_flat[stat][source] = value

func multiplier(stat: String) -> float:
	var result: float = 1.0
	for value: float in Dictionary(_percent.get(stat, {})).values():
		result *= 1.0 + value
	return result

func flat(stat: String) -> float:
	var result: float = 0.0
	for value: float in Dictionary(_flat.get(stat, {})).values():
		result += value
	return result

func evaluate(stat: String, base: float) -> float:
	return base * multiplier(stat) + flat(stat)

func to_preview() -> Dictionary:
	return {"percent": _percent.duplicate(true), "flat": _flat.duplicate(true)}
