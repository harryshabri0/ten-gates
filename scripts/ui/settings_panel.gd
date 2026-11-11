class_name SettingsPanel
extends Panel
## In-game, persisted accessibility and performance preferences.

func _ready() -> void:
	$Quality.clear()
	for value: String in ["low", "medium", "high"]:
		$Quality.add_item(value.capitalize())
	$FpsCap.clear()
	$FpsCap.add_item("30 FPS", 30)
	$FpsCap.add_item("60 FPS", 60)
	$Quality.item_selected.connect(_on_quality_selected)
	$FpsCap.item_selected.connect(func(index: int) -> void: _save({"fps_cap": $FpsCap.get_item_id(index)}))
	$Battery.toggled.connect(func(value: bool) -> void: Settings.set_battery_saver(value); SaveManager.save())
	$LeftHanded.toggled.connect(func(value: bool) -> void: _save({"left_handed": value}))
	$Colorblind.toggled.connect(func(value: bool) -> void: _save({"colorblind_mode": value}))
	$ReduceFlash.toggled.connect(func(value: bool) -> void: _save({"reduce_flash": value}))
	$Haptics.toggled.connect(func(value: bool) -> void: _save({"haptics_enabled": value}))
	$FontScale.value_changed.connect(func(value: float) -> void: _save({"font_scale": value}))
	$Music.value_changed.connect(func(value: float) -> void: _save({"music_volume": value}))
	$Sfx.value_changed.connect(func(value: float) -> void: _save({"sfx_volume": value}))
	$Close.pressed.connect(hide)
	_sync()
	hide()

func open_panel() -> void:
	_sync()
	show()

func _sync() -> void:
	$Quality.select(["low", "medium", "high"].find(Settings.quality))
	$FpsCap.select(0 if Settings.fps_cap <= 30 else 1)
	$Battery.button_pressed = Settings.battery_saver_enabled
	$LeftHanded.button_pressed = Settings.left_handed
	$Colorblind.button_pressed = Settings.colorblind_mode
	$ReduceFlash.button_pressed = Settings.reduce_flash
	$Haptics.button_pressed = Settings.haptics_enabled
	$FontScale.value = Settings.font_scale
	$Music.value = Settings.music_volume
	$Sfx.value = Settings.sfx_volume

func _on_quality_selected(index: int) -> void:
	_save({"quality": ["low", "medium", "high"][index]})

func _save(changes: Dictionary) -> void:
	var merged: Dictionary = Settings.to_save_data()
	merged.merge(changes, true)
	Settings.update_preferences(merged)
	SaveManager.save()
