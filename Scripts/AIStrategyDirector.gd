extends RefCounted
class_name AIStrategyDirector

const MODE_OPENING: String = "opening"
const MODE_ROUTE_SETUP: String = "route_setup"
## The player's crowned golem is on the board: walk it onto the enemy base.
const MODE_CROWN_PUSH: String = "crown_push"
## The codex is running out and the crown is (nearly) charged: get a golem
## within reach of the base and crown it.
const MODE_ENDGAME_FINISH: String = "endgame_finish"
## The same staging and crowning as the endgame finish, while there is still
## plenty of codex left: entered as soon as an attack is on.
const MODE_CROWN_ATTACK: String = "crown_attack"
const MODE_SOFT_DEFENSE: String = "soft_defense"
const MODE_EMERGENCY_DEFENSE: String = "emergency_defense"

const CENTER_RADIUS: float = 2.0
const BASE_DANGER_RADIUS: float = 2.0
const BASE_PRESSURE_RADIUS: float = 3.0
const BASE_STAGING_RADIUS: float = 4.0
const ENDGAME_RESOURCE_COUNT: int = 5
const ENDGAME_DECK_COUNT: int = 2
const ENDGAME_HAND_COUNT: int = 2
## The crown counts as coming soon this many of the player's own turns before
## it can be put down.
const CROWN_SOON_TURNS: int = 1
## Enemy golems crowding the own base are only a danger to defend against once
## the enemy crown is this close to charged.
const ENEMY_CROWN_DANGER_TURNS: int = 2
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
## golems crowding the own base (no enemy crown on the board yet).
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
	# Both crown meters are open to both players, so reading the opponent's is fair.
	context["own_crown_on_board"] = game_state.has_crown_on_board(player_id)
	context["own_crown_turns_to_ready"] = AIMoveEvaluator.get_crown_turns_to_ready(game_state, player_id)
	context["enemy_crown_on_board"] = game_state.has_crown_on_board(1 - player_id)
	context["enemy_crown_turns_to_ready"] = AIMoveEvaluator.get_crown_turns_to_ready(game_state, 1 - player_id)
	context["enemy_base_pressure_count"] = count_enemy_pieces_near_base(game_state, player_id, BASE_PRESSURE_RADIUS)
	context["enemy_base_danger_count"] = count_enemy_pieces_near_base(game_state, player_id, BASE_DANGER_RADIUS)
	context["enemy_base_staging_count"] = count_enemy_pieces_near_base(game_state, player_id, BASE_STAGING_RADIUS)
	context["enemy_crown_base_distance"] = get_enemy_crown_base_distance(game_state, player_id)
	context["enemy_immediate_base_win"] = has_immediate_base_win(game_state, 1 - player_id, board_size)
	context["own_base"] = StampEffectResolver.get_base_field_for_player(game_state, player_id)
	context["opponent_base"] = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	context["center_zone_keys"] = get_center_zone_keys(board_size)
	context["own_completed_turns"] = int(game_state.completed_turn_counts.get(player_id, 0))
	context["own_attack_staging_count"] = count_own_pieces_near_opponent_base(game_state, player_id, ATTACK_STAGING_RADIUS)
	context["resource_advantage"] = get_resource_advantage(game_state, player_id)
	context["aggression"] = aggression

	var opening_completed: bool = bool(memory.get("opening_completed", false))
	if !opening_completed and has_opening_goal_completed(context):
		opening_completed = true
	memory["opening_completed"] = opening_completed
	context["opening_completed"] = opening_completed
	context["memory"] = memory.duplicate()

	var attack_ready: bool = should_enter_crown_attack(context)
	var enemy_crown_on_board: bool = bool(context.get("enemy_crown_on_board", false))
	var crowded_base: bool = int(context.get("enemy_base_danger_count", 0)) >= 2 \
		and int(context.get("enemy_crown_turns_to_ready", 99)) <= ENEMY_CROWN_DANGER_TURNS
	if bool(context.get("enemy_immediate_base_win", false)) \
			or enemy_crown_on_board and float(context.get("enemy_crown_base_distance", 99.0)) <= BASE_PRESSURE_RADIUS:
		context["mode"] = MODE_EMERGENCY_DEFENSE
	elif bool(context.get("own_crown_on_board", false)):
		context["mode"] = MODE_CROWN_PUSH
	elif should_enter_endgame_finish(context):
		context["mode"] = MODE_ENDGAME_FINISH
	elif enemy_crown_on_board:
		context["mode"] = MODE_SOFT_DEFENSE
	elif attack_ready and (!crowded_base or aggression >= ATTACK_OVER_CROWD_AGGRESSION):
		context["mode"] = MODE_CROWN_ATTACK
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
	return center_piece_count >= 1 and bool(context.get("own_crown_on_board", false))

func get_opening_target_count(own_piece_count: int) -> int:
	if own_piece_count <= 0:
		return 0
	return mini(OPENING_TARGET_MAX, maxi(1, int(ceil(float(own_piece_count) * 0.5))))

## An attack is on once the opening is over and the crown is (nearly) charged,
## as soon as there is a golem within striking distance of the enemy base, a
## clear lead, or the match has run long.
func should_enter_crown_attack(context: Dictionary) -> bool:
	if !bool(context.get("opening_completed", false)):
		return false
	if !is_crown_coming_soon(context):
		return false
	if float(context.get("resource_advantage", 0.0)) >= ATTACK_RESOURCE_ADVANTAGE:
		return true
	if int(context.get("own_completed_turns", 0)) >= ATTACK_TURN_LIMIT:
		return true
	return int(context.get("own_attack_staging_count", 0)) > 0

func is_crown_coming_soon(context: Dictionary) -> bool:
	return int(context.get("own_crown_turns_to_ready", 99)) <= CROWN_SOON_TURNS

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

func should_enter_endgame_finish(context: Dictionary) -> bool:
	if !is_crown_coming_soon(context):
		return false

	var resource_count: int = int(context.get("own_resource_count", 99))
	var deck_count: int = int(context.get("own_deck_count", 99))
	var hand_count: int = int(context.get("own_hand_count", 99))
	return resource_count <= ENDGAME_RESOURCE_COUNT or deck_count <= ENDGAME_DECK_COUNT and hand_count <= ENDGAME_HAND_COUNT

func get_player_hand_count(game_state: GameStateData, player_id: int) -> int:
	return game_state.player_hands.get(player_id, []).size()

func get_player_deck_count(game_state: GameStateData, player_id: int) -> int:
	return game_state.player_decks.get(player_id, []).size()

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

func get_enemy_crown_base_distance(game_state: GameStateData, player_id: int) -> float:
	var crowned_pos: Vector2 = game_state.get_crowned_piece_position(1 - player_id)
	if crowned_pos == Vector2(-1, -1):
		return 99.0
	return get_manhattan_distance(crowned_pos, StampEffectResolver.get_base_field_for_player(game_state, player_id))

func has_immediate_base_win(game_state: GameStateData, player_id: int, board_size: int) -> bool:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(game_state.pieces, player_color, board_size, game_state.board_effects)
	for move: Dictionary in valid_moves:
		if AIStateSimulator.is_base_win_move(game_state.pieces, move, player_id, opponent_base):
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
