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
var player_clock_seconds: Dictionary = {0: 300.0, 1: 300.0}
var white_seeker_position: Vector2 = Vector2(-1, -1)
var black_seeker_position: Vector2 = Vector2(-1, -1)
var player_base_fields: Dictionary = {
	0: BoardConfig.WHITE_BASE_FIELD,
	1: BoardConfig.BLACK_BASE_FIELD,
}
var board_effects: Array = []
var recent_stamp_transfers: Array = []
var recent_stamp_expirations: Array = []
var recent_bomb_effects: Array = []
var recent_pending_respawn_queues: Array = []
var recent_pending_respawn_arrivals: Array = []
var last_move: Dictionary = {}
var pending_respawns: Dictionary = {
	0: [],
	1: [],
}
var attached_stamp_this_turn: Dictionary = {
	0: false,
	1: false,
}
var attached_stamp_count_this_turn: Dictionary = {
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

func _init():
	pass

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
	attached_stamp_this_turn[current_turn_player] = false
	attached_stamp_count_this_turn[current_turn_player] = 0
	moved_piece_this_turn[current_turn_player] = false
	exchanged_stamp_this_turn[current_turn_player] = false
	played_stamp_hand_slots_this_turn[current_turn_player] = []
	exchanged_stamp_names_this_turn[current_turn_player] = []
	reset_turn_page_state(current_turn_player)

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
	if bool(attached_stamp_this_turn.get(player_id, false)):
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
