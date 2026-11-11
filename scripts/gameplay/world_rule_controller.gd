class_name WorldRuleController
extends Node
## Modular world rules configured entirely by the selected level's world_rule data.

signal tower_range_multiplier_changed(multiplier: float)
signal rule_message_changed(message: String)
signal path_changed(points: PackedVector2Array)
signal enemy_speed_multiplier_changed(multiplier: float)
signal enemy_regen_percent_changed(percent_per_second: float)
signal element_damage_multipliers_changed(multipliers: Dictionary)
signal eruption_started(slot_indexes: Array, duration: float)
signal air_speed_multiplier_changed(multiplier: float)

var _rule: Dictionary = {}
var _elapsed: float = 0.0
var _storm_remaining: float = 0.0
var _tower_range_multiplier: float = 1.0
var _default_path: PackedVector2Array = PackedVector2Array()
var _alternate_path: PackedVector2Array = PackedVector2Array()
var _using_alternate: bool = false
var _lever_cooldown: float = 0.0
var _cycle_elapsed: float = 0.0
var _is_night: bool = false
var _element_damage_multipliers: Dictionary = {}
var _eruption_remaining: float = 0.0
var _eruption_slots: Array[int] = []

func configure(level: Dictionary) -> void:
	_rule = Dictionary(level.get("world_rule", {}))
	_elapsed = 0.0
	_storm_remaining = 0.0
	_tower_range_multiplier = 1.0
	_using_alternate = false
	_lever_cooldown = 0.0
	_cycle_elapsed = 0.0
	_is_night = false
	_element_damage_multipliers = {}
	_eruption_remaining = 0.0
	_eruption_slots.clear()
	_alternate_path.clear()
	for raw_point: Array in Array(_rule.get("alternate_path", [])):
		if raw_point.size() == 2:
			_alternate_path.append(Vector2(float(raw_point[0]), float(raw_point[1])))
	tower_range_multiplier_changed.emit(_tower_range_multiplier)
	enemy_speed_multiplier_changed.emit(float(_rule.get("mud_speed_multiplier", 1.0)))
	air_speed_multiplier_changed.emit(get_air_speed_multiplier())
	_enemy_rule_state_changed()

func set_default_path(points: PackedVector2Array) -> void:
	_default_path = points.duplicate()

func has_bridge_lever() -> bool:
	return String(_rule.get("id", "")) in ["swamp_bridge", "clockwork_conveyor"] and _alternate_path.size() >= 2

func get_world_action_label() -> String:
	return "CONVEYOR GATE" if String(_rule.get("id", "")) == "clockwork_conveyor" else "BRIDGE LEVER"

func toggle_bridge() -> bool:
	if not has_bridge_lever() or _lever_cooldown > 0.0:
		return false
	_using_alternate = not _using_alternate
	path_changed.emit(_alternate_path if _using_alternate else _default_path)
	_lever_cooldown = float(_rule.get("lever_cooldown", 20.0))
	enemy_speed_multiplier_changed.emit(get_enemy_speed_multiplier())
	if String(_rule.get("id", "")) == "clockwork_conveyor":
		rule_message_changed.emit("Conveyor gate switched to the long slow route. Cooldown 20 seconds." if _using_alternate else "Conveyor gate switched to the short fast route. Cooldown 20 seconds.")
	else:
		rule_message_changed.emit("Bridge lever switched route. Cooldown 20 seconds.")
	return true

func get_tower_range_multiplier() -> float:
	return _tower_range_multiplier

func get_enemy_speed_multiplier() -> float:
	if String(_rule.get("id", "")) == "clockwork_conveyor":
		return float(_rule.get("long_route_speed_multiplier", 0.80)) if _using_alternate else float(_rule.get("short_route_speed_multiplier", 1.20))
	return float(_rule.get("mud_speed_multiplier", 1.0))

func get_air_speed_multiplier() -> float:
	return float(_rule.get("air_speed_multiplier", 1.0))

func get_sky_slot_offset(wave_number: int) -> Vector2:
	if String(_rule.get("id", "")) != "sky_islands":
		return Vector2.ZERO
	var offsets: Array = Array(_rule.get("sky_slot_offsets", []))
	if offsets.is_empty():
		return Vector2.ZERO
	var raw_offset: Array = Array(offsets[mini((wave_number - 1) / 3, offsets.size() - 1)])
	return Vector2(float(raw_offset[0]), float(raw_offset[1])) if raw_offset.size() == 2 else Vector2.ZERO

func get_portal_pair(wave_number: int) -> Array[float]:
	if String(_rule.get("id", "")) != "void_portals":
		return []
	var pairs: Array = Array(_rule.get("portal_pairs", []))
	if pairs.is_empty():
		return []
	var pair: Array = Array(pairs[mini(floori(float(wave_number - 1) / 3.0), pairs.size() - 1)])
	return [float(pair[0]), float(pair[1])] if pair.size() == 2 else []

func get_enemy_regen_percent() -> float:
	return float(_rule.get("night_regen_percent", 0.01)) if _is_night else 0.0

func get_element_damage_multipliers() -> Dictionary:
	return _element_damage_multipliers.duplicate()

func is_night() -> bool:
	return _is_night

func is_eruption_active() -> bool:
	return _eruption_remaining > 0.0

func get_eruption_slots() -> Array[int]:
	return _eruption_slots.duplicate()

func tick(delta: float) -> void:
	_lever_cooldown = maxf(0.0, _lever_cooldown - delta)
	if String(_rule.get("id", "")) == "graveyard_day_night":
		_cycle_elapsed += delta
		if _cycle_elapsed >= float(_rule.get("cycle_seconds", 20.0)):
			_cycle_elapsed = 0.0
			_is_night = not _is_night
			_enemy_rule_state_changed()
			rule_message_changed.emit("Nightfall: enemies regenerate 1% HP/s." if _is_night else "Daylight: fire and holy damage +20%.")
		return
	if String(_rule.get("id", "")) == "volcano_eruption":
		_process_volcano_eruption(delta)
		return
	if String(_rule.get("id", "")) != "desert_sandstorm":
		return
	if _storm_remaining > 0.0:
		_storm_remaining = maxf(0.0, _storm_remaining - delta)
		if _storm_remaining <= 0.0:
			_tower_range_multiplier = 1.0
			tower_range_multiplier_changed.emit(_tower_range_multiplier)
			rule_message_changed.emit("The sandstorm has passed.")
		return
	_elapsed += delta
	if _elapsed < float(_rule.get("interval", 30.0)):
		return
	_elapsed = 0.0
	_storm_remaining = float(_rule.get("duration", 8.0))
	_tower_range_multiplier = float(_rule.get("range_multiplier", 0.75))
	tower_range_multiplier_changed.emit(_tower_range_multiplier)
	rule_message_changed.emit("Sandstorm: tower range -25% for 8 seconds.")

func _enemy_rule_state_changed() -> void:
	if String(_rule.get("id", "")) == "graveyard_day_night" and not _is_night:
		var multiplier: float = float(_rule.get("day_damage_multiplier", 1.20))
		for element: String in Array(_rule.get("day_elements", ["fire", "holy"])):
			_element_damage_multipliers[element] = multiplier
	enemy_regen_percent_changed.emit(get_enemy_regen_percent())
	element_damage_multipliers_changed.emit(_element_damage_multipliers.duplicate())

func _process_volcano_eruption(delta: float) -> void:
	if _eruption_remaining > 0.0:
		_eruption_remaining = maxf(0.0, _eruption_remaining - delta)
		if _eruption_remaining <= 0.0:
			_eruption_slots.clear()
			if _alternate_path.size() >= 2:
				path_changed.emit(_default_path)
			rule_message_changed.emit("Lava has cooled; the main path is open.")
		return
	_elapsed += delta
	if _elapsed < float(_rule.get("interval", 45.0)):
		return
	_elapsed = 0.0
	_eruption_remaining = float(_rule.get("duration", 6.0))
	_eruption_slots.clear()
	for raw_slot: Variant in Array(_rule.get("lava_slots", [])):
		_eruption_slots.append(int(raw_slot))
	if _alternate_path.size() >= 2:
		path_changed.emit(_alternate_path)
	eruption_started.emit(_eruption_slots.duplicate(), _eruption_remaining)
	rule_message_changed.emit("Eruption! Marked slots disabled; lava reroutes the path for 6 seconds.")
