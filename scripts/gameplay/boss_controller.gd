class_name BossController
extends Node2D
## Phase controller layered over the pooled EnemyManager boss entry.

signal phase_changed(phase_number: int, boss_name: String)
signal telegraph_started(position: Vector2, radius: float, duration: float, label: String)
signal encounter_finished(boss_id: String)

var _enemy_manager: PrototypeEnemyManager
var _definition: Dictionary = {}
var _boss_index: int = -1
var _pending_boss_id: String = ""
var _current_phase: int = -1
var _hard_mode: bool = false
var _ability_timers: Dictionary = {}
var _telegraphs: Array[Dictionary] = []
var _sub_targets: Dictionary = {}
var _map_objects: Dictionary = {}
var _burrow_remaining: float = 0.0
var _burrow_ability: Dictionary = {}
var _shield_enemy_id: String = ""
var _grounded_remaining: float = 0.0

func bind_enemy_manager(enemy_manager: PrototypeEnemyManager) -> void:
	_enemy_manager = enemy_manager

func start_encounter(boss_id: String, hard_mode: bool = false) -> void:
	var path: String = "res://data/bosses/%s.json" % boss_id
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing boss data: %s" % boss_id)
		return
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Invalid boss JSON: %s" % boss_id)
		return
	_definition = Dictionary(json.data)
	_hard_mode = hard_mode
	_pending_boss_id = boss_id
	_boss_index = -1
	_current_phase = -1
	_ability_timers.clear()
	_telegraphs.clear()
	_sub_targets.clear()
	_map_objects.clear()
	_burrow_remaining = 0.0
	_burrow_ability.clear()
	_shield_enemy_id = String(_definition.get("shield_enemy", ""))
	_grounded_remaining = 0.0
	for target: Dictionary in Array(_definition.get("sub_targets", [])):
		_sub_targets[String(target["id"])] = float(target["hp"])
	for map_object: Dictionary in Array(_definition.get("map_objects", [])):
		_map_objects[String(map_object["id"])] = float(map_object["hp"])
	_enemy_manager.queue_spawn(boss_id, 1, 0.03)

func tick(delta: float) -> void:
	if _enemy_manager == null:
		return
	if not _pending_boss_id.is_empty() and _boss_index < 0:
		_boss_index = _enemy_manager.find_active_enemy_index(_pending_boss_id)
		if _boss_index >= 0:
			_enemy_manager.set_enemy_flags(_boss_index, false, true)
			if not _shield_enemy_id.is_empty():
				_enemy_manager.set_targetable(_boss_index, false)
				_enemy_manager.spawn_children(_boss_index, _shield_enemy_id, int(_definition.get("shield_count", 3)), 1.0)
			_enter_phase(0)
	if _boss_index < 0:
		_process_telegraphs(delta)
		return
	_process_burrow(delta)
	_process_grounded_dive(delta)
	if _burrow_remaining > 0.0:
		_process_telegraphs(delta)
		return
	if not _enemy_manager.is_enemy_active(_boss_index):
		encounter_finished.emit(String(_definition.get("id", "")))
		_boss_index = -1
		_pending_boss_id = ""
		return
	if not _shield_enemy_id.is_empty() and _enemy_manager.count_active_enemy_id(_shield_enemy_id) <= 0:
		_enemy_manager.set_targetable(_boss_index, true)
		_shield_enemy_id = ""
	_update_phase()
	_process_phase_abilities(delta)
	_process_telegraphs(delta)
	queue_redraw()

func force_phase(phase_number: int) -> void:
	if _boss_index < 0:
		return
	_enter_phase(clampi(phase_number - 1, 0, Array(_definition.get("phases", [])).size() - 1))

func damage_sub_target(target_id: String, damage: float) -> void:
	if _sub_targets.has(target_id):
		_sub_targets[target_id] = maxf(0.0, float(_sub_targets[target_id]) - damage)

func damage_map_object(object_id: String, damage: float) -> void:
	if _map_objects.has(object_id):
		_map_objects[object_id] = maxf(0.0, float(_map_objects[object_id]) - damage)

func _update_phase() -> void:
	var phases: Array = Array(_definition.get("phases", []))
	var hp_ratio: float = _enemy_manager.get_hp_ratio(_boss_index)
	for index: int in range(phases.size() - 1, -1, -1):
		var phase: Dictionary = phases[index]
		if hp_ratio <= float(phase.get("threshold", 1.0)) and index > _current_phase:
			_enter_phase(index)
			return

func _enter_phase(index: int) -> void:
	var phases: Array = Array(_definition.get("phases", []))
	if index < 0 or index >= phases.size():
		return
	var phase: Dictionary = phases[index]
	if bool(phase.get("hard_only", false)) and not _hard_mode:
		return
	_current_phase = index
	_ability_timers.clear()
	phase_changed.emit(index + 1, String(_definition.get("name", "Boss")))

func _process_phase_abilities(delta: float) -> void:
	var phases: Array = Array(_definition.get("phases", []))
	if _current_phase < 0 or _current_phase >= phases.size():
		return
	for ability: Dictionary in Array(Dictionary(phases[_current_phase]).get("abilities", [])):
		var ability_id: String = String(ability["id"])
		if ability_id == "regen_if_idle":
			if _enemy_manager.get_time_since_hit(_boss_index) >= float(ability.get("idle_seconds", 3.0)):
				_enemy_manager.heal_enemy(_boss_index, _enemy_manager.get_max_hp(_boss_index) * float(ability.get("percent_per_second", 0.02)) * delta)
			continue
		if ability_id == "hard_enrage":
			if not bool(_ability_timers.get("hard_enrage_applied", false)):
				_enemy_manager.multiply_enemy_speed(_boss_index, float(ability.get("speed_multiplier", 1.25)))
				_ability_timers["hard_enrage_applied"] = true
			continue
		if ability_id == "shed_plating":
			if not bool(_ability_timers.get("plating_%d" % _current_phase, false)):
				_enemy_manager.add_enemy_armor(_boss_index, -float(ability.get("armor_loss", 30.0)))
				_start_telegraph(_enemy_manager.get_enemy_position(_boss_index), float(ability.get("radius", 160.0)), float(ability.get("telegraph_seconds", 1.0)), "Armor Plate Lava Burst", "damage_weaken", ability)
				_ability_timers["plating_%d" % _current_phase] = true
			continue
		if ability_id == "enrage":
			if not bool(_ability_timers.get("enrage_applied", false)):
				_enemy_manager.multiply_enemy_speed(_boss_index, float(ability.get("speed_multiplier", 1.40)))
				_enemy_manager.grant_status_immunity(_boss_index, "burn")
				_ability_timers["enrage_applied"] = true
			continue
		if ability_id == "overclock":
			if not bool(_ability_timers.get("overclock_applied", false)):
				_enemy_manager.apply_speed_buff_to_nearby(_boss_index, float(ability.get("speed_multiplier", 2.0)), float(ability.get("duration", 12.0)))
				_ability_timers["overclock_applied"] = true
			continue
		var elapsed: float = float(_ability_timers.get(ability_id, 0.0)) + delta
		var interval: float = float(ability.get("interval", 8.0))
		if elapsed < interval:
			_ability_timers[ability_id] = elapsed
			continue
		_ability_timers[ability_id] = 0.0
		_trigger_ability(ability)

func _trigger_ability(ability: Dictionary) -> void:
	var ability_id: String = String(ability["id"])
	var position: Vector2 = _enemy_manager.get_enemy_position(_boss_index)
	match ability_id:
		"charge":
			_enemy_manager.advance_progress(_boss_index, 0.04 * float(ability.get("speed_multiplier", 2.0)))
			_enemy_manager.spawn_children(_boss_index, String(ability.get("enemy", "grunt")), int(ability.get("count", 0)), 1.0)
		"rock_throw":
			_start_telegraph(position, float(ability.get("radius", 95.0)), float(ability.get("telegraph_seconds", 1.5)), "Rock Throw", "disable", ability)
		"roar":
			_start_telegraph(position, 150.0, float(ability.get("telegraph_seconds", 1.2)), "Roar", "summon", ability)
		"summon":
			_enemy_manager.spawn_children(_boss_index, String(ability.get("enemy", "scarab")), int(ability.get("count", 1)), 1.0)
		"dive":
			_burrow_remaining = float(ability.get("duration", 4.0))
			_burrow_ability = ability.duplicate(true)
			_enemy_manager.set_targetable(_boss_index, false)
			_start_telegraph(position, float(ability.get("radius", 150.0)), 0.8, "Khepri dives", "none", ability)
		"sandstorm":
			_start_telegraph(position, float(ability.get("radius", 220.0)), float(ability.get("duration", 6.0)), "Personal Sandstorm", "weaken", ability)
		"split_worms":
			_enemy_manager.spawn_children(_boss_index, String(ability.get("enemy", "khepri_worm")), int(ability.get("count", 3)), 0.35)
		"poison_cloud", "hydra_poison_cloud":
			_start_telegraph(position, float(ability.get("radius", 180.0)), float(ability.get("telegraph_seconds", 1.0)), "Poison Cloud", "weaken", ability)
		"frostbite":
			_enemy_manager.request_tower_weaken(position, float(ability.get("attack_speed_multiplier", 0.70)), float(ability.get("duration", 4.0)))
		"avalanche":
			_start_telegraph(position, float(ability.get("radius", 170.0)), float(ability.get("telegraph_seconds", 1.2)), "Avalanche", "disable", ability)
		"resurrect":
			_enemy_manager.revive_nearby_dead(_boss_index, int(ability.get("count", 5)), float(ability.get("hp_ratio", 0.30)))
		"death_nova":
			_start_telegraph(position, float(ability.get("radius", 210.0)), float(ability.get("telegraph_seconds", 1.2)), "Death Nova", "disable_radius", ability)
		"lava_rain":
			_start_telegraph(position, float(ability.get("radius", 220.0)), float(ability.get("telegraph_seconds", 1.2)), "Lava Rain", "damage_weaken", ability)
		"emp_pulse":
			_start_telegraph(position, float(ability.get("radius", 320.0)), float(ability.get("telegraph_seconds", 2.0)), "EMP Pulse", "disable_radius", ability)
		"siege_shot":
			_enemy_manager.request_farthest_tower_disable(position, float(ability.get("tower_disable_seconds", 5.0)))
		"repair_bots":
			_enemy_manager.spawn_children(_boss_index, String(ability.get("enemy", "repair_bot")), int(ability.get("count", 2)), 1.0)
		"lightning_strike":
			_enemy_manager.request_random_tower_disable(int(ability.get("count", 3)), float(ability.get("tower_disable_seconds", 4.0)))
		"gust":
			_enemy_manager.apply_speed_buff_to_nearby(_boss_index, float(ability.get("speed_multiplier", 1.30)), float(ability.get("duration", 5.0)), 99999.0)
		"dive_bomb":
			_grounded_remaining = float(ability.get("duration", 6.0))
			_enemy_manager.set_enemy_flying(_boss_index, false)
			_enemy_manager.request_random_tower_disable(1, float(ability.get("slot_disable_seconds", 20.0)))
			_start_telegraph(position, float(ability.get("radius", 180.0)), float(ability.get("telegraph_seconds", 1.0)), "Dive Bomb", "none", ability)
		"boss_teleport":
			_enemy_manager.advance_progress(_boss_index, float(ability.get("path_ratio", 0.10)))
		"gravity_well":
			_start_telegraph(position, float(ability.get("radius", 220.0)), float(ability.get("telegraph_seconds", 1.0)), "Gravity Well", "weaken", ability)

func _process_burrow(delta: float) -> void:
	if _burrow_remaining <= 0.0:
		return
	_burrow_remaining = maxf(0.0, _burrow_remaining - delta)
	if _burrow_remaining > 0.0:
		return
	_enemy_manager.advance_progress(_boss_index, float(_burrow_ability.get("jump_path_ratio", 0.15)))
	_enemy_manager.set_targetable(_boss_index, true)
	_enemy_manager.request_tower_disable(_enemy_manager.get_enemy_position(_boss_index), float(_burrow_ability.get("stun_duration", 1.0)))

func _process_grounded_dive(delta: float) -> void:
	if _grounded_remaining <= 0.0:
		return
	_grounded_remaining = maxf(0.0, _grounded_remaining - delta)
	if _grounded_remaining <= 0.0 and _boss_index >= 0:
		_enemy_manager.set_enemy_flying(_boss_index, true)

func _start_telegraph(position: Vector2, radius: float, duration: float, label: String, action: String, ability: Dictionary) -> void:
	_telegraphs.append({"position": position, "radius": radius, "remaining": duration, "label": label, "action": action, "ability": ability})
	telegraph_started.emit(position, radius, duration, label)

func _process_telegraphs(delta: float) -> void:
	for index: int in range(_telegraphs.size() - 1, -1, -1):
		var telegraph: Dictionary = _telegraphs[index]
		telegraph["remaining"] = float(telegraph["remaining"]) - delta
		if float(telegraph["remaining"]) > 0.0:
			_telegraphs[index] = telegraph
			continue
		var ability: Dictionary = telegraph["ability"]
		if String(telegraph["action"]) == "disable":
			_enemy_manager.request_tower_disable(telegraph["position"], float(ability.get("tower_disable_seconds", 5.0)))
		elif String(telegraph["action"]) == "disable_radius":
			_enemy_manager.request_tower_disable_radius(telegraph["position"], float(telegraph["radius"]), float(ability.get("tower_disable_seconds", 3.0)))
		elif String(telegraph["action"]) == "summon":
			_enemy_manager.spawn_children(_boss_index, String(ability.get("enemy", "grunt")), int(ability.get("count", 1)), 1.0)
			_enemy_manager.apply_speed_buff_to_nearby(_boss_index, float(ability.get("speed_multiplier", 1.20)), 5.0)
		elif String(telegraph["action"]) == "weaken":
			_enemy_manager.request_tower_weaken(telegraph["position"], float(ability.get("range_multiplier", 0.70)), float(ability.get("duration", 6.0)))
		elif String(telegraph["action"]) == "damage_weaken":
			_enemy_manager.request_tower_damage_weaken(telegraph["position"], float(ability.get("damage_multiplier", 0.50)), float(ability.get("duration", 8.0)))
		_telegraphs.remove_at(index)

func _draw() -> void:
	for telegraph: Dictionary in _telegraphs:
		draw_arc(telegraph["position"], float(telegraph["radius"]), 0.0, TAU, 40, Color(1.0, 0.12, 0.12, 0.85), 4.0)

