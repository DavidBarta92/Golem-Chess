extends RefCounted
class_name CollectionSavedDeckListController

const STAMP_VISUAL = preload("res://Scenes/StampVisual.tscn")

var collection
var deck_list: VBoxContainer
var stamp_visual_size: Vector2 = Vector2(168.7, 229)
var max_deck_size: int = 6

var reset_scroll_callback: Callable = Callable()
var edit_deck_callback: Callable = Callable()
var editor_back_callback: Callable = Callable()
var print_for_deck_stamp_provider: Callable = Callable()

func bind(config: Dictionary) -> void:
	collection = config.get("collection", collection)
	deck_list = config.get("deck_list", deck_list) as VBoxContainer
	stamp_visual_size = config.get("stamp_visual_size", stamp_visual_size)
	max_deck_size = int(config.get("max_deck_size", max_deck_size))
	reset_scroll_callback = config.get("reset_scroll_callback", reset_scroll_callback)
	edit_deck_callback = config.get("edit_deck_callback", edit_deck_callback)
	editor_back_callback = config.get("editor_back_callback", editor_back_callback)
	print_for_deck_stamp_provider = config.get("print_for_deck_stamp_provider", print_for_deck_stamp_provider)

func populate_saved_decks_list() -> void:
	if deck_list == null:
		return

	for child in deck_list.get_children():
		deck_list.remove_child(child)
		child.queue_free()

	if reset_scroll_callback.is_valid():
		reset_scroll_callback.call()

	var saved_decks: Array = PlayerDeckStore.list_decks()
	if saved_decks.is_empty():
		var empty_label := Label.new()
		deck_list.add_child(empty_label)
		empty_label.text = tr("No saved codexes")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return

	for deck_data in saved_decks:
		if !(deck_data is Dictionary):
			continue
		deck_list.add_child(create_saved_deck_row(deck_data))

func create_saved_deck_row(deck_data: Dictionary) -> Control:
	var ownership_info: Dictionary = PlayerDeckStore.get_deck_ownership_info(deck_data)
	var is_playable: bool = bool(ownership_info.get("is_playable", false))
	var owned_count: int = int(ownership_info.get("owned_count", 0))

	var row_frame := Control.new()
	row_frame.custom_minimum_size = Vector2(0, 148)
	row_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	row_frame.clip_contents = false

	var preview_prints: Array = get_deck_preview_prints(deck_data)
	var preview_offsets: Array = [Vector2(76, -2), Vector2(126, -6), Vector2(176, -2)]
	var preview_rotations: Array = [-8.0, 8.0, -4.0]
	for index in range(preview_prints.size()):
		var preview_print: StampPrint = preview_prints[index] as StampPrint
		if preview_print == null:
			continue
		var preview_visual := create_small_deck_preview_stamp(preview_print)
		row_frame.add_child(preview_visual)
		preview_visual.position = preview_offsets[index]
		preview_visual.rotation = deg_to_rad(preview_rotations[index])

	var front_panel := PanelContainer.new()
	row_frame.add_child(front_panel)
	front_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	front_panel.anchor_left = 0.0
	front_panel.anchor_top = 0.0
	front_panel.anchor_right = 1.0
	front_panel.anchor_bottom = 1.0
	front_panel.offset_left = 0.0
	front_panel.offset_top = 64.0
	front_panel.offset_right = 0.0
	front_panel.offset_bottom = 0.0
	front_panel.add_theme_stylebox_override("panel", create_dark_panel_style(0, 20))

	var content := VBoxContainer.new()
	front_panel.add_child(content)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)

	var name_label := Label.new()
	content.add_child(name_label)
	name_label.text = str(deck_data.get("name", tr("Unnamed codex")))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))

	var footer := HBoxContainer.new()
	content.add_child(footer)
	footer.mouse_filter = Control.MOUSE_FILTER_PASS
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 8)

	var count_label := Label.new()
	footer.add_child(count_label)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.text = "%d/%d" % [owned_count if !is_playable else max_deck_size, max_deck_size]
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", Color(0.95, 0.2, 0.2) if !is_playable else Color(0.86, 0.86, 0.82))

	var edit_button := create_circle_icon_button("E", tr("Edit codex"))
	footer.add_child(edit_button)
	if edit_deck_callback.is_valid():
		edit_button.pressed.connect(edit_deck_callback.bind(deck_data.duplicate(true)))

	var delete_button := create_circle_icon_button("X", tr("Delete codex"))
	footer.add_child(delete_button)
	delete_button.pressed.connect(on_delete_deck_pressed.bind(str(deck_data.get("deck_id", ""))))

	return row_frame

func get_deck_preview_prints(deck_data: Dictionary) -> Array:
	var preview_prints: Array = []
	var deck_stamps = deck_data.get("stamps", [])
	if !(deck_stamps is Array):
		return preview_prints

	var candidate_indexes: Array = [0, int(deck_stamps.size() / 2), maxi(0, deck_stamps.size() - 1)]
	for candidate_index in candidate_indexes:
		if candidate_index < 0 or candidate_index >= deck_stamps.size():
			continue
		var deck_stamp = deck_stamps[candidate_index]
		if !(deck_stamp is Dictionary):
			continue
		var stamp_print: StampPrint = get_print_for_deck_stamp(deck_stamp)
		if stamp_print != null && !preview_prints.has(stamp_print):
			preview_prints.append(stamp_print)
		if preview_prints.size() >= 3:
			break
	return preview_prints

func create_small_deck_preview_stamp(stamp_print: StampPrint) -> StampVisual:
	var stamp_visual := STAMP_VISUAL.instantiate() as StampVisual
	stamp_visual.custom_minimum_size = stamp_visual_size
	stamp_visual.size = stamp_visual_size
	stamp_visual.set_hover_raise_enabled(false)
	stamp_visual.set_stamp_print(stamp_print)
	stamp_visual.set_face_down(false)
	stamp_visual.set_collection_owned(true)
	stamp_visual.set_rest_scale(Vector2.ONE * 0.38)
	stamp_visual.draggable = false
	stamp_visual.disabled = true
	stamp_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return stamp_visual

func create_circle_icon_button(text_value: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(40, 40)
	button.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.68, 0.68, 1.0)
	style.border_color = Color(0.08, 0.08, 0.08, 0.65)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	return button

func on_delete_deck_pressed(deck_id: String) -> void:
	if deck_id.is_empty():
		return
	PlayerDeckStore.delete_deck(deck_id)
	if collection != null and str(collection.editing_deck_id) == deck_id and editor_back_callback.is_valid():
		editor_back_callback.call()
	populate_saved_decks_list()

func get_print_for_deck_stamp(deck_stamp: Dictionary) -> StampPrint:
	if print_for_deck_stamp_provider.is_valid():
		return print_for_deck_stamp_provider.call(deck_stamp) as StampPrint
	return null

func create_dark_panel_style(radius_top: int, radius_bottom: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.035, 0.04, 0.95)
	style.border_color = Color(1.0, 1.0, 1.0, 0.18)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius_top
	style.corner_radius_top_right = radius_top
	style.corner_radius_bottom_left = radius_bottom
	style.corner_radius_bottom_right = radius_bottom
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style
