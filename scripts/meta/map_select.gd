extends Control
## Original fantasy-cartoon campaign selection for the ten featured maps.

const MAP_COLORS: Array[Color] = [
	Color("477d4f"), Color("b17a39"), Color("55744c"), Color("75a9b9"), Color("77657c"),
	Color("b34d32"), Color("657982"), Color("79a8d1"), Color("625287"), Color("903d4a")
]

var _campaign: Campaign = Campaign.new()
var _detail: Label

func _ready() -> void:
	_campaign.load_data(SaveManager.get_section("campaign"))
	_build_interface()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("142433")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var header := PanelContainer.new()
	header.position = Vector2(70, 38)
	header.size = Vector2(1780, 128)
	header.add_theme_stylebox_override("panel", _panel_style(Color("283a32"), Color("d8b65e"), 4, 18))
	add_child(header)
	var header_row := HBoxContainer.new()
	header.add_child(header_row)
	var back := _button("← BACK", Color("6b4936"))
	back.custom_minimum_size = Vector2(210, 74)
	back.pressed.connect(func() -> void: AudioDirector.play_ui(); get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	header_row.add_child(back)
	var title := Label.new()
	title.text = "THE TEN GATES • MAP CAMPAIGN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("ffe2a5"))
	header_row.add_child(title)
	var progress := Label.new()
	progress.text = "%d / 10 OPEN" % _unlocked_count()
	progress.custom_minimum_size = Vector2(220, 0)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 22)
	progress.add_theme_color_override("font_color", Color("b9dfbd"))
	header_row.add_child(progress)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(92, 205)
	grid.size = Vector2(1736, 690)
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 28)
	add_child(grid)
	for map_index: int in Campaign.WORLD_COUNT:
		grid.add_child(_map_card(map_index + 1))
	var guide := PanelContainer.new()
	guide.position = Vector2(280, 930)
	guide.size = Vector2(1360, 86)
	guide.add_theme_stylebox_override("panel", _panel_style(Color("23383b"), Color("6a9ba0"), 2, 14))
	add_child(guide)
	_detail = Label.new()
	_detail.text = "Complete the current map to unlock the next gate. Maps use normal difficulty by default."
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail.add_theme_font_size_override("font_size", 23)
	_detail.add_theme_color_override("font_color", Color("d9eeee"))
	guide.add_child(_detail)

func _map_card(map_number: int) -> Button:
	var unlocked: bool = _campaign.is_map_unlocked(map_number)
	var stars: int = _campaign.get_level_stars(map_number, 1)
	var card := Button.new()
	card.custom_minimum_size = Vector2(325, 320)
	card.disabled = not unlocked
	card.tooltip_text = "Complete Map %d first." % (map_number - 1) if not unlocked else "Play Map %d" % map_number
	var world_name: String = _campaign.get_world_name(map_number)
	if unlocked:
		card.text = "MAP %02d\n%s\n\n%s\nTAP TO DEFEND" % [map_number, world_name, "★".repeat(stars) + "☆".repeat(3 - stars)]
		card.add_theme_stylebox_override("normal", _panel_style(MAP_COLORS[map_number - 1].darkened(0.28), Color("f2cf72"), 4, 20))
		card.add_theme_stylebox_override("hover", _panel_style(MAP_COLORS[map_number - 1], Color("fff0b5"), 5, 20))
		card.add_theme_color_override("font_color", Color("fff4d6"))
		card.pressed.connect(_start_map.bind(map_number))
	else:
		card.text = "LOCKED\n\nMAP %02d\n%s\n\n🔒" % [map_number, world_name]
		card.add_theme_stylebox_override("disabled", _panel_style(Color("303944"), Color("56606d"), 3, 20))
		card.add_theme_color_override("font_disabled_color", Color("9aa1a9"))
	card.add_theme_font_size_override("font_size", 24)
	return card

func _start_map(map_number: int) -> void:
	AudioDirector.play_build()
	SaveManager.clear_active_run()
	SaveManager.set_section("session", {"selected_level_id": "%d-1" % map_number}, false)
	PlayerStats.flush()
	get_tree().change_scene_to_file("res://scenes/game/game_root.tscn")

func _unlocked_count() -> int:
	var count: int = 0
	for map_index: int in Campaign.WORLD_COUNT:
		if _campaign.is_map_unlocked(map_index + 1):
			count += 1
	return count

func _button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("fff3d3"))
	button.add_theme_stylebox_override("normal", _panel_style(color, Color("e9c46a"), 3, 14))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), Color.WHITE, 4, 14))
	return button

func _panel_style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
