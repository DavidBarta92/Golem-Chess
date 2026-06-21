extends RefCounted

var board: Array
var piece_objects: Dictionary
var local_pending_respawns: Dictionary
var moved_piece_this_turn: Dictionary
var played_card_hand_slots_this_turn: Dictionary
var player_base_fields: Dictionary
var board_effects: Array
var board_size: int = BoardConfig.BOARD_SIZE
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var fragment_group_none: String = ""
var fragment_group_bottom: String = "bottom"
var fragment_group_top: String = "top"
var fragment_group_pending: String = "pending"

var player_id_for_color_provider: Callable
var card_hand_provider: Callable
var card_deck_provider: Callable
var current_turn_color_provider: Callable
var moved_piece_this_turn_provider: Callable
var can_exchange_card_provider: Callable
var create_board_tiles_callback: Callable

func configure(config: Dictionary) -> void:
	board = config.get("board", board)
	piece_objects = config.get("piece_objects", piece_objects)
	local_pending_respawns = config.get("local_pending_respawns", local_pending_respawns)
	moved_piece_this_turn = config.get("moved_piece_this_turn", moved_piece_this_turn)
	played_card_hand_slots_this_turn = config.get("played_card_hand_slots_this_turn", played_card_hand_slots_this_turn)
	player_base_fields = config.get("player_base_fields", player_base_fields)
	board_effects = config.get("board_effects", board_effects)
	board_size = int(config.get("board_size", board_size))
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)
	fragment_group_none = str(config.get("fragment_group_none", fragment_group_none))
	fragment_group_bottom = str(config.get("fragment_group_bottom", fragment_group_bottom))
	fragment_group_top = str(config.get("fragment_group_top", fragment_group_top))
	fragment_group_pending = str(config.get("fragment_group_pending", fragment_group_pending))
	player_id_for_color_provider = config.get("player_id_for_color_provider", player_id_for_color_provider)
	card_hand_provider = config.get("card_hand_provider", card_hand_provider)
	card_deck_provider = config.get("card_deck_provider", card_deck_provider)
	current_turn_color_provider = config.get("current_turn_color_provider", current_turn_color_provider)
	moved_piece_this_turn_provider = config.get("moved_piece_this_turn_provider", moved_piece_this_turn_provider)
	can_exchange_card_provider = config.get("can_exchange_card_provider", can_exchange_card_provider)
	create_board_tiles_callback = config.get("create_board_tiles_callback", create_board_tiles_callback)

func move_piece_on_board(start_pos: Vector2, end_pos: Vector2) -> Dictionary:
	var moving_color: int = 1 if board[start_pos.x][start_pos.y] > 0 else -1
	var captured_piece: Piece = piece_objects[end_pos] as Piece if piece_objects.has(end_pos) else null
	var moving_piece_visible_to_enemy: bool = true

	if piece_objects.has(start_pos):
		var piece: Piece = piece_objects[start_pos] as Piece
		moving_piece_visible_to_enemy = !CardEffectResolver.piece_has_attached_effect(piece, CardEffect.TYPE_INVISIBLE_TO_ENEMY)
		piece.position = end_pos
		piece_objects.erase(start_pos)
		piece_objects[end_pos] = piece
		DebugLog.info("  Piece moved: %s -> %s" % [start_pos, end_pos])

	board[end_pos.x][end_pos.y] = board[start_pos.x][start_pos.y]
	board[start_pos.x][start_pos.y] = 0

	return {
		"moving_color": moving_color,
		"captured_piece": captured_piece,
		"captured_nexus": is_nexus_piece(captured_piece),
		"moving_piece_visible_to_enemy": moving_piece_visible_to_enemy,
	}

func apply_piece_move(start_pos: Vector2, end_pos: Vector2) -> Dictionary:
	var move_state: Dictionary = move_piece_on_board(start_pos, end_pos)
	var moving_color: int = int(move_state.get("moving_color", 0))
	var moving_piece_visible_to_enemy: bool = bool(move_state.get("moving_piece_visible_to_enemy", true))
	move_state["last_move"] = create_last_move_record(moving_color, start_pos, end_pos, moving_piece_visible_to_enemy)
	move_state["winner_color"] = get_winner_after_move(moving_color, end_pos)
	return move_state

func create_last_move_record(moving_color: int, from_pos: Vector2, to_pos: Vector2, visible_to_enemy: bool) -> Dictionary:
	if from_pos == to_pos:
		return {}

	return {
		"from": from_pos,
		"to": to_pos,
		"player_id": get_player_id_for_color(moving_color),
		"piece_color": moving_color,
		"visible_to_enemy": visible_to_enemy,
	}

func record_played_card_hand_slot(owner_color: int, current_hand_index: int) -> void:
	if current_hand_index < 0:
		return
	var played_slots: Array = played_card_hand_slots_this_turn.get(owner_color, [])
	played_slots.append(get_original_hand_slot_for_play(owner_color, current_hand_index))
	played_card_hand_slots_this_turn[owner_color] = played_slots

func get_original_hand_slot_for_play(owner_color: int, current_hand_index: int) -> int:
	var played_slots: Array = played_card_hand_slots_this_turn.get(owner_color, [])
	for candidate in range(current_hand_index, DeckManager.HAND_SIZE):
		if played_slots.has(candidate):
			continue

		var previous_slots_before_candidate: int = 0
		for slot_value in played_slots:
			if int(slot_value) < candidate:
				previous_slots_before_candidate += 1
		if candidate - previous_slots_before_candidate == current_hand_index:
			return candidate
	return clampi(current_hand_index, 0, DeckManager.HAND_SIZE - 1)

func respawn_captured_piece(captured_piece: Piece) -> Dictionary:
	if captured_piece == null:
		return {
			"respawn_pos": invalid_board_pos,
			"fragment_group": fragment_group_none,
		}

	var released_respawn_pos: Vector2 = release_pending_respawn_piece(captured_piece.color)
	if released_respawn_pos != invalid_board_pos:
		return {
			"respawn_pos": released_respawn_pos,
			"fragment_group": fragment_group_top,
		}
	if release_pending_edge_respawn_piece(captured_piece.color):
		return {
			"respawn_pos": invalid_board_pos,
			"fragment_group": fragment_group_none,
		}

	var respawn_pos: Vector2 = get_random_empty_home_position(captured_piece.color)
	if respawn_pos == invalid_board_pos:
		queue_pending_edge_respawn_piece(captured_piece)
		push_warning("No empty non-base home row square for captured piece respawn. Piece queued.")
		return {
			"respawn_pos": invalid_board_pos,
			"fragment_group": fragment_group_pending,
		}

	captured_piece.position = respawn_pos
	captured_piece.set_respawn_cooldown(GameConfig.RESPAWN_COOLDOWN_OWN_TURNS)
	piece_objects[respawn_pos] = captured_piece
	board[respawn_pos.x][respawn_pos.y] = captured_piece.color
	return {
		"respawn_pos": respawn_pos,
		"fragment_group": fragment_group_bottom,
	}

func resolve_capture_respawn(captured_piece: Piece) -> Dictionary:
	var respawn_info: Dictionary = {
		"respawn_pos": invalid_board_pos,
		"fragment_group": fragment_group_none,
	}
	if captured_piece != null:
		respawn_info = respawn_captured_piece(captured_piece)

	var pending_respawn_arrivals: Array[Dictionary] = []
	pending_respawn_arrivals.append_array(resolve_pending_respawns_for_all())
	return {
		"respawn_pos": value_to_vector2(respawn_info.get("respawn_pos", invalid_board_pos), invalid_board_pos),
		"fragment_group": str(respawn_info.get("fragment_group", fragment_group_none)),
		"pending_respawn_arrivals": pending_respawn_arrivals,
	}

func release_pending_respawn_piece(owner_color: int) -> Vector2:
	for position_value in piece_objects:
		var board_pos: Vector2 = value_to_vector2(position_value, invalid_board_pos)
		var piece: Piece = piece_objects[position_value] as Piece
		if piece != null and piece.color == owner_color and piece.is_respawn_locked():
			piece.set_respawn_cooldown(0)
			return board_pos
	return invalid_board_pos

func release_pending_edge_respawn_piece(owner_color: int) -> bool:
	var pending_respawns: Array = get_pending_respawns_for_color(owner_color)
	for piece_value in pending_respawns:
		var piece: Piece = piece_value as Piece
		if piece != null and piece.is_respawn_locked():
			piece.set_respawn_cooldown(0)
			return true
	return false

func queue_pending_edge_respawn_piece(captured_piece: Piece) -> void:
	if captured_piece == null:
		return

	captured_piece.position = invalid_board_pos
	captured_piece.set_respawn_cooldown(GameConfig.RESPAWN_COOLDOWN_OWN_TURNS)
	var pending_respawns: Array = get_pending_respawns_for_color(captured_piece.color)
	pending_respawns.append(captured_piece)
	local_pending_respawns[captured_piece.color] = pending_respawns

func get_pending_respawns_for_color(owner_color: int) -> Array:
	if !local_pending_respawns.has(owner_color):
		local_pending_respawns[owner_color] = []
	return local_pending_respawns[owner_color]

func resolve_pending_respawns_for_all() -> Array[Dictionary]:
	var arrivals: Array[Dictionary] = []
	for owner_color in [1, -1]:
		arrivals.append_array(resolve_pending_respawns(owner_color))
	return arrivals

func resolve_pending_respawns(owner_color: int) -> Array[Dictionary]:
	var arrivals: Array[Dictionary] = []
	var pending_respawns: Array = get_pending_respawns_for_color(owner_color)
	while !pending_respawns.is_empty():
		var respawn_pos: Vector2 = get_random_empty_home_position(owner_color)
		if respawn_pos == invalid_board_pos:
			break

		var piece: Piece = pending_respawns.pop_front() as Piece
		if piece == null:
			continue

		piece.position = respawn_pos
		piece_objects[respawn_pos] = piece
		board[respawn_pos.x][respawn_pos.y] = piece.color
		arrivals.append({
			"player_id": get_player_id_for_color(piece.color),
			"piece_color": piece.color,
			"respawn_pos": respawn_pos,
			"respawn_cooldown_turns": piece.respawn_cooldown_turns,
		})

	local_pending_respawns[owner_color] = pending_respawns
	return arrivals

func get_random_empty_home_position(owner_color: int) -> Vector2:
	var player_id: int = get_player_id_for_color(owner_color)
	var home_row: int = BoardConfig.get_home_row_for_player_id(player_id)
	var empty_positions: Array[Vector2] = []
	for col in BoardConfig.BOARD_SIZE:
		var pos: Vector2 = Vector2(home_row, col)
		if !piece_objects.has(pos) and !is_base_field(pos):
			empty_positions.append(pos)

	if empty_positions.is_empty():
		return invalid_board_pos

	return empty_positions[randi() % empty_positions.size()]

func move_base_effect(source_pos: Vector2, piece: Piece, card: Card) -> Array[Dictionary]:
	var pending_respawn_arrivals: Array[Dictionary] = []
	if piece == null or card == null:
		return pending_respawn_arrivals

	var raw_target_squares: Array[Vector2] = CardEffectResolver.get_effect_squares_unfiltered(card, source_pos, piece.color)
	if raw_target_squares.is_empty():
		return pending_respawn_arrivals

	var target_pos: Vector2 = raw_target_squares[0]
	var player_id: int = get_player_id_for_color(piece.color)
	if !is_valid_position(target_pos):
		DebugLog.info("Local move base ignored: target outside board: %s" % target_pos)
		return pending_respawn_arrivals
	if is_base_field_for_other_player(target_pos, player_id):
		DebugLog.info("Local move base ignored: target already contains another base: %s" % target_pos)
		return pending_respawn_arrivals

	player_base_fields[player_id] = target_pos
	pending_respawn_arrivals.append_array(resolve_pending_respawns_for_all())
	if create_board_tiles_callback.is_valid():
		create_board_tiles_callback.call()
	return pending_respawn_arrivals

func apply_card_effect_trigger(trigger: String, source_pos: Vector2, piece: Piece, card: Card) -> Array[Dictionary]:
	var pending_respawn_arrivals: Array[Dictionary] = []
	if piece == null or card == null or !card.has_effect() or card.effect_trigger != trigger:
		return pending_respawn_arrivals

	match card.effect_type:
		CardEffect.TYPE_MOVE_BASE:
			pending_respawn_arrivals.append_array(move_base_effect(source_pos, piece, card))
		CardEffect.TYPE_INVALID_SQUARES, CardEffect.TYPE_FROZEN_SQUARES:
			add_board_zone_effect(source_pos, piece, card)
	return pending_respawn_arrivals

func add_board_zone_effect(source_pos: Vector2, piece: Piece, card: Card) -> void:
	if piece == null or card == null:
		return

	var squares: Array[Vector2] = CardEffectResolver.get_effect_squares(card, source_pos, board_size, piece.color)
	if card.effect_type == CardEffect.TYPE_INVALID_SQUARES or card.effect_type == CardEffect.TYPE_FROZEN_SQUARES:
		squares = filter_base_fields_from_effect_squares(squares)
	if squares.is_empty():
		return

	var turns_remaining: int = int(card.effect_settings.get("turns_remaining", card.duration))
	if turns_remaining == 0:
		turns_remaining = 1

	board_effects.append({
		"effect_type": card.effect_type,
		"owner_player_id": get_player_id_for_color(piece.color),
		"target_player_id": int(card.effect_settings.get("target_player_id", -1)),
		"squares": squares,
		"turns_remaining": turns_remaining,
	})

func tick_board_effects() -> void:
	var remaining_effects: Array = []
	for effect_value in board_effects:
		if !(effect_value is Dictionary):
			continue

		var effect: Dictionary = effect_value
		var turns_remaining: int = int(effect.get("turns_remaining", -1))
		if turns_remaining == -1:
			remaining_effects.append(effect)
			continue

		turns_remaining -= 1
		if turns_remaining <= 0:
			continue

		effect["turns_remaining"] = turns_remaining
		remaining_effects.append(effect)

	board_effects.clear()
	board_effects.append_array(remaining_effects)

func clear_piece_exhaustion_for_color(owner_color: int) -> void:
	for position_value in piece_objects:
		var piece: Piece = piece_objects[position_value] as Piece
		if piece != null and piece.color == owner_color:
			if piece.is_respawn_locked():
				continue
			piece.exhausted_this_turn = false

func filter_base_fields_from_effect_squares(squares: Array[Vector2]) -> Array[Vector2]:
	var filtered_squares: Array[Vector2] = []
	for square_pos: Vector2 in squares:
		if !is_base_field(square_pos):
			filtered_squares.append(square_pos)
	return filtered_squares

func player_has_available_nexus_card(owner_color: int) -> bool:
	for card: Card in get_card_hand(owner_color):
		if MoveRules.is_nexus_card(card):
			return true
	if DeckManager.has_nexus_card(get_card_deck(owner_color)):
		return true
	for position_value in piece_objects:
		var piece: Piece = piece_objects[position_value] as Piece
		if piece != null and piece.color == owner_color and MoveRules.is_nexus_card(piece.attached_card):
			return true
	return false

func get_winner_after_move(moving_color: int, end_pos: Vector2) -> int:
	if is_opponent_base_field(moving_color, end_pos) and is_nexus_piece_at(end_pos):
		return moving_color
	return 0

func is_opponent_base_field(moving_color: int, pos: Vector2) -> bool:
	var owner_player_id: int = get_player_id_for_color(moving_color)
	var opponent_player_id: int = 1 - owner_player_id
	return pos == get_base_field_for_player(opponent_player_id)

func get_base_field_for_player(player_id: int) -> Vector2:
	return player_base_fields.get(player_id, BoardConfig.get_base_field_for_player_id(player_id))

func is_base_field(pos: Vector2) -> bool:
	for player_id in [0, 1]:
		if pos == BoardConfig.get_base_field_for_player_id(player_id):
			return true
		if pos == get_base_field_for_player(player_id):
			return true
	return false

func is_base_field_for_other_player(pos: Vector2, owner_player_id: int) -> bool:
	for player_id in [0, 1]:
		if player_id == owner_player_id:
			continue
		if pos == get_base_field_for_player(player_id):
			return true
	return false

func has_any_piece(owner_color: int) -> bool:
	return MoveRules.has_any_piece(piece_objects, owner_color)

func is_nexus_piece(piece: Piece) -> bool:
	return piece != null and MoveRules.is_nexus_card(piece.attached_card)

func is_nexus_piece_at(piece_position: Vector2) -> bool:
	if !piece_objects.has(piece_position):
		return false
	return is_nexus_piece(piece_objects[piece_position] as Piece)

func current_player_has_valid_turn_action() -> bool:
	var current_color: int = get_current_turn_color()
	var hand_cards: Array[Card] = get_card_hand(current_color)
	if !has_moved_piece_this_turn(current_color) and MoveRules.has_valid_piece_move(piece_objects, current_color, board_size, board_effects):
		return true
	if MoveRules.has_valid_attachment_move(piece_objects, current_color, hand_cards, board_size, board_effects):
		return true
	if can_exchange_card(current_color):
		return true
	return false

func get_card_hand(owner_color: int) -> Array[Card]:
	if card_hand_provider.is_valid():
		var value = card_hand_provider.call(owner_color)
		if value is Array:
			return value
	return []

func get_card_deck(owner_color: int) -> Array[String]:
	if card_deck_provider.is_valid():
		var value = card_deck_provider.call(owner_color)
		if value is Array:
			return value
	return []

func get_current_turn_color() -> int:
	if current_turn_color_provider.is_valid():
		return int(current_turn_color_provider.call())
	return 1

func has_moved_piece_this_turn(owner_color: int) -> bool:
	if moved_piece_this_turn_provider.is_valid():
		return bool(moved_piece_this_turn_provider.call(owner_color))
	return false

func can_exchange_card(owner_color: int) -> bool:
	if can_exchange_card_provider.is_valid():
		return bool(can_exchange_card_provider.call(owner_color))
	return false

func get_player_id_for_color(owner_color: int) -> int:
	if player_id_for_color_provider.is_valid():
		return int(player_id_for_color_provider.call(owner_color))
	return 0

func is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < board_size and pos.y >= 0 and pos.y < board_size

func value_to_vector2(value, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		var vector_value: Vector2i = value
		return Vector2(vector_value.x, vector_value.y)
	if value is Array:
		var array_value: Array = value
		if array_value.size() >= 2:
			return Vector2(float(array_value[0]), float(array_value[1]))
	if value is Dictionary:
		var dict_value: Dictionary = value
		if dict_value.has("x") and dict_value.has("y"):
			return Vector2(float(dict_value.x), float(dict_value.y))
	return fallback
