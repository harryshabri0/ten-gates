class_name SkillTree
extends RefCounted
## Data-driven seven-branch skill tree. It stores choices only; Campaign owns earned SP.

const PRESET_COUNT: int = 3

var _nodes: Dictionary = {}
var _branches: Array[Dictionary] = []
var _unlocked: Dictionary = {}
var _presets: Array[Dictionary] = [{}, {}, {}]

func _init() -> void:
	_load_definitions()

func load_data(data: Dictionary) -> void:
	_unlocked = Dictionary(data.get("unlocked", {})).duplicate(true)
	var saved_presets: Array = Array(data.get("presets", []))
	_presets = [{}, {}, {}]
	for index: int in mini(PRESET_COUNT, saved_presets.size()):
		_presets[index] = Dictionary(saved_presets[index]).duplicate(true)

func to_data() -> Dictionary:
	return {"unlocked": _unlocked.duplicate(true), "presets": _presets.duplicate(true)}

func get_branches() -> Array[Dictionary]:
	return _branches.duplicate(true)

func get_node(node_id: String) -> Dictionary:
	return Dictionary(_nodes.get(node_id, {})).duplicate(true)

func is_unlocked(node_id: String) -> bool:
	return _unlocked.has(node_id)

func spent_total() -> int:
	var total: int = 0
	for node_id: String in _unlocked.keys():
		total += int(Dictionary(_nodes.get(node_id, {})).get("cost", 0))
	return total

func spent_in_branch(branch_id: String) -> int:
	var total: int = 0
	for node_id: String in _unlocked.keys():
		var node: Dictionary = Dictionary(_nodes.get(node_id, {}))
		if String(node.get("branch", "")) == branch_id:
			total += int(node.get("cost", 0))
	return total

func can_unlock(node_id: String, available_sp: int, completed_world: int) -> Dictionary:
	var node: Dictionary = Dictionary(_nodes.get(node_id, {}))
	if node.is_empty():
		return {"valid": false, "reason": "Unknown skill node."}
	if is_unlocked(node_id):
		return {"valid": false, "reason": "Node already unlocked."}
	if available_sp < int(node["cost"]):
		return {"valid": false, "reason": "Not enough Skill Points."}
	var tier: int = int(node["tier"])
	var branch: String = String(node["branch"])
	if tier == 2 and (completed_world < 3 or spent_in_branch(branch) < 9):
		return {"valid": false, "reason": "Tier II requires World 3 complete and 9 SP in this branch."}
	if tier == 3 and (completed_world < 6 or spent_in_branch(branch) < 24):
		return {"valid": false, "reason": "Tier III requires World 6 complete and 24 SP in this branch."}
	if tier == 3 and _has_other_keystone(branch):
		return {"valid": false, "reason": "Only one keystone may be chosen in this branch."}
	return {"valid": true, "reason": ""}

func unlock(node_id: String, available_sp: int, completed_world: int) -> Dictionary:
	var check: Dictionary = can_unlock(node_id, available_sp, completed_world)
	if not bool(check["valid"]):
		return check
	_unlocked[node_id] = true
	return {"valid": true, "reason": "", "cost": int(Dictionary(_nodes[node_id])["cost"])}

func respec() -> void:
	_unlocked.clear()

func save_preset(index: int) -> bool:
	if index < 0 or index >= PRESET_COUNT:
		return false
	_presets[index] = _unlocked.duplicate(true)
	return true

func apply_preset(index: int, available_sp: int, completed_world: int) -> Dictionary:
	if index < 0 or index >= PRESET_COUNT:
		return {"valid": false, "reason": "Invalid preset."}
	var candidate: Dictionary = Dictionary(_presets[index])
	var prior: Dictionary = _unlocked.duplicate(true)
	var previously_spent: int = spent_total()
	_unlocked.clear()
	var remaining: int = available_sp + previously_spent
	for node_id: String in candidate.keys():
		var result: Dictionary = unlock(node_id, remaining, completed_world)
		if not bool(result["valid"]):
			_unlocked = prior
			return result
		remaining -= int(result["cost"])
	return {"valid": true, "reason": ""}

func build_modifier_stack() -> StatModifierStack:
	var stack: StatModifierStack = StatModifierStack.new()
	for node_id: String in _unlocked.keys():
		var node: Dictionary = Dictionary(_nodes.get(node_id, {}))
		for modifier: Dictionary in Array(node.get("modifiers", [])):
			var stat: String = String(modifier["stat"])
			if String(modifier["op"]) == "percent":
				stack.add_percent(stat, node_id, float(modifier["value"]))
			else:
				stack.add_flat(stat, node_id, float(modifier["value"]))
	return stack

func preview_node(node_id: String) -> Dictionary:
	var node: Dictionary = get_node(node_id)
	return {"name": node.get("name", ""), "description": node.get("description", ""), "cost": node.get("cost", 0), "tier": node.get("tier", 0), "unlocked": is_unlocked(node_id)}

func _has_other_keystone(branch_id: String) -> bool:
	for node_id: String in _unlocked.keys():
		var node: Dictionary = Dictionary(_nodes.get(node_id, {}))
		if String(node.get("branch", "")) == branch_id and int(node.get("tier", 0)) == 3:
			return true
	return false

func _load_definitions() -> void:
	var file: FileAccess = FileAccess.open("res://data/skilltree.json", FileAccess.READ)
	if file == null:
		push_error("Could not load skill tree data.")
		return
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Invalid skill tree data.")
		return
	for source_branch: Dictionary in Array(Dictionary(json.data).get("branches", [])):
		var branch: Dictionary = source_branch.duplicate(true)
		var branch_id: String = String(branch["id"])
		for source_node: Dictionary in Array(branch.get("nodes", [])):
			var node: Dictionary = source_node.duplicate(true)
			node["branch"] = branch_id
			_nodes[String(node["id"])] = node
		_branches.append(branch)
