extends Control

var _stats_panel: PanelContainer
var _stats_label: Label

func _ready() -> void:
	_build_interface()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("101b2b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var glow := ColorRect.new()
	glow.color = Color(0.12, 0.34, 0.43, 0.72)
	glow.position = Vector2(0, 560)
	glow.size = Vector2(1920, 520)
	add_child(glow)
	var layout := VBoxContainer.new()
	layout.position = Vector2(150, 150)
	layout.size = Vector2(650, 680)
	layout.add_theme_constant_override("separation", 20)
	add_child(layout)
	var title := Label.new()
	title.text = "TEN GATES"
	title.add_theme_font_size_override("font_size", 82)
	title.add_theme_color_override("font_color", Color("f7d78b"))
	layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "3D FANTASY TOWER DEFENSE\nDEFEND THE REALMS. HOLD THE GATES."
	subtitle.add_theme_font_size_override("font_size", 25)
	subtitle.add_theme_color_override("font_color", Color("bbd7df"))
	layout.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 30
	layout.add_child(spacer)
	layout.add_child(_button("PLAY CAMPAIGN", _play, Color("3e8b67")))
	layout.add_child(_button("PLAYER STATS", _toggle_stats, Color("315a88")))
	layout.add_child(_button("QUIT", _quit, Color("593d52")))
	var note := Label.new()
	note.text = "Landscape mode • Drag to pan • Use +/- to zoom"
	note.add_theme_font_size_override("font_size", 20)
	note.add_theme_color_override("font_color", Color("8da8b5"))
	layout.add_child(note)
	_stats_panel = PanelContainer.new()
	_stats_panel.position = Vector2(1040, 210)
	_stats_panel.size = Vector2(620, 520)
	_stats_panel.visible = false
	add_child(_stats_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	_stats_panel.add_child(box)
	var stat_title := Label.new()
	stat_title.text = "PLAYER STATISTICS"
	stat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_title.add_theme_font_size_override("font_size", 34)
	box.add_child(stat_title)
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 27)
	_stats_label.add_theme_color_override("font_color", Color("dceef2"))
	box.add_child(_stats_label)
	box.add_child(_button("CLOSE", _toggle_stats, Color("435b73")))

func _button(caption: String, action: Callable, color: Color) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(460, 78)
	button.add_theme_font_size_override("font_size", 29)
	button.add_theme_color_override("font_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_color = Color("e7c869")
	normal.set_border_width_all(3)
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.14)
	hover.border_color = Color("fff2bb")
	button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(func() -> void: AudioDirector.play_ui(); action.call())
	return button

func _play() -> void:
	PlayerStats.flush()
	get_tree().change_scene_to_file("res://scenes/meta/map_select.tscn")

func _toggle_stats() -> void:
	_stats_panel.visible = not _stats_panel.visible
	if _stats_panel.visible:
		_stats_label.text = PlayerStats.summary_text()

func _quit() -> void:
	get_tree().quit()
