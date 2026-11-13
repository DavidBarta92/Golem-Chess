class_name GameStateSerializer

## The match as it goes over the wire: what the host sends every board after
## every action (NetworkGameHost.broadcast_full_state), cut to what that
## board's player may know - a golem hidden from the viewer goes without its
## stamp, a move it made without its arrow. ServerStateUpdateController is the
## other end: a field added here needs reading there too.
##
## Only what changes during a match belongs here. What a player brings to it -
## name, portrait, and later the prints and drawings - travels once, as their
## PlayerProfile (NetworkGameHost.broadcast_player_profiles).
##
## Both players' hands and codex pages go to both boards. A board shows only
## its own player's, but a modified client could read the other's.

static func serialize_for_player(game_state: GameStateData, viewer_player_id: int) -> Dictionary:
	var data = {
		"viewer_player_id": viewer_player_id,
		"pieces": [],
		"hidden_stamps": [],
		"player_hands": game_state.player_hands,
		"player_decks_size": {
			0: game_state.get_remaining_codex_stamp_count(0),
			1: game_state.get_remaining_codex_stamp_count(1)
		},
		"player_codex_state": serialize_player_codex_state(game_state),
		"current_turn": game_state.current_turn_player,
		"game_over": game_state.game_over,
		"winner_player": game_state.winner_player,
		"player_base_fields": serialize_player_base_fields(game_state),
		"board_effects": serialize_board_effects(game_state),
		"recent_stamp_transfers": serialize_recent_stamp_transfers(game_state, viewer_player_id),
		"recent_stamp_expirations": serialize_recent_stamp_expirations(game_state),
		"recent_bomb_effects": serialize_recent_bomb_effects(game_state),
		"recent_effect_activations": serialize_recent_effect_activations(game_state),
		"recent_pending_respawn_queues": serialize_recent_pending_respawn_queues(game_state),
		"recent_pending_respawn_arrivals": serialize_recent_pending_respawn_arrivals(game_state),
		"last_move": serialize_last_move_for_player(game_state, viewer_player_id),
		"turn_action_state": serialize_turn_action_state(game_state),
		"player_clock_seconds": game_state.player_clock_seconds.duplicate(),
		# Both players' points are open information; where a crown is, is not
		# when its golem is hidden from the viewer (has_crown below).
		"crown_points": game_state.crown_points.duplicate(),
		"crown_points_required": game_state.crown_points_required,
	}

	for pos in game_state.pieces:
		var piece: Piece = game_state.pieces[pos]
		var hidden_from_viewer: bool = viewer_player_id != -1 && !StampEffectResolver.is_piece_visible_to_player(piece, viewer_player_id)
		if hidden_from_viewer:
			append_hidden_stamp_data(data["hidden_stamps"], piece)
		data.pieces.append({
			"position": [pos.x, pos.y],
			"color": piece.color,
			"stamp_name": "" if hidden_from_viewer else (piece.affixed_stamp.stamp_name if piece.affixed_stamp else ""),
			"turns_remaining": 0 if hidden_from_viewer else piece.turns_remaining,
			"exhausted_this_turn": true if hidden_from_viewer else piece.exhausted_this_turn,
			"respawn_cooldown_turns": piece.respawn_cooldown_turns,
			"hidden_from_viewer": hidden_from_viewer,
			"protection_turns_remaining": -1 if hidden_from_viewer else piece.protection_turns_remaining,
			"has_crown": false if hidden_from_viewer else piece.has_crown,
		})

	return data

static func serialize_turn_action_state(game_state: GameStateData) -> Dictionary:
	return {
		"affixed_stamp_this_turn": duplicate_bool_dictionary(game_state.affixed_stamp_this_turn),
		"moved_piece_this_turn": duplicate_bool_dictionary(game_state.moved_piece_this_turn),
		"exchanged_stamp_this_turn": duplicate_bool_dictionary(game_state.exchanged_stamp_this_turn),
		"has_turned_page_this_turn": duplicate_bool_dictionary(game_state.has_turned_page_this_turn),
		"affixed_stamp_count_this_turn": game_state.affixed_stamp_count_this_turn.duplicate(),
		"completed_turn_counts": game_state.completed_turn_counts.duplicate(),
		"crowned_this_turn": duplicate_bool_dictionary(game_state.crowned_this_turn),
	}

static func serialize_player_codex_state(game_state: GameStateData) -> Dictionary:
	return {
		0: {
			"current_page_index": game_state.get_current_page_index(0),
			"page_counts": game_state.get_page_stamp_counts(0),
			"pages": serialize_codex_pages_for_player(game_state, 0),
			"has_turned_page_this_turn": bool(game_state.has_turned_page_this_turn.get(0, false)),
		},
		1: {
			"current_page_index": game_state.get_current_page_index(1),
			"page_counts": game_state.get_page_stamp_counts(1),
			"pages": serialize_codex_pages_for_player(game_state, 1),
			"has_turned_page_this_turn": bool(game_state.has_turned_page_this_turn.get(1, false)),
		},
	}

static func serialize_codex_pages_for_player(game_state: GameStateData, player_id: int) -> Array:
	var serialized_pages: Array = []
	var pages: Array = game_state.get_codex_pages(player_id)
	for page_index in range(DeckManager.CODEX_PAGE_COUNT):
		var serialized_page: Array[String] = []
		if page_index < pages.size() and pages[page_index] is Array:
			for stamp_name_value in pages[page_index]:
				serialized_page.append(str(stamp_name_value))
		serialized_pages.append(serialized_page)
	return serialized_pages

static func duplicate_bool_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		output[key] = bool(source[key])
	return output

static func serialize_recent_stamp_transfers(game_state: GameStateData, _viewer_player_id: int) -> Array:
	var serialized_transfers: Array = []
	for transfer_value in game_state.recent_stamp_transfers:
		var transfer: Dictionary = transfer_value
		var source_pos: Vector2 = StampEffectResolver.as_vector2(transfer.get("source_pos", [-1, -1]), Vector2(-1, -1))
		serialized_transfers.append({
			"source_player_id": int(transfer.get("source_player_id", -1)),
			"target_player_id": int(transfer.get("target_player_id", -1)),
			"stamp_name": str(transfer.get("stamp_name", "")),
			"source_zone": str(transfer.get("source_zone", "")),
			"target_zone": str(transfer.get("target_zone", "")),
			"source_pos": vector2_to_array(source_pos),
		})

	return serialized_transfers

static func serialize_recent_stamp_expirations(game_state: GameStateData) -> Array:
	var serialized_expirations: Array = []
	for expiration_value in game_state.recent_stamp_expirations:
		var expiration: Dictionary = expiration_value
		var piece_pos: Vector2 = StampEffectResolver.as_vector2(expiration.get("piece_pos", [-1, -1]), Vector2(-1, -1))
		serialized_expirations.append({
			"player_id": int(expiration.get("player_id", -1)),
			"stamp_name": str(expiration.get("stamp_name", "")),
			"piece_pos": vector2_to_array(piece_pos),
		})

	return serialized_expirations

static func serialize_recent_bomb_effects(game_state: GameStateData) -> Array:
	var serialized_effects: Array = []
	for effect_value in game_state.recent_bomb_effects:
		var effect: Dictionary = effect_value
		var serialized_squares: Array = []
		var squares: Array = effect.get("squares", [])
		for square_value in squares:
			serialized_squares.append(vector2_to_array(StampEffectResolver.as_vector2(square_value, Vector2(-1, -1))))

		var serialized_affected_positions: Array = []
		var affected_positions: Array = effect.get("affected_positions", [])
		for position_value in affected_positions:
			serialized_affected_positions.append(vector2_to_array(StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))))

		serialized_effects.append({
			"player_id": int(effect.get("player_id", -1)),
			"stamp_name": str(effect.get("stamp_name", "")),
			"source_pos": vector2_to_array(StampEffectResolver.as_vector2(effect.get("source_pos", Vector2(-1, -1)), Vector2(-1, -1))),
			"squares": serialized_squares,
			"affected_positions": serialized_affected_positions,
		})

	return serialized_effects

static func serialize_recent_effect_activations(game_state: GameStateData) -> Array:
	var serialized_activations: Array = []
	for activation_value in game_state.recent_effect_activations:
		var activation: Dictionary = activation_value
		serialized_activations.append({
			"player_id": int(activation.get("player_id", -1)),
			"stamp_name": str(activation.get("stamp_name", "")),
			"source_pos": vector2_to_array(StampEffectResolver.as_vector2(activation.get("source_pos", Vector2(-1, -1)), Vector2(-1, -1))),
		})

	return serialized_activations

static func serialize_recent_pending_respawn_queues(game_state: GameStateData) -> Array:
	var serialized_queues: Array = []
	for queue_value in game_state.recent_pending_respawn_queues:
		var queue_event: Dictionary = queue_value
		serialized_queues.append({
			"player_id": int(queue_event.get("player_id", -1)),
			"piece_color": int(queue_event.get("piece_color", 0)),
			"source_pos": vector2_to_array(StampEffectResolver.as_vector2(queue_event.get("source_pos", Vector2(-1, -1)), Vector2(-1, -1))),
		})

	return serialized_queues

static func serialize_recent_pending_respawn_arrivals(game_state: GameStateData) -> Array:
	var serialized_arrivals: Array = []
	for arrival_value in game_state.recent_pending_respawn_arrivals:
		var arrival: Dictionary = arrival_value
		serialized_arrivals.append({
			"player_id": int(arrival.get("player_id", -1)),
			"piece_color": int(arrival.get("piece_color", 0)),
			"respawn_pos": vector2_to_array(StampEffectResolver.as_vector2(arrival.get("respawn_pos", Vector2(-1, -1)), Vector2(-1, -1))),
			"respawn_cooldown_turns": int(arrival.get("respawn_cooldown_turns", 0)),
		})

	return serialized_arrivals

static func serialize_last_move_for_player(game_state: GameStateData, viewer_player_id: int) -> Dictionary:
	if game_state.last_move.is_empty():
		return {}

	var mover_player_id: int = int(game_state.last_move.get("player_id", -1))
	var is_mover_viewer: bool = viewer_player_id != -1 && mover_player_id == viewer_player_id
	var from_pos: Vector2 = StampEffectResolver.as_vector2(game_state.last_move.get("from", Vector2(-1, -1)), Vector2(-1, -1))
	var to_pos: Vector2 = StampEffectResolver.as_vector2(game_state.last_move.get("to", Vector2(-1, -1)), Vector2(-1, -1))
	if from_pos == Vector2(-1, -1) or to_pos == Vector2(-1, -1) or from_pos == to_pos:
		return {}

	var moving_piece: Piece = game_state.get_piece(to_pos)
	if moving_piece == null:
		return {}

	# A piece the viewer cannot see keeps its moves to itself - except the one
	# that takes a piece of theirs. That capture happens in plain view, so the
	# viewer is shown it: the attacker coming in and striking, then going out
	# of sight again where it stands. Never with an arrow, which would go on
	# pointing at it long after it had vanished.
	var hidden_after_capture: bool = false
	if viewer_player_id != -1 && !is_mover_viewer:
		var visible_now: bool = StampEffectResolver.is_piece_visible_to_player(moving_piece, viewer_player_id)
		if !visible_now or !bool(game_state.last_move.get("visible_to_enemy", true)):
			if visible_now or int(game_state.last_move.get("captured_piece_color", 0)) == 0:
				return {}
			hidden_after_capture = true

	var serialized_last_move := {
		"from": vector2_to_array(from_pos),
		"to": vector2_to_array(to_pos),
		"player_id": mover_player_id,
		"piece_color": int(game_state.last_move.get("piece_color", StampEffectResolver.get_color_for_player_id(mover_player_id))),
		"visible_to_enemy": bool(game_state.last_move.get("visible_to_enemy", true)),
		"show_arrow": !is_mover_viewer and !hidden_after_capture,
	}
	if hidden_after_capture:
		serialized_last_move["hidden_after_capture"] = true
		serialized_last_move["piece_stamp_name"] = moving_piece.affixed_stamp.stamp_name if moving_piece.affixed_stamp != null else ""
	if int(game_state.last_move.get("captured_piece_color", 0)) != 0:
		serialized_last_move["captured_piece_color"] = int(game_state.last_move.get("captured_piece_color", 0))
		serialized_last_move["captured_stamp_name"] = str(game_state.last_move.get("captured_stamp_name", ""))
	return serialized_last_move

static func append_hidden_stamp_data(hidden_stamps: Array, piece: Piece) -> void:
	if piece == null or piece.affixed_stamp == null:
		return

	hidden_stamps.append({
		"stamp_name": piece.affixed_stamp.stamp_name,
		"turns_remaining": piece.turns_remaining,
		"owner_player_id": BoardConfig.get_player_id_for_color(piece.color),
	})

static func serialize_player_base_fields(game_state: GameStateData) -> Dictionary:
	return {
		0: vector2_to_array(StampEffectResolver.get_base_field_for_player(game_state, 0)),
		1: vector2_to_array(StampEffectResolver.get_base_field_for_player(game_state, 1)),
	}

static func serialize_board_effects(game_state: GameStateData) -> Array:
	var serialized_effects: Array = []
	for effect_value in game_state.board_effects:
		var effect: Dictionary = effect_value
		var serialized_squares: Array = []
		var squares: Array = effect.get("squares", [])
		for square_value in squares:
			serialized_squares.append(vector2_to_array(StampEffectResolver.as_vector2(square_value, Vector2(-1, -1))))

		serialized_effects.append({
			"effect_type": str(effect.get("effect_type", "")),
			"owner_player_id": int(effect.get("owner_player_id", -1)),
			"target_player_id": int(effect.get("target_player_id", -1)),
			"squares": serialized_squares,
			"turns_remaining": int(effect.get("turns_remaining", -1)),
			"source_pos": vector2_to_array(StampEffectResolver.as_vector2(effect.get("source_pos", Vector2(-1, -1)), Vector2(-1, -1))),
		})

	return serialized_effects

static func vector2_to_array(value: Vector2) -> Array:
	return [value.x, value.y]
