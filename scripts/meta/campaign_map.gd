extends Control
## Ten-gate map/progression grid. Buttons reflect sequential and world-gate rules.

var _campaign: Campaign = Campaign.new()
@onready var _worlds: HBoxContainer = $Layout/MapScroll/Worlds
@onready var _detail: Label = $Layout/Detail

func _ready() -> void:
	_campaign.load_data(SaveManager.get_section("campaign"))
	for world: int in Campaign.WORLD_COUNT:
		var world_number: int = world + 1
		var column: VBoxContainer = VBoxContainer.new()
		column.custom_minimum_size = Vector2(180, 0)
		var title: Label = Label.new()
		title.text = "%d. %s\n%d / 30 stars" % [world_number, _campaign.get_world_name(world_number), _campaign.get_world_stars(world_number)]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(title)
		for level: int in Campaign.LEVELS_PER_WORLD:
			var level_number: int = level + 1
			var button: Button = Button.new()
			button.text = "%d-%d  %s" % [world_number, level_number, "★".repeat(_campaign.get_level_stars(world_number, level_number))]
			button.disabled = not _campaign.is_level_unlocked(world_number, level_number)
			button.pressed.connect(_select_level.bind(world_number, level_number))
			column.add_child(button)
		_worlds.add_child(column)
	_detail.text = "Complete levels in order. Defeat each world's boss and earn 15/30 stars to open the next gate."

func _select_level(world: int, level: int) -> void:
	_detail.text = "Level %d-%d selected • best: %d stars" % [world, level, _campaign.get_level_stars(world, level)]
