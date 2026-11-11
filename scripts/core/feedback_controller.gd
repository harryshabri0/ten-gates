class_name FeedbackController
extends CanvasLayer
## Lightweight visual/haptic feedback with an accessibility-aware flash cap.

var _flash_alpha: float = 0.0
var _shake_remaining: float = 0.0

@onready var _flash: ColorRect = $HitFlash

func hit_flash() -> void:
	if Settings.quality == "low":
		return
	_flash_alpha = 0.12 if Settings.reduce_flash else 0.30
	_flash.color.a = _flash_alpha

func boss_shake() -> void:
	if Settings.quality == "low":
		return
	_shake_remaining = 0.18
	if Settings.haptics_enabled:
		Input.vibrate_handheld(18)

func _process(delta: float) -> void:
	_flash_alpha = maxf(0.0, _flash_alpha - delta * 2.8)
	_flash.color.a = _flash_alpha
	_shake_remaining = maxf(0.0, _shake_remaining - delta)
