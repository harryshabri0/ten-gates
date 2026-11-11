class_name PrototypeHud
extends CanvasLayer

signal build_requested(tower_id: String)
signal next_wave_requested()
signal speed_requested(multiplier: int)
signal stress_test_requested()
signal upgrade_requested()
signal branch_requested(branch_id: String)
signal sell_requested()
signal target_requested()
signal undo_requested()
signal unlock_requested()
signal difficulty_requested()
signal spell_requested(spell_id: String)
signal loadout_requested()
signal spell_loadout_requested(spell_id: String)
signal third_spell_slot_requested()
signal pause_requested()
signal auto_next_requested(enabled: bool)
signal settings_requested()
signal world_action_requested()
signal update_requested()

@onready var _status: Label = $TopBar/Status
@onready var _hint: Label = $BottomBar/Hint
@onready var _radial: Control = $BuildRadial
@onready var _tower_panel: Panel = $TowerPanel
@onready var _branch_panel: Panel = $BranchPanel
var _auto_next_enabled: bool = false
var _sell_hold_timer: Timer
var _update_button: Button

func _ready() -> void:
	for tower_id: String in ["archer", "cannon", "barracks", "ice", "arcane", "poison_lab", "tesla", "skyfang", "coin_tower", "ballista", "fire_tower", "mechanic_workshop", "war_totem", "void_tower"]:
		get_node("BuildRadial/%s" % _tower_node_name(tower_id)).pressed.connect(func() -> void: build_requested.emit(tower_id))
	$TopBar/NextWave.pressed.connect(func() -> void: next_wave_requested.emit())
	$TopBar/Speed1.pressed.connect(func() -> void: speed_requested.emit(1))
	$TopBar/Speed2.pressed.connect(func() -> void: speed_requested.emit(2))
	$TopBar/Speed3.pressed.connect(func() -> void: speed_requested.emit(3))
	$TopBar/Stress.pressed.connect(func() -> void: stress_test_requested.emit())
	$TopBar/Mode.pressed.connect(func() -> void: difficulty_requested.emit())
	$TopBar/Pause.pressed.connect(func() -> void: pause_requested.emit())
	$TopBar/AutoNext.pressed.connect(_toggle_auto_next)
	$TopBar/Settings.pressed.connect(func() -> void: settings_requested.emit())
	$WorldAction.pressed.connect(func() -> void: world_action_requested.emit())
	_update_button = Button.new()
	_update_button.name = "UpdateAvailable"
	_update_button.position = Vector2(1450.0, 112.0)
	_update_button.size = Vector2(340.0, 54.0)
	_update_button.hide()
	add_child(_update_button)
	_update_button.pressed.connect(func() -> void: update_requested.emit())
	$SpellPanel/Spell1.pressed.connect(func() -> void: spell_requested.emit(String($SpellPanel/Spell1.get_meta("spell_id"))))
	$SpellPanel/Spell2.pressed.connect(func() -> void: spell_requested.emit(String($SpellPanel/Spell2.get_meta("spell_id"))))
	$SpellPanel/Spell3.pressed.connect(func() -> void: spell_requested.emit(String($SpellPanel/Spell3.get_meta("spell_id"))))
	$SpellPanel/Loadout.pressed.connect(func() -> void: loadout_requested.emit())
	$LoadoutPanel/Close.pressed.connect(func() -> void: $LoadoutPanel.hide())
	$LoadoutPanel/UnlockThirdSlot.pressed.connect(func() -> void: third_spell_slot_requested.emit())
	for spell_id: String in ["meteor_shower", "time_freeze", "reinforcements", "overcharge", "gold_rush", "holy_barrier"]:
		get_node("LoadoutPanel/%s" % _spell_node_name(spell_id)).pressed.connect(func() -> void: spell_loadout_requested.emit(spell_id))
	$TowerPanel/Upgrade.pressed.connect(func() -> void: upgrade_requested.emit())
	$TowerPanel/Target.pressed.connect(func() -> void: target_requested.emit())
	_sell_hold_timer = Timer.new()
	_sell_hold_timer.one_shot = true
	_sell_hold_timer.wait_time = 0.5
	add_child(_sell_hold_timer)
	_sell_hold_timer.timeout.connect(func() -> void: sell_requested.emit())
	$TowerPanel/Sell.button_down.connect(func() -> void: _sell_hold_timer.start())
	$TowerPanel/Sell.button_up.connect(func() -> void: _sell_hold_timer.stop())
	$TowerPanel/Undo.pressed.connect(func() -> void: undo_requested.emit())
	$TowerPanel/Unlock.pressed.connect(func() -> void: unlock_requested.emit())
	$BranchPanel/BranchA.pressed.connect(func() -> void: branch_requested.emit("A"))
	$BranchPanel/BranchB.pressed.connect(func() -> void: branch_requested.emit("B"))
	_radial.hide()
	_tower_panel.hide()
	_branch_panel.hide()
	$LoadoutPanel.hide()
	$ResultPanel.hide()
	$DefeatPanel.hide()
	$WorldAction.hide()
	set_hint("Tap an empty build slot, then choose a tower.")

func set_status(base_hp: int, gold: int, wave: int, speed: int) -> void:
	_status.text = "BASE %d HP   •   GOLD %d   •   WAVE %d   •   %dx" % [base_hp, gold, wave, speed]

func set_hint(message: String) -> void:
	_hint.text = message

func show_update_available(version: String) -> void:
	_update_button.text = "UPDATE v%s AVAILABLE" % version
	_update_button.tooltip_text = "Download the latest Ten Gates APK"
	_update_button.show()

func set_difficulty_label(difficulty_id: String) -> void:
	$TopBar/Mode.text = difficulty_id.capitalize()

func set_wave_preview(entries: Array[String]) -> void:
	$WavePreview.text = "NEXT: " + ("  •  ".join(entries) if not entries.is_empty() else "Final wave complete")

func set_paused(value: bool) -> void:
	$TopBar/Pause.text = "RESUME" if value else "PAUSE"

func apply_preferences() -> void:
	$SpellPanel.position.x = 50.0 if Settings.left_handed else 1550.0
	$TopBar/Status.add_theme_font_size_override("font_size", roundi(22.0 * Settings.font_scale))
	$BottomBar/Hint.add_theme_font_size_override("font_size", roundi(18.0 * Settings.font_scale))
	$WavePreview.add_theme_font_size_override("font_size", roundi(18.0 * Settings.font_scale))
	$TopBar.modulate = Color(1.0, 0.94, 0.66) if Settings.colorblind_mode else Color.WHITE

func show_result(stars: int, gained_sp: int, total_sp: int) -> void:
	$ResultPanel/Details.text = "%s\n+%d Skill Points • %d total" % ["★".repeat(stars), gained_sp, total_sp]
	$ResultPanel.show()

func show_defeat(summary: String) -> void:
	$DefeatPanel/Details.text = summary
	$DefeatPanel.show()

func set_tutorial(message: String, visible: bool) -> void:
	$Tutorial.text = message
	$Tutorial.visible = visible

func set_world_action(label: String, visible: bool) -> void:
	$WorldAction.text = label
	$WorldAction.visible = visible

func toggle_settings() -> void:
	$SettingsPanel.open_panel()

func set_spell_slots(spell_ids: Array[String]) -> void:
	var buttons: Array[Button] = [$SpellPanel/Spell1, $SpellPanel/Spell2, $SpellPanel/Spell3]
	for index: int in buttons.size():
		var button: Button = buttons[index]
		if index < spell_ids.size():
			button.show()
			button.set_meta("spell_id", spell_ids[index])
			button.text = spell_ids[index].replace("_", " ").capitalize()
		else:
			button.hide()
	for spell_id: String in ["meteor_shower", "time_freeze", "reinforcements", "overcharge", "gold_rush", "holy_barrier"]:
		var choice: Button = get_node("LoadoutPanel/%s" % _spell_node_name(spell_id))
		choice.text = ("✓ " if spell_ids.has(spell_id) else "") + spell_id.replace("_", " ").capitalize()

func set_spell_cooldown(spell_id: String, remaining: float) -> void:
	for button: Button in [$SpellPanel/Spell1, $SpellPanel/Spell2, $SpellPanel/Spell3]:
		if String(button.get_meta("spell_id", "")) == spell_id:
			var label: String = spell_id.replace("_", " ").capitalize()
			button.text = "%s%s" % [label, " %.0fs" % ceilf(remaining) if remaining > 0.0 else ""]

func show_loadout(world: int, towers: Array[String], maximum: int, borrowed: Array[String]) -> void:
	$LoadoutPanel/Title.text = "World %d Tower Loadout" % world
	$LoadoutPanel/TowerSummary.text = "Selected: %s\nMaximum %d towers%s" % [", ".join(towers), maximum, " • borrowed: %s" % ", ".join(borrowed) if not borrowed.is_empty() else ""]
	$LoadoutPanel.show()

func set_third_spell_slot_state(unlocked: bool, skill_points: int) -> void:
	$LoadoutPanel/UnlockThirdSlot.disabled = unlocked
	$LoadoutPanel/UnlockThirdSlot.text = "Third spell slot unlocked" if unlocked else "Unlock Arcana Tier III: Slot Ketiga"

func _spell_node_name(spell_id: String) -> String:
	return "Spell_%s" % spell_id

func _tower_node_name(tower_id: String) -> String:
	match tower_id:
		"poison_lab": return "PoisonLab"
		"coin_tower": return "CoinTower"
		"fire_tower": return "FireTower"
		"mechanic_workshop": return "MechanicWorkshop"
		"war_totem": return "WarTotem"
		"void_tower": return "VoidTower"
		_: return tower_id.capitalize()

func set_spell_targeting(spell_id: String) -> void:
	set_hint("Tap the map to target %s." % spell_id.replace("_", " ").capitalize())

func show_build_radial(world_position: Vector2, definitions: Dictionary, slot_type: String) -> void:
	_tower_panel.hide()
	_branch_panel.hide()
	_radial.position = world_position - Vector2(155.0, 155.0)
	_radial.show()
	for tower_id: String in ["archer", "cannon", "barracks", "ice", "arcane", "poison_lab", "tesla", "skyfang", "coin_tower", "ballista", "fire_tower", "mechanic_workshop", "war_totem", "void_tower"]:
		var button: Button = get_node("BuildRadial/%s" % _tower_node_name(tower_id))
		var definition: Dictionary = definitions[tower_id]
		button.text = "%s\n%d" % [String(definition["name"]), int(definition["base_cost"])]
		button.disabled = slot_type == "roadside" and tower_id != "barracks"

func hide_selection() -> void:
	_radial.hide()
	_tower_panel.hide()
	_branch_panel.hide()

func show_tower(tower: PrototypeTower, refund: int, undo_available: bool, is_locked: bool) -> void:
	_radial.hide()
	_branch_panel.hide()
	_tower_panel.show()
	if is_locked:
		$TowerPanel/Title.text = "Locked slot"
		$TowerPanel/Stats.text = "Pay 75 gold to unlock this slot."
		$TowerPanel/Upgrade.hide()
		$TowerPanel/Target.hide()
		$TowerPanel/Sell.hide()
		$TowerPanel/Undo.hide()
		$TowerPanel/Unlock.show()
		return
	$TowerPanel/Unlock.hide()
	$TowerPanel/Upgrade.show()
	$TowerPanel/Upgrade.disabled = false
	$TowerPanel/Target.show()
	$TowerPanel/Sell.show()
	$TowerPanel/Undo.visible = undo_available
	var stats: Dictionary = tower.get_display_stats()
	$TowerPanel/Title.text = "%s  L%d %s" % [tower.tower_name, tower.level, tower.get_branch_name(tower.branch) if not tower.branch.is_empty() else ""]
	$TowerPanel/Stats.text = "DMG %.0f  •  RNG %.0f  •  %.2fs\nTarget: %s" % [float(stats["damage"]), float(stats["range"]), float(stats["interval"]), tower.get_target_mode_name()]
	if tower.can_choose_branch():
		$TowerPanel/Upgrade.text = "Choose branch"
	elif tower.can_upgrade():
		$TowerPanel/Upgrade.text = "Upgrade • %d" % tower.get_next_upgrade_cost()
	else:
		$TowerPanel/Upgrade.text = "MAX LEVEL"
		$TowerPanel/Upgrade.disabled = true
	$TowerPanel/Sell.text = "Sell • %d" % refund
	$TowerPanel/Sell.tooltip_text = "Hold for 0.5 seconds to sell"

func show_locked_slot() -> void:
	_radial.hide()
	_branch_panel.hide()
	_tower_panel.show()
	$TowerPanel/Title.text = "Locked slot"
	$TowerPanel/Stats.text = "Pay 75 gold to unlock this slot."
	$TowerPanel/Upgrade.hide()
	$TowerPanel/Target.hide()
	$TowerPanel/Sell.hide()
	$TowerPanel/Undo.hide()
	$TowerPanel/Unlock.show()

func show_branches(tower: PrototypeTower) -> void:
	_branch_panel.show()
	var branches: Dictionary = tower.definition["branches"]
	$BranchPanel/BranchA.text = "%s\nL4 cost %d" % [String(branches["A"]["name"]), tower.get_upgrade_cost_for_level(4)]
	$BranchPanel/BranchB.text = "%s\nL4 cost %d" % [String(branches["B"]["name"]), tower.get_upgrade_cost_for_level(4)]

func hide_branches() -> void:
	_branch_panel.hide()

func _toggle_auto_next() -> void:
	_auto_next_enabled = not _auto_next_enabled
	$TopBar/AutoNext.text = "AUTO: ON" if _auto_next_enabled else "AUTO: OFF"
	auto_next_requested.emit(_auto_next_enabled)

