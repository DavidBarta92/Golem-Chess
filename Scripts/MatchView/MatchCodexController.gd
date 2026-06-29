extends RefCounted

var match_board
var panel_size: Vector2 = Vector2(244, 116)
var panel_margin: Vector2 = Vector2(22, 24)

var white_page_index: int = 0
var black_page_index: int = 0
var white_page_counts: Array[int] = [0, 0, 0, 0, 0]
var black_page_counts: Array[int] = [0, 0, 0, 0, 0]
var white_pages: Array = []
var black_pages: Array = []

var codex_panel: PanelContainer
var page_label: Label
var counts_row: HBoxContainer
var turn_page_button: Button
var count_labels: Array[Label] = []

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	panel_size = config.get("panel_size", panel_size)
	panel_margin = config.get("panel_margin", panel_margin)

func create_ui() -> void:
	if match_board.canvas_layer == null or codex_panel != null:
		return

	codex_panel = PanelContainer.new()
	codex_panel.name = "CodexPanel"
	codex_panel.anchor_left = 0.0
	codex_panel.anchor_right = 0.0
	codex_panel.anchor_top = 1.0
	codex_panel.anchor_bottom = 1.0
	codex_panel.offset_left = panel_margin.x
	codex_panel.offset_right = panel_margin.x + panel_size.x
	codex_panel.offset_top = -panel_margin.y - panel_size.y
	codex_panel.offset_bottom = -panel_margin.y
	codex_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	codex_panel.z_index = 920
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.042, 0.038, 0.88)
	panel_style.border_color = Color(1.0, 0.92, 0.72, 0.34)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 12
	panel_style.content_margin_bottom = 10
	codex_panel.add_theme_stylebox_override("panel", panel_style)
	match_board.canvas_layer.add_child(codex_panel)

	var root := VBoxContainer.new()
	codex_panel.add_child(root)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	page_label = Label.new()
	root.add_child(page_label)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.add_theme_font_size_override("font_size", 16)
	page_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))

	counts_row = HBoxContainer.new()
	root.add_child(counts_row)
	counts_row.alignment = BoxContainer.ALIGNMENT_CENTER
	counts_row.add_theme_constant_override("separation", 6)
	count_labels.clear()
	for page_index in range(DeckManager.CODEX_PAGE_COUNT):
		var count_label := Label.new()
		counts_row.add_child(count_label)
		count_label.custom_minimum_size = Vector2(34, 24)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 14)
		count_labels.append(count_label)

	turn_page_button = Button.new()
	root.add_child(turn_page_button)
	turn_page_button.text = "Turn Page"
	turn_page_button.custom_minimum_size = Vector2(0, 34)
	turn_page_button.pressed.connect(on_turn_page_pressed)
	update_ui()

func update_ui() -> void:
	if codex_panel == null:
		return

	var owner_color: int = get_display_color()
	var page_index: int = get_page_index(owner_color)
	var page_counts: Array[int] = get_page_counts(owner_color)
	page_label.text = "%d. oldal / %d" % [page_index + 1, DeckManager.CODEX_PAGE_COUNT]
	for index in range(count_labels.size()):
		var count_label: Label = count_labels[index]
		var page_count: int = int(page_counts[index]) if index < page_counts.size() else 0
		count_label.text = "%d:%d" % [index + 1, page_count]
		count_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.44) if index == page_index else Color(0.82, 0.80, 0.74))
	if turn_page_button != null:
		turn_page_button.disabled = !can_turn_page_locally(owner_color)

func get_panel() -> PanelContainer:
	return codex_panel

func get_display_color() -> int:
	if match_board.can_control_current_turn():
		return match_board.get_controllable_color()
	return match_board.get_local_view_color()

func get_page_index(owner_color: int) -> int:
	return white_page_index if owner_color == 1 else black_page_index

func get_page_counts(owner_color: int) -> Array[int]:
	return white_page_counts if owner_color == 1 else black_page_counts

func get_pages(owner_color: int) -> Array:
	return white_pages if owner_color == 1 else black_pages

func set_page_index(owner_color: int, page_index: int) -> void:
	if owner_color == 1:
		white_page_index = clampi(page_index, 0, DeckManager.CODEX_PAGE_COUNT - 1)
	else:
		black_page_index = clampi(page_index, 0, DeckManager.CODEX_PAGE_COUNT - 1)
	sync_deck_from_local_codex(owner_color)

func set_pages(owner_color: int, pages: Array) -> void:
	if owner_color == 1:
		white_pages = pages
		white_page_counts = get_counts_from_pages(pages)
	else:
		black_pages = pages
		black_page_counts = get_counts_from_pages(pages)
	sync_deck_from_local_codex(owner_color)

func get_counts_from_pages(pages: Array) -> Array[int]:
	var counts: Array[int] = []
	for page_index in range(DeckManager.CODEX_PAGE_COUNT):
		if page_index < pages.size() and pages[page_index] is Array:
			counts.append((pages[page_index] as Array).size())
		else:
			counts.append(0)
	return counts

func apply_state_from_server(player_codex_state: Dictionary) -> void:
	for player_id in [0, 1]:
		var state_value = player_codex_state.get(player_id, player_codex_state.get(str(player_id), {}))
		if !(state_value is Dictionary):
			continue
		var state: Dictionary = state_value
		var owner_color: int = match_board.get_color_for_player_id(player_id)
		set_page_index(owner_color, int(state.get("current_page_index", 0)))
		var pages_value = state.get("pages", [])
		if pages_value is Array:
			set_pages(owner_color, parse_pages_from_state(pages_value))
		var counts_value = state.get("page_counts", [])
		var parsed_counts: Array[int] = [0, 0, 0, 0, 0]
		if counts_value is Array:
			for index in range(mini(parsed_counts.size(), (counts_value as Array).size())):
				parsed_counts[index] = int((counts_value as Array)[index])
		if owner_color == 1:
			white_page_counts = parsed_counts
			match_board.has_turned_page_this_turn[1] = bool(state.get("has_turned_page_this_turn", false))
		else:
			black_page_counts = parsed_counts
			match_board.has_turned_page_this_turn[-1] = bool(state.get("has_turned_page_this_turn", false))
	update_ui()

func parse_pages_from_state(pages_value: Array) -> Array:
	var pages: Array = []
	for page_index in range(DeckManager.CODEX_PAGE_COUNT):
		var page: Array[String] = []
		if page_index < pages_value.size() and pages_value[page_index] is Array:
			for stamp_value in pages_value[page_index]:
				var stamp_name: String = ""
				if stamp_value is Dictionary:
					stamp_name = str((stamp_value as Dictionary).get("stamp_name", ""))
				else:
					stamp_name = str(stamp_value)
				if !stamp_name.is_empty():
					page.append(stamp_name)
		pages.append(page)
	return pages

func can_turn_page_locally(owner_color: int) -> bool:
	if !match_board.can_control_current_turn():
		return false
	if owner_color != match_board.get_controllable_color():
		return false
	if !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_TURN_PAGE, {
		"owner_color": owner_color,
	}):
		return false
	if bool(match_board.has_turned_page_this_turn.get(owner_color, false)):
		return false
	if bool(match_board.attached_stamp_this_turn.get(owner_color, false)):
		return false
	return count_non_empty_pages(owner_color) > 1

func count_non_empty_pages(owner_color: int) -> int:
	var count: int = 0
	for page_count in get_page_counts(owner_color):
		if int(page_count) > 0:
			count += 1
	return count

func on_turn_page_pressed() -> void:
	var owner_color: int = match_board.get_controllable_color()
	if !match_board.is_tutorial_action_allowed(match_board.TUTORIAL_ACTION_TURN_PAGE, {
		"owner_color": owner_color,
	}, true):
		update_ui()
		return
	if !can_turn_page_locally(owner_color):
		update_ui()
		return
	if GameController.current_game_host:
		send_turn_page_action(owner_color)
		return
	turn_page_locally(owner_color)

func send_turn_page_action(owner_color: int) -> bool:
	return bool(GameController.send_action({
		"type": "turn_page",
		"player_id": match_board.get_player_id_for_color(owner_color),
	}))

func turn_page_locally(owner_color: int) -> void:
	var next_page_index: int = find_next_non_empty_page(owner_color, get_page_index(owner_color))
	if next_page_index == -1:
		return
	set_page_index(owner_color, next_page_index)
	match_board.has_turned_page_this_turn[owner_color] = true
	sync_hand_from_local_codex(owner_color)
	match_board.codex_page_turned.emit(owner_color, next_page_index)
	match_board.update_stamp_presentation()

func find_next_non_empty_page(owner_color: int, start_index: int) -> int:
	var counts: Array[int] = get_page_counts(owner_color)
	for offset in range(1, DeckManager.CODEX_PAGE_COUNT + 1):
		var candidate_index: int = (start_index + offset) % DeckManager.CODEX_PAGE_COUNT
		if candidate_index < counts.size() and int(counts[candidate_index]) > 0:
			return candidate_index
	return -1

func advance_empty_page_at_turn_start(owner_color: int) -> void:
	var page_index: int = get_page_index(owner_color)
	var counts: Array[int] = get_page_counts(owner_color)
	if page_index < counts.size() and int(counts[page_index]) > 0:
		return
	var next_page_index: int = find_next_non_empty_page(owner_color, page_index)
	if next_page_index == -1:
		return
	set_page_index(owner_color, next_page_index)
	sync_hand_from_local_codex(owner_color)

func remove_local_stamp(owner_color: int, stamp_index: int) -> void:
	var pages: Array = get_pages(owner_color)
	var page_index: int = get_page_index(owner_color)
	if page_index < 0 or page_index >= pages.size() or !(pages[page_index] is Array):
		return
	var page: Array = pages[page_index]
	if stamp_index < 0 or stamp_index >= page.size():
		return
	page.remove_at(stamp_index)
	pages[page_index] = page
	set_pages(owner_color, pages)
	update_ui()

func return_local_seeker_stamp(owner_color: int, stamp: Stamp) -> void:
	if stamp == null:
		return
	var pages: Array = get_pages(owner_color)
	var page_index: int = int(stamp.get_meta("codex_page_index", get_page_index(owner_color)))
	var stamp_index: int = int(stamp.get_meta("codex_stamp_index", -1))
	page_index = clampi(page_index, 0, DeckManager.CODEX_PAGE_COUNT - 1)
	while pages.size() < DeckManager.CODEX_PAGE_COUNT:
		pages.append([])
	var page = pages[page_index]
	if !(page is Array):
		page = []
	var stamps: Array = page
	var insert_index: int = clampi(stamp_index, 0, stamps.size()) if stamp_index >= 0 else stamps.size()
	stamps.insert(insert_index, stamp.stamp_name)
	pages[page_index] = stamps
	set_pages(owner_color, pages)
	if page_index == get_page_index(owner_color):
		sync_hand_from_local_codex(owner_color)
	else:
		update_ui()

func sync_hand_from_local_codex(owner_color: int) -> void:
	var pages: Array = get_pages(owner_color)
	var page_index: int = get_page_index(owner_color)
	var page_names: Array = []
	if page_index >= 0 and page_index < pages.size() and pages[page_index] is Array:
		page_names = pages[page_index]
	var stamps: Array[Stamp] = match_board.create_stamp_hand_from_names(page_names)
	if owner_color == 1:
		match_board.white_stamp_hand = stamps
		match_board.white_stamp_visuals = match_board.populate_stamp_hand(match_board.white_pieces, match_board.white_stamp_hand, 1)
	else:
		match_board.black_stamp_hand = stamps
		match_board.black_stamp_visuals = match_board.populate_stamp_hand(match_board.black_pieces, match_board.black_stamp_hand, -1)
	sync_deck_from_local_codex(owner_color)
	match_board.setup_deck_visuals()

func sync_deck_from_local_codex(owner_color: int) -> void:
	var pages: Array = get_pages(owner_color)
	var closed_page_names: Array[String] = DeckManager.flatten_codex_pages(pages, get_page_index(owner_color))
	if owner_color == 1:
		match_board.white_stamp_deck = closed_page_names
	else:
		match_board.black_stamp_deck = closed_page_names
