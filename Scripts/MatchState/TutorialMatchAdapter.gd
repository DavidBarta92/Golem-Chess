extends RefCounted

var match_board
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var board_size: int = BoardConfig.BOARD_SIZE

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)
	board_size = int(config.get("board_size", board_size))

func set_constraints(constraints: Dictionary) -> void:
	match_board.tutorial_constraints = constraints.duplicate(true)
	match_board.tutorial_constraints_enabled = !match_board.tutorial_constraints.is_empty() and bool(match_board.tutorial_constraints.get("enabled", true))
	refresh_dependent_ui()

func set_mode_active(active: bool) -> void:
	match_board.tutorial_mode_active = active

func clear_constraints() -> void:
	match_board.tutorial_constraints.clear()
	match_board.tutorial_constraints_enabled = false
	refresh_dependent_ui()

func refresh_dependent_ui() -> void:
	match_board.update_stamp_drag_permissions()
	match_board.update_end_turn_button()
	match_board.get_turn_hud_controller().update_action_status_ui()
	if match_board.state:
		match_board.show_options()

func is_action_allowed(action_name: String, context: Dictionary = {}, emit_rejection: bool = false) -> bool:
	if !match_board.tutorial_constraints_enabled:
		return true
	if !is_action_name_allowed(action_name):
		return reject_action(action_name, context, emit_rejection)

	var allowed: bool = true
	match action_name:
		match_board.TUTORIAL_ACTION_SELECT_PIECE:
			if context.has("piece_pos"):
				allowed = vector_allowed(["allowed_select_piece_positions", "allowed_move_sources", "allowed_piece_positions", "allowed_pieces"], context.get("piece_pos"))
		match_board.TUTORIAL_ACTION_ATTACH_STAMP:
			if context.has("piece_pos"):
				allowed = allowed and vector_allowed(["allowed_attach_piece_positions", "allowed_piece_positions", "allowed_pieces"], context.get("piece_pos"))
			if context.has("stamp_name"):
				allowed = allowed and string_allowed(["allowed_attach_stamp_names", "allowed_stamp_names", "allowed_stamps"], str(context.get("stamp_name", "")))
		match_board.TUTORIAL_ACTION_MOVE_PIECE:
			if context.has("from_pos"):
				allowed = allowed and vector_allowed(["allowed_move_sources", "allowed_piece_positions", "allowed_pieces"], context.get("from_pos"))
			if context.has("to_pos"):
				allowed = allowed and vector_allowed(["allowed_move_targets"], context.get("to_pos"))
		match_board.TUTORIAL_ACTION_EXCHANGE_STAMP:
			if context.has("stamp_name"):
				allowed = allowed and string_allowed(["allowed_exchange_stamp_names", "allowed_stamp_names", "allowed_stamps"], str(context.get("stamp_name", "")))

	if !allowed:
		return reject_action(action_name, context, emit_rejection)
	return true

func is_action_name_allowed(action_name: String) -> bool:
	if !match_board.tutorial_constraints.has("allowed_actions"):
		return true
	var allowed_actions: Array = constraint_array(["allowed_actions"])
	return allowed_actions.has(action_name)

func reject_action(action_name: String, context: Dictionary, emit_rejection: bool) -> bool:
	if emit_rejection:
		match_board.tutorial_action_rejected.emit(action_name, context.duplicate(true))
	return false

func string_allowed(keys: Array, candidate: String) -> bool:
	if !has_constraint(keys):
		return true
	var allowed_values: Array = constraint_array(keys)
	for value in allowed_values:
		if str(value) == candidate:
			return true
	return false

func vector_allowed(keys: Array, candidate) -> bool:
	if !has_constraint(keys):
		return true
	var allowed_values: Array = constraint_array(keys)

	var candidate_pos: Vector2 = match_board.value_to_vector2(candidate, invalid_board_pos)
	if candidate_pos == invalid_board_pos:
		return false
	for value in allowed_values:
		if match_board.value_to_vector2(value, invalid_board_pos) == candidate_pos:
			return true
	return false

func constraint_array(keys: Array) -> Array:
	for key_value in keys:
		var key: String = str(key_value)
		if !match_board.tutorial_constraints.has(key):
			continue
		var value = match_board.tutorial_constraints[key]
		if value is Array:
			return value
	return []

func has_constraint(keys: Array) -> bool:
	for key_value in keys:
		if match_board.tutorial_constraints.has(str(key_value)):
			return true
	return false

func can_auto_end_turn_now() -> bool:
	if !match_board.tutorial_constraints_enabled:
		return true
	return bool(match_board.tutorial_constraints.get("allow_auto_end_turn", false))

func apply_setup(setup: Dictionary) -> void:
	if setup.has("board"):
		set_board_from_array(setup.get("board", []))
	if setup.has("attached_stamps"):
		set_attached_stamps(setup.get("attached_stamps", []))
	if setup.has("white_hand"):
		set_stamp_hand(1, setup.get("white_hand", []))
	if setup.has("black_hand"):
		set_stamp_hand(-1, setup.get("black_hand", []))
	if setup.has("white_deck"):
		set_stamp_deck(1, setup.get("white_deck", []))
	if setup.has("black_deck"):
		set_stamp_deck(-1, setup.get("black_deck", []))
	if setup.has("turn_color"):
		set_turn(int(setup.get("turn_color", 1)))
	if bool(setup.get("reset_turn_state", true)):
		reset_turn_state()

	match_board.update_stamp_presentation()
	match_board.display_board()

func set_board_from_array(board_data: Array) -> void:
	if board_data.is_empty():
		return

	match_board.board = BoardConfig.create_empty_board()
	for row in range(mini(board_data.size(), board_size)):
		var row_data: Array = board_data[row] if board_data[row] is Array else []
		for col in range(mini(row_data.size(), board_size)):
			match_board.board[row][col] = int(row_data[col])

	match_board.piece_objects.clear()
	match_board.create_pieces_from_board()
	match_board.current_board_effects.clear()
	match_board.current_last_move.clear()
	match_board.state = false
	match_board.delete_dots()

func set_attached_stamps(attached_stamps: Array) -> void:
	for entry_value in attached_stamps:
		if !(entry_value is Dictionary):
			continue

		var entry: Dictionary = entry_value
		var piece_pos: Vector2 = match_board.value_to_vector2(entry.get("pos", invalid_board_pos), invalid_board_pos)
		if !match_board.piece_objects.has(piece_pos):
			continue

		var stamp_name: String = str(entry.get("stamp_name", ""))
		var stamp: Stamp = StampLibrary.duplicate_stamp(stamp_name)
		if stamp == null:
			push_warning("Tutorial attached stamp not found: %s" % stamp_name)
			continue

		var piece: Piece = match_board.piece_objects[piece_pos] as Piece
		piece.attach_stamp(stamp, bool(entry.get("exhausted", false)))
		piece.turns_remaining = int(entry.get("turns_remaining", stamp.duration))

func reset_turn_state() -> void:
	for owner_color in [1, -1]:
		match_board.attached_stamp_this_turn[owner_color] = false
		match_board.attached_stamp_count_this_turn[match_board.get_player_id_for_color(owner_color)] = 0
		match_board.moved_piece_this_turn[owner_color] = false
		match_board.exchanged_stamp_this_turn[owner_color] = false
		match_board.has_turned_page_this_turn[owner_color] = false
		match_board.played_stamp_hand_slots_this_turn[owner_color] = []
		match_board.exchanged_stamp_names_this_turn[owner_color] = []
	match_board.local_auto_end_turn_pending = false
	match_board.state = false
	match_board.delete_dots()

func set_stamp_hand(owner_color: int, stamp_names: Array) -> void:
	var stamps: Array[Stamp] = match_board.create_stamp_hand_from_names(stamp_names)
	if owner_color == 1:
		match_board.white_stamp_hand = stamps
		match_board.white_stamp_visuals = match_board.populate_stamp_hand(match_board.white_pieces, match_board.white_stamp_hand, 1)
		match_board.set_codex_page_index(1, 0)
		match_board.set_codex_pages(1, DeckManager.create_codex_pages(stamp_names))
	else:
		match_board.black_stamp_hand = stamps
		match_board.black_stamp_visuals = match_board.populate_stamp_hand(match_board.black_pieces, match_board.black_stamp_hand, -1)
		match_board.set_codex_page_index(-1, 0)
		match_board.set_codex_pages(-1, DeckManager.create_codex_pages(stamp_names))
	match_board.setup_deck_visuals()

func set_stamp_deck(owner_color: int, stamp_names: Array) -> void:
	var deck_names: Array[String] = []
	for stamp_name_value in stamp_names:
		deck_names.append(str(stamp_name_value))

	var pages: Array = match_board.get_codex_pages(owner_color)
	while pages.size() < DeckManager.CODEX_PAGE_COUNT:
		pages.append([])
	var stamp_index: int = 0
	for page_index in range(1, DeckManager.CODEX_PAGE_COUNT):
		var page: Array[String] = []
		for _slot_index in range(DeckManager.CODEX_STAMPS_PER_PAGE):
			if stamp_index >= deck_names.size():
				break
			page.append(deck_names[stamp_index])
			stamp_index += 1
		pages[page_index] = page

	if owner_color == 1:
		match_board.set_codex_pages(1, pages)
		match_board.white_deck_count_override = -1
	else:
		match_board.set_codex_pages(-1, pages)
		match_board.black_deck_count_override = -1
	match_board.setup_deck_visuals()

func set_turn(owner_color: int) -> void:
	var was_white_turn: bool = match_board.white
	match_board.white = owner_color == 1
	if was_white_turn != match_board.white:
		match_board.get_turn_action_state_controller().reset_current_turn_stamp_attach()
