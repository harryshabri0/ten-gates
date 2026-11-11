class_name GameplayCameraController
extends Camera2D
## Landscape map camera: pinch or the large +/- controls pan and zoom the map.

const MIN_ZOOM := 1.0
const MAX_ZOOM := 1.65
const WORLD_RECT := Rect2(0.0, 0.0, 1920.0, 1080.0)

func _ready() -> void:
	make_current()
	EventBus.screen_dragged.connect(_on_screen_dragged)
	EventBus.pinch_zoom_requested.connect(_on_pinch_zoom_requested)
	get_viewport().size_changed.connect(_clamp_to_world)
	_clamp_to_world()

func _on_screen_dragged(delta: Vector2) -> void:
	position -= delta * zoom.x
	_clamp_to_world()

func _on_pinch_zoom_requested(factor: float) -> void:
	var zoom_level := clampf(zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(zoom_level, zoom_level)
	_clamp_to_world()

func _clamp_to_world() -> void:
	var viewport_size := get_viewport_rect().size
	var half_visible := viewport_size * zoom.x * 0.5
	var center := WORLD_RECT.get_center()
	var minimum := WORLD_RECT.position + half_visible
	var maximum := WORLD_RECT.end - half_visible
	position.x = center.x if minimum.x > maximum.x else clampf(position.x, minimum.x, maximum.x)
	position.y = center.y if minimum.y > maximum.y else clampf(position.y, minimum.y, maximum.y)
