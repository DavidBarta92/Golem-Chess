extends RefCounted
class_name CardEffectResolver

const DEFAULT_BOARD_SIZE: int = 5
const DEFAULT_MAX_HAND_SIZE: int = 5
const DEFAULT_WHITE_BASE_FIELD: Vector2 = Vector2(0, 2)
const DEFAULT_BLACK_BASE_FIELD: Vector2 = Vector2(4, 2)

static func resolve_trigger(trigger: String, game_state: GameStateData, context: Dictionary, board_size: int = DEFAULT_BOARD_SIZE) -> bool:
	if game_state == null or game_state.game_over:
		return false

	var card: Card = get_context_card(context)
	if card == null or !card.has_effect() or card.effect_trigger != trigger:
		return false

	var player_id: int = get_context_player_id(context)
	var source_pos: Vector2 = get_context_piece_position(context)
	var effect_color: int = get_context_effect_color(context, player_id)
	match card.effect_type:
		CardEffect.TYPE_STEAL_CARD:
			resolve_steal_card(game_state, player_id, card)
		CardEffect.TYPE_GRANT_CARD:
			resolve_grant_card(game_state, player_id, card)
		CardEffect.TYPE_MOVE_BASE:
			resolve_move_base(game_state, player_id, card, source_pos, board_size, effect_color)
		CardEffect.TYPE_INVALID_SQUARES:
			resolve_board_zone_effect(game_state, player_id, card, source_pos, board_size, effect_color)
		CardEffect.TYPE_FROZEN_SQUARES:
			resolve_board_zone_effect(game_state, player_id, card, source_pos, board_size, effect_color)
		CardEffect.TYPE_BOMB:
			resolve_bomb(game_state, player_id, card, source_pos, board_size, effect_color)
		_:
			pass

	return true

static func get_context_card(context: Dictionary) -> Card:
	var card: Card = context.get("card", null) as Card
	if card != null:
		return card

	var piece: Piece = context.get("piece", null) as Piece
	if piece != null:
		return piece.attached_card

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

static func resolve_steal_card(game_state: GameStateData, player_id: int, card: Card) -> void:
	var params: Dictionary = card.effect_settings
	var source_player_id: int = int(params.get("source_player_id", 1 - player_id))
	var amount: int = max(1, int(params.get("amount", 1)))
	var source: String = str(params.get("source", "enemy_hand"))
	var max_hand_size: int = max(1, int(params.get("max_hand_size", DEFAULT_MAX_HAND_SIZE)))

	for steal_index in range(amount):
		var stolen_card_name: String = take_card_from_player_zone(game_state, source_player_id, source)
		if stolen_card_name.is_empty():
			return

		give_card_to_player(game_state, player_id, stolen_card_name, max_hand_size)
		print("Card stolen: player=%d stole %s from player=%d" % [player_id, stolen_card_name, source_player_id])

static func resolve_grant_card(game_state: GameStateData, player_id: int, card: Card) -> void:
	var params: Dictionary = card.effect_settings
	var granted_card_name: String = str(params.get("card_name", ""))
	if granted_card_name.is_empty():
		return

	var target_player_id: int = int(params.get("target_player_id", player_id))
	var amount: int = max(1, int(params.get("amount", 1)))
	var max_hand_size: int = max(1, int(params.get("max_hand_size", DEFAULT_MAX_HAND_SIZE)))
	for grant_index in range(amount):
		give_card_to_player(game_state, target_player_id, granted_card_name, max_hand_size)

	print("Card granted: %s x%d to player=%d" % [granted_card_name, amount, target_player_id])

static func take_card_from_player_zone(game_state: GameStateData, source_player_id: int, source: String) -> String:
	var source_cards: Array = []
	if source == "enemy_deck":
		source_cards = game_state.player_decks.get(source_player_id, [])
	else:
		source_cards = game_state.player_hands.get(source_player_id, [])

	if source_cards.is_empty():
		return ""

	var stolen_index: int = randi() % source_cards.size()
	var stolen_card_name: String = str(source_cards[stolen_index])
	source_cards.remove_at(stolen_index)

	if source == "enemy_deck":
		game_state.player_decks[source_player_id] = source_cards
	else:
		game_state.player_hands[source_player_id] = source_cards

	return stolen_card_name

static func give_card_to_player(game_state: GameStateData, player_id: int, card_name: String, max_hand_size: int) -> void:
	var hand: Array = game_state.player_hands.get(player_id, [])
	if hand.size() < max_hand_size:
		hand.append(card_name)
		game_state.player_hands[player_id] = hand
		return

	var deck: Array = game_state.player_decks.get(player_id, [])
	deck.append(card_name)
	game_state.player_decks[player_id] = deck

static func resolve_move_base(game_state: GameStateData, player_id: int, card: Card, source_pos: Vector2, board_size: int, effect_color: int) -> void:
	var target_squares: Array[Vector2] = get_effect_squares(card, source_pos, board_size, effect_color)
	if target_squares.is_empty():
		return

	var target_pos: Vector2 = target_squares[0]
	if !MoveRules.is_valid_position(target_pos, board_size):
		return

	game_state.player_base_fields[player_id] = target_pos
	print("Base moved: player=%d, new_base=%s" % [player_id, target_pos])

static func resolve_board_zone_effect(game_state: GameStateData, player_id: int, card: Card, source_pos: Vector2, board_size: int, effect_color: int) -> void:
	var squares: Array[Vector2] = get_effect_squares(card, source_pos, board_size, effect_color)
	if squares.is_empty():
		return

	var target_player_id: int = int(card.effect_settings.get("target_player_id", -1))
	var turns_remaining: int = int(card.effect_settings.get("turns_remaining", card.duration))
	if turns_remaining == 0:
		turns_remaining = 1

	game_state.board_effects.append({
		"effect_type": card.effect_type,
		"owner_player_id": player_id,
		"target_player_id": target_player_id,
		"squares": squares,
		"turns_remaining": turns_remaining,
	})
	print("Board effect added: type=%s, squares=%d" % [card.effect_type, squares.size()])

static func get_effect_squares(card: Card, source_pos: Vector2, board_size: int, effect_color: int) -> Array[Vector2]:
	var squares: Array[Vector2] = []
	for offset: Vector2 in card.get_effect_offsets():
		var square_pos: Vector2 = source_pos + (offset * effect_color)
		if MoveRules.is_valid_position(square_pos, board_size):
			squares.append(square_pos)

	return squares

static func resolve_bomb(game_state: GameStateData, player_id: int, card: Card, source_pos: Vector2, board_size: int, effect_color: int) -> void:
	var positions_to_remove: Array[Vector2] = []

	for target_pos: Vector2 in get_effect_squares(card, source_pos, board_size, effect_color):
		if game_state.get_piece(target_pos) != null:
			positions_to_remove.append(target_pos)

	for target_pos: Vector2 in positions_to_remove:
		remove_piece_as_effect_capture(game_state, player_id, target_pos)
		if game_state.game_over:
			return

	print("Bomb resolved: player=%d, source=%s, removed=%d" % [player_id, source_pos, positions_to_remove.size()])

static func remove_piece_as_effect_capture(game_state: GameStateData, effect_owner_player_id: int, target_pos: Vector2) -> void:
	var target_piece: Piece = game_state.get_piece(target_pos)
	if target_piece == null:
		return

	var target_player_id: int = get_player_id_for_color(target_piece.color)
	var target_card: Card = target_piece.attached_card
	var target_was_king: bool = is_king_piece(target_piece)

	if target_card != null && !target_was_king && target_piece.turns_remaining > 0:
		return_card_to_owner_deck(game_state, target_player_id, target_card.card_name)

	game_state.remove_piece(target_pos)
	clear_king_position_if_needed(game_state, target_player_id, target_was_king)

	if target_was_king:
		var winner_player_id: int = 1 - target_player_id
		game_state.game_over = true
		game_state.winner_player = winner_player_id
		print("King removed by effect. Effect owner=%d, winner=%d" % [effect_owner_player_id, winner_player_id])

static func return_card_to_owner_deck(game_state: GameStateData, owner_player_id: int, card_name: String) -> void:
	if !game_state.player_decks.has(owner_player_id):
		game_state.player_decks[owner_player_id] = []
	var deck: Array = game_state.player_decks[owner_player_id]
	DeckManager.return_card_to_deck(deck, card_name)
	game_state.player_decks[owner_player_id] = deck

static func tick_board_effects(game_state: GameStateData) -> void:
	var remaining_effects: Array = []
	for effect_value in game_state.board_effects:
		var effect: Dictionary = effect_value
		var turns_remaining: int = int(effect.get("turns_remaining", -1))
		if turns_remaining == -1:
			remaining_effects.append(effect)
			continue

		turns_remaining -= 1
		if turns_remaining > 0:
			effect["turns_remaining"] = turns_remaining
			remaining_effects.append(effect)

	game_state.board_effects = remaining_effects

static func is_square_invalid(board_effects: Array, pos: Vector2, player_id: int = -1) -> bool:
	return has_square_effect(board_effects, CardEffect.TYPE_INVALID_SQUARES, pos, player_id)

static func is_square_frozen(board_effects: Array, pos: Vector2, player_id: int = -1) -> bool:
	return has_square_effect(board_effects, CardEffect.TYPE_FROZEN_SQUARES, pos, player_id)

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
	return piece_has_attached_effect(piece, CardEffect.TYPE_SHARED_CONTROL)

static func is_piece_visible_to_player(piece: Piece, viewer_player_id: int) -> bool:
	if piece == null:
		return false
	var owner_player_id: int = get_player_id_for_color(piece.color)
	if owner_player_id == viewer_player_id:
		return true
	return !piece_has_attached_effect(piece, CardEffect.TYPE_INVISIBLE_TO_ENEMY)

static func piece_has_attached_effect(piece: Piece, effect_type: String) -> bool:
	return piece != null && piece.attached_card != null && piece.attached_card.effect_type == effect_type

static func is_king_piece(piece: Piece) -> bool:
	return piece != null && piece.attached_card != null && piece.attached_card.card_name == MoveRules.KING_CARD_NAME

static func clear_king_position_if_needed(game_state: GameStateData, player_id: int, was_king: bool) -> void:
	if !was_king:
		return
	if player_id == 0:
		game_state.white_king_position = Vector2(-1, -1)
	else:
		game_state.black_king_position = Vector2(-1, -1)

static func get_base_field_for_player(game_state: GameStateData, player_id: int) -> Vector2:
	if game_state.player_base_fields.has(player_id):
		return game_state.player_base_fields[player_id]
	return DEFAULT_WHITE_BASE_FIELD if player_id == 0 else DEFAULT_BLACK_BASE_FIELD

static func get_player_id_for_color(color: int) -> int:
	return 0 if color == 1 else 1

static func get_color_for_player_id(player_id: int) -> int:
	return 1 if player_id == 0 else -1

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
