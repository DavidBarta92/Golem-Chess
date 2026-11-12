extends RefCounted
class_name AISeTenantScoring

## The Se-tenant set: what a set on the board is worth on its way to whole (a
## whole set keeps the crown meter full), how soon the codex can bring the
## stamps it still needs, and the affixes and page turns that help or hurt that.

## A Se-tenant set on its way counts this share less for every codex page the
## last stamp it still needs waits behind (get_se_tenant_arrival_weight).
const SE_TENANT_PAGE_WEIGHT: float = 0.8
## On top of the golem itself: taking the bearer takes the crown and its charge.
## A whole Se-tenant set on top of its full crown meter: no crown capture
## empties the meter, and it can move the crown every turn.
const SCORE_SE_TENANT_WHOLE_SET: float = 120.0
## A Se-tenant set not yet whole, by its golems on the board: the share of
## the way to a full meter it is worth (get_se_tenant_progress_value).
const SE_TENANT_PROGRESS_SHARES: Array[float] = [0.0, 0.1, 0.3]
## While the set can still be made whole (get_se_tenant_build_value): each of
## its golems on the board, and each stamp it still needs that waits in the
## codex or is on its way from a grant, by how soon it comes.
const SCORE_SE_TENANT_SET_GOLEM: float = 90.0
const SCORE_SE_TENANT_SET_SOURCE: float = 30.0
## A grant that glues a Se-tenant into the player's own codex while the set is
## not whole, on top of what any new stamp is worth, by how near the open page
## it lands (AIEffectScoring.score_grant_stamp_effect); and putting on the stamp that grants
## it, so those go on first (score_se_tenant_grant_affix).
const SCORE_SE_TENANT_GRANT: float = 60.0
const SCORE_SE_TENANT_GRANT_AFFIX: float = 30.0
## Turning the page away from a Se-tenant the set needs: it waits a whole
## round of the codex, while putting it on (and so emptying the page) would
## open the next page at the next turn's start anyway (score_se_tenant_page_turn).
const PENALTY_SE_TENANT_LEFT_BEHIND: float = 60.0
const CAPTURE_CONTACT_CHANCE: float = AIReach.CAPTURE_CONTACT_CHANCE
const INVALID_POS: Vector2 = AIScoringContext.INVALID_POS
const SCORE_CROWN_POINT: float = AIReach.SCORE_CROWN_POINT

var context: AIScoringContext
var reach: AIReach
var se_tenant_sources_cache: Dictionary = {}

func _init(new_context: AIScoringContext, new_reach: AIReach) -> void:
	context = new_context
	reach = new_reach

## How the affix moves the player's Se-tenant set: a Se-tenant stamp put on,
## or one covered by an Overseal. Full plan scoring sees this through the crown
## race; ranking affixes and the fast scores need it spelled out.
func score_se_tenant_affix(game_state: GameStateData, player_id: int, affix_action: Dictionary) -> float:
	var piece: Piece = game_state.get_piece(StampEffectResolver.as_vector2(affix_action.get("piece_pos", INVALID_POS), INVALID_POS))
	if piece == null:
		return 0.0
	var stamp: Stamp = affix_action.get("stamp", null) as Stamp
	if stamp == null:
		stamp = context.get_cached_stamp(str(affix_action.get("stamp_name", "")))
	var delta: int = int(MoveRules.is_se_tenant_stamp(stamp)) - int(MoveRules.is_se_tenant_stamp(piece.affixed_stamp))
	return score_se_tenant_change(game_state, player_id, delta)

## A whole Se-tenant set keeps the crown meter full; this is what the player's
## standing gains (or loses) with delta Se-tenant golems more on the board.
## Losing one from a whole set drops the meter to 0.
func score_se_tenant_change(game_state: GameStateData, player_id: int, delta: int) -> float:
	if game_state == null or delta == 0:
		return 0.0
	var golem_count: int = game_state.count_se_tenant_golems(player_id)
	var set_size: int = GameStateData.SE_TENANT_SET_SIZE
	var points_value: float = float(int(game_state.crown_points.get(player_id, 0))) * SCORE_CROWN_POINT
	var full_meter_value: float = reach.get_crown_hold_value() + get_se_tenant_progress_value(game_state, player_id, set_size)
	var before: float = full_meter_value if golem_count >= set_size else points_value + get_se_tenant_progress_value(game_state, player_id, golem_count)
	var after_count: int = maxi(0, golem_count + delta)
	var after: float = 0.0
	if after_count >= set_size:
		after = full_meter_value
	elif golem_count >= set_size:
		after = get_se_tenant_progress_value(game_state, player_id, after_count)
	else:
		after = points_value + get_se_tenant_progress_value(game_state, player_id, after_count)
	return after - before

## A Se-tenant set on its way: its share of filling the crown meter for good,
## while the codex still holds the stamps to finish it. A whole set is worth
## SCORE_SE_TENANT_WHOLE_SET on top of its full meter: no crown capture
## empties it, and it can move the crown every turn. With the crown already on
## the board a full meter only moves it, so then that is all the set is on
## its way to. Both on top of what its golems and stamps are worth as they
## build up (get_se_tenant_build_value).
func get_se_tenant_progress_value(game_state: GameStateData, player_id: int, golem_count: int) -> float:
	var set_size: int = GameStateData.SE_TENANT_SET_SIZE
	var build_value: float = get_se_tenant_build_value(game_state, player_id, golem_count)
	if golem_count >= set_size:
		return SCORE_SE_TENANT_WHOLE_SET + build_value
	if golem_count <= 0:
		return build_value
	var arrival_weight: float = get_se_tenant_arrival_weight(game_state, player_id, set_size - golem_count)
	if arrival_weight <= 0.0:
		return build_value
	var share: float = SE_TENANT_PROGRESS_SHARES[mini(golem_count, SE_TENANT_PROGRESS_SHARES.size() - 1)] * arrival_weight
	if game_state.has_crown_on_board(player_id):
		return SCORE_SE_TENANT_WHOLE_SET * share + build_value
	var points_value: float = float(int(game_state.crown_points.get(player_id, 0))) * SCORE_CROWN_POINT
	return maxf(0.0, reach.get_crown_hold_value() - points_value) * share + build_value

## A set the codex can still finish: SCORE_SE_TENANT_SET_GOLEM for each of its
## golems on the board, and SCORE_SE_TENANT_SET_SOURCE for each stamp it still
## needs, by how soon that comes (get_se_tenant_sources); a whole set its three
## golems. It is what makes the AI put a Se-tenant on as soon as it has one -
## even the first of the set - bring its page round, run out the stamps that
## grant them and have a free slot on the open page for what they grant.
func get_se_tenant_build_value(game_state: GameStateData, player_id: int, golem_count: int) -> float:
	if !game_state.has_codex_for_player(player_id):
		return 0.0
	var missing: int = GameStateData.SE_TENANT_SET_SIZE - golem_count
	if missing <= 0:
		return float(GameStateData.SE_TENANT_SET_SIZE) * SCORE_SE_TENANT_SET_GOLEM
	var sources: Array[float] = get_se_tenant_sources(game_state, player_id)
	if sources.size() < missing:
		return 0.0
	var value: float = float(golem_count) * SCORE_SE_TENANT_SET_GOLEM
	for source_index in range(missing):
		value += sources[source_index] * SCORE_SE_TENANT_SET_SOURCE
	return value

## Whether the Se-tenant golems on the board and the stamps on their way
## (get_se_tenant_sources) are enough for a whole set.
func can_complete_se_tenant_set(game_state: GameStateData, player_id: int) -> bool:
	if !game_state.has_codex_for_player(player_id):
		return false
	return game_state.count_se_tenant_golems(player_id) + get_se_tenant_sources(game_state, player_id).size() >= GameStateData.SE_TENANT_SET_SIZE

## How soon the codex brings the missing Se-tenant stamps of a set: 1 when they
## are all on the open page, less the further off the last of them is (see
## get_se_tenant_sources), 0 when the codex does not hold enough. Without a
## codex the hand and the deck count, all at once.
func get_se_tenant_arrival_weight(game_state: GameStateData, player_id: int, missing: int) -> float:
	if missing <= 0:
		return 1.0
	if !game_state.has_codex_for_player(player_id):
		var found: int = 0
		for zone in [game_state.player_hands, game_state.player_decks]:
			for stamp_name_value in zone.get(player_id, []):
				if MoveRules.is_se_tenant_stamp(context.get_cached_stamp(str(stamp_name_value))):
					found += 1
		return 1.0 if found >= missing else 0.0

	var sources: Array[float] = get_se_tenant_sources(game_state, player_id)
	return sources[missing - 1] if sources.size() >= missing else 0.0

## How soon each Se-tenant stamp the player's set can still draw on comes, best
## first - each SE_TENANT_PAGE_WEIGHT less for every turn it is off:
## - one in the codex: a turn for each page turn to it;
## - one on its way from a grant (get_granted_se_tenant_stamp): on a golem, the
##   steps until its stamp runs out, one for each step it has left for a grant
##   on a step, or for a grant on a capture one turn at the chance of a capture
##   in the steps it has left; in the codex, the page turns to the granting
##   stamp and the steps it then needs (CAPTURE_CONTACT_CHANCE for a capture).
##   Both also by the page the new stamp lands on (get_codex_landing_weight),
##   and nothing with the codex full.
func get_se_tenant_sources(game_state: GameStateData, player_id: int) -> Array[float]:
	var cache_key: String = "%s|p%d" % [context.get_state_hash(game_state), player_id]
	if se_tenant_sources_cache.has(cache_key):
		return se_tenant_sources_cache[cache_key]

	var sources: Array[float] = []
	var landing_weight: float = get_codex_landing_weight(game_state, player_id, false)
	var open_index: int = get_effective_open_page_index(game_state, player_id)
	var pages: Array = game_state.get_codex_pages(player_id)
	for page_index in range(pages.size()):
		if !(pages[page_index] is Array):
			continue
		var page_turns: int = get_codex_page_distance(game_state, player_id, open_index, page_index)
		for stamp_name_value in pages[page_index]:
			var stamp: Stamp = context.get_cached_stamp(str(stamp_name_value))
			if MoveRules.is_se_tenant_stamp(stamp):
				sources.append(pow(SE_TENANT_PAGE_WEIGHT, page_turns))
			elif landing_weight > 0.0 and get_granted_se_tenant_stamp(stamp, player_id) != null:
				var weight: float = 0.0
				match stamp.effect_trigger:
					StampEffect.TRIGGER_ON_AFFIX:
						weight = pow(SE_TENANT_PAGE_WEIGHT, page_turns)
					StampEffect.TRIGGER_ON_MOVE:
						for step in range(1, get_grant_step_count(stamp, stamp.duration)):
							append_se_tenant_grant_source(sources, stamp, pow(SE_TENANT_PAGE_WEIGHT, page_turns + step) * landing_weight)
						weight = pow(SE_TENANT_PAGE_WEIGHT, page_turns + get_grant_step_count(stamp, stamp.duration))
					StampEffect.TRIGGER_ON_EXPIRE:
						if stamp.duration > 0:
							weight = pow(SE_TENANT_PAGE_WEIGHT, page_turns + stamp.duration)
					StampEffect.TRIGGER_ON_CAPTURE:
						weight = CAPTURE_CONTACT_CHANCE * pow(SE_TENANT_PAGE_WEIGHT, page_turns + 1)
				append_se_tenant_grant_source(sources, stamp, weight * landing_weight)

	if landing_weight > 0.0:
		var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
		for position_value in game_state.pieces:
			var piece: Piece = game_state.pieces[position_value] as Piece
			if piece == null or piece.color != player_color or get_granted_se_tenant_stamp(piece.affixed_stamp, player_id) == null:
				continue
			var stamp: Stamp = piece.affixed_stamp
			var weight: float = 0.0
			match stamp.effect_trigger:
				StampEffect.TRIGGER_ON_MOVE:
					for step in range(1, get_grant_step_count(stamp, piece.turns_remaining)):
						append_se_tenant_grant_source(sources, stamp, pow(SE_TENANT_PAGE_WEIGHT, step) * landing_weight)
					weight = pow(SE_TENANT_PAGE_WEIGHT, get_grant_step_count(stamp, piece.turns_remaining))
				StampEffect.TRIGGER_ON_EXPIRE:
					if stamp.duration > 0:
						weight = pow(SE_TENANT_PAGE_WEIGHT, maxi(1, piece.turns_remaining))
				StampEffect.TRIGGER_ON_CAPTURE:
					var capture_chance: float = minf(1.0, reach.get_expected_captures(game_state, player_id, stamp, StampEffectResolver.as_vector2(position_value, INVALID_POS), piece.turns_remaining))
					weight = capture_chance * SE_TENANT_PAGE_WEIGHT
			append_se_tenant_grant_source(sources, stamp, weight * landing_weight)

	sources.sort()
	sources.reverse()
	se_tenant_sources_cache[cache_key] = sources
	return sources

## The steps a stamp that grants on each step still has to do it: the ones it
## has left, at most SE_TENANT_SET_SIZE, as more cannot add to one set.
func get_grant_step_count(stamp: Stamp, steps_left: int) -> int:
	if stamp.duration < 0:
		return GameStateData.SE_TENANT_SET_SIZE
	return clampi(steps_left, 1, GameStateData.SE_TENANT_SET_SIZE)

func append_se_tenant_grant_source(sources: Array[float], stamp: Stamp, weight: float) -> void:
	if weight <= 0.0:
		return
	for _copy in range(maxi(1, int(stamp.effect_settings.get("amount", 1)))):
		sources.append(weight)

## The Se-tenant stamp this stamp's grant glues into the player's own codex
## (Advocate a Sun, Consul a Moon, Logician a Bicycle), or null.
func get_granted_se_tenant_stamp(stamp: Stamp, player_id: int) -> Stamp:
	if stamp == null or !stamp.has_effect() or stamp.effect_type != StampEffect.TYPE_GRANT_STAMP:
		return null
	if int(stamp.effect_settings.get("target_player_id", player_id)) != player_id:
		return null
	var granted_stamp: Stamp = context.get_cached_stamp(str(stamp.effect_settings.get("stamp_name", stamp.stamp_name)))
	return granted_stamp if MoveRules.is_se_tenant_stamp(granted_stamp) else null

## Turning the page while the open page holds Se-tenant stamps the set still
## needs: PENALTY_SE_TENANT_LEFT_BEHIND for each, up to the number missing.
func score_se_tenant_page_turn(game_state: GameStateData, player_id: int) -> float:
	if !game_state.has_codex_for_player(player_id):
		return 0.0
	var missing: int = GameStateData.SE_TENANT_SET_SIZE - game_state.count_se_tenant_golems(player_id)
	if missing <= 0 or !can_complete_se_tenant_set(game_state, player_id):
		return 0.0
	var left_behind: int = 0
	for stamp_name_value in game_state.get_current_page(player_id):
		if MoveRules.is_se_tenant_stamp(context.get_cached_stamp(str(stamp_name_value))):
			left_behind += 1
	return -PENALTY_SE_TENANT_LEFT_BEHIND * float(mini(left_behind, missing))

## Putting on a stamp that grants a Se-tenant while the set can still be made
## whole: it starts that stamp on its way, so these go on first.
func score_se_tenant_grant_affix(game_state: GameStateData, player_id: int, stamp: Stamp) -> float:
	if get_granted_se_tenant_stamp(stamp, player_id) == null:
		return 0.0
	if game_state.count_se_tenant_golems(player_id) >= GameStateData.SE_TENANT_SET_SIZE or !can_complete_se_tenant_set(game_state, player_id):
		return 0.0
	return SCORE_SE_TENANT_GRANT_AFFIX

## The page the codex is open on at the player's next turn: the open one, or -
## when that is empty - the next one that is not, which the turn's start turns
## to (GameStateData.reset_turn_page_state).
func get_effective_open_page_index(game_state: GameStateData, player_id: int) -> int:
	var current_index: int = game_state.get_current_page_index(player_id)
	if game_state.has_stamps_on_page(player_id, current_index):
		return current_index
	var next_index: int = game_state.find_next_non_empty_page(player_id, current_index)
	return next_index if next_index != -1 else current_index

## Page turns from one page to another: one for each page with stamps on the
## way, as empty pages are passed over.
func get_codex_page_distance(game_state: GameStateData, player_id: int, from_index: int, to_index: int) -> int:
	var page_turns: int = 0
	var page_index: int = from_index
	for _step in range(DeckManager.CODEX_PAGE_COUNT):
		if page_index == to_index:
			break
		if game_state.has_stamps_on_page(player_id, page_index):
			page_turns += 1
		page_index = (page_index + 1) % DeckManager.CODEX_PAGE_COUNT
	return page_turns

## How soon a stamp glued into the codex comes up: SE_TENANT_PAGE_WEIGHT less
## for each page turn to the nearest free slot, where it lands
## (GameStateData.add_stamp_to_nearest_free_slot), 0 with the codex full. A
## grant that goes off now lands on the open page if it has room - an emptied
## one then stays open - one later from the page open by then.
func get_codex_landing_weight(game_state: GameStateData, player_id: int, goes_off_now: bool) -> float:
	var pages: Array = game_state.get_codex_pages(player_id)
	var start_index: int = game_state.get_current_page_index(player_id) if goes_off_now else get_effective_open_page_index(game_state, player_id)
	for offset in range(DeckManager.CODEX_PAGE_COUNT):
		var page_index: int = (start_index + offset) % DeckManager.CODEX_PAGE_COUNT
		if page_index >= pages.size():
			continue
		var page_size: int = (pages[page_index] as Array).size() if pages[page_index] is Array else 0
		if page_size < DeckManager.CODEX_STAMPS_PER_PAGE:
			return pow(SE_TENANT_PAGE_WEIGHT, get_codex_page_distance(game_state, player_id, start_index, page_index))
	return 0.0

## A move after which the golem's Se-tenant stamp runs out.
func is_se_tenant_expiring_move(moving_piece: Piece, move: Dictionary) -> bool:
	return moving_piece != null \
		and !bool(move.get("requires_affix", false)) \
		and MoveRules.is_se_tenant_stamp(moving_piece.affixed_stamp) \
		and moving_piece.turns_remaining == 1
