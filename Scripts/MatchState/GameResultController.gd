extends RefCounted

var match_board
var main_menu_scene: String = "res://Scenes/MainMenu.tscn"

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)
	main_menu_scene = str(config.get("main_menu_scene", main_menu_scene))

func finish_if_current_player_has_no_valid_turn() -> bool:
	if match_board.game_over:
		return false
	if match_board.get_local_state_mutator().current_player_has_valid_turn_action():
		return false

	var losing_color: int = match_board.get_current_turn_color()
	var winner_color: int = -losing_color
	DebugLog.info("No valid moves for player: %s. Winner: %s" % [losing_color, winner_color])
	match_board.finish_game(winner_color)
	return true

func finish_game(winner_color: int) -> void:
	if match_board.game_over:
		return

	match_board.game_over = true
	match_board.state = false
	match_board.hovered_piece = Vector2(-1, -1)
	match_board.delete_dots()
	match_board.hide_hover_piece_details()
	match_board.update_card_drag_permissions()
	match_board.update_end_turn_button()
	award_win_points_if_applicable(winner_color)
	show_result_message(winner_color)

	var result_wait_seconds: float = 0.05 if match_board.should_skip_visual_animations() else 8.0
	await match_board.get_tree().create_timer(result_wait_seconds).timeout
	var next_scene: String = get_next_scene_after_game(winner_color)
	if match_board.get_parent().has_method("close_game_connection"):
		match_board.get_parent().close_game_connection()
	if match_board.get_tree():
		match_board.get_tree().change_scene_to_file(next_scene)

func get_next_scene_after_game(winner_color: int) -> String:
	if GameConfig.is_ai_vs_ai_batch:
		var winner_player_id: int = match_board.get_player_id_for_color(winner_color)
		GameConfig.record_ai_vs_ai_result(winner_player_id)
		DebugLog.info("AI vs AI match %d/%d finished. White wins: %d, Black wins: %d" % [
			GameConfig.ai_vs_ai_matches_played,
			GameConfig.ai_vs_ai_match_count,
			int(GameConfig.ai_vs_ai_results.get(0, 0)),
			int(GameConfig.ai_vs_ai_results.get(1, 0)),
		])

		if GameConfig.should_continue_ai_vs_ai_batch():
			return "res://Scenes/main.tscn"

		GameConfig.stop_ai_vs_ai_batch()

	return main_menu_scene

func award_win_points_if_applicable(winner_color: int) -> void:
	if !should_award_win_points(winner_color):
		return

	PlayerProgressStore.add_points(PlayerProgressStore.WIN_POINTS_PER_WIN)

func should_award_win_points(winner_color: int) -> bool:
	if match_board.tutorial_mode_active:
		return false
	if GameConfig.is_ai_vs_ai_batch:
		return false

	if match_board.side == null:
		if GameConfig.is_singleplayer:
			var winner_player_id: int = match_board.get_player_id_for_color(winner_color)
			return GameConfig.get_player_controller(winner_player_id) == GameConfig.CONTROLLER_HUMAN
		return true

	return winner_color == match_board.get_own_color()

func show_result_message(winner_color: int) -> void:
	match_board.get_turn_hud_controller().show_result_message(winner_color)
