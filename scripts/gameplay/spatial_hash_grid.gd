class_name SpatialHashGrid
extends RefCounted
## Rebuilt by EnemyManager once per simulation tick for fast radius queries.

const CELL_SIZE: float = 128.0

var _cells: Dictionary = {}

func clear() -> void:
	_cells.clear()

func rebuild(enemies: Array) -> void:
	_cells.clear()
	for index: int in enemies.size():
		var enemy: Dictionary = enemies[index]
		if not enemy["active"]:
			continue
		var cell: Vector2i = _to_cell(enemy["position"])
		if not _cells.has(cell):
			_cells[cell] = PackedInt32Array()
		var indices: PackedInt32Array = _cells[cell]
		indices.append(index)
		_cells[cell] = indices

func query_circle(center: Vector2, radius: float, output: Array[int]) -> void:
	output.clear()
	var min_cell: Vector2i = _to_cell(center - Vector2.ONE * radius)
	var max_cell: Vector2i = _to_cell(center + Vector2.ONE * radius)
	for x: int in range(min_cell.x, max_cell.x + 1):
		for y: int in range(min_cell.y, max_cell.y + 1):
			var cell: Vector2i = Vector2i(x, y)
			if not _cells.has(cell):
				continue
			var indices: PackedInt32Array = _cells[cell]
			for index: int in indices:
				output.append(index)

func _to_cell(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / CELL_SIZE), floori(position.y / CELL_SIZE))

