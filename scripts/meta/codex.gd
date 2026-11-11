class_name Codex
extends RefCounted
## Persistent discovery list for first-seen towers and enemies.

var _entries: Dictionary = {"towers": {}, "enemies": {}}

func load_data(data: Dictionary) -> void:
	_entries = {"towers": Dictionary(data.get("towers", {})), "enemies": Dictionary(data.get("enemies", {}))}

func discover(category: String, entry_id: String) -> bool:
	if not _entries.has(category) or entry_id.is_empty() or Dictionary(_entries[category]).has(entry_id):
		return false
	_entries[category][entry_id] = true
	return true

func has(category: String, entry_id: String) -> bool:
	return Dictionary(_entries.get(category, {})).has(entry_id)

func get_entries(category: String) -> Array[String]:
	var result: Array[String] = []
	for entry_id: String in Dictionary(_entries.get(category, {})).keys():
		result.append(entry_id)
	result.sort()
	return result

func to_data() -> Dictionary:
	return _entries.duplicate(true)
