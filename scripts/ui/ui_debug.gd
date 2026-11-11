extends Node
## P9 smoke test: invokes HUD polish surfaces without requiring pointer input.

@onready var _hud: PrototypeHud = $GameRoot/GameHud

func _ready() -> void:
	await get_tree().process_frame
	var original: Dictionary = Settings.to_save_data()
	Settings.update_preferences({"left_handed": true, "colorblind_mode": true, "font_scale": 1.15, "reduce_flash": true})
	_hud.apply_preferences()
	_hud.set_wave_preview(["W1 Grunt ×8", "W2 Runner ×3"])
	_hud.set_paused(true)
	_hud.set_tutorial("Tutorial test", true)
	_hud.show_result(3, 3, 3)
	_hud.show_defeat("Most leaks: Runner (2).")
	_hud.toggle_settings()
	Settings.update_preferences(original)
	print("P9 UI/UX smoke test passed.")
	get_tree().quit()
