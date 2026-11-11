extends CanvasLayer
## Manual P6 boss test: starts either World 1 encounter and can force phase transitions.

@onready var _game: Node = get_parent().get_node("GameRoot")
@onready var _boss: BossController = _game.get_node("BossController")

func _ready() -> void:
	var panel := Panel.new()
	panel.position = Vector2(1410, 165)
	panel.size = Vector2(455, 460)
	add_child(panel)
	var title := Label.new()
	title.position = Vector2(20, 18)
	title.text = "P6 Boss Debug"
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)
	var list := VBoxContainer.new()
	list.position = Vector2(20, 70)
	list.size = Vector2(415, 360)
	panel.add_child(list)
	for entry: Dictionary in [
		{"label":"Start Kepala Orc", "id":"orc_chief", "hard":false},
		{"label":"Start Gorvak Normal", "id":"gorvak", "hard":false},
		{"label":"Start Gorvak Hard", "id":"gorvak", "hard":true},
		{"label":"Start Ratu Scarab", "id":"scarab_queen", "hard":false},
		{"label":"Start Khepri Normal", "id":"khepri", "hard":false},
		{"label":"Start Khepri Hard", "id":"khepri", "hard":true},
		{"label":"Start Penyihir Rawa", "id":"swamp_witch", "hard":false},
		{"label":"Start Mother Hydra", "id":"mother_hydra", "hard":false},
		{"label":"Start Penjaga Es", "id":"ice_guardian", "hard":false},
		{"label":"Start Glacier Titan", "id":"glacier_titan", "hard":false},
		{"label":"Start Bone Colossus", "id":"bone_colossus", "hard":false},
		{"label":"Start Morthal", "id":"morthal", "hard":false},
		{"label":"Start Brute Lahar", "id":"lava_brute", "hard":false},
		{"label":"Start Ignis", "id":"ignis", "hard":false},
		{"label":"Start Siege Walker", "id":"siege_walker", "hard":false},
		{"label":"Start Overseer", "id":"overseer_automaton", "hard":false},
		{"label":"Start Matron Harpy", "id":"harpy_matron", "hard":false},
		{"label":"Start Zephyra", "id":"zephyra", "hard":false},
		{"label":"Start Bayangan Cermin", "id":"mirror_shade", "hard":false},
		{"label":"Start Eclipse Weaver", "id":"eclipse_weaver", "hard":false},
		{"label":"Start Dread Sovereign", "id":"dread_sovereign", "hard":false}
	]:
		var button := Button.new()
		button.text = String(entry["label"])
		button.pressed.connect(_start_boss.bind(String(entry["id"]), bool(entry["hard"])))
		list.add_child(button)
	for phase: int in [1, 2, 3, 4]:
		var button := Button.new()
		button.text = "Force Phase %d" % phase
		button.pressed.connect(_boss.force_phase.bind(phase))
		list.add_child(button)

func _start_boss(id: String, hard: bool) -> void:
	_boss.start_encounter(id, hard)

