class_name LevelLoader
extends RefCounted
## Reads level/difficulty data without binding gameplay code to a specific level id.

func load_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not load JSON: %s" % path)
		return {}
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Invalid JSON: %s" % path)
		return {}
	return Dictionary(json.data)

func load_level(level_id: String) -> Dictionary:
	var parts: PackedStringArray = level_id.split("-")
	if parts.size() != 2:
		push_error("Invalid level id: %s" % level_id)
		return {}
	var world: int = int(parts[0])
	var level: int = int(parts[1])
	return load_json("res://data/levels/world%02d/level%02d.json" % [world, level])

func load_difficulties() -> Dictionary:
	return load_json("res://data/difficulty.json")

