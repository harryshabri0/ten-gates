class_name PrototypeProjectilePool
extends Node2D
## Fixed-size projectile pool. Projectiles are data entries, not scene nodes.

const MAX_PROJECTILES: int = 256
const FIRE_TEXTURE: Texture2D = preload("res://assets/fantasy/tiny_swords/fire_fx.png")

var _projectiles: Array[Dictionary] = []
var _draw_stride: int = 1

func _ready() -> void:
	Settings.preferences_changed.connect(_apply_quality)
	_apply_quality()
	for _index: int in MAX_PROJECTILES:
		_projectiles.append({
			"active": false,
			"position": Vector2.ZERO,
			"target": -1,
			"damage": 0.0,
			"speed": 0.0,
			"splash": 0.0,
			"color": Color.WHITE,
			"heavy": false,
			"damage_type": "physical"
		})

func _apply_quality() -> void:
	_draw_stride = 4 if Settings.quality == "low" else 2 if Settings.quality == "medium" else 1

func fire(origin: Vector2, target: int, damage: float, speed: float, splash: float, color: Color, heavy: bool = false, damage_type: String = "physical") -> bool:
	for projectile: Dictionary in _projectiles:
		if projectile["active"]:
			continue
		projectile["active"] = true
		projectile["position"] = origin
		projectile["target"] = target
		projectile["damage"] = damage
		projectile["speed"] = speed
		projectile["splash"] = splash
		projectile["color"] = color
		projectile["heavy"] = heavy
		projectile["damage_type"] = damage_type
		return true
	return false

func tick(delta: float, enemy_manager: Node) -> void:
	for projectile: Dictionary in _projectiles:
		if not projectile["active"]:
			continue
		var target_position: Vector2 = enemy_manager.get_enemy_position(int(projectile["target"]))
		if target_position == Vector2.INF:
			projectile["active"] = false
			continue
		var offset: Vector2 = target_position - projectile["position"]
		var travel: float = float(projectile["speed"]) * delta
		if offset.length_squared() <= travel * travel:
			projectile["position"] = target_position
			_resolve_hit(projectile, enemy_manager)
			projectile["active"] = false
			continue
		projectile["position"] += offset.normalized() * travel
	GameState.set_active_projectile_count(active_count())
	queue_redraw()

func reset() -> void:
	for projectile: Dictionary in _projectiles:
		projectile["active"] = false
	GameState.set_active_projectile_count(0)
	queue_redraw()

func active_count() -> int:
	var count: int = 0
	for projectile: Dictionary in _projectiles:
		if projectile["active"]:
			count += 1
	return count

func _resolve_hit(projectile: Dictionary, enemy_manager: Node) -> void:
	AudioDirector.play_hit(bool(projectile["heavy"]))
	var splash: float = float(projectile["splash"])
	if splash > 0.0:
		enemy_manager.damage_radius(projectile["position"], splash, float(projectile["damage"]), String(projectile["damage_type"]))
	else:
		enemy_manager.damage_enemy(int(projectile["target"]), float(projectile["damage"]), String(projectile["damage_type"]), bool(projectile["heavy"]))

func _draw() -> void:
	var visual_index: int = 0
	for projectile: Dictionary in _projectiles:
		if projectile["active"]:
			visual_index += 1
			if visual_index % _draw_stride != 0:
				continue
			var position: Vector2 = projectile["position"]
			var tint: Color = projectile["color"]
			draw_texture_rect_region(FIRE_TEXTURE, Rect2(position - Vector2(8.0, 8.0), Vector2(16.0, 16.0)), Rect2(0.0, 0.0, 64.0, 64.0), tint)

