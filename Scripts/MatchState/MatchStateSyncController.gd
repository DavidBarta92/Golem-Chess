extends RefCounted

var board_size: int = BoardConfig.BOARD_SIZE
var invalid_board_pos: Vector2 = Vector2(-1, -1)
var white_base_field: Vector2 = BoardConfig.WHITE_BASE_FIELD
var black_base_field: Vector2 = BoardConfig.BLACK_BASE_FIELD
var fragment_group_none: String = ""
var fragment_group_bottom: String = "bottom"
var fragment_group_top: String = "top"
var fragment_group_pending: String = "pending"
var default_piece_texture_provider: Callable
var card_piece_texture_provider: Callable

func configure(config: Dictionary) -> void:
	board_size = int(config.get("board_size", board_size))
	invalid_board_pos = config.get("invalid_board_pos", invalid_board_pos)
	white_base_field = config.get("white_base_field", white_base_field)
	black_base_field = config.get("black_base_field", black_base_field)
	fragment_group_none = str(config.get("fragment_group_none", fragment_group_none))
	fragment_group_bottom = str(config.get("fragment_group_bottom", fragment_group_bottom))
	fragment_group_top = str(config.get("fragment_group_top", fragment_group_top))
	fragment_group_pending = str(config.get("fragment_group_pending", fragment_group_pending))
	default_piece_texture_provider = config.get("default_piece_texture_provider", default_piece_texture_provider)
	card_piece_texture_provider = config.get("card_piece_texture_provider", card_piece_texture_provider)

func get_hand_names_from_state(player_hands: Dictionary, player_id: int) -> Array:
	if player_hands.has(player_id):
		return player_hands[player_id]
	var string_key: String = str(player_id)
	if player_hands.has(string_key):
		return player_hands[string_key]
	return []

func get_int_from_state_dict(data: Dictionary, player_id: int, default_value: int) -> int:
	if data.has(player_id):
		return int(data[player_id])
	var string_key: String = str(player_id)
	if data.has(string_key):
		return int(data[string_key])
	return default_value

func get_card_names_from_hand(cards: Array[Card]) -> Array[String]:
	var names: Array[String] = []
	for card: Card in cards:
		if card:
			names.append(card.card_name)
	return names

func parse_player_names(player_names: Dictionary, current_player_names: Dictionary) -> Dictionary:
	var parsed_names: Dictionary = current_player_names.duplicate()
	for player_id in [0, 1]:
		if player_names.has(player_id):
			parsed_names[player_id] = GameConfig.sanitize_player_name(str(player_names[player_id]))
			continue

		var string_key: String = str(player_id)
		if player_names.has(string_key):
			parsed_names[player_id] = GameConfig.sanitize_player_name(str(player_names[string_key]))

	return parsed_names

func parse_player_portraits(player_portraits: Dictionary, current_player_portraits: Dictionary) -> Dictionary:
	var parsed_portraits: Dictionary = current_player_portraits.duplicate()
	if parsed_portraits.is_empty():
		parsed_portraits = {
			0: PortraitLibrary.get_default_portrait_for_player_id(0),
			1: PortraitLibrary.get_default_portrait_for_player_id(1),
		}

	for player_id in [0, 1]:
		if player_portraits.has(player_id):
			parsed_portraits[player_id] = PortraitLibrary.config_from_data_or_default(player_portraits[player_id], player_id)
			continue

		var string_key: String = str(player_id)
		if player_portraits.has(string_key):
			parsed_portraits[player_id] = PortraitLibrary.config_from_data_or_default(player_portraits[string_key], player_id)

	return parsed_portraits

func parse_player_base_fields(player_base_fields: Dictionary) -> Dictionary:
	var parsed_fields: Dictionary = {
		0: white_base_field,
		1: black_base_field,
	}
	if player_base_fields.is_empty():
		return parsed_fields

	for player_id in [0, 1]:
		if player_base_fields.has(player_id):
			parsed_fields[player_id] = value_to_vector2(player_base_fields[player_id], parsed_fields[player_id])
			continue

		var string_key: String = str(player_id)
		if player_base_fields.has(string_key):
			parsed_fields[player_id] = value_to_vector2(player_base_fields[string_key], parsed_fields[player_id])

	return parsed_fields

func parse_board_effects(board_effects: Array) -> Array:
	var parsed_effects: Array = []
	for effect_value in board_effects:
		var effect: Dictionary = effect_value
		var parsed_squares: Array[Vector2] = []
		var square_values: Array = effect.get("squares", [])
		for square_value in square_values:
			var square_pos: Vector2 = value_to_vector2(square_value, invalid_board_pos)
			if is_valid_position(square_pos):
				parsed_squares.append(square_pos)

		parsed_effects.append({
			"effect_type": str(effect.get("effect_type", "")),
			"squares": parsed_squares,
		})

	return parsed_effects

func parse_last_move(last_move: Dictionary) -> Dictionary:
	if last_move.is_empty():
		return {}

	var from_pos: Vector2 = value_to_vector2(last_move.get("from", invalid_board_pos), invalid_board_pos)
	var to_pos: Vector2 = value_to_vector2(last_move.get("to", invalid_board_pos), invalid_board_pos)
	if !is_valid_position(from_pos) or !is_valid_position(to_pos) or from_pos == to_pos:
		return {}

	return {
		"from": from_pos,
		"to": to_pos,
		"player_id": int(last_move.get("player_id", -1)),
		"piece_color": int(last_move.get("piece_color", 0)),
		"visible_to_enemy": bool(last_move.get("visible_to_enemy", true)),
		"show_arrow": bool(last_move.get("show_arrow", true)),
		"captured_piece_color": int(last_move.get("captured_piece_color", 0)),
		"captured_card_name": str(last_move.get("captured_card_name", "")),
	}

func build_piece_state_from_server(pieces_data: Dictionary) -> Dictionary:
	var parsed_board: Array = BoardConfig.create_empty_board()
	var parsed_piece_objects: Dictionary = {}
	for pos in pieces_data:
		var data: Dictionary = pieces_data[pos]
		var piece_color: int = int(data.color)
		var piece_position: Vector2 = value_to_vector2(data.position, invalid_board_pos)
		var piece: Piece = Piece.new(piece_position, piece_color)
		piece.hidden_from_viewer = bool(data.get("hidden_from_viewer", false))
		var card_name: String = str(data.card_name)
		if !card_name.is_empty():
			var card: Card = CardLibrary.duplicate_card(card_name)
			if card:
				piece.attach_card(card)
				piece.turns_remaining = int(data.turns_remaining)
				piece.exhausted_this_turn = bool(data.get("exhausted_this_turn", false))
		piece.respawn_cooldown_turns = int(data.get("respawn_cooldown_turns", 0))

		parsed_piece_objects[piece_position] = piece
		if is_valid_position(piece_position):
			parsed_board[piece_position.x][piece_position.y] = piece_color

	return {
		"board": parsed_board,
		"piece_objects": parsed_piece_objects,
	}

func get_turn_transition_from_server(was_white_turn: bool, current_turn: int, has_received_state: bool) -> Dictionary:
	var is_white_turn: bool = current_turn == 0
	var changed_turn: bool = was_white_turn != is_white_turn
	return {
		"is_white_turn": is_white_turn,
		"changed_turn": changed_turn,
		"should_emit_turn_ended": changed_turn and has_received_state,
		"server_ending_color": 1 if was_white_turn else -1,
	}

func parse_pending_respawn_arrival_animations(recent_pending_respawn_arrivals: Array) -> Array[Dictionary]:
	var animations: Array[Dictionary] = []
	for arrival_value in recent_pending_respawn_arrivals:
		if !(arrival_value is Dictionary):
			continue

		var arrival: Dictionary = arrival_value
		var respawn_pos: Vector2 = value_to_vector2(arrival.get("respawn_pos", invalid_board_pos), invalid_board_pos)
		if !is_valid_position(respawn_pos):
			continue
		var piece_color: int = int(arrival.get("piece_color", 0))
		if piece_color == 0:
			continue

		animations.append({
			"player_id": int(arrival.get("player_id", BoardConfig.get_player_id_for_color(piece_color))),
			"piece_color": piece_color,
			"respawn_pos": respawn_pos,
			"fragment_group": fragment_group_bottom if int(arrival.get("respawn_cooldown_turns", 0)) > 0 else fragment_group_top,
		})
	return animations

func get_state_card_expiration_events(previous_snapshot: Dictionary, recent_card_expirations: Array, piece_objects: Dictionary) -> Array[Dictionary]:
	var expiration_events: Array[Dictionary] = []
	var known_expirations: Dictionary = {}
	for expiration_value in recent_card_expirations:
		if !(expiration_value is Dictionary):
			continue

		var expiration: Dictionary = (expiration_value as Dictionary).duplicate(true)
		var board_pos: Vector2 = value_to_vector2(expiration.get("piece_pos", invalid_board_pos), invalid_board_pos)
		var card_name: String = str(expiration.get("card_name", ""))
		if !is_valid_position(board_pos) or card_name.is_empty():
			continue

		expiration["piece_pos"] = board_pos
		expiration_events.append(expiration)
		known_expirations[get_card_expiration_signature(board_pos, card_name, int(expiration.get("player_id", -1)))] = true

	for position_value in previous_snapshot:
		var board_pos: Vector2 = value_to_vector2(position_value, invalid_board_pos)
		if !is_valid_position(board_pos) or !piece_objects.has(board_pos):
			continue

		var previous_state: Dictionary = previous_snapshot[position_value]
		var expired_card_name: String = str(previous_state.get("card_name", ""))
		if expired_card_name.is_empty():
			continue

		var piece: Piece = piece_objects[board_pos] as Piece
		if piece == null or piece.attached_card != null:
			continue
		if int(previous_state.get("color", 0)) != piece.color:
			continue

		var player_id: int = BoardConfig.get_player_id_for_color(piece.color)
		var signature: String = get_card_expiration_signature(board_pos, expired_card_name, player_id)
		if known_expirations.has(signature):
			continue

		expiration_events.append({
			"player_id": player_id,
			"card_name": expired_card_name,
			"piece_pos": board_pos,
		})
		known_expirations[signature] = true

	return expiration_events

func get_card_expiration_signature(piece_pos: Vector2, card_name: String, player_id: int) -> String:
	return "%d,%d:%d:%s" % [int(piece_pos.x), int(piece_pos.y), player_id, card_name]

func collect_piece_revert_animations(previous_snapshot: Dictionary, card_expiration_events: Array, piece_objects: Dictionary, has_received_state: bool, skip_visual_animations: bool) -> Array[Dictionary]:
	var animations: Array[Dictionary] = []
	if !has_received_state or skip_visual_animations:
		return animations

	var used_previous_positions: Dictionary = {}
	for expiration_value in card_expiration_events:
		if !(expiration_value is Dictionary):
			continue

		var expiration: Dictionary = expiration_value
		var board_pos: Vector2 = value_to_vector2(expiration.get("piece_pos", invalid_board_pos), invalid_board_pos)
		if !is_valid_position(board_pos) or !piece_objects.has(board_pos):
			continue

		var expired_card_name: String = str(expiration.get("card_name", ""))
		if expired_card_name.is_empty():
			continue

		var piece: Piece = piece_objects[board_pos] as Piece
		if piece == null or piece.attached_card != null:
			continue

		var expiration_player_id: int = int(expiration.get("player_id", -1))
		if expiration_player_id >= 0 and BoardConfig.get_player_id_for_color(piece.color) != expiration_player_id:
			continue

		var previous_state: Dictionary = find_previous_expiring_piece_state(
			previous_snapshot,
			used_previous_positions,
			piece.color,
			expired_card_name,
			board_pos
		)
		if previous_state.is_empty():
			continue

		animations.append({
			"position": board_pos,
			"start_texture": get_previous_state_texture(previous_state, piece.color),
		})

	return animations

func find_previous_expiring_piece_state(previous_snapshot: Dictionary, used_previous_positions: Dictionary, piece_color: int, expired_card_name: String, preferred_pos: Vector2) -> Dictionary:
	if previous_snapshot.has(preferred_pos) and !used_previous_positions.has(preferred_pos):
		var preferred_state: Dictionary = previous_snapshot[preferred_pos]
		if int(preferred_state.get("color", 0)) == piece_color and str(preferred_state.get("card_name", "")) == expired_card_name:
			used_previous_positions[preferred_pos] = true
			return preferred_state

	for position_value in previous_snapshot:
		var previous_pos: Vector2 = value_to_vector2(position_value, invalid_board_pos)
		if used_previous_positions.has(previous_pos):
			continue

		var previous_state: Dictionary = previous_snapshot[position_value]
		if int(previous_state.get("color", 0)) != piece_color:
			continue
		if str(previous_state.get("card_name", "")) != expired_card_name:
			continue

		used_previous_positions[previous_pos] = true
		return previous_state

	return {}

func get_previous_state_texture(previous_state: Dictionary, piece_color: int) -> Texture2D:
	var texture_value: Texture2D = previous_state.get("texture", null) as Texture2D
	if texture_value != null:
		return texture_value
	if default_piece_texture_provider.is_valid():
		return default_piece_texture_provider.call(piece_color) as Texture2D
	return null

func collect_state_piece_move_animation(previous_snapshot: Dictionary, piece_objects: Dictionary, current_last_move: Dictionary, has_received_state: bool, skip_visual_animations: bool, can_play_animation: bool) -> Dictionary:
	if !has_received_state or current_last_move.is_empty() or skip_visual_animations or !can_play_animation:
		return {}

	var from_pos: Vector2 = value_to_vector2(current_last_move.get("from", invalid_board_pos), invalid_board_pos)
	var to_pos: Vector2 = value_to_vector2(current_last_move.get("to", invalid_board_pos), invalid_board_pos)
	var visible_to_enemy: bool = bool(current_last_move.get("visible_to_enemy", true))
	if !is_valid_position(from_pos) or !is_valid_position(to_pos) or from_pos == to_pos:
		return {}
	if !previous_snapshot.has(from_pos) or !piece_objects.has(to_pos):
		return {}

	var previous_state: Dictionary = previous_snapshot[from_pos]
	var previous_color: int = int(previous_state.get("color", 0))
	var current_piece: Piece = piece_objects[to_pos] as Piece
	if current_piece == null or previous_color == 0 or current_piece.color != previous_color:
		return {}

	var move_animation := {
		"from": from_pos,
		"to": to_pos,
		"start_texture": get_previous_state_texture(previous_state, current_piece.color),
		"visible_to_enemy": visible_to_enemy,
		"piece_color": current_piece.color,
	}
	if previous_snapshot.has(to_pos):
		var captured_state: Dictionary = previous_snapshot[to_pos]
		var captured_color: int = int(captured_state.get("color", 0))
		if captured_color != 0 and captured_color != previous_color:
			move_animation["captured_texture"] = get_previous_state_texture(captured_state, captured_color)
	else:
		var hidden_captured_texture: Texture2D = get_hidden_captured_piece_texture(current_last_move)
		if hidden_captured_texture != null:
			move_animation["captured_texture"] = hidden_captured_texture
			move_animation["captured_reveal_from_invisibility"] = true
	return move_animation

func get_hidden_captured_piece_texture(current_last_move: Dictionary) -> Texture2D:
	var captured_color: int = int(current_last_move.get("captured_piece_color", 0))
	if captured_color == 0:
		return null

	var captured_card_name: String = str(current_last_move.get("captured_card_name", ""))
	if !captured_card_name.is_empty() and card_piece_texture_provider.is_valid():
		var captured_card: Card = CardLibrary.get_card(captured_card_name)
		if captured_card != null:
			var card_texture: Texture2D = card_piece_texture_provider.call(captured_card, captured_color) as Texture2D
			if card_texture != null:
				return card_texture

	if default_piece_texture_provider.is_valid():
		return default_piece_texture_provider.call(captured_color) as Texture2D
	return null

func get_hidden_card_counts_from_state(hidden_cards: Array) -> Dictionary:
	var counts: Dictionary = {}
	for hidden_card_value in hidden_cards:
		if !(hidden_card_value is Dictionary):
			continue

		var hidden_card_data: Dictionary = hidden_card_value
		var owner_player_id: int = int(hidden_card_data.get("owner_player_id", -1))
		var card_name: String = str(hidden_card_data.get("card_name", ""))
		if owner_player_id < 0 or card_name.is_empty():
			continue

		var signature: String = get_hidden_card_signature(owner_player_id, card_name)
		counts[signature] = int(counts.get(signature, 0)) + 1

	return counts

func get_new_hidden_card_counts(hidden_cards: Array, previous_hidden_card_counts: Dictionary) -> Dictionary:
	var current_counts: Dictionary = get_hidden_card_counts_from_state(hidden_cards)
	var new_counts: Dictionary = {}
	for signature in current_counts:
		var current_count: int = int(current_counts.get(signature, 0))
		var previous_count: int = int(previous_hidden_card_counts.get(signature, 0))
		var added_count: int = current_count - previous_count
		if added_count > 0:
			new_counts[signature] = added_count
	return new_counts

func get_hidden_card_signature(owner_player_id: int, card_name: String) -> String:
	return "%d:%s" % [owner_player_id, card_name]

func collect_state_attach_animations(previous_snapshot: Dictionary, piece_objects: Dictionary, hidden_cards: Array, previous_hidden_card_counts: Dictionary, own_player_id: int, has_received_state: bool, skip_visual_animations: bool) -> Array[Dictionary]:
	var animations: Array[Dictionary] = []
	if !has_received_state or skip_visual_animations:
		return animations

	var animated_positions: Dictionary = {}
	for position_value in piece_objects:
		var board_pos: Vector2 = value_to_vector2(position_value, invalid_board_pos)
		if !previous_snapshot.has(board_pos):
			continue

		var piece: Piece = piece_objects[position_value] as Piece
		if piece == null or piece.attached_card == null:
			continue

		var previous_state: Dictionary = previous_snapshot[board_pos]
		if int(previous_state.get("color", 0)) != piece.color:
			continue
		if str(previous_state.get("card_name", "")) == piece.attached_card.card_name:
			continue

		animations.append({
			"position": board_pos,
			"card": piece.attached_card,
			"start_texture": get_previous_state_texture(previous_state, piece.color),
		})
		animated_positions[board_pos] = true

	append_hidden_invisibility_attach_animations(
		animations,
		animated_positions,
		previous_snapshot,
		piece_objects,
		hidden_cards,
		previous_hidden_card_counts,
		own_player_id
	)

	return animations

func append_hidden_invisibility_attach_animations(animations: Array[Dictionary], animated_positions: Dictionary, previous_snapshot: Dictionary, piece_objects: Dictionary, hidden_cards: Array, previous_hidden_card_counts: Dictionary, own_player_id: int) -> void:
	var used_positions: Dictionary = animated_positions.duplicate()
	var new_hidden_card_counts: Dictionary = get_new_hidden_card_counts(hidden_cards, previous_hidden_card_counts)
	for hidden_card_value in hidden_cards:
		if !(hidden_card_value is Dictionary):
			continue

		var hidden_card_data: Dictionary = hidden_card_value
		var owner_player_id: int = int(hidden_card_data.get("owner_player_id", -1))
		if owner_player_id < 0 or owner_player_id == own_player_id:
			continue

		var card_name: String = str(hidden_card_data.get("card_name", ""))
		var hidden_signature: String = get_hidden_card_signature(owner_player_id, card_name)
		var new_count: int = int(new_hidden_card_counts.get(hidden_signature, 0))
		if new_count <= 0:
			continue

		var card: Card = CardLibrary.duplicate_card(card_name)
		if card == null or card.effect_type != CardEffect.TYPE_INVISIBLE_TO_ENEMY:
			continue

		var piece_color: int = BoardConfig.get_color_for_player_id(owner_player_id)
		var hidden_pos: Vector2 = find_recently_hidden_piece_position(previous_snapshot, piece_objects, used_positions, piece_color)
		if hidden_pos == invalid_board_pos:
			continue

		var previous_state: Dictionary = previous_snapshot[hidden_pos]
		animations.append({
			"position": hidden_pos,
			"card": card,
			"start_texture": get_previous_state_texture(previous_state, piece_color),
			"piece_color": piece_color,
			"hide_after_attach": true,
		})
		used_positions[hidden_pos] = true
		new_hidden_card_counts[hidden_signature] = new_count - 1

func find_recently_hidden_piece_position(previous_snapshot: Dictionary, piece_objects: Dictionary, used_positions: Dictionary, piece_color: int) -> Vector2:
	for position_value in previous_snapshot:
		var board_pos: Vector2 = value_to_vector2(position_value, invalid_board_pos)
		if !is_valid_position(board_pos) or used_positions.has(board_pos):
			continue
		if piece_objects.has(board_pos):
			var current_piece: Piece = piece_objects[board_pos] as Piece
			if current_piece == null or !current_piece.hidden_from_viewer:
				continue
			if current_piece.color != piece_color:
				continue

		var previous_state: Dictionary = previous_snapshot[position_value]
		if int(previous_state.get("color", 0)) != piece_color:
			continue
		var previous_card_name: String = str(previous_state.get("card_name", ""))
		if !previous_card_name.is_empty():
			continue
		return board_pos

	return invalid_board_pos

func collect_bomb_warning_animations(recent_bomb_effects: Array, previous_snapshot: Dictionary, has_received_state: bool, skip_visual_animations: bool) -> Array[Dictionary]:
	var animations: Array[Dictionary] = []
	if !has_received_state or skip_visual_animations:
		return animations

	var used_positions: Dictionary = {}
	for effect_value in recent_bomb_effects:
		if !(effect_value is Dictionary):
			continue

		var effect: Dictionary = effect_value
		var affected_positions: Array = effect.get("affected_positions", [])
		for position_value in affected_positions:
			var target_pos: Vector2 = value_to_vector2(position_value, invalid_board_pos)
			if !is_valid_position(target_pos) or used_positions.has(target_pos):
				continue
			if !previous_snapshot.has(target_pos):
				continue

			used_positions[target_pos] = true
			animations.append({
				"target_pos": target_pos,
			})

	return animations

func collect_piece_shatter_animations(previous_snapshot: Dictionary, piece_objects: Dictionary, recent_bomb_effects: Array, recent_pending_respawn_queues: Array, current_last_move: Dictionary, has_received_state: bool, skip_visual_animations: bool) -> Array[Dictionary]:
	var animations: Array[Dictionary] = []
	if !has_received_state or skip_visual_animations:
		return animations

	var pending_respawn_source_positions: Dictionary = get_pending_respawn_queue_source_positions(recent_pending_respawn_queues)
	var forced_capture_positions: Dictionary = get_recent_effect_capture_positions(recent_bomb_effects)
	var respawn_targets_by_color: Dictionary = collect_new_respawn_targets_by_color(previous_snapshot, piece_objects)
	var release_targets_by_color: Dictionary = collect_released_respawn_targets_by_color(previous_snapshot, piece_objects)
	var used_respawn_targets: Dictionary = {}
	var used_release_targets: Dictionary = {}
	for position_value in previous_snapshot:
		var board_pos: Vector2 = value_to_vector2(position_value, invalid_board_pos)
		if !is_valid_position(board_pos):
			continue

		var previous_state: Dictionary = previous_snapshot[position_value]
		var previous_color: int = int(previous_state.get("color", 0))
		if previous_color == 0:
			continue

		var current_piece: Piece = piece_objects.get(board_pos, null) as Piece
		if current_piece != null and current_piece.color == previous_color:
			continue

		var respawn_pos: Vector2 = get_unused_respawn_target_for_color(respawn_targets_by_color, used_respawn_targets, previous_color)
		var fragment_group: String = fragment_group_bottom
		if respawn_pos == invalid_board_pos:
			respawn_pos = get_unused_respawn_target_for_color(release_targets_by_color, used_release_targets, previous_color)
			fragment_group = fragment_group_top

		var was_replaced_by_enemy: bool = current_piece != null and current_piece.color != previous_color
		var was_forced_capture: bool = forced_capture_positions.has(board_pos)
		var was_queued_pending_respawn: bool = pending_respawn_source_positions.has(board_pos)
		if respawn_pos == invalid_board_pos and !was_replaced_by_enemy and !was_forced_capture and !was_queued_pending_respawn:
			continue
		if respawn_pos == invalid_board_pos:
			fragment_group = fragment_group_pending if was_queued_pending_respawn else fragment_group_none

		animations.append({
			"source_pos": board_pos,
			"respawn_pos": respawn_pos,
			"piece_color": previous_color,
			"fragment_group": fragment_group,
		})

	append_hidden_capture_shatter_animation(
		animations,
		current_last_move,
		previous_snapshot,
		piece_objects,
		respawn_targets_by_color,
		release_targets_by_color,
		used_respawn_targets,
		used_release_targets,
		pending_respawn_source_positions
	)
	return animations

func append_hidden_capture_shatter_animation(
	animations: Array[Dictionary],
	current_last_move: Dictionary,
	previous_snapshot: Dictionary,
	piece_objects: Dictionary,
	respawn_targets_by_color: Dictionary,
	release_targets_by_color: Dictionary,
	used_respawn_targets: Dictionary,
	used_release_targets: Dictionary,
	pending_respawn_source_positions: Dictionary
) -> void:
	if current_last_move.is_empty():
		return
	var source_pos: Vector2 = value_to_vector2(current_last_move.get("to", invalid_board_pos), invalid_board_pos)
	if !is_valid_position(source_pos) or previous_snapshot.has(source_pos):
		return

	var captured_color: int = int(current_last_move.get("captured_piece_color", 0))
	if captured_color == 0:
		return
	var current_piece: Piece = piece_objects.get(source_pos, null) as Piece
	if current_piece == null or current_piece.color == captured_color:
		return

	var respawn_pos: Vector2 = get_unused_respawn_target_for_color(respawn_targets_by_color, used_respawn_targets, captured_color)
	var fragment_group: String = fragment_group_bottom
	if respawn_pos == invalid_board_pos:
		respawn_pos = get_unused_respawn_target_for_color(release_targets_by_color, used_release_targets, captured_color)
		fragment_group = fragment_group_top
	if respawn_pos == invalid_board_pos:
		fragment_group = fragment_group_pending if pending_respawn_source_positions.has(source_pos) else fragment_group_none

	animations.append({
		"source_pos": source_pos,
		"respawn_pos": respawn_pos,
		"piece_color": captured_color,
		"fragment_group": fragment_group,
	})

func collect_new_respawn_targets_by_color(previous_snapshot: Dictionary, piece_objects: Dictionary) -> Dictionary:
	var targets_by_color: Dictionary = {}
	for position_value in piece_objects:
		var board_pos: Vector2 = value_to_vector2(position_value, invalid_board_pos)
		if !is_valid_position(board_pos):
			continue

		var piece: Piece = piece_objects[position_value] as Piece
		if piece == null or !piece.is_respawn_locked():
			continue

		var previous_state: Dictionary = previous_snapshot.get(board_pos, {})
		var previous_color: int = int(previous_state.get("color", 0))
		var previous_cooldown: int = int(previous_state.get("respawn_cooldown_turns", 0))
		if previous_color == piece.color and previous_cooldown > 0:
			continue

		var targets: Array = targets_by_color.get(piece.color, [])
		targets.append(board_pos)
		targets_by_color[piece.color] = targets

	return targets_by_color

func collect_released_respawn_targets_by_color(previous_snapshot: Dictionary, piece_objects: Dictionary) -> Dictionary:
	var targets_by_color: Dictionary = {}
	for position_value in previous_snapshot:
		var board_pos: Vector2 = value_to_vector2(position_value, invalid_board_pos)
		if !is_valid_position(board_pos):
			continue

		var previous_state: Dictionary = previous_snapshot[position_value]
		var previous_color: int = int(previous_state.get("color", 0))
		var previous_cooldown: int = int(previous_state.get("respawn_cooldown_turns", 0))
		if previous_color == 0 or previous_cooldown <= 0:
			continue

		var current_piece: Piece = piece_objects.get(board_pos, null) as Piece
		if current_piece == null or current_piece.color != previous_color or current_piece.is_respawn_locked():
			continue

		var targets: Array = targets_by_color.get(previous_color, [])
		targets.append(board_pos)
		targets_by_color[previous_color] = targets

	return targets_by_color

func get_pending_respawn_queue_source_positions(recent_pending_respawn_queues: Array) -> Dictionary:
	var positions: Dictionary = {}
	for queue_value in recent_pending_respawn_queues:
		if !(queue_value is Dictionary):
			continue

		var queue_event: Dictionary = queue_value
		var source_pos: Vector2 = value_to_vector2(queue_event.get("source_pos", invalid_board_pos), invalid_board_pos)
		if is_valid_position(source_pos):
			positions[source_pos] = true
	return positions

func get_recent_effect_capture_positions(recent_bomb_effects: Array) -> Dictionary:
	var positions: Dictionary = {}
	for effect_value in recent_bomb_effects:
		if !(effect_value is Dictionary):
			continue

		var effect: Dictionary = effect_value
		var affected_positions: Array = effect.get("affected_positions", [])
		for position_value in affected_positions:
			var board_pos: Vector2 = value_to_vector2(position_value, invalid_board_pos)
			if is_valid_position(board_pos):
				positions[board_pos] = true
	return positions

func get_unused_respawn_target_for_color(targets_by_color: Dictionary, used_targets: Dictionary, piece_color: int) -> Vector2:
	var targets: Array = targets_by_color.get(piece_color, [])
	for target_value in targets:
		var target_pos: Vector2 = value_to_vector2(target_value, invalid_board_pos)
		if !is_valid_position(target_pos) or used_targets.has(target_pos):
			continue
		used_targets[target_pos] = true
		return target_pos
	return invalid_board_pos

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

func is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < board_size and pos.y >= 0 and pos.y < board_size
