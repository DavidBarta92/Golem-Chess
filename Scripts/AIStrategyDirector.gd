extends RefCounted
class_name AIStrategyDirector

const MODE_OPENING: String = "opening"
const MODE_ROUTE_SETUP: String = "route_setup"
const MODE_ACTIVE_SEEKER_PUSH: String = "active_seeker_push"
const MODE_ENDGAME_SEEKER_FINISH: String = "endgame_seeker_finish"
## Going for the base with a Seeker while there is still plenty of codex left:
## the same staging and affix logic as the endgame finish, entered as soon as an
## attack is on rather than only once the stamps are running out.
const MODE_SEEKER_ATTACK: String = "seeker_attack"
const MODE_SOFT_DEFENSE: String = "soft_defense"
const MODE_EMERGENCY_DEFENSE: String = "emergency_defense"

const CENTER_RADIUS: float = 2.0
const BASE_DANGER_RADIUS: float = 2.0
const BASE_PRESSURE_RADIUS: float = 3.0
const BASE_STAGING_RADIUS: float = 4.0
const ENDGAME_RESOURCE_COUNT: int = 5
const ENDGAME_DECK_COUNT: int = 2
const ENDGAME_HAND_COUNT: int = 2
## The opening ends at this many golems in the centre, or after this many of
## the player's own turns (the first, stamp-only turn included), whichever
## comes first. Matches last 10-20 turns a side, so an open-ended opening ate
## most of them.
const OPENING_TARGET_MAX: int = 2
const OPENING_MAX_OWN_TURNS: int = 4
const ATTACK_STAGING_RADIUS: float = 3.0
const ATTACK_TURN_LIMIT: int = 8
const ATTACK_RESOURCE_ADVANTAGE: float = 3.0
## From this aggression up, an attack that is ready goes ahead even with enemy
## golems crowding the own base (no enemy Seeker on the board yet).
const ATTACK_OVER_CROWD_AGGRESSION: float = 0.7
const RESOURCE_WEIGHT_USABLE_GOLEM: float = 2.0
const RESOURCE_WEIGHT_STAMPED_GOLEM: float = 1.0
const RESOURCE_WEIGHT_CODEX_STAMP: float = 0.5

func evaluate_strategy(
	game_state: GameStateData,
	player_id: int,
	memory: Dictionary,
	board_size: int = BoardConfig.BOARD_SIZE,
	aggression: float = 0.5
) -> Dictionary:
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
	# Deliberately not reading the opponent's hidden Codex pages here (count_available_seeker_stamps
	# would need game_state.player_decks[1 - player_id]): a real opponent can't see those either,
	# so the AI is limited to what's visible on the board, like a human would be.
	context["enemy_base_pressure_count"] = count_enemy_pieces_near_base(game_state, player_id, BASE_PRESSURE_RADIUS)
	context["enemy_base_danger_count"] = count_enemy_pieces_near_base(game_state, player_id, BASE_DANGER_RADIUS)
	context["enemy_base_staging_count"] = count_enemy_pieces_near_base(game_state, player_id, BASE_STAGING_RADIUS)
	context["enemy_seeker_min_base_distance"] = get_enemy_seeker_min_base_distance(game_state, player_id)
	context["enemy_immediate_base_win"] = has_immediate_base_win(game_state, 1 - player_id, board_size)
	context["own_base"] = StampEffectResolver.get_base_field_for_player(game_state, player_id)
	context["opponent_base"] = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	context["center_zone_keys"] = get_center_zone_keys(board_size)
	context["own_completed_turns"] = int(game_state.completed_turn_counts.get(player_id, 0))
	context["own_reachable_seeker_count"] = count_reachable_seeker_stamps(game_state, player_id)
	context["own_attack_staging_count"] = count_own_pieces_near_opponent_base(game_state, player_id, ATTACK_STAGING_RADIUS)
	context["resource_advantage"] = get_resource_advantage(game_state, player_id)
	context["aggression"] = aggression

	var opening_completed: bool = bool(memory.get("opening_completed", false))
	if !opening_completed and has_opening_goal_completed(context):
		opening_completed = true
	memory["opening_completed"] = opening_completed
	context["opening_completed"] = opening_completed
	context["memory"] = memory.duplicate()

	var attack_ready: bool = should_enter_seeker_attack(context)
	var crowded_base: bool = int(context.get("enemy_base_danger_count", 0)) >= 2
	if bool(context.get("enemy_immediate_base_win", false)) \
			or int(context.get("enemy_active_seeker_count", 0)) > 0 and float(context.get("enemy_seeker_min_base_distance", 99.0)) <= BASE_PRESSURE_RADIUS:
		context["mode"] = MODE_EMERGENCY_DEFENSE
	elif int(context.get("own_active_seeker_count", 0)) > 0:
		context["mode"] = MODE_ACTIVE_SEEKER_PUSH
	elif should_enter_endgame_seeker_finish(context):
		context["mode"] = MODE_ENDGAME_SEEKER_FINISH
	elif int(context.get("enemy_active_seeker_count", 0)) > 0:
		context["mode"] = MODE_SOFT_DEFENSE
	elif attack_ready and (!crowded_base or aggression >= ATTACK_OVER_CROWD_AGGRESSION):
		context["mode"] = MODE_SEEKER_ATTACK
	elif crowded_base:
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
	var opening_target_count: int = int(context.get("opening_target_count", OPENING_TARGET_MAX))
	if center_piece_count >= opening_target_count:
		return true
	if int(context.get("own_completed_turns", 0)) >= OPENING_MAX_OWN_TURNS:
		return true
	return center_piece_count >= 1 and int(context.get("own_active_seeker_count", 0)) > 0

func get_opening_target_count(own_piece_count: int) -> int:
	if own_piece_count <= 0:
		return 0
	return mini(OPENING_TARGET_MAX, maxi(1, int(ceil(float(own_piece_count) * 0.5))))

## An attack is on once the opening is over and a Seeker can be put down soon
## (on the open page, or one page turn away), as soon as there is a golem within
## striking distance of the enemy base, a clear lead, or the match has run long.
func should_enter_seeker_attack(context: Dictionary) -> bool:
	if !bool(context.get("opening_completed", false)):
		return false
	if int(context.get("own_reachable_seeker_count", 0)) <= 0:
		return false
	if float(context.get("resource_advantage", 0.0)) >= ATTACK_RESOURCE_ADVANTAGE:
		return true
	if int(context.get("own_completed_turns", 0)) >= ATTACK_TURN_LIMIT:
		return true
	return int(context.get("own_attack_staging_count", 0)) > 0

## Seekers on the open page, plus those on the page a single page turn opens.
func count_reachable_seeker_stamps(game_state: GameStateData, player_id: int) -> int:
	var stamp_names: Array = []
	stamp_names.append_array(game_state.player_hands.get(player_id, []))
	if game_state.has_codex_for_player(player_id):
		var current_page_index: int = game_state.get_current_page_index(player_id)
		var next_page_index: int = game_state.find_next_non_empty_page(player_id, current_page_index)
		if next_page_index != -1 and next_page_index != current_page_index:
			stamp_names.append_array(game_state.get_codex_pages(player_id)[next_page_index])
	var count: int = 0
	for stamp_name_value in stamp_names:
		var stamp: Stamp = StampLibrary.get_stamp(str(stamp_name_value))
		if stamp != null and MoveRules.is_seeker_stamp(stamp):
			count += 1
	return count

func count_own_pieces_near_opponent_base(game_state: GameStateData, player_id: int, radius: float) -> int:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece.is_respawn_locked():
			continue
		if get_manhattan_distance(pos, opponent_base) <= radius:
			count += 1
	return count

## How far ahead the player is in what each side can still do: unlocked golems
## weigh most, then golems carrying a stamp, then stamps left in the codex.
## Raw golem counts are no use for this - a captured golem respawns, and only
## every second capture takes one off the board. Both sides' codex sizes are
## public, so this reads nothing a human player could not see.
static func get_resource_advantage(game_state: GameStateData, player_id: int) -> float:
	return get_side_resources(game_state, player_id) - get_side_resources(game_state, 1 - player_id)

static func get_side_resources(game_state: GameStateData, player_id: int) -> float:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var usable_golems: int = 0
	var stamped_golems: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color:
			continue
		if !piece.is_respawn_locked():
			usable_golems += 1
		if piece.affixed_stamp != null:
			stamped_golems += 1
	var codex_stamps: int = game_state.player_hands.get(player_id, []).size() + game_state.player_decks.get(player_id, []).size()
	return float(usable_golems) * RESOURCE_WEIGHT_USABLE_GOLEM \
		+ float(stamped_golems) * RESOURCE_WEIGHT_STAMPED_GOLEM \
		+ float(codex_stamps) * RESOURCE_WEIGHT_CODEX_STAMP

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
		if piece != null and piece.color == player_color and MoveRules.is_seeker_stamp(piece.affixed_stamp):
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
		if piece != null and piece.color == enemy_color and MoveRules.is_seeker_stamp(piece.affixed_stamp):
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
