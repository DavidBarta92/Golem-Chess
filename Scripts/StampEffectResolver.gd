extends RefCounted
class_name StampEffectResolver

const DEFAULT_BOARD_SIZE: int = BoardConfig.BOARD_SIZE
const DEFAULT_MAX_HAND_SIZE: int = DeckManager.HAND_SIZE
const DEFAULT_WHITE_BASE_FIELD: Vector2 = BoardConfig.WHITE_BASE_FIELD
const DEFAULT_BLACK_BASE_FIELD: Vector2 = BoardConfig.BLACK_BASE_FIELD

static func resolve_trigger(trigger: String, game_state: GameStateData, context: Dictionary, board_size: int = DEFAULT_BOARD_SIZE) -> bool:
	if game_state == null or game_state.game_over:
		return false

	var stamp: Stamp = get_context_stamp(context)
	if stamp == null or !stamp.has_effect() or stamp.effect_trigger != trigger:
		return false

	var player_id: int = get_context_player_id(context)
	var source_pos: Vector2 = get_context_piece_position(context)
	var source_piece: Piece = get_context_piece(context)
	var effect_color: int = get_context_effect_color(context, player_id)
	var effect_log_context: Dictionary = {}
	if game_state.match_logger != null:
		effect_log_context = game_state.match_logger.create_effect_context(game_state, trigger, player_id, stamp, source_pos, context)

	var result: Dictionary = {}
	match stamp.effect_type:
		StampEffect.TYPE_STEAL_STAMP:
			result = resolve_steal_stamp(game_state, player_id, stamp)
		StampEffect.TYPE_GRANT_STAMP:
			result = resolve_grant_stamp(game_state, player_id, stamp, source_pos)
		StampEffect.TYPE_GIVE_STAMP:
			result = resolve_give_stamp(game_state, player_id, stamp, source_pos)
		StampEffect.TYPE_MOVE_BASE:
			result = resolve_move_base(game_state, player_id, stamp, source_pos, board_size, effect_color)
		StampEffect.TYPE_INVALID_SQUARES:
			result = resolve_board_zone_effect(game_state, player_id, stamp, source_pos, board_size, effect_color)
		StampEffect.TYPE_FROZEN_SQUARES:
			result = resolve_board_zone_effect(game_state, player_id, stamp, source_pos, board_size, effect_color)
		StampEffect.TYPE_BOMB:
			result = resolve_bomb(game_state, player_id, stamp, source_pos, board_size, effect_color)
		StampEffect.TYPE_INCREASE_OWN_DURATIONS:
			result = resolve_duration_adjustment(game_state, player_id, stamp, source_piece, source_pos, board_size, player_id, 1)
		StampEffect.TYPE_INCREASE_ENEMY_DURATIONS:
			result = resolve_duration_adjustment(game_state, player_id, stamp, source_piece, source_pos, board_size, 1 - player_id, 1)
		StampEffect.TYPE_DECREASE_OWN_DURATIONS:
			result = resolve_duration_adjustment(game_state, player_id, stamp, source_piece, source_pos, board_size, player_id, -1)
		StampEffect.TYPE_DECREASE_ENEMY_DURATIONS:
			result = resolve_duration_adjustment(game_state, player_id, stamp, source_piece, source_pos, board_size, 1 - player_id, -1)
		StampEffect.TYPE_INCREASE_SELF_DURATION:
			result = resolve_self_duration_adjustment(game_state, player_id, source_piece, source_pos, board_size, 1)
		_:
			pass

	if game_state.match_logger != null:
		game_state.match_logger.log_effect_event(game_state, effect_log_context, result)

	return true

static func resolve_symbol_count_trigger(game_state: GameStateData, player_id: int, piece: Piece, piece_pos: Vector2, stamp: Stamp, board_size: int = DEFAULT_BOARD_SIZE) -> bool:
	if game_state == null or game_state.game_over:
		return false
	if stamp == null or !stamp.has_effect() or stamp.effect_trigger != StampEffect.TRIGGER_ON_SYMBOL_COUNT:
		return false

	var symbol: String = stamp.symbol.strip_edges()
	if symbol.is_empty():
		return false

	var required_count: int = max(1, int(stamp.effect_settings.get("symbol_count", 3)))
	if count_symbol_pieces_for_player(game_state, player_id, symbol) < required_count:
		return false

	return resolve_trigger(StampEffect.TRIGGER_ON_SYMBOL_COUNT, game_state, {
		"player_id": player_id,
		"piece": piece,
		"piece_pos": piece_pos,
		"stamp": stamp,
		"symbol": symbol,
		"symbol_count": required_count,
	}, board_size)

static func get_context_stamp(context: Dictionary) -> Stamp:
	var stamp: Stamp = context.get("stamp", null) as Stamp
	if stamp != null:
		return stamp

	var piece: Piece = context.get("piece", null) as Piece
	if piece != null:
		return piece.attached_stamp

	return null

static func get_context_piece(context: Dictionary) -> Piece:
	return context.get("piece", null) as Piece

static func get_context_player_id(context: Dictionary) -> int:
	if context.has("player_id"):
		return int(context.player_id)

	var piece: Piece = get_context_piece(context)
	if piece != null:
		return get_player_id_for_color(piece.color)

	return 0

static func get_context_effect_color(context: Dictionary, fallback_player_id: int) -> int:
	var piece: Piece = get_context_piece(context)
	if piece != null:
		return piece.color
	return get_color_for_player_id(fallback_player_id)

static func get_context_piece_position(context: Dictionary) -> Vector2:
	if context.has("piece_pos"):
		return as_vector2(context.piece_pos, Vector2(-1, -1))

	var piece: Piece = get_context_piece(context)
	if piece != null:
		return piece.position

	return Vector2(-1, -1)

static func resolve_steal_stamp(game_state: GameStateData, player_id: int, stamp: Stamp) -> Dictionary:
	var params: Dictionary = stamp.effect_settings
	var source_player_id: int = int(params.get("source_player_id", 1 - player_id))
	var amount: int = max(1, int(params.get("amount", 1)))
	var source: String = str(params.get("source", "enemy_hand"))
	var max_hand_size: int = max(1, int(params.get("max_hand_size", DEFAULT_MAX_HAND_SIZE)))
	var stolen_stamps: Array = []

	for steal_index in range(amount):
		var stolen_stamp_name: String = take_stamp_from_player_zone(game_state, source_player_id, source)
		if stolen_stamp_name.is_empty():
			return build_stamp_transfer_result(source_player_id, player_id, source, "hand_or_deleted", stolen_stamps)

		var target_zone: String = give_stamp_to_player(game_state, player_id, stolen_stamp_name, max_hand_size)
		register_stamp_transfer(game_state, source_player_id, player_id, stolen_stamp_name, source, target_zone)
		stolen_stamps.append(stolen_stamp_name)
		if game_state.match_logger != null:
			game_state.match_logger.log_stamp_event(game_state, "steal_stamp", {
				"player_id": player_id,
				"stamp_name": stolen_stamp_name,
				"source_player_id": source_player_id,
				"target_player_id": player_id,
				"source_zone": source,
				"target_zone": target_zone,
				"reason": stamp.stamp_name,
			})
		DebugLog.info("Stamp stolen: player=%d stole %s from player=%d" % [player_id, stolen_stamp_name, source_player_id])
	return build_stamp_transfer_result(source_player_id, player_id, source, "hand_or_deleted", stolen_stamps)

static func resolve_grant_stamp(game_state: GameStateData, player_id: int, stamp: Stamp, source_pos: Vector2 = Vector2(-1, -1)) -> Dictionary:
	var params: Dictionary = stamp.effect_settings
	var granted_stamp_name: String = str(params.get("stamp_name", stamp.stamp_name))
	if granted_stamp_name.is_empty():
		return {}

	var target_player_id: int = int(params.get("target_player_id", player_id))
	var amount: int = max(1, int(params.get("amount", 1)))
	var max_hand_size: int = max(1, int(params.get("max_hand_size", DEFAULT_MAX_HAND_SIZE)))
	var granted_stamps: Array = []
	for grant_index in range(amount):
		if !take_named_stamp_from_player_deck(game_state, target_player_id, granted_stamp_name):
			DebugLog.info("Stamp grant ignored: %s is not in player=%d deck" % [granted_stamp_name, target_player_id])
			return build_stamp_transfer_result(target_player_id, target_player_id, "deck", "hand_or_deleted", granted_stamps)

		var target_zone: String = give_stamp_to_player(game_state, target_player_id, granted_stamp_name, max_hand_size)
		register_stamp_transfer(game_state, target_player_id, target_player_id, granted_stamp_name, "deck", target_zone, source_pos)
		granted_stamps.append(granted_stamp_name)
		if game_state.match_logger != null:
			game_state.match_logger.log_stamp_event(game_state, "grant_stamp", {
				"player_id": target_player_id,
				"stamp_name": granted_stamp_name,
				"source_player_id": target_player_id,
				"target_player_id": target_player_id,
				"source_zone": "deck",
				"target_zone": target_zone,
				"reason": stamp.stamp_name,
			})

	DebugLog.info("Stamp granted: %s x%d to player=%d" % [granted_stamp_name, amount, target_player_id])
	return build_stamp_transfer_result(target_player_id, target_player_id, "deck", "hand_or_deleted", granted_stamps)

static func resolve_give_stamp(game_state: GameStateData, player_id: int, stamp: Stamp, source_pos: Vector2 = Vector2(-1, -1)) -> Dictionary:
	var params: Dictionary = stamp.effect_settings
	var target_player_id: int = int(params.get("target_player_id", 1 - player_id))
	var amount: int = max(1, int(params.get("amount", 1)))
	var max_hand_size: int = max(1, int(params.get("max_hand_size", DEFAULT_MAX_HAND_SIZE)))
	var given_stamps: Array = []

	for give_index in range(amount):
		var given_stamp_name: String = take_stamp_from_player_zone(game_state, player_id, "hand")
		if given_stamp_name.is_empty():
			return build_stamp_transfer_result(player_id, target_player_id, "hand", "hand_or_deleted", given_stamps)

		var target_zone: String = give_stamp_to_player(game_state, target_player_id, given_stamp_name, max_hand_size)
		var animation_source_zone: String = "piece" if source_pos != Vector2(-1, -1) else "hand"
		register_stamp_transfer(game_state, player_id, target_player_id, given_stamp_name, animation_source_zone, target_zone, source_pos)
		given_stamps.append(given_stamp_name)
		if game_state.match_logger != null:
			game_state.match_logger.log_stamp_event(game_state, "give_stamp", {
				"player_id": player_id,
				"stamp_name": given_stamp_name,
				"source_player_id": player_id,
				"target_player_id": target_player_id,
				"source_zone": "hand",
				"target_zone": target_zone,
				"reason": stamp.stamp_name,
			})
		DebugLog.info("Stamp given: player=%d gave %s to player=%d" % [player_id, given_stamp_name, target_player_id])

	return build_stamp_transfer_result(player_id, target_player_id, "hand", "hand_or_deleted", given_stamps)

static func build_stamp_transfer_result(source_player_id: int, target_player_id: int, source_zone: String, target_zone: String, stamp_names: Array) -> Dictionary:
	return {
		"source_player_id": source_player_id,
		"target_player_id": target_player_id,
		"source_zone": source_zone,
		"target_zone": target_zone,
		"stamps_moved": stamp_names.size(),
		"stamp_names": stamp_names,
	}

static func take_stamp_from_player_zone(game_state: GameStateData, source_player_id: int, source: String) -> String:
	if game_state != null and game_state.has_codex_for_player(source_player_id):
		var from_deck_zone: bool = source == "enemy_deck" or source == "deck"
		if from_deck_zone:
			return game_state.remove_stamp_from_codex_zone(source_player_id, "", false)
		return game_state.remove_stamp_from_current_page(source_player_id)

	var source_stamps: Array = []
	if source == "enemy_deck" or source == "deck":
		source_stamps = game_state.player_decks.get(source_player_id, [])
	else:
		source_stamps = game_state.player_hands.get(source_player_id, [])

	if source_stamps.is_empty():
		return ""

	var stolen_index: int = randi() % source_stamps.size()
	var stolen_stamp_name: String = str(source_stamps[stolen_index])
	source_stamps.remove_at(stolen_index)

	if source == "enemy_deck" or source == "deck":
		game_state.player_decks[source_player_id] = source_stamps
	else:
		game_state.player_hands[source_player_id] = source_stamps

	return stolen_stamp_name

static func take_named_stamp_from_player_deck(game_state: GameStateData, player_id: int, stamp_name: String) -> bool:
	if game_state != null and game_state.has_codex_for_player(player_id):
		return !game_state.remove_stamp_from_codex_zone(player_id, stamp_name, false).is_empty()

	if !game_state.player_decks.has(player_id):
		return false

	var deck: Array = game_state.player_decks[player_id]
	var stamp_index: int = deck.find(stamp_name)
	if stamp_index == -1:
		return false

	deck.remove_at(stamp_index)
	game_state.player_decks[player_id] = deck
	return true

static func give_stamp_to_player(game_state: GameStateData, player_id: int, stamp_name: String, max_hand_size: int) -> String:
	if game_state != null and game_state.has_codex_for_player(player_id):
		if game_state.add_stamp_to_current_page(player_id, stamp_name, max_hand_size):
			return "hand"
		return "deleted"

	var hand: Array = game_state.player_hands.get(player_id, [])
	if hand.size() < max_hand_size:
		hand.append(stamp_name)
		game_state.player_hands[player_id] = hand
		return "hand"

	return "deleted"

static func register_stamp_transfer(game_state: GameStateData, source_player_id: int, target_player_id: int, stamp_name: String, source_zone: String, target_zone: String, source_pos: Vector2 = Vector2(-1, -1)) -> void:
	if game_state == null:
		return

	game_state.recent_stamp_transfers.append({
		"source_player_id": source_player_id,
		"target_player_id": target_player_id,
		"stamp_name": stamp_name,
		"source_zone": source_zone,
		"target_zone": target_zone,
		"source_pos": [source_pos.x, source_pos.y],
	})

static func resolve_move_base(game_state: GameStateData, player_id: int, stamp: Stamp, source_pos: Vector2, board_size: int, effect_color: int) -> Dictionary:
	var raw_target_squares: Array[Vector2] = get_effect_squares_unfiltered(stamp, source_pos, effect_color)
	if raw_target_squares.is_empty():
		return {}

	var target_pos: Vector2 = raw_target_squares[0]
	if !MoveRules.is_valid_position(target_pos, board_size):
		DebugLog.info("Move base ignored: target outside board: %s" % target_pos)
		return {
			"squares": [],
			"base_player_id": player_id,
			"base_before": get_base_field_for_player(game_state, player_id),
			"base_after": get_base_field_for_player(game_state, player_id),
		}
	if is_base_field_for_other_player(game_state, target_pos, player_id):
		DebugLog.info("Move base ignored: target already contains another base: %s" % target_pos)
		return {
			"squares": [],
			"base_player_id": player_id,
			"base_before": get_base_field_for_player(game_state, player_id),
			"base_after": get_base_field_for_player(game_state, player_id),
		}

	var target_squares: Array[Vector2] = []
	target_squares.append(target_pos)
	if target_squares.is_empty():
		return {}

	var base_before: Vector2 = get_base_field_for_player(game_state, player_id)
	game_state.player_base_fields[player_id] = target_pos
	resolve_pending_respawns_for_all_players(game_state)
	DebugLog.info("Base moved: player=%d, new_base=%s" % [player_id, target_pos])
	return {
		"squares": target_squares,
		"base_player_id": player_id,
		"base_before": base_before,
		"base_after": target_pos,
	}

static func resolve_board_zone_effect(game_state: GameStateData, player_id: int, stamp: Stamp, source_pos: Vector2, board_size: int, effect_color: int) -> Dictionary:
	var squares: Array[Vector2] = get_effect_squares(stamp, source_pos, board_size, effect_color)
	if stamp.effect_type == StampEffect.TYPE_INVALID_SQUARES or stamp.effect_type == StampEffect.TYPE_FROZEN_SQUARES:
		squares = filter_out_base_fields(game_state, squares)
	if squares.is_empty():
		return {}

	var target_player_id: int = int(stamp.effect_settings.get("target_player_id", -1))
	var turns_remaining: int = int(stamp.effect_settings.get("turns_remaining", stamp.duration))
	if turns_remaining == 0:
		turns_remaining = 1

	game_state.board_effects.append({
		"effect_type": stamp.effect_type,
		"owner_player_id": player_id,
		"target_player_id": target_player_id,
		"squares": squares,
		"turns_remaining": turns_remaining,
		"skip_next_tick": stamp.effect_type == StampEffect.TYPE_FROZEN_SQUARES,
	})
	DebugLog.info("Board effect added: type=%s, squares=%d" % [stamp.effect_type, squares.size()])
	return {
		"target_player_id": target_player_id,
		"squares": squares,
		"affected_count": squares.size(),
		"board_effect_turns_remaining": turns_remaining,
	}

static func get_effect_squares(stamp: Stamp, source_pos: Vector2, board_size: int, effect_color: int) -> Array[Vector2]:
	var squares: Array[Vector2] = []
	for square_pos: Vector2 in get_effect_squares_unfiltered(stamp, source_pos, effect_color):
		if MoveRules.is_valid_position(square_pos, board_size):
			squares.append(square_pos)

	return squares

static func get_effect_squares_unfiltered(stamp: Stamp, source_pos: Vector2, effect_color: int) -> Array[Vector2]:
	var squares: Array[Vector2] = []
	for offset: Vector2 in stamp.get_effect_offsets():
		squares.append(source_pos + (offset * effect_color))
	return squares

static func filter_out_base_fields(game_state: GameStateData, squares: Array[Vector2]) -> Array[Vector2]:
	var filtered_squares: Array[Vector2] = []
	for square_pos: Vector2 in squares:
		var is_base_field: bool = false
		for player_id in [0, 1]:
			if square_pos == get_base_field_for_player(game_state, player_id):
				is_base_field = true
				break
		if !is_base_field:
			filtered_squares.append(square_pos)
	return filtered_squares

static func resolve_bomb(game_state: GameStateData, player_id: int, stamp: Stamp, source_pos: Vector2, board_size: int, effect_color: int) -> Dictionary:
	var positions_to_remove: Array[Vector2] = []
	var affected_stamp_names: Array = []
	var own_pieces_affected: int = 0
	var enemy_pieces_affected: int = 0

	for target_pos: Vector2 in get_effect_squares(stamp, source_pos, board_size, effect_color):
		var target_piece: Piece = game_state.get_piece(target_pos)
		if target_piece != null:
			positions_to_remove.append(target_pos)
			if target_piece.attached_stamp != null:
				affected_stamp_names.append(target_piece.attached_stamp.stamp_name)
			var target_player_id: int = get_player_id_for_color(target_piece.color)
			if target_player_id == player_id:
				own_pieces_affected += 1
			else:
				enemy_pieces_affected += 1

	if !positions_to_remove.is_empty():
		register_bomb_effect(game_state, player_id, stamp.stamp_name, source_pos, get_effect_squares(stamp, source_pos, board_size, effect_color), positions_to_remove)

	for target_pos: Vector2 in positions_to_remove:
		remove_piece_as_effect_capture(game_state, player_id, target_pos)
		if game_state.game_over:
			break
	if !game_state.game_over:
		resolve_pending_respawns_for_all_players(game_state)

	DebugLog.info("Bomb resolved: player=%d, source=%s, removed=%d" % [player_id, source_pos, positions_to_remove.size()])
	return {
		"squares": get_effect_squares(stamp, source_pos, board_size, effect_color),
		"affected_positions": positions_to_remove,
		"affected_count": positions_to_remove.size(),
		"own_pieces_affected": own_pieces_affected,
		"enemy_pieces_affected": enemy_pieces_affected,
		"stamp_names": affected_stamp_names,
	}

static func register_bomb_effect(game_state: GameStateData, player_id: int, stamp_name: String, source_pos: Vector2, squares: Array[Vector2], affected_positions: Array[Vector2]) -> void:
	if game_state == null or affected_positions.is_empty():
		return

	game_state.recent_bomb_effects.append({
		"player_id": player_id,
		"stamp_name": stamp_name,
		"source_pos": source_pos,
		"squares": squares,
		"affected_positions": affected_positions,
	})

static func resolve_self_duration_adjustment(game_state: GameStateData, player_id: int, source_piece: Piece, source_pos: Vector2, board_size: int, delta: int) -> Dictionary:
	if source_piece == null or source_piece.attached_stamp == null:
		return {}

	var source_player_id: int = get_player_id_for_color(source_piece.color)
	return adjust_piece_duration(game_state, player_id, source_player_id, source_pos, source_piece, delta, board_size)

static func resolve_duration_adjustment(game_state: GameStateData, effect_owner_player_id: int, _stamp: Stamp, _source_piece: Piece, _source_pos: Vector2, board_size: int, target_player_id: int, delta: int) -> Dictionary:
	var affected_positions: Array[Vector2] = []
	var affected_stamp_names: Array = []
	var expired_stamp_names: Array = []
	var own_pieces_affected: int = 0
	var enemy_pieces_affected: int = 0
	var expired_count: int = 0
	var positions: Array = game_state.pieces.keys()

	for position_value in positions:
		var piece_pos: Vector2 = as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.get_piece(piece_pos)
		if piece == null or piece.attached_stamp == null:
			continue

		var piece_player_id: int = get_player_id_for_color(piece.color)
		if piece_player_id != target_player_id:
			continue

		var result: Dictionary = adjust_piece_duration(game_state, effect_owner_player_id, piece_player_id, piece_pos, piece, delta, board_size)
		if result.is_empty():
			continue

		affected_positions.append(piece_pos)
		affected_stamp_names.append(str(result.get("stamp_name", "")))
		if bool(result.get("expired", false)):
			expired_count += 1
			expired_stamp_names.append(str(result.get("stamp_name", "")))
		if piece_player_id == effect_owner_player_id:
			own_pieces_affected += 1
		else:
			enemy_pieces_affected += 1
		if game_state.game_over:
			break

	return {
		"target_player_id": target_player_id,
		"affected_positions": affected_positions,
		"affected_count": affected_positions.size(),
		"own_pieces_affected": own_pieces_affected,
		"enemy_pieces_affected": enemy_pieces_affected,
		"stamp_names": affected_stamp_names,
		"expired_count": expired_count,
		"expired_stamp_names": expired_stamp_names,
		"duration_delta": delta,
	}

static func adjust_piece_duration(game_state: GameStateData, effect_owner_player_id: int, piece_owner_player_id: int, piece_pos: Vector2, piece: Piece, delta: int, board_size: int) -> Dictionary:
	if piece == null or piece.attached_stamp == null or piece.turns_remaining == -1 or delta == 0:
		return {}

	var before: int = piece.turns_remaining
	piece.turns_remaining += delta
	var affected_stamp: Stamp = piece.attached_stamp
	var result: Dictionary = {
		"stamp_name": affected_stamp.stamp_name,
		"turns_before": before,
		"turns_after": piece.turns_remaining,
		"expired": false,
	}

	if piece.turns_remaining <= 0:
		result["expired"] = true
		expire_piece_stamp_due_to_duration_adjustment(game_state, effect_owner_player_id, piece_owner_player_id, piece_pos, piece, affected_stamp, board_size)

	return result

static func expire_piece_stamp_due_to_duration_adjustment(game_state: GameStateData, effect_owner_player_id: int, piece_owner_player_id: int, piece_pos: Vector2, piece: Piece, expired_stamp: Stamp, board_size: int) -> void:
	if piece == null or expired_stamp == null:
		return

	piece.detach_stamp()

	if MoveRules.is_seeker_stamp(expired_stamp):
		clear_seeker_position_if_needed(game_state, piece_owner_player_id, true)
		return_stamp_to_owner_deck(game_state, piece_owner_player_id, expired_stamp.stamp_name, piece_pos, "expired_seeker", expired_stamp)
		return

	register_stamp_expiration(game_state, piece_owner_player_id, expired_stamp.stamp_name, piece_pos)
	resolve_trigger(StampEffect.TRIGGER_ON_EXPIRE, game_state, {
		"player_id": piece_owner_player_id,
		"piece": piece,
		"piece_pos": piece_pos,
		"stamp": expired_stamp,
		"expired_by_player_id": effect_owner_player_id,
	}, board_size)

static func register_stamp_expiration(game_state: GameStateData, player_id: int, stamp_name: String, piece_pos: Vector2) -> void:
	if game_state == null:
		return

	game_state.recent_stamp_expirations.append({
		"player_id": player_id,
		"stamp_name": stamp_name,
		"piece_pos": [piece_pos.x, piece_pos.y],
	})

static func remove_piece_as_effect_capture(game_state: GameStateData, effect_owner_player_id: int, target_pos: Vector2) -> void:
	var target_piece: Piece = game_state.get_piece(target_pos)
	if target_piece == null:
		return

	var target_player_id: int = get_player_id_for_color(target_piece.color)
	var target_stamp: Stamp = target_piece.attached_stamp
	var target_was_seeker: bool = is_seeker_piece(target_piece)

	if target_stamp != null:
		if target_was_seeker:
			return_stamp_to_owner_deck(game_state, target_player_id, target_stamp.stamp_name, target_pos, "effect_capture", target_stamp)

	target_piece.detach_stamp()
	game_state.remove_piece(target_pos)
	respawn_captured_piece(game_state, target_piece, target_player_id)
	clear_seeker_position_if_needed(game_state, target_player_id, target_was_seeker)

	if target_was_seeker:
		DebugLog.info("Seeker removed by effect. Seeker stamp returned to player=%d deck. Effect owner=%d" % [target_player_id, effect_owner_player_id])

static func respawn_captured_piece(game_state: GameStateData, captured_piece: Piece, player_id: int) -> bool:
	if captured_piece == null or player_id < 0:
		return false

	if release_pending_respawn_piece(game_state, player_id):
		return true

	var respawn_pos: Vector2 = get_random_empty_home_position(game_state, player_id)
	if respawn_pos == Vector2(-1, -1):
		queue_pending_respawn_piece(game_state, captured_piece, player_id)
		push_warning("No empty non-base home row square for captured piece respawn. Piece queued.")
		return true

	captured_piece.position = respawn_pos
	captured_piece.set_respawn_cooldown(GameConfig.RESPAWN_COOLDOWN_OWN_TURNS)
	game_state.set_piece(respawn_pos, captured_piece)
	return true

static func release_pending_respawn_piece(game_state: GameStateData, player_id: int) -> bool:
	var player_color: int = get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color and piece.is_respawn_locked():
			piece.set_respawn_cooldown(0)
			return true

	var pending_respawns: Array = get_pending_respawns_for_player(game_state, player_id)
	for pending_piece_value in pending_respawns:
		var pending_piece: Piece = pending_piece_value as Piece
		if pending_piece != null and pending_piece.color == player_color and pending_piece.is_respawn_locked():
			pending_piece.set_respawn_cooldown(0)
			return true
	return false

static func get_random_empty_home_position(game_state: GameStateData, player_id: int) -> Vector2:
	var home_row: int = BoardConfig.get_home_row_for_player_id(player_id)
	var empty_positions: Array[Vector2] = []
	for col in BoardConfig.BOARD_SIZE:
		var pos: Vector2 = Vector2(home_row, col)
		if !game_state.pieces.has(pos) and !is_any_base_field(game_state, pos):
			empty_positions.append(pos)

	if empty_positions.is_empty():
		return Vector2(-1, -1)

	return empty_positions[randi() % empty_positions.size()]

static func queue_pending_respawn_piece(game_state: GameStateData, captured_piece: Piece, player_id: int) -> void:
	if game_state == null or captured_piece == null or player_id < 0:
		return

	var source_pos: Vector2 = captured_piece.position
	captured_piece.position = Vector2(-1, -1)
	captured_piece.set_respawn_cooldown(GameConfig.RESPAWN_COOLDOWN_OWN_TURNS)
	var pending_respawns: Array = get_pending_respawns_for_player(game_state, player_id)
	pending_respawns.append(captured_piece)
	game_state.pending_respawns[player_id] = pending_respawns
	register_pending_respawn_queue(game_state, {
		"player_id": player_id,
		"piece_color": captured_piece.color,
		"source_pos": source_pos,
	})

static func get_pending_respawns_for_player(game_state: GameStateData, player_id: int) -> Array:
	if game_state == null:
		return []
	if !game_state.pending_respawns.has(player_id):
		game_state.pending_respawns[player_id] = []
	return game_state.pending_respawns[player_id]

static func resolve_pending_respawns_for_all_players(game_state: GameStateData) -> Array[Dictionary]:
	var arrivals: Array[Dictionary] = []
	for player_id in [0, 1]:
		arrivals.append_array(resolve_pending_respawns_for_player(game_state, player_id))
	return arrivals

static func resolve_pending_respawns_for_player(game_state: GameStateData, player_id: int) -> Array[Dictionary]:
	var arrivals: Array[Dictionary] = []
	if game_state == null or player_id < 0:
		return arrivals

	var pending_respawns: Array = get_pending_respawns_for_player(game_state, player_id)
	while !pending_respawns.is_empty():
		var respawn_pos: Vector2 = get_random_empty_home_position(game_state, player_id)
		if respawn_pos == Vector2(-1, -1):
			break

		var piece: Piece = pending_respawns.pop_front() as Piece
		if piece == null:
			continue

		piece.position = respawn_pos
		game_state.set_piece(respawn_pos, piece)
		var arrival: Dictionary = {
			"player_id": player_id,
			"piece_color": piece.color,
			"respawn_pos": respawn_pos,
			"respawn_cooldown_turns": piece.respawn_cooldown_turns,
		}
		arrivals.append(arrival)
		register_pending_respawn_arrival(game_state, arrival)

	game_state.pending_respawns[player_id] = pending_respawns
	return arrivals

static func register_pending_respawn_arrival(game_state: GameStateData, arrival: Dictionary) -> void:
	if game_state == null or arrival.is_empty():
		return
	game_state.recent_pending_respawn_arrivals.append(arrival)

static func register_pending_respawn_queue(game_state: GameStateData, queue_event: Dictionary) -> void:
	if game_state == null or queue_event.is_empty():
		return
	game_state.recent_pending_respawn_queues.append(queue_event)

static func is_any_base_field(game_state: GameStateData, pos: Vector2) -> bool:
	for player_id in [0, 1]:
		if pos == BoardConfig.get_base_field_for_player_id(player_id):
			return true
		if pos == get_base_field_for_player(game_state, player_id):
			return true
	return false

static func is_base_field_for_other_player(game_state: GameStateData, pos: Vector2, owner_player_id: int) -> bool:
	for player_id in [0, 1]:
		if player_id == owner_player_id:
			continue
		if pos == get_base_field_for_player(game_state, player_id):
			return true
	return false

static func return_stamp_to_owner_deck(game_state: GameStateData, owner_player_id: int, stamp_name: String, source_pos: Vector2 = Vector2(-1, -1), reason: String = "effect_capture", stamp: Stamp = null) -> void:
	if game_state != null and game_state.has_codex_for_player(owner_player_id):
		var page_index: int = int(stamp.get_meta("codex_page_index", -1)) if stamp != null else -1
		var stamp_index: int = int(stamp.get_meta("codex_stamp_index", -1)) if stamp != null else -1
		game_state.return_stamp_to_codex_page(owner_player_id, stamp_name, page_index, stamp_index)
		register_stamp_transfer(game_state, owner_player_id, owner_player_id, stamp_name, "piece", "codex", source_pos)
		if game_state.match_logger != null:
			game_state.match_logger.log_stamp_event(game_state, "return_to_deck", {
				"player_id": owner_player_id,
				"stamp_name": stamp_name,
				"returned_stamp": stamp_name,
				"target_zone": "codex",
				"reason": reason,
			})
		return

	var deck: Array[String] = []
	if game_state.player_decks.has(owner_player_id):
		deck.assign(game_state.player_decks[owner_player_id])
	DeckManager.return_stamp_to_deck(deck, stamp_name)
	game_state.player_decks[owner_player_id] = deck
	register_stamp_transfer(game_state, owner_player_id, owner_player_id, stamp_name, "piece", "deck", source_pos)
	if game_state.match_logger != null:
		game_state.match_logger.log_stamp_event(game_state, "return_to_deck", {
			"player_id": owner_player_id,
			"stamp_name": stamp_name,
			"returned_stamp": stamp_name,
			"target_zone": "deck",
			"reason": reason,
		})

static func player_has_available_seeker_stamp(game_state: GameStateData, player_id: int) -> bool:
	if game_state.player_hands.has(player_id) && DeckManager.has_seeker_stamp(game_state.player_hands[player_id]):
		return true
	if game_state.player_decks.has(player_id) && DeckManager.has_seeker_stamp(game_state.player_decks[player_id]):
		return true

	var player_color: int = get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null && piece.color == player_color && MoveRules.is_seeker_stamp(piece.attached_stamp):
			return true
	return false

static func tick_board_effects(game_state: GameStateData) -> void:
	var remaining_effects: Array = []
	for effect_value in game_state.board_effects:
		var effect: Dictionary = effect_value
		var turns_remaining: int = int(effect.get("turns_remaining", -1))
		if turns_remaining == -1:
			remaining_effects.append(effect)
			continue

		if bool(effect.get("skip_next_tick", false)):
			effect.erase("skip_next_tick")
			remaining_effects.append(effect)
			continue

		turns_remaining -= 1
		if turns_remaining > 0:
			effect["turns_remaining"] = turns_remaining
			remaining_effects.append(effect)

	game_state.board_effects = remaining_effects

static func is_square_invalid(board_effects: Array, pos: Vector2, player_id: int = -1) -> bool:
	return has_square_effect(board_effects, StampEffect.TYPE_INVALID_SQUARES, pos, player_id)

static func is_square_frozen(board_effects: Array, pos: Vector2, player_id: int = -1) -> bool:
	return has_square_effect(board_effects, StampEffect.TYPE_FROZEN_SQUARES, pos, player_id)

static func has_square_effect(board_effects: Array, effect_type: String, pos: Vector2, player_id: int = -1) -> bool:
	for effect_value in board_effects:
		var effect: Dictionary = effect_value
		if str(effect.get("effect_type", "")) != effect_type:
			continue

		var target_player_id: int = int(effect.get("target_player_id", -1))
		if target_player_id != -1 && target_player_id != player_id:
			continue

		var squares: Array = effect.get("squares", [])
		if squares.has(pos):
			return true

	return false

static func can_player_control_piece(piece: Piece, player_id: int) -> bool:
	if piece == null:
		return false
	var player_color: int = get_color_for_player_id(player_id)
	if piece.color == player_color:
		return true
	return MoveRules.is_shared_stamp(piece.attached_stamp) || piece_has_attached_effect(piece, StampEffect.TYPE_SHARED_CONTROL)

static func is_piece_visible_to_player(piece: Piece, viewer_player_id: int) -> bool:
	if piece == null:
		return false
	var owner_player_id: int = get_player_id_for_color(piece.color)
	if owner_player_id == viewer_player_id:
		return true
	return !piece_has_attached_effect(piece, StampEffect.TYPE_INVISIBLE_TO_ENEMY)

static func piece_has_attached_effect(piece: Piece, effect_type: String) -> bool:
	return piece != null && piece.attached_stamp != null && piece.attached_stamp.effect_type == effect_type

static func count_symbol_pieces_for_player(game_state: GameStateData, player_id: int, symbol: String) -> int:
	if game_state == null or symbol.strip_edges().is_empty():
		return 0

	var player_color: int = get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece.attached_stamp == null:
			continue
		if piece.attached_stamp.symbol.strip_edges() == symbol:
			count += 1
	return count

static func is_seeker_piece(piece: Piece) -> bool:
	return piece != null && MoveRules.is_seeker_stamp(piece.attached_stamp)

static func clear_seeker_position_if_needed(game_state: GameStateData, player_id: int, was_seeker: bool) -> void:
	if !was_seeker:
		return
	if player_id == 0:
		game_state.white_seeker_position = Vector2(-1, -1)
	else:
		game_state.black_seeker_position = Vector2(-1, -1)

static func get_base_field_for_player(game_state: GameStateData, player_id: int) -> Vector2:
	if game_state.player_base_fields.has(player_id):
		return game_state.player_base_fields[player_id]
	return BoardConfig.get_base_field_for_player_id(player_id)

static func get_player_id_for_color(color: int) -> int:
	return BoardConfig.get_player_id_for_color(color)

static func get_color_for_player_id(player_id: int) -> int:
	return BoardConfig.get_color_for_player_id(player_id)

static func as_vector2(value, fallback: Vector2) -> Vector2:
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
		if dict_value.has("x") && dict_value.has("y"):
			return Vector2(float(dict_value.x), float(dict_value.y))
	return fallback
