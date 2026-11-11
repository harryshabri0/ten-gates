extends CanvasLayer
## Manual P4 scene: spawn every World 1-3 enemy and optional elite affixes.

@onready var _game: Node = get_parent().get_node("GameRoot")
@onready var _enemy_manager: PrototypeEnemyManager = _game.get_node("EnemyManager")

var _elite: bool = false
var _label: Label

func _ready() -> void:
	var panel := Panel.new()
	panel.position = Vector2(1390, 145)
	panel.size = Vector2(500, 760)
	add_child(panel)
	_label = Label.new()
	_label.position = Vector2(20, 18)
	_label.size = Vector2(460, 55)
	_label.text = "P4 Enemy Debug\nWorld 1-3"
	_label.add_theme_font_size_override("font_size", 21)
	panel.add_child(_label)
	var list := VBoxContainer.new()
	list.position = Vector2(20, 88)
	list.size = Vector2(460, 555)
	panel.add_child(list)
	for enemy_id: String in ["grunt", "runner", "brute", "swarmling", "bat", "scarab", "digger", "swamp_shaman", "spore_splitter", "poison_spitter"]:
		var button := Button.new()
		button.text = "Spawn %s" % enemy_id
		button.pressed.connect(_spawn_enemy.bind(enemy_id))
		list.add_child(button)
	var elite := Button.new()
	elite.position = Vector2(20, 660)
	elite.size = Vector2(220, 54)
	elite.text = "Elite: OFF"
	elite.pressed.connect(_toggle_elite.bind(elite))
	panel.add_child(elite)

func _spawn_enemy(enemy_id: String) -> void:
	_enemy_manager.queue_spawn(enemy_id, 1, 0.03, _elite)
	_label.text = "Spawned %s%s" % [enemy_id, " with rotating affix" if _elite else ""]

func _toggle_elite(button: Button) -> void:
	_elite = not _elite
	button.text = "Elite: %s" % ("ON" if _elite else "OFF")

