extends Node
## Converts screen touch, drag, and pinch input into game-level signals.
## Camera movement and gameplay reactions will be connected in later phases.

const TAP_SLOP_PX: float = 18.0
const MIN_ZOOM_FACTOR: float = 0.85
const MAX_ZOOM_FACTOR: float = 1.15

var _touch_start: Vector2 = Vector2.ZERO
var _tracking_touch: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event is InputEventMagnifyGesture:
		_handle_magnify(event)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_tracking_touch = true
		_touch_start = event.position
		return
	if not _tracking_touch:
		return
	_tracking_touch = false
	if _touch_start.distance_to(event.position) <= TAP_SLOP_PX:
		EventBus.screen_tapped.emit(event.position)

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not _tracking_touch:
		return
	EventBus.screen_dragged.emit(event.relative)

func _handle_magnify(event: InputEventMagnifyGesture) -> void:
	var clamped_factor: float = clampf(event.factor, MIN_ZOOM_FACTOR, MAX_ZOOM_FACTOR)
	EventBus.pinch_zoom_requested.emit(clamped_factor)

