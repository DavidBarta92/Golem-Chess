extends RefCounted
class_name AICrownRace

## The crown race: a player's standing in it (points on the meter, the crown on
## the board and its bearer's way home), how a plan moves it, when the crown is
## ready, and whether it should go onto a golem now.

## A bearer that can step onto the base on its next turn.
const SCORE_CROWN_NEXT_TURN_WIN: float = 600.0
## How many own turns shorter the new bearer's route has to be for the crown to
## move (is_crown_move_worthwhile): the new bearer waits out the turn the old one
## could have stepped in.
const CROWN_MOVE_MIN_ROUTE_GAIN: float = 2.0
## How many steps from the enemy base a stamp may run out on a golem and it still
## be worth a crown not yet down (stamp_carries_crown): a new stamp can finish a
## walk from that near, and asking for more leaves many sides without a bearer.
## From farther out hardly any first crown got home.
const CROWN_STEPS_SHORT_ALLOWED: int = 2
## The share of the best bearer-to-be's route bonus a (nearly) charged crown is
## worth before it goes down: what walks golems into range first.
const CROWN_STAGING_SHARE: float = 0.25
## A bearer an enemy golem can take: the share of its value lost when the enemy
## moves next, and when its owner moves first and can still get it away.
const CROWN_EXPOSED_LOSS_SHARE: float = 0.85
const CROWN_EXPOSED_FLEE_SHARE: float = 0.25
const CROWN_RACE_DEFENSE_WEIGHT: float = 1.0
const INVALID_POS: Vector2 = AIScoringContext.INVALID_POS
const SCORE_CROWN_ON_BOARD: float = AIReach.SCORE_CROWN_ON_BOARD
const SCORE_CROWN_POINT: float = AIReach.SCORE_CROWN_POINT

var context: AIScoringContext
var reach: AIReach
var se_tenant_scoring: AISeTenantScoring
var effect_scoring: AIEffectScoring
var crown_race_value_cache: Dictionary = {}

func _init(
	new_context: AIScoringContext,
	new_reach: AIReach,
	new_se_tenant_scoring: AISeTenantScoring,
	new_effect_scoring: AIEffectScoring,
) -> void:
	context = new_context
	reach = new_reach
	se_tenant_scoring = new_se_tenant_scoring
	effect_scoring = new_effect_scoring

## Whether the crown can go, this turn, onto a golem that has a route and that
## the enemy cannot take. Asked with its bearer under attack.
func can_crown_move_to_safety(game_state: GameStateData, player_id: int, board_size: int) -> bool:
	for position_value in game_state.pieces:
		var square: Vector2 = StampEffectResolver.as_vector2(position_value, INVALID_POS)
		if game_state.can_crown_piece(player_id, square) and is_crown_move_worthwhile(game_state, player_id, square, board_size):
			return true
	return false

## How many of the player's own turns until they can put the crown down (or,
## with it on the board, move it): 0 means on this turn if it is theirs, else
## at the start of their next one.
static func get_crown_turns_to_ready(game_state: GameStateData, player_id: int) -> int:
	var points: int = int(game_state.crown_points.get(player_id, 0))
	# A turn's point comes at its start, so a player waiting for their turn
	# still has one due.
	if game_state.current_turn_player != player_id:
		points += 1
	return maxi(0, game_state.crown_points_required - points)

static func can_crown_next_turn(game_state: GameStateData, player_id: int) -> bool:
	return get_crown_turns_to_ready(game_state, player_id) == 0

## The player's standing in the crown race: the points gathered - a (nearly)
## charged crown also by how close its best bearer would be - and a crown on
## the board by how close its bearer is to taking the enemy base. With both,
## the better of the two counts: the points only move the crown, and a capture
## takes them along with it. A Se-tenant set on the board, whole or on its
## way, adds its own share.
func get_crown_race_value(game_state: GameStateData, player_id: int, board_size: int) -> float:
	var cache_key: String = "%s|p%d" % [context.get_state_hash(game_state), player_id]
	if crown_race_value_cache.has(cache_key):
		return float(crown_race_value_cache[cache_key])

	var points: int = int(game_state.crown_points.get(player_id, 0))
	var value: float = float(points) * SCORE_CROWN_POINT
	if points >= game_state.crown_points_required:
		value = reach.get_crown_hold_value()
	if points + 1 >= game_state.crown_points_required:
		value += reach.get_crown_route_bonus(get_best_crown_candidate_route_turns(game_state, player_id, board_size)) * CROWN_STAGING_SHARE
	var crowned_pos: Vector2 = game_state.get_crowned_piece_position(player_id)
	if crowned_pos != INVALID_POS:
		value = maxf(value, score_crown_bearer(game_state, player_id, crowned_pos, board_size, game_state.current_turn_player == player_id))
	value += se_tenant_scoring.get_se_tenant_progress_value(game_state, player_id, game_state.count_se_tenant_golems(player_id))
	crown_race_value_cache[cache_key] = value
	return value

func get_crown_race_value_delta(before_state: GameStateData, after_state: GameStateData, player_id: int, board_size: int) -> float:
	return get_crown_race_value(after_state, player_id, board_size) - get_crown_race_value(before_state, player_id, board_size)

## How the plan moves the crown race: the player's own standing, and - when the
## AI sees the threats this turn - the opponent's, against it.
func score_crown_race_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = context.get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return 0.0
	var score: float = get_crown_race_value_delta(game_state, simulated_state, player_id, board_size)
	if context.sees_threats_this_turn:
		score -= get_crown_race_value_delta(game_state, simulated_state, 1 - player_id, board_size) * CROWN_RACE_DEFENSE_WEIGHT
	for action_value in plan.get("actions", []):
		if action_value is Dictionary and str(action_value.get("type", "")) == "place_crown":
			score += score_crown_condition_effect(game_state, player_id, StampEffectResolver.as_vector2(action_value.get("piece_pos", INVALID_POS), INVALID_POS), board_size)
	return score

## The crown on this golem (it need not be there yet): its route to the enemy
## base, less the risk of losing it to an enemy golem that can take it - all
## but certain when the enemy moves next, smaller when the owner moves first
## and can still get it away. A golem crowned this turn waits it out, so for
## a crown about to go down the owner does not move first.
func score_crown_bearer(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int, owner_moves_next: bool = false) -> float:
	var route_turns: float = reach.get_golem_route_turns(game_state, player_id, piece_pos, board_size)
	var value: float = SCORE_CROWN_ON_BOARD + reach.get_crown_route_bonus(route_turns)
	if route_turns == 1.0:
		value += SCORE_CROWN_NEXT_TURN_WIN
	if reach.is_square_attacked_by(game_state, 1 - player_id, piece_pos, board_size):
		value *= 1.0 - (CROWN_EXPOSED_FLEE_SHARE if owner_moves_next else CROWN_EXPOSED_LOSS_SHARE)
	return value

## The crown race's quick take on crowning this golem now rather than holding
## the charged crown back.
func score_crown_action(game_state: GameStateData, player_id: int, action: Dictionary, board_size: int) -> float:
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(action.get("piece_pos", INVALID_POS), INVALID_POS)
	return score_crown_landing(game_state, player_id, piece_pos, board_size) - reach.get_crown_hold_value()

## score_crown_bearer for a crown about to go down: on the board the crowning
## leaves (Mercury's freeze can take the attacker off it, Goat is safe), and with
## what the crowning itself does.
func score_crown_landing(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> float:
	var crowned_state: GameStateData = get_crowned_state(game_state, player_id, piece_pos)
	return score_crown_bearer(crowned_state, player_id, piece_pos, board_size) + score_crown_condition_effect(game_state, player_id, piece_pos, board_size)

## The board once this golem is crowned, its crown_condition effect gone off. The
## state itself for a stamp without one, the usual case.
func get_crowned_state(game_state: GameStateData, player_id: int, piece_pos: Vector2) -> GameStateData:
	if !has_crown_condition_effect(game_state.get_piece(piece_pos)):
		return game_state
	var crowned_state: GameStateData = AIStateSimulator.clone_game_state(game_state)
	AIStateSimulator.apply_place_crown_action(crowned_state, player_id, {"piece_pos": piece_pos})
	return crowned_state

func has_crown_condition_effect(piece: Piece) -> bool:
	if piece == null or piece.affixed_stamp == null:
		return false
	return piece.affixed_stamp.has_effect() and piece.affixed_stamp.effect_trigger == StampEffect.TRIGGER_CROWN_CONDITION

## What the golem's crown_condition effect is worth as it goes off, on the board
## before it does: a frozen golem counts by the moves it loses. The golem itself
## as it stands crowned, which an uncapturable crown is worth more for.
func score_crown_condition_effect(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> float:
	var piece: Piece = game_state.get_piece(piece_pos)
	if !has_crown_condition_effect(piece):
		return 0.0
	var crowned_piece: Piece = get_crowned_state(game_state, player_id, piece_pos).get_piece(piece_pos)
	var crowning: Dictionary = {"from": piece_pos, "to": piece_pos, "stamp": piece.affixed_stamp, "requires_affix": false}
	return effect_scoring.score_effect_value(game_state, player_id, crowned_piece, piece.affixed_stamp, piece_pos, crowning, board_size)

## Whether the crown should go onto this golem now. It costs the turn the bearer
## could have stepped in and the page turn, while a whole Se-tenant set leaves the
## meter full, so the crown race alone does not hold it back. A crown not yet
## down waits for a golem that can carry it (near enough) home: a full meter loses
## nothing by waiting. A crown on the board moves for a route
## CROWN_MOVE_MIN_ROUTE_GAIN turns shorter, or to get it off a bearer under attack
## or without a route, and never onto a golem without a route or one the enemy
## can take. All of it as the board stands once the golem is crowned.
func is_crown_move_worthwhile(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> bool:
	var crowned_state: GameStateData = get_crowned_state(game_state, player_id, piece_pos)
	var bearer_pos: Vector2 = game_state.get_crowned_piece_position(player_id)
	if bearer_pos == INVALID_POS:
		return can_golem_carry_crown(crowned_state, player_id, piece_pos, board_size)
	var route_turns: float = reach.get_golem_route_turns(crowned_state, player_id, piece_pos, board_size)
	if route_turns < 0.0:
		return false
	var bearer_turns: float = reach.get_golem_route_turns(game_state, player_id, bearer_pos, board_size)
	if bearer_turns >= 0.0 and bearer_turns - route_turns < CROWN_MOVE_MIN_ROUTE_GAIN and !reach.is_square_attacked_by(game_state, 1 - player_id, bearer_pos, board_size):
		return false
	return !reach.is_square_attacked_by(crowned_state, 1 - player_id, piece_pos, board_size)

## Whether the golem can walk the crown home or near enough: on the stamp it
## carries, or for a bare golem, on one from the open codex page.
func can_golem_carry_crown(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> bool:
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null or piece.is_respawn_locked():
		return false
	if piece.affixed_stamp != null:
		return stamp_carries_crown(game_state, player_id, piece.affixed_stamp, piece.turns_remaining, piece_pos, board_size)
	for stamp: Stamp in reach.get_open_page_stamps(game_state, player_id):
		if stamp_carries_crown(game_state, player_id, stamp, stamp.duration if stamp.duration == -1 else maxi(1, stamp.duration), piece_pos, board_size):
			return true
	return false

func stamp_carries_crown(game_state: GameStateData, player_id: int, stamp: Stamp, turns_left: int, piece_pos: Vector2, board_size: int) -> bool:
	var route: Vector2 = reach.get_base_route(game_state, player_id, stamp, piece_pos, board_size)
	if route.y < 0.0:
		return false
	return reach.stamp_outlasts_route(stamp, turns_left, int(route.y)) or int(route.y) - turns_left <= CROWN_STEPS_SHORT_ALLOWED

func get_best_crown_candidate_route_turns(game_state: GameStateData, player_id: int, board_size: int) -> float:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var best_turns: float = -1.0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece.has_crown:
			continue
		var turns: float = reach.get_golem_route_turns(game_state, player_id, StampEffectResolver.as_vector2(position_value, INVALID_POS), board_size)
		if turns >= 0.0 and (best_turns < 0.0 or turns < best_turns):
			best_turns = turns
	return best_turns

## The route the crown race is about: its bearer's, or while the crown is not
## down, that of the best golem to put it on.
func get_crown_staging_route_turns(game_state: GameStateData, player_id: int, board_size: int) -> float:
	var crowned_pos: Vector2 = game_state.get_crowned_piece_position(player_id)
	if crowned_pos != INVALID_POS:
		return reach.get_golem_route_turns(game_state, player_id, crowned_pos, board_size)
	return get_best_crown_candidate_route_turns(game_state, player_id, board_size)

## Whether the crown is on the board or near enough to charged to plan around.
func player_has_crown_plan(game_state: GameStateData, player_id: int) -> bool:
	return game_state.has_crown_on_board(player_id) or get_crown_turns_to_ready(game_state, player_id) <= 1
