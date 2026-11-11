extends Node
## P0 settings surface. Persistent storage is deliberately deferred to P8.

signal frame_cap_changed(value: int)
signal preferences_changed()

const FPS_CAP_BATTERY_SAVER: int = 30
const FPS_CAP_DEFAULT: int = 60

var battery_saver_enabled: bool = false
var fps_cap: int = FPS_CAP_DEFAULT
var quality: String = "medium"
var left_handed: bool = false
var colorblind_mode: bool = false
var font_scale: float = 1.0
var reduce_flash: bool = false
var haptics_enabled: bool = true
var music_volume: float = 0.8
var sfx_volume: float = 0.8

func _ready() -> void:
	apply_frame_cap()

func set_battery_saver(enabled: bool) -> void:
	if battery_saver_enabled == enabled:
		return
	battery_saver_enabled = enabled
	apply_frame_cap()
	preferences_changed.emit()

func set_fps_cap(value: int) -> void:
	fps_cap = FPS_CAP_BATTERY_SAVER if value <= FPS_CAP_BATTERY_SAVER else FPS_CAP_DEFAULT
	apply_frame_cap()
	preferences_changed.emit()

func update_preferences(data: Dictionary) -> void:
	quality = String(data.get("quality", quality))
	left_handed = bool(data.get("left_handed", left_handed))
	colorblind_mode = bool(data.get("colorblind_mode", colorblind_mode))
	font_scale = clampf(float(data.get("font_scale", font_scale)), 0.85, 1.35)
	reduce_flash = bool(data.get("reduce_flash", reduce_flash))
	haptics_enabled = bool(data.get("haptics_enabled", haptics_enabled))
	music_volume = clampf(float(data.get("music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", sfx_volume)), 0.0, 1.0)
	preferences_changed.emit()

func apply_frame_cap() -> void:
	var effective_cap: int = FPS_CAP_BATTERY_SAVER if battery_saver_enabled else fps_cap
	Engine.max_fps = effective_cap
	frame_cap_changed.emit(effective_cap)

func to_save_data() -> Dictionary:
	return {"battery_saver_enabled": battery_saver_enabled, "fps_cap": fps_cap, "quality": quality, "left_handed": left_handed, "colorblind_mode": colorblind_mode, "font_scale": font_scale, "reduce_flash": reduce_flash, "haptics_enabled": haptics_enabled, "music_volume": music_volume, "sfx_volume": sfx_volume}

func apply_save_data(data: Dictionary) -> void:
	battery_saver_enabled = bool(data.get("battery_saver_enabled", battery_saver_enabled))
	fps_cap = int(data.get("fps_cap", fps_cap))
	update_preferences(data)
	apply_frame_cap()

