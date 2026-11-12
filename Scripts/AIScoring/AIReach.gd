extends RefCounted
class_name AIReach

## Where a stamped golem can get to: its route onto the enemy base and the own
## turns that takes, the squares the enemy can take, and the captures a stamp can
## expect in its next steps. Also what a crown on such a route is worth, which the
## crown race (AICrownRace) and the Se-tenant set (AISeTenantScoring) build on.
## The route and capture maps depend on the stamp, the side and the square, not
## on the turn, so they stay cached for the evaluator's life.

## An on_capture effect put on a golem counts for the captures it can expect
## (get_expected_captures): each turn, every enemy golem it could take by then
## is a chance of this much, and each later turn counts this share of the one
## before. Looked at for at most this many of the stamp's steps.
const CAPTURE_CONTACT_CHANCE: float = 0.4
const CAPTURE_CONTACT_TURN_DECAY: float = 0.8
const CAPTURE_CONTACT_MAX_STEPS: int = 4
## The crown race (AICrownRace.get_crown_race_value): what a point on the meter, a crown on
## the board, and each own turn fewer its bearer needs to reach the enemy base
## are worth. Route bonuses count down from CROWN_ROUTE_HORIZON turns out.
const SCORE_CROWN_POINT: float = 40.0
const SCORE_CROWN_ON_BOARD: float = 320.0
const SCORE_CROWN_ROUTE_STEP: float = 140.0
const CROWN_ROUTE_HORIZON: int = 6
## A charged crown held back is worth a crown on a golem this many turns from
## the base (see get_crown_hold_value): crowning a golem farther out loses
## value, a nearer one gains.
const CROWN_HOLD_ROUTE_TURNS: int = 3
const MAX_BASE_ROUTE_DISTANCE: int = 8
## What a step on the way to the base counts for (see get_base_route_map): a
## move-and-capture step works whatever stands there, a move-only one needs the
## square empty, and a capture-only one needs an enemy golem standing just there.
const ROUTE_COST_MOVE_AND_CAPTURE: float = 1.0
const ROUTE_COST_MOVE_ONLY: float = 1.25
const ROUTE_COST_CAPTURE_ONLY: float = 4.0
const NO_BASE_ROUTE: Vector2 = Vector2(-1, -1)
## What a stamp running out on the way adds to a route, in own turns: the golem
## stands bare until a stamp comes, and that stamp has to fit the square it
## stopped on.
const ROUTE_TURNS_STAMP_RUNS_OUT: float = 2.0
const INVALID_POS: Vector2 = AIScoringContext.INVALID_POS

var context: AIScoringContext
var base_route_cache: Dictionary = {}
var capture_reach_cache: Dictionary = {}

func _init(new_context: AIScoringContext) -> void:
	context = new_context

## The route onto the enemy base as Vector2(cost, steps), NO_BASE_ROUTE when there
## is none. See get_base_route_map.
func get_base_route(game_state: GameStateData, player_id: int, stamp: Stamp, from_pos: Vector2, board_size: int) -> Vector2:
	if game_state == null or stamp == null:
		return NO_BASE_ROUTE
	return get_base_route_map(game_state, player_id, stamp, board_size).get(from_pos, NO_BASE_ROUTE)

func get_route_step_cost(movement_type: int) -> float:
	match movement_type:
		StampEffect.MOVEMENT_MOVE_ONLY:
			return ROUTE_COST_MOVE_ONLY
		StampEffect.MOVEMENT_CAPTURE_ONLY:
			return ROUTE_COST_CAPTURE_ONLY
	return ROUTE_COST_MOVE_AND_CAPTURE

## The cheapest route from each square onto the enemy base for a golem carrying
## this stamp, keyed by square, as Vector2(cost, steps). The steps on the way
## follow the stamp's cells and ignore the pieces in the way, which come and go,
## so a cell counts for how far it can be relied on (ROUTE_COST_*). The last step
## onto the base follows the movement rules for whatever stands there now (see
## can_stamp_enter_base_from), so it costs 1 whatever its cell. So the map
## depends only on the stamp, the side, the base and its occupant, and stays
## cached from turn to turn.
func get_base_route_map(game_state: GameStateData, player_id: int, stamp: Stamp, board_size: int) -> Dictionary:
	var opponent_base: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var base_piece: Piece = game_state.get_piece(opponent_base)
	var cache_key: String = "%s|c%d|base%s|%s" % [
		stamp.stamp_name,
		player_color,
		context.vector_hash(opponent_base),
		get_base_occupant_key(base_piece, player_color),
	]
	if base_route_cache.has(cache_key):
		return base_route_cache[cache_key]

	var route_map: Dictionary = {}
	var predecessors: Dictionary = {}
	var open_routes: Dictionary = {}
	for x in range(board_size):
		for y in range(board_size):
			var square: Vector2 = Vector2(x, y)
			if can_stamp_enter_base_from(base_piece, player_color, stamp, square, opponent_base):
				open_routes[square] = Vector2(1.0, 1.0)
			for movement_option: Dictionary in stamp.get_movement_options():
				var offset: Vector2 = movement_option.get("offset", Vector2.ZERO)
				var next_square: Vector2 = square + offset * player_color
				if next_square == square or next_square == opponent_base or !MoveRules.is_valid_position(next_square, board_size):
					continue
				if !predecessors.has(next_square):
					predecessors[next_square] = []
				predecessors[next_square].append({
					"square": square,
					"cost": get_route_step_cost(int(movement_option.get("movement_type", StampEffect.MOVEMENT_MOVE_AND_CAPTURE))),
				})

	while !open_routes.is_empty():
		var target: Vector2 = get_cheapest_route_square(open_routes)
		var route: Vector2 = open_routes[target]
		open_routes.erase(target)
		route_map[target] = route
		if int(route.y) >= MAX_BASE_ROUTE_DISTANCE:
			continue
		for link: Dictionary in predecessors.get(target, []):
			var square: Vector2 = link["square"]
			if route_map.has(square):
				continue
			var cost: float = route.x + float(link["cost"])
			if !open_routes.has(square) or cost < Vector2(open_routes[square]).x:
				open_routes[square] = Vector2(cost, route.y + 1.0)

	base_route_cache[cache_key] = route_map
	return route_map

func get_cheapest_route_square(routes: Dictionary) -> Vector2:
	var best_square: Vector2 = INVALID_POS
	var best_cost: float = INF
	for square: Vector2 in routes:
		var cost: float = Vector2(routes[square]).x
		if cost < best_cost:
			best_cost = cost
			best_square = square
	return best_square

func get_base_occupant_key(base_piece: Piece, player_color: int) -> String:
	if base_piece == null:
		return "empty"
	if base_piece.color == player_color:
		return "own"
	return "enemy" if MoveRules.can_capture_target_piece(base_piece, player_color) else "guarded"

## The last step onto the base follows the movement rules exactly: a move-only
## step cannot enter an occupied base, a capture-only one only by taking a
## piece that stands there, and nothing enters over a golem of its own side.
## That is what makes a golem parked on its own base a wall against some
## stamps, and an empty base a wall against others.
func can_stamp_enter_base_from(base_piece: Piece, player_color: int, stamp: Stamp, candidate_pos: Vector2, base_pos: Vector2) -> bool:
	for movement_option: Dictionary in stamp.get_movement_options():
		var offset: Vector2 = movement_option.get("offset", Vector2.ZERO)
		if candidate_pos + offset * player_color != base_pos:
			continue
		var movement_type: int = int(movement_option.get("movement_type", StampEffect.MOVEMENT_MOVE_AND_CAPTURE))
		if MoveRules.is_target_allowed_by_movement_type(base_piece, player_color, movement_type):
			return true
	return false

## A charged crown not yet down is worth as much as a crown on a golem
## CROWN_HOLD_ROUTE_TURNS from the base - less for a more aggressive AI, which
## so crowns golems farther out.
func get_crown_hold_value() -> float:
	return SCORE_CROWN_ON_BOARD + get_crown_route_bonus(CROWN_HOLD_ROUTE_TURNS) - context.aggression * SCORE_CROWN_ROUTE_STEP

func get_crown_route_bonus(route_turns: float) -> float:
	if route_turns < 0.0:
		return 0.0
	return maxf(0.0, float(CROWN_ROUTE_HORIZON) - route_turns) * SCORE_CROWN_ROUTE_STEP

## Own turns the golem needs to step onto the enemy base, as far as the route can
## be relied on (see get_base_route_map): with the stamp it carries while that
## lasts (ROUTE_TURNS_STAMP_RUNS_OUT more if it runs out on the way), or for a
## bare golem a turn to be stamped first, with the best stamp on the open codex
## page. -1 when no route is in sight.
func get_golem_route_turns(game_state: GameStateData, player_id: int, piece_pos: Vector2, board_size: int) -> float:
	var piece: Piece = game_state.get_piece(piece_pos)
	if piece == null or piece.is_respawn_locked():
		return -1.0
	if piece.affixed_stamp != null:
		var carried_route: Vector2 = get_base_route(game_state, player_id, piece.affixed_stamp, piece_pos, board_size)
		if carried_route.y < 0.0:
			return -1.0
		if !stamp_outlasts_route(piece.affixed_stamp, piece.turns_remaining, int(carried_route.y)):
			return carried_route.x + ROUTE_TURNS_STAMP_RUNS_OUT
		return carried_route.x

	var best_turns: float = -1.0
	for stamp: Stamp in get_open_page_stamps(game_state, player_id):
		var route: Vector2 = get_base_route(game_state, player_id, stamp, piece_pos, board_size)
		if route.y < 0.0:
			continue
		var turns: float = route.x + 1.0
		if !stamp_outlasts_route(stamp, stamp.duration if stamp.duration == -1 else maxi(1, stamp.duration), int(route.y)):
			turns += ROUTE_TURNS_STAMP_RUNS_OUT
		if best_turns < 0.0 or turns < best_turns:
			best_turns = turns
	return best_turns

## Whether the stamp lasts a route of this many steps: on the turns it has left
## (-1 never runs out), or because a plain step costs it nothing (Cherry tree).
func stamp_outlasts_route(stamp: Stamp, turns_left: int, steps: int) -> bool:
	if turns_left == -1 or steps <= turns_left:
		return true
	return stamp.effect_type == StampEffect.TYPE_INCREASE_SELF_DURATION and stamp.effect_trigger == StampEffect.TRIGGER_ON_MOVE

func get_open_page_stamps(game_state: GameStateData, player_id: int) -> Array[Stamp]:
	var stamps: Array[Stamp] = []
	var seen: Dictionary = {}
	for stamp_name_value in game_state.player_hands.get(player_id, []):
		var stamp_name: String = str(stamp_name_value)
		if seen.has(stamp_name):
			continue
		seen[stamp_name] = true
		var stamp: Stamp = context.get_cached_stamp(stamp_name)
		if stamp != null and MoveRules.stamp_can_be_used(stamp):
			stamps.append(stamp)
	return stamps

func is_square_attacked_by(game_state: GameStateData, attacker_player_id: int, square: Vector2, board_size: int) -> bool:
	var valid_moves: Array[Dictionary] = MoveRules.get_existing_stamp_moves(
		game_state.pieces,
		StampEffectResolver.get_color_for_player_id(attacker_player_id),
		board_size,
		game_state.board_effects
	)
	for move: Dictionary in valid_moves:
		if AIStateSimulator.get_move_to(move) == square:
			return true
	return false

## The captures a golem with this stamp on this square can expect in its next
## steps_left steps. On each of its turns, every enemy golem it could take by
## then is a CAPTURE_CONTACT_CHANCE chance of one capture, and each later turn
## counts CAPTURE_CONTACT_TURN_DECAY of the one before: the enemy moves too, and
## the golem need not move every turn. So a stamp put on far from the enemy, as
## in the opening, expects little, and one put on in the thick of it a lot.
func get_expected_captures(game_state: GameStateData, player_id: int, stamp: Stamp, pos: Vector2, steps_left: int) -> float:
	if stamp.duration < 0:
		steps_left = CAPTURE_CONTACT_MAX_STEPS
	steps_left = mini(steps_left, CAPTURE_CONTACT_MAX_STEPS)
	if steps_left <= 0:
		return 0.0

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var reach_map: Dictionary = get_capture_reach_map(stamp, player_color, pos, steps_left, BoardConfig.BOARD_SIZE)
	var targets_by_step: Array[int] = []
	targets_by_step.resize(steps_left + 1)
	for position_value in game_state.pieces:
		var target: Piece = game_state.pieces[position_value] as Piece
		if !MoveRules.can_capture_target_piece(target, player_color):
			continue
		var reach_step: int = int(reach_map.get(StampEffectResolver.as_vector2(position_value, INVALID_POS), 0))
		if reach_step > 0:
			targets_by_step[reach_step] += 1

	var expected: float = 0.0
	var turn_weight: float = 1.0
	var targets_in_reach: int = 0
	for step in range(1, steps_left + 1):
		targets_in_reach += targets_by_step[step]
		expected += (1.0 - pow(1.0 - CAPTURE_CONTACT_CHANCE, targets_in_reach)) * turn_weight
		turn_weight *= CAPTURE_CONTACT_TURN_DECAY
	return expected

## Square -> the step on which a golem with this stamp, from this square, could
## first capture there, within max_steps steps. The steps on the way follow
## the stamp's non-capturing offsets and ignore what stands in the way, so the
## map depends only on the stamp, the side and the square, and stays cached.
func get_capture_reach_map(stamp: Stamp, player_color: int, from_pos: Vector2, max_steps: int, board_size: int) -> Dictionary:
	var cache_key: String = "%s|c%d|%s|%d" % [stamp.stamp_name, player_color, context.vector_hash(from_pos), max_steps]
	if capture_reach_cache.has(cache_key):
		return capture_reach_cache[cache_key]

	var walk_offsets: Array[Vector2] = []
	var capture_offsets: Array[Vector2] = []
	for movement_option: Dictionary in stamp.get_movement_options():
		var offset: Vector2 = movement_option.get("offset", Vector2.ZERO) * player_color
		var movement_type: int = int(movement_option.get("movement_type", StampEffect.MOVEMENT_NONE))
		if movement_type != StampEffect.MOVEMENT_CAPTURE_ONLY:
			walk_offsets.append(offset)
		if movement_type != StampEffect.MOVEMENT_MOVE_ONLY:
			capture_offsets.append(offset)

	var reach_map: Dictionary = {}
	var visited: Dictionary = {from_pos: true}
	var frontier: Array[Vector2] = [from_pos]
	for step in range(1, max_steps + 1):
		var next_frontier: Array[Vector2] = []
		for square: Vector2 in frontier:
			for offset: Vector2 in capture_offsets:
				var target: Vector2 = square + offset
				if MoveRules.is_valid_position(target, board_size) and !reach_map.has(target):
					reach_map[target] = step
			if step == max_steps:
				continue
			for offset: Vector2 in walk_offsets:
				var next_square: Vector2 = square + offset
				if MoveRules.is_valid_position(next_square, board_size) and !visited.has(next_square):
					visited[next_square] = true
					next_frontier.append(next_square)
		frontier = next_frontier

	capture_reach_cache[cache_key] = reach_map
	return reach_map
