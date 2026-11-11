class_name EnemyAbilitySystem
extends RefCounted
## Data-driven ability hooks; EnemyManager owns the pooled state and calls these hooks.

var _manager: PrototypeEnemyManager

func bind_manager(manager: PrototypeEnemyManager) -> void:
	_manager = manager

func on_spawn(enemy_index: int) -> void:
	for ability: Dictionary in _manager.get_abilities(enemy_index):
		if String(ability["id"]) == "burrow":
			_manager.set_targetable(enemy_index, false)
			_manager.set_ability_timer(enemy_index, "burrow", float(ability.get("duration", 3.0)))

func on_timer(enemy_index: int, delta: float) -> void:
	for ability: Dictionary in _manager.get_abilities(enemy_index):
		var ability_id: String = String(ability["id"])
		if ability_id == "burrow":
			var remaining: float = _manager.advance_ability_timer(enemy_index, ability_id, -delta)
			if remaining <= 0.0 and not _manager.is_targetable(enemy_index):
				_manager.advance_progress(enemy_index, float(ability.get("jump_path_ratio", 0.10)))
				_manager.set_targetable(enemy_index, true)
			continue
		var interval: float = float(ability.get("interval", 0.0))
		if interval <= 0.0:
			if ability_id == "repair_if_idle" and _manager.get_time_since_hit(enemy_index) > 0.0:
				_manager.heal_enemy(enemy_index, _manager.get_max_hp(enemy_index) * float(ability.get("percent_per_second", 0.01)) * delta)
			continue
		var elapsed: float = _manager.advance_ability_timer(enemy_index, ability_id, delta)
		if elapsed < interval:
			continue
		_manager.set_ability_timer(enemy_index, ability_id, 0.0)
		match ability_id:
			"revive":
				_manager.revive_nearby_dead(enemy_index, int(ability.get("count", 1)), float(ability.get("hp_ratio", 0.30)))
			"heal_aura":
				for target: int in _manager.get_targets_in_radius(_manager.get_enemy_position(enemy_index), float(ability.get("radius", 120.0)), PrototypeEnemyManager.MAX_ENEMIES):
					_manager.heal_enemy(target, _manager.get_max_hp(target) * float(ability.get("percent", 0.05)))
			"tower_weaken", "tower_aura_weaken":
				_manager.request_tower_weaken(_manager.get_enemy_position(enemy_index), float(ability.get("attack_speed_multiplier", 0.80)), float(ability.get("duration", 5.0)))
			"emp_pulse":
				_manager.request_tower_disable(_manager.get_enemy_position(enemy_index), float(ability.get("stun_duration", 0.5)))
			"carrier_drop":
				_manager.spawn_children(enemy_index, String(ability.get("child_id", "grunt")), int(ability.get("count", 1)), 1.0)
			"teleport":
				_manager.advance_progress(enemy_index, float(ability.get("path_ratio", 0.10)))
			"leech_buff":
				_manager.request_tower_support_disable(_manager.get_enemy_position(enemy_index), float(ability.get("duration", 6.0)))

func on_hit(enemy_index: int, _damage: float) -> void:
	_manager.reset_time_since_hit(enemy_index)

func on_death(enemy_index: int) -> void:
	for ability: Dictionary in _manager.get_abilities(enemy_index):
		match String(ability["id"]):
			"split":
				_manager.spawn_children(enemy_index, String(ability.get("child_id", "swarmling")), int(ability.get("count", 2)), float(ability.get("child_hp_ratio", 0.55)))
			"revive":
				if not bool(ability.get("self_revive", false)):
					continue
				if not _manager.get_ability_flag(enemy_index, "revived"):
					_manager.set_ability_flag(enemy_index, "revived", true)
					_manager.revive_enemy(enemy_index, float(ability.get("hp_ratio", 0.30)))
			"enrage_on_ally_death":
				_manager.enrage_nearby(enemy_index, float(ability.get("speed_per_stack", 0.06)))

func on_reach_tower(enemy_index: int) -> void:
	for ability: Dictionary in _manager.get_abilities(enemy_index):
		if String(ability["id"]) == "bomb_on_reach":
			_manager.request_tower_disable(_manager.get_enemy_position(enemy_index), float(ability.get("tower_disable_duration", 5.0)))

