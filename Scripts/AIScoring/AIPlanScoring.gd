extends RefCounted
class_name AIPlanScoring

## A whole turn plan: its full score, broken down into the move, the affixes, the
## hand and codex it leaves, the threats on the board after it, the crown race,
## the strategy mode and the hard tactical rules; and the fast score that ranks
## the plans before the full one is worth working out.

const HAND_DECK_ECONOMY_WEIGHT: float = 0.18
const SCORE_TWO_TURN_BASE_THREAT: float = 260.0
const SCORE_FORCE_DEFENSE: float = 120.0
const SCORE_THREAT_MAP_OWN_ATTACK: float = 14.0
const PENALTY_THREAT_MAP_EXPOSURE: float = 18.0
const SCORE_HAND_SYNERGY: float = 18.0
const SCORE_MOVE_BASE_PIECE_ESCAPE: float = 950.0
const PENALTY_MOVE_BASE_PIECE_THREATENED: float = 1800.0
const SCORE_MATERIAL_ADVANTAGE_FINISH: float = 360.0
const SCORE_EMERGENCY_PREVENT_BASE_WIN: float = 50000.0
const PENALTY_ALLOW_IMMEDIATE_BASE_WIN: float = 65000.0
const RESOURCE_ADVANTAGE_FOR_FINISH: float = 4.0
const ENEMY_USABLE_GOLEMS_FOR_FINISH: int = 3
## How far ahead in the codex the AI looks for a stamp that a stamp put on now
## prepares (score_upcoming_partner_bonus), and the share of what that stamp
## would then do that counts now: it may not come in time.
const UPCOMING_PARTNER_LOOKAHEAD: int = 3
const UPCOMING_PARTNER_SHARE: float = 0.5
const SCORE_CLEAR_OWN_GOLEM_FROM_ENEMY_BASE: float = 360.0
const DURATION_STEP_REACH_CHANCE: float = AIEffectScoring.DURATION_STEP_REACH_CHANCE
const INVALID_POS: Vector2 = AIScoringContext.INVALID_POS
const SCORE_AFFIX_STAMP: float = AIMoveScoring.SCORE_AFFIX_STAMP
const SCORE_DURATION_SAVES_EXPIRY: float = AIEffectScoring.SCORE_DURATION_SAVES_EXPIRY
const SCORE_WIN: float = AIScoringContext.SCORE_WIN
const STAMP_ESTIMATE_POINT_SCORE: float = AIStampValues.STAMP_ESTIMATE_POINT_SCORE

var context: AIScoringContext
var se_tenant_scoring: AISeTenantScoring
var effect_scoring: AIEffectScoring
var crown_race: AICrownRace
var move_scoring: AIMoveScoring
var strategy_scoring: AIStrategyScoring

func _init(
	new_context: AIScoringContext,
	new_se_tenant_scoring: AISeTenantScoring,
	new_effect_scoring: AIEffectScoring,
	new_crown_race: AICrownRace,
	new_move_scoring: AIMoveScoring,
	new_strategy_scoring: AIStrategyScoring,
) -> void:
	context = new_context
	se_tenant_scoring = new_se_tenant_scoring
	effect_scoring = new_effect_scoring
	crown_race = new_crown_race
	move_scoring = new_move_scoring
	strategy_scoring = new_strategy_scoring

func score_turn_plan_fast(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var score: float = 0.0

	var actions: Array = plan.get("actions", [])
	for action_value in actions:
		if action_value is Dictionary and str(action_value.get("type", "")) == "place_crown":
			score += crown_race.score_crown_action(game_state, player_id, action_value, board_size)
		elif action_value is Dictionary and str(action_value.get("type", "")) == "turn_page":
			score += se_tenant_scoring.score_se_tenant_page_turn(game_state, player_id)

	var setup_affix_actions: Array = plan.get("setup_affix_actions", [])
	for affix_action_value in setup_affix_actions:
		var affix_action: Dictionary = affix_action_value
		score += move_scoring.score_affix_setup_fast(game_state, player_id, affix_action, board_size)

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		score += move_scoring.score_move_fast(game_state, player_id, move, board_size)

	score -= float(maxi(0, actions.size() - 1)) * 0.4
	return score

func score_hand_deck_economy_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary) -> float:
	if game_state == null:
		return 0.0

	var score: float = 0.0
	var actions: Array = plan.get("actions", [])
	var has_affix_action: bool = false
	for action_value in actions:
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		match str(action.get("type", "")):
			"affix_stamp":
				var affixed_stamp: Stamp = context.get_cached_stamp(str(action.get("stamp_name", "")))
				if affixed_stamp != null:
					has_affix_action = true
					score -= AIStampValues.get_stamp_value_above_average(affixed_stamp) * 0.20
					score += max(0, affixed_stamp.duration) * 0.75
					score += score_stamp_synergy_for_affix(game_state, player_id, action, affixed_stamp)
					score += score_upcoming_partner_bonus(game_state, player_id, affixed_stamp, StampEffectResolver.as_vector2(action.get("piece_pos", INVALID_POS), INVALID_POS))
			"exchange_stamp":
				var exchanged_stamp: Stamp = context.get_cached_stamp(str(action.get("stamp_name", "")))
				if exchanged_stamp != null:
					score -= AIStampValues.get_stamp_value_above_average(exchanged_stamp) * 0.35
					score += score_deck_draw_quality(game_state, player_id, str(action.get("stamp_name", ""))) * 0.35
			"turn_page":
				score += se_tenant_scoring.score_se_tenant_page_turn(game_state, player_id)

	score += score_remaining_hand_quality(game_state, player_id, actions) * HAND_DECK_ECONOMY_WEIGHT
	score += score_remaining_deck_quality(game_state, player_id) * HAND_DECK_ECONOMY_WEIGHT * 0.35
	score += score_hand_synergy(game_state, player_id) * HAND_DECK_ECONOMY_WEIGHT
	if has_affix_action:
		score += SCORE_AFFIX_STAMP * 1.5
	return score

func score_stamp_synergy_for_affix(game_state: GameStateData, player_id: int, action: Dictionary, stamp: Stamp) -> float:
	if game_state == null or stamp == null:
		return 0.0

	var piece_pos: Vector2 = StampEffectResolver.as_vector2(action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var distance_to_base: float = AIBoardMath.get_manhattan_distance(piece_pos, opponent_base)
	var movement_count: int = stamp.get_directions().size()
	var score: float = 0.0
	if stamp.effect_type == StampEffect.TYPE_FROZEN_SQUARES or stamp.effect_type == StampEffect.TYPE_INVALID_SQUARES:
		score += maxf(0.0, float(BoardConfig.BOARD_SIZE) - distance_to_base) * 1.5
	if stamp.effect_type == StampEffect.TYPE_INCREASE_SELF_DURATION and movement_count >= 4:
		score += SCORE_HAND_SYNERGY
	if stamp.effect_type == StampEffect.TYPE_MOVE_BASE:
		score += SCORE_HAND_SYNERGY * 0.75
	return score

## A one-step stamp put on now for one the codex brings soon (the next
## UPCOMING_PARTNER_LOOKAHEAD stamps after the open page): it stays on its last
## step until then, as a step would end it. A stamp that adds a step to every
## own stamp on affix keeps it; one that takes a step off every own stamp sets
## off its on_expire effect, right where it is put on now - counted only when
## that helps, as the owner need not make that move, and on a stamp that does
## it on its moves only if it makes one (DURATION_STEP_REACH_CHANCE).
## UPCOMING_PARTNER_SHARE of it counts now, as the stamp may not come in time.
func score_upcoming_partner_bonus(game_state: GameStateData, player_id: int, stamp: Stamp, piece_pos: Vector2) -> float:
	if stamp == null or stamp.duration != 1 or !game_state.has_codex_for_player(player_id):
		return 0.0
	var extender_coming: bool = false
	var shortener_share: float = 0.0
	for stamp_name in game_state.get_upcoming_stamp_names_in_turn_order(player_id, UPCOMING_PARTNER_LOOKAHEAD):
		var upcoming: Stamp = context.get_cached_stamp(stamp_name)
		if upcoming == null or !upcoming.has_effect():
			continue
		if upcoming.effect_type == StampEffect.TYPE_INCREASE_OWN_DURATIONS and upcoming.effect_trigger == StampEffect.TRIGGER_ON_AFFIX:
			extender_coming = true
		elif upcoming.effect_type == StampEffect.TYPE_DECREASE_OWN_DURATIONS:
			if upcoming.effect_trigger == StampEffect.TRIGGER_ON_AFFIX:
				shortener_share = 1.0
			elif upcoming.effect_trigger == StampEffect.TRIGGER_ON_MOVE:
				shortener_share = maxf(shortener_share, DURATION_STEP_REACH_CHANCE)

	var bonus: float = 0.0
	if extender_coming:
		bonus += (AIStampValues.get_stamp_remaining_value(stamp, 2) - AIStampValues.get_stamp_remaining_value(stamp, 1)) * STAMP_ESTIMATE_POINT_SCORE * DURATION_STEP_REACH_CHANCE + SCORE_DURATION_SAVES_EXPIRY
	var piece: Piece = game_state.get_piece(piece_pos)
	if shortener_share > 0.0 and piece != null and stamp.has_effect() and stamp.effect_trigger == StampEffect.TRIGGER_ON_EXPIRE:
		var expiry_move: Dictionary = {"from": piece_pos, "to": piece_pos, "stamp": stamp, "requires_affix": false}
		bonus += maxf(0.0, effect_scoring.score_effect_value(game_state, player_id, piece, stamp, piece_pos, expiry_move, BoardConfig.BOARD_SIZE)) * shortener_share
	return bonus * UPCOMING_PARTNER_SHARE

func score_hand_synergy(game_state: GameStateData, player_id: int) -> float:
	var hand: Array = game_state.player_hands.get(player_id, [])
	if hand.size() < 2:
		return 0.0

	var has_duration: bool = false
	var mobility_total: int = 0
	for stamp_name_value in hand:
		var stamp: Stamp = context.get_cached_stamp(str(stamp_name_value))
		if stamp == null:
			continue
		has_duration = has_duration or stamp.effect_type == StampEffect.TYPE_INCREASE_SELF_DURATION or stamp.effect_type == StampEffect.TYPE_INCREASE_OWN_DURATIONS
		mobility_total += stamp.get_directions().size()

	if has_duration and mobility_total >= hand.size() * 3:
		return SCORE_HAND_SYNERGY * 0.75
	return 0.0

func score_remaining_hand_quality(game_state: GameStateData, player_id: int, actions: Array) -> float:
	var consumed_stamp_names: Array = []
	for action_value in actions:
		if !(action_value is Dictionary):
			continue
		var action: Dictionary = action_value
		if str(action.get("type", "")) == "affix_stamp":
			consumed_stamp_names.append(str(action.get("stamp_name", "")))

	var hand: Array = game_state.player_hands.get(player_id, [])
	var score: float = 0.0
	var remaining_count: int = 0
	for stamp_name_value in hand:
		var stamp_name: String = str(stamp_name_value)
		var consumed_index: int = consumed_stamp_names.find(stamp_name)
		if consumed_index != -1:
			consumed_stamp_names.remove_at(consumed_index)
			continue

		var stamp: Stamp = context.get_cached_stamp(stamp_name)
		if stamp == null:
			continue
		score += AIStampValues.get_stamp_value_above_average(stamp)
		remaining_count += 1

	if remaining_count <= 0:
		return -8.0
	return score / float(remaining_count)

func score_remaining_deck_quality(game_state: GameStateData, player_id: int) -> float:
	var deck: Array = game_state.get_upcoming_stamp_names_in_turn_order(player_id, 5)
	if deck.is_empty():
		return -6.0

	var sample_count: int = deck.size()
	var score: float = 0.0
	for stamp_name_value in deck:
		var stamp: Stamp = context.get_cached_stamp(str(stamp_name_value))
		if stamp == null:
			continue
		score += AIStampValues.get_stamp_value_above_average(stamp)
	return score / float(sample_count)

func score_deck_draw_quality(game_state: GameStateData, player_id: int, avoided_stamp_name: String) -> float:
	var deck: Array = game_state.get_upcoming_stamp_names_in_turn_order(player_id)
	if deck.is_empty():
		return -10.0

	for stamp_name_value in deck:
		var stamp_name: String = str(stamp_name_value)
		if stamp_name == avoided_stamp_name:
			continue
		var stamp: Stamp = context.get_cached_stamp(stamp_name)
		if stamp == null:
			continue
		return AIStampValues.get_stamp_value_above_average(stamp)
	return -5.0

func score_threat_map_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = context.get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	if simulated_state.game_over:
		return clampf(context.get_terminal_score_for_player(simulated_state, player_id) * 0.05, -SCORE_WIN * 0.05, SCORE_WIN * 0.05)

	var opponent_player_id: int = 1 - player_id
	var score: float = 0.0
	score += score_two_turn_base_pressure(simulated_state, player_id, board_size)
	if context.sees_threats_this_turn:
		score -= score_two_turn_base_pressure(simulated_state, opponent_player_id, board_size) * 1.25
	score += score_attack_map_pressure(simulated_state, player_id, board_size) * SCORE_THREAT_MAP_OWN_ATTACK
	score -= score_attack_map_pressure(simulated_state, opponent_player_id, board_size) * PENALTY_THREAT_MAP_EXPOSURE
	return score

func score_two_turn_base_pressure(game_state: GameStateData, player_id: int, board_size: int) -> float:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_player_id: int = 1 - player_id
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, opponent_player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)

	# Only a crowned golem wins, and a move cannot crown one, so without a crown
	# already on the board no move can set up a base entry for next turn, and
	# the per-move simulation (the expensive part of full plan scoring) has
	# nothing to find.
	var has_bearer: bool = game_state.has_crown_on_board(player_id)
	var best_pressure: float = 0.0
	for move: Dictionary in valid_moves:
		var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
		var is_bearer_move: bool = AIStateSimulator.is_own_crown_candidate(game_state.pieces, move, player_id)
		if AIStateSimulator.is_base_win_move(game_state.pieces, move, player_id, opponent_base):
			best_pressure = maxf(best_pressure, SCORE_WIN * 0.25)
			continue

		var distance_after: float = AIBoardMath.get_manhattan_distance(to_pos, opponent_base)
		var pressure: float = maxf(0.0, float(board_size) - distance_after) * 8.0
		if is_bearer_move:
			pressure += SCORE_TWO_TURN_BASE_THREAT
		if has_bearer:
			var simulated_plan: Dictionary = {
				"actions": [{
					"type": "move_piece",
					"player_id": player_id,
					"from": AIStateSimulator.get_move_from(move),
					"to": to_pos,
				}],
				"move": move,
				"setup_affix_actions": [],
				"plan_type": "threat_probe",
			}
			var next_state: GameStateData = AIStateSimulator.apply_turn_plan(game_state, player_id, simulated_plan, board_size)
			if !next_state.game_over and has_immediate_base_win(next_state, player_id, board_size):
				pressure += SCORE_FORCE_DEFENSE
		best_pressure = maxf(best_pressure, pressure)
	return best_pressure

func has_immediate_base_win(game_state: GameStateData, player_id: int, board_size: int) -> bool:
	if !game_state.has_crown_on_board(player_id):
		return false
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)
	for move: Dictionary in valid_moves:
		if AIStateSimulator.is_base_win_move(game_state.pieces, move, player_id, opponent_base):
			return true
	return false

func score_attack_map_pressure(game_state: GameStateData, player_id: int, board_size: int) -> float:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var opponent_player_id: int = 1 - player_id
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		player_color,
		board_size,
		game_state.board_effects
	)
	var pressure: float = 0.0
	var threatened_squares: Dictionary = {}
	for move: Dictionary in valid_moves:
		var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
		var square_key: String = context.vector_hash(to_pos)
		if threatened_squares.has(square_key):
			continue
		threatened_squares[square_key] = true

		var target_piece: Piece = game_state.get_piece(to_pos)
		if target_piece == null:
			continue
		var target_player_id: int = BoardConfig.get_player_id_for_color(target_piece.color)
		if target_player_id != opponent_player_id:
			continue
		pressure += effect_scoring.get_piece_target_score(target_piece, game_state)
	return pressure

func score_turn_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> float:
	var breakdown: Dictionary = score_turn_plan_breakdown(game_state, player_id, plan, board_size)
	return float(breakdown.get("total", 0.0))

func score_turn_plan_breakdown(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int = BoardConfig.BOARD_SIZE) -> Dictionary:
	var move_score: float = 0.0
	var setup_score: float = 0.0
	var action_score: float = 0.0

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		move_score = move_scoring.score_move_cached(game_state, player_id, move, board_size)

	var setup_affix_actions: Array = plan.get("setup_affix_actions", [])
	for affix_index in range(setup_affix_actions.size()):
		var affix_action: Dictionary = setup_affix_actions[affix_index]
		setup_score += move_scoring.score_affix_setup(get_affix_scoring_state(game_state, player_id, plan, affix_index, board_size), player_id, affix_action, board_size)

	var actions: Array = plan.get("actions", [])
	action_score = -float(maxi(0, actions.size() - 1)) * 0.8
	var economy_score: float = score_hand_deck_economy_for_plan(game_state, player_id, plan)
	var threat_score: float = score_threat_map_for_plan(game_state, player_id, plan, board_size)
	var crown_score: float = crown_race.score_crown_race_for_plan(game_state, player_id, plan, board_size)
	var strategy_score: float = strategy_scoring.score_strategy_mode_for_plan(game_state, player_id, plan, board_size)
	var hard_rule_score: float = score_hard_tactical_rules_for_plan(game_state, player_id, plan, board_size)
	var total_score: float = move_score + setup_score + action_score + economy_score + threat_score + crown_score + strategy_score + hard_rule_score
	return {
		"move": move_score,
		"setup": setup_score,
		"action_count": action_score,
		"economy": economy_score,
		"threat": threat_score,
		"crown": crown_score,
		"strategy": strategy_score,
		"hard_rules": hard_rule_score,
		"total": total_score,
	}

## The state a plan's setup affix is scored on: the turn's start, except for a
## stamp whose on_affix effect works on the board as the turn's earlier actions
## left it - a War Drummer put on after the turn's one-step stamps extends
## them too.
func get_affix_scoring_state(game_state: GameStateData, player_id: int, plan: Dictionary, affix_index: int, board_size: int) -> GameStateData:
	if affix_index <= 0:
		return game_state
	var affix_action: Dictionary = plan.get("setup_affix_actions", [])[affix_index]
	var stamp: Stamp = context.get_cached_stamp(str(affix_action.get("stamp_name", "")))
	if stamp == null or !stamp.has_effect() or stamp.effect_trigger != StampEffect.TRIGGER_ON_AFFIX:
		return game_state

	var state: GameStateData = AIStateSimulator.clone_game_state(game_state)
	state.current_turn_player = player_id
	var affixes_done: int = 0
	for action_value in plan.get("actions", []):
		var action: Dictionary = action_value
		var action_type: String = str(action.get("type", ""))
		if action_type == "affix_stamp":
			if affixes_done == affix_index:
				break
			AIStateSimulator.apply_affix_action(state, player_id, action, board_size)
			affixes_done += 1
		elif action_type == "turn_page":
			AIStateSimulator.apply_turn_page_action(state, player_id)
		elif action_type == "place_crown":
			AIStateSimulator.apply_place_crown_action(state, player_id, action)
	return state

func score_hard_tactical_rules_for_plan(game_state: GameStateData, player_id: int, plan: Dictionary, board_size: int) -> float:
	if game_state == null or plan.is_empty():
		return 0.0

	var simulated_state: GameStateData = context.get_simulated_turn_plan_state(game_state, player_id, plan, board_size)
	# A finished game has no next turn to defend: without this, a winning plan
	# would still be charged for the base threat the opponent never gets to use,
	# and a win by leaving the opponent without a legal action would go unseen.
	if simulated_state.game_over:
		return context.get_terminal_score_for_player(simulated_state, player_id)

	var score: float = 0.0
	if context.sees_threats_this_turn:
		var opponent_player_id: int = 1 - player_id
		var opponent_had_immediate_base_win: bool = has_immediate_base_win(game_state, opponent_player_id, board_size)
		var opponent_has_immediate_base_win_after: bool = has_immediate_base_win(simulated_state, opponent_player_id, board_size)
		if opponent_had_immediate_base_win:
			score += SCORE_EMERGENCY_PREVENT_BASE_WIN if !opponent_has_immediate_base_win_after else -PENALTY_ALLOW_IMMEDIATE_BASE_WIN
		elif opponent_has_immediate_base_win_after:
			score -= PENALTY_ALLOW_IMMEDIATE_BASE_WIN

	if context.sees_threats_this_turn:
		score += score_move_base_piece_escape_rule(game_state, simulated_state, player_id, plan, board_size)
	score += score_material_advantage_finish_rule(game_state, simulated_state, player_id, board_size)
	score += score_move_off_enemy_base_rule(game_state, player_id, plan)
	return score

func score_material_advantage_finish_rule(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	board_size: int
) -> float:
	# Golem counts hardly ever differ (captured golems respawn), so the lead is
	# measured in what each side can still do - see get_resource_advantage.
	var resource_advantage: float = AIStrategyDirector.get_resource_advantage(before_state, player_id)
	if resource_advantage < RESOURCE_ADVANTAGE_FOR_FINISH and effect_scoring.count_usable_golems(before_state, 1 - player_id) > ENEMY_USABLE_GOLEMS_FOR_FINISH:
		return 0.0
	# In golem-sized units, the scale the bonus below was tuned for.
	var material_advantage: int = int(floor(resource_advantage / AIStrategyDirector.RESOURCE_WEIGHT_USABLE_GOLEM))

	# Ahead, the crown is what turns the lead into a win: push it harder.
	var score: float = crown_race.get_crown_race_value_delta(before_state, after_state, player_id, board_size) * 0.8
	score += float(maxi(0, material_advantage)) * SCORE_MATERIAL_ADVANTAGE_FINISH
	return score

func score_move_base_piece_escape_rule(
	before_state: GameStateData,
	after_state: GameStateData,
	player_id: int,
	plan: Dictionary,
	board_size: int
) -> float:
	var before_risk: float = score_move_base_piece_crown_risk(before_state, player_id, board_size)
	if before_risk <= 0.0:
		return 0.0

	var after_risk: float = score_move_base_piece_crown_risk(after_state, player_id, board_size)
	var score: float = (before_risk - after_risk) * SCORE_MOVE_BASE_PIECE_ESCAPE
	if after_risk >= before_risk:
		score -= PENALTY_MOVE_BASE_PIECE_THREATENED

	var move: Dictionary = plan.get("move", {})
	if !move.is_empty():
		var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
		var moving_piece: Piece = before_state.get_piece(from_pos)
		if is_move_base_piece(moving_piece):
			score += SCORE_MOVE_BASE_PIECE_ESCAPE * 0.75
	return score

## How close the enemy's crowned golem is to the player's base-moving golems.
func score_move_base_piece_crown_risk(game_state: GameStateData, player_id: int, board_size: int) -> float:
	if game_state == null:
		return 0.0

	var opponent_player_id: int = 1 - player_id
	var bearer_pos: Vector2 = game_state.get_crowned_piece_position(opponent_player_id)
	if bearer_pos == INVALID_POS:
		return 0.0
	var bearer_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(
		game_state.pieces,
		bearer_pos,
		opponent_player_id,
		board_size,
		game_state.board_effects
	)

	var risk: float = 0.0
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var pos: Vector2 = StampEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or !is_move_base_piece(piece):
			continue

		if bearer_moves.has(pos):
			risk += 3.0
			continue

		var bearer_distance: float = AIBoardMath.get_manhattan_distance(bearer_pos, pos)
		if bearer_distance <= 1.0:
			risk += 2.0
		elif bearer_distance <= 2.0:
			risk += 1.0
	return risk

func is_move_base_piece(piece: Piece) -> bool:
	return piece != null and piece.affixed_stamp != null and piece.affixed_stamp.effect_type == StampEffect.TYPE_MOVE_BASE

func score_move_off_enemy_base_rule(game_state: GameStateData, player_id: int, plan: Dictionary) -> float:
	var move: Dictionary = plan.get("move", {})
	if move.is_empty():
		return 0.0

	var from_pos: Vector2 = AIStateSimulator.get_move_from(move)
	var to_pos: Vector2 = AIStateSimulator.get_move_to(move)
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	if from_pos != opponent_base or to_pos == opponent_base:
		return 0.0

	# A bearer crowned on the base has to step off and back on anyway.
	var moving_piece: Piece = game_state.get_piece(from_pos)
	if moving_piece != null and moving_piece.has_crown:
		return 0.0
	if crown_race.player_has_crown_plan(game_state, player_id):
		return SCORE_CLEAR_OWN_GOLEM_FROM_ENEMY_BASE
	return 0.0
