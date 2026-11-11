extends Node
## Versioned JSON persistence with a backup and a safe active-run snapshot.

const SAVE_VERSION: int = 2
const SAVE_PATH: String = "user://save.json"
const BACKUP_PATH: String = "user://save.bak"
const TEMP_PATH: String = "user://save.tmp"

var _data: Dictionary = {}

func _ready() -> void:
	load_save()
	Settings.apply_save_data(Dictionary(_data.get("settings", {})))

func get_section(section: String) -> Dictionary:
	return Dictionary(_data.get(section, {})).duplicate(true)

func set_section(section: String, value: Dictionary, flush: bool = true) -> void:
	_data[section] = value.duplicate(true)
	if flush:
		save()

func set_active_run(snapshot: Dictionary) -> void:
	_data["active_run"] = snapshot.duplicate(true)
	save()

func clear_active_run() -> void:
	_data["active_run"] = {}
	save()

func get_active_run() -> Dictionary:
	return Dictionary(_data.get("active_run", {})).duplicate(true)

func save() -> bool:
	_data["version"] = SAVE_VERSION
	_data["settings"] = Settings.to_save_data()
	var file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write temporary save.")
		return false
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
	var error: Error = DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
	if error != OK:
		push_error("Could not finalize save: %s" % error)
	return error == OK

func load_save() -> void:
	var loaded: Dictionary = _read_file(SAVE_PATH)
	if loaded.is_empty():
		loaded = _read_file(BACKUP_PATH)
	_data = _migrate(loaded) if not loaded.is_empty() else _default_data()

func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	return Dictionary(json.data)

func _migrate(source: Dictionary) -> Dictionary:
	var migrated: Dictionary = source.duplicate(true)
	var version: int = int(migrated.get("version", 0))
	if version < 1:
		migrated["campaign"] = Dictionary(migrated.get("campaign", {}))
		migrated["skill_tree"] = Dictionary(migrated.get("skill_tree", {}))
		migrated["codex"] = Dictionary(migrated.get("codex", {}))
		migrated["statistics"] = Dictionary(migrated.get("statistics", {}))
		migrated["active_run"] = Dictionary(migrated.get("active_run", {}))
	if version < 2:
		migrated["settings"] = Dictionary(migrated.get("settings", {}))
		migrated["presets"] = Array(migrated.get("presets", []))
	migrated["version"] = SAVE_VERSION
	return migrated

func _default_data() -> Dictionary:
	return {"version": SAVE_VERSION, "settings": {}, "campaign": {}, "skill_tree": {}, "codex": {}, "statistics": {}, "active_run": {}, "presets": []}
