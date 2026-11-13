class_name NetworkGameHost

const CODEX_BRIDGE_SCRIPT = preload("res://Scripts/CodexBridge.gd")
const CHESS_CLOCK_SECONDS: float = 600.0

var game_state: GameStateData
var multiplayer_node
var codex_bridge = null
## Goes up with every broadcast. An action that leaves it unchanged was
## rejected, which is how the multiplayer node knows to resync the sender.
var state_revision: int = 0
## Players whose turns a script plays: the tutorial's Grandpa, a puzzle's
## opponent. Having nothing to do does not lose them the game; the script hands
## the turn back itself (pass_turn).
var scripted_player_ids: Array[int] = []

func _init(mp_node = null):
	configure(mp_node)

func configure(mp_node = null) -> void:
	multiplayer_node = mp_node
	game_state = GameStateData.new()
	codex_bridge = CODEX_BRIDGE_SCRIPT.new() if should_use_codex_bridge() else null

## The Codex bridge is a development tool: it mirrors every state change, both
## hands included, to user://codex_bridge and plays actions from a command file
## for either player. That has no place in a networked match or a release build.
func should_use_codex_bridge() -> bool:
	return OS.is_debug_build() and GameConfig.is_singleplayer and !is_local_scripted_match()

## A board played with no network and no opponent of its own - the tutorial, a
## puzzle (LocalMatchLink). It keeps no match log and no Codex bridge.
func is_local_scripted_match() -> bool:
	return multiplayer_node != null and multiplayer_node.has_method("is_local_scripted_match") and bool(multiplayer_node.is_local_scripted_match())

## The board on this machine that shows the match, if there is one.
func get_match_board():
	if multiplayer_node == null or !is_instance_valid(multiplayer_node):
		return null
	if multiplayer_node.has_method("get_match_board"):
		return multiplayer_node.get_match_board()
	return multiplayer_node.get_node_or_null("MatchBoard")

func initialize_game(board_data: Array):
	for i in range(board_data.size()):
		for j in range(board_data[i].size()):
			var value = board_data[i][j]
			if value != 0:
				var pos = Vector2(i, j)
				var color = 1 if value > 0 else -1
				var piece = Piece.new(pos, color)
				game_state.set_piece(pos, piece)

	var white_codex_stamps: Array[String] = create_starting_deck_for_player_id(0)
	var black_codex_stamps: Array[String] = create_starting_deck_for_player_id(1)
	game_state.initialize_player_codex(0, white_codex_stamps)
	game_state.initialize_player_codex(1, black_codex_stamps)
	# Both clocks start full when the match does, however long the host waited
	# for its opponent before this.
	game_state.player_clock_seconds = {0: CHESS_CLOCK_SECONDS, 1: CHESS_CLOCK_SECONDS}
	game_state.begin_crown_points(GameConfig.crown_points_required, GameConfig.crown_second_player_head_start)
	setup_match_logging()

	DebugLog.info("NetworkGameHost: game state initialized")

	broadcast_player_profiles()
	broadcast_full_state()

## A match that starts from a position rather than a deal: the tutorial, a
## puzzle. Nothing is dealt and nothing goes over a network; the position, the
## codexes and whose turn it is all come from `setup` (apply_setup).
func initialize_from_setup(setup: Dictionary) -> void:
	game_state.begin_crown_points(GameConfig.crown_points_required, GameConfig.crown_second_player_head_start)
	broadcast_player_profiles()
	apply_setup(setup)

## Puts a position in place and sends it. The keys speak in colours, as a board
## does (1 white, -1 black):
##   "board"              rows of 1, -1 and 0: the golems, all bare; replaces
##                        every golem, and with them the board's effects, the
##                        last move and anyone waiting to come back
##   "affixed_stamps"     [{"pos", "stamp_name", "turns_remaining", "exhausted"}]
##   "crowned"            [pos]: golems that wear the crown
##   "exhausted"          [pos]: golems that have done their part this turn
##   "white_pages"        the codex page by page, empty slots and all, open on
##                        the first; or "white_hand" (the open page) and
##                        "white_deck" (the pages after it, three to a page)
##   "black_pages" ...    the same for black
##   "turn_color"         whose turn it is
##   "crown_points"       {colour: points}
##   "completed_turns"    {colour: turns played}, which decides whether the
##                        first-turn rules still apply
##   "reset_turn_state"   false keeps what this turn has seen so far
## What it leaves out stays as it is. A game that was over is on again.
func apply_setup(setup: Dictionary) -> void:
	if setup.has("board"):
		game_state.pieces.clear()
		var rows: Array = setup.get("board", [])
		for row in range(mini(rows.size(), BoardConfig.BOARD_SIZE)):
			var row_data: Array = rows[row] if rows[row] is Array else []
			for col in range(mini(row_data.size(), BoardConfig.BOARD_SIZE)):
				var value: int = int(row_data[col])
				if value != 0:
					var pos := Vector2(row, col)
					game_state.set_piece(pos, Piece.new(pos, 1 if value > 0 else -1))
		game_state.pending_respawns = {0: [], 1: []}
		game_state.board_effects.clear()
		game_state.last_move = {}
	for entry_value in setup.get("affixed_stamps", []):
		var entry: Dictionary = entry_value
		var pos: Vector2 = StampEffectResolver.as_vector2(entry.get("pos", Vector2(-1, -1)), Vector2(-1, -1))
		var piece: Piece = game_state.get_piece(pos)
		var stamp: Stamp = StampLibrary.duplicate_stamp(str(entry.get("stamp_name", "")))
		if piece == null or stamp == null:
			push_warning("Setup: no stamp %s for a golem on %s." % [entry.get("stamp_name", ""), pos])
			continue
		piece.affix_stamp(stamp, bool(entry.get("exhausted", false)))
		piece.turns_remaining = int(entry.get("turns_remaining", stamp.duration))
	for pos_value in setup.get("crowned", []):
		var piece: Piece = game_state.get_piece(StampEffectResolver.as_vector2(pos_value, Vector2(-1, -1)))
		if piece != null:
			piece.has_crown = true
	for pos_value in setup.get("exhausted", []):
		var piece: Piece = game_state.get_piece(StampEffectResolver.as_vector2(pos_value, Vector2(-1, -1)))
		if piece != null:
			piece.exhausted_this_turn = true
	for owner_color in [1, -1]:
		var prefix: String = "white" if owner_color == 1 else "black"
		var player_id: int = BoardConfig.get_player_id_for_color(owner_color)
		if setup.has(prefix + "_pages"):
			set_codex_pages(player_id, setup.get(prefix + "_pages", []))
		elif setup.has(prefix + "_hand") or setup.has(prefix + "_deck"):
			var pages: Array = DeckManager.create_codex_pages(setup.get(prefix + "_hand", game_state.player_hands.get(player_id, [])))
			if setup.has(prefix + "_deck"):
				var deck_pages: Array = DeckManager.create_codex_pages(setup.get(prefix + "_deck", []))
				for page_index in range(1, DeckManager.CODEX_PAGE_COUNT):
					pages[page_index] = deck_pages[page_index - 1] if page_index - 1 < deck_pages.size() else []
			set_codex_pages(player_id, pages)
	if setup.has("turn_color"):
		game_state.current_turn_player = BoardConfig.get_player_id_for_color(int(setup.get("turn_color", 1)))
	var crown_points: Dictionary = setup.get("crown_points", {})
	for color_value in crown_points:
		game_state.crown_points[BoardConfig.get_player_id_for_color(int(color_value))] = mini(int(crown_points[color_value]), game_state.crown_points_required)
	var completed_turns: Dictionary = setup.get("completed_turns", {})
	for color_value in completed_turns:
		game_state.completed_turn_counts[BoardConfig.get_player_id_for_color(int(color_value))] = int(completed_turns[color_value])
	if bool(setup.get("reset_turn_state", true)):
		for player_id in [0, 1]:
			game_state.affixed_stamp_this_turn[player_id] = false
			game_state.affixed_stamp_count_this_turn[player_id] = 0
			game_state.moved_piece_this_turn[player_id] = false
			game_state.exchanged_stamp_this_turn[player_id] = false
			game_state.played_stamp_hand_slots_this_turn[player_id] = []
			game_state.exchanged_stamp_names_this_turn[player_id] = []
			game_state.crowned_this_turn[player_id] = false
			game_state.has_turned_page_this_turn[player_id] = false
	game_state.game_over = false
	game_state.winner_player = -1
	game_state.win_condition = ""
	game_state.recent_stamp_transfers.clear()
	game_state.recent_stamp_expirations.clear()
	game_state.recent_bomb_effects.clear()
	game_state.recent_effect_activations.clear()
	game_state.recent_pending_respawn_queues.clear()
	game_state.recent_pending_respawn_arrivals.clear()
	broadcast_full_state()

## A codex exactly as given, open on its first page.
func set_codex_pages(player_id: int, pages: Array) -> void:
	var copied: Array = []
	for page_index in range(DeckManager.CODEX_PAGE_COUNT):
		var page: Array[String] = []
		if page_index < pages.size() and pages[page_index] is Array:
			for stamp_name_value in pages[page_index]:
				page.append(str(stamp_name_value))
		copied.append(page)
	game_state.player_codex_pages[player_id] = copied
	game_state.player_initial_decks[player_id] = DeckManager.flatten_codex_pages(copied)
	game_state.current_page_index[player_id] = 0
	game_state.has_turned_page_this_turn[player_id] = false
	game_state.spent_stamps[player_id] = []
	game_state.sync_player_stamp_zones_from_codex(player_id)

func process_codex_bridge_commands() -> bool:
	if codex_bridge == null:
		return false
	return codex_bridge.process_command_file(self)

## Runs both clocks, single player included: only the player whose turn it is
## loses time, and running out loses the game. The host owns this so a client
## can never disagree about whose clock ran out.
##
## A story boss played without the clock (BossDefinition.show_clock) stops it
## here too: a clock nobody can see must not be one the player can lose on.
func process(delta: float) -> void:
	if game_state == null or game_state.game_over:
		return
	if !StoryManager.should_show_match_clock():
		return
	var active_player: int = game_state.current_turn_player
	var remaining: float = maxf(float(game_state.player_clock_seconds.get(active_player, CHESS_CLOCK_SECONDS)) - maxf(delta, 0.0), 0.0)
	game_state.player_clock_seconds[active_player] = remaining
	if remaining > 0.0:
		return
	DebugLog.info("Chess clock expired for player: %d" % active_player)
	finish_game(1 - active_player, "time_expired")
	broadcast_full_state()

func detach_multiplayer_node() -> void:
	multiplayer_node = null

func create_starting_deck_for_player_id(player_id: int) -> Array[String]:
	if multiplayer_node != null && multiplayer_node.has_method("get_starting_deck_for_player_id"):
		var selected_deck: Array[String] = multiplayer_node.get_starting_deck_for_player_id(player_id)
		if !selected_deck.is_empty():
			DebugLog.info("Player %d selected codex: %s" % [player_id, selected_deck])
			return selected_deck

	return DeckManager.create_starting_deck()

func setup_match_logging() -> void:
	if !should_log_match():
		return

	game_state.match_logger = MatchCsvLogger.new()
	if GameConfig.is_dedicated_server:
		game_state.match_logger.set_log_dir(GameConfig.get_dedicated_server_log_dir())
		DebugLog.info("Dedicated match CSV logs: %s" % GameConfig.get_dedicated_server_log_dir())
	game_state.match_logger.start_match(game_state)

func should_log_match() -> bool:
	if is_local_scripted_match():
		return false
	if GameConfig.is_dedicated_server:
		return true
	if GameConfig.is_ai_vs_ai_batch:
		return true
	if !GameConfig.is_singleplayer:
		return false
	for player_id in [0, 1]:
		if GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_AI:
			return true
	return false

func on_player_action(action: Dictionary):
	DebugLog.info("Action received: %s" % [action])

	match action.type:
		"affix_stamp":
			handle_affix_stamp(action)
		"turn_page":
			return handle_turn_page(action)
		"exchange_stamp":
			return handle_exchange_stamp(action)
		"place_crown":
			return handle_place_crown(action)
		"move_piece":
			handle_move_piece(action)
		"end_turn":
			handle_end_turn(action)
		_:
			push_warning("Unknown action type: ", action.type)
			return false

	return true

func handle_affix_stamp(action: Dictionary):
	var player_id: int = int(action.player_id)
	var stamp_name: String = str(action.stamp_name)
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(action.piece_pos, Vector2(-1, -1))
	var hand_index: int = int(action.get("hand_index", -1))

	DebugLog.info("Affix stamp: player=%s, stamp=%s, position=%s" % [player_id, stamp_name, piece_pos])

	if game_state.game_over:
		return
	if game_state.current_turn_player != player_id:
		return

	if !game_state.player_hands[player_id].has(stamp_name):
		push_warning("Stamp is not in hand.")
		return

	var piece = game_state.get_piece(piece_pos)
	if piece == null:
		push_warning("No piece at this position.")
		return

	var expected_color: int = BoardConfig.get_color_for_player_id(player_id)
	if piece.color != expected_color:
		push_warning("This piece does not belong to the player.")
		return

	if !piece.can_receive_stamp(StampLibrary.get_stamp(stamp_name)):
		push_warning("This piece cannot receive a stamp right now.")
		return

	var stamp: Stamp = StampLibrary.duplicate_stamp(stamp_name)
	if stamp:
		var hand_before: Array = duplicate_player_stamp_list(game_state.player_hands[player_id])
		var deck_before: Array = duplicate_player_stamp_list(game_state.player_decks[player_id])
		var deck_top_before: String = str(deck_before[0]) if !deck_before.is_empty() else ""
		var piece_stamp_before: String = piece.affixed_stamp.stamp_name if piece.affixed_stamp != null else ""
		var piece_turns_before: int = piece.turns_remaining
		var consumed_stamp: Dictionary = game_state.consume_current_page_stamp_by_name(player_id, stamp_name, hand_index)
		if consumed_stamp.is_empty():
			push_warning("Stamp could not be removed from current Codex page.")
			return
		stamp.set_meta("codex_owner_player_id", player_id)
		stamp.set_meta("codex_page_index", int(consumed_stamp.get("page_index", game_state.get_current_page_index(player_id))))
		stamp.set_meta("codex_stamp_index", int(consumed_stamp.get("stamp_index", hand_index)))
		StampEffectResolver.cover_piece_stamp(game_state, player_id, piece, piece_pos)
		piece.affix_stamp(stamp, true)
		game_state.affixed_stamp_this_turn[player_id] = true
		game_state.affixed_stamp_count_this_turn[player_id] = int(game_state.affixed_stamp_count_this_turn.get(player_id, 0)) + 1
		log_stamp_affixed(player_id, stamp, piece, piece_pos, hand_before, deck_before, deck_top_before, piece_stamp_before, piece_turns_before)
		StampEffectResolver.resolve_trigger(StampEffect.TRIGGER_ON_AFFIX, game_state, {
			"player_id": player_id,
			"piece": piece,
			"piece_pos": piece_pos,
			"stamp": stamp,
		})
		if game_state.game_over:
			log_turn_snapshot("after_affix")
			broadcast_full_state()
			return
		StampEffectResolver.resolve_symbol_count_trigger(game_state, player_id, piece, piece_pos, stamp, BoardConfig.BOARD_SIZE)
		if game_state.game_over:
			log_turn_snapshot("after_affix")
			broadcast_full_state()
			return
		game_state.refresh_se_tenant_crown_points()
		log_turn_snapshot("after_affix")

		DebugLog.info("Stamp affixed successfully")
		if is_first_turn_for_player(player_id) and int(game_state.affixed_stamp_count_this_turn.get(player_id, 0)) >= DeckManager.HAND_SIZE:
			DebugLog.info("Three first-turn stamps affixed. Ending turn for player: %d" % player_id)
			end_current_turn()
			return
		broadcast_full_state()

func handle_turn_page(action: Dictionary) -> bool:
	var player_id: int = int(action.player_id)
	DebugLog.info("Turn Codex page: player=%s" % player_id)

	if game_state.game_over:
		return false
	if game_state.current_turn_player != player_id:
		return false
	if !game_state.turn_page(player_id):
		push_warning("This player cannot turn the Codex page now.")
		return false

	log_turn_snapshot("after_turn_page")
	broadcast_full_state()
	return true

func handle_place_crown(action: Dictionary) -> bool:
	var player_id: int = int(action.get("player_id", -1))
	var piece_pos: Vector2 = StampEffectResolver.as_vector2(action.get("piece_pos", Vector2(-1, -1)), Vector2(-1, -1))
	DebugLog.info("Place crown: player=%s, position=%s" % [player_id, piece_pos])
	if !game_state.place_crown(player_id, piece_pos):
		push_warning("This player cannot crown that golem now.")
		return false
	StampEffectResolver.resolve_crown_trigger(game_state, player_id, piece_pos, BoardConfig.BOARD_SIZE)
	game_state.refresh_se_tenant_crown_points()
	log_turn_snapshot("after_place_crown")
	broadcast_full_state()
	return true

func handle_exchange_stamp(action: Dictionary):
	var player_id: int = int(action.player_id)
	var stamp_name: String = str(action.get("stamp_name", ""))
	var hand_index: int = int(action.get("hand_index", -1))

	DebugLog.info("Exchange stamp: player=%s, stamp=%s, hand_index=%s" % [player_id, stamp_name, hand_index])

	push_warning("Stamp exchange is disabled. Use turn_page instead.")
	return false

func get_exchange_stamp_hand_index(hand: Array, stamp_name: String, hand_index: int) -> int:
	if hand_index >= 0 && hand_index < hand.size():
		if stamp_name.is_empty() or str(hand[hand_index]) == stamp_name:
			return hand_index
	if !stamp_name.is_empty():
		return hand.find(stamp_name)
	return -1

func handle_move_piece(action: Dictionary):
	var player_id: int = int(action.player_id)
	var from_pos: Vector2 = StampEffectResolver.as_vector2(action.from, Vector2(-1, -1))
	var to_pos: Vector2 = StampEffectResolver.as_vector2(action.to, Vector2(-1, -1))

	DebugLog.info("Move: player=%s, %s -> %s" % [player_id, from_pos, to_pos])

	if game_state.game_over:
		return

	var piece = game_state.get_piece(from_pos)
	if piece == null:
		push_warning("No piece at the start position.")
		return

	if !StampEffectResolver.can_player_control_piece(piece, player_id):
		push_warning("This piece does not belong to the player.")
		return

	if !piece.can_move():
		push_warning("This piece has no usable stamp.")
		return

	if game_state.current_turn_player != player_id:
		push_warning("It is not this player's turn.")
		return
	if bool(game_state.moved_piece_this_turn.get(player_id, false)):
		push_warning("This player has already moved this turn.")
		return

	if !is_valid_move(piece, from_pos, to_pos, player_id):
		push_warning("Invalid move.")
		return

	var captured_piece = game_state.get_piece(to_pos)
	var captured_seeker: bool = is_seeker_piece(captured_piece)
	var captured_piece_owner_player_id: int = BoardConfig.get_player_id_for_color(captured_piece.color) if captured_piece != null else -1
	var move_log_context: Dictionary = create_move_log_context(player_id, from_pos, to_pos, piece, captured_piece)
	var moving_piece_visible_to_enemy: bool = !StampEffectResolver.piece_has_affixed_effect(piece, StampEffect.TYPE_INVISIBLE_TO_ENEMY)

	if captured_piece != null:
		DebugLog.info("Piece captured at: %s" % to_pos)
		if captured_seeker && captured_piece.affixed_stamp != null:
			return_stamp_to_player_deck(captured_piece_owner_player_id, captured_piece.affixed_stamp, "captured_seeker", to_pos)

	game_state.remove_piece(from_pos)
	piece.position = to_pos
	game_state.set_piece(to_pos, piece)
	record_last_move(player_id, from_pos, to_pos, moving_piece_visible_to_enemy, captured_piece)

	if captured_seeker:
		DebugLog.info("Seeker piece captured. Seeker stamp returned to player %d deck." % captured_piece_owner_player_id)

	# The captured stamp's on_captured effect fires once the capturing golem
	# stands on its square, so a bomb there takes the capturing golem too.
	if captured_piece != null && captured_piece.affixed_stamp != null:
		StampEffectResolver.resolve_trigger(StampEffect.TRIGGER_ON_CAPTURED, game_state, {
			"player_id": captured_piece_owner_player_id,
			"piece": captured_piece,
			"piece_pos": to_pos,
			"stamp": captured_piece.affixed_stamp,
			"capturing_piece": piece,
			"capturing_piece_pos": to_pos,
		})
		if game_state.game_over:
			log_move_result(move_log_context, game_state.win_condition)
			broadcast_full_state()
			return
		if game_state.get_piece(to_pos) != piece:
			captured_piece.detach_stamp()
			respawn_captured_piece(captured_piece, captured_piece_owner_player_id)
			StampEffectResolver.resolve_pending_respawns_for_all_players(game_state)
			log_move_result(move_log_context, "capturing_piece_removed")
			game_state.moved_piece_this_turn[player_id] = true
			log_turn_snapshot("after_move")
			end_current_turn()
			return

	if captured_piece != null && piece.affixed_stamp != null:
		StampEffectResolver.resolve_trigger(StampEffect.TRIGGER_ON_CAPTURE, game_state, {
			"player_id": player_id,
			"piece": piece,
			"piece_pos": to_pos,
			"stamp": piece.affixed_stamp,
			"captured_piece": captured_piece,
			"captured_piece_pos": to_pos,
		})
		if game_state.game_over:
			log_move_result(move_log_context, game_state.win_condition)
			broadcast_full_state()
			return

	if captured_piece != null:
		captured_piece.detach_stamp()
		respawn_captured_piece(captured_piece, captured_piece_owner_player_id)
	StampEffectResolver.resolve_pending_respawns_for_all_players(game_state)

	var opponent_base_field: Vector2 = StampEffectResolver.get_base_field_for_player(game_state, 1 - player_id)
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	if piece.has_crown && piece.color == player_color && to_pos == opponent_base_field:
		DebugLog.info("Opponent base reached by the crowned golem. Player %d wins." % player_id)
		finish_game(player_id, "base_reached")
		log_move_result(move_log_context, game_state.win_condition)
		broadcast_full_state()
		return

	# A capturing step does not set off the on_move effect.
	if piece.affixed_stamp != null and captured_piece == null:
		StampEffectResolver.resolve_trigger(StampEffect.TRIGGER_ON_MOVE, game_state, {
			"player_id": player_id,
			"piece": piece,
			"piece_pos": to_pos,
			"stamp": piece.affixed_stamp,
			"from_pos": from_pos,
			"to_pos": to_pos,
		})
		if game_state.game_over:
			log_move_result(move_log_context, game_state.win_condition)
			broadcast_full_state()
			return

	consume_moved_piece_duration(player_id, piece, to_pos)
	if game_state.game_over:
		log_move_result(move_log_context, game_state.win_condition)
		broadcast_full_state()
		return

	log_move_result(move_log_context, "")
	game_state.moved_piece_this_turn[player_id] = true
	log_turn_snapshot("after_move")

	DebugLog.info("Move complete. Ending turn for player: %s" % game_state.current_turn_player)
	end_current_turn()

func handle_end_turn(action: Dictionary):
	var player_id: int = int(action.player_id)
	if game_state.game_over or game_state.current_turn_player != player_id:
		return
	if !can_end_turn_by_button(player_id):
		push_warning("End turn rejected for player %d: a move is required unless the first-turn or frozen-piece exception applies." % player_id)
		return
	end_current_turn()

## Last resort for an AI that has tried turning the page, affixing and moving
## and still cannot close its turn by the rules. Without it the AI sits on the
## turn until its clock runs out.
func force_end_turn_for_ai(player_id: int) -> bool:
	if game_state.game_over or game_state.current_turn_player != player_id:
		return false
	push_warning("AI player %d found no legal way to finish its turn; ending it." % player_id)
	end_current_turn()
	return true

## A scripted player's turn handed back with nothing done - which the rules
## let nobody else do (handle_end_turn).
func pass_turn(player_id: int) -> bool:
	if game_state.game_over or game_state.current_turn_player != player_id or !scripted_player_ids.has(player_id):
		return false
	end_current_turn()
	return true

func end_current_turn():
	if game_state.game_over:
		return

	var ending_player_id: int = game_state.current_turn_player
	game_state.played_stamp_hand_slots_this_turn[ending_player_id] = []
	clear_exchanged_stamp_names_this_turn(ending_player_id)
	clear_piece_exhaustion_for_player(ending_player_id)
	game_state.completed_turn_counts[ending_player_id] = int(game_state.completed_turn_counts.get(ending_player_id, 0)) + 1
	# Before the turn's point, so a set broken this turn starts again from 0 the
	# way a captured crown's meter does.
	game_state.refresh_se_tenant_crown_points()
	game_state.switch_turn()
	advance_logged_turn()
	StampEffectResolver.tick_board_effects(game_state)
	StampEffectResolver.tick_piece_protection_windows(game_state)
	finish_if_player_has_no_valid_turn(game_state.current_turn_player)
	log_turn_snapshot("turn_end")
	DebugLog.info("Turn ended. Next player: %s" % game_state.current_turn_player)
	broadcast_full_state()

func clear_piece_exhaustion_for_player(player_id: int) -> void:
	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece != null && piece.color == player_color:
			if piece.is_respawn_locked():
				continue
			piece.exhausted_this_turn = false

func handle_expired_seeker_stamp(player_id: int, expired_stamp: Stamp, piece_pos: Vector2) -> void:
	return_stamp_to_player_deck(player_id, expired_stamp, "expired_seeker", piece_pos)

func consume_moved_piece_duration(player_id: int, piece: Piece, piece_pos: Vector2) -> void:
	if piece == null or piece.affixed_stamp == null:
		return

	var expired_stamp: Stamp = piece.use_turn()
	if expired_stamp == null:
		return

	if MoveRules.is_seeker_stamp(expired_stamp):
		handle_expired_seeker_stamp(player_id, expired_stamp, piece_pos)
		return

	register_stamp_expiration(player_id, expired_stamp, piece_pos)
	log_stamp_expired(player_id, expired_stamp, piece, piece_pos)
	StampEffectResolver.resolve_trigger(StampEffect.TRIGGER_ON_EXPIRE, game_state, {
		"player_id": player_id,
		"piece": piece,
		"piece_pos": piece_pos,
		"stamp": expired_stamp,
	})

func respawn_captured_piece(captured_piece: Piece, player_id: int) -> bool:
	return StampEffectResolver.respawn_captured_piece(game_state, captured_piece, player_id)

func release_pending_respawn_piece(player_id: int) -> bool:
	return StampEffectResolver.release_pending_respawn_piece(game_state, player_id)

func get_random_empty_home_position(player_id: int) -> Vector2:
	return StampEffectResolver.get_random_empty_home_position(game_state, player_id)

func maybe_auto_end_turn(player_id: int) -> bool:
	return false

func is_first_turn_for_player(player_id: int) -> bool:
	return int(game_state.completed_turn_counts.get(player_id, 0)) == 0

func player_has_remaining_turn_action(player_id: int) -> bool:
	if can_affix_any_stamp_for_player(player_id):
		return true
	if can_move_any_piece_for_player(player_id):
		return true
	if can_turn_page_for_player(player_id):
		return true
	return false

func can_affix_any_stamp_for_player(player_id: int) -> bool:
	if !game_state.player_hands.has(player_id):
		return false

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	var hand_stamps: Array[Stamp] = get_hand_stamps_for_player(player_id)
	if hand_stamps.is_empty():
		return false

	for position_value in game_state.pieces:
		var piece: Piece = game_state.pieces[position_value] as Piece
		if piece == null or piece.color != player_color:
			continue

		for stamp: Stamp in hand_stamps:
			if !MoveRules.stamp_can_be_used(stamp) or !piece.can_receive_stamp(stamp):
				continue
			if MoveRules.can_affix_stamp_for_turn(game_state.pieces, player_color, stamp):
				return true

	return false

func can_move_any_piece_for_player(player_id: int) -> bool:
	if bool(game_state.moved_piece_this_turn.get(player_id, false)):
		return false

	var player_color: int = StampEffectResolver.get_color_for_player_id(player_id)
	return MoveRules.has_valid_piece_move(game_state.pieces, player_color, BoardConfig.BOARD_SIZE, game_state.board_effects)

func finish_game(winner_player: int, win_condition: String = "unknown"):
	game_state.game_over = true
	game_state.winner_player = winner_player
	game_state.win_condition = win_condition
	if game_state.match_logger != null:
		game_state.match_logger.log_match_end(game_state, win_condition)

func finish_if_player_has_no_valid_turn(player_id: int) -> bool:
	if game_state.game_over:
		return false
	if scripted_player_ids.has(player_id):
		return false
	if player_has_valid_turn_action(player_id):
		return false

	var winner_player: int = 1 - player_id
	DebugLog.info("No valid moves: losing player=%d, winning player=%d" % [player_id, winner_player])
	finish_game(winner_player, "no_valid_move")
	return true

func player_has_valid_turn_action(player_id: int) -> bool:
	if is_first_turn_for_player(player_id):
		return int(game_state.affixed_stamp_count_this_turn.get(player_id, 0)) > 0 or can_affix_any_stamp_for_player(player_id) or can_turn_page_for_player(player_id)
	if can_move_any_piece_for_player(player_id):
		return true
	if can_affix_any_stamp_for_player(player_id):
		return true
	if can_turn_page_for_player(player_id):
		return true
	if game_state.can_place_crown(player_id):
		return true
	if can_end_turn_due_to_frozen_piece(player_id):
		return true
	return false

func can_end_turn_by_button(player_id: int) -> bool:
	if is_first_turn_for_player(player_id):
		return int(game_state.affixed_stamp_count_this_turn.get(player_id, 0)) >= 1
	return can_end_turn_due_to_frozen_piece(player_id)

func can_end_turn_due_to_frozen_piece(player_id: int) -> bool:
	if can_move_any_piece_for_player(player_id):
		return false
	var player_color: int = BoardConfig.get_color_for_player_id(player_id)
	return MoveRules.has_frozen_movable_piece(game_state.pieces, player_color, BoardConfig.BOARD_SIZE, game_state.board_effects)

func can_exchange_stamp_for_player(player_id: int) -> bool:
	return false

func can_turn_page_for_player(player_id: int) -> bool:
	if game_state == null:
		return false
	return game_state.can_turn_page(player_id)

func draw_exchange_replacement_stamp(deck: Array, returned_stamp_name: String) -> String:
	return draw_stamp_from_deck_avoiding_names(deck, [returned_stamp_name])

func draw_refill_stamp_for_player(player_id: int, deck: Array) -> String:
	var protected_names: Array = game_state.exchanged_stamp_names_this_turn.get(player_id, [])
	return draw_stamp_from_deck_avoiding_names(deck, protected_names)

func draw_stamp_from_deck_avoiding_names(deck: Array, avoided_stamp_names: Array) -> String:
	if deck.is_empty():
		return ""

	var draw_index: int = -1
	for i in deck.size():
		var candidate_name: String = str(deck[i])
		if !avoided_stamp_names.has(candidate_name):
			draw_index = i
			break
	if draw_index == -1:
		draw_index = 0

	var drawn_stamp_name: String = str(deck[draw_index])
	deck.remove_at(draw_index)
	return drawn_stamp_name

func record_exchanged_stamp_name_this_turn(player_id: int, stamp_name: String) -> void:
	var exchanged_names: Array = game_state.exchanged_stamp_names_this_turn.get(player_id, [])
	exchanged_names.append(stamp_name)
	game_state.exchanged_stamp_names_this_turn[player_id] = exchanged_names

func clear_exchanged_stamp_names_this_turn(player_id: int) -> void:
	game_state.exchanged_stamp_names_this_turn[player_id] = []

func should_hold_turn_for_optional_exchange(player_id: int) -> bool:
	return false

func is_seeker_piece(piece: Piece) -> bool:
	return piece != null && MoveRules.is_seeker_stamp(piece.affixed_stamp)

func get_hand_stamps_for_player(player_id: int) -> Array[Stamp]:
	var hand_stamps: Array[Stamp] = []
	if !game_state.player_hands.has(player_id):
		return hand_stamps

	var hand_stamp_names: Array = game_state.player_hands[player_id]
	for stamp_name_value in hand_stamp_names:
		var stamp_name: String = str(stamp_name_value)
		var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
		if stamp != null:
			hand_stamps.append(stamp)

	return hand_stamps

func has_any_piece(player_id: int) -> bool:
	var expected_color: int = BoardConfig.get_color_for_player_id(player_id)
	return MoveRules.has_any_piece(game_state.pieces, expected_color)

func is_valid_move(_piece: Piece, from_pos: Vector2, to_pos: Vector2, player_id: int) -> bool:
	return MoveRules.is_valid_move_for_player(game_state.pieces, from_pos, to_pos, player_id, BoardConfig.BOARD_SIZE, game_state.board_effects)

func broadcast_full_state():
	DebugLog.info("Broadcasting full state")
	state_revision += 1
	if multiplayer_node == null or !is_instance_valid(multiplayer_node):
		DebugLog.info("State broadcast skipped: multiplayer node is no longer available")
		return

	var match_board = get_match_board()
	# A dedicated server has nobody at its own board. Playing the match out on
	# it would also run the match-end flow there, which closes the connection
	# and leaves the server sitting on the result screen.
	if match_board != null and !GameConfig.is_dedicated_server:
		var local_viewer_player_id: int = get_viewer_player_id_for_peer(1)
		match_board.get_server_state_update_controller().apply_state_data(GameStateSerializer.serialize_for_player(game_state, local_viewer_player_id))

	for peer_id in multiplayer_node.connected_peer_ids:
		if peer_id != 1:
			send_state_to_peer(peer_id)

	if multiplayer_node.has_method("on_host_state_changed"):
		multiplayer_node.on_host_state_changed()

	if codex_bridge != null:
		codex_bridge.export_state(self, "broadcast")

	game_state.recent_stamp_transfers.clear()
	game_state.recent_stamp_expirations.clear()
	game_state.recent_bomb_effects.clear()
	game_state.recent_effect_activations.clear()
	game_state.recent_pending_respawn_queues.clear()
	game_state.recent_pending_respawn_arrivals.clear()
	DebugLog.info("State broadcast complete")

## Sends one remote peer the state as that peer's player sees it. Outside a
## broadcast the recent-event lists are already empty, so a resync this way
## replays no animation, it only puts the peer's board back in line.
func send_state_to_peer(peer_id: int) -> void:
	if multiplayer_node == null or !is_instance_valid(multiplayer_node):
		return
	var viewer_player_id: int = get_viewer_player_id_for_peer(peer_id)
	multiplayer_node.receive_game_state.rpc_id(peer_id, GameStateSerializer.serialize_for_player(game_state, viewer_player_id))

## Sends both players' public profiles (PlayerProfile.to_public_dict: the name
## and the portrait) to every board, this machine's included. Once, as the
## match starts: they do not change, so they stay out of the state that goes
## out after every action. A board keeps them to the end, so the result still
## names a player who left.
func broadcast_player_profiles() -> void:
	if multiplayer_node == null or !is_instance_valid(multiplayer_node):
		return
	var profiles: Dictionary = {
		0: PlayerProfile.default_public_dict(0),
		1: PlayerProfile.default_public_dict(1),
	}
	if multiplayer_node.has_method("get_public_player_profiles"):
		profiles = multiplayer_node.get_public_player_profiles()
	var match_board = get_match_board()
	if match_board != null and !GameConfig.is_dedicated_server:
		match_board.get_server_state_update_controller().apply_player_profiles(profiles)
	for peer_id in multiplayer_node.connected_peer_ids:
		if peer_id != 1:
			multiplayer_node.receive_player_profiles.rpc_id(peer_id, profiles)

func get_viewer_player_id_for_peer(peer_id: int) -> int:
	if multiplayer_node == null or !is_instance_valid(multiplayer_node):
		return 0
	if multiplayer_node.peer_player_ids.has(peer_id):
		return int(multiplayer_node.peer_player_ids[peer_id])
	return 0

func duplicate_player_stamp_list(source) -> Array:
	var output: Array = []
	if source is Array:
		for stamp_name_value in source:
			output.append(str(stamp_name_value))
	return output

func record_last_move(player_id: int, from_pos: Vector2, to_pos: Vector2, visible_to_enemy: bool, captured_piece: Piece = null) -> void:
	if from_pos == to_pos:
		game_state.last_move = {}
		return

	game_state.last_move = {
		"from": from_pos,
		"to": to_pos,
		"player_id": player_id,
		"piece_color": StampEffectResolver.get_color_for_player_id(player_id),
		"visible_to_enemy": visible_to_enemy,
	}
	if captured_piece != null:
		game_state.last_move["captured_piece_color"] = captured_piece.color
		game_state.last_move["captured_stamp_name"] = captured_piece.affixed_stamp.stamp_name if captured_piece.affixed_stamp != null else ""

func play_stamp_from_player_hand(player_id: int, stamp_name: String, hand_index: int) -> bool:
	if !game_state.player_hands.has(player_id):
		return false

	var hand: Array = game_state.player_hands[player_id]
	var remove_index: int = hand.find(stamp_name)
	if hand_index >= 0 && hand_index < hand.size() && str(hand[hand_index]) == stamp_name:
		remove_index = hand_index
	if remove_index == -1:
		return false

	var original_slot: int = get_original_hand_slot_for_play(player_id, remove_index)
	hand.remove_at(remove_index)
	game_state.player_hands[player_id] = hand
	record_played_stamp_hand_slot(player_id, original_slot)
	DebugLog.info("Stamp played: %s" % stamp_name)
	return true

func get_original_hand_slot_for_play(player_id: int, current_hand_index: int) -> int:
	var played_slots: Array = game_state.played_stamp_hand_slots_this_turn.get(player_id, [])
	for candidate in range(current_hand_index, DeckManager.HAND_SIZE):
		if played_slots.has(candidate):
			continue

		var previous_slots_before_candidate: int = 0
		for slot_value in played_slots:
			if int(slot_value) < candidate:
				previous_slots_before_candidate += 1
		if candidate - previous_slots_before_candidate == current_hand_index:
			return candidate
	return clampi(current_hand_index, 0, DeckManager.HAND_SIZE - 1)

func record_played_stamp_hand_slot(player_id: int, hand_slot: int) -> void:
	var played_slots: Array = game_state.played_stamp_hand_slots_this_turn.get(player_id, [])
	played_slots.append(clampi(hand_slot, 0, DeckManager.HAND_SIZE - 1))
	game_state.played_stamp_hand_slots_this_turn[player_id] = played_slots

func refill_played_stamps_for_player(player_id: int) -> void:
	var played_slots: Array = game_state.played_stamp_hand_slots_this_turn.get(player_id, [])
	if played_slots.is_empty():
		clear_exchanged_stamp_names_this_turn(player_id)
		return
	if !game_state.player_decks.has(player_id) or !game_state.player_hands.has(player_id):
		game_state.played_stamp_hand_slots_this_turn[player_id] = []
		clear_exchanged_stamp_names_this_turn(player_id)
		return

	played_slots.sort()
	var deck: Array = game_state.player_decks[player_id]
	var hand: Array = game_state.player_hands[player_id]
	for slot_value in played_slots:
		if deck.is_empty() or hand.size() >= DeckManager.HAND_SIZE:
			break

		var hand_before: Array = duplicate_player_stamp_list(hand)
		var deck_before: Array = duplicate_player_stamp_list(deck)
		var deck_top_before: String = str(deck_before[0]) if !deck_before.is_empty() else ""
		var drawn_stamp_name: String = draw_refill_stamp_for_player(player_id, deck)
		if drawn_stamp_name.is_empty():
			break
		var insert_index: int = clampi(int(slot_value), 0, hand.size())
		hand.insert(insert_index, drawn_stamp_name)
		StampEffectResolver.register_stamp_transfer(game_state, player_id, player_id, drawn_stamp_name, "deck", "hand")
		log_stamp_drawn(player_id, drawn_stamp_name, hand_before, deck_before, deck_top_before, "hand", "turn_end_refill")

	game_state.player_decks[player_id] = deck
	game_state.player_hands[player_id] = hand
	game_state.played_stamp_hand_slots_this_turn[player_id] = []
	clear_exchanged_stamp_names_this_turn(player_id)

func return_stamp_to_player_deck(player_id: int, stamp: Stamp, reason: String, piece_pos: Vector2 = Vector2(-1, -1)) -> void:
	if stamp == null:
		return
	var page_index: int = int(stamp.get_meta("codex_page_index", -1))
	var stamp_index: int = int(stamp.get_meta("codex_stamp_index", -1))
	game_state.return_stamp_to_codex_page(player_id, stamp.stamp_name, page_index, stamp_index)
	StampEffectResolver.register_stamp_transfer(game_state, player_id, player_id, stamp.stamp_name, "piece", "codex", piece_pos)
	log_stamp_returned_to_deck(player_id, stamp, piece_pos, reason)

func setup_logger_if_needed() -> MatchCsvLogger:
	return game_state.match_logger

func log_stamp_affixed(player_id: int, stamp: Stamp, piece: Piece, piece_pos: Vector2, hand_before: Array, deck_before: Array, deck_top_before: String, piece_stamp_before: String, piece_turns_before: int) -> void:
	if game_state.match_logger == null:
		return

	var drawn_stamp: String = ""
	if deck_before.size() > game_state.player_decks[player_id].size():
		drawn_stamp = deck_top_before
	game_state.match_logger.log_stamp_event(game_state, "affix_stamp", {
		"player_id": player_id,
		"stamp": stamp,
		"piece": piece,
		"piece_pos": piece_pos,
		"piece_stamp_before": piece_stamp_before,
		"piece_turns_before": piece_turns_before,
		"hand_before": hand_before,
		"deck_count_before": deck_before.size(),
		"deck_top_before": deck_top_before,
		"drawn_stamp": drawn_stamp,
		"reason": "played_from_hand",
	})

func log_stamp_returned_to_deck(player_id: int, stamp: Stamp, piece_pos: Vector2, reason: String) -> void:
	if game_state.match_logger == null:
		return

	game_state.match_logger.log_stamp_event(game_state, "return_to_deck", {
		"player_id": player_id,
		"stamp": stamp,
		"piece_pos": piece_pos,
		"returned_stamp": stamp.stamp_name if stamp != null else "",
		"target_zone": "codex",
		"reason": reason,
	})

func log_stamp_drawn(player_id: int, drawn_stamp_name: String, hand_before: Array, deck_before: Array, deck_top_before: String, target_zone: String = "hand", reason: String = "turn_end_refill") -> void:
	if game_state.match_logger == null:
		return

	var drawn_stamp: Stamp = StampLibrary.get_stamp(drawn_stamp_name)
	game_state.match_logger.log_stamp_event(game_state, "draw_stamp", {
		"player_id": player_id,
		"stamp": drawn_stamp,
		"stamp_name": drawn_stamp_name,
		"hand_before": hand_before,
		"deck_count_before": deck_before.size(),
		"deck_top_before": deck_top_before,
		"drawn_stamp": drawn_stamp_name,
		"source_zone": "deck",
		"target_zone": target_zone,
		"reason": reason,
	})

func log_stamp_expired(player_id: int, stamp: Stamp, piece: Piece, piece_pos: Vector2) -> void:
	if game_state.match_logger == null:
		return

	game_state.match_logger.log_stamp_event(game_state, "expire_stamp", {
		"player_id": player_id,
		"stamp": stamp,
		"piece": piece,
		"piece_pos": piece_pos,
		"reason": "duration_ended",
	})

func register_stamp_expiration(player_id: int, stamp: Stamp, piece_pos: Vector2) -> void:
	if stamp == null:
		return

	game_state.recent_stamp_expirations.append({
		"player_id": player_id,
		"stamp_name": stamp.stamp_name,
		"piece_pos": piece_pos,
	})

func create_move_log_context(player_id: int, from_pos: Vector2, to_pos: Vector2, piece: Piece, captured_piece: Piece) -> Dictionary:
	if game_state.match_logger == null:
		return {}
	return game_state.match_logger.create_move_context(game_state, player_id, from_pos, to_pos, piece, captured_piece)

func log_move_result(move_log_context: Dictionary, win_condition_after: String) -> void:
	if game_state.match_logger == null or move_log_context.is_empty():
		return
	game_state.match_logger.log_move_event(game_state, move_log_context, win_condition_after)

func advance_logged_turn() -> void:
	if game_state.match_logger == null:
		return
	game_state.match_logger.advance_turn()

func log_turn_snapshot(event_type: String) -> void:
	if game_state.match_logger == null:
		return
	game_state.match_logger.log_turn_snapshot(game_state, event_type)
