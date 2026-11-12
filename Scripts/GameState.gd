# GameState.gd - Shared game state data, not an autoload.
class_name GameStateData

var pieces: Dictionary = {}  # Vector2 -> Piece
var player_decks: Dictionary = {}  # int (player_id) -> Array[String] (stamp names)
var player_initial_decks: Dictionary = {}  # int (player_id) -> Array[String] (full starting deck order)
var player_hands: Dictionary = {}  # int (player_id) -> Array[String] (stamp names)
var player_codex_pages: Dictionary = {
	0: [],
	1: [],
}
var current_page_index: Dictionary = {
	0: 0,
	1: 0,
}
var has_turned_page_this_turn: Dictionary = {
	0: false,
	1: false,
}
var spent_stamps: Dictionary = {
	0: [],
	1: [],
}
var current_turn_player: int = 0  # 0 = white, 1 = black
var completed_turn_counts: Dictionary = {0: 0, 1: 0}
var player_clock_seconds: Dictionary = {0: 600.0, 1: 600.0}
## Crown points per player and the number a crown costs, copied from GameConfig
## when the match starts (begin_crown_points) so everything that reads or
## simulates this state - the host, the AI, a remote client - uses the same rule.
var crown_points: Dictionary = {0: 0, 1: 0}
var crown_points_required: int = 5
const SE_TENANT_SET_SIZE: int = 3
var crowned_this_turn: Dictionary = {0: false, 1: false}
## Whether the player's Se-tenant set (refresh_se_tenant_crown_points) was whole
## when last looked at, so its breaking can take the points back to 0.
var se_tenant_set_whole: Dictionary = {0: false, 1: false}
var player_base_fields: Dictionary = {
	0: BoardConfig.WHITE_BASE_FIELD,
	1: BoardConfig.BLACK_BASE_FIELD,
}
var board_effects: Array = []
var recent_stamp_transfers: Array = []
var recent_stamp_expirations: Array = []
var recent_bomb_effects: Array = []
var recent_effect_activations: Array = []
var recent_pending_respawn_queues: Array = []
var recent_pending_respawn_arrivals: Array = []
var last_move: Dictionary = {}
var pending_respawns: Dictionary = {
	0: [],
	1: [],
}
var affixed_stamp_this_turn: Dictionary = {
	0: false,
	1: false,
}
var affixed_stamp_count_this_turn: Dictionary = {
	0: 0,
	1: 0,
}
var moved_piece_this_turn: Dictionary = {
	0: false,
	1: false,
}
var exchanged_stamp_this_turn: Dictionary = {
	0: false,
	1: false,
}
var played_stamp_hand_slots_this_turn: Dictionary = {
	0: [],
	1: [],
}
var exchanged_stamp_names_this_turn: Dictionary = {
	0: [],
	1: [],
}
var game_over: bool = false
var winner_player: int = -1
var win_condition: String = ""
var match_logger: MatchCsvLogger = null

func get_piece(pos: Vector2) -> Piece:
	return pieces.get(pos)

func set_piece(pos: Vector2, piece: Piece):
	pieces[pos] = piece

func remove_piece(pos: Vector2):
	pieces.erase(pos)

func is_white_turn() -> bool:
	return current_turn_player == 0

func switch_turn():
	current_turn_player = 1 - current_turn_player
	affixed_stamp_this_turn[current_turn_player] = false
	affixed_stamp_count_this_turn[current_turn_player] = 0
	moved_piece_this_turn[current_turn_player] = false
	exchanged_stamp_this_turn[current_turn_player] = false
	played_stamp_hand_slots_this_turn[current_turn_player] = []
	exchanged_stamp_names_this_turn[current_turn_player] = []
	crowned_this_turn[current_turn_player] = false
	reset_turn_page_state(current_turn_player)
	gain_crown_point(current_turn_player)

## Starts both players' crown points: the second player gets their head start,
## and the player about to take the first turn gets that turn's point.
func begin_crown_points(points_required: int, second_player_head_start: int) -> void:
	crown_points_required = maxi(1, points_required)
	var first_player: int = current_turn_player
	crown_points = {
		first_player: 0,
		1 - first_player: clampi(second_player_head_start, 0, crown_points_required),
	}
	crowned_this_turn = {0: false, 1: false}
	se_tenant_set_whole = {0: false, 1: false}
	gain_crown_point(first_player)

## A point at the start of each of the player's turns, up to what a crown
## costs. It keeps coming while the crown is on the board: a full meter then
## moves the crown to another golem (place_crown).
func gain_crown_point(player_id: int) -> void:
	crown_points[player_id] = mini(crown_points_required, int(crown_points.get(player_id, 0)) + 1)

## Takes a point away (remove_enemy_crown_point), never below zero.
func remove_crown_point(player_id: int) -> void:
	crown_points[player_id] = maxi(0, int(crown_points.get(player_id, 0)) - 1)

## With Se-tenant stamps on at least SE_TENANT_SET_SIZE of a player's golems,
## their crown meter stays full. When the set breaks - a stamp captured, run
## out or covered - the meter drops to 0 and fills again turn by turn. The host
## and the AI call this after every affix and crowning, and before each turn's
## point.
func refresh_se_tenant_crown_points() -> void:
	for player_id in [0, 1]:
		if count_se_tenant_golems(player_id) >= SE_TENANT_SET_SIZE:
			se_tenant_set_whole[player_id] = true
			crown_points[player_id] = crown_points_required
		elif bool(se_tenant_set_whole.get(player_id, false)):
			se_tenant_set_whole[player_id] = false
			crown_points[player_id] = 0

func count_se_tenant_golems(player_id: int) -> int:
	var player_color: int = BoardConfig.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in pieces:
		var piece: Piece = pieces[position_value] as Piece
		if piece != null and piece.color == player_color and MoveRules.is_se_tenant_stamp(piece.affixed_stamp):
			count += 1
	return count

func has_crown_on_board(player_id: int) -> bool:
	return get_crowned_piece_position(player_id) != Vector2(-1, -1)

func get_crowned_piece_position(player_id: int) -> Vector2:
	var player_color: int = BoardConfig.get_color_for_player_id(player_id)
	for position_value in pieces:
		var piece: Piece = pieces[position_value] as Piece
		if piece != null and piece.color == player_color and piece.has_crown:
			return position_value
	return Vector2(-1, -1)

## Whether the player may crown a golem now: in their own turn, before moving,
## once a turn, with the points gathered. With their crown already on the
## board, this moves it to another golem.
func can_place_crown(player_id: int) -> bool:
	if game_over or current_turn_player != player_id:
		return false
	if bool(moved_piece_this_turn.get(player_id, false)) or bool(crowned_this_turn.get(player_id, false)):
		return false
	return int(crown_points.get(player_id, 0)) >= crown_points_required

## Any golem of the player's will do - bare, stamped, anywhere on the board -
## except one that is locked after a capture, and the one wearing the crown.
func can_crown_piece(player_id: int, piece_pos: Vector2) -> bool:
	if !can_place_crown(player_id):
		return false
	var piece: Piece = get_piece(piece_pos)
	if piece == null or piece.color != BoardConfig.get_color_for_player_id(player_id):
		return false
	return !piece.is_respawn_locked() and !piece.has_crown

## Crowns the golem: the points are spent, the crown leaves the golem that
## wore it, and the new one waits out the turn, like a golem that has just
## been stamped.
func place_crown(player_id: int, piece_pos: Vector2) -> bool:
	if !can_crown_piece(player_id, piece_pos):
		return false
	var previous_pos: Vector2 = get_crowned_piece_position(player_id)
	if previous_pos != Vector2(-1, -1):
		get_piece(previous_pos).has_crown = false
	var piece: Piece = get_piece(piece_pos)
	piece.has_crown = true
	piece.exhausted_this_turn = true
	crown_points[player_id] = 0
	crowned_this_turn[player_id] = true
	return true

func initialize_player_codex(player_id: int, stamp_names: Array) -> void:
	var normalized_names: Array[String] = []
	for stamp_name_value in stamp_names:
		if normalized_names.size() >= DeckManager.DECK_SIZE:
			break
		var stamp_name: String = str(stamp_name_value)
		if !stamp_name.is_empty():
			normalized_names.append(stamp_name)

	player_initial_decks[player_id] = normalized_names.duplicate()
	player_codex_pages[player_id] = DeckManager.create_codex_pages(normalized_names)
	current_page_index[player_id] = 0
	has_turned_page_this_turn[player_id] = false
	spent_stamps[player_id] = []
	sync_player_stamp_zones_from_codex(player_id)

func has_codex_for_player(player_id: int) -> bool:
	return player_codex_pages.has(player_id) and player_codex_pages[player_id] is Array and !(player_codex_pages[player_id] as Array).is_empty()

func get_current_page(player_id: int) -> Array:
	var pages: Array = get_codex_pages(player_id)
	var page_index: int = get_current_page_index(player_id)
	if page_index < 0 or page_index >= pages.size():
		return []
	var page = pages[page_index]
	return page if page is Array else []

func get_codex_pages(player_id: int) -> Array:
	if !player_codex_pages.has(player_id) or !(player_codex_pages[player_id] is Array):
		player_codex_pages[player_id] = DeckManager.create_codex_pages(player_initial_decks.get(player_id, []))
	return player_codex_pages[player_id]

func get_current_page_index(player_id: int) -> int:
	var page_index: int = int(current_page_index.get(player_id, 0))
	return clampi(page_index, 0, DeckManager.CODEX_PAGE_COUNT - 1)

func has_stamps_on_page(player_id: int, page_index: int) -> bool:
	var pages: Array = get_codex_pages(player_id)
	if page_index < 0 or page_index >= pages.size():
		return false
	var page = pages[page_index]
	return page is Array and !(page as Array).is_empty()

func can_turn_page(player_id: int) -> bool:
	if bool(has_turned_page_this_turn.get(player_id, false)):
		return false
	if bool(affixed_stamp_this_turn.get(player_id, false)) or bool(crowned_this_turn.get(player_id, false)):
		return false
	if count_non_empty_pages(player_id) <= 1:
		return false
	return find_next_non_empty_page(player_id, get_current_page_index(player_id)) != -1

func turn_page(player_id: int) -> bool:
	if !can_turn_page(player_id):
		return false
	var next_page_index: int = find_next_non_empty_page(player_id, get_current_page_index(player_id))
	if next_page_index == -1:
		return false
	current_page_index[player_id] = next_page_index
	has_turned_page_this_turn[player_id] = true
	sync_player_stamp_zones_from_codex(player_id)
	return true

func find_next_non_empty_page(player_id: int, start_index: int) -> int:
	for offset in range(1, DeckManager.CODEX_PAGE_COUNT + 1):
		var candidate_index: int = (start_index + offset) % DeckManager.CODEX_PAGE_COUNT
		if has_stamps_on_page(player_id, candidate_index):
			return candidate_index
	return -1

func get_upcoming_stamp_names_in_turn_order(player_id: int, max_count: int = -1) -> Array[String]:
	var stamp_names: Array[String] = []
	var pages: Array = get_codex_pages(player_id)
	var start_index: int = get_current_page_index(player_id)
	for offset in range(1, DeckManager.CODEX_PAGE_COUNT + 1):
		var page_index: int = (start_index + offset) % DeckManager.CODEX_PAGE_COUNT
		if page_index == start_index:
			break
		if page_index < 0 or page_index >= pages.size() or !(pages[page_index] is Array):
			continue
		for stamp_name_value in pages[page_index] as Array:
			stamp_names.append(str(stamp_name_value))
			if max_count > 0 and stamp_names.size() >= max_count:
				return stamp_names
	return stamp_names

func consume_stamp(player_id: int, page_index: int, stamp_index: int) -> Dictionary:
	var pages: Array = get_codex_pages(player_id)
	if page_index < 0 or page_index >= pages.size():
		return {}
	var page = pages[page_index]
	if !(page is Array):
		return {}
	var stamps: Array = page
	if stamp_index < 0 or stamp_index >= stamps.size():
		return {}

	var stamp_name: String = str(stamps[stamp_index])
	stamps.remove_at(stamp_index)
	pages[page_index] = stamps
	player_codex_pages[player_id] = pages
	var spent_record: Dictionary = {
		"stamp_name": stamp_name,
		"page_index": page_index,
		"stamp_index": stamp_index,
	}
	var player_spent_stamps: Array = spent_stamps.get(player_id, [])
	player_spent_stamps.append(spent_record)
	spent_stamps[player_id] = player_spent_stamps
	sync_player_stamp_zones_from_codex(player_id)
	return spent_record

func consume_current_page_stamp_by_name(player_id: int, stamp_name: String, preferred_stamp_index: int = -1) -> Dictionary:
	var page_index: int = get_current_page_index(player_id)
	var page: Array = get_current_page(player_id)
	var stamp_index: int = -1
	if preferred_stamp_index >= 0 and preferred_stamp_index < page.size() and str(page[preferred_stamp_index]) == stamp_name:
		stamp_index = preferred_stamp_index
	else:
		stamp_index = page.find(stamp_name)
	if stamp_index == -1:
		return {}
	return consume_stamp(player_id, page_index, stamp_index)

func remove_stamp_from_codex_zone(player_id: int, stamp_name: String = "", include_current_page: bool = false) -> String:
	var pages: Array = get_codex_pages(player_id)
	var candidates: Array[Dictionary] = []
	var current_index: int = get_current_page_index(player_id)
	for page_index in range(pages.size()):
		if !include_current_page and page_index == current_index:
			continue
		var page = pages[page_index]
		if !(page is Array):
			continue
		var stamps: Array = page
		for stamp_index in range(stamps.size()):
			var candidate_name: String = str(stamps[stamp_index])
			if !stamp_name.is_empty() and candidate_name != stamp_name:
				continue
			candidates.append({
				"page_index": page_index,
				"stamp_index": stamp_index,
				"stamp_name": candidate_name,
			})

	if candidates.is_empty():
		return ""
	var selected: Dictionary = candidates[randi() % candidates.size()]
	var selected_page_index: int = int(selected.get("page_index", -1))
	var selected_stamp_index: int = int(selected.get("stamp_index", -1))
	var selected_stamp_name: String = str(selected.get("stamp_name", ""))
	var selected_page: Array = pages[selected_page_index]
	selected_page.remove_at(selected_stamp_index)
	pages[selected_page_index] = selected_page
	player_codex_pages[player_id] = pages
	sync_player_stamp_zones_from_codex(player_id)
	return selected_stamp_name

func remove_stamp_from_current_page(player_id: int, stamp_name: String = "") -> String:
	var pages: Array = get_codex_pages(player_id)
	var page_index: int = get_current_page_index(player_id)
	if page_index < 0 or page_index >= pages.size() or !(pages[page_index] is Array):
		return ""
	var page: Array = pages[page_index]
	if page.is_empty():
		return ""
	var stamp_index: int = -1
	if stamp_name.is_empty():
		stamp_index = randi() % page.size()
	else:
		stamp_index = page.find(stamp_name)
	if stamp_index == -1:
		return ""
	var removed_stamp_name: String = str(page[stamp_index])
	page.remove_at(stamp_index)
	pages[page_index] = page
	player_codex_pages[player_id] = pages
	sync_player_stamp_zones_from_codex(player_id)
	return removed_stamp_name

func add_stamp_to_current_page(player_id: int, stamp_name: String, max_page_size: int = DeckManager.CODEX_STAMPS_PER_PAGE) -> bool:
	if stamp_name.is_empty():
		return false
	var pages: Array = get_codex_pages(player_id)
	var page_index: int = get_current_page_index(player_id)
	if page_index < 0 or page_index >= pages.size():
		return false
	var page = pages[page_index]
	if !(page is Array):
		page = []
	var stamps: Array = page
	if stamps.size() >= max_page_size:
		return false
	stamps.append(stamp_name)
	pages[page_index] = stamps
	player_codex_pages[player_id] = pages
	sync_player_stamp_zones_from_codex(player_id)
	return true

## Puts the stamp into the nearest free slot: on the open page if it has one,
## else on the pages after it, in the order they come up. Returns the page
## index, or -1 when the codex is full.
func add_stamp_to_nearest_free_slot(player_id: int, stamp_name: String) -> int:
	if stamp_name.is_empty():
		return -1
	var pages: Array = get_codex_pages(player_id)
	var current_index: int = get_current_page_index(player_id)
	for offset in range(DeckManager.CODEX_PAGE_COUNT):
		var page_index: int = (current_index + offset) % DeckManager.CODEX_PAGE_COUNT
		if page_index >= pages.size():
			continue
		var stamps: Array = pages[page_index] if pages[page_index] is Array else []
		if stamps.size() >= DeckManager.CODEX_STAMPS_PER_PAGE:
			continue
		stamps.append(stamp_name)
		pages[page_index] = stamps
		player_codex_pages[player_id] = pages
		sync_player_stamp_zones_from_codex(player_id)
		return page_index
	return -1

## The free slots add_stamp_to_nearest_free_slot can fill.
func count_free_codex_slots(player_id: int) -> int:
	var pages: Array = get_codex_pages(player_id)
	var free_slots: int = 0
	for page_index in range(DeckManager.CODEX_PAGE_COUNT):
		var page_size: int = (pages[page_index] as Array).size() if page_index < pages.size() and pages[page_index] is Array else 0
		free_slots += maxi(0, DeckManager.CODEX_STAMPS_PER_PAGE - page_size)
	return free_slots

func return_stamp_to_codex_page(player_id: int, stamp_name: String, preferred_page_index: int = -1, preferred_stamp_index: int = -1) -> bool:
	if stamp_name.is_empty():
		return false
	var target_page_index: int = preferred_page_index
	var target_stamp_index: int = preferred_stamp_index
	if target_page_index < 0 or target_page_index >= DeckManager.CODEX_PAGE_COUNT:
		var spent_record: Dictionary = pop_spent_stamp_record(player_id, stamp_name)
		target_page_index = int(spent_record.get("page_index", get_current_page_index(player_id)))
		target_stamp_index = int(spent_record.get("stamp_index", -1))
	else:
		remove_matching_spent_stamp_record(player_id, stamp_name, target_page_index)

	var pages: Array = get_codex_pages(player_id)
	if target_page_index < 0 or target_page_index >= pages.size():
		target_page_index = get_current_page_index(player_id)
	var page = pages[target_page_index]
	if !(page is Array):
		page = []
	var stamps: Array = page
	var insert_index: int = clampi(target_stamp_index, 0, stamps.size()) if target_stamp_index >= 0 else stamps.size()
	stamps.insert(insert_index, stamp_name)
	pages[target_page_index] = stamps
	player_codex_pages[player_id] = pages
	sync_player_stamp_zones_from_codex(player_id)
	return true

func pop_spent_stamp_record(player_id: int, stamp_name: String) -> Dictionary:
	var player_spent_stamps: Array = spent_stamps.get(player_id, [])
	for reverse_index in range(player_spent_stamps.size() - 1, -1, -1):
		var record = player_spent_stamps[reverse_index]
		if record is Dictionary and str(record.get("stamp_name", "")) == stamp_name:
			player_spent_stamps.remove_at(reverse_index)
			spent_stamps[player_id] = player_spent_stamps
			return record
	return {}

func remove_matching_spent_stamp_record(player_id: int, stamp_name: String, page_index: int) -> void:
	var player_spent_stamps: Array = spent_stamps.get(player_id, [])
	for reverse_index in range(player_spent_stamps.size() - 1, -1, -1):
		var record = player_spent_stamps[reverse_index]
		if record is Dictionary and str(record.get("stamp_name", "")) == stamp_name and int(record.get("page_index", -1)) == page_index:
			player_spent_stamps.remove_at(reverse_index)
			spent_stamps[player_id] = player_spent_stamps
			return

func reset_turn_page_state(player_id: int) -> void:
	has_turned_page_this_turn[player_id] = false
	if !has_stamps_on_page(player_id, get_current_page_index(player_id)):
		var next_page_index: int = find_next_non_empty_page(player_id, get_current_page_index(player_id))
		if next_page_index != -1:
			current_page_index[player_id] = next_page_index
	sync_player_stamp_zones_from_codex(player_id)

func count_non_empty_pages(player_id: int) -> int:
	var count: int = 0
	for page_index in range(DeckManager.CODEX_PAGE_COUNT):
		if has_stamps_on_page(player_id, page_index):
			count += 1
	return count

func get_page_stamp_counts(player_id: int) -> Array[int]:
	var counts: Array[int] = []
	var pages: Array = get_codex_pages(player_id)
	for page_index in range(DeckManager.CODEX_PAGE_COUNT):
		if page_index >= pages.size() or !(pages[page_index] is Array):
			counts.append(0)
		else:
			counts.append((pages[page_index] as Array).size())
	return counts

func get_remaining_codex_stamp_count(player_id: int) -> int:
	var total: int = 0
	for count_value in get_page_stamp_counts(player_id):
		total += int(count_value)
	return total

func sync_player_stamp_zones_from_codex(player_id: int) -> void:
	if !has_codex_for_player(player_id):
		return
	var current_page: Array = get_current_page(player_id)
	var hand: Array[String] = []
	for stamp_name_value in current_page:
		hand.append(str(stamp_name_value))
	player_hands[player_id] = hand
	player_decks[player_id] = DeckManager.flatten_codex_pages(get_codex_pages(player_id), get_current_page_index(player_id))
