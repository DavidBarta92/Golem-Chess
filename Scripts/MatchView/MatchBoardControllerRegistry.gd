extends RefCounted

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")
const STAMP_VISUAL = preload("res://Scenes/StampVisual.tscn")
const BOARD_GEOMETRY_SCRIPT = preload("res://Scripts/MatchView/BoardGeometry.gd")
const BOARD_VISUAL_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/BoardVisualController.gd")
const BOARD_TILE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/BoardTileController.gd")
const BOARD_MARKER_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/BoardMarkerController.gd")
const BOARD_ENVIRONMENT_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/BoardEnvironmentController.gd")
const VISUAL_PROCESS_TRACKER_SCRIPT = preload("res://Scripts/MatchView/VisualProcessTracker.gd")
const MATCH_STATE_SYNC_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/MatchStateSyncController.gd")
const SERVER_STATE_UPDATE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/ServerStateUpdateController.gd")
const SERVER_STATE_VISUAL_UPDATE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/ServerStateVisualUpdateController.gd")
const LOCAL_STATE_MUTATOR_SCRIPT = preload("res://Scripts/MatchState/LocalStateMutator.gd")
const LOCAL_MOVE_FLOW_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/LocalMoveFlowController.gd")
const LOCAL_STAMP_ACTION_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/LocalStampActionController.gd")
const LOCAL_GAMEPLAY_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/LocalGameplayController.gd")
const TUTORIAL_MATCH_ADAPTER_SCRIPT = preload("res://Scripts/MatchState/TutorialMatchAdapter.gd")
const GAME_RESULT_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/GameResultController.gd")
const TURN_FLOW_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/TurnFlowController.gd")
const TURN_ACTION_STATE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/TurnActionStateController.gd")
const PIECE_VISUAL_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/PieceVisualController.gd")
const PIECE_TEXTURE_RESOLVER_SCRIPT = preload("res://Scripts/MatchView/PieceTextureResolver.gd")
const PIECE_EFFECT_GEOMETRY_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/PieceEffectGeometryController.gd")
const PIECE_MOVE_ANIMATOR_SCRIPT = preload("res://Scripts/MatchView/PieceMoveAnimator.gd")
const PIECE_SHATTER_ANIMATOR_SCRIPT = preload("res://Scripts/MatchView/PieceShatterAnimator.gd")
const PIECE_RESPAWN_FRAGMENT_COORDINATOR_SCRIPT = preload("res://Scripts/MatchView/PieceRespawnFragmentCoordinator.gd")
const PIECE_DISPLAY_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/PieceDisplayController.gd")
const PIECE_EFFECT_ANIMATOR_SCRIPT = preload("res://Scripts/MatchView/PieceEffectAnimator.gd")
const PIECE_EFFECT_FLOW_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/PieceEffectFlowController.gd")
const FREEZE_EFFECT_ANIMATOR_SCRIPT = preload("res://Scripts/MatchView/FreezeEffectAnimator.gd")
const BOARD_EFFECT_ICON_GRID_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/BoardEffectIconGridController.gd")
const MATCH_STAMP_HUD_SCRIPT = preload("res://Scripts/MatchView/MatchStampHud.gd")
const MATCH_CODEX_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/MatchCodexController.gd")
const STAMP_HOVER_PREVIEW_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/StampHoverPreviewController.gd")
const PIECE_DURATION_CHANGE_ANIMATOR_SCRIPT = preload("res://Scripts/MatchView/PieceDurationChangeAnimator.gd")
const STAMP_INTERACTION_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/StampInteractionController.gd")
const STAMP_ANIMATION_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/StampAnimationController.gd")
const TURN_HUD_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/TurnHudController.gd")
const DECK_COUNTER_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/DeckCounterController.gd")
const MATCH_INPUT_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/MatchInputController.gd")
const MATCH_BOARD_LIFECYCLE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/MatchBoardLifecycleController.gd")
const STAMP_HAND_STATE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/StampHandStateController.gd")

var match_board
var match_board_lifecycle_controller
var board_geometry
var board_visuals
var board_environment_controller
var visual_process_tracker
var board_tile_controller
var board_marker_controller
var match_state_sync_controller
var server_state_update_controller
var server_state_visual_update_controller
var local_state_mutator
var local_move_flow_controller
var local_stamp_action_controller
var local_gameplay_controller
var tutorial_match_adapter
var game_result_controller
var turn_flow_controller
var turn_action_state_controller
var piece_texture_resolver
var piece_visuals
var piece_effect_geometry_controller
var piece_move_animator
var piece_shatter_animator
var piece_respawn_fragment_coordinator
var piece_display_controller
var piece_effect_animator
var piece_effect_flow_controller
var freeze_effect_animator
var board_effect_icon_grid_controller
var stamp_hud_controller
var match_codex_controller
var stamp_hover_preview_controller
var piece_duration_change_animator
var stamp_interaction_controller
var stamp_animation_controller
var deck_counter_controller
var turn_hud_controller
var match_input_controller
var stamp_hand_state_controller

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)

func initialize_startup_controllers() -> void:
	initialize_board_view_helpers()
	initialize_board_environment_controller()
	initialize_visual_process_tracker()
	initialize_board_tile_controller()
	initialize_match_state_sync_controller()
	initialize_server_state_update_controller()
	initialize_server_state_visual_update_controller()
	initialize_local_state_mutator()
	initialize_local_move_flow_controller()
	initialize_local_stamp_action_controller()
	initialize_local_gameplay_controller()
	initialize_tutorial_match_adapter()
	initialize_game_result_controller()
	initialize_turn_flow_controller()
	initialize_turn_action_state_controller()
	initialize_piece_visual_controller()
	initialize_piece_effect_geometry_controller()
	initialize_piece_move_animator()
	initialize_board_marker_controller()
	initialize_stamp_interaction_controller()
	initialize_stamp_animation_controller()
	initialize_deck_counter_controller()
	initialize_match_codex_controller()
	initialize_turn_hud_controller()
	initialize_match_input_controller()
	initialize_stamp_hand_state_controller()
	initialize_piece_shatter_animator()
	initialize_piece_respawn_fragment_coordinator()
	initialize_piece_display_controller()
	initialize_piece_effect_animator()
	initialize_piece_effect_flow_controller()
	initialize_freeze_effect_animator()

func initialize_match_board_lifecycle_controller() -> void:
	if match_board_lifecycle_controller == null:
		match_board_lifecycle_controller = MATCH_BOARD_LIFECYCLE_CONTROLLER_SCRIPT.new()
	sync_match_board_lifecycle_controller()

func sync_match_board_lifecycle_controller() -> void:
	if match_board_lifecycle_controller == null:
		return
	match_board_lifecycle_controller.configure({
		"match_board": match_board,
		"board_visual_scale": match_board.BOARD_VISUAL_SCALE,
	})

func get_match_board_lifecycle_controller():
	initialize_match_board_lifecycle_controller()
	return match_board_lifecycle_controller

func initialize_board_view_helpers() -> void:
	if board_geometry == null:
		board_geometry = BOARD_GEOMETRY_SCRIPT.new()
	if board_visuals == null:
		board_visuals = BOARD_VISUAL_CONTROLLER_SCRIPT.new()
	sync_board_geometry()
	board_visuals.configure(board_geometry)

func sync_board_geometry() -> void:
	if board_geometry == null:
		return
	board_geometry.configure({
		"board_size": match_board.BOARD_SIZE,
		"cell_width": match_board.CELL_WIDTH,
		"perspective_enabled": match_board.BOARD_PERSPECTIVE_ENABLED,
		"perspective_top_scale": match_board.BOARD_PERSPECTIVE_TOP_SCALE,
		"perspective_bottom_scale": match_board.BOARD_PERSPECTIVE_BOTTOM_SCALE,
		"perspective_vertical_scale": match_board.BOARD_PERSPECTIVE_VERTICAL_SCALE,
		"tile_slide_distance_factor": match_board.BOARD_TILE_SLIDE_DISTANCE_FACTOR,
		"tile_sink_offset": match_board.BOARD_TILE_SINK_OFFSET,
		"view_color": match_board.get_board_view_color(),
	})

func get_board_geometry():
	initialize_board_view_helpers()
	board_geometry.set_view_color(match_board.get_board_view_color())
	return board_geometry

func get_board_visuals():
	initialize_board_view_helpers()
	return board_visuals

func initialize_board_environment_controller() -> void:
	if board_environment_controller == null:
		board_environment_controller = BOARD_ENVIRONMENT_CONTROLLER_SCRIPT.new()
	sync_board_environment_controller()

func sync_board_environment_controller() -> void:
	if board_environment_controller == null:
		return
	board_environment_controller.configure({
		"match_board": match_board,
		"board_kuwahara_shader": match_board.BOARD_KUWAHARA_SHADER,
		"piece_kuwahara_shader": match_board.PIECE_KUWAHARA_SHADER,
		"board_shader_overlay_z_index": match_board.BOARD_SHADER_OVERLAY_Z_INDEX,
		"board_shader_radius": match_board.BOARD_SHADER_RADIUS,
		"piece_kuwahara_radius": match_board.PIECE_KUWAHARA_RADIUS,
		"board_frame_width": match_board.BOARD_FRAME_WIDTH,
		"board_frame_vertical_extension": match_board.BOARD_FRAME_VERTICAL_EXTENSION,
		"ambient_board_light_name": match_board.AMBIENT_BOARD_LIGHT_NAME,
		"ambient_board_fill_light_name": match_board.AMBIENT_BOARD_FILL_LIGHT_NAME,
		"ambient_board_light_texture_scale": match_board.AMBIENT_BOARD_LIGHT_TEXTURE_SCALE,
		"ambient_board_fill_light_texture_scale": match_board.AMBIENT_BOARD_FILL_LIGHT_TEXTURE_SCALE,
		"ambient_board_light_offset": match_board.AMBIENT_BOARD_LIGHT_OFFSET,
		"ambient_board_light_energy": match_board.AMBIENT_BOARD_LIGHT_ENERGY,
		"ambient_board_fill_light_energy": match_board.AMBIENT_BOARD_FILL_LIGHT_ENERGY,
		"ambient_board_light_color": match_board.AMBIENT_BOARD_LIGHT_COLOR,
		"ambient_board_light_shadow_color": match_board.AMBIENT_BOARD_LIGHT_SHADOW_COLOR,
		"ambient_board_light_shadow_smooth": match_board.AMBIENT_BOARD_LIGHT_SHADOW_SMOOTH,
		"board_light_receive_mask": match_board.BOARD_LIGHT_RECEIVE_MASK,
		"piece_light_occluder_mask": match_board.PIECE_LIGHT_OCCLUDER_MASK,
	})

func get_board_environment_controller():
	initialize_board_environment_controller()
	return board_environment_controller

func initialize_visual_process_tracker() -> void:
	if visual_process_tracker == null:
		visual_process_tracker = VISUAL_PROCESS_TRACKER_SCRIPT.new()

func get_visual_process_tracker():
	initialize_visual_process_tracker()
	return visual_process_tracker

func initialize_board_tile_controller() -> void:
	if board_tile_controller == null:
		board_tile_controller = BOARD_TILE_CONTROLLER_SCRIPT.new()
	sync_board_tile_controller()

func sync_board_tile_controller() -> void:
	if board_tile_controller == null:
		return
	board_tile_controller.configure({
		"match_board": match_board,
		"visuals": get_board_visuals(),
		"geometry": get_board_geometry(),
		"board_size": match_board.BOARD_SIZE,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
		"board_tile_texture": match_board.BOARD_TILE_TEXTURE,
		"board_tile_base_white_texture": match_board.BOARD_TILE_BASE_WHITE_TEXTURE,
		"board_tile_base_black_texture": match_board.BOARD_TILE_BASE_BLACK_TEXTURE,
		"board_tile_freeze_texture": match_board.BOARD_TILE_FREEZE_TEXTURE,
		"board_tile_disabled_texture": match_board.BOARD_TILE_DISABLED_TEXTURE,
		"special_tile_none": match_board.BOARD_SPECIAL_TILE_NONE,
		"special_tile_base_white": match_board.BOARD_SPECIAL_TILE_BASE_WHITE,
		"special_tile_base_black": match_board.BOARD_SPECIAL_TILE_BASE_BLACK,
		"special_tile_freeze": match_board.BOARD_SPECIAL_TILE_FREEZE,
		"special_tile_disabled": match_board.BOARD_SPECIAL_TILE_DISABLED,
		"special_tile_z_index": match_board.BOARD_SPECIAL_TILE_Z_INDEX,
		"tile_swap_duration": match_board.BOARD_TILE_SWAP_DURATION,
		"tile_sunk_alpha": match_board.BOARD_TILE_SUNK_ALPHA,
		"tile_depth_wall_color": match_board.BOARD_TILE_DEPTH_WALL_COLOR,
		"tile_occlusion_lip_color": match_board.BOARD_TILE_OCCLUSION_LIP_COLOR,
		"tile_occlusion_lip_inset_factor": match_board.BOARD_TILE_OCCLUSION_LIP_INSET_FACTOR,
		"tile_transition_cover_z_index": match_board.BOARD_TILE_TRANSITION_COVER_Z_INDEX,
		"frame_width": match_board.BOARD_FRAME_WIDTH,
		"frame_vertical_extension": match_board.BOARD_FRAME_VERTICAL_EXTENSION,
		"frame_color": match_board.BOARD_FRAME_COLOR,
		"side_thickness": match_board.BOARD_SIDE_THICKNESS,
		"side_color": match_board.BOARD_SIDE_COLOR,
		"shadow_enabled": match_board.board_shadow_enabled,
		"shadow_color": match_board.board_shadow_color,
		"shadow_offset": match_board.board_shadow_offset,
		"shadow_spread": match_board.board_shadow_spread,
		"shadow_steps": match_board.board_shadow_steps,
	})

func get_board_tile_controller():
	initialize_board_tile_controller()
	return board_tile_controller

func initialize_board_marker_controller() -> void:
	if board_marker_controller == null:
		board_marker_controller = BOARD_MARKER_CONTROLLER_SCRIPT.new()
	sync_board_marker_controller()

func sync_board_marker_controller() -> void:
	if board_marker_controller == null:
		return
	board_marker_controller.configure({
		"geometry": get_board_geometry(),
		"visuals": get_board_visuals(),
		"dots_node": match_board.dots,
		"board_markers_node": match_board.board_markers_node,
		"texture_holder_scene": TEXTURE_HOLDER,
		"move_option_dot_texture": match_board.MOVE_OPTION_DOT_TEXTURE,
		"move_option_dot_shader": match_board.MOVE_OPTION_DOT_SHADER,
		"cell_width": match_board.CELL_WIDTH,
		"board_size": match_board.BOARD_SIZE,
		"move_option_dot_cell_width_ratio": match_board.MOVE_OPTION_DOT_CELL_WIDTH_RATIO,
		"move_option_dot_shader_speed": match_board.MOVE_OPTION_DOT_SHADER_SPEED,
		"move_option_dot_shader_glow_strength": match_board.MOVE_OPTION_DOT_SHADER_GLOW_STRENGTH,
		"move_option_dot_shader_edge_softness": match_board.MOVE_OPTION_DOT_SHADER_EDGE_SOFTNESS,
		"move_option_dot_shader_pulse_min_scale": match_board.MOVE_OPTION_DOT_SHADER_PULSE_MIN_SCALE,
		"move_option_dot_shader_pulse_max_scale": match_board.MOVE_OPTION_DOT_SHADER_PULSE_MAX_SCALE,
		"move_option_dot_shader_color": match_board.MOVE_OPTION_DOT_SHADER_COLOR,
		"last_move_arrow_color": match_board.LAST_MOVE_ARROW_COLOR,
		"last_move_arrow_width": match_board.LAST_MOVE_ARROW_WIDTH,
		"last_move_arrow_endpoint_inset": match_board.LAST_MOVE_ARROW_ENDPOINT_INSET,
		"last_move_arrow_head_length": match_board.LAST_MOVE_ARROW_HEAD_LENGTH,
		"last_move_arrow_head_half_width": match_board.LAST_MOVE_ARROW_HEAD_HALF_WIDTH,
		"piece_objects_provider": Callable(match_board, "get_piece_objects"),
		"board_effects_provider": Callable(match_board, "get_current_board_effects"),
		"current_last_move_provider": Callable(match_board, "get_current_last_move"),
		"local_view_color_provider": Callable(match_board, "get_local_view_color"),
		"local_view_ready_provider": Callable(match_board, "is_local_view_ready"),
		"own_player_id_provider": Callable(match_board, "get_own_player_id"),
		"can_move_action_now_provider": Callable(match_board, "can_move_action_now"),
		"can_player_control_piece_at_provider": Callable(match_board, "can_player_control_piece_at"),
		"update_special_tiles_callback": Callable(get_board_tile_controller(), "update_board_special_tiles"),
	})

func get_board_marker_controller():
	initialize_board_marker_controller()
	return board_marker_controller

func initialize_match_state_sync_controller() -> void:
	if match_state_sync_controller == null:
		match_state_sync_controller = MATCH_STATE_SYNC_CONTROLLER_SCRIPT.new()
	sync_match_state_sync_controller()

func sync_match_state_sync_controller() -> void:
	if match_state_sync_controller == null:
		return
	match_state_sync_controller.configure({
		"board_size": match_board.BOARD_SIZE,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
		"white_base_field": match_board.WHITE_BASE_FIELD,
		"black_base_field": match_board.BLACK_BASE_FIELD,
		"fragment_group_none": match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE,
		"fragment_group_bottom": match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM,
		"fragment_group_top": match_board.PIECE_SHATTER_FRAGMENT_GROUP_TOP,
		"fragment_group_pending": match_board.PIECE_SHATTER_FRAGMENT_GROUP_PENDING,
		"default_piece_texture_provider": Callable(get_piece_texture_resolver(), "get_default_piece_texture"),
		"stamp_piece_texture_provider": Callable(get_piece_texture_resolver(), "get_stamp_piece_texture_for_color"),
	})

func get_match_state_sync_controller():
	initialize_match_state_sync_controller()
	return match_state_sync_controller

func initialize_server_state_update_controller() -> void:
	if server_state_update_controller == null:
		server_state_update_controller = SERVER_STATE_UPDATE_CONTROLLER_SCRIPT.new()
	sync_server_state_update_controller()

func sync_server_state_update_controller() -> void:
	if server_state_update_controller == null:
		return
	server_state_update_controller.configure({
		"match_board": match_board,
	})

func get_server_state_update_controller():
	initialize_server_state_update_controller()
	return server_state_update_controller

func initialize_server_state_visual_update_controller() -> void:
	if server_state_visual_update_controller == null:
		server_state_visual_update_controller = SERVER_STATE_VISUAL_UPDATE_CONTROLLER_SCRIPT.new()
	sync_server_state_visual_update_controller()

func sync_server_state_visual_update_controller() -> void:
	if server_state_visual_update_controller == null:
		return
	server_state_visual_update_controller.configure({
		"match_board": match_board,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
	})

func get_server_state_visual_update_controller():
	initialize_server_state_visual_update_controller()
	return server_state_visual_update_controller

func initialize_local_state_mutator() -> void:
	if local_state_mutator == null:
		local_state_mutator = LOCAL_STATE_MUTATOR_SCRIPT.new()
	sync_local_state_mutator()

func sync_local_state_mutator() -> void:
	if local_state_mutator == null:
		return
	local_state_mutator.configure({
		"board": match_board.board,
		"piece_objects": match_board.piece_objects,
		"local_pending_respawns": match_board.local_pending_respawns,
		"moved_piece_this_turn": match_board.moved_piece_this_turn,
		"played_stamp_hand_slots_this_turn": match_board.played_stamp_hand_slots_this_turn,
		"player_base_fields": match_board.current_player_base_fields,
		"board_effects": match_board.current_board_effects,
		"board_size": match_board.BOARD_SIZE,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
		"fragment_group_none": match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE,
		"fragment_group_bottom": match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM,
		"fragment_group_top": match_board.PIECE_SHATTER_FRAGMENT_GROUP_TOP,
		"fragment_group_pending": match_board.PIECE_SHATTER_FRAGMENT_GROUP_PENDING,
		"player_id_for_color_provider": Callable(match_board, "get_player_id_for_color"),
		"stamp_hand_provider": Callable(match_board, "get_stamp_hand"),
		"stamp_deck_provider": Callable(match_board, "get_stamp_deck"),
		"current_turn_color_provider": Callable(match_board, "get_current_turn_color"),
		"moved_piece_this_turn_provider": Callable(get_turn_action_state_controller(), "has_moved_piece_this_turn"),
		"can_exchange_stamp_provider": Callable(match_board, "can_exchange_stamp_locally"),
		"can_turn_page_provider": Callable(get_match_codex_controller(), "can_turn_page_locally"),
		"create_board_tiles_callback": Callable(match_board, "create_board_tiles"),
	})

func get_local_state_mutator():
	initialize_local_state_mutator()
	sync_local_state_mutator()
	return local_state_mutator

func initialize_local_move_flow_controller() -> void:
	if local_move_flow_controller == null:
		local_move_flow_controller = LOCAL_MOVE_FLOW_CONTROLLER_SCRIPT.new()
	sync_local_move_flow_controller()

func sync_local_move_flow_controller() -> void:
	if local_move_flow_controller == null:
		return
	local_move_flow_controller.configure({
		"match_board": match_board,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
		"fragment_group_none": match_board.PIECE_SHATTER_FRAGMENT_GROUP_NONE,
	})

func get_local_move_flow_controller():
	initialize_local_move_flow_controller()
	return local_move_flow_controller

func initialize_local_stamp_action_controller() -> void:
	if local_stamp_action_controller == null:
		local_stamp_action_controller = LOCAL_STAMP_ACTION_CONTROLLER_SCRIPT.new()
	sync_local_stamp_action_controller()

func sync_local_stamp_action_controller() -> void:
	if local_stamp_action_controller == null:
		return
	local_stamp_action_controller.configure({
		"match_board": match_board,
	})

func get_local_stamp_action_controller():
	initialize_local_stamp_action_controller()
	return local_stamp_action_controller

func initialize_local_gameplay_controller() -> void:
	if local_gameplay_controller == null:
		local_gameplay_controller = LOCAL_GAMEPLAY_CONTROLLER_SCRIPT.new()
	sync_local_gameplay_controller()

func sync_local_gameplay_controller() -> void:
	if local_gameplay_controller == null:
		return
	local_gameplay_controller.configure({
		"match_board": match_board,
		"board_size": match_board.BOARD_SIZE,
	})

func get_local_gameplay_controller():
	initialize_local_gameplay_controller()
	return local_gameplay_controller

func initialize_tutorial_match_adapter() -> void:
	if tutorial_match_adapter == null:
		tutorial_match_adapter = TUTORIAL_MATCH_ADAPTER_SCRIPT.new()
	sync_tutorial_match_adapter()

func sync_tutorial_match_adapter() -> void:
	if tutorial_match_adapter == null:
		return
	tutorial_match_adapter.configure({
		"match_board": match_board,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
		"board_size": match_board.BOARD_SIZE,
	})

func get_tutorial_match_adapter():
	initialize_tutorial_match_adapter()
	return tutorial_match_adapter

func initialize_game_result_controller() -> void:
	if game_result_controller == null:
		game_result_controller = GAME_RESULT_CONTROLLER_SCRIPT.new()
	sync_game_result_controller()

func sync_game_result_controller() -> void:
	if game_result_controller == null:
		return
	game_result_controller.configure({
		"match_board": match_board,
		"main_menu_scene": match_board.MAIN_MENU_SCENE,
		"match_end_feedback_scene": match_board.MATCH_END_FEEDBACK_SCENE,
	})

func get_game_result_controller():
	initialize_game_result_controller()
	return game_result_controller

func initialize_turn_flow_controller() -> void:
	if turn_flow_controller == null:
		turn_flow_controller = TURN_FLOW_CONTROLLER_SCRIPT.new()
	sync_turn_flow_controller()

func sync_turn_flow_controller() -> void:
	if turn_flow_controller == null:
		return
	turn_flow_controller.configure({
		"match_board": match_board,
		"board_size": match_board.BOARD_SIZE,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
	})

func get_turn_flow_controller():
	initialize_turn_flow_controller()
	return turn_flow_controller

func initialize_turn_action_state_controller() -> void:
	if turn_action_state_controller == null:
		turn_action_state_controller = TURN_ACTION_STATE_CONTROLLER_SCRIPT.new()
	sync_turn_action_state_controller()

func sync_turn_action_state_controller() -> void:
	if turn_action_state_controller == null:
		return
	turn_action_state_controller.configure({
		"match_board": match_board,
	})

func get_turn_action_state_controller():
	initialize_turn_action_state_controller()
	return turn_action_state_controller

func initialize_piece_texture_resolver() -> void:
	if piece_texture_resolver == null:
		piece_texture_resolver = PIECE_TEXTURE_RESOLVER_SCRIPT.new()
	sync_piece_texture_resolver()

func sync_piece_texture_resolver() -> void:
	if piece_texture_resolver == null:
		return
	piece_texture_resolver.configure({
		"match_board": match_board,
		"default_piece_texture": match_board.DEFAULT_PIECE_TEXTURE,
		"own_default_piece_texture": match_board.OWN_DEFAULT_PIECE_TEXTURE,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
	})

func get_piece_texture_resolver():
	initialize_piece_texture_resolver()
	return piece_texture_resolver

func initialize_piece_visual_controller() -> void:
	if piece_visuals == null:
		piece_visuals = PIECE_VISUAL_CONTROLLER_SCRIPT.new()
	sync_piece_visual_controller()

func sync_piece_visual_controller() -> void:
	if piece_visuals == null:
		return
	piece_visuals.configure({
		"geometry": get_board_geometry(),
		"board_size": match_board.BOARD_SIZE,
		"cell_width": match_board.CELL_WIDTH,
		"view_color": match_board.get_board_view_color(),
		"texture_filter": match_board.PIECE_TEXTURE_FILTER,
		"default_piece_texture": match_board.DEFAULT_PIECE_TEXTURE,
		"own_default_piece_texture": match_board.OWN_DEFAULT_PIECE_TEXTURE,
		"default_piece_visual_height": match_board.DEFAULT_PIECE_VISUAL_HEIGHT,
		"piece_auto_fit_height_threshold": match_board.PIECE_AUTO_FIT_HEIGHT_THRESHOLD,
		"default_piece_bottom_inset": match_board.DEFAULT_PIECE_BOTTOM_INSET,
		"piece_perspective_scale_variation": match_board.PIECE_PERSPECTIVE_SCALE_VARIATION,
		"piece_shadow_name": match_board.PIECE_SHADOW_NAME,
		"piece_shadow_light_texture_scale": match_board.PIECE_SHADOW_LIGHT_TEXTURE_SCALE,
		"piece_shadow_light_source_offset": match_board.PIECE_SHADOW_LIGHT_SOURCE_OFFSET,
		"piece_shadow_light_energy": match_board.PIECE_SHADOW_LIGHT_ENERGY,
		"piece_shadow_light_color": match_board.PIECE_SHADOW_LIGHT_COLOR,
		"piece_shadow_light_shadow_color": match_board.PIECE_SHADOW_LIGHT_SHADOW_COLOR,
		"piece_shadow_light_shadow_smooth": match_board.PIECE_SHADOW_LIGHT_SHADOW_SMOOTH,
		"board_light_receive_mask": match_board.BOARD_LIGHT_RECEIVE_MASK,
		"piece_light_occluder_mask": match_board.PIECE_LIGHT_OCCLUDER_MASK,
		"piece_light_receive_mask": match_board.PIECE_LIGHT_RECEIVE_MASK,
		"piece_effect_light_receive_mask": match_board.PIECE_EFFECT_LIGHT_RECEIVE_MASK,
		"piece_light_occluder_name": match_board.PIECE_LIGHT_OCCLUDER_NAME,
		"piece_light_occluder_footprint_width_factor": match_board.PIECE_LIGHT_OCCLUDER_FOOTPRINT_WIDTH_FACTOR,
		"piece_light_occluder_footprint_fixed_radius_y": match_board.PIECE_LIGHT_OCCLUDER_FOOTPRINT_FIXED_RADIUS_Y,
		"piece_light_occluder_footprint_bottom_inset_factor": match_board.PIECE_LIGHT_OCCLUDER_FOOTPRINT_BOTTOM_INSET_FACTOR,
		"piece_light_occluder_footprint_offset": match_board.PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET,
		"piece_light_occluder_footprint_segments": match_board.PIECE_LIGHT_OCCLUDER_FOOTPRINT_SEGMENTS,
		"piece_footprint_alpha_threshold": match_board.PIECE_FOOTPRINT_ALPHA_THRESHOLD,
		"piece_footprint_width_scan_start_ratio": match_board.PIECE_FOOTPRINT_WIDTH_SCAN_START_RATIO,
		"piece_footprint_stable_width_band_ratio": match_board.PIECE_FOOTPRINT_STABLE_WIDTH_BAND_RATIO,
		"piece_footprint_stable_row_sample_count": match_board.PIECE_FOOTPRINT_STABLE_ROW_SAMPLE_COUNT,
		"piece_light_occluder_footprint_min_radius_bounds_factor": match_board.PIECE_LIGHT_OCCLUDER_FOOTPRINT_MIN_RADIUS_BOUNDS_FACTOR,
		"attach_effect_names": [match_board.PIECE_ATTACH_GLOW_NAME, match_board.PIECE_ATTACH_TARGET_GLOW_NAME, match_board.PIECE_ATTACH_RAYS_NAME, match_board.PIECE_ATTACH_MORPH_NAME],
	})

func get_piece_visuals():
	initialize_piece_visual_controller()
	return piece_visuals

func initialize_piece_effect_geometry_controller() -> void:
	if piece_effect_geometry_controller == null:
		piece_effect_geometry_controller = PIECE_EFFECT_GEOMETRY_CONTROLLER_SCRIPT.new()
	sync_piece_effect_geometry_controller()

func sync_piece_effect_geometry_controller() -> void:
	if piece_effect_geometry_controller == null:
		return
	piece_effect_geometry_controller.configure({
		"match_board": match_board,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
		"attach_point_light_texture_size": match_board.ATTACH_POINT_LIGHT_TEXTURE_SIZE,
		"light_texture_grain_strength": match_board.LIGHT_TEXTURE_GRAIN_STRENGTH,
		"light_texture_fine_grain_strength": match_board.LIGHT_TEXTURE_FINE_GRAIN_STRENGTH,
		"light_texture_grain_frequency": match_board.LIGHT_TEXTURE_GRAIN_FREQUENCY,
		"light_texture_fine_grain_frequency": match_board.LIGHT_TEXTURE_FINE_GRAIN_FREQUENCY,
	})

func get_piece_effect_geometry_controller():
	initialize_piece_effect_geometry_controller()
	return piece_effect_geometry_controller

func initialize_piece_move_animator() -> void:
	if piece_move_animator == null:
		piece_move_animator = PIECE_MOVE_ANIMATOR_SCRIPT.new()
	sync_piece_move_animator()

func sync_piece_move_animator() -> void:
	if piece_move_animator == null:
		return
	var effect_geometry_controller = get_piece_effect_geometry_controller()
	piece_move_animator.configure({
		"geometry": get_board_geometry(),
		"piece_visuals": get_piece_visuals(),
		"tween_owner": match_board,
		"cell_width": match_board.CELL_WIDTH,
		"board_size": match_board.BOARD_SIZE,
		"move_duration": match_board.piece_move_duration,
		"move_lift_ratio": match_board.piece_move_lift_ratio,
		"lift_duration": match_board.piece_move_lift_duration,
		"drop_duration": match_board.piece_move_drop_duration,
		"wobble_step_duration": match_board.piece_move_wobble_step_duration,
		"wobble_rotation_degrees": match_board.piece_move_wobble_rotation_degrees,
		"movement_tilt_degrees": match_board.piece_move_travel_tilt_degrees,
		"capture_approach_edge_ratio": match_board.piece_move_capture_approach_edge_ratio,
		"capture_approach_hold_duration": match_board.piece_move_capture_approach_hold_duration,
		"capture_push_duration": match_board.piece_move_capture_push_duration,
		"capture_recoil_duration": match_board.piece_move_capture_recoil_duration,
		"capture_center_settle_duration": match_board.piece_move_capture_center_settle_duration,
		"capture_push_rotation_degrees": match_board.piece_move_capture_push_rotation_degrees,
		"movement_shadow_color": match_board.piece_move_shadow_color,
		"movement_shadow_radius_scale": match_board.piece_move_shadow_radius_scale,
		"movement_shadow_ground_edge_softness": match_board.piece_move_shadow_ground_edge_softness,
		"movement_shadow_lifted_edge_softness": match_board.piece_move_shadow_lifted_edge_softness,
		"movement_shadow_lifted_scale": match_board.piece_move_shadow_lifted_scale,
		"movement_shadow_lifted_alpha": match_board.piece_move_shadow_lifted_alpha,
		"corner_rounding_ratio": match_board.PIECE_MOVE_ROUTE_CORNER_ROUNDING_RATIO,
		"corner_sample_count": match_board.PIECE_MOVE_ROUTE_CORNER_SAMPLE_COUNT,
		"pieces_node": match_board.pieces_node,
		"local_space_node": match_board,
		"avoid_occupied_footprints": match_board.piece_move_avoid_occupied_footprints,
		"footprint_clearance": match_board.piece_move_footprint_clearance,
		"footprint_fixed_radius_y": match_board.PIECE_LIGHT_OCCLUDER_FOOTPRINT_FIXED_RADIUS_Y,
		"route_z_front_offset": match_board.PIECE_MOVE_ROUTE_Z_FRONT_OFFSET,
		"route_z_back_offset": match_board.PIECE_MOVE_ROUTE_Z_BACK_OFFSET,
		"view_color": match_board.get_board_view_color(),
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
		"piece_exists_provider": Callable(match_board, "has_piece_object_at"),
		"sprite_bounds_provider": Callable(effect_geometry_controller, "get_sprite_texture_bounds_local"),
	})

func get_piece_move_animator():
	initialize_piece_move_animator()
	return piece_move_animator

func initialize_piece_shatter_animator() -> void:
	if piece_shatter_animator == null:
		piece_shatter_animator = PIECE_SHATTER_ANIMATOR_SCRIPT.new()
	sync_piece_shatter_animator()

func sync_piece_shatter_animator() -> void:
	if piece_shatter_animator == null:
		return
	var respawn_fragment_coordinator = get_piece_respawn_fragment_coordinator()
	piece_shatter_animator.configure({
		"geometry": get_board_geometry(),
		"piece_visuals": get_piece_visuals(),
		"pieces_node": match_board.pieces_node,
		"piece_effects_node": match_board.piece_effects_node,
		"tween_owner": match_board,
		"board_size": match_board.BOARD_SIZE,
		"cell_width": match_board.CELL_WIDTH,
		"view_color": match_board.get_board_view_color(),
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
		"texture_filter": match_board.PIECE_TEXTURE_FILTER,
		"piece_effect_light_receive_mask": match_board.PIECE_EFFECT_LIGHT_RECEIVE_MASK,
		"flipped_view": match_board.side != null && !match_board.side,
		"returning_debris_count": match_board.piece_shatter_returning_debris_count,
		"scatter_duration": match_board.piece_shatter_scatter_duration,
		"fade_duration": match_board.piece_shatter_fade_duration,
		"return_duration": match_board.piece_shatter_return_duration,
		"return_fade_duration": match_board.piece_shatter_return_fade_duration,
		"fragment_settle_duration": match_board.piece_shatter_fragment_settle_duration,
		"scatter_radius": match_board.piece_shatter_scatter_radius,
		"scatter_jitter": match_board.piece_shatter_scatter_jitter,
		"min_piece_scale": match_board.piece_shatter_min_piece_scale,
		"max_piece_scale": match_board.piece_shatter_max_piece_scale,
		"avoid_occupied_cells": match_board.piece_shatter_avoid_occupied_cells,
		"route_jitter_ratio": match_board.piece_shatter_route_jitter_ratio,
		"fragment_landing_hold_duration": match_board.PIECE_SHATTER_FRAGMENT_LANDING_HOLD_DURATION,
		"route_z_front_offset": match_board.PIECE_SHATTER_ROUTE_Z_FRONT_OFFSET,
		"route_z_back_offset": match_board.PIECE_SHATTER_ROUTE_Z_BACK_OFFSET,
		"route_direct_fallback_offset": match_board.PIECE_SHATTER_ROUTE_DIRECT_FALLBACK_OFFSET,
		"return_acceleration_progress": match_board.PIECE_SHATTER_RETURN_ACCELERATION_PROGRESS,
		"fragment_group_bottom": match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM,
		"route_cell_blocked_provider": Callable(respawn_fragment_coordinator, "is_piece_shatter_route_cell_blocked"),
		"finish_respawn_fragment_callback": Callable(respawn_fragment_coordinator, "finish_piece_shatter_respawn_fragment"),
		"player_id_for_color_provider": Callable(match_board, "get_player_id_for_color"),
		"antialias_provider": Callable(get_board_visuals(), "enable_canvas_item_antialiasing"),
	})

func get_piece_shatter_animator():
	initialize_piece_shatter_animator()
	return piece_shatter_animator

func initialize_piece_respawn_fragment_coordinator() -> void:
	if piece_respawn_fragment_coordinator == null:
		piece_respawn_fragment_coordinator = PIECE_RESPAWN_FRAGMENT_COORDINATOR_SCRIPT.new()
	sync_piece_respawn_fragment_coordinator()

func sync_piece_respawn_fragment_coordinator() -> void:
	if piece_respawn_fragment_coordinator == null:
		return
	piece_respawn_fragment_coordinator.configure({
		"match_board": match_board,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
	})

func get_piece_respawn_fragment_coordinator():
	initialize_piece_respawn_fragment_coordinator()
	return piece_respawn_fragment_coordinator

func initialize_piece_display_controller() -> void:
	if piece_display_controller == null:
		piece_display_controller = PIECE_DISPLAY_CONTROLLER_SCRIPT.new()
	sync_piece_display_controller()

func sync_piece_display_controller() -> void:
	if piece_display_controller == null:
		return
	piece_display_controller.configure({
		"match_board": match_board,
		"piece_visuals": get_piece_visuals(),
		"texture_resolver": get_piece_texture_resolver(),
		"texture_holder_scene": TEXTURE_HOLDER,
		"board_size": match_board.BOARD_SIZE,
		"piece_light_receive_mask": match_board.PIECE_LIGHT_RECEIVE_MASK,
		"selected_piece_glow_name": match_board.SELECTED_PIECE_GLOW_NAME,
		"selected_piece_glow_z_index": match_board.SELECTED_PIECE_GLOW_Z_INDEX,
		"selected_piece_glow_strength": match_board.SELECTED_PIECE_GLOW_STRENGTH,
		"piece_hover_dim_color": match_board.PIECE_HOVER_DIM_COLOR,
		"piece_hover_dim_tween_duration": match_board.PIECE_HOVER_DIM_TWEEN_DURATION,
		"piece_shadow_light_energy": match_board.PIECE_SHADOW_LIGHT_ENERGY,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
	})

func get_piece_display_controller():
	initialize_piece_display_controller()
	return piece_display_controller

func initialize_piece_effect_animator() -> void:
	if piece_effect_animator == null:
		piece_effect_animator = PIECE_EFFECT_ANIMATOR_SCRIPT.new()
	sync_piece_effect_animator()

func sync_piece_effect_animator() -> void:
	if piece_effect_animator == null:
		return
	var effect_geometry_controller = get_piece_effect_geometry_controller()
	piece_effect_animator.configure({
		"geometry": get_board_geometry(),
		"piece_visuals": get_piece_visuals(),
		"pieces_node": match_board.pieces_node,
		"piece_effects_node": match_board.piece_effects_node,
		"tween_owner": match_board,
		"texture_holder_scene": TEXTURE_HOLDER,
		"cell_width": match_board.CELL_WIDTH,
		"board_size": match_board.BOARD_SIZE,
		"texture_filter": match_board.PIECE_TEXTURE_FILTER,
		"board_light_receive_mask": match_board.BOARD_LIGHT_RECEIVE_MASK,
		"piece_light_receive_mask": match_board.PIECE_LIGHT_RECEIVE_MASK,
		"piece_effect_light_receive_mask": match_board.PIECE_EFFECT_LIGHT_RECEIVE_MASK,
		"piece_light_occluder_mask": match_board.PIECE_LIGHT_OCCLUDER_MASK,
		"flipped_view": match_board.side != null && !match_board.side,
		"default_piece_visual_height": match_board.DEFAULT_PIECE_VISUAL_HEIGHT,
		"piece_capture_sparkle_shader": match_board.PIECE_CAPTURE_SPARKLE_SHADER,
		"capture_sparkle_color": match_board.capture_sparkle_color,
		"capture_sparkle_duration": match_board.capture_sparkle_duration,
		"capture_sparkle_fade_out_ratio": match_board.capture_sparkle_fade_out_ratio,
		"capture_sparkle_size_ratio": match_board.capture_sparkle_size_ratio,
		"capture_sparkle_shader_scale": match_board.capture_sparkle_shader_scale,
		"capture_sparkle_decay_magnitude": match_board.capture_sparkle_decay_magnitude,
		"capture_sparkle_rotate_speed": match_board.capture_sparkle_rotate_speed,
		"capture_sparkle_time_speed": match_board.capture_sparkle_time_speed,
		"capture_sparkle_frequency_base": match_board.capture_sparkle_frequency_base,
		"capture_sparkle_frequency_disturbance_scale": match_board.capture_sparkle_frequency_disturbance_scale,
		"capture_sparkle_circle_ratio": match_board.capture_sparkle_circle_ratio,
		"bomb_warning_texture": match_board.BOMB_WARNING_TEXTURE,
		"bomb_warning_color": match_board.bomb_warning_color,
		"bomb_warning_duration": match_board.bomb_warning_duration,
		"bomb_warning_rise_distance": match_board.bomb_warning_rise_distance,
		"bomb_warning_size_ratio": match_board.bomb_warning_size_ratio,
		"bomb_warning_target_y_offset": match_board.bomb_warning_target_y_offset,
		"bomb_warning_z_offset": match_board.BOMB_WARNING_Z_OFFSET,
		"piece_expire_dissolve_shader": match_board.PIECE_EXPIRE_DISSOLVE_SHADER,
		"piece_expire_dissolve_duration": match_board.PIECE_EXPIRE_DISSOLVE_DURATION,
		"piece_expire_dissolve_beam_size": match_board.PIECE_EXPIRE_DISSOLVE_BEAM_SIZE,
		"piece_expire_dissolve_noise_density": match_board.PIECE_EXPIRE_DISSOLVE_NOISE_DENSITY,
		"piece_expire_dissolve_color": match_board.PIECE_EXPIRE_DISSOLVE_COLOR,
		"piece_invisibility_refract_shader": match_board.PIECE_INVISIBILITY_REFRACT_SHADER,
		"piece_invisibility_visible_hold_duration": match_board.PIECE_INVISIBILITY_VISIBLE_HOLD_DURATION,
		"piece_invisibility_refract_in_duration": match_board.PIECE_INVISIBILITY_REFRACT_IN_DURATION,
		"piece_invisibility_fade_out_duration": match_board.PIECE_INVISIBILITY_FADE_OUT_DURATION,
		"piece_invisibility_refract_distance": match_board.PIECE_INVISIBILITY_REFRACT_DISTANCE,
		"attach_point_light_name": match_board.ATTACH_POINT_LIGHT_NAME,
		"attach_piece_light_name": match_board.ATTACH_PIECE_LIGHT_NAME,
		"attach_point_light_texture_scale": match_board.ATTACH_POINT_LIGHT_TEXTURE_SCALE,
		"attach_point_light_color": match_board.ATTACH_POINT_LIGHT_COLOR,
		"attach_point_light_shadow_color": match_board.ATTACH_POINT_LIGHT_SHADOW_COLOR,
		"attach_point_light_shadow_smooth": match_board.ATTACH_POINT_LIGHT_SHADOW_SMOOTH,
		"attach_piece_light_texture_scale": match_board.ATTACH_PIECE_LIGHT_TEXTURE_SCALE,
		"attach_piece_light_color": match_board.ATTACH_PIECE_LIGHT_COLOR,
		"attach_point_light_energy": match_board.ATTACH_POINT_LIGHT_ENERGY,
		"attach_piece_light_energy": match_board.ATTACH_PIECE_LIGHT_ENERGY,
		"piece_attach_glow_name": match_board.PIECE_ATTACH_GLOW_NAME,
		"piece_attach_target_glow_name": match_board.PIECE_ATTACH_TARGET_GLOW_NAME,
		"piece_attach_rays_name": match_board.PIECE_ATTACH_RAYS_NAME,
		"piece_attach_morph_name": match_board.PIECE_ATTACH_MORPH_NAME,
		"piece_effect_occlusion_dim_name": match_board.PIECE_EFFECT_OCCLUSION_DIM_NAME,
		"piece_attach_glow_z_index": match_board.PIECE_ATTACH_GLOW_Z_INDEX,
		"piece_attach_rays_z_index": match_board.PIECE_ATTACH_RAYS_Z_INDEX,
		"piece_attach_morph_z_index": match_board.PIECE_ATTACH_MORPH_Z_INDEX,
		"piece_effect_occlusion_dim_z_index": match_board.PIECE_EFFECT_OCCLUSION_DIM_Z_INDEX,
		"piece_attach_glow_shader": match_board.PIECE_ATTACH_GLOW_SHADER,
		"piece_attach_rays_shader": match_board.PIECE_ATTACH_RAYS_SHADER,
		"piece_texture_morph_shader": match_board.PIECE_TEXTURE_MORPH_SHADER,
		"piece_attach_glow_color": match_board.PIECE_ATTACH_GLOW_COLOR,
		"occluded_piece_effect_dim_color": match_board.occluded_piece_effect_dim_color,
		"piece_attach_glow_size": match_board.PIECE_ATTACH_GLOW_SIZE,
		"piece_attach_glow_fill_strength": match_board.PIECE_ATTACH_GLOW_FILL_STRENGTH,
		"piece_attach_glow_base_strength": match_board.PIECE_ATTACH_GLOW_BASE_STRENGTH,
		"piece_attach_glow_switch_strength": match_board.PIECE_ATTACH_GLOW_SWITCH_STRENGTH,
		"piece_attach_glow_switch_duration": match_board.PIECE_ATTACH_GLOW_SWITCH_DURATION,
		"piece_attach_in_duration": match_board.PIECE_ATTACH_IN_DURATION,
		"piece_attach_pre_switch_hold_duration": match_board.PIECE_ATTACH_PRE_SWITCH_HOLD_DURATION,
		"piece_attach_morph_duration": match_board.PIECE_ATTACH_MORPH_DURATION,
		"piece_attach_target_appear_duration": match_board.PIECE_ATTACH_TARGET_APPEAR_DURATION,
		"piece_attach_post_switch_hold_duration": match_board.PIECE_ATTACH_POST_SWITCH_HOLD_DURATION,
		"piece_attach_morph_noise_strength": match_board.PIECE_ATTACH_MORPH_NOISE_STRENGTH,
		"piece_attach_morph_shine_strength": match_board.PIECE_ATTACH_MORPH_SHINE_STRENGTH,
		"piece_attach_out_duration": match_board.PIECE_ATTACH_OUT_DURATION,
		"piece_attach_rays_start_size": match_board.PIECE_ATTACH_RAYS_START_SIZE,
		"piece_attach_rays_switch_size": match_board.PIECE_ATTACH_RAYS_SWITCH_SIZE,
		"piece_attach_rays_texture_size": match_board.PIECE_ATTACH_RAYS_TEXTURE_SIZE,
		"piece_attach_rays_overlay_scale": match_board.PIECE_ATTACH_RAYS_OVERLAY_SCALE,
		"piece_attach_rays_local_offset": match_board.PIECE_ATTACH_RAYS_LOCAL_OFFSET,
		"piece_attach_rays_spread": match_board.PIECE_ATTACH_RAYS_SPREAD,
		"piece_attach_rays_cutoff": match_board.PIECE_ATTACH_RAYS_CUTOFF,
		"piece_attach_rays_speed": match_board.PIECE_ATTACH_RAYS_SPEED,
		"piece_attach_rays_ray1_density": match_board.PIECE_ATTACH_RAYS_RAY1_DENSITY,
		"piece_attach_rays_ray2_density": match_board.PIECE_ATTACH_RAYS_RAY2_DENSITY,
		"piece_attach_rays_ray2_intensity": match_board.PIECE_ATTACH_RAYS_RAY2_INTENSITY,
		"piece_attach_rays_core_intensity": match_board.PIECE_ATTACH_RAYS_CORE_INTENSITY,
		"piece_attach_rays_seed": match_board.PIECE_ATTACH_RAYS_SEED,
		"piece_attach_rays_fade_in_delay_ratio": match_board.PIECE_ATTACH_RAYS_FADE_IN_DELAY_RATIO,
		"piece_attach_rays_fade_in_duration_ratio": match_board.PIECE_ATTACH_RAYS_FADE_IN_DURATION_RATIO,
		"attach_point_light_texture_provider": Callable(effect_geometry_controller, "get_attach_point_light_texture"),
		"piece_light_global_position_provider": Callable(effect_geometry_controller, "get_piece_light_global_position_for_texture"),
		"sprite_bounds_provider": Callable(effect_geometry_controller, "get_sprite_texture_bounds_local"),
	})

func get_piece_effect_animator():
	initialize_piece_effect_animator()
	return piece_effect_animator

func initialize_piece_effect_flow_controller() -> void:
	if piece_effect_flow_controller == null:
		piece_effect_flow_controller = PIECE_EFFECT_FLOW_CONTROLLER_SCRIPT.new()
	sync_piece_effect_flow_controller()

func sync_piece_effect_flow_controller() -> void:
	if piece_effect_flow_controller == null:
		return
	piece_effect_flow_controller.configure({
		"match_board": match_board,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
	})

func get_piece_effect_flow_controller():
	initialize_piece_effect_flow_controller()
	return piece_effect_flow_controller

func initialize_freeze_effect_animator() -> void:
	if freeze_effect_animator == null:
		freeze_effect_animator = FREEZE_EFFECT_ANIMATOR_SCRIPT.new()
	sync_freeze_effect_animator()

func sync_freeze_effect_animator() -> void:
	if freeze_effect_animator == null:
		return
	var effect_animator = get_piece_effect_animator()
	freeze_effect_animator.configure({
		"tween_owner": match_board,
		"geometry": get_board_geometry(),
		"visuals": get_board_visuals(),
		"board_markers_node": match_board.board_markers_node,
		"freeze_shader": match_board.PIECE_FREEZE_CRACK_SHADER,
		"square_texture_provider": Callable(effect_animator, "get_attach_rays_square_texture"),
		"sync_overlay_to_holder_callback": Callable(effect_animator, "sync_sprite_overlay_to_holder"),
		"piece_holder_provider": Callable(match_board, "get_piece_holder_at"),
		"should_skip_visual_animations_provider": Callable(match_board, "should_skip_visual_animations"),
		"pending_affix_positions_provider": Callable(match_board, "get_pending_stamp_affix_positions"),
		"piece_objects_provider": Callable(match_board, "get_piece_objects"),
		"board_effects_provider": Callable(match_board, "get_current_board_effects"),
		"player_id_for_color_callback": Callable(match_board, "get_player_id_for_color"),
		"is_valid_position_callback": Callable(match_board, "is_valid_position"),
		"crack_name": match_board.PIECE_FREEZE_CRACK_NAME,
		"release_name": match_board.PIECE_FREEZE_RELEASE_NAME,
		"square_name": match_board.PIECE_FREEZE_SQUARE_NAME,
		"square_release_name": match_board.PIECE_FREEZE_SQUARE_RELEASE_NAME,
		"crack_z_index": match_board.PIECE_FREEZE_CRACK_Z_INDEX,
		"square_z_index": match_board.PIECE_FREEZE_SQUARE_Z_INDEX,
		"crack_duration": match_board.PIECE_FREEZE_CRACK_DURATION,
		"crack_release_duration": match_board.PIECE_FREEZE_CRACK_RELEASE_DURATION,
		"crack_start_width": match_board.PIECE_FREEZE_CRACK_START_WIDTH,
		"crack_end_width": match_board.PIECE_FREEZE_CRACK_END_WIDTH,
		"crack_depth": match_board.PIECE_FREEZE_CRACK_DEPTH,
		"crack_scale": match_board.PIECE_FREEZE_CRACK_SCALE,
		"crack_zebra_scale": match_board.PIECE_FREEZE_CRACK_ZEBRA_SCALE,
		"crack_zebra_amp": match_board.PIECE_FREEZE_CRACK_ZEBRA_AMP,
		"crack_profile": match_board.PIECE_FREEZE_CRACK_PROFILE,
		"crack_slope": match_board.PIECE_FREEZE_CRACK_SLOPE,
		"refraction_offset": match_board.PIECE_FREEZE_REFRACTION_OFFSET,
		"reflection_offset": match_board.PIECE_FREEZE_REFLECTION_OFFSET,
		"square_inset": match_board.PIECE_FREEZE_SQUARE_INSET,
		"square_alpha": match_board.PIECE_FREEZE_SQUARE_ALPHA,
		"piece_effect_light_receive_mask": match_board.PIECE_EFFECT_LIGHT_RECEIVE_MASK,
	})

func get_freeze_effect_animator():
	initialize_freeze_effect_animator()
	return freeze_effect_animator

func initialize_board_effect_icon_grid_controller() -> void:
	if board_effect_icon_grid_controller == null:
		board_effect_icon_grid_controller = BOARD_EFFECT_ICON_GRID_CONTROLLER_SCRIPT.new()
	sync_board_effect_icon_grid_controller()

func sync_board_effect_icon_grid_controller() -> void:
	if board_effect_icon_grid_controller == null:
		return
	board_effect_icon_grid_controller.configure({
		"match_board": match_board,
		"canvas_layer": match_board.canvas_layer,
	})

func get_board_effect_icon_grid_controller():
	initialize_board_effect_icon_grid_controller()
	return board_effect_icon_grid_controller

func initialize_stamp_hud_controller() -> void:
	if stamp_hud_controller == null:
		stamp_hud_controller = MATCH_STAMP_HUD_SCRIPT.new()
	sync_stamp_hud_controller()

func sync_stamp_hud_controller() -> void:
	if stamp_hud_controller == null:
		return
	stamp_hud_controller.configure({
		"stamp_visual_scene": STAMP_VISUAL,
		"stamp_ui_size": match_board.STAMP_UI_SIZE,
		"player_hand_size": match_board.PLAYER_HAND_SIZE,
		"stamp_hand_scale": match_board.STAMP_HAND_SCALE,
		"deck_stamp_scale": match_board.DECK_STAMP_SCALE,
		"deck_extra_left_offset": match_board.DECK_EXTRA_LEFT_OFFSET,
		"stamp_ui_gap": match_board.STAMP_UI_GAP,
		"top_stamp_hand_margin": match_board.TOP_STAMP_HAND_MARGIN,
		"bottom_stamp_hand_margin": match_board.BOTTOM_STAMP_HAND_MARGIN,
	})

func get_stamp_hud_controller():
	initialize_stamp_hud_controller()
	return stamp_hud_controller

func initialize_match_codex_controller() -> void:
	if match_codex_controller == null:
		match_codex_controller = MATCH_CODEX_CONTROLLER_SCRIPT.new()
	sync_match_codex_controller()

func sync_match_codex_controller() -> void:
	if match_codex_controller == null:
		return
	match_codex_controller.configure({
		"match_board": match_board,
	})

func get_match_codex_controller():
	initialize_match_codex_controller()
	return match_codex_controller

func initialize_stamp_hover_preview_controller() -> void:
	if stamp_hover_preview_controller == null:
		stamp_hover_preview_controller = STAMP_HOVER_PREVIEW_CONTROLLER_SCRIPT.new()
	sync_stamp_hover_preview_controller()

func sync_stamp_hover_preview_controller() -> void:
	if stamp_hover_preview_controller == null:
		return
	stamp_hover_preview_controller.configure({
		"canvas_layer": match_board.canvas_layer,
		"stamp_visual_scene": STAMP_VISUAL,
		"stamp_ui_size": match_board.STAMP_UI_SIZE,
		"hover_stamp_margin": match_board.HOVER_STAMP_MARGIN,
		"hover_stamp_extra_left_offset": match_board.HOVER_STAMP_EXTRA_LEFT_OFFSET,
		"hover_stamp_preview_scale": match_board.HOVER_STAMP_PREVIEW_SCALE,
		"hover_stamp_vertical_offset": match_board.HOVER_STAMP_VERTICAL_OFFSET,
		"hover_stamp_rotation_degrees": match_board.HOVER_STAMP_ROTATION_DEGREES,
		"hover_piece_preview_size": match_board.HOVER_PIECE_PREVIEW_SIZE,
		"hover_piece_preview_vertical_offset": match_board.HOVER_PIECE_PREVIEW_VERTICAL_OFFSET,
		"description_text_margin": match_board.HOVER_DESCRIPTION_TEXT_MARGIN,
		"description_panel_gap": match_board.HOVER_DESCRIPTION_PANEL_GAP,
		"description_panel_width": match_board.HOVER_DESCRIPTION_PANEL_WIDTH,
		"description_panel_height": match_board.HOVER_DESCRIPTION_PANEL_HEIGHT,
		"duration_shadow_color": match_board.HOVER_DURATION_SHADOW_COLOR,
		"duration_shadow_blur": match_board.HOVER_DURATION_SHADOW_BLUR,
		"duration_outline_size": match_board.HOVER_DURATION_OUTLINE_SIZE,
		"is_reveal_blocked_provider": Callable(match_board, "is_stamp_affix_reveal_active"),
	})

func get_stamp_hover_preview_controller():
	initialize_stamp_hover_preview_controller()
	return stamp_hover_preview_controller

func initialize_piece_duration_change_animator() -> void:
	if piece_duration_change_animator == null:
		piece_duration_change_animator = PIECE_DURATION_CHANGE_ANIMATOR_SCRIPT.new()
	sync_piece_duration_change_animator()

func sync_piece_duration_change_animator() -> void:
	if piece_duration_change_animator == null:
		return
	piece_duration_change_animator.configure({
		"match_board": match_board,
		"canvas_layer": match_board.canvas_layer,
		"shadow_color": match_board.HOVER_DURATION_SHADOW_COLOR,
		"shadow_blur": match_board.HOVER_DURATION_SHADOW_BLUR,
		"outline_size": match_board.HOVER_DURATION_OUTLINE_SIZE,
	})

func get_piece_duration_change_animator():
	initialize_piece_duration_change_animator()
	return piece_duration_change_animator

func initialize_stamp_interaction_controller() -> void:
	if stamp_interaction_controller == null:
		stamp_interaction_controller = STAMP_INTERACTION_CONTROLLER_SCRIPT.new()
	sync_stamp_interaction_controller()

func sync_stamp_interaction_controller() -> void:
	if stamp_interaction_controller == null:
		return
	stamp_interaction_controller.configure({
		"tween_owner": match_board,
		"geometry": get_board_geometry(),
		"visuals": get_board_visuals(),
		"board_markers_node": match_board.board_markers_node,
		"stamp_affix_target_fill_color": match_board.STAMP_AFFIX_TARGET_FILL_COLOR,
		"stamp_affix_target_fill_inset": match_board.STAMP_AFFIX_TARGET_FILL_INSET,
		"stamp_affix_target_wiggle_rise": match_board.STAMP_AFFIX_TARGET_WIGGLE_RISE,
		"stamp_affix_target_wiggle_rotation_degrees": match_board.STAMP_AFFIX_TARGET_WIGGLE_ROTATION_DEGREES,
		"stamp_affix_target_wiggle_step_duration": match_board.STAMP_AFFIX_TARGET_WIGGLE_STEP_DURATION,
		"hide_hover_callback": Callable(match_board, "hide_hover_piece_details"),
		"show_hover_stamp_description_callback": Callable(match_board, "show_hover_stamp_description"),
		"can_control_current_turn_provider": Callable(match_board, "can_control_current_turn"),
		"controllable_color_provider": Callable(match_board, "get_controllable_color"),
		"is_mouse_out_provider": Callable(match_board, "is_mouse_out"),
		"mouse_board_position_provider": Callable(match_board, "get_mouse_board_position"),
		"is_valid_position_callback": Callable(match_board, "is_valid_position"),
		"is_piece_owned_by_callback": Callable(match_board, "is_piece_owned_by"),
		"can_affix_stamp_to_piece_callback": Callable(match_board, "can_affix_stamp_to_piece"),
		"can_exchange_stamp_locally_callback": Callable(match_board, "can_exchange_stamp_locally"),
		"is_mouse_over_deck_callback": Callable(match_board, "is_mouse_over_deck"),
		"affix_stamp_visual_to_piece_callback": Callable(match_board, "affix_stamp_visual_to_piece"),
		"stamp_visuals_provider": Callable(match_board, "get_stamp_visuals"),
		"stamp_hand_provider": Callable(match_board, "get_stamp_hand"),
		"stamp_home_position_provider": Callable(match_board, "get_stamp_home_position"),
		"piece_holder_provider": Callable(match_board, "get_piece_holder_at"),
		"stamp_visual_index_provider": Callable(match_board, "get_stamp_visual_index"),
		"tutorial_exchange_allowed_callback": Callable(match_board, "is_tutorial_exchange_stamp_allowed"),
		"send_stamp_exchange_callback": Callable(match_board, "send_stamp_exchange_action"),
		"stamp_deck_provider": Callable(match_board, "get_stamp_deck"),
		"remove_stamp_from_hand_index_callback": Callable(match_board, "remove_stamp_from_hand_index"),
		"complete_stamp_exchange_callback": Callable(match_board, "complete_stamp_exchange"),
	})

func get_stamp_interaction_controller():
	initialize_stamp_interaction_controller()
	return stamp_interaction_controller

func initialize_stamp_animation_controller() -> void:
	if stamp_animation_controller == null:
		stamp_animation_controller = STAMP_ANIMATION_CONTROLLER_SCRIPT.new()
	sync_stamp_animation_controller()

func sync_stamp_animation_controller() -> void:
	if stamp_animation_controller == null:
		return
	stamp_animation_controller.configure({
		"canvas_layer": match_board.canvas_layer,
		"tween_owner": match_board,
		"stamp_visual_scene": STAMP_VISUAL,
		"stamp_ui_size": match_board.STAMP_UI_SIZE,
		"stamp_burn_sequence_gap": match_board.STAMP_BURN_SEQUENCE_GAP,
		"return_to_deck_start_scale": match_board.STAMP_RETURN_TO_DECK_START_SCALE,
		"return_to_deck_end_scale": match_board.STAMP_RETURN_TO_DECK_END_SCALE,
		"return_to_deck_duration": match_board.STAMP_RETURN_TO_DECK_DURATION,
		"stamp_side_reveal_scale": match_board.HOVER_STAMP_PREVIEW_SCALE,
		"color_for_player_provider": Callable(match_board, "get_color_for_player_id"),
		"player_id_for_color_provider": Callable(match_board, "get_player_id_for_color"),
		"local_view_color_provider": Callable(match_board, "get_local_view_color"),
		"is_valid_position_callback": Callable(match_board, "is_valid_position"),
		"board_screen_position_provider": Callable(match_board, "get_board_position_screen_position"),
		"stamp_draw_start_position_provider": Callable(match_board, "get_stamp_draw_start_position"),
		"stamp_return_to_deck_target_position_provider": Callable(match_board, "get_stamp_return_to_deck_target_position"),
		"stamp_hand_source_position_provider": Callable(match_board, "get_stamp_hand_source_position"),
		"deck_visual_provider": Callable(match_board, "get_deck_visual"),
		"viewport_size_provider": Callable(match_board, "get_visible_viewport_size"),
		"board_screen_size_provider": Callable(match_board, "get_board_screen_size"),
		"value_to_vector2_provider": Callable(match_board, "value_to_vector2"),
		"stamp_visuals_provider": Callable(match_board, "get_stamp_visuals"),
	})

func get_stamp_animation_controller():
	initialize_stamp_animation_controller()
	return stamp_animation_controller

func initialize_deck_counter_controller() -> void:
	if deck_counter_controller == null:
		deck_counter_controller = DECK_COUNTER_CONTROLLER_SCRIPT.new()
	sync_deck_counter_controller()

func sync_deck_counter_controller() -> void:
	if deck_counter_controller == null:
		return
	deck_counter_controller.configure({
		"canvas_layer": match_board.canvas_layer,
		"tween_owner": match_board,
		"deck_count_label_size": match_board.DECK_COUNT_LABEL_SIZE,
		"deck_count_label_gap": match_board.DECK_COUNT_LABEL_GAP,
		"deck_counter_background_size": match_board.DECK_COUNTER_BACKGROUND_SIZE,
		"deck_counter_digit_size": match_board.DECK_COUNTER_DIGIT_SIZE,
		"deck_counter_digit_gap": match_board.DECK_COUNTER_DIGIT_GAP,
		"deck_counter_frame_size": match_board.DECK_COUNTER_FRAME_SIZE,
		"deck_counter_content_offset": match_board.DECK_COUNTER_CONTENT_OFFSET,
		"deck_counter_size": match_board.DECK_COUNTER_SIZE,
		"deck_counter_roll_duration": match_board.DECK_COUNTER_ROLL_DURATION,
		"deck_counter_motion_blur": match_board.DECK_COUNTER_MOTION_BLUR,
		"deck_counter_offset": match_board.DECK_COUNTER_OFFSET,
		"deck_counter_z_index": match_board.DECK_COUNTER_Z_INDEX,
		"deck_counter_digits_texture": match_board.DECK_COUNTER_DIGITS_TEXTURE,
		"deck_counter_background_texture": match_board.DECK_COUNTER_BACKGROUND_TEXTURE,
		"deck_counter_frame_texture": match_board.DECK_COUNTER_FRAME_TEXTURE,
		"deck_counter_shadow_texture": match_board.DECK_COUNTER_SHADOW_TEXTURE,
		"deck_counter_digit_shader": match_board.DECK_COUNTER_DIGIT_SHADER,
		"deck_visual_provider": Callable(match_board, "get_deck_visual"),
		"stamp_deck_count_provider": Callable(match_board, "get_stamp_deck_count"),
		"game_over_provider": Callable(match_board, "is_game_over"),
	})

func get_deck_counter_controller():
	initialize_deck_counter_controller()
	return deck_counter_controller

func initialize_turn_hud_controller() -> void:
	if turn_hud_controller == null:
		turn_hud_controller = TURN_HUD_CONTROLLER_SCRIPT.new()
	sync_turn_hud_controller()

func sync_turn_hud_controller() -> void:
	if turn_hud_controller == null:
		return
	turn_hud_controller.configure({
		"canvas_layer": match_board.canvas_layer,
		"tween_owner": match_board,
		"turn_timer_limit_seconds": match_board.TURN_TIMER_LIMIT_SECONDS,
		"turn_timer_counter_key": match_board.TURN_TIMER_COUNTER_KEY,
		"turn_timer_gap": match_board.TURN_TIMER_GAP,
		"turn_timer_z_index": match_board.TURN_TIMER_Z_INDEX,
		"deck_counter_size": match_board.DECK_COUNTER_SIZE,
		"action_status_size": match_board.ACTION_STATUS_SIZE,
		"action_status_margin": match_board.ACTION_STATUS_MARGIN,
		"action_status_cell_size": match_board.ACTION_STATUS_CELL_SIZE,
		"action_status_cell_gap": match_board.ACTION_STATUS_CELL_GAP,
		"action_status_flip_duration": match_board.ACTION_STATUS_FLIP_DURATION,
		"action_status_active_color": match_board.ACTION_STATUS_ACTIVE_COLOR,
		"action_status_active_text_color": match_board.ACTION_STATUS_ACTIVE_TEXT_COLOR,
		"action_status_active_border_color": match_board.ACTION_STATUS_ACTIVE_BORDER_COLOR,
		"action_status_inactive_color": match_board.ACTION_STATUS_INACTIVE_COLOR,
		"action_status_blocked_color": match_board.ACTION_STATUS_BLOCKED_COLOR,
		"action_status_state_active": match_board.ACTION_STATUS_STATE_ACTIVE,
		"action_status_state_empty": match_board.ACTION_STATUS_STATE_EMPTY,
		"action_status_state_blocked": match_board.ACTION_STATUS_STATE_BLOCKED,
		"end_turn_indicator_padding": match_board.END_TURN_INDICATOR_PADDING,
		"end_turn_indicator_color": match_board.END_TURN_INDICATOR_COLOR,
		"end_turn_indicator_z_index": match_board.END_TURN_INDICATOR_Z_INDEX,
		"player_name_label_size": match_board.PLAYER_NAME_LABEL_SIZE,
		"player_name_label_gap": match_board.PLAYER_NAME_LABEL_GAP,
		"player_portrait_size": match_board.get_scaled_player_portrait_size(),
		"player_portrait_margin": match_board.PLAYER_PORTRAIT_MARGIN,
		"player_portrait_top_position": match_board.get_player_portrait_top_position(),
		"player_portrait_z_index": match_board.PLAYER_PORTRAIT_Z_INDEX,
		"rules_info_button_size": match_board.RULES_INFO_BUTTON_SIZE,
		"rules_info_panel_size": match_board.RULES_INFO_PANEL_SIZE,
		"rules_info_panel_margin": match_board.RULES_INFO_PANEL_MARGIN,
		"rules_info_text": match_board.RULES_INFO_TEXT,
		"current_player_names": match_board.current_player_names,
		"current_player_portraits": match_board.current_player_portraits,
		"create_digit_counter_callback": Callable(get_deck_counter_controller(), "create_digit_counter_container"),
		"set_digit_counter_value_callback": Callable(get_deck_counter_controller(), "set_deck_counter_value"),
		"end_turn_pressed_callback": Callable(match_board, "_on_end_turn_pressed"),
		"game_over_provider": Callable(match_board, "is_game_over"),
		"can_control_current_turn_provider": Callable(match_board, "can_control_current_turn"),
		"tutorial_end_turn_allowed_provider": Callable(match_board, "is_end_turn_tutorial_allowed"),
		"show_first_turn_end_provider": Callable(match_board, "should_show_first_turn_end_button"),
		"can_end_first_turn_provider": Callable(match_board, "can_end_first_turn"),
		"can_switch_action_provider": Callable(match_board, "can_switch_action_now"),
		"can_affix_action_provider": Callable(match_board, "can_affix_action_now"),
		"can_move_action_provider": Callable(match_board, "can_move_action_now"),
		"current_turn_color_provider": Callable(match_board, "get_current_turn_color"),
		"player_id_for_color_provider": Callable(match_board, "get_player_id_for_color"),
		"turn_timer_timeout_callback": Callable(match_board, "defer_turn_timer_timeout"),
		"deck_visual_provider": Callable(match_board, "get_deck_visual"),
		"local_view_color_provider": Callable(match_board, "get_local_view_color"),
		"own_color_provider": Callable(match_board, "get_own_color"),
		"visible_viewport_size_provider": Callable(match_board, "get_visible_viewport_size"),
		"board_screen_size_provider": Callable(match_board, "get_board_screen_size"),
		"game_result_context_provider": Callable(match_board, "get_game_result_context"),
	})

func get_turn_hud_controller():
	initialize_turn_hud_controller()
	return turn_hud_controller

func initialize_match_input_controller() -> void:
	if match_input_controller == null:
		match_input_controller = MATCH_INPUT_CONTROLLER_SCRIPT.new()
	sync_match_input_controller()

func sync_match_input_controller() -> void:
	if match_input_controller == null:
		return
	match_input_controller.configure({
		"match_board": match_board,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
		"main_menu_scene": match_board.MAIN_MENU_SCENE,
	})

func get_match_input_controller():
	initialize_match_input_controller()
	return match_input_controller

func initialize_stamp_hand_state_controller() -> void:
	if stamp_hand_state_controller == null:
		stamp_hand_state_controller = STAMP_HAND_STATE_CONTROLLER_SCRIPT.new()
	sync_stamp_hand_state_controller()

func sync_stamp_hand_state_controller() -> void:
	if stamp_hand_state_controller == null:
		return
	stamp_hand_state_controller.configure({
		"match_board": match_board,
		"stamp_visual_scene": STAMP_VISUAL,
		"stamp_ui_size": match_board.STAMP_UI_SIZE,
		"stamp_hand_scale": match_board.STAMP_HAND_SCALE,
	})

func get_stamp_hand_state_controller():
	initialize_stamp_hand_state_controller()
	return stamp_hand_state_controller
