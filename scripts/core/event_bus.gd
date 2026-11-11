extends Node
## Global signals. Systems communicate through this bus instead of node lookups.

signal screen_tapped(position: Vector2)
signal screen_dragged(delta: Vector2)
signal pinch_zoom_requested(factor: float)

