extends Node2D
## P2 orchestration: fixed-step prototype, data-driven tower upgrades, and build UI.

const FIXED_TICK_SECONDS: float = 1.0 / 30.0
const MAX_TICKS_PER_FRAME: int = 4
const SLOT_RADIUS: float = 42.0
const SELL_REFUND_NORMAL: float = 0.70
const LOCKED_SLOT_COST: int = 75
const UNDO_WINDOW_MS: int = 3000
const TERRAIN_TEXTURE: Texture2D = preload("res://assets/fantasy/tiny_swords/terrain_tilemap.png")
const BUSH_TEXTURE: Texture2D = preload("res://assets/fantasy/tiny_swords/bushes.png")
const TREE_TEXTURE: Texture2D = preload("res://assets/fantasy/tiny_swords/trees.png")

var _path_points: PackedVector2Array = PackedVector2Array([
	Vector2(70, 510), Vector2(340, 510), Vector2(520, 325), Vector2(810, 325),
	Vector2(960, 610), Vector2(1280, 610), Vector2(1460, 420), Vector2(1840, 420)
])
var _slot_positions: PackedVector2Array = PackedVector2Array([
	Vector2(305, 380), Vector2(420, 650), Vector2(600, 210), Vector2(690, 480),
	Vector2(870, 215), Vector2(900, 750), Vector2(1110, 460), Vector2(1190, 760),
	Vector2(1370, 330), Vector2(1510, 610), Vector2(1650, 295), Vector2(1710, 700)
])
var _layout_slot_positions: PackedVector2Array = PackedVector2Array()
var _slot_types: PackedStringArray = PackedStringArray([
	"standard", "highland", "rune", "roadside", "locked", "standard",
	"highland", "standard", "rune", "roadside", "standard", "locked"
])

@onready var _enemy_manager: PrototypeEnemyManager = $EnemyManager
@onready var _projectile_pool: PrototypeProjectilePool = $ProjectilePool
@onready var _wave_director: PrototypeWaveDirector = $WaveDirector
@onready var _status_system: PrototypeStatusSystem = $StatusSystem
@onready var _boss_controller: BossController = $BossController
@onready var _spell_system: SpellSystem = $SpellSystem
@onready var _hud: PrototypeHud = $GameHud
@onready var _feedback: FeedbackController = $FeedbackLayer
@onready var _world_rules: WorldRuleController = $WorldRuleController

var _tower_definitions: Dictionary = {}
var _level_loader: LevelLoader = LevelLoader.new()
var _loadout_manager: LoadoutManager = LoadoutManager.new()
var _star_progress: StarProgress = StarProgress.new()
var _campaign: Campaign = Campaign.new()
var _skill_tree: SkillTree = SkillTree.new()
var _skill_modifiers: StatModifierStack = StatModifierStack.new()
var _codex: Codex = Codex.new()
var _difficulties: Dictionary = {}
var _difficulty_id: String = "normal"
var _difficulty: Dictionary = {}
var _current_level: Dictionary = {}
var _level_start_base_hp: int = 20
var _leaks: int = 0
var _sell_count: int = 0
var _gold_rush_multiplier: float = 1.0
var _slots_occupied: PackedByteArray = PackedByteArray()
var _tower_by_slot: Array[PrototypeTower] = []
var _towers: Array[PrototypeTower] = []
var _selected_slot: int = -1
var _selected_tower: PrototypeTower
var _undo_tower: PrototypeTower
var _undo_slot: int = -1
var _undo_deadline_ms: int = 0
var _simulation_accumulator: float = 0.0
var _speed_multiplier: int = 1
var _stress_test_running: bool = false
var _is_paused: bool = false
var _auto_next: bool = false
var _leak_causes: Dictionary = {}

func _ready() -> void:
	_load_tower_data()
	_campaign.load_data(SaveManager.get_section("campaign"))
	_skill_tree.load_data(SaveManager.get_section("skill_tree"))
	_codex.load_data(SaveManager.get_section("codex"))
	_refresh_skill_modifiers()
	_difficulties = _level_loader.load_difficulties()
	set_difficulty("normal")
	_enemy_manager.set_status_system(_status_system)
	_status_system.bind_enemy_manager(_enemy_manager)
	_boss_controller.bind_enemy_manager(_enemy_manager)
	_boss_controller.telegraph_started.connect(_on_boss_telegraph)
	_spell_system.bind(_enemy_manager, _status_system)
	var active_run: Dictionary = SaveManager.get_active_run()
	var level_id: String = String(active_run.get("level_id", "1-1"))
	var level: Dictionary = _wave_director.load_level_id(level_id, _enemy_manager)
	_current_level = level
	_apply_level_layout(level)
	_apply_world_rule(level)
	_slots_occupied.resize(_slot_positions.size())
	_tower_by_slot.resize(_slot_positions.size())
	_enemy_manager.set_path(_path_points)
	GameState.set_gold(roundi(float(level.get("starting_gold", 500)) * float(_difficulty.get("starting_gold_multiplier", 1.0)) * _skill_modifiers.multiplier("starting_gold")))
	GameState.set_base_hp(roundi(_skill_modifiers.evaluate("base_hp", float(_difficulty.get("base_hp", level.get("base_hp", 20))))))
	_level_start_base_hp = GameState.base_hp
	GameState.set_current_wave(1)
	_enemy_manager.enemy_defeated.connect(_on_enemy_defeated)
	_enemy_manager.enemy_leaked.connect(_on_enemy_leaked)
	_enemy_manager.enemy_leaked_detail.connect(_on_enemy_leaked_detail)
	_enemy_manager.enemy_spawned.connect(_on_enemy_spawned)
	_enemy_manager.enemy_damaged.connect(_on_enemy_damaged)
	_enemy_manager.tower_weaken_requested.connect(_on_tower_weaken_requested)
	_enemy_manager.tower_disable_requested.connect(_on_tower_disable_requested)
	_enemy_manager.tower_disable_radius_requested.connect(_on_tower_disable_radius_requested)
	_enemy_manager.tower_damage_weaken_requested.connect(_on_tower_damage_weaken_requested)
	_enemy_manager.tower_farthest_disable_requested.connect(_on_tower_farthest_disable_requested)
	_enemy_manager.tower_random_disable_requested.connect(_on_tower_random_disable_requested)
	_enemy_manager.tower_support_disable_requested.connect(_on_tower_support_disable_requested)
	_wave_director.wave_started.connect(_on_wave_started)
	_wave_director.wave_completed.connect(_on_wave_completed)
	_wave_director.level_completed.connect(_on_level_completed)
	_wave_director.boss_requested.connect(_on_boss_requested)
	_world_rules.tower_range_multiplier_changed.connect(_on_world_range_multiplier_changed)
	_world_rules.rule_message_changed.connect(_hud.set_hint)
	_world_rules.path_changed.connect(_on_world_path_changed)
	_world_rules.enemy_speed_multiplier_changed.connect(_enemy_manager.set_world_speed_multiplier)
	_world_rules.enemy_regen_percent_changed.connect(_enemy_manager.set_world_regen_percent)
	_world_rules.air_speed_multiplier_changed.connect(_enemy_manager.set_world_air_speed_multiplier)
	_world_rules.element_damage_multipliers_changed.connect(_on_world_element_damage_multipliers_changed)
	_world_rules.eruption_started.connect(_on_eruption_started)
	_hud.build_requested.connect(_on_build_requested)
	_hud.next_wave_requested.connect(_on_next_wave_requested)
	_hud.speed_requested.connect(_set_speed)
	_hud.stress_test_requested.connect(_start_stress_test)
	_hud.upgrade_requested.connect(_on_upgrade_requested)
	_hud.branch_requested.connect(_on_branch_requested)
	_hud.sell_requested.connect(_on_sell_requested)
	_hud.target_requested.connect(_on_target_requested)
	_hud.undo_requested.connect(_on_undo_requested)
	_hud.unlock_requested.connect(_on_unlock_requested)
	_hud.difficulty_requested.connect(_on_difficulty_requested)
	_hud.spell_requested.connect(_on_spell_requested)
	_hud.loadout_requested.connect(_on_loadout_requested)
	_hud.spell_loadout_requested.connect(_on_spell_loadout_requested)
	_hud.third_spell_slot_requested.connect(_on_third_spell_slot_requested)
	_hud.pause_requested.connect(_on_pause_requested)
	_hud.auto_next_requested.connect(_on_auto_next_requested)
	_hud.settings_requested.connect(_on_settings_requested)
	_hud.world_action_requested.connect(_on_world_action_requested)
	_hud.update_requested.connect(UpdateService.open_download)
	UpdateService.update_available.connect(_on_update_available)
	_spell_system.targeting_requested.connect(_hud.set_spell_targeting)
	_spell_system.cooldown_changed.connect(_hud.set_spell_cooldown)
	_spell_system.tower_speed_multiplier_changed.connect(_on_spell_tower_speed_changed)
	_spell_system.gold_rush_changed.connect(_on_gold_rush_changed)
	EventBus.screen_tapped.connect(_on_screen_tapped)
	Settings.preferences_changed.connect(_on_preferences_changed)
	_hud.apply_preferences()
	_refresh_hud()
	_hud.set_wave_preview(_wave_director.get_preview())
	_hud.set_spell_slots(_spell_system.get_equipped())
	_hud.set_third_spell_slot_state(_spell_system.has_third_slot(), _available_skill_points())
	if not active_run.is_empty() and String(active_run.get("level_id", "")) == level_id:
		_restore_active_run(active_run)
	_update_tutorial("start")
	if UpdateService.has_update():
		_on_update_available(UpdateService.get_pending_version())
	queue_redraw()

func _on_update_available(version: String) -> void:
	_hud.show_update_available(version)
	_hud.set_hint("Update Ten Gates v%s is available. Tap UPDATE to download it." % version)

func _process(delta: float) -> void:
	if _is_paused:
		return
	_simulation_accumulator += delta * float(_speed_multiplier)
	var ticks: int = 0
	while _simulation_accumulator >= FIXED_TICK_SECONDS and ticks < MAX_TICKS_PER_FRAME:
		_simulation_accumulator -= FIXED_TICK_SECONDS
		_tick_simulation(FIXED_TICK_SECONDS)
		ticks += 1
	queue_redraw()

func _tick_simulation(delta: float) -> void:
	_enemy_manager.tick(delta)
	_status_system.tick(delta)
	_boss_controller.tick(delta)
	_world_rules.tick(delta)
	_spell_system.tick(delta)
	_projectile_pool.tick(delta, _enemy_manager)
	_apply_totem_auras()
	for tower: PrototypeTower in _towers:
		tower.tick(delta, _enemy_manager, _projectile_pool, _status_system)
	_wave_director.tick()
	if _stress_test_running and _enemy_manager.is_idle():
		_stress_test_running = false
		_hud.set_hint("Stress test complete. Record the FPS and draw calls on your Android device.")

func _on_screen_tapped(position: Vector2) -> void:
	if _spell_system.confirm_target(position):
		return
	if _stress_test_running:
		return
	for index: int in _slot_positions.size():
		if position.distance_squared_to(_slot_positions[index]) > SLOT_RADIUS * SLOT_RADIUS:
			continue
		_select_slot(index)
		return
	_clear_selection()

func _select_slot(index: int) -> void:
	_clear_selected_tower_only()
	_selected_slot = index
	if _slot_types[index] == "locked":
		_hud.show_locked_slot()
		_hud.set_hint("This slot is locked.")
		return
	if _slots_occupied[index] != 0:
		_selected_tower = _tower_by_slot[index]
		_selected_tower.set_selected(true)
		_refresh_tower_panel()
		return
	_hud.show_build_radial(_slot_positions[index], _tower_definitions, _slot_types[index])
	_hud.set_hint("%s slot selected. Choose a tower from the radial menu." % _slot_types[index].capitalize())

func _on_build_requested(tower_id: String) -> void:
	if str(_current_level.get("modifier", "")) == "tower_limited" and _towers.size() >= 8:
		_hud.set_hint("This level modifier limits you to 8 towers.")
		return
	if _selected_slot < 0 or _slots_occupied[_selected_slot] != 0 or not _tower_definitions.has(tower_id):
		return
	if _slot_types[_selected_slot] == "roadside" and tower_id != "barracks":
		_hud.set_hint("Roadside slots only accept Barracks in P2.")
		return
	var tower: PrototypeTower = PrototypeTower.new()
	tower.position = _slot_positions[_selected_slot]
	tower.configure(_tower_definitions[tower_id], _slot_types[_selected_slot])
	tower.set_skill_modifiers(_skill_modifiers)
	tower.set_world_range_multiplier(_world_rules.get_tower_range_multiplier())
	tower.set_world_element_damage_multipliers(_world_rules.get_element_damage_multipliers())
	_discover("towers", tower_id)
	if str(_current_level.get("modifier", "")) == "fog":
		tower.set_level_range_multiplier(0.85)
	var cost: int = tower.get_build_cost()
	if GameState.gold < cost:
		_hud.set_hint("Not enough gold for %s." % tower.tower_name)
		return
	add_child(tower)
	_towers.append(tower)
	_tower_by_slot[_selected_slot] = tower
	_slots_occupied[_selected_slot] = 1
	GameState.set_gold(GameState.gold - cost)
	_undo_tower = tower
	_undo_slot = _selected_slot
	_undo_deadline_ms = Time.get_ticks_msec() + UNDO_WINDOW_MS
	_selected_tower = tower
	tower.set_selected(true)
	_hud.set_hint("%s built. Undo is available for 3 seconds." % tower.tower_name)
	_update_tutorial("built")
	_refresh_tower_panel()
	_refresh_hud()

func _on_upgrade_requested() -> void:
	if _selected_tower == null:
		return
	if _selected_tower.can_choose_branch():
		_hud.show_branches(_selected_tower)
		return
	if not _selected_tower.can_upgrade():
		return
	var cost: int = _selected_tower.get_next_upgrade_cost()
	if GameState.gold < cost:
		_hud.set_hint("Not enough gold for this upgrade.")
		return
	if _selected_tower.upgrade():
		GameState.set_gold(GameState.gold - cost)
		_hud.set_hint("%s upgraded to L%d." % [_selected_tower.tower_name, _selected_tower.level])
		_refresh_tower_panel()
		_refresh_hud()

func _on_branch_requested(branch_id: String) -> void:
	if _selected_tower == null or not _selected_tower.can_choose_branch():
		return
	var cost: int = _selected_tower.get_upgrade_cost_for_level(4)
	if GameState.gold < cost:
		_hud.set_hint("Not enough gold for this branch.")
		return
	if _selected_tower.choose_branch(branch_id):
		GameState.set_gold(GameState.gold - cost)
		_hud.hide_branches()
		_hud.set_hint("%s chose %s." % [_selected_tower.tower_name, _selected_tower.get_branch_name(branch_id)])
		_refresh_tower_panel()
		_refresh_hud()

func _on_target_requested() -> void:
	if _selected_tower == null:
		return
	_selected_tower.cycle_target_mode()
	_refresh_tower_panel()

func _on_sell_requested() -> void:
	if _selected_tower == null:
		return
	var slot: int = _tower_by_slot.find(_selected_tower)
	if slot < 0:
		return
	var refund: int = _selected_tower.get_sell_refund(SELL_REFUND_NORMAL)
	refund = _selected_tower.get_sell_refund(minf(0.95, float(_difficulty.get("sell_refund", SELL_REFUND_NORMAL)) + _skill_modifiers.flat("sell_refund")))
	_sell_count += 1
	GameState.set_gold(GameState.gold + refund)
	_remove_tower(slot, _selected_tower)
	_hud.set_hint("Tower sold for %d gold." % refund)
	_clear_selection()
	_refresh_hud()

func _on_undo_requested() -> void:
	if _undo_tower == null or Time.get_ticks_msec() > _undo_deadline_ms:
		_hud.set_hint("Undo window expired.")
		return
	GameState.set_gold(GameState.gold + _undo_tower.get_build_cost())
	_remove_tower(_undo_slot, _undo_tower)
	_undo_tower = null
	_undo_slot = -1
	_hud.set_hint("Build undone. Full gold refunded.")
	_clear_selection()
	_refresh_hud()

func _on_unlock_requested() -> void:
	if _selected_slot < 0 or _slot_types[_selected_slot] != "locked":
		return
	if GameState.gold < LOCKED_SLOT_COST:
		_hud.set_hint("Not enough gold to unlock this slot.")
		return
	GameState.set_gold(GameState.gold - LOCKED_SLOT_COST)
	_slot_types[_selected_slot] = "standard"
	_hud.show_build_radial(_slot_positions[_selected_slot], _tower_definitions, "standard")
	_hud.set_hint("Slot unlocked. Choose a tower.")
	_refresh_hud()

func _remove_tower(slot: int, tower: PrototypeTower) -> void:
	_towers.erase(tower)
	_tower_by_slot[slot] = null
	_slots_occupied[slot] = 0
	if is_instance_valid(tower):
		tower.queue_free()

func _clear_selected_tower_only() -> void:
	if _selected_tower != null and is_instance_valid(_selected_tower):
		_selected_tower.set_selected(false)
	_selected_tower = null

func _clear_selection() -> void:
	_clear_selected_tower_only()
	_selected_slot = -1
	_hud.hide_selection()

func _refresh_tower_panel() -> void:
	if _selected_tower == null:
		return
	var undo_available: bool = _selected_tower == _undo_tower and Time.get_ticks_msec() <= _undo_deadline_ms
	_hud.show_tower(_selected_tower, _selected_tower.get_sell_refund(SELL_REFUND_NORMAL), undo_available, false)

func _on_next_wave_requested() -> void:
	if _stress_test_running:
		_hud.set_hint("Stress test is running at 3×.")
		return
	if not _wave_director.start_next_wave():
		_hud.set_hint("The current wave is still active, or the prototype level is complete.")

func _on_difficulty_requested() -> void:
	var order: PackedStringArray = PackedStringArray(["easy", "normal", "hard"])
	var next_index: int = (order.find(_difficulty_id) + 1) % order.size()
	set_difficulty(order[next_index])
	_hud.set_hint("Mode set to %s. Restart the scene before starting a wave to apply all starting values." % _difficulty_id.capitalize())

func _on_spell_requested(spell_id: String) -> void:
	if not _spell_system.request_cast(spell_id):
		_hud.set_hint("Spell is cooling down or not equipped.")

func _on_spell_tower_speed_changed(multiplier: float) -> void:
	for tower: PrototypeTower in _towers:
		tower.set_spell_attack_speed_multiplier(multiplier)

func _on_gold_rush_changed(multiplier: float) -> void:
	_gold_rush_multiplier = multiplier

func _on_loadout_requested() -> void:
	var unlocked: Array[String] = ["archer", "cannon", "barracks", "ice", "arcane"]
	var borrowed: Array[String] = ["skyfang"]
	var effective: Array[String] = _loadout_manager.effective_loadout(4, unlocked, unlocked, borrowed)
	_hud.show_loadout(4, effective, LoadoutManager.MAX_TOWERS, borrowed)

func _on_spell_loadout_requested(spell_id: String) -> void:
	var equipped: Array[String] = _spell_system.get_equipped()
	if equipped.has(spell_id):
		equipped.erase(spell_id)
	elif equipped.size() < _spell_system.get_max_slots():
		equipped.append(spell_id)
	else:
		_hud.set_hint("Choose at most two spells until the third spell slot is unlocked.")
		return
	if equipped.is_empty():
		_hud.set_hint("Keep at least one spell equipped.")
		return
	_spell_system.equip_spells(equipped)
	_hud.set_spell_slots(_spell_system.get_equipped())

func _on_third_spell_slot_requested() -> void:
	if _spell_system.has_third_slot():
		return
	_hud.set_hint("Unlock Arcana's Slot Ketiga keystone in the Skill Tree (Tier III).")

func _set_speed(multiplier: int) -> void:
	_speed_multiplier = clampi(multiplier, 1, 3)
	_refresh_hud()

func _start_stress_test() -> void:
	_clear_selection()
	_enemy_manager.reset()
	_projectile_pool.reset()
	_stress_test_running = true
	_speed_multiplier = 3
	_enemy_manager.queue_spawn("swarmling", 200, 0.04)
	_hud.set_hint("Stress test: 200 Swarmling queued at 3×. Build towers before starting to exercise upgrades.")
	_refresh_hud()

func _on_enemy_defeated(bounty: int) -> void:
	if str(_current_level.get("modifier", "")) != "gold_scarce":
		GameState.set_gold(GameState.gold + roundi(float(bounty) * _gold_rush_multiplier * _skill_modifiers.multiplier("bounty")))
	_refresh_hud()

func _on_enemy_spawned(enemy_id: String) -> void:
	_discover("enemies", enemy_id)

func _on_enemy_damaged(_position: Vector2, _damage: float) -> void:
	_feedback.hit_flash()

func _on_boss_telegraph(_position: Vector2, _radius: float, _duration: float, label: String) -> void:
	_feedback.boss_shake()
	_hud.set_hint("Warning: %s" % label)

func _on_enemy_leaked_detail(enemy_id: String, _weight: int) -> void:
	_leak_causes[enemy_id] = int(_leak_causes.get(enemy_id, 0)) + 1

func _on_enemy_leaked(weight: int) -> void:
	if _spell_system.consume_barrier():
		_hud.set_hint("Holy Barrier prevented a leak.")
		return
	_leaks += 1
	GameState.set_base_hp(GameState.base_hp - weight)
	_refresh_hud()
	if GameState.base_hp <= 0:
		_enemy_manager.reset()
		_projectile_pool.reset()
		_hud.set_hint("Base destroyed. Reload the scene to restart the prototype.")
		_hud.show_defeat(_build_defeat_summary())

func _on_tower_weaken_requested(position: Vector2, multiplier: float, duration: float) -> void:
	var target: PrototypeTower = _nearest_tower(position)
	if target != null:
		target.apply_attack_speed_debuff(multiplier, duration)

func _on_tower_disable_requested(position: Vector2, duration: float) -> void:
	var target: PrototypeTower = _nearest_tower(position)
	if target != null:
		target.disable_for(duration)

func _on_tower_disable_radius_requested(position: Vector2, radius: float, duration: float) -> void:
	for tower: PrototypeTower in _towers:
		if tower.global_position.distance_squared_to(position) <= radius * radius:
			tower.disable_for(duration)

func _on_tower_damage_weaken_requested(position: Vector2, multiplier: float, duration: float) -> void:
	var target: PrototypeTower = _nearest_tower(position)
	if target != null:
		target.apply_damage_debuff(multiplier, duration)

func _on_tower_farthest_disable_requested(position: Vector2, duration: float) -> void:
	var target: PrototypeTower
	var farthest_distance: float = -1.0
	for tower: PrototypeTower in _towers:
		var distance: float = tower.global_position.distance_squared_to(position)
		if distance > farthest_distance:
			farthest_distance = distance
			target = tower
	if target != null:
		target.disable_for(duration)

func _on_tower_random_disable_requested(count: int, duration: float) -> void:
	for index: int in mini(count, _towers.size()):
		_towers[index].disable_for(duration)

func _on_tower_support_disable_requested(position: Vector2, duration: float) -> void:
	var nearest_totem: PrototypeTower
	var best_distance: float = INF
	for tower: PrototypeTower in _towers:
		if tower.tower_id == "war_totem" and tower.global_position.distance_squared_to(position) < best_distance:
			best_distance = tower.global_position.distance_squared_to(position)
			nearest_totem = tower
	if nearest_totem != null:
		nearest_totem.disable_support_for(duration)

func _nearest_tower(position: Vector2) -> PrototypeTower:
	var result: PrototypeTower
	var best_distance: float = INF
	for tower: PrototypeTower in _towers:
		var distance: float = tower.global_position.distance_squared_to(position)
		if distance < best_distance:
			best_distance = distance
			result = tower
	return result

func _on_wave_started(number: int) -> void:
	_apply_sky_island_shift(number)
	_apply_void_portal_pair(number)
	GameState.set_current_wave(number)
	SaveManager.set_active_run(_build_active_run_snapshot(number))
	_hud.set_hint("Wave %d started." % number)
	_hud.set_wave_preview(_wave_director.get_preview())
	_update_tutorial("wave")
	_refresh_hud()

func _on_boss_requested(boss_id: String) -> void:
	_boss_controller.start_encounter(boss_id, _difficulty_id == "hard")

func _on_world_range_multiplier_changed(multiplier: float) -> void:
	for tower: PrototypeTower in _towers:
		tower.set_world_range_multiplier(multiplier)

func _on_world_element_damage_multipliers_changed(multipliers: Dictionary) -> void:
	for tower: PrototypeTower in _towers:
		tower.set_world_element_damage_multipliers(multipliers)

func _on_eruption_started(slot_indexes: Array, duration: float) -> void:
	for raw_slot: Variant in slot_indexes:
		var slot_index: int = int(raw_slot)
		if slot_index >= 0 and slot_index < _tower_by_slot.size() and _tower_by_slot[slot_index] != null:
			_tower_by_slot[slot_index].disable_for(duration)

func _on_world_path_changed(points: PackedVector2Array) -> void:
	_path_points = points
	_enemy_manager.set_path(_path_points)

func _on_world_action_requested() -> void:
	if not _world_rules.toggle_bridge():
		_hud.set_hint("Bridge lever is cooling down.")

func _on_wave_completed(number: int) -> void:
	var coin_bonus: int = 0
	for tower: PrototypeTower in _towers:
		coin_bonus += tower.get_wave_gold_bonus()
	if coin_bonus > 0:
		GameState.set_gold(GameState.gold + coin_bonus)
	_hud.set_hint("Wave %d cleared. Build or press NEXT WAVE." % number)
	_hud.set_wave_preview(_wave_director.get_preview())
	if _auto_next:
		call_deferred("_on_next_wave_requested")

func _on_level_completed() -> void:
	var result: Dictionary = {
		"won": true,
		"base_hp_ratio": float(GameState.base_hp) / float(maxi(1, _level_start_base_hp)),
		"leaks": _leaks,
		"tower_count": _towers.size(),
		"tower_ids": _tower_ids(),
		"active_skill_uses": 0,
		"sell_count": _sell_count
	}
	var stars: int = _star_progress.evaluate(result, _difficulty, Dictionary(_current_level.get("challenge", {})))
	var level_parts: PackedStringArray = String(_current_level.get("level_id", "1-1")).split("-")
	var world: int = int(level_parts[0]) if level_parts.size() == 2 else 1
	var level: int = int(level_parts[1]) if level_parts.size() == 2 else 1
	var new_sp: int = _campaign.record_result(world, level, _difficulty_id, stars)
	SaveManager.set_section("campaign", _campaign.to_data(), false)
	SaveManager.set_section("skill_tree", _skill_tree.to_data(), false)
	SaveManager.clear_active_run()
	_hud.set_third_spell_slot_state(_spell_system.has_third_slot(), _available_skill_points())
	_hud.set_hint("Level clear: %d stars, +%d SP (total %d)." % [stars, new_sp, _campaign.get_total_skill_points()])
	_hud.show_result(stars, new_sp, _campaign.get_total_skill_points())
	_hud.set_tutorial("", false)

func _refresh_hud() -> void:
	_hud.set_status(GameState.base_hp, GameState.gold, GameState.current_wave, _speed_multiplier)

func set_difficulty(difficulty_id: String) -> void:
	if not _difficulties.has(difficulty_id):
		return
	_difficulty_id = difficulty_id
	_difficulty = Dictionary(_difficulties[difficulty_id])
	_enemy_manager.set_difficulty(_difficulty)
	_wave_director.set_difficulty(_difficulty)
	_spell_system.set_difficulty(_difficulty)
	if _hud != null:
		_hud.set_difficulty_label(_difficulty_id)

func _refresh_skill_modifiers() -> void:
	_skill_modifiers = _skill_tree.build_modifier_stack()
	_spell_system.set_skill_modifiers(_skill_modifiers)

func _available_skill_points() -> int:
	return maxi(0, _campaign.get_total_skill_points() - _skill_tree.spent_total())

func _on_pause_requested() -> void:
	_is_paused = not _is_paused
	_hud.set_paused(_is_paused)
	_hud.set_hint("Game paused." if _is_paused else "Game resumed.")

func _on_auto_next_requested(enabled: bool) -> void:
	_auto_next = enabled
	_hud.set_hint("Auto-next %s." % ("enabled" if enabled else "disabled"))

func _on_settings_requested() -> void:
	_hud.toggle_settings()

func _on_preferences_changed() -> void:
	_hud.apply_preferences()

func _discover(category: String, entry_id: String) -> void:
	if _codex.discover(category, entry_id):
		SaveManager.set_section("codex", _codex.to_data())

func _update_tutorial(event_name: String) -> void:
	if String(_current_level.get("level_id", "")) == "1-1":
		match event_name:
			"start": _hud.set_tutorial("Tutorial: tap an empty build slot and choose a tower.", true)
			"built": _hud.set_tutorial("Tutorial: press NEXT WAVE when you are ready.", true)
			"wave": _hud.set_tutorial("Tutorial: upgrade during a wave and use spells from the lower corner.", true)
			_: _hud.set_tutorial("", false)
	elif String(_current_level.get("level_id", "")) in ["1-2", "1-3"]:
		_hud.set_tutorial("Tutorial: inspect the wave preview and adapt your tower choices.", true)
	else:
		_hud.set_tutorial("", false)

func _build_defeat_summary() -> String:
	var worst_enemy: String = "unknown enemies"
	var worst_count: int = 0
	for enemy_id: String in _leak_causes.keys():
		if int(_leak_causes[enemy_id]) > worst_count:
			worst_enemy = enemy_id.capitalize()
			worst_count = int(_leak_causes[enemy_id])
	var suggestion: String = "Try a balanced mix of single-target and area damage."
	if worst_enemy.to_lower().contains("runner") or worst_enemy.to_lower().contains("swarmling"):
		suggestion = "Use Ice Tower or Barracks to slow fast enemies."
	elif worst_enemy.to_lower().contains("brute"):
		suggestion = "Use Arcane Tower against tough armored enemies."
	return "Most leaks: %s (%d).\n%s\nYou may retry on Easy without changing Hard progress." % [worst_enemy, worst_count, suggestion]

func _apply_world_rule(level: Dictionary) -> void:
	_world_rules.configure(level)
	_world_rules.set_default_path(_path_points)
	_enemy_manager.set_world_speed_multiplier(_world_rules.get_enemy_speed_multiplier())
	_enemy_manager.set_world_regen_percent(_world_rules.get_enemy_regen_percent())
	_enemy_manager.set_world_air_speed_multiplier(_world_rules.get_air_speed_multiplier())
	_hud.set_world_action(_world_rules.get_world_action_label(), _world_rules.has_bridge_lever())
	for slot_index: int in Array(level.get("oasis_slots", [])):
		if slot_index >= 0 and slot_index < _slot_types.size():
			_slot_types[slot_index] = "rune"

func _apply_level_layout(level: Dictionary) -> void:
	var path: String = String(level.get("layout_data", ""))
	if path.is_empty():
		return
	var layout: Dictionary = _level_loader.load_json(path)
	var points: PackedVector2Array = PackedVector2Array()
	for raw_point: Array in Array(layout.get("path", [])):
		if raw_point.size() == 2:
			points.append(Vector2(float(raw_point[0]), float(raw_point[1])))
	var positions: PackedVector2Array = PackedVector2Array()
	var types: PackedStringArray = PackedStringArray()
	for slot: Dictionary in Array(layout.get("slots", [])):
		positions.append(Vector2(float(slot.get("x", 0.0)), float(slot.get("y", 0.0))))
		types.append(String(slot.get("type", "standard")))
	if points.size() >= 2 and positions.size() > 0:
		_path_points = points
		_slot_positions = positions
		_layout_slot_positions = positions.duplicate()
		_slot_types = types

func _apply_sky_island_shift(wave_number: int) -> void:
	if _layout_slot_positions.is_empty():
		return
	var offset: Vector2 = _world_rules.get_sky_slot_offset(wave_number)
	if offset == Vector2.ZERO and wave_number < 4:
		return
	for slot: int in _layout_slot_positions.size():
		_slot_positions[slot] = _layout_slot_positions[slot] + offset
		if slot < _tower_by_slot.size() and _tower_by_slot[slot] != null:
			_tower_by_slot[slot].position = _slot_positions[slot]
	_hud.set_hint("Floating islands shifted; towers moved with their slots.")

func _apply_void_portal_pair(wave_number: int) -> void:
	var pair: Array = _world_rules.get_portal_pair(wave_number)
	if pair.size() != 2:
		return
	_enemy_manager.set_portal_pair(pair[0], pair[1])
	_hud.set_hint("Void portals shifted; enemies will emerge farther along the path.")

func _apply_totem_auras() -> void:
	for tower: PrototypeTower in _towers:
		tower.set_support_multipliers(1.0, 1.0)
	for totem: PrototypeTower in _towers:
		if totem.tower_id != "war_totem" or not totem.is_support_active():
			continue
		var stats: Dictionary = totem._current_stats()
		var aura_range: float = float(stats.get("aura_radius", 0.0))
		if aura_range <= 0.0:
			continue
		for tower: PrototypeTower in _towers:
			if tower != totem and tower.global_position.distance_squared_to(totem.global_position) <= aura_range * aura_range:
				tower.set_support_multipliers(float(stats.get("aura_range_multiplier", 1.0)), float(stats.get("aura_attack_speed_multiplier", 1.0)))
		if bool(stats.get("reveal_stealth", false)):
			_enemy_manager.reveal_stealth_nearby(totem.global_position, aura_range)

func _build_active_run_snapshot(wave_number: int) -> Dictionary:
	var towers: Array[Dictionary] = []
	for slot: int in _tower_by_slot.size():
		var tower: PrototypeTower = _tower_by_slot[slot]
		if tower != null:
			towers.append({"slot": slot, "tower_id": tower.tower_id, "level": tower.level, "branch": tower.branch, "invested_cost": tower.invested_cost})
	return {"level_id": _current_level.get("level_id", "1-1"), "difficulty": _difficulty_id, "wave": wave_number, "gold": GameState.gold, "base_hp": GameState.base_hp, "towers": towers}

func _restore_active_run(snapshot: Dictionary) -> void:
	set_difficulty(String(snapshot.get("difficulty", _difficulty_id)))
	GameState.set_gold(int(snapshot.get("gold", GameState.gold)))
	GameState.set_base_hp(int(snapshot.get("base_hp", GameState.base_hp)))
	for saved: Dictionary in Array(snapshot.get("towers", [])):
		var slot: int = int(saved.get("slot", -1))
		var tower_id: String = String(saved.get("tower_id", ""))
		if slot < 0 or slot >= _slot_positions.size() or not _tower_definitions.has(tower_id):
			continue
		var tower: PrototypeTower = PrototypeTower.new()
		tower.position = _slot_positions[slot]
		tower.configure(_tower_definitions[tower_id], _slot_types[slot])
		tower.restore_state(int(saved.get("level", 1)), String(saved.get("branch", "")), int(saved.get("invested_cost", tower.get_build_cost())))
		tower.set_skill_modifiers(_skill_modifiers)
		tower.set_world_range_multiplier(_world_rules.get_tower_range_multiplier())
		tower.set_world_element_damage_multipliers(_world_rules.get_element_damage_multipliers())
		add_child(tower)
		_towers.append(tower)
		_tower_by_slot[slot] = tower
		_slots_occupied[slot] = 1
	_wave_director.restore_at_wave(int(snapshot.get("wave", 1)))
	GameState.set_current_wave(int(snapshot.get("wave", 1)))
	_hud.set_hint("Saved run restored. Press NEXT WAVE to replay wave %d." % int(snapshot.get("wave", 1)))

func _tower_ids() -> Array[String]:
	var ids: Array[String] = []
	for tower: PrototypeTower in _towers:
		ids.append(tower.tower_id)
	return ids

func _load_tower_data() -> void:
	for path: String in [
		"res://data/towers/archer.json", "res://data/towers/cannon.json", "res://data/towers/barracks.json",
		"res://data/towers/ice.json", "res://data/towers/arcane.json", "res://data/towers/poison_lab.json", "res://data/towers/tesla.json", "res://data/towers/skyfang.json", "res://data/towers/coin_tower.json", "res://data/towers/ballista.json", "res://data/towers/fire_tower.json", "res://data/towers/mechanic_workshop.json", "res://data/towers/war_totem.json", "res://data/towers/void_tower.json"
	]:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Could not load tower data: %s" % path)
			continue
		var json: JSON = JSON.new()
		if json.parse(file.get_as_text()) != OK:
			push_error("Invalid tower JSON: %s" % path)
			continue
		var tower: Dictionary = json.data
		_tower_definitions[String(tower["id"])] = tower

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1920.0, 1080.0), Color("#31513b"))
	for row: int in 6:
		for column: int in 10:
			draw_texture_rect_region(TERRAIN_TEXTURE, Rect2(column * 192.0, row * 192.0, 194.0, 194.0), Rect2(0.0, 0.0, 192.0, 192.0), Color.WHITE)
	for position: Vector2 in [Vector2(118.0, 176.0), Vector2(1060.0, 118.0), Vector2(1550.0, 900.0)]:
		draw_texture_rect_region(BUSH_TEXTURE, Rect2(position, Vector2(74.0, 42.0)), Rect2(0.0, 0.0, 128.0, 128.0), Color.WHITE)
	for position: Vector2 in [Vector2(1630.0, 100.0), Vector2(185.0, 815.0)]:
		draw_texture_rect_region(TREE_TEXTURE, Rect2(position, Vector2(104.0, 86.0)), Rect2(0.0, 0.0, 256.0, 256.0), Color.WHITE)
	for index: int in range(_path_points.size() - 1):
		draw_line(_path_points[index], _path_points[index + 1], Color("#4a3424"), 82.0, true)
		draw_line(_path_points[index], _path_points[index + 1], Color("#9a7750"), 64.0, true)
	if _stress_test_running:
		return
	for index: int in _slot_positions.size():
		var color: Color = _slot_color(index)
		draw_circle(_slot_positions[index], SLOT_RADIUS, color)
		if _slot_types[index] == "locked":
			draw_string(ThemeDB.fallback_font, _slot_positions[index] + Vector2(-12, 7), "🔒", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color.WHITE)

func _slot_color(index: int) -> Color:
	if _world_rules.is_eruption_active() and _world_rules.get_eruption_slots().has(index):
		return Color(0.88, 0.12, 0.06, 0.96)
	if _slot_types[index] == "locked":
		return Color(0.28, 0.18, 0.20, 0.9)
	if _slots_occupied[index] != 0:
		return Color(0.11, 0.18, 0.18, 0.65)
	if index == _selected_slot:
		return Color(0.83, 0.77, 0.26, 0.95)
	match _slot_types[index]:
		"highland": return Color(0.28, 0.46, 0.37, 0.9)
		"rune": return Color(0.30, 0.25, 0.55, 0.9)
		"roadside": return Color(0.38, 0.32, 0.20, 0.9)
		_: return Color(0.21, 0.42, 0.32, 0.82)

