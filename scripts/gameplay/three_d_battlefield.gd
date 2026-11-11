class_name ThreeDBattlefield
extends Node
## 3D presentation layer for the existing deterministic tower-defense simulation.
## It renders low-poly fantasy forms in a SubViewport while gameplay data remains
## lightweight and mobile-friendly in the 2D simulation layer.

const MAX_VISIBLE_ENEMIES: int = 80

var _viewport: SubViewport
var _camera: Camera3D
var _enemy_nodes: Array[MeshInstance3D] = []
var _tower_nodes: Array[Node3D] = []
var _ground: MeshInstance3D
var _path_root: Node3D
var _world_root: Node3D
var _enemy_mesh: SphereMesh
var _last_path_count: int = -1
var _zoom_size: float = 18.5

func _ready() -> void:
	_setup_viewport()
	_setup_world()
	EventBus.pinch_zoom_requested.connect(_on_zoom)

func _setup_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1920, 1080)
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	var display := TextureRect.new()
	display.texture = _viewport.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.z_index = -10
	get_parent().call_deferred("add_child", display)
	get_parent().call_deferred("move_child", display, 0)
	var backdrop: CanvasItem = get_parent().get_node_or_null("Backdrop") as CanvasItem
	if backdrop != null:
		backdrop.hide()
	var old_camera: Camera2D = get_parent().get_node_or_null("GameplayCamera") as Camera2D
	if old_camera != null:
		old_camera.enabled = false

func _setup_world() -> void:
	_world_root = Node3D.new()
	_viewport.add_child(_world_root)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("13253a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b8d7e7")
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	_world_root.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.light_color = Color("ffe1ab")
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	_world_root.add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-5.0, 4.0, 2.0)
	fill.light_color = Color("79b6ff")
	fill.light_energy = 2.0
	fill.omni_range = 17.0
	_world_root.add_child(fill)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = _zoom_size
	_camera.position = Vector3(0.0, 13.5, 10.5)
	_world_root.add_child(_camera)
	_camera.look_at(Vector3(0.0, 0.0, 0.0))
	_ground = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20.0, 13.0)
	_ground.mesh = plane
	_ground.material_override = _material(Color("31543f"), 0.0, 0.95)
	_world_root.add_child(_ground)
	_path_root = Node3D.new()
	_world_root.add_child(_path_root)
	_add_scatter()
	_enemy_mesh = SphereMesh.new()
	_enemy_mesh.radius = 0.23
	_enemy_mesh.height = 0.50
	_enemy_mesh.radial_segments = 8
	_enemy_mesh.rings = 4
	for index: int in MAX_VISIBLE_ENEMIES:
		var actor := MeshInstance3D.new()
		actor.mesh = _enemy_mesh
		actor.material_override = _material(Color.WHITE, 0.0, 0.72)
		actor.visible = false
		_world_root.add_child(actor)
		_enemy_nodes.append(actor)

func _process(_delta: float) -> void:
	var controller: Node = get_parent()
	var enemy_manager: PrototypeEnemyManager = controller.get_node_or_null("EnemyManager") as PrototypeEnemyManager
	if enemy_manager == null:
		return
	enemy_manager.hide()
	var projectile_pool: CanvasItem = controller.get_node_or_null("ProjectilePool") as CanvasItem
	if projectile_pool != null:
		projectile_pool.hide()
	for tower: PrototypeTower in controller.get_visual_tower_nodes():
		tower.hide()
	_sync_path(controller.get_visual_path())
	_sync_enemies(enemy_manager.get_visual_enemies(MAX_VISIBLE_ENEMIES))
	_sync_towers(controller.get_visual_towers())

func _sync_path(path: PackedVector2Array) -> void:
	if path.size() == _last_path_count:
		return
	_last_path_count = path.size()
	for child: Node in _path_root.get_children():
		child.queue_free()
	for index: int in range(maxi(0, path.size() - 1)):
		var start: Vector3 = _to_world(path[index])
		var finish: Vector3 = _to_world(path[index + 1])
		var segment: Vector3 = finish - start
		var road := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.72, 0.07, segment.length() + 0.12)
		road.mesh = mesh
		road.position = (start + finish) * 0.5 + Vector3.UP * 0.045
		road.rotation.y = atan2(segment.x, segment.z)
		road.material_override = _material(Color("765038"), 0.0, 0.96)
		_path_root.add_child(road)

func _sync_enemies(enemies: Array[Dictionary]) -> void:
	for index: int in _enemy_nodes.size():
		var actor: MeshInstance3D = _enemy_nodes[index]
		if index >= enemies.size():
			actor.visible = false
			continue
		var enemy: Dictionary = enemies[index]
		actor.visible = true
		actor.position = _to_world(Vector2(enemy["position"]))
		actor.position.y = 0.78 if bool(enemy.get("flying", false)) else 0.30
		var size: float = 1.85 if bool(enemy.get("is_boss", false)) else 1.22 if bool(enemy.get("is_elite", false)) else 1.0
		actor.scale = Vector3(size, size, size)
		var color: Color = Color(enemy.get("color", Color.WHITE))
		if bool(enemy.get("is_boss", false)):
			color = Color("e86a55")
		var material: StandardMaterial3D = actor.material_override as StandardMaterial3D
		material.albedo_color = color

func _sync_towers(towers: Array[Dictionary]) -> void:
	while _tower_nodes.size() < towers.size():
		_tower_nodes.append(_make_tower())
	for index: int in _tower_nodes.size():
		var tower: Node3D = _tower_nodes[index]
		if index >= towers.size():
			tower.visible = false
			continue
		var data: Dictionary = towers[index]
		tower.visible = true
		tower.position = _to_world(Vector2(data["position"]))
		var color: Color = Color(data["color"])
		var glow: MeshInstance3D = tower.get_node("Glow") as MeshInstance3D
		var glow_material: StandardMaterial3D = glow.material_override as StandardMaterial3D
		glow_material.albedo_color = color
		glow.rotation.y += 0.03
		var height: float = 0.78 + float(data.get("level", 1)) * 0.08
		tower.get_node("Spire").scale.y = height

func _make_tower() -> Node3D:
	var root := Node3D.new()
	_world_root.add_child(root)
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.30
	base_mesh.bottom_radius = 0.42
	base_mesh.height = 0.32
	base.mesh = base_mesh
	base.position.y = 0.16
	base.material_override = _material(Color("2b3138"), 0.12, 0.6)
	root.add_child(base)
	var spire := MeshInstance3D.new()
	spire.name = "Spire"
	var spire_mesh := CylinderMesh.new()
	spire_mesh.top_radius = 0.16
	spire_mesh.bottom_radius = 0.22
	spire_mesh.height = 0.85
	spire.mesh = spire_mesh
	spire.position.y = 0.66
	spire.material_override = _material(Color("7d8d92"), 0.1, 0.56)
	root.add_child(spire)
	var glow := MeshInstance3D.new()
	glow.name = "Glow"
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.18
	glow_mesh.height = 0.36
	glow.mesh = glow_mesh
	glow.position.y = 1.18
	glow.material_override = _material(Color("f5cf6d"), 0.15, 0.3, true)
	root.add_child(glow)
	return root

func _add_scatter() -> void:
	for pos: Vector3 in [Vector3(-7.7, 0.0, -4.5), Vector3(7.5, 0.0, -4.2), Vector3(-7.0, 0.0, 4.0), Vector3(7.2, 0.0, 3.7)]:
		var tree := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.65
		cone.height = 1.8
		tree.mesh = cone
		tree.position = pos + Vector3.UP * 0.9
		tree.material_override = _material(Color("1e4937"), 0.0, 0.9)
		_world_root.add_child(tree)

func _to_world(position: Vector2) -> Vector3:
	return Vector3((position.x - 960.0) / 112.0, 0.0, (position.y - 540.0) / 112.0)

func _material(color: Color, metallic: float, roughness: float, emission: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.5
	return material

func _on_zoom(factor: float) -> void:
	_zoom_size = clampf(_zoom_size / maxf(0.2, factor), 11.0, 24.0)
	if _camera != null:
		_camera.size = _zoom_size
