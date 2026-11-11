class_name LoadoutManager
extends RefCounted
## World 1-3 use every unlocked tower. World 4+ validates a six-tower selection.

const MAX_TOWERS: int = 6

func requires_selection(world: int) -> bool:
	return world >= 4

func validate_selection(selected: Array[String], unlocked: Array[String], mandatory_borrowed: Array[String] = []) -> Dictionary:
	var merged: Array[String] = selected.duplicate()
	for tower_id: String in mandatory_borrowed:
		if not merged.has(tower_id):
			merged.append(tower_id)
	if merged.size() > MAX_TOWERS:
		return {"valid": false, "reason": "Maximum six towers.", "towers": []}
	for tower_id: String in merged:
		if not unlocked.has(tower_id) and not mandatory_borrowed.has(tower_id):
			return {"valid": false, "reason": "Tower is not unlocked: %s" % tower_id, "towers": []}
	return {"valid": true, "reason": "", "towers": merged}

func effective_loadout(world: int, unlocked: Array[String], selected: Array[String], mandatory_borrowed: Array[String] = []) -> Array[String]:
	if not requires_selection(world):
		return unlocked.duplicate()
	var result: Dictionary = validate_selection(selected, unlocked, mandatory_borrowed)
	return Array(result["towers"]) if bool(result["valid"]) else []

