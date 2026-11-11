extends Control
## Horizontal, drag-scrollable view of the skill tree with purchase preview and presets.

var _campaign: Campaign = Campaign.new()
var _tree: SkillTree = SkillTree.new()
var _selected_node_id: String = ""

@onready var _columns: HBoxContainer = $Layout/TreeScroll/Columns
@onready var _detail: Label = $Layout/DetailPanel/Detail
@onready var _points: Label = $Layout/TopBar/Points

func _ready() -> void:
	_campaign.load_data(SaveManager.get_section("campaign"))
	_tree.load_data(SaveManager.get_section("skill_tree"))
	$Layout/TopBar/Respec.pressed.connect(_on_respec)
	$Layout/TopBar/Preset1.pressed.connect(func() -> void: _on_preset(0))
	$Layout/TopBar/Preset2.pressed.connect(func() -> void: _on_preset(1))
	$Layout/TopBar/Preset3.pressed.connect(func() -> void: _on_preset(2))
	$Layout/DetailPanel/Unlock.pressed.connect(_on_unlock)
	_rebuild()

func _rebuild() -> void:
	for child: Node in _columns.get_children():
		child.queue_free()
	var available: int = _available_points()
	_points.text = "SKILL POINTS %d available • %d spent • World %d complete" % [available, _tree.spent_total(), _campaign.highest_completed_world()]
	for branch: Dictionary in _tree.get_branches():
		var column: VBoxContainer = VBoxContainer.new()
		column.custom_minimum_size = Vector2(300.0, 0.0)
		var title: Label = Label.new()
		title.text = String(branch["name"])
		title.add_theme_font_size_override("font_size", 23)
		column.add_child(title)
		for node: Dictionary in Array(branch["nodes"]):
			var button: Button = Button.new()
			var node_id: String = String(node["id"])
			button.custom_minimum_size = Vector2(280.0, 58.0)
			button.text = "%s  •  T%d / %d SP%s" % [String(node["name"]), int(node["tier"]), int(node["cost"]), "  ✓" if _tree.is_unlocked(node_id) else ""]
			button.pressed.connect(_select_node.bind(node_id))
			column.add_child(button)
		_columns.add_child(column)
	if not _selected_node_id.is_empty():
		_select_node(_selected_node_id)
	else:
		_detail.text = "Select a node to preview its effect. Tier II needs World 3 + 9 SP in branch; Tier III needs World 6 + 24 SP."
		$Layout/DetailPanel/Unlock.disabled = true

func _select_node(node_id: String) -> void:
	_selected_node_id = node_id
	var node: Dictionary = _tree.preview_node(node_id)
	var check: Dictionary = _tree.can_unlock(node_id, _available_points(), _campaign.highest_completed_world())
	_detail.text = "%s\n%s\nTier %d • Cost %d SP\n%s" % [String(node["name"]), String(node["description"]), int(node["tier"]), int(node["cost"]), "Unlocked" if bool(node["unlocked"]) else String(check["reason"] if not bool(check["valid"]) else "Available")]
	$Layout/DetailPanel/Unlock.disabled = bool(node["unlocked"]) or not bool(check["valid"])
	$Layout/DetailPanel/Unlock.text = "Unlocked" if bool(node["unlocked"]) else "Unlock node"

func _on_unlock() -> void:
	var result: Dictionary = _tree.unlock(_selected_node_id, _available_points(), _campaign.highest_completed_world())
	if bool(result["valid"]):
		_save_tree()
	_rebuild()

func _on_respec() -> void:
	_tree.respec()
	_save_tree()
	_rebuild()

func _on_preset(index: int) -> void:
	if Input.is_key_pressed(KEY_SHIFT):
		_tree.save_preset(index)
		_save_tree()
		_detail.text = "Preset %d saved." % (index + 1)
		return
	var result: Dictionary = _tree.apply_preset(index, _available_points(), _campaign.highest_completed_world())
	_detail.text = "Preset %d applied." % (index + 1) if bool(result["valid"]) else String(result["reason"])
	if bool(result["valid"]):
		_save_tree()
	_rebuild()

func _available_points() -> int:
	return maxi(0, _campaign.get_total_skill_points() - _tree.spent_total())

func _save_tree() -> void:
	SaveManager.set_section("skill_tree", _tree.to_data())
