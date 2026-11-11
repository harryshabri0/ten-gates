class_name PrototypeStatusSystem
extends Node
## Central 10 Hz status processor. State is preallocated per enemy pool slot.

const STATUS_TICK_SECONDS: float = 0.1
const MAX_ENEMIES: int = PrototypeEnemyManager.MAX_ENEMIES
const CC_RESET_SECONDS: float = 8.0
const REACTION_COOLDOWN_SECONDS: float = 3.0

var _enemy_manager: PrototypeEnemyManager
var _states: Array[Dictionary] = []
var _accumulator: float = 0.0
var last_tick_ms: float = 0.0
var active_status_count: int = 0

func _ready() -> void:
	add_to_group("status_system")
	for _index: int in MAX_ENEMIES:
		_states.append(_new_state())

func bind_enemy_manager(enemy_manager: PrototypeEnemyManager) -> void:
	_enemy_manager = enemy_manager

func tick(delta: float) -> void:
	if _enemy_manager == null:
		return
	_accumulator += delta
	while _accumulator >= STATUS_TICK_SECONDS:
		_accumulator -= STATUS_TICK_SECONDS
		var start_us: int = Time.get_ticks_usec()
		_process_status_tick()
		last_tick_ms = float(Time.get_ticks_usec() - start_us) / 1000.0

func apply_status(enemy_index: int, status_id: String, duration: float, potency: float = 1.0) -> void:
	if not _is_valid_enemy(enemy_index):
		return
	if _enemy_manager.has_status_immunity(enemy_index, status_id):
		return
	var state: Dictionary = _states[enemy_index]
	var applied_duration: float = duration
	if status_id == "freeze" or status_id == "stun" or status_id == "root":
		if _enemy_manager.is_elite_or_boss(enemy_index):
			applied_duration *= pow(0.5, float(int(state["cc_count"])))
			state["cc_count"] = int(state["cc_count"]) + 1
		state["cc_reset"] = CC_RESET_SECONDS
	match status_id:
		"burn":
			state["burn_duration"] = maxf(float(state["burn_duration"]), applied_duration)
			state["burn_power"] = maxf(float(state["burn_power"]), potency)
		"poison":
			state["poison_duration"] = maxf(float(state["poison_duration"]), applied_duration)
			state["poison_stacks"] = mini(5, int(state["poison_stacks"]) + maxi(1, roundi(potency)))
		"slow":
			state["slow_duration"] = maxf(float(state["slow_duration"]), applied_duration)
			state["slow_multiplier"] = minf(float(state["slow_multiplier"]), clampf(potency, 0.1, 0.95))
		"freeze":
			state["freeze_duration"] = maxf(float(state["freeze_duration"]), applied_duration)
		"stun":
			state["stun_duration"] = maxf(float(state["stun_duration"]), applied_duration)
		"mark":
			state["mark_duration"] = maxf(float(state["mark_duration"]), applied_duration)
			state["mark_multiplier"] = maxf(float(state["mark_multiplier"]), potency)
		"armor_break":
			state["armor_break_duration"] = maxf(float(state["armor_break_duration"]), applied_duration)
		"weaken":
			state["weaken_duration"] = maxf(float(state["weaken_duration"]), applied_duration)
			state["weaken_multiplier"] = maxf(float(state["weaken_multiplier"]), potency)
		"root":
			state["root_duration"] = maxf(float(state["root_duration"]), applied_duration)
		_:
			push_warning("Unknown status: %s" % status_id)
			return
	_resolve_reactions(enemy_index)
	_refresh_active_count()

func modify_damage(enemy_index: int, damage: float, damage_type: String) -> float:
	if enemy_index < 0 or enemy_index >= _states.size():
		return damage
	var state: Dictionary = _states[enemy_index]
	var result: float = damage
	if float(state["mark_duration"]) > 0.0:
		result *= float(state["mark_multiplier"])
	if damage_type == "physical" and float(state["armor_break_duration"]) > 0.0:
		result *= 1.25
	return result

func on_heavy_hit(enemy_index: int, damage: float) -> void:
	if not _is_valid_enemy(enemy_index):
		return
	var state: Dictionary = _states[enemy_index]
	if float(state["freeze_duration"]) <= 0.0 or not _reaction_ready(state, "shatter"):
		return
	state["freeze_duration"] = 0.0
	_set_reaction_cooldown(state, "shatter")
	_enemy_manager.damage_enemy(enemy_index, damage * 0.80, "physical")

func get_status_summary(enemy_index: int) -> String:
	if enemy_index < 0 or enemy_index >= _states.size():
		return ""
	var state: Dictionary = _states[enemy_index]
	var names: PackedStringArray = PackedStringArray()
	for status_id: String in ["burn", "poison", "slow", "freeze", "stun", "mark", "armor_break", "weaken", "root"]:
		if _duration(state, status_id) > 0.0:
			names.append(status_id)
	return ", ".join(names)

func _process_status_tick() -> void:
	active_status_count = 0
	for index: int in _states.size():
		if not _enemy_manager.is_enemy_active(index):
			_states[index] = _new_state()
			continue
		var state: Dictionary = _states[index]
		_decrement_state(state)
		if float(state["burn_duration"]) > 0.0:
			_enemy_manager.damage_enemy(index, _enemy_manager.get_max_hp(index) * 0.012 * float(state["burn_power"]), "magic")
		if float(state["poison_duration"]) > 0.0:
			_enemy_manager.damage_enemy(index, _enemy_manager.get_max_hp(index) * 0.007 * float(state["poison_stacks"]), "magic")
		if float(state["slow_duration"]) > 0.0:
			_enemy_manager.apply_slow(index, STATUS_TICK_SECONDS + 0.02, float(state["slow_multiplier"]))
		if float(state["freeze_duration"]) > 0.0 or float(state["stun_duration"]) > 0.0 or float(state["root_duration"]) > 0.0:
			_enemy_manager.apply_stun(index, STATUS_TICK_SECONDS + 0.02)
		active_status_count += _count_active(state)

func _resolve_reactions(enemy_index: int) -> void:
	var state: Dictionary = _states[enemy_index]
	if float(state["burn_duration"]) > 0.0 and int(state["poison_stacks"]) > 0 and _reaction_ready(state, "toxic_blast"):
		_set_reaction_cooldown(state, "toxic_blast")
		_enemy_manager.damage_targets_around(_enemy_manager.get_enemy_position(enemy_index), 55.0, _enemy_manager.get_max_hp(enemy_index) * 0.12, 4)
	if float(state["stun_duration"]) > 0.0 and float(state["mark_duration"]) > 0.0 and _reaction_ready(state, "overload"):
		_set_reaction_cooldown(state, "overload")
		_enemy_manager.damage_targets_around(_enemy_manager.get_enemy_position(enemy_index), 110.0, _enemy_manager.get_max_hp(enemy_index) * 0.10, 3)
	if float(state["poison_duration"]) > 0.0 and float(state["armor_break_duration"]) > 0.0 and _reaction_ready(state, "corrode"):
		_set_reaction_cooldown(state, "corrode")
	if float(state["burn_duration"]) > 0.0 and (float(state["slow_duration"]) > 0.0 or float(state["freeze_duration"]) > 0.0) and _reaction_ready(state, "thermal_shock"):
		_set_reaction_cooldown(state, "thermal_shock")
		var thermal_multiplier: float = 0.015 if _enemy_manager.is_elite_or_boss(enemy_index) else 0.05
		_enemy_manager.damage_enemy(enemy_index, _enemy_manager.get_max_hp(enemy_index) * thermal_multiplier, "magic")

func _decrement_state(state: Dictionary) -> void:
	for key: String in ["burn_duration", "poison_duration", "slow_duration", "freeze_duration", "stun_duration", "mark_duration", "armor_break_duration", "weaken_duration", "root_duration", "cc_reset"]:
		state[key] = maxf(0.0, float(state[key]) - STATUS_TICK_SECONDS)
	for key: String in ["shatter_cd", "toxic_blast_cd", "overload_cd", "corrode_cd", "thermal_shock_cd"]:
		state[key] = maxf(0.0, float(state[key]) - STATUS_TICK_SECONDS)
	if float(state["cc_reset"]) <= 0.0:
		state["cc_count"] = 0
	if float(state["slow_duration"]) <= 0.0:
		state["slow_multiplier"] = 1.0
	if float(state["mark_duration"]) <= 0.0:
		state["mark_multiplier"] = 1.0
	if float(state["poison_duration"]) <= 0.0:
		state["poison_stacks"] = 0

func _new_state() -> Dictionary:
	return {
		"burn_duration": 0.0, "burn_power": 1.0, "poison_duration": 0.0, "poison_stacks": 0,
		"slow_duration": 0.0, "slow_multiplier": 1.0, "freeze_duration": 0.0, "stun_duration": 0.0,
		"mark_duration": 0.0, "mark_multiplier": 1.0, "armor_break_duration": 0.0,
		"weaken_duration": 0.0, "weaken_multiplier": 1.0, "root_duration": 0.0,
		"cc_count": 0, "cc_reset": 0.0, "shatter_cd": 0.0, "toxic_blast_cd": 0.0,
		"overload_cd": 0.0, "corrode_cd": 0.0, "thermal_shock_cd": 0.0
	}

func _duration(state: Dictionary, status_id: String) -> float:
	if status_id == "poison":
		return float(state["poison_duration"])
	return float(state.get("%s_duration" % status_id, 0.0))

func _reaction_ready(state: Dictionary, reaction_id: String) -> bool:
	return float(state["%s_cd" % reaction_id]) <= 0.0

func _set_reaction_cooldown(state: Dictionary, reaction_id: String) -> void:
	state["%s_cd" % reaction_id] = REACTION_COOLDOWN_SECONDS

func _count_active(state: Dictionary) -> int:
	var count: int = 0
	for status_id: String in ["burn", "poison", "slow", "freeze", "stun", "mark", "armor_break", "weaken", "root"]:
		if _duration(state, status_id) > 0.0:
			count += 1
	return count

func _refresh_active_count() -> void:
	active_status_count = 0
	for state: Dictionary in _states:
		active_status_count += _count_active(state)

func _is_valid_enemy(index: int) -> bool:
	return _enemy_manager != null and _enemy_manager.is_enemy_active(index)

