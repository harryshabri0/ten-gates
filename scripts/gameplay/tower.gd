class_name PrototypeTower
extends Node2D
## Data-driven P2 tower. The controller is the only object that ticks placed towers.

const ARCHERY_TEXTURE: Texture2D = preload("res://assets/fantasy/tiny_swords/archery.png")
const BARRACKS_TEXTURE: Texture2D = preload("res://assets/fantasy/tiny_swords/barracks.png")
const MONASTERY_TEXTURE: Texture2D = preload("res://assets/fantasy/tiny_swords/monastery.png")
const TOWER_TEXTURE: Texture2D = preload("res://assets/fantasy/tiny_swords/tower.png")
const VOID_TOWER_TEXTURE: Texture2D = preload("res://assets/fantasy/tiny_swords/void_tower.png")

var _cost_multipliers: Array[float] = [1.0, 0.7, 1.1, 1.6, 2.4]
var _target_mode_names: Array[String] = ["First", "Last", "Strongest", "Weakest", "Fastest", "Nearest"]

var tower_id: String = ""
var tower_name: String = ""
var definition: Dictionary = {}
var level: int = 1
var branch: String = ""
var target_mode: int = 0
var invested_cost: int = 0
var slot_type: String = "standard"
var _range_modifier: float = 1.0
var _damage_modifier: float = 1.0
var _level_range_multiplier: float = 1.0
var _world_range_multiplier: float = 1.0
var _world_element_damage_multipliers: Dictionary = {}
var _enemy_damage_multiplier: float = 1.0
var _enemy_damage_debuff_timer: float = 0.0
var _support_range_multiplier: float = 1.0
var _support_attack_speed_multiplier: float = 1.0
var _support_disabled_timer: float = 0.0
var _cooldown: float = 0.0
var _ability_elapsed: float = 0.0
var _focus_target: int = -1
var _focus_stacks: int = 0
var _shot_count: int = 0
var _selected: bool = false
var _enemy_debuff_timer: float = 0.0
var _enemy_attack_speed_multiplier: float = 1.0
var _disabled_timer: float = 0.0
var _spell_attack_speed_multiplier: float = 1.0
var _skill_modifiers: StatModifierStack

func configure(data: Dictionary, assigned_slot_type: String) -> void:
	definition = data
	tower_id = String(data["id"])
	tower_name = String(data["name"])
	slot_type = assigned_slot_type
	if slot_type == "highland":
		_range_modifier = 1.15
	if slot_type == "rune" and String(data.get("slot_affinity", "")) != "":
		_damage_modifier = 1.20
	invested_cost = get_build_cost()
	queue_redraw()

func get_build_cost() -> int:
	return _cost_for_multiplier(_cost_multipliers[0])

func get_next_upgrade_cost() -> int:
	if level >= 5:
		return 0
	var cost: int = _cost_for_multiplier(_cost_multipliers[level])
	if level + 1 >= 4:
		cost = roundi(float(cost) * _skill_multiplier("high_upgrade_cost"))
	return roundi(float(cost) * _skill_multiplier("tower_upgrade_cost"))

func get_upgrade_cost_for_level(target_level: int) -> int:
	var cost: int = _cost_for_multiplier(_cost_multipliers[target_level - 1])
	if target_level >= 4:
		cost = roundi(float(cost) * _skill_multiplier("high_upgrade_cost"))
	return roundi(float(cost) * _skill_multiplier("tower_upgrade_cost"))

func can_choose_branch() -> bool:
	return level == 3 and branch.is_empty()

func can_upgrade() -> bool:
	return level < 5 and not can_choose_branch()

func choose_branch(chosen_branch: String) -> bool:
	if not can_choose_branch() or not definition.get("branches", {}).has(chosen_branch):
		return false
	branch = chosen_branch
	level = 4
	invested_cost += get_upgrade_cost_for_level(4)
	queue_redraw()
	return true

func upgrade() -> bool:
	if not can_upgrade():
		return false
	level += 1
	invested_cost += get_upgrade_cost_for_level(level)
	queue_redraw()
	return true

func get_sell_refund(refund_ratio: float) -> int:
	return floori(float(invested_cost) * refund_ratio)

func get_wave_gold_bonus() -> int:
	if tower_id != "coin_tower":
		return 0
	return int(_current_stats().get("wave_gold", 0))

func cycle_target_mode() -> void:
	target_mode = (target_mode + 1) % _target_mode_names.size()

func get_target_mode_name() -> String:
	return _target_mode_names[target_mode]

func get_branch_name(branch_id: String) -> String:
	return String(definition.get("branches", {}).get(branch_id, {}).get("name", branch_id))

func get_display_stats() -> Dictionary:
	var stats: Dictionary = _current_stats()
	return {"damage": float(stats["damage"]) * _damage_modifier * _skill_multiplier("tower_damage"), "range": float(stats["range"]) * _range_modifier * _level_range_multiplier * _world_range_multiplier * _skill_multiplier("tower_range"), "interval": float(stats["interval"]) / _skill_multiplier("tower_attack_speed")}

func set_selected(value: bool) -> void:
	_selected = value
	queue_redraw()

func set_level_range_multiplier(multiplier: float) -> void:
	_level_range_multiplier = multiplier
	queue_redraw()

func set_world_range_multiplier(multiplier: float) -> void:
	_world_range_multiplier = maxf(0.1, multiplier)
	queue_redraw()

func set_world_element_damage_multipliers(multipliers: Dictionary) -> void:
	_world_element_damage_multipliers = multipliers.duplicate()

func set_support_multipliers(range_multiplier: float, attack_speed_multiplier: float) -> void:
	_support_range_multiplier = maxf(0.1, range_multiplier)
	_support_attack_speed_multiplier = maxf(0.1, attack_speed_multiplier)

func disable_support_for(duration: float) -> void:
	_support_disabled_timer = maxf(_support_disabled_timer, duration)

func is_support_active() -> bool:
	return _support_disabled_timer <= 0.0

func apply_attack_speed_debuff(multiplier: float, duration: float) -> void:
	_enemy_attack_speed_multiplier = minf(_enemy_attack_speed_multiplier, multiplier)
	_enemy_debuff_timer = maxf(_enemy_debuff_timer, duration)

func apply_damage_debuff(multiplier: float, duration: float) -> void:
	_enemy_damage_multiplier = minf(_enemy_damage_multiplier, multiplier)
	_enemy_damage_debuff_timer = maxf(_enemy_damage_debuff_timer, duration)

func disable_for(duration: float) -> void:
	_disabled_timer = maxf(_disabled_timer, duration)

func set_spell_attack_speed_multiplier(multiplier: float) -> void:
	_spell_attack_speed_multiplier = maxf(0.1, multiplier)

func set_skill_modifiers(modifiers: StatModifierStack) -> void:
	_skill_modifiers = modifiers

func restore_state(saved_level: int, saved_branch: String, saved_invested_cost: int) -> void:
	level = clampi(saved_level, 1, 5)
	branch = saved_branch if level >= 4 else ""
	invested_cost = maxi(get_build_cost(), saved_invested_cost)
	queue_redraw()

func tick(delta: float, enemy_manager: PrototypeEnemyManager, projectile_pool: PrototypeProjectilePool, status_system: PrototypeStatusSystem) -> void:
	if tower_id == "coin_tower":
		return
	_disabled_timer = maxf(0.0, _disabled_timer - delta)
	_enemy_debuff_timer = maxf(0.0, _enemy_debuff_timer - delta)
	_enemy_damage_debuff_timer = maxf(0.0, _enemy_damage_debuff_timer - delta)
	_support_disabled_timer = maxf(0.0, _support_disabled_timer - delta)
	if _enemy_debuff_timer <= 0.0:
		_enemy_attack_speed_multiplier = 1.0
	if _enemy_damage_debuff_timer <= 0.0:
		_enemy_damage_multiplier = 1.0
	if _disabled_timer > 0.0:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	_ability_elapsed += delta
	var stats: Dictionary = _current_stats()
	_process_ultimate(stats, enemy_manager, status_system)
	if _cooldown > 0.0:
		return
	var attack_range: float = float(stats["range"]) * _range_modifier * _level_range_multiplier * _world_range_multiplier * _support_range_multiplier * _skill_multiplier("tower_range")
	var allowed_targets: Array = Array(definition.get("targets", ["ground", "air"]))
	var target: int = enemy_manager.find_target(global_position, attack_range, target_mode, allowed_targets.has("air"), tower_id == "skyfang")
	if target < 0:
		return
	var tower_speed: float = _skill_multiplier("tower_attack_speed")
	if tower_id == "cannon":
		tower_speed *= _skill_multiplier("cannon_attack_speed")
	_cooldown = float(stats["interval"]) / maxf(0.1, _enemy_attack_speed_multiplier * _spell_attack_speed_multiplier * _support_attack_speed_multiplier * tower_speed)
	_attack_target(target, stats, enemy_manager, projectile_pool, status_system)

func _attack_target(target: int, stats: Dictionary, enemy_manager: PrototypeEnemyManager, projectile_pool: PrototypeProjectilePool, status_system: PrototypeStatusSystem) -> void:
	AudioDirector.play_attack(tower_id)
	var element_multiplier: float = float(_world_element_damage_multipliers.get(String(definition.get("element", "")), 1.0))
	var final_damage: float = float(stats["damage"]) * _damage_modifier * _skill_multiplier("tower_damage") * element_multiplier * _enemy_damage_multiplier
	if tower_id == "archer":
		final_damage *= _skill_multiplier("archer_damage")
	if tower_id == "barracks":
		final_damage *= _skill_multiplier("barracks_damage")
	if tower_id == "archer":
		if target == _focus_target:
			_focus_stacks = mini(5, _focus_stacks + 1)
		else:
			_focus_target = target
			_focus_stacks = 1
		final_damage *= 1.0 + float(_focus_stacks) * 0.05
	_shot_count += 1
	if String(stats.get("ability", "")) == "deadeye" and _shot_count % 5 == 0:
		final_damage *= 3.0
	if tower_id == "barracks":
		if String(stats.get("ability", "")) == "assassinate" and enemy_manager.get_hp_ratio(target) < 0.20:
			final_damage *= 5.0
		enemy_manager.damage_enemy(target, final_damage, "physical", false)
		enemy_manager.apply_block(target, float(stats.get("block_duration", 0.45)))
		return
	if tower_id == "tesla":
		var chain_targets: Array[int] = enemy_manager.get_targets_in_radius(enemy_manager.get_enemy_position(target), float(stats.get("chain_radius", 105.0)), int(stats.get("chain_targets", 3)))
		for chain_target: int in chain_targets:
			enemy_manager.damage_enemy(chain_target, final_damage, "magic")
			if float(stats.get("stun_duration", 0.0)) > 0.0:
				status_system.apply_status(chain_target, "stun", float(stats["stun_duration"]))
		return
	if tower_id == "fire_tower":
		var flame_targets: Array[int] = enemy_manager.get_targets_in_radius(enemy_manager.get_enemy_position(target), float(stats.get("flame_radius", 64.0)), int(stats.get("flame_targets", 4)))
		for flame_target: int in flame_targets:
			enemy_manager.damage_enemy(flame_target, final_damage, "fire")
			status_system.apply_status(flame_target, "burn", float(stats.get("burn_duration", 2.5)), float(stats.get("burn_power", 1.0)))
		return
	if tower_id == "mechanic_workshop" and String(stats.get("mode", "")) == "mine":
		var mine_targets: Array[int] = enemy_manager.get_targets_in_radius(enemy_manager.get_enemy_position(target), float(stats.get("mine_radius", 75.0)), int(stats.get("mine_targets", 5)))
		for mine_target: int in mine_targets:
			enemy_manager.damage_enemy(mine_target, final_damage, "physical")
			if float(stats.get("stun_duration", 0.0)) > 0.0:
				status_system.apply_status(mine_target, "stun", float(stats["stun_duration"]))
		return
	if tower_id == "void_tower":
		if String(stats.get("mode", "")) == "rift":
			enemy_manager.retreat_enemy(target, float(stats.get("retreat_ratio", 0.15)))
			if float(stats.get("weaken_duration", 0.0)) > 0.0:
				status_system.apply_status(target, "weaken", float(stats["weaken_duration"]), float(stats.get("weaken_multiplier", 1.0)))
		else:
			var void_targets: Array[int] = enemy_manager.get_targets_in_radius(enemy_manager.get_enemy_position(target), float(stats.get("singularity_radius", 80.0)), int(stats.get("singularity_targets", 5)))
			for void_target: int in void_targets:
				enemy_manager.damage_enemy(void_target, final_damage, "magic")
				status_system.apply_status(void_target, "slow", float(stats.get("slow_duration", 1.2)), float(stats.get("slow_multiplier", 0.65)))
		return
	var special: String = String(stats.get("ability", ""))
	if special == "piercing_beam" or special == "prism_beam":
		var beam_targets: Array[int] = enemy_manager.get_targets_in_radius(enemy_manager.get_enemy_position(target), 90.0, int(stats.get("pierce_count", 3)))
		for beam_target: int in beam_targets:
			enemy_manager.damage_enemy(beam_target, final_damage, "magic")
		return
	var shots: int = int(stats.get("multishot", 1))
	for _shot: int in shots:
		projectile_pool.fire(global_position, target, final_damage, float(stats["projectile_speed"]) * _skill_multiplier("projectile_speed"), float(stats["splash"]), _display_color(), tower_id == "cannon")
	if stats.has("slow_duration"):
		status_system.apply_status(target, "slow", float(stats["slow_duration"]), float(stats["slow_multiplier"]))
		if float(stats.get("freeze_chance", 0.0)) > 0.0 and _shot_count % 4 == 0:
			status_system.apply_status(target, "freeze", 1.0 + float(stats["freeze_chance"]) * 2.0)
	if special == "siege_stun":
		status_system.apply_status(target, "stun", 0.5)
	if tower_id == "poison_lab":
		status_system.apply_status(target, "poison", float(stats.get("poison_duration", 3.0)), float(stats.get("poison_stacks", 1.0)))
		if float(stats.get("armor_break_duration", 0.0)) > 0.0:
			status_system.apply_status(target, "armor_break", float(stats["armor_break_duration"]))

func _process_ultimate(stats: Dictionary, enemy_manager: PrototypeEnemyManager, status_system: PrototypeStatusSystem) -> void:
	var ability: String = String(stats.get("ability", ""))
	var cooldown: float = float(stats.get("ability_cooldown", 0.0))
	if cooldown <= 0.0 or _ability_elapsed < cooldown:
		return
	_ability_elapsed = 0.0
	var nearby: Array[int] = enemy_manager.get_targets_in_radius(global_position, float(stats["range"]) * _range_modifier * _level_range_multiplier * _world_range_multiplier, PrototypeEnemyManager.MAX_ENEMIES)
	match ability:
		"rain_of_arrows":
			if not nearby.is_empty():
				enemy_manager.damage_targets_around(enemy_manager.get_enemy_position(nearby[0]), 55.0, float(stats["damage"]) * _damage_modifier * 0.7, 4)
		"absolute_zero", "time_stop":
			for target: int in nearby:
				status_system.apply_status(target, "stun", 1.5)
		"whiteout":
			for target: int in nearby:
				status_system.apply_status(target, "slow", 2.5, 0.48)
				enemy_manager.damage_enemy(target, float(stats["damage"]) * _damage_modifier * 0.45)
		"paladin_aura":
			for target: int in nearby:
				enemy_manager.apply_block(target, 0.65)
		"pandemic":
			for target: int in nearby:
				status_system.apply_status(target, "poison", 4.0, 1.0)
		"thunderlord", "storm_net":
			for target: int in nearby:
				status_system.apply_status(target, "stun", 1.2 if ability == "thunderlord" else 0.5)
				enemy_manager.damage_enemy(target, float(stats["damage"]) * _damage_modifier * 0.6, "magic")
		"sunfire", "hellfire":
			for target: int in nearby:
				enemy_manager.damage_enemy(target, float(stats["damage"]) * _damage_modifier * 0.65, "fire")
				status_system.apply_status(target, "burn", 4.0, 1.5)

func _current_stats() -> Dictionary:
	if level <= 3:
		return Array(definition["levels"])[level - 1]
	return Array(definition["branches"][branch]["levels"])[level - 4]

func _cost_for_multiplier(multiplier: float) -> int:
	var slot_multiplier: float = 1.10 if slot_type == "highland" else 1.0
	return ceili(float(definition["base_cost"]) * multiplier * slot_multiplier)

func _skill_multiplier(stat: String) -> float:
	return _skill_modifiers.multiplier(stat) if _skill_modifiers != null else 1.0

func _display_color() -> Color:
	var base_color: Color = Color.html(String(definition["color"]))
	if branch == "A":
		return base_color.lerp(Color(1.0, 0.42, 0.20), 0.35)
	if branch == "B":
		return base_color.lerp(Color(0.25, 0.75, 1.0), 0.35)
	return base_color

func get_visual_color() -> Color:
	return _display_color()

func _draw() -> void:
	var stats: Dictionary = _current_stats()
	var color: Color = _display_color()
	if _selected:
		draw_arc(Vector2.ZERO, float(stats["range"]) * _range_modifier * _level_range_multiplier * _world_range_multiplier, 0.0, TAU, 48, Color(color, 0.22), 2.0)
	draw_circle(Vector2(0.0, 19.0), 32.0 + float(level), Color(0.04, 0.06, 0.09, 0.82))
	var texture := _fantasy_building_texture()
	var source_size := texture.get_size()
	var scale := 94.0 / source_size.y
	var size := source_size * scale
	draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, 24.0 - size.y), size), false, Color.WHITE)
	draw_circle(Vector2(0.0, 17.0), 5.0 + float(level) * 0.8, Color(color, 0.94))
	if tower_id in ["arcane", "void_tower", "tesla"]:
		draw_arc(Vector2(0.0, 17.0), 13.0 + float(level), 0.0, TAU, 18, Color(color, 0.75), 1.5)
	if tower_id == "fire_tower":
		draw_colored_polygon(PackedVector2Array([Vector2(-7, 16), Vector2(0, -2), Vector2(7, 16)]), Color(1.0, 0.50, 0.12, 0.92))

func _fantasy_building_texture() -> Texture2D:
	match tower_id:
		"archer", "ballista", "skyfang": return ARCHERY_TEXTURE
		"barracks", "war_totem", "mechanic_workshop": return BARRACKS_TEXTURE
		"arcane", "ice", "poison_lab", "tesla", "coin_tower": return MONASTERY_TEXTURE
		"void_tower": return VOID_TOWER_TEXTURE
		_: return TOWER_TEXTURE

