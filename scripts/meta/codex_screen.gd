extends Control
## Read-only view of items unlocked automatically during play.

@onready var _towers: Label = $Layout/TowerList
@onready var _enemies: Label = $Layout/EnemyList

func _ready() -> void:
	var codex: Codex = Codex.new()
	codex.load_data(SaveManager.get_section("codex"))
	_towers.text = "Towers\n" + _display(codex.get_entries("towers"), "Build towers to discover them.")
	_enemies.text = "Enemies\n" + _display(codex.get_entries("enemies"), "Encounter enemies in a wave to discover them.")

func _display(entries: Array[String], fallback: String) -> String:
	if entries.is_empty():
		return fallback
	return "\n".join(entries).replace("_", " ").capitalize()
