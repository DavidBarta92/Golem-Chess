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
const CROWN_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/CrownController.gd")
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
var crown_controller
var stamp_hover_preview_controller
var piece_duration_change_animator
var stamp_interaction_controller
var stamp_animation_controller
var deck_counter_controller
var turn_hud_controller
var match_input_controller
var stamp_hand_state_controller
var _settled: bool = false
var _configured: Dictionary = {}

func configure(config: Dictionary) -> void:
	match_board = config.get("match_board", match_board)

## The controller itself, made if it is not yet, for a Callable into it in
## another controller's config. Its own config comes when it is initialized:
## going through its getter here would sync it, and the two configs would ask
## for each other.
func _created(var_name: String, script: Script) -> Object:
	if get(var_name) == null:
		set(var_name, script.new())
	return get(var_name)

## Until the board's _ready is over (settle()), a controller is configured again
## every time it is asked for: the board makes some of the nodes the configs
## point at halfway through it. After that each controller is configured once,
## the first time it is asked for, and only what changes during a match is
## refreshed - the view, by apply_view() from MatchBoard.side's setter; the turn
## HUD's names, portraits and portrait spot, by its getter. A value a
## controller's config copies that can change mid-match needs one of these.
func _needs_sync(var_name: String) -> bool:
	if !_settled:
		return true
	if _configured.has(var_name):
		return false
	_configured[var_name] = true
	return true

## The board's _ready is over: from here on, configure each controller once.
func settle() -> void:
	_settled = true
	_configured.clear()

## The board has made one of its nodes again: configure everything afresh on
## its next ask, so no controller keeps the old node.
func reconfigure_all() -> void:
	_configured.clear()

## Pushes the side the board is seen from to the controllers that draw by it.
func apply_view() -> void:
	var view_color: int = match_board.get_board_view_color()
	if board_geometry != null:
		board_geometry.set_view_color(view_color)
	for controller in [piece_visuals, piece_move_animator, piece_shatter_animator]:
		if controller != null:
			controller.configure({"view_color": view_color})
	for controller in [piece_shatter_animator, piece_effect_animator]:
		if controller != null:
			controller.configure({"flipped_view": view_color < 0})

func initialize_startup_controllers() -> void:
	initialize_board_view_helpers()
	initialize_board_environment_controller()
	initialize_visual_process_tracker()
	initialize_board_tile_controller()
	initialize_match_state_sync_controller()
	initialize_server_state_update_controller()
	initialize_server_state_visual_update_controller()
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
	initialize_crown_controller()
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
	if _needs_sync("match_board_lifecycle_controller"):
		sync_match_board_lifecycle_controller()

func sync_match_board_lifecycle_controller() -> void:
	if match_board_lifecycle_controller == null:
		return
	match_board_lifecycle_controller.configure({
		"match_board": match_board,
	})

func get_match_board_lifecycle_controller():
	initialize_match_board_lifecycle_controller()
	return match_board_lifecycle_controller

func initialize_board_view_helpers() -> void:
	if board_geometry == null:
		board_geometry = BOARD_GEOMETRY_SCRIPT.new()
	if board_visuals == null:
		board_visuals = BOARD_VISUAL_CONTROLLER_SCRIPT.new()
	if _needs_sync("board_geometry"):
		sync_board_geometry()
		board_visuals.configure(board_geometry)

func sync_board_geometry() -> void:
	if board_geometry == null:
		return
	board_geometry.configure({
		"board_size": match_board.BOARD_SIZE,
		"cell_width": match_board.CELL_WIDTH,
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
	if _needs_sync("board_environment_controller"):
		sync_board_environment_controller()

func sync_board_environment_controller() -> void:
	if board_environment_controller == null:
		return
	board_environment_controller.configure({
		"match_board": match_board,
		"board_frame_width": match_board.BOARD_FRAME_WIDTH,
		"board_frame_vertical_extension": match_board.BOARD_FRAME_VERTICAL_EXTENSION,
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
	if _needs_sync("board_tile_controller"):
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
		"frame_width": match_board.BOARD_FRAME_WIDTH,
		"frame_vertical_extension": match_board.BOARD_FRAME_VERTICAL_EXTENSION,
		"frame_color": match_board.BOARD_FRAME_COLOR,
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
	if _needs_sync("board_marker_controller"):
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
		"cell_width": match_board.CELL_WIDTH,
		"board_size": match_board.BOARD_SIZE,
		"piece_objects_provider": Callable(match_board, "get_piece_objects"),
		"board_effects_provider": Callable(match_board, "get_current_board_effects"),
		"current_last_move_provider": Callable(match_board, "get_current_last_move"),
		"local_view_color_provider": Callable(match_board, "get_local_view_color"),
		"local_view_ready_provider": Callable(match_board, "is_local_view_ready"),
		"own_player_id_provider": Callable(match_board, "get_own_player_id"),
		"can_move_action_now_provider": Callable(_created("turn_flow_controller", TURN_FLOW_CONTROLLER_SCRIPT), "can_move_action_now"),
		"can_player_control_piece_at_provider": Callable(match_board, "can_player_control_piece_at"),
		"update_special_tiles_callback": Callable(get_board_tile_controller(), "update_board_special_tiles"),
	})

func get_board_marker_controller():
	initialize_board_marker_controller()
	return board_marker_controller

func initialize_match_state_sync_controller() -> void:
	if match_state_sync_controller == null:
		match_state_sync_controller = MATCH_STATE_SYNC_CONTROLLER_SCRIPT.new()
	if _needs_sync("match_state_sync_controller"):
		sync_match_state_sync_controller()

func sync_match_state_sync_controller() -> void:
	if match_state_sync_controller == null:
		return
	match_state_sync_controller.configure({
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
	if _needs_sync("server_state_update_controller"):
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
	if _needs_sync("server_state_visual_update_controller"):
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

func initialize_local_stamp_action_controller() -> void:
	if local_stamp_action_controller == null:
		local_stamp_action_controller = LOCAL_STAMP_ACTION_CONTROLLER_SCRIPT.new()
	if _needs_sync("local_stamp_action_controller"):
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
	if _needs_sync("local_gameplay_controller"):
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
	if _needs_sync("tutorial_match_adapter"):
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
	if _needs_sync("game_result_controller"):
		sync_game_result_controller()

func sync_game_result_controller() -> void:
	if game_result_controller == null:
		return
	game_result_controller.configure({
		"match_board": match_board,
		"main_menu_scene": match_board.MAIN_MENU_SCENE,
	})

func get_game_result_controller():
	initialize_game_result_controller()
	return game_result_controller

func initialize_turn_flow_controller() -> void:
	if turn_flow_controller == null:
		turn_flow_controller = TURN_FLOW_CONTROLLER_SCRIPT.new()
	if _needs_sync("turn_flow_controller"):
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
	if _needs_sync("turn_action_state_controller"):
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
	if _needs_sync("piece_texture_resolver"):
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
	if _needs_sync("piece_visual_controller"):
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
		"piece_shadow_light_energy": match_board.PIECE_SHADOW_LIGHT_ENERGY,
		"piece_ground_shadow_color": match_board.piece_move_shadow_color,
		"piece_ground_shadow_radius_scale": match_board.piece_move_shadow_radius_scale,
		"piece_ground_shadow_edge_softness": match_board.piece_move_shadow_ground_edge_softness,
		"board_light_receive_mask": match_board.BOARD_LIGHT_RECEIVE_MASK,
		"piece_light_occluder_mask": match_board.PIECE_LIGHT_OCCLUDER_MASK,
		"piece_light_receive_mask": match_board.PIECE_LIGHT_RECEIVE_MASK,
		"piece_effect_light_receive_mask": match_board.PIECE_EFFECT_LIGHT_RECEIVE_MASK,
		"piece_light_occluder_footprint_fixed_radius_y": match_board.PIECE_LIGHT_OCCLUDER_FOOTPRINT_FIXED_RADIUS_Y,
		"attach_effect_names": [PIECE_EFFECT_ANIMATOR_SCRIPT.PIECE_ATTACH_GLOW_NAME, PIECE_EFFECT_ANIMATOR_SCRIPT.PIECE_ATTACH_TARGET_GLOW_NAME, PIECE_EFFECT_ANIMATOR_SCRIPT.PIECE_ATTACH_RAYS_NAME, PIECE_EFFECT_ANIMATOR_SCRIPT.PIECE_ATTACH_MORPH_NAME],
	})

func get_piece_visuals():
	initialize_piece_visual_controller()
	return piece_visuals

func initialize_piece_effect_geometry_controller() -> void:
	if piece_effect_geometry_controller == null:
		piece_effect_geometry_controller = PIECE_EFFECT_GEOMETRY_CONTROLLER_SCRIPT.new()
	if _needs_sync("piece_effect_geometry_controller"):
		sync_piece_effect_geometry_controller()

func sync_piece_effect_geometry_controller() -> void:
	if piece_effect_geometry_controller == null:
		return
	piece_effect_geometry_controller.configure({
		"match_board": match_board,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
	})

func get_piece_effect_geometry_controller():
	initialize_piece_effect_geometry_controller()
	return piece_effect_geometry_controller

func initialize_piece_move_animator() -> void:
	if piece_move_animator == null:
		piece_move_animator = PIECE_MOVE_ANIMATOR_SCRIPT.new()
	if _needs_sync("piece_move_animator"):
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
	if _needs_sync("piece_shatter_animator"):
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
		"min_chip_size": match_board.piece_shatter_min_chip_size,
		"max_chip_size": match_board.piece_shatter_max_chip_size,
		"debris_linger_duration": match_board.piece_shatter_debris_linger_duration,
		"avoid_occupied_cells": match_board.piece_shatter_avoid_occupied_cells,
		"route_jitter_ratio": match_board.piece_shatter_route_jitter_ratio,
		"route_z_front_offset": match_board.PIECE_SHATTER_ROUTE_Z_FRONT_OFFSET,
		"route_z_back_offset": match_board.PIECE_SHATTER_ROUTE_Z_BACK_OFFSET,
		"fragment_group_bottom": match_board.PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM,
		"route_cell_blocked_provider": Callable(respawn_fragment_coordinator, "is_piece_shatter_route_cell_blocked"),
		"finish_respawn_fragment_callback": Callable(respawn_fragment_coordinator, "finish_piece_shatter_respawn_fragment"),
		"antialias_provider": Callable(get_board_visuals(), "enable_canvas_item_antialiasing"),
	})

func get_piece_shatter_animator():
	initialize_piece_shatter_animator()
	return piece_shatter_animator

func initialize_piece_respawn_fragment_coordinator() -> void:
	if piece_respawn_fragment_coordinator == null:
		piece_respawn_fragment_coordinator = PIECE_RESPAWN_FRAGMENT_COORDINATOR_SCRIPT.new()
	if _needs_sync("piece_respawn_fragment_coordinator"):
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
	if _needs_sync("piece_display_controller"):
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
		"piece_shadow_light_energy": match_board.PIECE_SHADOW_LIGHT_ENERGY,
		"invalid_board_pos": match_board.INVALID_BOARD_POS,
	})

func get_piece_display_controller():
	initialize_piece_display_controller()
	return piece_display_controller

func initialize_piece_effect_animator() -> void:
	if piece_effect_animator == null:
		piece_effect_animator = PIECE_EFFECT_ANIMATOR_SCRIPT.new()
	if _needs_sync("piece_effect_animator"):
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
		"texture_filter": match_board.PIECE_TEXTURE_FILTER,
		"board_light_receive_mask": match_board.BOARD_LIGHT_RECEIVE_MASK,
		"piece_light_receive_mask": match_board.PIECE_LIGHT_RECEIVE_MASK,
		"piece_effect_light_receive_mask": match_board.PIECE_EFFECT_LIGHT_RECEIVE_MASK,
		"piece_light_occluder_mask": match_board.PIECE_LIGHT_OCCLUDER_MASK,
		"flipped_view": match_board.side != null && !match_board.side,
		"default_piece_visual_height": match_board.DEFAULT_PIECE_VISUAL_HEIGHT,
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
		"bomb_warning_color": match_board.bomb_warning_color,
		"bomb_warning_duration": match_board.bomb_warning_duration,
		"bomb_warning_rise_distance": match_board.bomb_warning_rise_distance,
		"bomb_warning_size_ratio": match_board.bomb_warning_size_ratio,
		"bomb_warning_target_y_offset": match_board.bomb_warning_target_y_offset,
		"occluded_piece_effect_dim_color": match_board.occluded_piece_effect_dim_color,
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
	if _needs_sync("piece_effect_flow_controller"):
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
	if _needs_sync("freeze_effect_animator"):
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
		"square_texture_provider": Callable(effect_animator, "get_attach_rays_square_texture"),
		"sync_overlay_to_holder_callback": Callable(effect_animator, "sync_sprite_overlay_to_holder"),
		"footprint_metrics_provider": Callable(get_piece_visuals(), "get_footprint_metrics"),
		"piece_holder_provider": Callable(match_board, "get_piece_holder_at"),
		"should_skip_visual_animations_provider": Callable(match_board, "should_skip_visual_animations"),
		"pending_affix_positions_provider": Callable(match_board, "get_pending_stamp_affix_positions"),
		"piece_objects_provider": Callable(match_board, "get_piece_objects"),
		"board_effects_provider": Callable(match_board, "get_current_board_effects"),
		"piece_effect_light_receive_mask": match_board.PIECE_EFFECT_LIGHT_RECEIVE_MASK,
	})

func get_freeze_effect_animator():
	initialize_freeze_effect_animator()
	return freeze_effect_animator

func initialize_board_effect_icon_grid_controller() -> void:
	if board_effect_icon_grid_controller == null:
		board_effect_icon_grid_controller = BOARD_EFFECT_ICON_GRID_CONTROLLER_SCRIPT.new()
	if _needs_sync("board_effect_icon_grid_controller"):
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
	if _needs_sync("stamp_hud_controller"):
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
		"stamp_ui_gap": match_board.STAMP_UI_GAP,
		"bottom_stamp_hand_margin": match_board.BOTTOM_STAMP_HAND_MARGIN,
	})

func get_stamp_hud_controller():
	initialize_stamp_hud_controller()
	return stamp_hud_controller

func initialize_match_codex_controller() -> void:
	if match_codex_controller == null:
		match_codex_controller = MATCH_CODEX_CONTROLLER_SCRIPT.new()
	if _needs_sync("match_codex_controller"):
		sync_match_codex_controller()

func sync_match_codex_controller() -> void:
	if match_codex_controller == null:
		return
	match_codex_controller.configure({
		"match_board": match_board,
	})

func initialize_crown_controller() -> void:
	if crown_controller == null:
		crown_controller = CROWN_CONTROLLER_SCRIPT.new()
	if _needs_sync("crown_controller"):
		crown_controller.configure({
			"match_board": match_board,
		})

func get_crown_controller():
	initialize_crown_controller()
	return crown_controller

func get_match_codex_controller():
	initialize_match_codex_controller()
	return match_codex_controller

func initialize_stamp_hover_preview_controller() -> void:
	if stamp_hover_preview_controller == null:
		stamp_hover_preview_controller = STAMP_HOVER_PREVIEW_CONTROLLER_SCRIPT.new()
	if _needs_sync("stamp_hover_preview_controller"):
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
		"is_reveal_blocked_provider": Callable(_created("stamp_animation_controller", STAMP_ANIMATION_CONTROLLER_SCRIPT), "is_stamp_affix_reveal_active"),
	})

func get_stamp_hover_preview_controller():
	initialize_stamp_hover_preview_controller()
	return stamp_hover_preview_controller

func initialize_piece_duration_change_animator() -> void:
	if piece_duration_change_animator == null:
		piece_duration_change_animator = PIECE_DURATION_CHANGE_ANIMATOR_SCRIPT.new()
	if _needs_sync("piece_duration_change_animator"):
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
	if _needs_sync("stamp_interaction_controller"):
		sync_stamp_interaction_controller()

func sync_stamp_interaction_controller() -> void:
	if stamp_interaction_controller == null:
		return
	stamp_interaction_controller.configure({
		"tween_owner": match_board,
		"geometry": get_board_geometry(),
		"visuals": get_board_visuals(),
		"board_markers_node": match_board.board_markers_node,
		"hide_hover_callback": Callable(match_board, "hide_hover_piece_details"),
		"show_hover_stamp_description_callback": Callable(match_board, "show_hover_stamp_description"),
		"can_control_current_turn_provider": Callable(match_board, "can_control_current_turn"),
		"controllable_color_provider": Callable(match_board, "get_controllable_color"),
		"is_mouse_out_provider": Callable(_created("match_input_controller", MATCH_INPUT_CONTROLLER_SCRIPT), "is_mouse_out"),
		"mouse_board_position_provider": Callable(match_board, "get_mouse_board_position"),
		"is_piece_owned_by_callback": Callable(match_board, "is_piece_owned_by"),
		"can_affix_stamp_to_piece_callback": Callable(_created("local_stamp_action_controller", LOCAL_STAMP_ACTION_CONTROLLER_SCRIPT), "can_affix_stamp_to_piece"),
		"can_exchange_stamp_locally_callback": Callable(_created("local_stamp_action_controller", LOCAL_STAMP_ACTION_CONTROLLER_SCRIPT), "can_exchange_stamp_locally"),
		"is_mouse_over_deck_callback": Callable(_created("deck_counter_controller", DECK_COUNTER_CONTROLLER_SCRIPT), "is_mouse_over_deck"),
		"affix_stamp_visual_to_piece_callback": Callable(_created("local_stamp_action_controller", LOCAL_STAMP_ACTION_CONTROLLER_SCRIPT), "affix_stamp_visual_to_piece"),
		"stamp_visuals_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_stamp_visuals"),
		"stamp_hand_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_stamp_hand"),
		"stamp_home_position_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_stamp_home_position"),
		"piece_holder_provider": Callable(match_board, "get_piece_holder_at"),
		"stamp_visual_index_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_stamp_visual_index"),
		"tutorial_exchange_allowed_callback": Callable(_created("local_stamp_action_controller", LOCAL_STAMP_ACTION_CONTROLLER_SCRIPT), "is_tutorial_exchange_stamp_allowed"),
		"send_stamp_exchange_callback": Callable(_created("local_stamp_action_controller", LOCAL_STAMP_ACTION_CONTROLLER_SCRIPT), "send_stamp_exchange_action"),
		"stamp_deck_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_stamp_deck"),
		"remove_stamp_from_hand_index_callback": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "remove_stamp_from_hand_index"),
		"complete_stamp_exchange_callback": Callable(_created("local_stamp_action_controller", LOCAL_STAMP_ACTION_CONTROLLER_SCRIPT), "complete_stamp_exchange"),
	})

func get_stamp_interaction_controller():
	initialize_stamp_interaction_controller()
	return stamp_interaction_controller

func initialize_stamp_animation_controller() -> void:
	if stamp_animation_controller == null:
		stamp_animation_controller = STAMP_ANIMATION_CONTROLLER_SCRIPT.new()
	if _needs_sync("stamp_animation_controller"):
		sync_stamp_animation_controller()

func sync_stamp_animation_controller() -> void:
	if stamp_animation_controller == null:
		return
	stamp_animation_controller.configure({
		"canvas_layer": match_board.canvas_layer,
		"tween_owner": match_board,
		"stamp_visual_scene": STAMP_VISUAL,
		"stamp_ui_size": match_board.STAMP_UI_SIZE,
		"return_to_deck_end_scale": match_board.STAMP_RETURN_TO_DECK_END_SCALE,
		"stamp_side_reveal_scale": match_board.HOVER_STAMP_PREVIEW_SCALE,
		"color_for_player_provider": Callable(match_board, "get_color_for_player_id"),
		"local_view_color_provider": Callable(match_board, "get_local_view_color"),
		"board_screen_position_provider": Callable(match_board, "get_board_position_screen_position"),
		"stamp_draw_start_position_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_stamp_draw_start_position"),
		"stamp_return_to_deck_target_position_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_stamp_return_to_deck_target_position"),
		"stamp_codex_return_target_position_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_stamp_codex_return_target_position"),
		"stamp_hand_source_position_provider": Callable(match_board, "get_stamp_hand_source_position"),
		"deck_visual_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_deck_visual"),
		"viewport_size_provider": Callable(match_board, "get_visible_viewport_size"),
		"board_screen_size_provider": Callable(match_board, "get_board_screen_size"),
		"stamp_visuals_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_stamp_visuals"),
	})

func get_stamp_animation_controller():
	initialize_stamp_animation_controller()
	return stamp_animation_controller

func initialize_deck_counter_controller() -> void:
	if deck_counter_controller == null:
		deck_counter_controller = DECK_COUNTER_CONTROLLER_SCRIPT.new()
	if _needs_sync("deck_counter_controller"):
		sync_deck_counter_controller()

func sync_deck_counter_controller() -> void:
	if deck_counter_controller == null:
		return
	deck_counter_controller.configure({
		"canvas_layer": match_board.canvas_layer,
		"tween_owner": match_board,
		"deck_counter_background_size": match_board.DECK_COUNTER_BACKGROUND_SIZE,
		"deck_counter_digit_size": match_board.DECK_COUNTER_DIGIT_SIZE,
		"deck_counter_digit_gap": match_board.DECK_COUNTER_DIGIT_GAP,
		"deck_counter_frame_size": match_board.DECK_COUNTER_FRAME_SIZE,
		"deck_counter_content_offset": match_board.DECK_COUNTER_CONTENT_OFFSET,
		"deck_counter_size": match_board.DECK_COUNTER_SIZE,
		"deck_visual_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_deck_visual"),
		"stamp_deck_count_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_stamp_deck_count"),
		"game_over_provider": Callable(match_board, "is_game_over"),
	})

func get_deck_counter_controller():
	initialize_deck_counter_controller()
	return deck_counter_controller

func initialize_turn_hud_controller() -> void:
	if turn_hud_controller == null:
		turn_hud_controller = TURN_HUD_CONTROLLER_SCRIPT.new()
	if _needs_sync("turn_hud_controller"):
		sync_turn_hud_controller()

func sync_turn_hud_controller() -> void:
	if turn_hud_controller == null:
		return
	turn_hud_controller.configure({
		"canvas_layer": match_board.canvas_layer,
		"tween_owner": match_board,
		"match_background_provider": Callable(match_board, "get_match_background"),
		"deck_counter_size": match_board.DECK_COUNTER_SIZE,
		"create_digit_counter_callback": Callable(get_deck_counter_controller(), "create_digit_counter_container"),
		"set_digit_counter_value_callback": Callable(get_deck_counter_controller(), "set_deck_counter_value"),
		"end_turn_pressed_callback": Callable(_created("turn_flow_controller", TURN_FLOW_CONTROLLER_SCRIPT), "on_end_turn_pressed"),
		"game_over_provider": Callable(match_board, "is_game_over"),
		"can_control_current_turn_provider": Callable(match_board, "can_control_current_turn"),
		"tutorial_end_turn_allowed_provider": Callable(match_board, "is_end_turn_tutorial_allowed"),
		"show_first_turn_end_provider": Callable(match_board, "should_show_first_turn_end_button"),
		"can_end_first_turn_provider": Callable(match_board, "can_end_first_turn"),
		"can_switch_action_provider": Callable(_created("turn_flow_controller", TURN_FLOW_CONTROLLER_SCRIPT), "can_switch_action_now"),
		"can_affix_action_provider": Callable(_created("turn_flow_controller", TURN_FLOW_CONTROLLER_SCRIPT), "can_affix_action_now"),
		"can_move_action_provider": Callable(_created("turn_flow_controller", TURN_FLOW_CONTROLLER_SCRIPT), "can_move_action_now"),
		"current_turn_color_provider": Callable(match_board, "get_current_turn_color"),
		"turn_timer_timeout_callback": Callable(match_board, "defer_turn_timer_timeout"),
		"turn_changed_callback": match_board.turn_changed.emit,
		"deck_visual_provider": Callable(_created("stamp_hand_state_controller", STAMP_HAND_STATE_CONTROLLER_SCRIPT), "get_deck_visual"),
		"local_view_color_provider": Callable(match_board, "get_local_view_color"),
		"own_color_provider": Callable(match_board, "get_own_color"),
		"visible_viewport_size_provider": Callable(match_board, "get_visible_viewport_size"),
		"board_screen_size_provider": Callable(match_board, "get_board_screen_size"),
		"game_result_context_provider": Callable(match_board, "get_game_result_context"),
	})
	turn_hud_controller.configure(_turn_hud_live_config())

func get_turn_hud_controller():
	initialize_turn_hud_controller()
	turn_hud_controller.configure(_turn_hud_live_config())
	return turn_hud_controller

## What the turn HUD shows that changes during a match: the players' names and
## portraits come with each state, and the portrait spot follows the window.
func _turn_hud_live_config() -> Dictionary:
	return {
		"player_portrait_size": match_board.get_scaled_player_portrait_size(),
		"player_portrait_top_position": match_board.get_player_portrait_top_position(),
		"current_player_names": match_board.current_player_names,
		"current_player_portraits": match_board.current_player_portraits,
	}

func initialize_match_input_controller() -> void:
	if match_input_controller == null:
		match_input_controller = MATCH_INPUT_CONTROLLER_SCRIPT.new()
	if _needs_sync("match_input_controller"):
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
	if _needs_sync("stamp_hand_state_controller"):
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
