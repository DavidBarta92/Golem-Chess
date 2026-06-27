extends RefCounted
class_name CodexBridge

const BRIDGE_DIR: String = "user://codex_bridge"
const STATE_PATH: String = "user://codex_bridge/state.json"
const COMMAND_PATH: String = "user://codex_bridge/command.json"
const RESULT_PATH: String = "user://codex_bridge/command_result.json"
const HISTORY_PATH: String = "user://codex_bridge/history.jsonl"
const STATS_PATH: String = "user://codex_bridge/stats.json"

var state_sequence: int = 0
var last_command_id: String = ""
var processed_command_count: int = 0
var processed_action_count: int = 0

func _init() -> void:
	ensure_bridge_dir()

func ensure_bridge_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive("codex_bridge")

func export_state(host, event_type: String = "state") -> void:
	if host == null or host.game_state == null:
		return

	ensure_bridge_dir()
	state_sequence += 1
	var state_data: Dictionary = build_codex_state(host, event_type)
	write_json(STATE_PATH, state_data)
	append_history({
		"kind": "state",
		"sequence": state_sequence,
		"event_type": event_type,
		"current_turn": int(host.game_state.current_turn_player),
		"game_over": bool(host.game_state.game_over),
		"winner_player": int(host.game_state.winner_player),
		"timestamp_unix": Time.get_unix_time_from_system(),
	})
	write_stats(host)

func process_command_file(host) -> bool:
	if host == null or host.game_state == null:
		return false
	if !FileAccess.file_exists(COMMAND_PATH):
		return false

	var parsed = read_json(COMMAND_PATH)
	if !(parsed is Dictionary):
		write_command_result("", false, "command.json is not a JSON object", [])
		remove_command_file()
		return false

	var command: Dictionary = parsed
	var command_id: String = str(command.get("command_id", ""))
	if command_id.is_empty():
		command_id = "cmd_%d" % Time.get_ticks_msec()
	if command_id == last_command_id:
		remove_command_file()
		return false

	var actions: Array = command.get("actions", [])
	var executed_actions: Array = []
	var success: bool = true
	var message: String = "ok"
	for action_value in actions:
		if !(action_value is Dictionary):
			success = false
			message = "One action is not a JSON object"
			break

		var action: Dictionary = normalize_action(action_value)
		var before_snapshot: Dictionary = create_action_snapshot(host, action)
		var before_game_over: bool = bool(host.game_state.game_over)
		host.on_player_action(action)
		var applied: bool = was_action_applied(host, action, before_snapshot)
		executed_actions.append({
			"action": action_to_json(action),
			"applied": applied,
		})
		if !applied:
			success = false
			message = "Action was rejected or had no effect: %s" % str(action.get("type", ""))
			break
		processed_action_count += 1
		if bool(host.game_state.game_over) and !before_game_over:
			break

	last_command_id = command_id
	processed_command_count += 1
	write_command_result(command_id, success, message, executed_actions)
	append_history({
		"kind": "command",
		"command_id": command_id,
		"success": success,
		"message": message,
		"actions": executed_actions,
		"timestamp_unix": Time.get_unix_time_from_system(),
	})
	remove_command_file()
	export_state(host, "after_codex_command")
	return true

func build_codex_state(host, event_type: String) -> Dictionary:
	var game_state: GameStateData = host.game_state
	return {
		"schema": "golem_codex_bridge_v1",
		"sequence": state_sequence,
		"event_type": event_type,
		"timestamp_unix": Time.get_unix_time_from_system(),
		"board_size": BoardConfig.BOARD_SIZE,
		"current_turn": int(game_state.current_turn_player),
		"game_over": bool(game_state.game_over),
		"winner_player": int(game_state.winner_player),
		"win_condition": str(game_state.win_condition),
		"player_base_fields": serialize_base_fields(game_state),
		"pieces": serialize_pieces(game_state),
		"player_hands": serialize_player_card_lists(game_state.player_hands, true),
		"player_decks": serialize_player_card_lists(game_state.player_decks, false),
		"player_codexes": serialize_player_codexes(game_state),
		"turn_flags": serialize_turn_flags(game_state),
		"board_effects": host.serialize_board_effects(),
		"last_move": host.serialize_last_move_for_player(-1),
		"legal_actions": serialize_legal_actions(host),
	}

func serialize_pieces(game_state: GameStateData) -> Array:
	var pieces: Array = []
	for position_value in game_state.pieces:
		var pos: Vector2 = CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null:
			continue
		pieces.append({
			"position": vector2_to_array(pos),
			"color": piece.color,
			"player_id": CardEffectResolver.get_player_id_for_color(piece.color),
			"card": serialize_card(piece.attached_card),
			"card_name": piece.attached_card.card_name if piece.attached_card != null else "",
			"turns_remaining": piece.turns_remaining,
			"exhausted_this_turn": piece.exhausted_this_turn,
			"respawn_cooldown_turns": piece.respawn_cooldown_turns,
		})
	return pieces

func serialize_player_card_lists(card_lists: Dictionary, include_card_details: bool) -> Dictionary:
	var output: Dictionary = {}
	for player_id in card_lists:
		var cards: Array = []
		for card_name_value in card_lists[player_id]:
			var card_name: String = str(card_name_value)
			if include_card_details:
				cards.append(serialize_card(CardLibrary.get_card(card_name)))
			else:
				cards.append(card_name)
		output[str(player_id)] = cards
	return output

func serialize_card(card: Card) -> Dictionary:
	if card == null:
		return {}
	return {
		"name": card.card_name,
		"code": card.card_code,
		"role": card.role,
		"is_nexus": MoveRules.is_nexus_card(card),
		"duration": card.duration,
		"symbol": card.symbol,
		"description": card.description,
		"effect_type": card.effect_type,
		"effect_trigger": card.effect_trigger,
		"directions": serialize_vector_array(card.get_directions()),
		"movement_options": serialize_movement_options(card.get_movement_options()),
	}

func serialize_movement_options(options: Array[Dictionary]) -> Array:
	var output: Array = []
	for option in options:
		output.append({
			"offset": vector2_to_array(CardEffectResolver.as_vector2(option.get("offset", Vector2.ZERO), Vector2.ZERO)),
			"movement_type": int(option.get("movement_type", CardEffect.MOVEMENT_MOVE_AND_CAPTURE)),
		})
	return output

func serialize_legal_actions(host) -> Dictionary:
	var game_state: GameStateData = host.game_state
	var player_id: int = int(game_state.current_turn_player)
	var player_color: int = CardEffectResolver.get_color_for_player_id(player_id)
	var legal_actions: Dictionary = {
		"player_id": player_id,
		"attach_card": [],
		"move_piece": [],
		"turn_page": [],
		"end_turn": [{
			"type": "end_turn",
			"player_id": player_id,
		}],
	}

	var hand_card_names: Array = game_state.player_hands.get(player_id, [])
	for position_value in game_state.pieces:
		var pos: Vector2 = CardEffectResolver.as_vector2(position_value, Vector2(-1, -1))
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color or piece.attached_card != null:
			continue
		for hand_index in range(hand_card_names.size()):
			var card_name: String = str(hand_card_names[hand_index])
			var card: Card = CardLibrary.get_card(card_name)
			if !MoveRules.card_can_be_used(card) or !MoveRules.can_attach_card_for_turn(game_state.pieces, player_color, card):
				continue
			legal_actions["attach_card"].append({
				"type": "attach_card",
				"player_id": player_id,
				"card_name": card_name,
				"hand_index": hand_index,
				"piece_pos": vector2_to_array(pos),
				"next_turn_moves_after_attach": serialize_vector_array(MoveRules.get_card_moves_for_piece(game_state.pieces, pos, player_color, card, BoardConfig.BOARD_SIZE, game_state.board_effects)),
				"note": "Attach exhausts the piece this turn; these moves are for later turns.",
			})

	if !bool(game_state.moved_piece_this_turn.get(player_id, false)):
		var existing_moves: Array[Dictionary] = MoveRules.get_existing_card_moves(game_state.pieces, player_color, BoardConfig.BOARD_SIZE, game_state.board_effects)
		for move in existing_moves:
			legal_actions["move_piece"].append({
				"type": "move_piece",
				"player_id": player_id,
				"from": vector2_to_array(AIStateSimulator.get_move_from(move)),
				"to": vector2_to_array(AIStateSimulator.get_move_to(move)),
				"card_name": get_move_card_name(move),
			})

	if host.can_turn_page_for_player(player_id):
		legal_actions["turn_page"].append({
			"type": "turn_page",
			"player_id": player_id,
		})
	return legal_actions

func serialize_player_codexes(game_state: GameStateData) -> Dictionary:
	var output: Dictionary = {}
	for player_id in [0, 1]:
		var pages: Array = []
		for page in game_state.get_codex_pages(player_id):
			var page_cards: Array = []
			if page is Array:
				for card_name_value in page:
					page_cards.append(serialize_card(CardLibrary.get_card(str(card_name_value))))
			pages.append(page_cards)
		output[str(player_id)] = {
			"current_page_index": game_state.get_current_page_index(player_id),
			"page_counts": game_state.get_page_stamp_counts(player_id),
			"pages": pages,
			"has_turned_page_this_turn": bool(game_state.has_turned_page_this_turn.get(player_id, false)),
		}
	return output

func serialize_base_fields(game_state: GameStateData) -> Dictionary:
	return {
		"0": vector2_to_array(CardEffectResolver.get_base_field_for_player(game_state, 0)),
		"1": vector2_to_array(CardEffectResolver.get_base_field_for_player(game_state, 1)),
	}

func serialize_turn_flags(game_state: GameStateData) -> Dictionary:
	return {
		"attached_card_this_turn": stringify_key_dictionary(game_state.attached_card_this_turn),
		"moved_piece_this_turn": stringify_key_dictionary(game_state.moved_piece_this_turn),
		"exchanged_card_this_turn": stringify_key_dictionary(game_state.exchanged_card_this_turn),
		"has_turned_page_this_turn": stringify_key_dictionary(game_state.has_turned_page_this_turn),
	}

func stringify_key_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		output[str(key)] = source[key]
	return output

func normalize_action(action_value: Dictionary) -> Dictionary:
	var action: Dictionary = action_value.duplicate()
	match str(action.get("type", "")):
		"attach_card":
			action["piece_pos"] = array_to_vector2(action.get("piece_pos", Vector2(-1, -1)))
			action["hand_index"] = int(action.get("hand_index", -1))
		"move_piece":
			action["from"] = array_to_vector2(action.get("from", Vector2(-1, -1)))
			action["to"] = array_to_vector2(action.get("to", Vector2(-1, -1)))
		"exchange_card":
			action["hand_index"] = int(action.get("hand_index", -1))
		"turn_page":
			pass
	action["player_id"] = int(action.get("player_id", -1))
	return action

func create_action_snapshot(host, action: Dictionary) -> Dictionary:
	var game_state: GameStateData = host.game_state
	var snapshot: Dictionary = {
		"turn": int(game_state.current_turn_player),
		"game_over": bool(game_state.game_over),
	}
	match str(action.get("type", "")):
		"attach_card":
			var piece_pos: Vector2 = CardEffectResolver.as_vector2(action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
			var piece: Piece = game_state.get_piece(piece_pos)
			snapshot["piece_card_name"] = piece.attached_card.card_name if piece != null and piece.attached_card != null else ""
			snapshot["hand"] = duplicate_card_names(game_state.player_hands.get(int(action.get("player_id", -1)), []))
		"move_piece":
			var from_pos: Vector2 = CardEffectResolver.as_vector2(action.get("from", Vector2(-1, -1)), Vector2(-1, -1))
			var to_pos: Vector2 = CardEffectResolver.as_vector2(action.get("to", Vector2(-1, -1)), Vector2(-1, -1))
			snapshot["from_has_piece"] = game_state.get_piece(from_pos) != null
			snapshot["to_card_name"] = get_piece_card_name(game_state.get_piece(to_pos))
		"exchange_card":
			snapshot["hand"] = duplicate_card_names(game_state.player_hands.get(int(action.get("player_id", -1)), []))
			snapshot["deck"] = duplicate_card_names(game_state.player_decks.get(int(action.get("player_id", -1)), []))
			snapshot["exchanged"] = bool(game_state.exchanged_card_this_turn.get(int(action.get("player_id", -1)), false))
		"turn_page":
			var player_id: int = int(action.get("player_id", -1))
			snapshot["page_index"] = game_state.get_current_page_index(player_id)
			snapshot["turned"] = bool(game_state.has_turned_page_this_turn.get(player_id, false))
	return snapshot

func was_action_applied(host, action: Dictionary, before_snapshot: Dictionary) -> bool:
	var game_state: GameStateData = host.game_state
	if bool(game_state.game_over) and !bool(before_snapshot.get("game_over", false)):
		return true

	match str(action.get("type", "")):
		"attach_card":
			var piece_pos: Vector2 = CardEffectResolver.as_vector2(action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
			var piece: Piece = game_state.get_piece(piece_pos)
			return piece != null \
				&& piece.attached_card != null \
				&& piece.attached_card.card_name == str(action.get("card_name", "")) \
				&& str(before_snapshot.get("piece_card_name", "")) != piece.attached_card.card_name
		"move_piece":
			var from_pos: Vector2 = CardEffectResolver.as_vector2(action.get("from", Vector2(-1, -1)), Vector2(-1, -1))
			var to_pos: Vector2 = CardEffectResolver.as_vector2(action.get("to", Vector2(-1, -1)), Vector2(-1, -1))
			return game_state.get_piece(from_pos) == null and game_state.get_piece(to_pos) != null
		"exchange_card":
			var player_id: int = int(action.get("player_id", -1))
			return bool(game_state.exchanged_card_this_turn.get(player_id, false)) and !bool(before_snapshot.get("exchanged", false))
		"turn_page":
			var player_id: int = int(action.get("player_id", -1))
			return bool(game_state.has_turned_page_this_turn.get(player_id, false)) \
				and !bool(before_snapshot.get("turned", false)) \
				and game_state.get_current_page_index(player_id) != int(before_snapshot.get("page_index", -1))
		"end_turn":
			return int(game_state.current_turn_player) != int(before_snapshot.get("turn", -1))
		_:
			return false

func duplicate_card_names(source) -> Array:
	var output: Array = []
	if source is Array:
		for card_name_value in source:
			output.append(str(card_name_value))
	return output

func get_piece_card_name(piece: Piece) -> String:
	return piece.attached_card.card_name if piece != null and piece.attached_card != null else ""

func action_to_json(action: Dictionary) -> Dictionary:
	var output: Dictionary = action.duplicate()
	if output.has("piece_pos"):
		output["piece_pos"] = vector2_to_array(CardEffectResolver.as_vector2(output["piece_pos"], Vector2(-1, -1)))
	if output.has("from"):
		output["from"] = vector2_to_array(CardEffectResolver.as_vector2(output["from"], Vector2(-1, -1)))
	if output.has("to"):
		output["to"] = vector2_to_array(CardEffectResolver.as_vector2(output["to"], Vector2(-1, -1)))
	return output

func get_move_card_name(move: Dictionary) -> String:
	var card: Card = AIStateSimulator.get_card_for_candidate({}, move)
	return card.card_name if card != null else str(move.get("card_name", ""))

func serialize_vector_array(values: Array) -> Array:
	var output: Array = []
	for value in values:
		output.append(vector2_to_array(CardEffectResolver.as_vector2(value, Vector2.ZERO)))
	return output

func vector2_to_array(value: Vector2) -> Array:
	return [int(value.x), int(value.y)]

func array_to_vector2(value, fallback: Vector2 = Vector2(-1, -1)) -> Vector2:
	return CardEffectResolver.as_vector2(value, fallback)

func write_command_result(command_id: String, success: bool, message: String, actions: Array) -> void:
	write_json(RESULT_PATH, {
		"command_id": command_id,
		"success": success,
		"message": message,
		"actions": actions,
		"timestamp_unix": Time.get_unix_time_from_system(),
	})

func write_stats(host) -> void:
	if host == null or host.game_state == null:
		return
	write_json(STATS_PATH, {
		"state_sequence": state_sequence,
		"processed_command_count": processed_command_count,
		"processed_action_count": processed_action_count,
		"current_turn": int(host.game_state.current_turn_player),
		"game_over": bool(host.game_state.game_over),
		"winner_player": int(host.game_state.winner_player),
		"win_condition": str(host.game_state.win_condition),
		"last_command_id": last_command_id,
		"timestamp_unix": Time.get_unix_time_from_system(),
	})

func read_json(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var content: String = file.get_as_text()
	file.close()
	return JSON.parse_string(content)

func write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("CodexBridge could not write %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func append_history(data: Dictionary) -> void:
	var file := FileAccess.open(HISTORY_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(data))
	file.close()

func remove_command_file() -> void:
	var dir := DirAccess.open(BRIDGE_DIR)
	if dir != null and dir.file_exists("command.json"):
		dir.remove("command.json")
