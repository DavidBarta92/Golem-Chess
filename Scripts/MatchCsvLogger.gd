extends RefCounted
class_name MatchCsvLogger

const DEFAULT_LOG_DIR: String = "user://ai_match_logs"

const MATCH_HEADERS: Array = [
	"session_id", "match_id", "batch_index", "batch_total", "started_unix", "ended_unix", "duration_ms",
	"mode", "white_controller", "black_controller", "white_ai_difficulty", "black_ai_difficulty",
	"winner_player", "win_condition", "turn_count", "action_count",
	"white_initial_deck", "black_initial_deck", "white_starting_hand", "black_starting_hand",
	"white_final_hand", "black_final_hand", "white_final_deck_count", "black_final_deck_count",
	"white_remaining_pieces", "black_remaining_pieces", "white_active_cards", "black_active_cards",
	"white_wins_in_batch", "black_wins_in_batch"
]

const TURN_HEADERS: Array = [
	"session_id", "match_id", "event_index", "turn_index", "event_type", "current_player",
	"white_hand", "black_hand", "white_deck_count", "black_deck_count",
	"white_piece_count", "black_piece_count", "white_active_cards", "black_active_cards",
	"board_effects", "white_base", "black_base", "attached_card_this_turn",
	"valid_moves_current_player", "game_over", "winner_player"
]

const CARD_HEADERS: Array = [
	"session_id", "match_id", "event_index", "turn_index", "active_player", "event_type",
	"player_id", "card_name", "card_code", "duration", "effect_type", "effect_trigger",
	"effect_params", "effect_settings", "movement_pattern", "piece_pos", "piece_owner_player",
	"piece_card_before", "piece_turns_before", "piece_card_after", "piece_turns_after",
	"hand_before", "hand_after", "deck_count_before", "deck_count_after", "deck_top_before",
	"deck_top_after", "drawn_card", "returned_card", "source_player_id", "target_player_id",
	"source_zone", "target_zone", "reason", "game_over", "winner_player", "board_effect_count",
	"active_cards_snapshot"
]

const MOVE_HEADERS: Array = [
	"session_id", "match_id", "event_index", "turn_index", "player_id", "controller_type",
	"ai_difficulty", "from_pos", "to_pos", "move_direction", "piece_owner_player", "piece_color",
	"card_name", "card_code", "card_duration", "turns_remaining_before", "turns_remaining_after",
	"effect_type", "effect_trigger", "was_capture", "captured_piece_owner", "captured_card_name",
	"captured_card_code", "captured_card_duration", "captured_turns_remaining", "captured_king",
	"was_moving_king", "distance_to_enemy_base_before", "distance_to_enemy_base_after",
	"base_progress", "did_enter_enemy_base", "win_condition_after", "valid_moves_from_before",
	"hand_snapshot", "deck_count", "board_effects_before", "board_effects_after",
	"active_cards_before", "active_cards_after", "white_piece_count_before", "black_piece_count_before",
	"white_piece_count_after", "black_piece_count_after"
]

const EFFECT_HEADERS: Array = [
	"session_id", "match_id", "event_index", "turn_index", "trigger", "player_id",
	"card_name", "card_code", "effect_type", "effect_trigger", "piece_pos", "source_pos",
	"target_player_id", "source_player_id", "source_zone", "target_zone", "squares",
	"affected_positions", "affected_count", "own_pieces_affected", "enemy_pieces_affected",
	"cards_moved", "card_names", "base_player_id", "base_before", "base_after",
	"board_effect_turns_remaining", "hand_before", "hand_after", "deck_count_before",
	"deck_count_after", "game_over", "winner_player", "context"
]

var enabled: bool = true
var session_id: String = ""
var match_id: String = ""
var match_started_msec: int = 0
var match_started_unix: int = 0
var event_index: int = 0
var turn_index: int = 0
var action_count: int = 0
var match_finished: bool = false
var initial_decks: Dictionary = {}
var starting_hands: Dictionary = {}

func start_match(game_state: GameStateData) -> void:
	if !enabled or game_state == null:
		return

	ensure_log_dir()
	session_id = get_or_create_session_id()
	var batch_index: int = GameConfig.ai_vs_ai_matches_played + 1
	var timestamp: int = int(Time.get_unix_time_from_system())
	match_id = "%s_match_%04d_%d" % [session_id, batch_index, randi() % 100000]
	match_started_msec = Time.get_ticks_msec()
	match_started_unix = timestamp
	event_index = 0
	turn_index = 0
	action_count = 0
	match_finished = false
	initial_decks = {
		0: duplicate_string_array(game_state.player_initial_decks.get(0, game_state.player_decks.get(0, []))),
		1: duplicate_string_array(game_state.player_initial_decks.get(1, game_state.player_decks.get(1, []))),
	}
	starting_hands = {
		0: duplicate_string_array(game_state.player_hands.get(0, [])),
		1: duplicate_string_array(game_state.player_hands.get(1, [])),
	}

	log_turn_snapshot(game_state, "match_start")
	log_starting_cards(game_state, 0)
	log_starting_cards(game_state, 1)

func log_match_end(game_state: GameStateData, win_condition: String) -> void:
	if !enabled or game_state == null or match_finished:
		return

	match_finished = true
	var ended_unix: int = int(Time.get_unix_time_from_system())
	var duration_ms: int = Time.get_ticks_msec() - match_started_msec
	var row: Dictionary = {
		"session_id": session_id,
		"match_id": match_id,
		"batch_index": GameConfig.ai_vs_ai_matches_played + 1,
		"batch_total": GameConfig.ai_vs_ai_match_count,
		"started_unix": match_started_unix,
		"ended_unix": ended_unix,
		"duration_ms": duration_ms,
		"mode": "ai_vs_ai" if GameConfig.is_ai_vs_ai_batch else "game",
		"white_controller": GameConfig.get_player_controller(0),
		"black_controller": GameConfig.get_player_controller(1),
		"white_ai_difficulty": GameConfig.get_player_ai_difficulty(0),
		"black_ai_difficulty": GameConfig.get_player_ai_difficulty(1),
		"winner_player": game_state.winner_player,
		"win_condition": win_condition,
		"turn_count": turn_index,
		"action_count": action_count,
		"white_initial_deck": initial_decks.get(0, []),
		"black_initial_deck": initial_decks.get(1, []),
		"white_starting_hand": starting_hands.get(0, []),
		"black_starting_hand": starting_hands.get(1, []),
		"white_final_hand": game_state.player_hands.get(0, []),
		"black_final_hand": game_state.player_hands.get(1, []),
		"white_final_deck_count": get_deck_count(game_state, 0),
		"black_final_deck_count": get_deck_count(game_state, 1),
		"white_remaining_pieces": count_pieces(game_state, 0),
		"black_remaining_pieces": count_pieces(game_state, 1),
		"white_active_cards": get_active_cards(game_state, 0),
		"black_active_cards": get_active_cards(game_state, 1),
		"white_wins_in_batch": get_batch_wins_including_current(game_state, 0),
		"black_wins_in_batch": get_batch_wins_including_current(game_state, 1),
	}
	append_row("matches.csv", MATCH_HEADERS, row)
	log_turn_snapshot(game_state, "match_end")

func log_turn_snapshot(game_state: GameStateData, event_type: String) -> void:
	if !enabled or game_state == null or match_id.is_empty():
		return

	var current_player: int = game_state.current_turn_player
	var row: Dictionary = {
		"session_id": session_id,
		"match_id": match_id,
		"event_index": next_event_index(),
		"turn_index": turn_index,
		"event_type": event_type,
		"current_player": current_player,
		"white_hand": game_state.player_hands.get(0, []),
		"black_hand": game_state.player_hands.get(1, []),
		"white_deck_count": get_deck_count(game_state, 0),
		"black_deck_count": get_deck_count(game_state, 1),
		"white_piece_count": count_pieces(game_state, 0),
		"black_piece_count": count_pieces(game_state, 1),
		"white_active_cards": get_active_cards(game_state, 0),
		"black_active_cards": get_active_cards(game_state, 1),
		"board_effects": game_state.board_effects,
		"white_base": CardEffectResolver.get_base_field_for_player(game_state, 0),
		"black_base": CardEffectResolver.get_base_field_for_player(game_state, 1),
		"attached_card_this_turn": game_state.attached_card_this_turn,
		"valid_moves_current_player": count_valid_turn_moves(game_state, current_player),
		"game_over": game_state.game_over,
		"winner_player": game_state.winner_player,
	}
	append_row("turn_events.csv", TURN_HEADERS, row)

func log_card_event(game_state: GameStateData, event_type: String, details: Dictionary = {}) -> void:
	if !enabled or game_state == null or match_id.is_empty():
		return

	var player_id: int = int(details.get("player_id", game_state.current_turn_player))
	var card: Card = details.get("card", null) as Card
	if card == null:
		var card_name: String = str(details.get("card_name", ""))
		if !card_name.is_empty():
			card = CardLibrary.get_card(card_name)

	var piece: Piece = details.get("piece", null) as Piece
	var row: Dictionary = {
		"session_id": session_id,
		"match_id": match_id,
		"event_index": next_event_index(),
		"turn_index": turn_index,
		"active_player": game_state.current_turn_player,
		"event_type": event_type,
		"player_id": player_id,
		"card_name": get_card_name(card, details),
		"card_code": get_card_code(card),
		"duration": card.duration if card != null else int(details.get("duration", 0)),
		"effect_type": card.effect_type if card != null else str(details.get("effect_type", "")),
		"effect_trigger": card.effect_trigger if card != null else str(details.get("effect_trigger", "")),
		"effect_params": card.effect_params if card != null else details.get("effect_params", []),
		"effect_settings": card.effect_settings if card != null else details.get("effect_settings", {}),
		"movement_pattern": card.movement_pattern if card != null else details.get("movement_pattern", []),
		"piece_pos": details.get("piece_pos", piece.position if piece != null else Vector2(-1, -1)),
		"piece_owner_player": int(details.get("piece_owner_player", CardEffectResolver.get_player_id_for_color(piece.color) if piece != null else -1)),
		"piece_card_before": details.get("piece_card_before", ""),
		"piece_turns_before": int(details.get("piece_turns_before", 0)),
		"piece_card_after": piece.attached_card.card_name if piece != null and piece.attached_card != null else str(details.get("piece_card_after", "")),
		"piece_turns_after": piece.turns_remaining if piece != null else int(details.get("piece_turns_after", 0)),
		"hand_before": details.get("hand_before", []),
		"hand_after": details.get("hand_after", game_state.player_hands.get(player_id, [])),
		"deck_count_before": int(details.get("deck_count_before", -1)),
		"deck_count_after": get_deck_count(game_state, player_id),
		"deck_top_before": details.get("deck_top_before", ""),
		"deck_top_after": get_deck_top(game_state, player_id),
		"drawn_card": details.get("drawn_card", ""),
		"returned_card": details.get("returned_card", ""),
		"source_player_id": int(details.get("source_player_id", -1)),
		"target_player_id": int(details.get("target_player_id", -1)),
		"source_zone": details.get("source_zone", ""),
		"target_zone": details.get("target_zone", ""),
		"reason": details.get("reason", ""),
		"game_over": game_state.game_over,
		"winner_player": game_state.winner_player,
		"board_effect_count": game_state.board_effects.size(),
		"active_cards_snapshot": get_active_cards(game_state, player_id),
	}
	append_row("card_events.csv", CARD_HEADERS, row)

func create_move_context(game_state: GameStateData, player_id: int, from_pos: Vector2, to_pos: Vector2, piece: Piece, captured_piece: Piece) -> Dictionary:
	var card: Card = piece.attached_card if piece != null else null
	var opponent_player_id: int = 1 - player_id
	var opponent_base: Vector2 = CardEffectResolver.get_base_field_for_player(game_state, opponent_player_id)
	var valid_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(game_state.pieces, from_pos, player_id, 5, game_state.board_effects)
	return {
		"player_id": player_id,
		"from_pos": from_pos,
		"to_pos": to_pos,
		"piece_owner_player": CardEffectResolver.get_player_id_for_color(piece.color) if piece != null else -1,
		"piece_color": piece.color if piece != null else 0,
		"card": card,
		"turns_remaining_before": piece.turns_remaining if piece != null else 0,
		"captured_piece_owner": CardEffectResolver.get_player_id_for_color(captured_piece.color) if captured_piece != null else -1,
		"captured_card": captured_piece.attached_card if captured_piece != null else null,
		"captured_turns_remaining": captured_piece.turns_remaining if captured_piece != null else 0,
		"captured_king": CardEffectResolver.is_king_piece(captured_piece),
		"was_moving_king": CardEffectResolver.is_king_piece(piece),
		"distance_to_enemy_base_before": manhattan_distance(from_pos, opponent_base),
		"distance_to_enemy_base_after": manhattan_distance(to_pos, opponent_base),
		"did_enter_enemy_base": to_pos == opponent_base,
		"valid_moves_from_before": valid_moves,
		"hand_snapshot": game_state.player_hands.get(player_id, []),
		"deck_count": get_deck_count(game_state, player_id),
		"board_effects_before": duplicate_array(game_state.board_effects),
		"active_cards_before": get_active_cards(game_state, player_id),
		"white_piece_count_before": count_pieces(game_state, 0),
		"black_piece_count_before": count_pieces(game_state, 1),
	}

func log_move_event(game_state: GameStateData, context: Dictionary, win_condition_after: String = "") -> void:
	if !enabled or game_state == null or match_id.is_empty():
		return

	action_count += 1
	var player_id: int = int(context.get("player_id", game_state.current_turn_player))
	var from_pos: Vector2 = CardEffectResolver.as_vector2(context.get("from_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var to_pos: Vector2 = CardEffectResolver.as_vector2(context.get("to_pos", Vector2(-1, -1)), Vector2(-1, -1))
	var card: Card = context.get("card", null) as Card
	var captured_card: Card = context.get("captured_card", null) as Card
	var moving_piece_after: Piece = game_state.get_piece(to_pos)
	var turns_after: int = moving_piece_after.turns_remaining if moving_piece_after != null else 0
	var before_distance: int = int(context.get("distance_to_enemy_base_before", 0))
	var after_distance: int = int(context.get("distance_to_enemy_base_after", 0))
	var row: Dictionary = {
		"session_id": session_id,
		"match_id": match_id,
		"event_index": next_event_index(),
		"turn_index": turn_index,
		"player_id": player_id,
		"controller_type": GameConfig.get_player_controller(player_id),
		"ai_difficulty": GameConfig.get_player_ai_difficulty(player_id),
		"from_pos": from_pos,
		"to_pos": to_pos,
		"move_direction": to_pos - from_pos,
		"piece_owner_player": int(context.get("piece_owner_player", -1)),
		"piece_color": int(context.get("piece_color", 0)),
		"card_name": card.card_name if card != null else "",
		"card_code": get_card_code(card),
		"card_duration": card.duration if card != null else 0,
		"turns_remaining_before": int(context.get("turns_remaining_before", 0)),
		"turns_remaining_after": turns_after,
		"effect_type": card.effect_type if card != null else "",
		"effect_trigger": card.effect_trigger if card != null else "",
		"was_capture": int(context.get("captured_piece_owner", -1)) != -1,
		"captured_piece_owner": int(context.get("captured_piece_owner", -1)),
		"captured_card_name": captured_card.card_name if captured_card != null else "",
		"captured_card_code": get_card_code(captured_card),
		"captured_card_duration": captured_card.duration if captured_card != null else 0,
		"captured_turns_remaining": int(context.get("captured_turns_remaining", 0)),
		"captured_king": bool(context.get("captured_king", false)),
		"was_moving_king": bool(context.get("was_moving_king", false)),
		"distance_to_enemy_base_before": before_distance,
		"distance_to_enemy_base_after": after_distance,
		"base_progress": before_distance - after_distance,
		"did_enter_enemy_base": bool(context.get("did_enter_enemy_base", false)),
		"win_condition_after": win_condition_after,
		"valid_moves_from_before": context.get("valid_moves_from_before", []),
		"hand_snapshot": context.get("hand_snapshot", []),
		"deck_count": int(context.get("deck_count", -1)),
		"board_effects_before": context.get("board_effects_before", []),
		"board_effects_after": game_state.board_effects,
		"active_cards_before": context.get("active_cards_before", []),
		"active_cards_after": get_active_cards(game_state, player_id),
		"white_piece_count_before": int(context.get("white_piece_count_before", 0)),
		"black_piece_count_before": int(context.get("black_piece_count_before", 0)),
		"white_piece_count_after": count_pieces(game_state, 0),
		"black_piece_count_after": count_pieces(game_state, 1),
	}
	append_row("move_events.csv", MOVE_HEADERS, row)

func create_effect_context(game_state: GameStateData, trigger: String, player_id: int, card: Card, source_pos: Vector2, context: Dictionary) -> Dictionary:
	return {
		"trigger": trigger,
		"player_id": player_id,
		"card": card,
		"source_pos": source_pos,
		"piece_pos": context.get("piece_pos", source_pos),
		"hand_before": game_state.player_hands.get(player_id, []),
		"deck_count_before": get_deck_count(game_state, player_id),
		"base_before": CardEffectResolver.get_base_field_for_player(game_state, player_id),
		"context": context,
	}

func log_effect_event(game_state: GameStateData, before: Dictionary, result: Dictionary = {}) -> void:
	if !enabled or game_state == null or match_id.is_empty():
		return

	var player_id: int = int(before.get("player_id", game_state.current_turn_player))
	var card: Card = before.get("card", null) as Card
	var row: Dictionary = {
		"session_id": session_id,
		"match_id": match_id,
		"event_index": next_event_index(),
		"turn_index": turn_index,
		"trigger": before.get("trigger", ""),
		"player_id": player_id,
		"card_name": card.card_name if card != null else "",
		"card_code": get_card_code(card),
		"effect_type": card.effect_type if card != null else "",
		"effect_trigger": card.effect_trigger if card != null else "",
		"piece_pos": before.get("piece_pos", Vector2(-1, -1)),
		"source_pos": before.get("source_pos", Vector2(-1, -1)),
		"target_player_id": int(result.get("target_player_id", -1)),
		"source_player_id": int(result.get("source_player_id", -1)),
		"source_zone": result.get("source_zone", ""),
		"target_zone": result.get("target_zone", ""),
		"squares": result.get("squares", []),
		"affected_positions": result.get("affected_positions", []),
		"affected_count": int(result.get("affected_count", 0)),
		"own_pieces_affected": int(result.get("own_pieces_affected", 0)),
		"enemy_pieces_affected": int(result.get("enemy_pieces_affected", 0)),
		"cards_moved": int(result.get("cards_moved", 0)),
		"card_names": result.get("card_names", []),
		"base_player_id": int(result.get("base_player_id", -1)),
		"base_before": result.get("base_before", before.get("base_before", Vector2(-1, -1))),
		"base_after": result.get("base_after", CardEffectResolver.get_base_field_for_player(game_state, player_id)),
		"board_effect_turns_remaining": int(result.get("board_effect_turns_remaining", -1)),
		"hand_before": before.get("hand_before", []),
		"hand_after": game_state.player_hands.get(player_id, []),
		"deck_count_before": int(before.get("deck_count_before", -1)),
		"deck_count_after": get_deck_count(game_state, player_id),
		"game_over": game_state.game_over,
		"winner_player": game_state.winner_player,
		"context": before.get("context", {}),
	}
	append_row("effect_events.csv", EFFECT_HEADERS, row)

func advance_turn() -> void:
	turn_index += 1

func next_event_index() -> int:
	event_index += 1
	return event_index

func log_starting_cards(game_state: GameStateData, player_id: int) -> void:
	var hand: Array = game_state.player_hands.get(player_id, [])
	for card_name_value in hand:
		log_card_event(game_state, "starting_hand", {
			"player_id": player_id,
			"card_name": str(card_name_value),
			"hand_after": hand,
			"deck_count_after": get_deck_count(game_state, player_id),
			"reason": "initial_draw",
		})

func append_row(file_name: String, headers: Array, row: Dictionary) -> void:
	var path: String = get_log_file_path(file_name)
	var needs_header: bool = !FileAccess.file_exists(path)
	var file: FileAccess = null
	if needs_header:
		file = FileAccess.open(path, FileAccess.WRITE)
	else:
		file = FileAccess.open(path, FileAccess.READ_WRITE)

	if file == null:
		push_warning("Could not open CSV log file: %s" % path)
		return

	if needs_header:
		file.store_line(csv_line(headers))
	else:
		file.seek_end()

	var values: Array = []
	for header_value in headers:
		var header: String = str(header_value)
		values.append(row.get(header, ""))
	file.store_line(csv_line(values))
	file.close()

func csv_line(values: Array) -> String:
	var escaped_values: Array[String] = []
	for value in values:
		escaped_values.append(csv_escape(value))
	return ",".join(escaped_values)

func csv_escape(value) -> String:
	var text: String = stringify_value(value)
	var must_quote: bool = text.contains(",") or text.contains("\"") or text.contains("\n") or text.contains("\r")
	text = text.replace("\"", "\"\"")
	if must_quote:
		return "\"%s\"" % text
	return text

func stringify_value(value) -> String:
	if value == null:
		return ""
	if value is Vector2:
		var vector_value: Vector2 = value
		return "%d:%d" % [int(vector_value.x), int(vector_value.y)]
	if value is Vector2i:
		var vector_i_value: Vector2i = value
		return "%d:%d" % [vector_i_value.x, vector_i_value.y]
	if value is Array or value is Dictionary:
		return JSON.stringify(normalize_value(value))
	if value is bool:
		return "true" if bool(value) else "false"
	return str(value)

func normalize_value(value):
	if value is Vector2:
		var vector_value: Vector2 = value
		return [vector_value.x, vector_value.y]
	if value is Vector2i:
		var vector_i_value: Vector2i = value
		return [vector_i_value.x, vector_i_value.y]
	if value is Card:
		var card: Card = value
		return card.card_name
	if value is Piece:
		var piece: Piece = value
		return {
			"position": normalize_value(piece.position),
			"player_id": CardEffectResolver.get_player_id_for_color(piece.color),
			"card_name": piece.attached_card.card_name if piece.attached_card != null else "",
			"turns_remaining": piece.turns_remaining,
		}
	if value is Array:
		var source_array: Array = value
		var normalized_array: Array = []
		for item in source_array:
			normalized_array.append(normalize_value(item))
		return normalized_array
	if value is Dictionary:
		var source_dict: Dictionary = value
		var normalized_dict: Dictionary = {}
		for key in source_dict:
			normalized_dict[str(key)] = normalize_value(source_dict[key])
		return normalized_dict
	return value

func ensure_log_dir() -> void:
	var absolute_path: String = get_absolute_log_dir()
	DirAccess.make_dir_recursive_absolute(absolute_path)

func get_log_file_path(file_name: String) -> String:
	return "%s/%s" % [get_log_dir().trim_suffix("/"), file_name]

func get_log_dir() -> String:
	var log_dir: String = GameConfig.get_ai_vs_ai_csv_log_dir()
	if log_dir.strip_edges().is_empty():
		return DEFAULT_LOG_DIR
	return log_dir.strip_edges().replace("\\", "/")

func get_absolute_log_dir() -> String:
	var log_dir: String = get_log_dir()
	if log_dir.begins_with("user://") or log_dir.begins_with("res://"):
		return ProjectSettings.globalize_path(log_dir)
	return log_dir

func get_or_create_session_id() -> String:
	if GameConfig.ai_vs_ai_log_session_id.is_empty():
		var datetime: String = Time.get_datetime_string_from_system(false, true)
		datetime = datetime.replace(":", "-").replace(" ", "_")
		GameConfig.ai_vs_ai_log_session_id = "%s_%d" % [datetime, randi() % 100000]
	return GameConfig.ai_vs_ai_log_session_id

func duplicate_string_array(value) -> Array:
	var output: Array = []
	if value is Array:
		for item in value:
			output.append(str(item))
	return output

func duplicate_array(value: Array) -> Array:
	var output: Array = []
	for item in value:
		output.append(normalize_value(item))
	return output

func get_deck_count(game_state: GameStateData, player_id: int) -> int:
	var deck: Array = game_state.player_decks.get(player_id, [])
	return deck.size()

func get_deck_top(game_state: GameStateData, player_id: int) -> String:
	var deck: Array = game_state.player_decks.get(player_id, [])
	if deck.is_empty():
		return ""
	return str(deck[0])

func count_pieces(game_state: GameStateData, player_id: int) -> int:
	var expected_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var count: int = 0
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null && piece.color == expected_color:
			count += 1
	return count

func get_active_cards(game_state: GameStateData, player_id: int) -> Array:
	var expected_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var active_cards: Array = []
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != expected_color or piece.attached_card == null:
			continue
		active_cards.append({
			"position": normalize_value(position_value),
			"card_name": piece.attached_card.card_name,
			"turns_remaining": piece.turns_remaining,
			"effect_type": piece.attached_card.effect_type,
		})
	return active_cards

func count_valid_turn_moves(game_state: GameStateData, player_id: int) -> int:
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var can_attach_card: bool = !bool(game_state.attached_card_this_turn.get(player_id, false))
	var hand_cards: Array[Card] = []
	var hand_card_names: Array = game_state.player_hands.get(player_id, [])
	for card_name_value in hand_card_names:
		var card: Card = CardLibrary.get_card(str(card_name_value))
		if card != null:
			hand_cards.append(card)
	return MoveRules.get_valid_turn_moves(game_state.pieces, player_color, hand_cards, can_attach_card, 5, game_state.board_effects).size()

func get_card_name(card: Card, details: Dictionary) -> String:
	if card != null:
		return card.card_name
	return str(details.get("card_name", ""))

func get_card_code(card: Card) -> String:
	if card == null:
		return ""
	return card.card_code

func manhattan_distance(a: Vector2, b: Vector2) -> int:
	return int(abs(a.x - b.x) + abs(a.y - b.y))

func get_batch_wins_including_current(game_state: GameStateData, player_id: int) -> int:
	var wins: int = int(GameConfig.ai_vs_ai_results.get(player_id, 0))
	if game_state != null && game_state.winner_player == player_id:
		wins += 1
	return wins
