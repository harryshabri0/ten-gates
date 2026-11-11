class_name PrototypeEnemyManager
extends Node2D
## Central, pooled enemy simulation. There is no per-enemy _process.

signal enemy_defeated(bounty: int)
signal enemy_leaked(weight: int)
signal enemy_spawned(enemy_id: String)
signal enemy_leaked_detail(enemy_id: String, weight: int)
signal enemy_damaged(position: Vector2, damage: float)
signal tower_weaken_requested(position: Vector2, multiplier: float, duration: float)
signal tower_disable_requested(position: Vector2, duration: float)
signal tower_disable_radius_requested(position: Vector2, radius: float, duration: float)
signal tower_damage_weaken_requested(position: Vector2, multiplier: float, duration: float)
signal tower_farthest_disable_requested(position: Vector2, duration: float)
signal tower_random_disable_requested(count: int, duration: float)
signal tower_support_disable_requested(position: Vector2, duration: float)

const MAX_ENEMIES: int = 220
const GOBLIN_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/club_goblin.png")
const ORC_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/orc.png")
const ORC_MAGE_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/orc_mage.png")
const SLIME_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/slime.png")
const SKELETON_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/skeleton_soldier.png")
const NECROMANCER_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/necromancer.png")
const DEMON_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/red_demon.png")
const YETI_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/yeti.png")
const MINOTAUR_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/minotaur.png")
const CRAB_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/giant_crab.png")
const RED_DRAGON_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/red_dragon.png")
const BLUE_DRAGON_TEXTURE: Texture2D = preload("res://assets/fantasy/mini_world/blue_dragon.png")
var _elite_affixes: Array[String] = ["layered", "agile", "regenerative", "shielded", "vengeful", "hunter", "cursed"]

var _definitions: Dictionary = {}
var _enemies: Array[Dictionary] = []
var _spawn_queue: Array[Dictionary] = []
var _path: PackedVector2Array = PackedVector2Array()
var _segment_lengths: PackedFloat32Array = PackedFloat32Array()
var _path_length: float = 0.0
var _grid: SpatialHashGrid = SpatialHashGrid.new()
var _query_buffer: Array[int] = []
var _status_system: PrototypeStatusSystem
var _ability_system: EnemyAbilitySystem = EnemyAbilitySystem.new()
var _elite_counter: int = 0
var _difficulty: Dictionary = {"enemy_hp_multiplier": 1.0, "enemy_speed_multiplier": 1.0, "bounty_multiplier": 1.0}
var _world_speed_multiplier: float = 1.0
var _world_regen_percent: float = 0.0
var _world_air_speed_multiplier: float = 1.0
var _portal_entry_ratio: float = -1.0
var _portal_exit_ratio: float = 0.0
var _draw_stride: int = 1
var _recent_corpses: Array[Dictionary] = []

func _ready() -> void:
	_load_definitions()
	_initialize_pool()
	_ability_system.bind_manager(self)
	Settings.preferences_changed.connect(_apply_quality)
	_apply_quality()

func _apply_quality() -> void:
	_draw_stride = 3 if Settings.quality == "low" else 2 if Settings.quality == "medium" else 1

func set_path(points: PackedVector2Array) -> void:
	_path = points
	_segment_lengths.clear()
	_path_length = 0.0
	for index: int in range(max(0, _path.size() - 1)):
		var length: float = _path[index].distance_to(_path[index + 1])
		_segment_lengths.append(length)
		_path_length += length

func set_status_system(status_system: PrototypeStatusSystem) -> void:
	_status_system = status_system

func set_difficulty(difficulty: Dictionary) -> void:
	_difficulty = difficulty

func set_world_speed_multiplier(multiplier: float) -> void:
	_world_speed_multiplier = maxf(0.1, multiplier)

func set_world_regen_percent(percent_per_second: float) -> void:
	_world_regen_percent = maxf(0.0, percent_per_second)

func set_world_air_speed_multiplier(multiplier: float) -> void:
	_world_air_speed_multiplier = maxf(0.1, multiplier)

func set_portal_pair(entry_ratio: float, exit_ratio: float) -> void:
	_portal_entry_ratio = clampf(entry_ratio, 0.0, 0.99)
	_portal_exit_ratio = clampf(exit_ratio, _portal_entry_ratio, 0.99)

func queue_spawn(enemy_id: String, count: int, interval: float, elite: bool = false) -> void:
	if not _definitions.has(enemy_id):
		push_warning("Unknown enemy id: %s" % enemy_id)
		return
	_spawn_queue.append({
		"id": enemy_id,
		"remaining": count,
		"interval": maxf(0.03, interval),
		"elapsed": 0.0,
		"elite": elite
	})

func reset() -> void:
	for enemy: Dictionary in _enemies:
		enemy["active"] = false
	_spawn_queue.clear()
	_grid.clear()
	_recent_corpses.clear()
	GameState.set_active_enemy_count(0)
	queue_redraw()

func tick(delta: float) -> void:
	_process_spawns(delta)
	for index: int in _enemies.size():
		var enemy: Dictionary = _enemies[index]
		if not enemy["active"]:
			continue
		enemy["time_since_hit"] = float(enemy["time_since_hit"]) + delta
		if String(enemy["elite_affix"]) == "regenerative":
			heal_enemy(index, float(enemy["max_hp"]) * 0.01 * delta)
		if _world_regen_percent > 0.0:
			heal_enemy(index, float(enemy["max_hp"]) * _world_regen_percent * delta)
		_ability_system.on_timer(index, delta)
		var movement_multiplier: float = float(enemy["slow_multiplier"]) if float(enemy["slow_timer"]) > 0.0 else 1.0
		enemy["slow_timer"] = maxf(0.0, float(enemy["slow_timer"]) - delta)
		enemy["stun_timer"] = maxf(0.0, float(enemy["stun_timer"]) - delta)
		if float(enemy["stun_timer"]) > 0.0:
			movement_multiplier = 0.0
		var previous_progress: float = float(enemy["progress"])
		enemy["progress"] = previous_progress + float(enemy["speed"]) * _world_speed_multiplier * (_world_air_speed_multiplier if bool(enemy["flying"]) else 1.0) * movement_multiplier * delta
		if _portal_entry_ratio >= 0.0 and not bool(enemy["portal_used"]) and previous_progress < _path_length * _portal_entry_ratio and float(enemy["progress"]) >= _path_length * _portal_entry_ratio:
			enemy["progress"] = _path_length * _portal_exit_ratio
			enemy["portal_used"] = true
		if float(enemy["progress"]) >= _path_length:
			_ability_system.on_reach_tower(index)
			enemy_leaked_detail.emit(String(enemy["id"]), int(enemy["leak_weight"]))
			_deactivate_enemy(index)
			enemy_leaked.emit(int(enemy["leak_weight"]))
			continue
		enemy["position"] = _position_at(float(enemy["progress"]))
	_rebuild_grid()
	GameState.set_active_enemy_count(active_count())
	queue_redraw()

func is_idle() -> bool:
	return _spawn_queue.is_empty() and active_count() == 0

func active_count() -> int:
	var count: int = 0
	for enemy: Dictionary in _enemies:
		if enemy["active"]:
			count += 1
	return count

func find_target(origin: Vector2, radius: float, target_mode: int = 0, can_target_flying: bool = true, is_anti_air: bool = false) -> int:
	_grid.query_circle(origin, radius, _query_buffer)
	var best_index: int = -1
	var best_value: float = -INF
	for index: int in _query_buffer:
		var enemy: Dictionary = _enemies[index]
		if not enemy["active"] or not enemy["targetable"] or (bool(enemy["flying"]) and not can_target_flying) or (bool(enemy["anti_air_only"]) and not is_anti_air):
			continue
		var distance_squared: float = origin.distance_squared_to(enemy["position"])
		if distance_squared > radius * radius:
			continue
		var candidate_value: float = _target_value(enemy, distance_squared, target_mode)
		if candidate_value > best_value:
			best_value = candidate_value
			best_index = index
	return best_index

func find_nearest_target(origin: Vector2, radius: float) -> int:
	return find_target(origin, radius, 5)

func get_enemy_position(index: int) -> Vector2:
	if index < 0 or index >= _enemies.size() or not _enemies[index]["active"]:
		return Vector2.INF
	return _enemies[index]["position"]

func damage_enemy(index: int, damage: float, damage_type: String = "physical", heavy_hit: bool = false) -> void:
	if index < 0 or index >= _enemies.size():
		return
	var enemy: Dictionary = _enemies[index]
	if not enemy["active"]:
		return
	if not enemy["targetable"]:
		return
	var final_damage: float = _status_system.modify_damage(index, damage, damage_type) if _status_system != null else damage
	if damage_type == "physical":
		final_damage *= 1.0 - float(enemy["physical_resist"])
		final_damage *= 100.0 / (100.0 + float(enemy["armor"]))
	elif damage_type == "magic":
		final_damage *= 1.0 - float(enemy["magic_resist"])
	if float(enemy["shield"]) > 0.0:
		var absorbed: float = minf(float(enemy["shield"]), final_damage)
		enemy["shield"] = float(enemy["shield"]) - absorbed
		final_damage -= absorbed
	enemy["hp"] = float(enemy["hp"]) - final_damage
	enemy_damaged.emit(Vector2(enemy["position"]), final_damage)
	_ability_system.on_hit(index, final_damage)
	if heavy_hit and _status_system != null:
		_status_system.on_heavy_hit(index, final_damage)
	if float(enemy["hp"]) <= 0.0:
		var bounty: int = int(enemy["bounty"])
		if String(enemy["elite_affix"]) == "vengeful":
			request_tower_disable(enemy["position"], 0.5)
		_ability_system.on_death(index)
		if enemy["active"] and float(enemy["hp"]) > 0.0:
			return
		_remember_corpse(enemy)
		_deactivate_enemy(index)
		enemy_defeated.emit(bounty)

func damage_radius(center: Vector2, radius: float, damage: float, damage_type: String = "physical") -> void:
	_grid.query_circle(center, radius, _query_buffer)
	for index: int in _query_buffer:
		var enemy: Dictionary = _enemies[index]
		if enemy["active"] and center.distance_squared_to(enemy["position"]) <= radius * radius:
			damage_enemy(index, damage, damage_type)

func damage_targets_around(center: Vector2, radius: float, damage: float, max_targets: int) -> void:
	_grid.query_circle(center, radius, _query_buffer)
	var applied: int = 0
	for index: int in _query_buffer:
		if applied >= max_targets:
			break
		if _enemies[index]["active"] and center.distance_squared_to(_enemies[index]["position"]) <= radius * radius:
			damage_enemy(index, damage)
			applied += 1

func apply_block(index: int, duration: float) -> void:
	if index >= 0 and index < _enemies.size() and _enemies[index]["active"]:
		apply_slow(index, duration, 0.30)

func apply_slow(index: int, duration: float, movement_multiplier: float) -> void:
	if index >= 0 and index < _enemies.size() and _enemies[index]["active"]:
		if duration >= float(_enemies[index]["slow_timer"]):
			_enemies[index]["slow_multiplier"] = clampf(movement_multiplier, 0.0, 1.0)
		_enemies[index]["slow_timer"] = maxf(float(_enemies[index]["slow_timer"]), duration)

func apply_stun(index: int, duration: float) -> void:
	if index >= 0 and index < _enemies.size() and _enemies[index]["active"]:
		_enemies[index]["stun_timer"] = maxf(float(_enemies[index]["stun_timer"]), duration)

func get_hp_ratio(index: int) -> float:
	if index < 0 or index >= _enemies.size() or not _enemies[index]["active"]:
		return 1.0
	var enemy: Dictionary = _enemies[index]
	var definition: Dictionary = _definitions[String(enemy["id"])]
	return clampf(float(enemy["hp"]) / float(definition["hp"]), 0.0, 1.0)

func get_max_hp(index: int) -> float:
	if index < 0 or index >= _enemies.size() or not _enemies[index]["active"]:
		return 0.0
	return float(_definitions[String(_enemies[index]["id"])]["hp"])

func is_enemy_active(index: int) -> bool:
	return index >= 0 and index < _enemies.size() and bool(_enemies[index]["active"])

func find_active_enemy_index(enemy_id: String) -> int:
	for index: int in _enemies.size():
		if _enemies[index]["active"] and String(_enemies[index]["id"]) == enemy_id:
			return index
	return -1

func multiply_enemy_speed(index: int, multiplier: float) -> void:
	if is_enemy_active(index):
		_enemies[index]["speed"] = float(_enemies[index]["speed"]) * multiplier

func is_elite_or_boss(index: int) -> bool:
	return is_enemy_active(index) and (bool(_enemies[index]["is_elite"]) or bool(_enemies[index]["is_boss"]))

func set_enemy_flags(index: int, elite: bool, boss: bool) -> void:
	if is_enemy_active(index):
		_enemies[index]["is_elite"] = elite
		_enemies[index]["is_boss"] = boss

func get_abilities(index: int) -> Array:
	return Array(_enemies[index]["abilities"]) if is_enemy_active(index) else []

func set_targetable(index: int, value: bool) -> void:
	if is_enemy_active(index):
		_enemies[index]["targetable"] = value

func is_targetable(index: int) -> bool:
	return is_enemy_active(index) and bool(_enemies[index]["targetable"])

func get_time_since_hit(index: int) -> float:
	return float(_enemies[index]["time_since_hit"]) if is_enemy_active(index) else 0.0

func reset_time_since_hit(index: int) -> void:
	if is_enemy_active(index):
		_enemies[index]["time_since_hit"] = 0.0

func set_ability_timer(index: int, ability_id: String, value: float) -> void:
	if is_enemy_active(index):
		_enemies[index]["ability_timers"][ability_id] = value

func advance_ability_timer(index: int, ability_id: String, delta: float) -> float:
	if not is_enemy_active(index):
		return 0.0
	var timers: Dictionary = _enemies[index]["ability_timers"]
	var value: float = float(timers.get(ability_id, 0.0)) + delta
	timers[ability_id] = value
	return value

func get_ability_flag(index: int, flag: String) -> bool:
	return is_enemy_active(index) and bool(_enemies[index]["ability_flags"].get(flag, false))

func set_ability_flag(index: int, flag: String, value: bool) -> void:
	if is_enemy_active(index):
		_enemies[index]["ability_flags"][flag] = value

func heal_enemy(index: int, amount: float) -> void:
	if is_enemy_active(index):
		_enemies[index]["hp"] = minf(float(_enemies[index]["max_hp"]), float(_enemies[index]["hp"]) + amount)

func advance_progress(index: int, ratio: float) -> void:
	if is_enemy_active(index):
		_enemies[index]["progress"] = minf(_path_length - 1.0, float(_enemies[index]["progress"]) + _path_length * ratio)
		_enemies[index]["position"] = _position_at(float(_enemies[index]["progress"]))

func retreat_enemy(index: int, ratio: float) -> void:
	if is_enemy_active(index) and not bool(_enemies[index]["is_boss"]):
		_enemies[index]["progress"] = maxf(0.0, float(_enemies[index]["progress"]) - _path_length * ratio)
		_enemies[index]["position"] = _position_at(float(_enemies[index]["progress"]))

func request_tower_weaken(position: Vector2, multiplier: float, duration: float) -> void:
	tower_weaken_requested.emit(position, multiplier, duration)

func request_tower_disable(position: Vector2, duration: float) -> void:
	tower_disable_requested.emit(position, duration)

func request_tower_disable_radius(position: Vector2, radius: float, duration: float) -> void:
	tower_disable_radius_requested.emit(position, radius, duration)

func request_tower_damage_weaken(position: Vector2, multiplier: float, duration: float) -> void:
	tower_damage_weaken_requested.emit(position, multiplier, duration)

func request_farthest_tower_disable(position: Vector2, duration: float) -> void:
	tower_farthest_disable_requested.emit(position, duration)

func request_random_tower_disable(count: int, duration: float) -> void:
	tower_random_disable_requested.emit(count, duration)

func request_tower_support_disable(position: Vector2, duration: float) -> void:
	tower_support_disable_requested.emit(position, duration)

func set_enemy_flying(index: int, value: bool) -> void:
	if is_enemy_active(index):
		_enemies[index]["flying"] = value
		_enemies[index]["anti_air_only"] = bool(_enemies[index]["anti_air_only_base"]) if value else false

func reveal_stealth_nearby(center: Vector2, radius: float) -> void:
	_grid.query_circle(center, radius, _query_buffer)
	for index: int in _query_buffer:
		if _enemies[index]["active"] and _enemies[index]["stealth"] and center.distance_squared_to(_enemies[index]["position"]) <= radius * radius:
			_enemies[index]["targetable"] = true

func count_active_enemy_id(enemy_id: String) -> int:
	var count: int = 0
	for enemy: Dictionary in _enemies:
		if enemy["active"] and String(enemy["id"]) == enemy_id:
			count += 1
	return count

func add_enemy_armor(index: int, amount: float) -> void:
	if is_enemy_active(index):
		_enemies[index]["armor"] = maxf(0.0, float(_enemies[index]["armor"]) + amount)

func has_status_immunity(index: int, status_id: String) -> bool:
	return is_enemy_active(index) and Array(_enemies[index]["status_immunities"]).has(status_id)

func grant_status_immunity(index: int, status_id: String) -> void:
	if is_enemy_active(index) and not Array(_enemies[index]["status_immunities"]).has(status_id):
		_enemies[index]["status_immunities"].append(status_id)

func spawn_children(source_index: int, child_id: String, count: int, hp_ratio: float) -> void:
	if not is_enemy_active(source_index) or not _definitions.has(child_id):
		return
	var source: Dictionary = _enemies[source_index]
	for _child: int in count:
		var child_index: int = _spawn_one(child_id)
		if child_index >= 0:
			_enemies[child_index]["progress"] = float(source["progress"])
			_enemies[child_index]["position"] = source["position"]
			_enemies[child_index]["hp"] = float(_enemies[child_index]["max_hp"]) * hp_ratio

func revive_enemy(index: int, hp_ratio: float) -> void:
	if is_enemy_active(index):
		_enemies[index]["hp"] = float(_enemies[index]["max_hp"]) * hp_ratio

func revive_nearby_dead(source_index: int, count: int, hp_ratio: float) -> void:
	if not is_enemy_active(source_index):
		return
	var source_position: Vector2 = get_enemy_position(source_index)
	for _revival: int in count:
		var best_index: int = -1
		var best_distance: float = INF
		for corpse_index: int in _recent_corpses.size():
			var corpse: Dictionary = _recent_corpses[corpse_index]
			if float(corpse["expires_at"]) < Time.get_ticks_msec() / 1000.0:
				continue
			var distance: float = source_position.distance_to(corpse["position"])
			if distance < best_distance:
				best_distance = distance
				best_index = corpse_index
		if best_index < 0:
			return
		var corpse: Dictionary = _recent_corpses[best_index]
		var revived_index: int = _spawn_one(String(corpse["id"]))
		if revived_index >= 0:
			_enemies[revived_index]["progress"] = float(corpse["progress"])
			_enemies[revived_index]["position"] = corpse["position"]
			_enemies[revived_index]["hp"] = float(_enemies[revived_index]["max_hp"]) * hp_ratio
		_recent_corpses.remove_at(best_index)

func _remember_corpse(enemy: Dictionary) -> void:
	if bool(enemy.get("is_boss", false)):
		return
	_recent_corpses.append({"id": String(enemy["id"]), "progress": float(enemy["progress"]), "position": enemy["position"], "expires_at": Time.get_ticks_msec() / 1000.0 + 12.0})
	if _recent_corpses.size() > 32:
		_recent_corpses.pop_front()

func apply_speed_buff_to_nearby(source_index: int, multiplier: float, _duration: float, radius: float = 130.0) -> void:
	if not is_enemy_active(source_index):
		return
	for target: int in get_targets_in_radius(get_enemy_position(source_index), radius, MAX_ENEMIES):
		_enemies[target]["speed"] = maxf(float(_enemies[target]["speed"]), float(_enemies[target]["base_speed"]) * multiplier)

func enrage_nearby(source_index: int, speed_per_stack: float) -> void:
	if not is_enemy_active(source_index):
		return
	for target: int in get_targets_in_radius(get_enemy_position(source_index), 99999.0, MAX_ENEMIES):
		_enemies[target]["speed"] = float(_enemies[target]["speed"]) * (1.0 + speed_per_stack)

func get_targets_in_radius(center: Vector2, radius: float, max_targets: int) -> Array[int]:
	var result: Array[int] = []
	_grid.query_circle(center, radius, _query_buffer)
	for index: int in _query_buffer:
		if result.size() >= max_targets:
			break
		if _enemies[index]["active"] and center.distance_squared_to(_enemies[index]["position"]) <= radius * radius:
			result.append(index)
	return result

func _process_spawns(delta: float) -> void:
	if _spawn_queue.is_empty():
		return
	var request: Dictionary = _spawn_queue[0]
	request["elapsed"] = float(request["elapsed"]) + delta
	while int(request["remaining"]) > 0 and float(request["elapsed"]) >= float(request["interval"]) and active_count() < MAX_ENEMIES:
		request["elapsed"] = float(request["elapsed"]) - float(request["interval"])
		_spawn_one(String(request["id"]), bool(request["elite"]))
		request["remaining"] = int(request["remaining"]) - 1
	if int(request["remaining"]) <= 0:
		_spawn_queue.pop_front()
	else:
		_spawn_queue[0] = request

func _spawn_one(enemy_id: String, elite: bool = false) -> int:
	for index: int in _enemies.size():
		if _enemies[index]["active"]:
			continue
		var definition: Dictionary = _definitions[enemy_id]
		var enemy: Dictionary = _enemies[index]
		enemy["active"] = true
		enemy["id"] = enemy_id
		enemy["hp"] = float(definition["hp"]) * float(_difficulty.get("enemy_hp_multiplier", 1.0))
		enemy["max_hp"] = float(enemy["hp"])
		enemy["speed"] = float(definition["speed"]) * float(_difficulty.get("enemy_speed_multiplier", 1.0))
		enemy["base_speed"] = float(enemy["speed"])
		enemy["armor"] = float(definition.get("armor", 0.0))
		enemy["physical_resist"] = float(definition.get("physical_resist", 0.0))
		enemy["magic_resist"] = float(definition.get("magic_resist", 0.0))
		enemy["flying"] = bool(definition.get("flying", false))
		enemy["anti_air_only"] = bool(definition.get("anti_air_only", false))
		enemy["anti_air_only_base"] = bool(definition.get("anti_air_only", false))
		enemy["stealth"] = bool(definition.get("stealth", false))
		enemy["targetable"] = not bool(definition.get("stealth", false))
		enemy["abilities"] = Array(definition.get("abilities", []))
		enemy["status_immunities"] = Array(definition.get("status_immunities", []))
		enemy["ability_timers"] = {}
		enemy["ability_flags"] = {}
		enemy["time_since_hit"] = 0.0
		enemy["bounty"] = roundi(float(definition["bounty"]) * float(_difficulty.get("bounty_multiplier", 1.0)))
		enemy["leak_weight"] = int(definition["leak_weight"])
		enemy["radius"] = float(definition["radius"])
		enemy["color"] = Color.html(String(definition["color"]))
		enemy["progress"] = 0.0
		enemy["portal_used"] = false
		enemy["position"] = _path[0]
		enemy["slow_timer"] = 0.0
		enemy["slow_multiplier"] = 1.0
		enemy["stun_timer"] = 0.0
		enemy["is_elite"] = bool(definition.get("is_elite", false))
		enemy["is_boss"] = bool(definition.get("is_boss", false))
		enemy["elite_affix"] = ""
		enemy["shield"] = 0.0
		if elite:
			_apply_elite_affix(index)
		_ability_system.on_spawn(index)
		enemy_spawned.emit(enemy_id)
		return index
	return -1

func _apply_elite_affix(index: int) -> void:
	var enemy: Dictionary = _enemies[index]
	var affix: String = _elite_affixes[_elite_counter % _elite_affixes.size()]
	_elite_counter += 1
	enemy["is_elite"] = true
	enemy["elite_affix"] = affix
	match affix:
		"layered": enemy["armor"] = float(enemy["armor"]) + 50.0
		"agile": enemy["speed"] = float(enemy["speed"]) * 1.25
		"shielded": enemy["shield"] = float(enemy["max_hp"]) * 0.30
		"hunter": request_tower_weaken(enemy["position"], 0.85, 2.0)
		"cursed": request_tower_weaken(enemy["position"], 0.70, 6.0)

func _target_value(enemy: Dictionary, distance_squared: float, target_mode: int) -> float:
	match target_mode:
		0: return float(enemy["progress"])
		1: return -float(enemy["progress"])
		2: return float(enemy["hp"])
		3: return -float(enemy["hp"])
		4: return float(enemy["speed"])
		_: return -distance_squared

func _deactivate_enemy(index: int) -> void:
	_enemies[index]["active"] = false

func _rebuild_grid() -> void:
	_grid.rebuild(_enemies)

func _position_at(distance_along_path: float) -> Vector2:
	var remaining: float = distance_along_path
	for index: int in _segment_lengths.size():
		var segment_length: float = _segment_lengths[index]
		if remaining <= segment_length:
			return _path[index].lerp(_path[index + 1], remaining / segment_length)
		remaining -= segment_length
	return _path[_path.size() - 1]

func _initialize_pool() -> void:
	_enemies.clear()
	for _index: int in MAX_ENEMIES:
		_enemies.append({
			"active": false,
			"id": "",
			"hp": 0.0,
			"max_hp": 0.0,
			"speed": 0.0,
			"base_speed": 0.0,
			"armor": 0.0,
			"physical_resist": 0.0,
			"magic_resist": 0.0,
			"flying": false,
			"anti_air_only": false,
			"anti_air_only_base": false,
			"stealth": false,
			"targetable": true,
			"abilities": [],
			"status_immunities": [],
			"ability_timers": {},
			"ability_flags": {},
			"time_since_hit": 0.0,
			"bounty": 0,
			"leak_weight": 1,
			"radius": 10.0,
			"color": Color.WHITE,
			"progress": 0.0,
			"portal_used": false,
			"position": Vector2.ZERO,
			"slow_timer": 0.0,
			"slow_multiplier": 1.0,
			"stun_timer": 0.0,
			"is_elite": false,
			"is_boss": false,
			"elite_affix": "",
			"shield": 0.0
		})

func _load_definitions() -> void:
	_load_definitions_from_directory("res://data/enemies")
	_load_definitions_from_directory("res://data/bosses")

func _load_definitions_from_directory(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_error("Could not open %s" % directory_path)
		return
	for filename: String in directory.get_files():
		if not filename.ends_with(".json"):
			continue
		var path: String = "%s/%s" % [directory_path, filename]
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Could not open enemy definition: %s" % path)
			continue
		var json: JSON = JSON.new()
		if json.parse(file.get_as_text()) != OK:
			push_error("Invalid enemy JSON: %s" % path)
			continue
		var definition: Dictionary = json.data
		_definitions[String(definition["id"])] = definition

func _draw() -> void:
	var visual_index: int = 0
	for enemy: Dictionary in _enemies:
		if not enemy["active"]:
			continue
		visual_index += 1
		if visual_index % _draw_stride != 0:
			continue
		var position: Vector2 = enemy["position"]
		var radius: float = float(enemy["radius"])
		var sprite_size: float = maxf(34.0, radius * 3.15)
		if bool(enemy["is_boss"]):
			sprite_size *= 1.45
		draw_ellipse_shadow(position + Vector2(0.0, sprite_size * 0.28), sprite_size * 0.34, Color(0.03, 0.04, 0.08, 0.42))
		var destination := Rect2(position - Vector2(sprite_size * 0.5, sprite_size * 0.72), Vector2(sprite_size, sprite_size))
		draw_texture_rect_region(_visual_texture(enemy), destination, Rect2(0.0, 0.0, 16.0, 16.0), Color.WHITE)
		if bool(enemy["is_elite"]):
			draw_arc(position, sprite_size * 0.44, 0.0, TAU, 20, Color(1.0, 0.78, 0.25, 0.9), 1.5)
		elif bool(enemy["is_boss"]):
			draw_arc(position, sprite_size * 0.48, 0.0, TAU, 24, Color(0.96, 0.30, 0.32, 0.94), 2.0)

func draw_ellipse_shadow(center: Vector2, radius: float, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(1.5, 0.45))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO)

func _visual_texture(enemy: Dictionary) -> Texture2D:
	var enemy_id := String(enemy["id"])
	if bool(enemy["is_boss"]):
		return BLUE_DRAGON_TEXTURE if bool(enemy["flying"]) else MINOTAUR_TEXTURE
	match enemy_id:
		"grunt", "runner", "swarmling", "digger": return GOBLIN_TEXTURE
		"brute", "ice_knight", "machine_soldier", "repair_bot", "tesla_bot": return ORC_TEXTURE
		"poison_spitter", "swamp_shaman", "necro_acolyte", "void_walker": return ORC_MAGE_TEXTURE
		"spore_splitter", "void_leech", "scarab": return SLIME_TEXTURE
		"wraith", "infiltrator", "morthal_phylactery": return SKELETON_TEXTURE
		"demon_berserker", "bomber_imp", "magma_golem": return DEMON_TEXTURE
		"ice_wolf", "khepri_worm", "giant_crab": return CRAB_TEXTURE
		"harpy_matron", "sky_carrier", "bat", "swarm_drone": return RED_DRAGON_TEXTURE
		"dread_echo", "eclipse_clone": return NECROMANCER_TEXTURE
		_: return YETI_TEXTURE

