extends Node
## Checks the public GitHub Releases API once when the game starts.
## Android cannot silently replace an installed APK: the player explicitly
## opens the release download and Android handles the install confirmation.

signal update_available(version: String)
signal update_check_failed(message: String)

const CONFIG_PATH := "res://data/app_update.json"

var _http: HTTPRequest
var _config: Dictionary = {}
var _checking := false
var _pending_version := ""
var _pending_download_url := ""

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_load_config()
	call_deferred("check_for_update")

func check_for_update() -> void:
	if _checking or not bool(_config.get("enabled", false)):
		return
	var repository := String(_config.get("github_repo", "")).strip_edges()
	if repository.is_empty():
		return
	_checking = true
	var endpoint := "https://api.github.com/repos/%s/releases/latest" % repository
	var error := _http.request(endpoint, ["Accept: application/vnd.github+json", "User-Agent: Ten-Gates-Updater"])
	if error != OK:
		_checking = false
		update_check_failed.emit("Unable to start the update check.")

func has_update() -> bool:
	return not _pending_download_url.is_empty()

func get_pending_version() -> String:
	return _pending_version

func open_download() -> void:
	if not _pending_download_url.is_empty():
		OS.shell_open(_pending_download_url)

func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("Missing update configuration: %s" % CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_config = parsed
	else:
		push_warning("Invalid update configuration: %s" % CONFIG_PATH)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_checking = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		update_check_failed.emit("The update service is unavailable.")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		update_check_failed.emit("The release response was invalid.")
		return
	var release: Dictionary = parsed
	var version := String(release.get("tag_name", "")).trim_prefix("v")
	if version.is_empty() or not _is_newer_version(version, _current_version()):
		return
	var asset_url := _find_apk_url(Array(release.get("assets", [])))
	if asset_url.is_empty():
		update_check_failed.emit("The newest release has no Android APK.")
		return
	_pending_version = version
	_pending_download_url = asset_url
	update_available.emit(version)

func _find_apk_url(assets: Array) -> String:
	var preferred_name := String(_config.get("apk_asset_name", ""))
	for value: Variant in assets:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var asset: Dictionary = value
		var name := String(asset.get("name", ""))
		if name == preferred_name or (preferred_name.is_empty() and name.to_lower().ends_with(".apk")):
			return String(asset.get("browser_download_url", ""))
	return ""

func _current_version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", "0.0.0"))

func _is_newer_version(candidate: String, current: String) -> bool:
	var candidate_parts := _version_parts(candidate)
	var current_parts := _version_parts(current)
	for index: int in 3:
		if candidate_parts[index] != current_parts[index]:
			return candidate_parts[index] > current_parts[index]
	return false

func _version_parts(version: String) -> PackedInt32Array:
	var result := PackedInt32Array([0, 0, 0])
	var pieces := version.split("-", false, 1)[0].split(".")
	for index: int in min(3, pieces.size()):
		result[index] = int(pieces[index])
	return result
