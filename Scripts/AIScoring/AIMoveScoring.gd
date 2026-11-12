extends RefCounted
class_name AIMoveScoring

## A single move or affix: what its step, its capture and its stamp's effect are
## worth, and what it risks. AIPlanScoring adds these up for a whole turn.

const SCORE_CAPTURE_BASE_STAGING_PIECE: float = 180.0
const SCORE_AFFIX_STAMP: float = 10.0
const SCORE_CENTER: float = 4.0
const SCORE_USE_EXISTING_STAMP: float = 4.0
const SCORE_AFFIX_SETUP_MOBILITY: float = 5.0
const PENALTY_AFFIX_SETUP_NO_MOVE: float = 8.0
const PENALTY_PIECE_THREATENED: float = 35.0
const PENALTY_REPEAT_LAST_MOVE: float = 170.0
## A plain step with a stamp that drains its own side, on top of what the lost
## steps are worth (score_own_drain_step): a flat part, and a part for each
## other stamped golem it drains.
const PENALTY_OWN_DRAIN_STEP: float = 120.0
const PENALTY_OWN_DRAIN_STAMP: float = 60.0
## Walking such a stamp out of a capture when it should not: with this many other
## stamped golems to drain, or a crown that can move to a safe golem instead. More
## than the crown on it is worth (PENALTY_CROWN_THREATENED and the crown race).
const OWN_DRAIN_SACRIFICE_STAMPS: int = 3
const PENALTY_OWN_DRAIN_FLIGHT: float = 3000.0
## Walking such a stamp without the crown while it has other stamped golems to
## drain, on the same scale: only a move with nothing better left does it.
const PENALTY_OWN_DRAIN_WALK: float = 3000.0
const SCORE_THREATEN_CROWN: float = 420.0
const PENALTY_CROWN_THREATENED: float = 1400.0
const SCORE_CROWN_BASE_PROGRESS: float = 35.0
## A stamp on the own bearer that reaches the base in one step, and one that
## lasts the whole way there.
const SCORE_CROWN_BASE_ENTRY_THREAT: float = 900.0
const SCORE_CROWN_STAMP_IN_ROUTE: float = 220.0
const PENALTY_NON_BEARER_BASE_ENTRY: float = 420.0
const INVALID_POS: Vector2 = AIScoringContext.INVALID_POS
const SCORE_WIN: float = AIScoringContext.SCORE_WIN
const STAMP_ESTIMATE_POINT_SCORE: float = AIStampValues.STAMP_ESTIMATE_POINT_SCORE
const STAMP_VALUE_AFFIX_EXCHANGE_WEIGHT: float = AIStampValues.STAMP_VALUE_AFFIX_EXCHANGE_WEIGHT
const STAMP_VALUE_AFFIX_PLAY_WEIGHT: float = AIStampValues.STAMP_VALUE_AFFIX_PLAY_WEIGHT

var context: AIScoringContext
var reach: AIReach
var se_tenant_scoring: AISeTenantScoring
var effect_scoring: AIEffectScoring
var crown_race: AICrownRace
var move_score_cache: Dictionary = {}

func _init(
	new_context: AIScoringContext,
	new_reach: AIReach,
	new_se_tenant_scoring: AISeTenantScoring,
	new_effect_scoring: AIEffectScoring,
	new_crown_race: AICrownRace,
) -> void:
	context = new_context
	reach = new_reach
	se_tenant_scoring = new_se_tenant_scoring
	effect_scoring = new_effect_scoring
	crown_race = new_crown_race

func score_move_cached(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var cache_key: String = "move|%s|p%d|%s" % [context.get_state_hash(game_state), player_id, context.get_move_hash(move)]
	if move_score_cache.has(cache_key):
		return float(move_score_cache[cache_key])

	var score: float = score_move(game_state, player_id, move, board_size)
	move_score_cache[cache_key] = score
	return score

func score_affix_setup_fast(game_state: GameStateData, player_id: int, affix_action: Dictionary, board_size: int) -> float:
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(affix_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null:
		return 0.0

	var stamp: Stamp = affix_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = context.get_cached_stamp(str(affix_action.get("stamp_name", "")))
	if stamp == null:
		return 0.0

	var move: Dictionary = {
		"from": piece_pos,
		"to": piece_pos,
		"stamp": stamp,
		"requires_affix": true,
	}
	var score: float = SCORE_AFFIX_STAMP + max(0, stamp.duration) * 2.0
	score += float(stamp.get_directions().size()) * 2.5
	score += AIStampValues.get_stamp_value_above_average(stamp) * STAMP_VALUE_AFFIX_PLAY_WEIGHT
	score += score_bearer_stamp(game_state, player_id, piece, piece_pos, stamp, board_size) * 0.75
	score += score_stamp_effect_fast(game_state, player_id, piece, stamp, piece_pos, piece_pos, null, move, board_size) * 0.65
	score -= score_affix_danger(game_state, player_id, affix_action, board_size, false)
	score -= score_covered_stamp_loss(piece, STAMP_VALUE_AFFIX_PLAY_WEIGHT)
	score += se_tenant_scoring.score_se_tenant_affix(game_state, player_id, affix_action)
	score += se_tenant_scoring.score_se_tenant_grant_affix(game_state, player_id, stamp)
	return score

func score_move_fast(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece == null:
		return -SCORE_WIN

	var stamp: Stamp = AIStateSimulator.get_stamp_for_candidate(game_state.pieces, move)
	var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)
	var score: float = 0.0
	if bool(move.get("requires_affix", false)):
		if stamp != null:
			score += SCORE_AFFIX_STAMP + max(0, stamp.duration) * 2.0
			score += AIStampValues.get_stamp_value_above_average(stamp) * STAMP_VALUE_AFFIX_PLAY_WEIGHT
	else:
		score += SCORE_USE_EXISTING_STAMP

	if captured_piece != null:
		score += effect_scoring.score_capture_at(game_state, captured_piece) * 0.9
		score += effect_scoring.score_capture_respawn_effect(game_state, captured_piece) * 0.9
		score += score_base_staging_capture(game_state, player_id, captured_piece, to_pos, board_size) * 0.9
		score += score_captured_trigger(game_state, player_id, move, captured_piece, board_size) * 0.9
		if MoveRules.is_se_tenant_stamp(captured_piece.affixed_stamp):
			score -= se_tenant_scoring.score_se_tenant_change(game_state, BoardConfig.get_player_id_for_color(captured_piece.color), -1)
	if se_tenant_scoring.is_se_tenant_expiring_move(moving_piece, move):
		score += se_tenant_scoring.score_se_tenant_change(game_state, player_id, -1)

	score += score_repeat_last_move_penalty(game_state, player_id, move)
	# A capture that blows up the capturing golem ends the move there.
	if AIStateSimulator.capture_blows_up_capturer(game_state.pieces, move):
		return score
	score += score_bearer_move(game_state, player_id, move)
	score += score_center_control(to_pos, board_size) * 0.7
	score += score_stamp_effect_fast(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)
	return score

func score_stamp_effect_fast(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary,
	board_size: int
) -> float:
	if stamp == null or !stamp.has_effect():
		return 0.0

	var effect_source_pos: Vector2 = effect_scoring.get_effect_source_pos(stamp, from_pos, to_pos)
	var score: float = 0.0
	var fire_share: float = get_effect_fire_share(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move)
	if fire_share > 0.0:
		match stamp.effect_type:
			StampEffect.TYPE_INVISIBLE_TO_ENEMY:
				score += 32.0
				if moving_piece != null and moving_piece.has_crown:
					score += 80.0
			StampEffect.TYPE_STEAL_STAMP:
				score += 50.0
			StampEffect.TYPE_GRANT_STAMP:
				score += effect_scoring.score_grant_stamp_effect(game_state, player_id, stamp)
			StampEffect.TYPE_GIVE_STAMP:
				score += effect_scoring.score_give_stamp_effect(game_state, player_id, stamp)
			StampEffect.TYPE_MOVE_BASE:
				score += effect_scoring.score_move_base_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
			StampEffect.TYPE_INVALID_SQUARES:
				score += effect_scoring.score_invalid_squares_effect_fast(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
			StampEffect.TYPE_FROZEN_SQUARES:
				score += effect_scoring.score_frozen_squares_effect_fast(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
			StampEffect.TYPE_BOMB:
				score += effect_scoring.score_bomb_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
			StampEffect.TYPE_UNCAPTURABLE:
				score += effect_scoring.score_uncapturable_effect(moving_piece)
			StampEffect.TYPE_INCREASE_OWN_DURATIONS:
				score += effect_scoring.score_duration_adjustment_effect(game_state, player_id, player_id, 1)
			StampEffect.TYPE_INCREASE_ENEMY_DURATIONS:
				score += effect_scoring.score_duration_adjustment_effect(game_state, player_id, 1 - player_id, 1)
			StampEffect.TYPE_DECREASE_OWN_DURATIONS:
				score += effect_scoring.score_duration_adjustment_effect(game_state, player_id, player_id, -1)
			StampEffect.TYPE_DECREASE_ENEMY_DURATIONS:
				score += effect_scoring.score_duration_adjustment_effect(game_state, player_id, 1 - player_id, -1)
			StampEffect.TYPE_INCREASE_SELF_DURATION:
				score += 18.0
			StampEffect.TYPE_GAIN_CROWN_POINT:
				score += effect_scoring.score_crown_point_effect(game_state, player_id, player_id, 1)
			StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT:
				score += effect_scoring.score_crown_point_effect(game_state, player_id, 1 - player_id, -1)
			_:
				pass

		if stamp.effect_trigger == StampEffect.TRIGGER_ON_CAPTURE && captured_piece != null:
			score += 20.0
		if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE:
			score += 8.0
		if stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
			score += 5.0
		score *= fire_share
	if to_pos == from_pos:
		score -= 10.0
	score += score_own_drain_step(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)
	return score

## A plain step with a stamp whose every plain step takes a turn off the own
## stamps (Black Hole). Each -1 looks cheap at the far end of a stamp
## (AIEffectScoring.get_duration_step_value), but such steps empty the own board and codex, so
## this stamp should capture rather than walk. A golem without the crown walks it
## only with no other stamped golem to drain, or out of an attack with fewer than
## OWN_DRAIN_SACRIFICE_STAMPS of them: with more the stamp is better lost. The
## exception is a crown it carries in: the step reaches the base or leaves it one
## more step away. Under attack a crowned golem should not walk away either with
## that many to drain, or if its crown can move to a safe golem. Being a score,
## none of this stops a step when nothing else can move.
func score_own_drain_step(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary,
	board_size: int
) -> float:
	if captured_piece != null or from_pos == to_pos or bool(move.get("requires_affix", false)):
		return 0.0
	if stamp.effect_type != StampEffect.TYPE_DECREASE_OWN_DURATIONS or stamp.effect_trigger != StampEffect.TRIGGER_ON_MOVE:
		return 0.0
	var crowned: bool = moving_piece != null and moving_piece.has_crown
	if crowned:
		if to_pos == StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id):
			return 0.0
		if int(reach.get_base_route(game_state, player_id, stamp, to_pos, board_size).y) == 1:
			return 0.0

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var drained: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece != moving_piece and piece.color == player_color and piece.affixed_stamp != null and piece.turns_remaining > 0:
			drained += 1
	var penalty: float = PENALTY_OWN_DRAIN_STEP + float(drained) * PENALTY_OWN_DRAIN_STAMP
	var sacrifice: bool = drained >= OWN_DRAIN_SACRIFICE_STAMPS
	if !crowned:
		if drained > 0 and (sacrifice or !reach.is_square_attacked_by(game_state, 1 - player_id, from_pos, board_size)):
			penalty += PENALTY_OWN_DRAIN_WALK
	elif reach.is_square_attacked_by(game_state, 1 - player_id, from_pos, board_size):
		if sacrifice or crown_race.can_crown_move_to_safety(game_state, player_id, board_size):
			penalty += PENALTY_OWN_DRAIN_FLIGHT
	return -penalty

## Any own golem but the bearer on the enemy base only stands in the bearer's
## way: nothing steps onto a square its own side holds.
func score_non_bearer_base_entry_penalty(game_state: GameStateData, player_id: int, move: Dictionary) -> float:
	if game_state == null or move.is_empty():
		return 0.0

	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	if to_pos != opponent_base:
		return 0.0
	if AIStateSimulator.is_own_crown_candidate(game_state.pieces, move, player_id):
		return 0.0
	if crown_race.player_has_crown_plan(game_state, player_id):
		return -PENALTY_NON_BEARER_BASE_ENTRY
	return -PENALTY_NON_BEARER_BASE_ENTRY * 0.35

## A move by the player's crowned golem: the win when it steps onto the enemy
## base, otherwise its progress toward it.
func score_bearer_move(game_state: GameStateData, player_id: int, move: Dictionary) -> float:
	if !AIStateSimulator.is_own_crown_candidate(game_state.pieces, move, player_id):
		return score_non_bearer_base_entry_penalty(game_state, player_id, move)

	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	if to_pos == StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id):
		return SCORE_WIN
	return score_crown_base_progress(game_state, player_id, from_pos, to_pos)

func score_repeat_last_move_penalty(game_state: GameStateData, player_id: int, move: Dictionary) -> float:
	if game_state == null or game_state.last_move.is_empty() or move.is_empty():
		return 0.0
	if int(game_state.last_move.get("player_id", -1)) != player_id:
		return 0.0

	var last_from: Vector2 = StampEffectResolver.as_vector2(game_state.last_move.get("from", Vector2(-1, -1)), Vector2(-1, -1))
	var last_to: Vector2 = StampEffectResolver.as_vector2(game_state.last_move.get("to", Vector2(-1, -1)), Vector2(-1, -1))
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	if from_pos == last_to and to_pos == last_from:
		return -PENALTY_REPEAT_LAST_MOVE
	return 0.0

func score_affix_setup(game_state: GameStateData, player_id: int, affix_action: Dictionary, board_size: int) -> float:
	return score_affix_setup_with_stamp_value_weight(game_state, player_id, affix_action, board_size, STAMP_VALUE_AFFIX_PLAY_WEIGHT)

func score_affix_setup_for_exchange(game_state: GameStateData, player_id: int, affix_action: Dictionary, board_size: int) -> float:
	return score_affix_setup_with_stamp_value_weight(game_state, player_id, affix_action, board_size, STAMP_VALUE_AFFIX_EXCHANGE_WEIGHT)

func score_affix_setup_with_stamp_value_weight(
	game_state: GameStateData,
	player_id: int,
	affix_action: Dictionary,
	board_size: int,
	stamp_value_weight: float
) -> float:
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(affix_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null:
		return 0.0

	var stamp: Stamp = affix_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = context.get_cached_stamp(str(affix_action.get("stamp_name", "")))
	if stamp == null:
		return 0.0

	var score: float = SCORE_AFFIX_STAMP
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var setup_moves: Array[Vector2] = MoveRules.get_stamp_moves_for_piece(
		game_state.pieces,
		piece_pos,
		player_color,
		stamp,
		board_size,
		game_state.board_effects
	)
	score += float(setup_moves.size()) * SCORE_AFFIX_SETUP_MOBILITY
	if setup_moves.is_empty():
		score -= PENALTY_AFFIX_SETUP_NO_MOVE
	score += AIStampValues.get_stamp_value_above_average(stamp) * stamp_value_weight
	score += score_bearer_stamp(game_state, player_id, piece, piece_pos, stamp, board_size)

	var setup_move: Dictionary = {
		"from": piece_pos,
		"to": piece_pos,
		"stamp": stamp,
		"requires_affix": true,
	}
	score += score_stamp_effect(game_state, player_id, piece, stamp, piece_pos, piece_pos, null, setup_move, board_size) * 0.65
	score -= score_affix_danger(game_state, player_id, affix_action, board_size, true)
	score -= score_covered_stamp_loss(piece, stamp_value_weight)
	score += se_tenant_scoring.score_se_tenant_grant_affix(game_state, player_id, stamp)
	return score

## What an Overseal throws away when it goes onto a golem that already has a
## stamp: the turns the covered stamp had left and, unless it is a Seeker that
## goes back to the codex, the stamp itself, at what it is still worth. Weighed
## like the new stamp's own value, so a nearly spent stamp costs little to
## cover, though never less than an empty golem.
func score_covered_stamp_loss(piece: Piece, stamp_value_weight: float) -> float:
	if piece == null or piece.affixed_stamp == null:
		return 0.0
	var loss: float = float(maxi(0, piece.turns_remaining)) * 2.0
	if !MoveRules.is_seeker_stamp(piece.affixed_stamp):
		var value_above_average: float = (AIStampValues.get_stamp_remaining_value(piece.affixed_stamp, piece.turns_remaining) - AIStampValues.stamp_value_fresh_mean) * STAMP_ESTIMATE_POINT_SCORE
		loss += SCORE_AFFIX_STAMP + value_above_average * stamp_value_weight
	return maxf(0.0, loss)

func score_move(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var score: float = 0.0
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece == null:
		return -SCORE_WIN

	var stamp: Stamp = AIStateSimulator.get_stamp_for_candidate(game_state.pieces, move)
	var captured_piece: Piece = AIStateSimulator.get_captured_piece(game_state.pieces, move)

	if bool(move.get("requires_affix", false)):
		score += score_affixed_stamp(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)
	else:
		score += SCORE_USE_EXISTING_STAMP
		# The crown race sees a crown point move in the plan's simulated state.
		if stamp != null and !effect_scoring.is_crown_point_effect(stamp):
			score += score_stamp_effect(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)

	if captured_piece != null:
		score += effect_scoring.score_capture_at(game_state, captured_piece)
		score += effect_scoring.score_capture_respawn_effect(game_state, captured_piece)
		score += score_base_staging_capture(game_state, player_id, captured_piece, to_pos, board_size)
		score += score_captured_trigger(game_state, player_id, move, captured_piece, board_size)

	score += score_repeat_last_move_penalty(game_state, player_id, move)
	# A capture that blows up the capturing golem ends the move there.
	if AIStateSimulator.capture_blows_up_capturer(game_state.pieces, move):
		return score
	score += score_bearer_move(game_state, player_id, move)
	score += score_center_control(to_pos, board_size)
	score += score_crown_threat(game_state, player_id, move, board_size)
	score -= score_danger_after_move(game_state, player_id, move, board_size)
	return score

func score_affixed_stamp(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary,
	board_size: int
) -> float:
	if stamp == null:
		return 0.0

	var score: float = SCORE_AFFIX_STAMP
	score += max(0, stamp.duration) * 3.0
	score += AIStampValues.get_stamp_value_above_average(stamp) * STAMP_VALUE_AFFIX_PLAY_WEIGHT
	score += score_stamp_effect(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)
	return score

func score_crown_base_progress(game_state: GameStateData, player_id: int, from_pos: Vector2, to_pos: Vector2) -> float:
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	return (AIBoardMath.get_manhattan_distance(from_pos, opponent_base) - AIBoardMath.get_manhattan_distance(to_pos, opponent_base)) * SCORE_CROWN_BASE_PROGRESS

## A stamp on the player's own crowned golem: worth most when it puts the base
## one step away, and a fair amount when it lasts the whole way there.
func score_bearer_stamp(game_state: GameStateData, player_id: int, piece: Piece, piece_pos: Vector2, stamp: Stamp, board_size: int) -> float:
	if game_state == null or stamp == null or !AIStateSimulator.is_crown_carrier_of(piece, player_id):
		return 0.0

	var route: Vector2 = reach.get_base_route(game_state, player_id, stamp, piece_pos, board_size)
	if route.y < 0.0:
		return 0.0
	var steps: int = int(route.y)
	if steps == 1:
		return SCORE_CROWN_BASE_ENTRY_THREAT
	if reach.stamp_outlasts_route(stamp, stamp.duration, steps):
		# Counts for as much as the route can be relied on.
		return (SCORE_CROWN_STAMP_IN_ROUTE + float(maxi(0, stamp.duration - steps)) * 32.0) * route.y / route.x
	return 0.0

## Taking an enemy golem the enemy could crown on their coming turn and walk
## onto the own base on the turn after: one whose stamp reaches the base, or a
## bare one a stamp from their open codex page would put a step away.
func score_base_staging_capture(game_state: GameStateData, player_id: int, captured_piece: Piece, captured_pos: Vector2, board_size: int) -> float:
	if game_state == null or captured_piece == null:
		return 0.0

	var opponent_player_id: int = 1 - player_id
	if BoardConfig.get_player_id_for_color(captured_piece.color) != opponent_player_id:
		return 0.0
	if !AICrownRace.can_crown_next_turn(game_state, opponent_player_id):
		return 0.0
	var route_turns: float = reach.get_golem_route_turns(game_state, opponent_player_id, captured_pos, board_size)
	if route_turns == 1.0 or captured_piece.affixed_stamp == null and route_turns == 2.0:
		return SCORE_CAPTURE_BASE_STAGING_PIECE
	return 0.0

func score_center_control(pos: Vector2, board_size: int) -> float:
	var center: Vector2 = Vector2(float(board_size - 1) / 2.0, float(board_size - 1) / 2.0)
	var distance: float = abs(pos.x - center.x) + abs(pos.y - center.y)
	return max(0.0, float(board_size) - distance) * SCORE_CENTER

func score_crown_threat(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int) -> float:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var moved_to: Vector2 = AIStateSimulator.get_move_to(move)
	var enemy_bearer_pos: Vector2 = AIStateSimulator.find_crowned_position(simulated_pieces, 1 - player_id)
	if enemy_bearer_pos == INVALID_POS:
		return 0.0

	var next_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		simulated_pieces,
		moved_to,
		player_id,
		board_size,
		game_state.board_effects
	)
	if next_moves.has(enemy_bearer_pos):
		return SCORE_THREATEN_CROWN
	return 0.0

func score_danger_after_move(game_state: GameStateData, player_id: int, move: Dictionary, board_size: int) -> float:
	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_player_id: int = 1 - player_id
	var opponent_hand_stamps: Array[Stamp] = AIStateSimulator.get_hand_stamps_from_state(game_state, opponent_player_id)
	var is_threatened: bool = AIStateSimulator.is_square_threatened(
		simulated_pieces,
		to_pos,
		opponent_player_id,
		opponent_hand_stamps,
		game_state.board_effects,
		board_size
	)
	if !is_threatened:
		return 0.0

	var threatened_piece: Piece = simulated_pieces.get(to_pos, null) as Piece
	return score_threatened_piece_loss(threatened_piece, game_state)

func score_affix_danger(
	game_state: GameStateData,
	player_id: int,
	affix_action: Dictionary,
	board_size: int,
	simulate_effects: bool
) -> float:
	if game_state == null:
		return 0.0

	var piece_pos: Vector2 = StampEffectResolver.as_vector2(affix_action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var stamp: Stamp = affix_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = StampLibrary.get_stamp(str(affix_action.get("stamp_name", "")))
	if stamp == null:
		return 0.0

	var simulated_state: GameStateData = null
	var simulated_pieces: Dictionary = {}
	var simulated_board_effects: Array = []
	var affixed_piece: Piece = null
	if simulate_effects:
		simulated_state = AIStateSimulator.clone_game_state(game_state)
		AIStateSimulator.apply_affix_action(simulated_state, player_id, affix_action, board_size)
		if simulated_state.game_over:
			if simulated_state.winner_player == player_id:
				return 0.0
			return SCORE_WIN
		simulated_pieces = simulated_state.pieces
		simulated_board_effects = simulated_state.board_effects
		affixed_piece = simulated_state.get_piece(piece_pos)
	else:
		simulated_pieces = AIStateSimulator.clone_pieces(game_state.pieces)
		simulated_board_effects = game_state.board_effects
		affixed_piece = simulated_pieces.get(piece_pos, null) as Piece
		if affixed_piece != null:
			affixed_piece.affixed_stamp = stamp
			affixed_piece.turns_remaining = stamp.duration
			affixed_piece.exhausted_this_turn = true

	if affixed_piece == null or affixed_piece.affixed_stamp == null:
		return 0.0

	var opponent_player_id: int = 1 - player_id
	var threat_state: GameStateData = game_state
	if simulated_state != null:
		threat_state = simulated_state
	var opponent_hand_stamps: Array[Stamp] = AIStateSimulator.get_hand_stamps_from_state(threat_state, opponent_player_id)
	if !AIStateSimulator.is_square_threatened(
		simulated_pieces,
		piece_pos,
		opponent_player_id,
		opponent_hand_stamps,
		simulated_board_effects,
		board_size
	):
		return 0.0

	return score_threatened_piece_loss(affixed_piece, threat_state)

func score_threatened_piece_loss(piece: Piece, game_state: GameStateData = null) -> float:
	if piece == null:
		return 0.0
	if piece.has_crown:
		return PENALTY_CROWN_THREATENED
	var loss: float = effect_scoring.score_capture_at(game_state, piece) + effect_scoring.score_capture_respawn_effect(game_state, piece)
	if game_state != null and MoveRules.is_se_tenant_stamp(piece.affixed_stamp):
		loss -= se_tenant_scoring.score_se_tenant_change(game_state, BoardConfig.get_player_id_for_color(piece.color), -1)
	loss -= effect_scoring.score_on_captured_deterrent(game_state, piece)
	return maxf(PENALTY_PIECE_THREATENED, loss)

## What the captured stamp's on_captured effect does to the capturing player.
## It goes off with the capturing golem on the captured golem's square (see
## NetworkGameHost.handle_move_piece), so a bomb there takes that golem too.
func score_captured_trigger(game_state: GameStateData, player_id: int, move: Dictionary, captured_piece: Piece, board_size: int) -> float:
	var stamp: Stamp = captured_piece.affixed_stamp if captured_piece != null else null
	if stamp == null or !stamp.has_effect() or stamp.effect_trigger != StampEffect.TRIGGER_ON_CAPTURED:
		return 0.0
	if stamp.effect_type != StampEffect.TYPE_BOMB:
		var owner_value: float = effect_scoring.score_on_captured_effect_for_owner(game_state, captured_piece)
		return owner_value if BoardConfig.get_player_id_for_color(captured_piece.color) == player_id else -owner_value

	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var score: float = 0.0
	for square: Vector2 in StampEffectResolver.get_effect_squares(stamp, to_pos, board_size, captured_piece.color):
		var target_piece: Piece = null
		if square == to_pos:
			target_piece = game_state.get_piece(from_pos)
		elif square != from_pos:
			target_piece = game_state.get_piece(square)
		if target_piece == null:
			continue
		var target_loss: float = effect_scoring.score_capture_at(game_state, target_piece) + effect_scoring.score_capture_respawn_effect(game_state, target_piece)
		if BoardConfig.get_player_id_for_color(target_piece.color) == player_id:
			score -= target_loss
		else:
			score += target_loss
	return score

func score_stamp_effect(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary,
	board_size: int
) -> float:
	if stamp == null or !stamp.has_effect():
		return 0.0

	var score: float = 0.0
	var effect_source_pos: Vector2 = effect_scoring.get_effect_source_pos(stamp, from_pos, to_pos)
	var fire_share: float = get_effect_fire_share(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move)
	if fire_share > 0.0:
		score += effect_scoring.score_effect_value(game_state, player_id, moving_piece, stamp, effect_source_pos, move, board_size)

		if stamp.effect_trigger == StampEffect.TRIGGER_ON_CAPTURE && captured_piece != null:
			score += 20.0
		if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE:
			score += 8.0
		if stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
			score += 5.0
		score *= fire_share
	if to_pos == from_pos:
		score -= 10.0
	score += score_own_drain_step(game_state, player_id, moving_piece, stamp, from_pos, to_pos, captured_piece, move, board_size)

	return score

## Of an effect's value, the share a move or affix brings. An effect put on now
## counts in full, except an on_capture one that does not go off right away: it
## counts for the captures the golem can expect before the stamp runs out. On a
## golem that only moves, an effect counts when it goes off: on a step that
## takes nothing, on a capture, or when this step runs the stamp out.
func get_effect_fire_share(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	from_pos: Vector2,
	to_pos: Vector2,
	captured_piece: Piece,
	move: Dictionary
) -> float:
	if bool(move.get("requires_affix", false)):
		if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE and captured_piece != null:
			return 0.0
		if stamp.effect_trigger != StampEffect.TRIGGER_ON_CAPTURE or captured_piece != null:
			return 1.0
		# An affix with no step keeps every step for later.
		var steps_left: int = stamp.duration if from_pos == to_pos else stamp.duration - 1
		return reach.get_expected_captures(game_state, player_id, stamp, to_pos, steps_left)
	match stamp.effect_trigger:
		StampEffect.TRIGGER_ON_MOVE:
			return 1.0 if captured_piece == null else 0.0
		StampEffect.TRIGGER_ON_CAPTURE:
			return 1.0 if captured_piece != null else 0.0
		StampEffect.TRIGGER_ON_EXPIRE:
			return 1.0 if moving_piece != null and moving_piece.turns_remaining == 1 else 0.0
	return 0.0
