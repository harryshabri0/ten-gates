class_name WaveGenerator
extends RefCounted
## Deterministic budget-wave generator. Important waves can remain hand-authored in JSON.

var _catalog: Dictionary = {}

func load_catalog(path: String = "res://data/wave_catalog.json") -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not load wave catalog.")
		return
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_catalog = Dictionary(json.data)

func generate_world1(level_number: int, modifier: String = "") -> Dictionary:
	if _catalog.is_empty():
		load_catalog()
	var waves: Array = []
	var templates: PackedStringArray = PackedStringArray(["intro", "rush", "tank", "mixed"])
	for wave_number: int in 12:
		var template_name: String = templates[(wave_number + level_number - 1) % templates.size()]
		var budget: int = 28 + level_number * 10 + wave_number * 13
		waves.append({"w": wave_number + 1, "template": template_name, "groups": _build_groups(template_name, budget, wave_number, modifier)})
	return {"level_id": "1-%d" % level_number, "layout": "w1_layoutA", "modifier": modifier if not modifier.is_empty() else null, "waves": waves}

func _build_groups(template_name: String, budget: int, wave_number: int, modifier: String) -> Array:
	var ids: Array = Array(_catalog["templates"][template_name])
	var points: Dictionary = _catalog["enemy_points"]
	var groups: Array = []
	var remaining: int = budget
	var cursor: int = 0
	while remaining >= 5:
		var enemy_id: String = String(ids[cursor % ids.size()])
		var point_cost: int = int(points[enemy_id])
		var count: int = maxi(1, mini(8, floori(float(remaining) / float(point_cost))))
		groups.append({"enemy": enemy_id, "count": count, "interval": maxf(0.16, 0.66 - float(wave_number) * 0.025), "elite": modifier == "elite_dominant" and cursor == 0})
		remaining -= count * point_cost
		cursor += 1
	return groups

