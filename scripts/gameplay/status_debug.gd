extends CanvasLayer
## Manual P3 scene: spawn one enemy, then use the buttons to apply every status/reaction.

@onready var _game: Node = get_parent().get_node("GameRoot")
@onready var _enemy_manager: PrototypeEnemyManager = _game.get_node("EnemyManager")
@onready var _status_system: PrototypeStatusSystem = _game.get_node("StatusSystem")

var _target_index: int = 0
var _summary: Label

func _ready() -> void:
	_enemy_manager.queue_spawn("grunt", 1, 0.03)
	var panel := Panel.new()
	panel.position = Vector2(1420, 150)
	panel.size = Vector2(470, 620)
	add_child(panel)
	var title := Label.new()
	title.position = Vector2(18, 16)
	title.text = "P3 Status Debug\nSpawned Grunt = target 0"
	title.add_theme_font_size_override("font_size", 22)
	panel.add_child(title)
	var list := VBoxContainer.new()
	list.position = Vector2(18, 90)
	list.size = Vector2(434, 390)
	panel.add_child(list)
	for status_id: String in ["burn", "poison", "slow", "freeze", "stun", "mark", "armor_break", "weaken", "root"]:
		var button := Button.new()
		button.text = "Apply %s" % status_id
		button.pressed.connect(_apply_status.bind(status_id))
		list.add_child(button)
	for reaction_id: String in ["Shatter", "Toxic Blast", "Overload", "Corrode", "Thermal Shock"]:
		var button := Button.new()
		button.text = "Trigger %s" % reaction_id
		button.pressed.connect(_trigger_reaction.bind(reaction_id))
		list.add_child(button)
	var elite := Button.new()
	elite.position = Vector2(18, 500)
	elite.size = Vector2(205, 45)
	elite.text = "Mark target Elite"
	elite.pressed.connect(_mark_elite)
	panel.add_child(elite)
	_summary = Label.new()
	_summary.position = Vector2(18, 552)
	_summary.size = Vector2(434, 55)
	panel.add_child(_summary)

func _process(_delta: float) -> void:
	if _enemy_manager.is_enemy_active(_target_index):
		_summary.text = "Active: %s\nStatus tick: %.3f ms" % [_status_system.get_status_summary(_target_index), _status_system.last_tick_ms]
	else:
		_summary.text = "Waiting for target spawn…"

func _apply_status(status_id: String) -> void:
	match status_id:
		"burn": _status_system.apply_status(_target_index, status_id, 6.0, 1.0)
		"poison": _status_system.apply_status(_target_index, status_id, 8.0, 1.0)
		"slow": _status_system.apply_status(_target_index, status_id, 4.0, 0.55)
		"freeze", "stun", "root": _status_system.apply_status(_target_index, status_id, 2.0)
		"mark": _status_system.apply_status(_target_index, status_id, 5.0, 1.20)
		"armor_break": _status_system.apply_status(_target_index, status_id, 6.0)
		"weaken": _status_system.apply_status(_target_index, status_id, 5.0, 0.30)

func _trigger_reaction(reaction_id: String) -> void:
	match reaction_id:
		"Shatter":
			_apply_status("freeze")
			_status_system.on_heavy_hit(_target_index, 20.0)
		"Toxic Blast":
			_apply_status("burn")
			_apply_status("poison")
		"Overload":
			_apply_status("stun")
			_apply_status("mark")
		"Corrode":
			_apply_status("poison")
			_apply_status("armor_break")
		"Thermal Shock":
			_apply_status("burn")
			_apply_status("slow")

func _mark_elite() -> void:
	_enemy_manager.set_enemy_flags(_target_index, true, false)

