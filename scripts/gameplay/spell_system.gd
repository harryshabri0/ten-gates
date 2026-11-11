class_name SpellSystem
extends Node
## Central spell cooldowns and temporary effects. Spell values live in data/spells.json.

signal targeting_requested(spell_id: String)
signal cooldown_changed(spell_id: String, remaining: float)
signal tower_speed_multiplier_changed(multiplier: float)
signal gold_rush_changed(multiplier: float)
signal barrier_changed(charges: int)

var _enemy_manager: PrototypeEnemyManager
var _status_system: PrototypeStatusSystem
var _definitions: Dictionary = {}
var _equipped: Array[String] = ["meteor_shower", "overcharge"]
var _third_slot_unlocked: bool = false
var _cooldowns: Dictionary = {}
var _pending_target_spell: String = ""
var _difficulty_multiplier: float = 1.0
var _overcharge_remaining: float = 0.0
var _gold_rush_remaining: float = 0.0
var _barrier_charges: int = 0
var _reinforcements: Array[Dictionary] = []
var _skill_modifiers: StatModifierStack

func _ready() -> void:
	_load_definitions()

func bind(enemy_manager: PrototypeEnemyManager, status_system: PrototypeStatusSystem) -> void:
	_enemy_manager = enemy_manager
	_status_system = status_system

func set_difficulty(difficulty: Dictionary) -> void:
	_difficulty_multiplier = float(difficulty.get("skill_cooldown_multiplier", 1.0))

func set_skill_modifiers(modifiers: StatModifierStack) -> void:
	_skill_modifiers = modifiers
	if _skill_modifiers != null and _skill_modifiers.flat("third_spell_slot") > 0.0:
		unlock_third_slot()

func equip_spells(spell_ids: Array[String]) -> bool:
	var max_slots: int = get_max_slots()
	if spell_ids.size() > max_slots:
		return false
	for spell_id: String in spell_ids:
		if not _definitions.has(spell_id):
			return false
	_equipped = spell_ids.duplicate()
	return true

func unlock_third_slot() -> void:
	_third_slot_unlocked = true

func has_third_slot() -> bool:
	return _third_slot_unlocked

func get_max_slots() -> int:
	return 3 if _third_slot_unlocked else 2

func get_equipped() -> Array[String]:
	return _equipped.duplicate()

func request_cast(spell_id: String) -> bool:
	if not _equipped.has(spell_id) or _remaining(spell_id) > 0.0:
		return false
	var definition: Dictionary = _definitions[spell_id]
	if String(definition["targeting"]) == "point":
		_pending_target_spell = spell_id
		targeting_requested.emit(spell_id)
		return true
	_cast(spell_id, Vector2.ZERO)
	return true

func confirm_target(position: Vector2) -> bool:
	if _pending_target_spell.is_empty():
		return false
	var spell_id: String = _pending_target_spell
	_pending_target_spell = ""
	_cast(spell_id, position)
	return true

func tick(delta: float) -> void:
	for spell_id: String in _cooldowns.keys():
		_cooldowns[spell_id] = maxf(0.0, float(_cooldowns[spell_id]) - delta)
		cooldown_changed.emit(spell_id, float(_cooldowns[spell_id]))
	_overcharge_remaining = maxf(0.0, _overcharge_remaining - delta)
	_gold_rush_remaining = maxf(0.0, _gold_rush_remaining - delta)
	var overcharge: Dictionary = Dictionary(_definitions.get("overcharge", {}))
	var gold_rush: Dictionary = Dictionary(_definitions.get("gold_rush", {}))
	tower_speed_multiplier_changed.emit(float(overcharge.get("attack_speed_multiplier", 1.0)) if _overcharge_remaining > 0.0 else 1.0)
	gold_rush_changed.emit(float(gold_rush.get("bounty_multiplier", 1.0)) if _gold_rush_remaining > 0.0 else 1.0)
	for index: int in range(_reinforcements.size() - 1, -1, -1):
		var reinforcement: Dictionary = _reinforcements[index]
		reinforcement["remaining"] = float(reinforcement["remaining"]) - delta
		reinforcement["attack_elapsed"] = float(reinforcement["attack_elapsed"]) + delta
		if float(reinforcement["attack_elapsed"]) >= float(reinforcement["interval"]):
			reinforcement["attack_elapsed"] = 0.0
			for target: int in _enemy_manager.get_targets_in_radius(reinforcement["position"], float(reinforcement["radius"]), 3):
				_enemy_manager.damage_enemy(target, float(reinforcement["damage"]), "physical")
				_enemy_manager.apply_block(target, 0.45)
		if float(reinforcement["remaining"]) <= 0.0:
			_reinforcements.remove_at(index)
		else:
			_reinforcements[index] = reinforcement

func consume_barrier() -> bool:
	if _barrier_charges <= 0:
		return false
	_barrier_charges -= 1
	barrier_changed.emit(_barrier_charges)
	return true

func _cast(spell_id: String, position: Vector2) -> void:
	var definition: Dictionary = _definitions[spell_id]
	_cooldowns[spell_id] = float(definition["cooldown"]) * _difficulty_multiplier * _modifier("spell_cooldown")
	match spell_id:
		"meteor_shower":
			_enemy_manager.damage_targets_around(position, float(definition["radius"]), float(definition["damage"]) * _modifier("spell_power"), PrototypeEnemyManager.MAX_ENEMIES)
		"time_freeze":
			for target: int in _enemy_manager.get_targets_in_radius(Vector2(960, 540), 5000.0, PrototypeEnemyManager.MAX_ENEMIES):
				var duration: float = (float(definition["boss_duration"]) if _enemy_manager.is_elite_or_boss(target) else float(definition["duration"])) * _modifier("spell_power")
				_status_system.apply_status(target, "freeze", duration)
		"reinforcements":
			_reinforcements.append({"position": position, "remaining": float(definition["duration"]) * _modifier("spell_power"), "attack_elapsed": 0.0, "radius": float(definition["radius"]), "damage": float(definition["damage"]) * _modifier("reinforcement_strength"), "interval": float(definition["interval"])})
		"overcharge":
			_overcharge_remaining = float(definition["duration"])
		"gold_rush":
			_gold_rush_remaining = float(definition["duration"])
		"holy_barrier":
			_barrier_charges += int(definition["leaks_prevented"])
			barrier_changed.emit(_barrier_charges)

func _remaining(spell_id: String) -> float:
	return float(_cooldowns.get(spell_id, 0.0))

func _modifier(stat: String) -> float:
	return _skill_modifiers.multiplier(stat) if _skill_modifiers != null else 1.0

func _load_definitions() -> void:
	var file: FileAccess = FileAccess.open("res://data/spells.json", FileAccess.READ)
	if file == null:
		push_error("Could not load spell data.")
		return
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_definitions = Dictionary(json.data)

