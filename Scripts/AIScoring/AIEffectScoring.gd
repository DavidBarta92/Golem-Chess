extends RefCounted
class_name AIEffectScoring

## What a stamp's effect is worth when it goes off, to the player scoring it,
## and what a golem is worth to lose. The two are one module because they call
## each other: a captured golem takes its stamp's coming on_expire effect with it,
## and a bomb captures. How much of an effect a move or affix brings is
## AIMoveScoring's.

const SCORE_CAPTURE_PIECE: float = 45.0
## The flat part of a captured stamp's value; the rest is the part of its
## estimate still ahead of it (score_stamp_material).
const SCORE_CAPTURE_STAMP: float = 10.0
## A stamp glued into a codex by an effect, or taken from one, on top of how
## much better it is than the average stamp (score_grant_stamp_effect,
## score_give_stamp_effect).
const SCORE_CODEX_STAMP: float = 45.0
const SCORE_INVALID_MOVE_REDUCTION: float = 8.0
const PENALTY_OWN_MOVE_REDUCTION: float = 5.0
const SCORE_FROZEN_ENEMY_PIECE: float = 34.0
const SCORE_MOVE_BASE_MIN_DISTANCE: float = 24.0
const SCORE_MOVE_BASE_AVG_DISTANCE: float = 8.0
const PENALTY_MOVE_BASE_NOOP: float = 20.0
## A captured Seeker goes back to its owner's codex: only this share is lost.
const SEEKER_CAPTURE_VALUE_SHARE: float = 0.5
## A step added to (or taken from) the end of a stamp only counts if its golem
## makes every step before it; this is the chance it makes each next one
## (get_duration_step_value).
const DURATION_STEP_REACH_CHANCE: float = 0.6
## A stamp on its last step that a +1 keeps (or a -1 ends at once): its golem
## does not stand bare, waiting a turn for a new stamp. On the crowned golem
## that turn is one of the crown race.
const SCORE_DURATION_SAVES_EXPIRY: float = 15.0
const SCORE_DURATION_CROWN_BEARER: float = 110.0
const SCORE_CAPTURE_LOCKS_GOLEM: float = 30.0
const SCORE_CAPTURE_REMOVES_GOLEM: float = 18.0
const SCORE_CAPTURE_GOLEM_SCARCITY: float = 14.0
const LOW_USABLE_GOLEM_COUNT: int = 4
const SCORE_CAPTURE_CROWN: float = 420.0
const INVALID_POS: Vector2 = AIScoringContext.INVALID_POS
const SCORE_CROWN_POINT: float = AIReach.SCORE_CROWN_POINT
const SCORE_SE_TENANT_GRANT: float = AISeTenantScoring.SCORE_SE_TENANT_GRANT
const STAMP_ESTIMATE_POINT_SCORE: float = AIStampValues.STAMP_ESTIMATE_POINT_SCORE
const STAMP_VALUE_AFFIX_PLAY_WEIGHT: float = AIStampValues.STAMP_VALUE_AFFIX_PLAY_WEIGHT

var context: AIScoringContext
var se_tenant_scoring: AISeTenantScoring
## Set while an on_expire effect is scored, so an expiry it sets off in turn is
## not followed (see score_expiry_effect_for_owner).
var scoring_expiry_effect: bool = false

func _init(new_context: AIScoringContext, new_se_tenant_scoring: AISeTenantScoring) -> void:
	context = new_context
	se_tenant_scoring = new_se_tenant_scoring

func score_invalid_squares_effect_fast(game_state: GameStateData, player_id: int, moving_piece: Piece, stamp: Stamp, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var effect_color: int = moving_piece.color
	var target_squares: Array[Vector2] = StampEffectResolver.get_effect_squares(stamp, source_pos, board_size, effect_color)
	target_squares = StampEffectResolver.filter_out_base_fields(game_state, target_squares)
	if target_squares.is_empty():
		return 0.0

	var opponent_positions: Array[Vector2] = AIBoardMath.get_piece_positions_for_player(game_state.pieces, 1 - player_id)
	var own_positions: Array[Vector2] = AIBoardMath.get_piece_positions_for_player(game_state.pieces, player_id)
	var score: float = float(target_squares.size()) * 2.0
	for target_square: Vector2 in target_squares:
		for opponent_pos: Vector2 in opponent_positions:
			var opponent_distance: float = AIBoardMath.get_manhattan_distance(target_square, opponent_pos)
			if opponent_distance <= 1.0:
				score += 10.0
			elif opponent_distance <= 2.0:
				score += 4.0
		for own_pos: Vector2 in own_positions:
			var own_distance: float = AIBoardMath.get_manhattan_distance(target_square, own_pos)
			if own_distance <= 1.0:
				score -= 6.0
	return score

func score_frozen_squares_effect_fast(game_state: GameStateData, player_id: int, moving_piece: Piece, stamp: Stamp, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var effect_color: int = moving_piece.color
	var target_squares: Array[Vector2] = StampEffectResolver.get_effect_squares(stamp, source_pos, board_size, effect_color)
	var score: float = 0.0
	for target_pos: Vector2 in target_squares:
		var target_piece: Piece = game_state.get_piece(target_pos)
		if target_piece == null:
			continue

		var target_player_id: int = BoardConfig.get_player_id_for_color(target_piece.color)
		if !stamp_effect_targets_player(stamp, target_player_id):
			continue

		var piece_score: float = get_piece_target_score(target_piece) * 0.75 + SCORE_FROZEN_ENEMY_PIECE
		if target_player_id == player_id:
			score -= piece_score
		else:
			score += piece_score
	return score

## A grant glues new copies of a stamp into the target's codex, as many as fit
## in its free slots. A Se-tenant the player's set can use counts
## SCORE_SE_TENANT_GRANT more, by how near the open page it lands.
func score_grant_stamp_effect(game_state: GameStateData, player_id: int, stamp: Stamp) -> float:
	if game_state == null or stamp == null:
		return 0.0

	var granted_stamp: Stamp = context.get_cached_stamp(str(stamp.effect_settings.get("stamp_name", stamp.stamp_name)))
	if granted_stamp == null:
		return 0.0

	var target_player_id: int = int(stamp.effect_settings.get("target_player_id", player_id))
	var amount: int = max(1, int(stamp.effect_settings.get("amount", 1)))
	var granted_count: int = amount
	if game_state.has_codex_for_player(target_player_id):
		granted_count = mini(amount, game_state.count_free_codex_slots(target_player_id))
	var stamp_worth: float = SCORE_CODEX_STAMP + AIStampValues.get_stamp_value_above_average(granted_stamp) * STAMP_VALUE_AFFIX_PLAY_WEIGHT
	if target_player_id == player_id and MoveRules.is_se_tenant_stamp(granted_stamp) and se_tenant_scoring.can_complete_se_tenant_set(game_state, player_id):
		stamp_worth += SCORE_SE_TENANT_GRANT * se_tenant_scoring.get_codex_landing_weight(game_state, player_id, true)
	var score: float = stamp_worth * granted_count
	return score if target_player_id == player_id else -score

## A give takes stamps at random from the player's open page - each lost to
## them at what a granted one is worth - and puts them on the target's open
## page while it has room, where the opponent gains them.
func score_give_stamp_effect(game_state: GameStateData, player_id: int, stamp: Stamp) -> float:
	if game_state == null or stamp == null:
		return 0.0
	var hand: Array = game_state.player_hands.get(player_id, [])
	if hand.is_empty():
		return 0.0

	var target_player_id: int = int(stamp.effect_settings.get("target_player_id", 1 - player_id))
	var given_count: int = mini(max(1, int(stamp.effect_settings.get("amount", 1))), hand.size())
	var max_hand_size: int = max(1, int(stamp.effect_settings.get("max_hand_size", StampEffectResolver.DEFAULT_MAX_HAND_SIZE)))
	var value_above_average: float = 0.0
	for stamp_name_value in hand:
		value_above_average += AIStampValues.get_stamp_value_above_average(context.get_cached_stamp(str(stamp_name_value)))
	var stamp_worth: float = SCORE_CODEX_STAMP + value_above_average / float(hand.size()) * STAMP_VALUE_AFFIX_PLAY_WEIGHT
	var score: float = -stamp_worth * float(given_count)
	if target_player_id != player_id:
		var target_room: int = maxi(0, max_hand_size - (game_state.player_hands.get(target_player_id, []) as Array).size())
		score -= stamp_worth * float(mini(given_count, target_room))
	return score

func score_capture(captured_piece: Piece) -> float:
	if captured_piece == null:
		return 0.0

	var score: float = SCORE_CAPTURE_PIECE + score_stamp_material(captured_piece)
	if captured_piece.has_crown:
		score += SCORE_CAPTURE_CROWN
	return score

## score_capture on the board: the on_expire effect the golem's stamp has still
## to set off goes with it (score_expiry_at_stake), though the stamp never
## counts below nothing.
func score_capture_at(game_state: GameStateData, captured_piece: Piece) -> float:
	return score_capture(captured_piece) + maxf(score_expiry_at_stake(game_state, captured_piece), -score_stamp_material(captured_piece))

## The on_expire effect a golem's stamp has still to set off, for its owner: what
## taking the golem spares them (a Ballista giving a stamp away) or costs them
## (a Nova's blast). A harmful one counts in full - the owner either pays it or
## leaves the stamp's last step unused - a helpful one only if the golem makes
## every step to it (DURATION_STEP_REACH_CHANCE each).
func score_expiry_at_stake(game_state: GameStateData, piece: Piece) -> float:
	if game_state == null or piece == null or piece.affixed_stamp == null or piece.turns_remaining <= 0:
		return 0.0
	var value: float = score_expiry_effect_for_owner(game_state, piece, piece.position, BoardConfig.BOARD_SIZE)
	if value <= 0.0:
		return value
	return value * pow(DURATION_STEP_REACH_CHANCE, piece.turns_remaining - 1)

## What the stamp on a golem is worth to its owner: a flat part plus the part
## of its estimate still ahead of it. A Seeker goes back to its owner's codex
## when taken, so only part of it is lost.
func score_stamp_material(piece: Piece) -> float:
	if piece == null or piece.affixed_stamp == null:
		return 0.0
	var value: float = AIStampValues.get_stamp_remaining_value(piece.affixed_stamp, piece.turns_remaining) * STAMP_ESTIMATE_POINT_SCORE
	if MoveRules.is_seeker_stamp(piece.affixed_stamp):
		value *= SEEKER_CAPTURE_VALUE_SHARE
	return SCORE_CAPTURE_STAMP + value

## What the capture does to the victim's golems beyond the lost stamp. A
## captured golem respawns locked, unless its owner already has a locked one:
## then that one is freed and the captured golem leaves the board for good. So
## every first capture costs the victim a usable golem, every second one only
## thins the board out. The fewer usable golems the victim has left, the more a
## lock hurts: fewer pieces to stamp, and closer to having no legal action.
func score_capture_respawn_effect(game_state: GameStateData, captured_piece: Piece) -> float:
	if game_state == null or captured_piece == null:
		return 0.0
	# A locked golem just respawns locked again somewhere on its home row.
	if captured_piece.is_respawn_locked():
		return 0.0

	var victim_player_id: int = BoardConfig.get_player_id_for_color(captured_piece.color)
	if player_has_respawn_locked_golem(game_state, victim_player_id):
		return SCORE_CAPTURE_REMOVES_GOLEM

	var usable_after: int = count_usable_golems(game_state, victim_player_id) - 1
	return SCORE_CAPTURE_LOCKS_GOLEM + float(maxi(0, LOW_USABLE_GOLEM_COUNT - usable_after)) * SCORE_CAPTURE_GOLEM_SCARCITY

func player_has_respawn_locked_golem(game_state: GameStateData, player_id: int) -> bool:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color and piece.is_respawn_locked():
			return true
	for pending_piece_value in game_state.pending_respawns.get(player_id, []):
		var pending_piece: Piece = pending_piece_value as Piece
		if pending_piece != null and pending_piece.is_respawn_locked():
			return true
	return false

func count_usable_golems(game_state: GameStateData, player_id: int) -> int:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null and piece.color == player_color and !piece.is_respawn_locked():
			count += 1
	return count

## What a golem's on_captured effect is worth to its owner when it goes off.
## A bomb is left out: what it takes depends on the capturing golem.
func score_on_captured_effect_for_owner(game_state: GameStateData, piece: Piece) -> float:
	var stamp: Stamp = piece.affixed_stamp if piece != null else null
	if game_state == null or stamp == null or !stamp.has_effect() or stamp.effect_trigger != StampEffect.TRIGGER_ON_CAPTURED:
		return 0.0
	var owner_id: int = BoardConfig.get_player_id_for_color(piece.color)
	match stamp.effect_type:
		StampEffect.TYPE_INCREASE_OWN_DURATIONS:
			return score_duration_adjustment_effect(game_state, owner_id, owner_id, 1, piece)
		StampEffect.TYPE_INCREASE_ENEMY_DURATIONS:
			return score_duration_adjustment_effect(game_state, owner_id, 1 - owner_id, 1, piece)
		StampEffect.TYPE_DECREASE_OWN_DURATIONS:
			return score_duration_adjustment_effect(game_state, owner_id, owner_id, -1, piece)
		StampEffect.TYPE_DECREASE_ENEMY_DURATIONS:
			return score_duration_adjustment_effect(game_state, owner_id, 1 - owner_id, -1, piece)
		StampEffect.TYPE_GAIN_CROWN_POINT:
			return score_crown_point_effect(game_state, owner_id, owner_id, 1)
		StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT:
			return score_crown_point_effect(game_state, owner_id, 1 - owner_id, -1)
	return 0.0

## How much of a threatened golem's loss its on_captured effect pays back: a
## bomb on its own square takes the capturing golem (a stamped one, as it has
## to move), any other effect works for the owner.
func score_on_captured_deterrent(game_state: GameStateData, piece: Piece) -> float:
	var stamp: Stamp = piece.affixed_stamp if piece != null else null
	if !AIStateSimulator.is_on_captured_bomb(stamp):
		return score_on_captured_effect_for_owner(game_state, piece)
	if stamp.get_effect_offsets().has(Vector2.ZERO):
		# The capturer is not known yet: an average fresh stamp.
		return SCORE_CAPTURE_PIECE + SCORE_CAPTURE_STAMP + AIStampValues.stamp_value_fresh_mean * STAMP_ESTIMATE_POINT_SCORE
	return 0.0

## What the stamp's effect does for the player when it goes off here, before
## the share of it the move or affix brings (see AIMoveScoring.score_stamp_effect).
func score_effect_value(
	game_state: GameStateData,
	player_id: int,
	moving_piece: Piece,
	stamp: Stamp,
	effect_source_pos: Vector2,
	move: Dictionary,
	board_size: int
) -> float:
	var score: float = 0.0
	match stamp.effect_type:
		StampEffect.TYPE_INVISIBLE_TO_ENEMY:
			score += 32.0
			if moving_piece != null and moving_piece.has_crown:
				score += 80.0
		StampEffect.TYPE_STEAL_STAMP:
			score += 50.0
		StampEffect.TYPE_GRANT_STAMP:
			score += score_grant_stamp_effect(game_state, player_id, stamp)
		StampEffect.TYPE_GIVE_STAMP:
			score += score_give_stamp_effect(game_state, player_id, stamp)
		StampEffect.TYPE_MOVE_BASE:
			score += score_move_base_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_INVALID_SQUARES:
			score += score_invalid_squares_effect(game_state, player_id, stamp, move, effect_source_pos, board_size)
		StampEffect.TYPE_FROZEN_SQUARES:
			score += score_frozen_squares_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_BOMB:
			score += score_bomb_effect(game_state, player_id, moving_piece, stamp, effect_source_pos, board_size)
		StampEffect.TYPE_UNCAPTURABLE:
			score += score_uncapturable_effect(moving_piece)
		StampEffect.TYPE_INCREASE_OWN_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, player_id, 1)
		StampEffect.TYPE_INCREASE_ENEMY_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, 1 - player_id, 1)
		StampEffect.TYPE_DECREASE_OWN_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, player_id, -1)
		StampEffect.TYPE_DECREASE_ENEMY_DURATIONS:
			score += score_duration_adjustment_effect(game_state, player_id, 1 - player_id, -1)
		StampEffect.TYPE_INCREASE_SELF_DURATION:
			score += 18.0
		StampEffect.TYPE_GAIN_CROWN_POINT:
			score += score_crown_point_effect(game_state, player_id, player_id, 1)
		StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT:
			score += score_crown_point_effect(game_state, player_id, 1 - player_id, -1)
		_:
			pass
	return score

## What a golem's on_expire effect does for its owner when its stamp runs out
## on its square. An expiry it sets off in turn is not followed.
func score_expiry_effect_for_owner(game_state: GameStateData, piece: Piece, piece_pos: Vector2, board_size: int) -> float:
	var stamp: Stamp = piece.affixed_stamp
	if scoring_expiry_effect or stamp == null or !stamp.has_effect() or stamp.effect_trigger != StampEffect.TRIGGER_ON_EXPIRE:
		return 0.0
	scoring_expiry_effect = true
	var expiry_move: Dictionary = {"from": piece_pos, "to": piece_pos, "stamp": stamp, "requires_affix": false}
	var owner_id: int = BoardConfig.get_player_id_for_color(piece.color)
	var value: float = score_effect_value(game_state, owner_id, piece, stamp, piece_pos, expiry_move, board_size)
	scoring_expiry_effect = false
	return value

## Every golem in the blast, the player's own against them, at what losing it
## costs. The golem that sets it off by a move still stands on the square it
## left in the state scored, so it counts only where the blast is centred.
func score_bomb_effect(game_state: GameStateData, player_id: int, moving_piece: Piece, stamp: Stamp, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var score: float = 0.0
	var effect_color: int = moving_piece.color
	for offset: Vector2 in stamp.get_effect_offsets():
		var target_pos: Vector2 = source_pos + (offset * effect_color)
		if !MoveRules.is_valid_position(target_pos, board_size):
			continue

		var target_piece: Piece = game_state.get_piece(target_pos)
		if target_piece == null or (target_piece == moving_piece and target_pos != source_pos):
			continue

		var target_player_id: int = BoardConfig.get_player_id_for_color(target_piece.color)
		var target_score: float = score_capture_at(game_state, target_piece) + score_capture_respawn_effect(game_state, target_piece)
		if target_player_id == player_id:
			score -= target_score
		else:
			score += target_score

	return score

func score_frozen_squares_effect(game_state: GameStateData, player_id: int, moving_piece: Piece, stamp: Stamp, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var score: float = 0.0
	var effect_color: int = moving_piece.color
	var target_squares: Array[Vector2] = StampEffectResolver.get_effect_squares(stamp, source_pos, board_size, effect_color)
	for target_pos: Vector2 in target_squares:
		var target_piece: Piece = game_state.get_piece(target_pos)
		if target_piece == null:
			continue

		var target_player_id: int = BoardConfig.get_player_id_for_color(target_piece.color)
		if !stamp_effect_targets_player(stamp, target_player_id):
			continue

		var piece_score: float = get_frozen_piece_score(game_state, target_piece, target_pos, target_player_id, board_size)
		if target_player_id == player_id:
			score -= piece_score
		else:
			score += piece_score

	return score

func score_invalid_squares_effect(game_state: GameStateData, player_id: int, stamp: Stamp, move: Dictionary, source_pos: Vector2, board_size: int) -> float:
	var moving_piece: Piece = game_state.get_piece(AIStateSimulator.get_move_from(move))
	if moving_piece == null:
		return 0.0

	var effect_color: int = moving_piece.color
	var target_squares: Array[Vector2] = StampEffectResolver.get_effect_squares(stamp, source_pos, board_size, effect_color)
	target_squares = StampEffectResolver.filter_out_base_fields(game_state, target_squares)
	if target_squares.is_empty():
		return 0.0

	var simulated_pieces: Dictionary = AIStateSimulator.apply_candidate_to_pieces(game_state.pieces, move)
	var opponent_player_id: int = 1 - player_id
	var board_effects_with_invalid: Array = game_state.board_effects.duplicate()
	board_effects_with_invalid.append({
		"effect_type": StampEffect.TYPE_INVALID_SQUARES,
		"owner_player_id": player_id,
		"target_player_id": int(stamp.effect_settings.get("target_player_id", -1)),
		"squares": target_squares,
		"turns_remaining": max(1, int(stamp.effect_settings.get("turns_remaining", stamp.duration))),
	})

	var opponent_moves_before: int = AIBoardMath.count_valid_turn_moves_for_player(game_state, simulated_pieces, opponent_player_id, game_state.board_effects, board_size)
	var opponent_moves_after: int = AIBoardMath.count_valid_turn_moves_for_player(game_state, simulated_pieces, opponent_player_id, board_effects_with_invalid, board_size)
	var opponent_reduced_moves: int = max(0, opponent_moves_before - opponent_moves_after)

	var own_moves_before: int = AIBoardMath.count_valid_turn_moves_for_player(game_state, simulated_pieces, player_id, game_state.board_effects, board_size)
	var own_moves_after: int = AIBoardMath.count_valid_turn_moves_for_player(game_state, simulated_pieces, player_id, board_effects_with_invalid, board_size)
	var own_reduced_moves: int = max(0, own_moves_before - own_moves_after)

	return float(opponent_reduced_moves) * SCORE_INVALID_MOVE_REDUCTION - float(own_reduced_moves) * PENALTY_OWN_MOVE_REDUCTION

func score_move_base_effect(game_state: GameStateData, player_id: int, moving_piece: Piece, stamp: Stamp, source_pos: Vector2, board_size: int) -> float:
	if moving_piece == null:
		return 0.0

	var raw_target_squares: Array[Vector2] = StampEffectResolver.get_effect_squares_unfiltered(stamp, source_pos, moving_piece.color)
	if raw_target_squares.is_empty():
		return -PENALTY_MOVE_BASE_NOOP

	var new_base_pos: Vector2 = raw_target_squares[0]
	if !MoveRules.is_valid_position(new_base_pos, board_size):
		return -PENALTY_MOVE_BASE_NOOP
	if StampEffectResolver.is_base_field_for_other_player(game_state, new_base_pos, player_id):
		return -PENALTY_MOVE_BASE_NOOP

	var current_base_pos: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, player_id)
	var opponent_positions: Array[Vector2] = AIBoardMath.get_piece_positions_for_player(game_state.pieces, 1 - player_id)
	if opponent_positions.is_empty():
		return 0.0

	var min_distance_before: float = AIBoardMath.get_min_distance_to_positions(current_base_pos, opponent_positions)
	var min_distance_after: float = AIBoardMath.get_min_distance_to_positions(new_base_pos, opponent_positions)
	var avg_distance_before: float = AIBoardMath.get_average_distance_to_positions(current_base_pos, opponent_positions)
	var avg_distance_after: float = AIBoardMath.get_average_distance_to_positions(new_base_pos, opponent_positions)
	return (min_distance_after - min_distance_before) * SCORE_MOVE_BASE_MIN_DISTANCE \
		+ (avg_distance_after - avg_distance_before) * SCORE_MOVE_BASE_AVG_DISTANCE

func get_effect_source_pos(stamp: Stamp, from_pos: Vector2, to_pos: Vector2) -> Vector2:
	if stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE \
		or stamp.effect_trigger == StampEffect.TRIGGER_ON_CAPTURE \
		or stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
		return to_pos
	return from_pos

func get_frozen_piece_score(game_state: GameStateData, piece: Piece, piece_pos: Vector2, target_player_id: int, board_size: int) -> float:
	var score: float = SCORE_FROZEN_ENEMY_PIECE
	score += score_stamp_material(piece) * 0.45
	if piece.has_crown:
		score += SCORE_CAPTURE_CROWN * 0.65

	var moves_before_freeze: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		game_state.pieces,
		piece_pos,
		target_player_id,
		board_size,
		game_state.board_effects
	)
	score += float(moves_before_freeze.size()) * 4.0
	return score

func is_crown_point_effect(stamp: Stamp) -> bool:
	return stamp.effect_type == StampEffect.TYPE_GAIN_CROWN_POINT or stamp.effect_type == StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT

func stamp_effect_targets_player(stamp: Stamp, target_player_id: int) -> bool:
	var effect_target_player_id: int = int(stamp.effect_settings.get("target_player_id", -1))
	return effect_target_player_id == -1 || effect_target_player_id == target_player_id

func score_uncapturable_effect(piece: Piece) -> float:
	var score: float = 46.0
	if piece != null and piece.has_crown:
		score += 120.0
	return score

## A crown point effect is worth one point of the crown race to the player:
## their own point gained, or the opponent's taken away. Nothing when the
## meter has no room to move.
func score_crown_point_effect(game_state: GameStateData, player_id: int, target_player_id: int, delta: int) -> float:
	var points: int = int(game_state.crown_points.get(target_player_id, 0))
	if (delta > 0 and points >= game_state.crown_points_required) or (delta < 0 and points <= 0):
		return 0.0
	var side: float = 1.0 if target_player_id == player_id else -1.0
	return SCORE_CROWN_POINT * float(delta) * side

## One step more (delta 1) or less (-1) on each of the target's stamped golems
## (see get_duration_step_value). excluded_piece is left out: a captured golem
## is off the board by the time its on_captured effect works.
func score_duration_adjustment_effect(game_state: GameStateData, player_id: int, target_player_id: int, delta: int, excluded_piece: Piece = null) -> float:
	var target_color: int = StampEffectResolver.get_color_for_player_id(target_player_id)
	var helps_player: bool = (delta > 0) == (target_player_id == player_id)
	var score: float = 0.0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece == excluded_piece or piece.color != target_color or piece.affixed_stamp == null or piece.turns_remaining <= 0:
			continue
		var step_value: float = get_duration_step_value(game_state, piece, StampEffectResolver.as_vector2(position_value, INVALID_POS), delta)
		score += step_value if helps_player else -step_value
	return score

## What one step more (delta 1) or less (-1) on the golem's stamp is worth to
## its owner. The step comes at the end of the stamp, so it only counts if the
## golem makes every step before it - DURATION_STEP_REACH_CHANCE for each - and
## the stamp's later steps are worth less (its estimate's T(D)). A stamp on its
## last step gains the most: a +1 keeps it from running out on the golem's next
## move, a -1 ends it at once, and either way decides whether the golem stands
## bare, waiting a turn for a new stamp. Ended at once, its on_expire effect
## goes off: a Black Hole's -1 sets off the Nova next to it.
func get_duration_step_value(game_state: GameStateData, piece: Piece, piece_pos: Vector2, delta: int) -> float:
	var turns: int = piece.turns_remaining
	var step: int = turns + 1 if delta > 0 else turns
	var step_value: float = (AIStampValues.get_stamp_remaining_value(piece.affixed_stamp, step) - AIStampValues.get_stamp_remaining_value(piece.affixed_stamp, step - 1)) * STAMP_ESTIMATE_POINT_SCORE
	var value: float = step_value * pow(DURATION_STEP_REACH_CHANCE, step - 1)
	# What hangs on the stamp running out comes on its last step.
	var expiry_value: float = SCORE_DURATION_SAVES_EXPIRY if turns == 1 else 0.0
	if piece.has_crown:
		expiry_value += SCORE_DURATION_CROWN_BEARER
	value += expiry_value * pow(DURATION_STEP_REACH_CHANCE, turns - 1)
	if delta < 0 and turns == 1:
		value -= score_expiry_effect_for_owner(game_state, piece, piece_pos, BoardConfig.BOARD_SIZE)
	return value

## What taking the golem is worth to the attacker, less what its on_captured
## effect pays back (a bomb takes the capturing golem along).
func get_piece_target_score(piece: Piece, game_state: GameStateData = null) -> float:
	return maxf(0.0, score_capture_at(game_state, piece) - score_on_captured_deterrent(game_state, piece))
