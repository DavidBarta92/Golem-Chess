extends RefCounted

var match_board

var white_page_index: int = 0
var black_page_index: int = 0
var white_page_counts: Array[int] = [0, 0, 0, 0, 0]
var black_page_counts: Array[int] = [0, 0, 0, 0, 0]
var white_pages: Array = []
var black_pages: Array = []

## Pale type on the dark rim, and the page in hand picked out in reverse.
const PAGE_TEXT_COLOR: Color = Color(0.82, 0.80, 0.74)
const CURRENT_PAGE_TEXT_COLOR: Color = UiPalette.INK
const CURRENT_PAGE_DISC_COLOR: Color = Color(1.0, 1.0, 1.0)

var codex_panel: Control
var counts_row: HBoxContainer
var turn_page_button: Button
var count_labels: Array[Label] = []
var count_slots: Array[PanelContainer] = []

var _current_page_style: StyleBoxFlat
var _plain_slot_style: StyleBoxEmpty

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)

func create_ui() -> void:
	if match_board.canvas_layer == null or codex_panel != null:
		return

	codex_panel = match_board.canvas_layer.get_node_or_null("CodexPanel")
	if codex_panel == null:
		return

	counts_row = codex_panel.find_child("CountsRow", true, false) as HBoxContainer
	turn_page_button = codex_panel.find_child("TurnPageButton", true, false) as Button
	if counts_row == null or turn_page_button == null:
		return

	count_labels.clear()
	count_slots.clear()
	for child in counts_row.get_children():
		var slot := child as PanelContainer
		if slot != null:
			count_slots.append(slot)
			count_labels.append(slot.get_node("CountLabel") as Label)
			continue
	_build_page_disc_style()

	turn_page_button.text = tr("Turn Page")
	turn_page_button.pressed.connect(on_turn_page_pressed)
	counts_row.get_viewport().size_changed.connect(place_counts_row)
	update_ui()

## A disc, not a rounded box: the slots are square and the radius is half their
## side, so the page the player is on reads as a filled white dot with its
## number sitting in it.
func _build_page_disc_style() -> void:
	_current_page_style = StyleBoxFlat.new()
	_current_page_style.bg_color = CURRENT_PAGE_DISC_COLOR
	var radius: int = int(count_slots[0].custom_minimum_size.y * 0.5)
	_current_page_style.corner_radius_top_left = radius
	_current_page_style.corner_radius_top_right = radius
	_current_page_style.corner_radius_bottom_left = radius
	_current_page_style.corner_radius_bottom_right = radius
	_plain_slot_style = StyleBoxEmpty.new()

## Stands the counter on the board's near rim. The room's art is scaled to
## cover the viewport, so where that rim lands depends on the window's shape;
## BoardCanvas knows the conversion.
func place_counts_row() -> void:
	if counts_row == null or !is_instance_valid(counts_row):
		return
	var viewport_size: Vector2 = counts_row.get_viewport_rect().size
	var centre: Vector2 = BoardCanvas.to_viewport(BoardCanvas.RIM_CENTRE, viewport_size)
	counts_row.size = counts_row.get_combined_minimum_size()
	counts_row.position = centre - counts_row.size * 0.5

func update_ui() -> void:
	if codex_panel == null:
		return

	var owner_color: int = get_display_color()
	var page_index: int = get_page_index(owner_color)
	var page_counts: Array[int] = get_page_counts(owner_color)
	for index in range(count_labels.size()):
		var count_label: Label = count_labels[index]
		var page_count: int = int(page_counts[index]) if index < page_counts.size() else 0
		count_label.text = "%d:%d" % [index + 1, page_count]
		var is_current_page: bool = index == page_index
		count_label.add_theme_color_override(
			"font_color",
			CURRENT_PAGE_TEXT_COLOR if is_current_page else PAGE_TEXT_COLOR
		)
		count_slots[index].add_theme_stylebox_override(
			"panel",
			_current_page_style if is_current_page else _plain_slot_style
		)
	place_counts_row()
	if turn_page_button != null:
		turn_page_button.disabled = !can_turn_page_locally(owner_color)

## Where a stamp flies from and back to when there is no deck visual to aim
## at. The counter now stands in for the old box, since that is where the
## codex reads from on screen.
func get_panel() -> Control:
	return counts_row

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
		var previous_page_index: int = get_page_index(owner_color)
		var new_page_index: int = int(state.get("current_page_index", 0))
		set_page_index(owner_color, new_page_index)
		if new_page_index != previous_page_index and owner_color != match_board.get_own_color() and !match_board.should_skip_visual_animations():
			SFXManager.play("codex_fold")
			match_board.play_opponent_codex_page_turn_animation()
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
	if bool(match_board.affixed_stamp_this_turn.get(owner_color, false)):
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
	match_board.play_codex_page_turn_animation()
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
	match_board.codex_page_turned.emit(owner_color, next_page_index)
	match_board.update_stamp_presentation()
	# Swap the visible cards only once the codex has actually left the
	# screen, not right away -- otherwise the old->new hand change would be
	# visible while it's still sliding down.
	match_board.run_when_codex_off_screen(Callable(self, "finish_turn_page_locally").bind(owner_color))

func finish_turn_page_locally(owner_color: int) -> void:
	sync_hand_from_local_codex(owner_color)
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
