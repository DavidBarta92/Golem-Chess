extends RefCounted
class_name AIStrategyDirector

const MODE_OPENING: String = "opening"
const MODE_ROUTE_SETUP: String = "route_setup"
const MODE_ACTIVE_SEEKER_PUSH: String = "active_seeker_push"
const MODE_ENDGAME_SEEKER_FINISH: String = "endgame_seeker_finish"
const MODE_SOFT_DEFENSE: String = "soft_defense"
const MODE_EMERGENCY_DEFENSE: String = "emergency_defense"

const CENTER_RADIUS: float = 2.0
const BASE_DANGER_RADIUS: float = 2.0
const BASE_PRESSURE_RADIUS: float = 3.0
const BASE_STAGING_RADIUS: float = 4.0
const ENDGAME_RESOURCE_COUNT: int = 5
const ENDGAME_DECK_COUNT: int = 2
const ENDGAME_HAND_COUNT: int = 2

func evaluate_strategy(game_state: GameStateData, player_id: int, memory: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> Dictionary:
	if game_state == null:
		return build_context(MODE_ROUTE_SETUP, player_id, memory, board_size)

	var context: Dictionary = build_context(MODE_ROUTE_SETUP, player_id, memory, board_size)
	context["own_piece_count"] = count_player_pieces(game_state, player_id)
	context["center_piece_count"] = count_player_pieces_in_center(game_state, player_id, board_size)
	context["opening_target_count"] = get_opening_target_count(int(context.get("own_piece_count", 0)))
	context["own_hand_count"] = get_player_hand_count(game_state, player_id)
	context["own_deck_count"] = get_player_deck_count(game_state, player_id)
	context["own_resource_count"] = int(context.get("own_hand_count", 0)) + int(context.get("own_deck_count", 0))
	context["own_active_seeker_count"] = count_active_seeker_pieces(game_state, player_id)
	context["own_available_seeker_count"] = count_available_seeker_stamps(game_state, player_id)
	context["enemy_active_seeker_count"] = count_active_seeker_pieces(game_state, 1 - player_id)
	context["enemy_available_seeker_count"] = count_available_seeker_stamps(game_state, 1 - player_id)
	context["enemy_base_pressure_count"] = count_enemy_pieces_near_base(game_state, player_id, BASE_PRESSURE_RADIUS)
	context["enemy_base_danger_count"] = count_enemy_pieces_near_base(game_state, player_id, BASE_DANGER_RADIUS)
	context["enemy_base_staging_count"] = count_enemy_pieces_near_base(game_state, player_id, BASE_STAGING_RADIUS)
	context["enemy_seeker_min_base_distance"] = get_enemy_seeker_min_base_distance(game_state, player_id)
	context["enemy_immediate_base_win"] = has_immediate_base_win(game_state, 1 - player_id, board_size)
	context["own_base"] = StampEffectResolver.get_base_field_for_player(game_state, player_id)
	context["opponent_base"] = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	context["center_zone_keys"] = get_center_zone_keys(board_size)

	var opening_completed: bool = bool(memory.get("opening_completed", false))
	if !opening_completed and has_opening_goal_completed(context):
		opening_completed = true
	memory["opening_completed"] = opening_completed
	context["opening_completed"] = opening_completed
	context["memory"] = memory.duplicate()

	if bool(context.get("enemy_immediate_base_win", false)) \
			or int(context.get("enemy_active_seeker_count", 0)) > 0 and float(context.get("enemy_seeker_min_base_distance", 99.0)) <= BASE_PRESSURE_RADIUS \
			or int(context.get("enemy_available_seeker_count", 0)) > 0 and int(context.get("enemy_base_danger_count", 0)) > 0:
		context["mode"] = MODE_EMERGENCY_DEFENSE
	elif int(context.get("own_active_seeker_count", 0)) > 0:
		context["mode"] = MODE_ACTIVE_SEEKER_PUSH
	elif should_enter_endgame_seeker_finish(context):
		context["mode"] = MODE_ENDGAME_SEEKER_FINISH
	elif int(context.get("enemy_base_danger_count", 0)) >= 2 \
			or int(context.get("enemy_active_seeker_count", 0)) > 0 \
			or int(context.get("enemy_available_seeker_count", 0)) > 0 and int(context.get("enemy_base_staging_count", 0)) > 0:
		context["mode"] = MODE_SOFT_DEFENSE
	elif !opening_completed:
		context["mode"] = MODE_OPENING
	else:
		context["mode"] = MODE_ROUTE_SETUP

	return context

func build_context(mode: String, player_id: int, memory: Dictionary, board_size: int) -> Dictionary:
	return {
		"mode": mode,
		"player_id": player_id,
		"board_size": board_size,
		"opening_completed": bool(memory.get("opening_completed", false)),
		"memory": memory.duplicate(),
	}

func has_opening_goal_completed(context: Dictionary) -> bool:
	var center_piece_count: int = int(context.get("center_piece_count", 0))
	var opening_target_count: int = int(context.get("opening_target_count", 3))
	if center_piece_count >= opening_target_count:
		return true
	return center_piece_count >= 1 and int(context.get("own_active_seeker_count", 0)) > 0

func get_opening_target_count(own_piece_count: int) -> int:
	if own_piece_count <= 0:
		return 0
	return mini(3, maxi(1, int(ceil(float(own_piece_count) * 0.5))))

func should_enter_endgame_seeker_finish(context: Dictionary) -> bool:
	if int(context.get("own_available_seeker_count", 0)) <= 0:
		return false

	var resource_count: int = int(context.get("own_resource_count", 99))
	var deck_count: int = int(context.get("own_deck_count", 99))
	var hand_count: int = int(context.get("own_hand_count", 99))
	return resource_count <= ENDGAME_RESOURCE_COUNT or deck_count <= ENDGAME_DECK_COUNT and hand_count <= ENDGAME_HAND_COUNT

func get_player_hand_count(game_state: GameStateData, player_id: int) -> int:
	return game_state.player_hands.get(player_id, []).size()

func get_player_deck_count(game_state: GameStateData, player_id: int) -> int:
	return game_state.player_decks.get(player_id, []).size()

func count_available_seeker_stamps(game_state: GameStateData, player_id: int) -> int:
	var count: int = 0
	var seen: Dictionary = {}
	var stamp_names: Array = []
	stamp_names.append_array(game_state.player_hands.get(player_id, []))
	stamp_names.append_array(game_state.player_decks.get(player_id, []))
	for stamp_name_value in stamp_names:
		var stamp_name: String = str(stamp_name_value)
		if seen.has(stamp_name):
			continue
		seen[stamp_name] = true
		var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
		if stamp != null and MoveRules.is_seeker_stamp(stamp):
			count += 1
	return count

func count_player_pieces(game_state: GameStateData, player_id: int) -> int:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color:
			count += 1
	return count

func count_player_pieces_in_center(game_state: GameStateData, player_id: int, board_size: int) -> int:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color and is_in_center_zone(pos, board_size):
			count += 1
	return count

func count_active_seeker_pieces(game_state: GameStateData, player_id: int) -> int:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color and MoveRules.is_seeker_stamp(piece.attached_stamp):
			count += 1
	return count

func count_enemy_pieces_near_base(game_state: GameStateData, player_id: int, radius: float) -> int:
	var enemy_color: int = StampEffectResolver.get_color_for_player_id(1 - player_id)
	var own_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == enemy_color and get_manhattan_distance(pos, own_base) <= radius:
			count += 1
	return count

func get_enemy_seeker_min_base_distance(game_state: GameStateData, player_id: int) -> float:
	var enemy_color: int = StampEffectResolver.get_color_for_player_id(1 - player_id)
	var own_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, player_id)
	var best_distance: float = 99.0
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == enemy_color and MoveRules.is_seeker_stamp(piece.attached_stamp):
			best_distance = minf(best_distance, get_manhattan_distance(pos, own_base))
	return best_distance

func has_immediate_base_win(game_state: GameStateData, player_id: int, board_size: int) -> bool:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(game_state.pieces, player_color, board_size, game_state.board_effects)
	for move: Dictionary in valid_moves:
		if AIStateSimulator.get_move_to(move) == opponent_base and AIStateSimulator.is_own_seeker_candidate(game_state.pieces, move, player_id):
			return true
	return false

func get_center_zone_keys(board_size: int) -> Array[String]:
	var keys: Array[String] = []
	for x in range(board_size):
		for y in range(board_size):
			var pos: Vector2 = Vector2(x, y)
			if is_in_center_zone(pos, board_size):
				keys.append(vector_hash(pos))
	return keys

func is_in_center_zone(pos: Vector2, board_size: int) -> bool:
	var center: Vector2 = Vector2(float(board_size - 1) / 2.0, float(board_size - 1) / 2.0)
	return get_manhattan_distance(pos, center) <= CENTER_RADIUS

func get_manhattan_distance(left: Vector2, right: Vector2) -> float:
	return abs(left.x - right.x) + abs(left.y - right.y)

func vector_hash(value: Vector2) -> String:
	return "%d,%d" % [int(value.x), int(value.y)]
