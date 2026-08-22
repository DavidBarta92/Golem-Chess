extends Sprite2D

signal piece_selected(piece_pos: Vector2, player_id: int)
signal stamp_attached(piece_pos: Vector2, stamp_name: String, owner_color: int, hand_index: int)
signal piece_moved(from_pos: Vector2, to_pos: Vector2, owner_color: int)
signal stamp_exchanged(stamp_name: String, owner_color: int, hand_index: int)
signal codex_page_turned(owner_color: int, page_index: int)
signal turn_ended(ending_color: int, next_color: int)
signal tutorial_action_rejected(action_name: String, context: Dictionary)

const BOARD_SIZE: int = BoardConfig.BOARD_SIZE
const CELL_WIDTH: int = BoardConfig.CELL_WIDTH

const MATCH_BOARD_CONTROLLER_REGISTRY_SCRIPT = preload("res://Scripts/MatchView/MatchBoardControllerRegistry.gd")
const RESPONSIVE_REFERENCE_VIEWPORT_SIZE = Vector2(1280.0, 720.0)
const HOVER_DESCRIPTION_STAMP_BASE_TEXTURE = preload("res://Assets/stamp_base.svg")

const BOARD_TILE_TEXTURE = preload("res://Assets/board_tile.svg")
const BOARD_TILE_BASE_WHITE_TEXTURE = preload("res://Assets/board_tile_base_white.svg")
const BOARD_TILE_BASE_BLACK_TEXTURE = preload("res://Assets/board_tile_base_black.svg")
const BOARD_TILE_FREEZE_TEXTURE = preload("res://Assets/board_tile_freeze.svg")
const BOARD_TILE_DISABLED_TEXTURE = preload("res://Assets/board_tile_disabled.svg")

const DEFAULT_PIECE_TEXTURE = preload("res://Assets/golem_front.svg")
const OWN_DEFAULT_PIECE_TEXTURE = preload("res://Assets/golem_back.svg")
const GOLEM_FRAGMENT_TOP_LEFT_TEXTURE = preload("res://Assets/golem_fragment_top_left.svg")
const GOLEM_FRAGMENT_TOP_CENTER_TEXTURE = preload("res://Assets/golem_fragment_top_center.svg")
const GOLEM_FRAGMENT_TOP_RIGHT_TEXTURE = preload("res://Assets/golem_fragment_top_right.svg")
const GOLEM_FRAGMENT_BOTTOM_LEFT_TEXTURE = preload("res://Assets/golem_fragment_bottom_left.svg")
const GOLEM_FRAGMENT_BOTTOM_CENTER_TEXTURE = preload("res://Assets/golem_fragment_bottom_center.svg")
const GOLEM_FRAGMENT_BOTTOM_RIGHT_TEXTURE = preload("res://Assets/golem_fragment_bottom_right.svg")
const CAPTURE_FLASH_TEXTURE = preload("res://Assets/stamp_pattern_capture_only.svg")
const BOMB_WARNING_TEXTURE = preload("res://Assets/stamp_pattern_bomb.svg")

const DECK_COUNTER_DIGITS_TEXTURE = preload("res://Assets/deck_counter_digits.png")
const DECK_COUNTER_BACKGROUND_TEXTURE = preload("res://Assets/counter_backround.png")
const DECK_COUNTER_FRAME_TEXTURE = preload("res://Assets/counter_frame.png")
const DECK_COUNTER_SHADOW_TEXTURE = preload("res://Assets/counter_shadow.png")

const MOVE_OPTION_DOT_TEXTURE = preload("res://Assets/dot.svg")
const PIECE_FREEZE_CRACK_SHADER = preload("res://Shaders/piece_freeze_crack.gdshader")
const DECK_COUNTER_DIGIT_SHADER = preload("res://Shaders/deck_counter_digit.gdshader")
const PIECE_ATTACH_GLOW_SHADER = preload("res://Shaders/piece_attach_glow.gdshader")
const PIECE_ATTACH_RAYS_SHADER = preload("res://Shaders/piece_attach_rays.gdshader")
const PIECE_TEXTURE_MORPH_SHADER = preload("res://Shaders/piece_texture_morph.gdshader")
const PIECE_INVISIBILITY_REFRACT_SHADER = preload("res://Shaders/piece_invisibility_refract.gdshader")
const PIECE_EXPIRE_DISSOLVE_SHADER = preload("res://Shaders/piece_expire_dissolve.gdshader")
const MOVE_OPTION_DOT_SHADER = preload("res://Shaders/move_option_dot.gdshader")
const HIDDEN_STAMP_INVISIBILITY_SHADER = preload("res://Shaders/hidden_stamp_invisibility.gdshader")
const BOARD_KUWAHARA_SHADER = preload("res://Shaders/board_kuwahara.gdshader")
const PIECE_KUWAHARA_SHADER = preload("res://Shaders/piece_kuwahara.gdshader")
const MOVE_OPTION_DOT_CELL_WIDTH_RATIO: float = 0.58
const MOVE_OPTION_DOT_SHADER_SPEED: float = 0.24
const MOVE_OPTION_DOT_SHADER_GLOW_STRENGTH: float = 2.0
const MOVE_OPTION_DOT_SHADER_EDGE_SOFTNESS: float = 0.85
const MOVE_OPTION_DOT_SHADER_PULSE_MIN_SCALE: float = 0.88
const MOVE_OPTION_DOT_SHADER_PULSE_MAX_SCALE: float = 1.18
const MOVE_OPTION_DOT_SHADER_COLOR = Color(1.0, 0.94, 0.78, 1.0)
const HIDDEN_STAMP_INVISIBILITY_RADIUS: float = 0.32
const HIDDEN_STAMP_INVISIBILITY_EFFECT_CONTROL: float = 0.76
const HIDDEN_STAMP_INVISIBILITY_BURN_SPEED: float = 0.0
const HIDDEN_STAMP_INVISIBILITY_SHAPE: float = 0.2
const BOARD_VISUAL_SCALE: float = 1.08
# Adjust these values to tune the board-only perspective tilt.
const BOARD_PERSPECTIVE_ENABLED: bool = true
const BOARD_PERSPECTIVE_TOP_SCALE: float = 0.74
const BOARD_PERSPECTIVE_BOTTOM_SCALE: float = 1.05
const BOARD_PERSPECTIVE_VERTICAL_SCALE: float = 0.72
const BOARD_SPECIAL_TILE_NONE: String = ""
const BOARD_SPECIAL_TILE_BASE_WHITE: String = "base_white"
const BOARD_SPECIAL_TILE_BASE_BLACK: String = "base_black"
const BOARD_SPECIAL_TILE_FREEZE: String = "freeze"
const BOARD_SPECIAL_TILE_DISABLED: String = "disabled"
const VISUAL_PROCESS_STAMP_ATTACH: String = "stamp_attach"
const VISUAL_PROCESS_STATE_STAMP_ATTACH: String = "state_stamp_attach"
const VISUAL_PROCESS_PIECE_REVERT: String = "piece_revert"
const VISUAL_PROCESS_PIECE_MOVE: String = "piece_move"
const VISUAL_PROCESS_PIECE_SHATTER: String = "piece_shatter"
const VISUAL_PROCESS_BOMB_WARNING: String = "bomb_warning"
const BOARD_SPECIAL_TILE_Z_INDEX: int = 1
const BOARD_TILE_SWAP_DURATION: float = 0.26
const BOARD_TILE_SINK_OFFSET: float = 7.0
const BOARD_TILE_SUNK_ALPHA: float = 0.32
const BOARD_TILE_SLIDE_DISTANCE_FACTOR: float = 1.06
const BOARD_TILE_DEPTH_WALL_COLOR = Color(0.07, 0.065, 0.055, 0.86)
const BOARD_TILE_OCCLUSION_LIP_COLOR = Color(0.0, 0.0, 0.0, 0.30)
const BOARD_TILE_OCCLUSION_LIP_INSET_FACTOR: float = 0.18
const BOARD_TILE_TRANSITION_COVER_Z_INDEX: int = 5
const BOARD_FRAME_WIDTH: float = CELL_WIDTH
const BOARD_FRAME_VERTICAL_EXTENSION: float = CELL_WIDTH
const BOARD_FRAME_COLOR = Color(0.40, 0.32, 0.30, 1.0)
const BOARD_SIDE_THICKNESS: float = CELL_WIDTH * 0.58
const BOARD_SIDE_COLOR = Color(0.02, 0.12, 0.16, 1.0)
const BOARD_SHADER_OVERLAY_Z_INDEX: int = 220
const BOARD_SHADER_RADIUS: int = 1
const PIECE_KUWAHARA_RADIUS: int = 2
const DEFAULT_PIECE_VISUAL_HEIGHT: float = 24.0
const PIECE_AUTO_FIT_HEIGHT_THRESHOLD: float = DEFAULT_PIECE_VISUAL_HEIGHT * 2.0
const DEFAULT_PIECE_BOTTOM_INSET: float = 1.5
const PIECE_PERSPECTIVE_SCALE_VARIATION: float = 0.10
const PIECE_SHADOW_NAME = "PieceShadow"
const PIECE_SHADOW_LIGHT_TEXTURE_SCALE: float = 0.22
const PIECE_SHADOW_LIGHT_SOURCE_OFFSET: float = 8.0
const PIECE_SHADOW_LIGHT_ENERGY: float = 0.30
const PIECE_SHADOW_LIGHT_COLOR = Color(1.0, 0.92, 0.72, 1.0)
const PIECE_SHADOW_LIGHT_SHADOW_COLOR = Color(0.0, 0.0, 0.0, 0.88)
const PIECE_SHADOW_LIGHT_SHADOW_SMOOTH: float = 0.0
const PIECE_LIGHT_OCCLUDER_NAME = "PieceLightOccluder"
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_WIDTH_FACTOR: float = 0.68
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_FIXED_RADIUS_Y: float = 3.0
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_BOTTOM_INSET_FACTOR: float = 0.05
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET = Vector2.ZERO
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_SEGMENTS: int = 18
const PIECE_FOOTPRINT_ALPHA_THRESHOLD: float = 0.04
const PIECE_FOOTPRINT_WIDTH_SCAN_START_RATIO: float = 0.6666667
const PIECE_FOOTPRINT_STABLE_WIDTH_BAND_RATIO: float = 0.25
const PIECE_FOOTPRINT_STABLE_ROW_SAMPLE_COUNT: int = 8
const PIECE_LIGHT_OCCLUDER_FOOTPRINT_MIN_RADIUS_BOUNDS_FACTOR: float = 0.22
const BOARD_LIGHT_RECEIVE_MASK: int = 1
const PIECE_LIGHT_OCCLUDER_MASK: int = 1
const PIECE_LIGHT_RECEIVE_MASK: int = 2
const PIECE_EFFECT_LIGHT_RECEIVE_MASK: int = 0
const PIECE_TEXTURE_FILTER = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
const ATTACH_POINT_LIGHT_NAME = "AttachPointLight"
const ATTACH_PIECE_LIGHT_NAME = "AttachPieceLight"
const ATTACH_POINT_LIGHT_TEXTURE_SIZE: int = 256
const ATTACH_POINT_LIGHT_TEXTURE_SCALE: float = 0.92
const ATTACH_POINT_LIGHT_ENERGY: float = 1.25
const ATTACH_POINT_LIGHT_COLOR = Color(1.0, 0.74, 0.24, 1.0)
const ATTACH_POINT_LIGHT_SHADOW_COLOR = Color(0.0, 0.0, 0.0, 0.52)
const ATTACH_POINT_LIGHT_SHADOW_SMOOTH: float = 2.5
const ATTACH_PIECE_LIGHT_TEXTURE_SCALE: float = 1.08
const ATTACH_PIECE_LIGHT_ENERGY: float = 0.62
const ATTACH_PIECE_LIGHT_COLOR = Color(1.0, 0.84, 0.36, 1.0)
const LIGHT_TEXTURE_GRAIN_STRENGTH: float = 0.12
const LIGHT_TEXTURE_FINE_GRAIN_STRENGTH: float = 0.045
const LIGHT_TEXTURE_GRAIN_FREQUENCY: float = 0.085
const LIGHT_TEXTURE_FINE_GRAIN_FREQUENCY: float = 0.31
const AMBIENT_BOARD_LIGHT_NAME = "AmbientBoardLight"
const AMBIENT_BOARD_FILL_LIGHT_NAME = "AmbientBoardFillLight"
const AMBIENT_BOARD_LIGHT_TEXTURE_SCALE: float = 0.92
const AMBIENT_BOARD_FILL_LIGHT_TEXTURE_SCALE: float = 2.35
const AMBIENT_BOARD_LIGHT_OFFSET = Vector2.ZERO
const AMBIENT_BOARD_LIGHT_ENERGY: float = 0.32
const AMBIENT_BOARD_FILL_LIGHT_ENERGY: float = 0.16
const AMBIENT_BOARD_LIGHT_COLOR = Color(1.0, 0.86, 0.58, 1.0)
const AMBIENT_BOARD_LIGHT_SHADOW_COLOR = Color(0.0, 0.0, 0.0, 0.50)
const AMBIENT_BOARD_LIGHT_SHADOW_SMOOTH: float = 2.0
const PLAYER_HAND_SIZE = DeckManager.HAND_SIZE
const STAMP_UI_SIZE = Vector2(168.7, 229)
const STAMP_HAND_SCALE = 0.648
const DECK_STAMP_SCALE = STAMP_HAND_SCALE
const DECK_EXTRA_LEFT_OFFSET: float = 200.0
const STAMP_RETURN_TO_DECK_START_SCALE: float = 0.74 * 0.75
const STAMP_RETURN_TO_DECK_END_SCALE: float = DECK_STAMP_SCALE * 0.50
const STAMP_RETURN_TO_DECK_DURATION: float = 0.62
const STAMP_UI_GAP = 10
const TOP_STAMP_HAND_MARGIN = -28
const BOTTOM_STAMP_HAND_MARGIN = 34
const HOVER_STAMP_MARGIN = 24
const HOVER_STAMP_PREVIEW_SCALE: float = 0.82
const HOVER_STAMP_VERTICAL_OFFSET: float = 54.0
const HOVER_STAMP_ROTATION_DEGREES: float = -4.0
const HOVER_STAMP_VISUAL_EDGE_OVERLAP: float = 12.0
const HOVER_PIECE_PREVIEW_SIZE = Vector2(188, 224)
const HOVER_PIECE_PREVIEW_VERTICAL_OFFSET: float = -78.0
const HOVER_DESCRIPTION_TEXT_MARGIN = Vector2(22, 30)
const HOVER_DESCRIPTION_FRAME_EDGE_COLOR = Color(0.12, 0.085, 0.055, 0.62)
const HOVER_DESCRIPTION_FRAME_EDGE_THICKNESS: float = 2.0
const HOVER_DESCRIPTION_FRAME_EDGE_HORIZONTAL_INSET: float = 18.0
const HOVER_DESCRIPTION_FRAME_EDGE_VERTICAL_INSET: float = 19.0
const HIDDEN_STAMP_MARGIN = 24
const HIDDEN_STAMP_GAP = 10
const HIDDEN_STAMP_SCALE = 0.70 * 0.75
const HIDDEN_STAMP_PREVIEW_ALPHA: float = 0.70
const CODEX_PANEL_SIZE: Vector2 = Vector2(244, 116)
const CODEX_PANEL_MARGIN: Vector2 = Vector2(22, 24)
const BOARD_MARKER_LINE_WIDTH = 1.8
const STAMP_ATTACH_TARGET_FILL_COLOR = Color(1.0, 0.92, 0.58, 0.24)
const STAMP_ATTACH_TARGET_FILL_INSET: float = 1.0
const STAMP_ATTACH_TARGET_WIGGLE_RISE: float = 2.2
const STAMP_ATTACH_TARGET_WIGGLE_ROTATION_DEGREES: float = 2.2
const STAMP_ATTACH_TARGET_WIGGLE_STEP_DURATION: float = 0.105
const SELECTED_PIECE_GLOW_NAME = "SelectedPieceGlow"
const SELECTED_PIECE_GLOW_Z_INDEX = 24
const SELECTED_PIECE_GLOW_STRENGTH: float = 1.0
const PIECE_FREEZE_CRACK_NAME = "PieceFreezeCrack"
const PIECE_FREEZE_CRACK_Z_INDEX = 0
const PIECE_FREEZE_CRACK_DURATION: float = 1.5
const PIECE_FREEZE_CRACK_RELEASE_DURATION: float = 1.5
const PIECE_FREEZE_CRACK_START_WIDTH: float = 0.0
const PIECE_FREEZE_CRACK_END_WIDTH: float = 0.7
const PIECE_FREEZE_CRACK_DEPTH: float = 2.46
const PIECE_FREEZE_CRACK_SCALE: float = 7.96
const PIECE_FREEZE_CRACK_ZEBRA_SCALE: float = 1.61
const PIECE_FREEZE_CRACK_ZEBRA_AMP: float = 1.33
const PIECE_FREEZE_CRACK_PROFILE: float = 0.33
const PIECE_FREEZE_CRACK_SLOPE: float = 13.03
const PIECE_FREEZE_REFRACTION_OFFSET = Vector2(24.92, 25.0)
const PIECE_FREEZE_REFLECTION_OFFSET = Vector2(1.28, 1.0)
const PIECE_FREEZE_RELEASE_NAME = "PieceFreezeRelease"
const PIECE_FREEZE_SQUARE_NAME = "PieceFreezeSquare"
const PIECE_FREEZE_SQUARE_RELEASE_NAME = "PieceFreezeSquareRelease"
const PIECE_FREEZE_SQUARE_Z_INDEX: int = 0
const PIECE_FREEZE_SQUARE_INSET: float = 0.0
const PIECE_FREEZE_SQUARE_ALPHA: float = 0.74
const PIECE_ATTACH_GLOW_NAME = "PieceAttachGlow"
const PIECE_ATTACH_TARGET_GLOW_NAME = "PieceAttachTargetGlow"
const PIECE_ATTACH_RAYS_NAME = "PieceAttachRays"
const PIECE_ATTACH_MORPH_NAME = "PieceAttachMorph"
const PIECE_ATTACH_GLOW_Z_INDEX = 26
const PIECE_ATTACH_MORPH_Z_INDEX = 1
const PIECE_ATTACH_RAYS_Z_INDEX = 25
const PIECE_EFFECT_OCCLUSION_DIM_NAME = "PieceEffectOcclusionDim"
const PIECE_EFFECT_OCCLUSION_DIM_Z_INDEX = 0
const PIECE_ATTACH_GLOW_COLOR = Color(1.0, 0.82, 0.28, 1.0)
const PIECE_ATTACH_GLOW_SIZE: float = 4.8
const PIECE_ATTACH_GLOW_FILL_STRENGTH: float = 0.30
const PIECE_ATTACH_GLOW_BASE_STRENGTH: float = 1.0
const PIECE_ATTACH_GLOW_SWITCH_STRENGTH: float = 4.0
const PIECE_ATTACH_GLOW_SWITCH_DURATION: float = 0.06
const PIECE_ATTACH_IN_DURATION: float = 0.32
const PIECE_ATTACH_PRE_SWITCH_HOLD_DURATION: float = 0.14
const PIECE_ATTACH_MORPH_DURATION: float = 1.00
const PIECE_ATTACH_TARGET_APPEAR_DURATION: float = 0.50
const PIECE_ATTACH_POST_SWITCH_HOLD_DURATION: float = 0.20
const PIECE_ATTACH_OUT_DURATION: float = 0.32
const PIECE_ATTACH_MORPH_NOISE_STRENGTH: float = 0.14
const PIECE_ATTACH_MORPH_SHINE_STRENGTH: float = 0.34
const PIECE_ATTACH_RAYS_START_SIZE: float = 10.0
const PIECE_ATTACH_RAYS_SWITCH_SIZE: float = 1.0
const PIECE_ATTACH_RAYS_TEXTURE_SIZE: int = 256
const PIECE_ATTACH_RAYS_OVERLAY_SCALE: float = 2.65
const PIECE_ATTACH_RAYS_LOCAL_OFFSET = Vector2.ZERO
const PIECE_ATTACH_RAYS_SPREAD: float = 0.5
const PIECE_ATTACH_RAYS_CUTOFF: float = 0.39
const PIECE_ATTACH_RAYS_SPEED: float = 1.4
const PIECE_ATTACH_RAYS_RAY1_DENSITY: float = 8.0
const PIECE_ATTACH_RAYS_RAY2_DENSITY: float = 10.0
const PIECE_ATTACH_RAYS_RAY2_INTENSITY: float = 0.3
const PIECE_ATTACH_RAYS_CORE_INTENSITY: float = 2.0
const PIECE_ATTACH_RAYS_SEED: float = 5.0
const PIECE_ATTACH_RAYS_FADE_IN_DELAY_RATIO: float = 0.0
const PIECE_ATTACH_RAYS_FADE_IN_DURATION_RATIO: float = 1.0
const PIECE_INVISIBILITY_VISIBLE_HOLD_DURATION: float = 0.50
const PIECE_INVISIBILITY_REFRACT_IN_DURATION: float = 0.42
const PIECE_INVISIBILITY_FADE_OUT_DURATION: float = 1.48
const PIECE_INVISIBILITY_REFRACT_DISTANCE: float = 16.0
const PIECE_EXPIRE_DISSOLVE_DURATION: float = 1.62
const PIECE_EXPIRE_DISSOLVE_BEAM_SIZE: float = 0.05
const PIECE_EXPIRE_DISSOLVE_NOISE_DENSITY: float = 60.0
const PIECE_EXPIRE_DISSOLVE_COLOR = Color(1.0, 0.42, 0.02, 1.0)
const LAST_MOVE_ARROW_WIDTH = 3.0
const LAST_MOVE_ARROW_ENDPOINT_INSET = 6.0
const LAST_MOVE_ARROW_HEAD_LENGTH = 8.0
const LAST_MOVE_ARROW_HEAD_HALF_WIDTH = 5.0
const LAST_MOVE_ARROW_COLOR = Color(1.0, 0.88, 0.18, 1.0)
const DECK_COUNT_LABEL_SIZE = Vector2(88, 28)
const DECK_COUNT_LABEL_GAP = 8
const DECK_COUNTER_BACKGROUND_SIZE = Vector2(38, 38)
const DECK_COUNTER_DIGIT_SIZE = DECK_COUNTER_BACKGROUND_SIZE
const DECK_COUNTER_DIGIT_GAP: float = 0.0
const DECK_COUNTER_FRAME_SIZE = Vector2(82, 42)
const DECK_COUNTER_CONTENT_OFFSET = Vector2(
	(DECK_COUNTER_FRAME_SIZE.x - (DECK_COUNTER_BACKGROUND_SIZE.x * 2.0 + DECK_COUNTER_DIGIT_GAP)) * 0.5,
	(DECK_COUNTER_FRAME_SIZE.y - DECK_COUNTER_BACKGROUND_SIZE.y) * 0.5
)
const DECK_COUNTER_SIZE = DECK_COUNTER_FRAME_SIZE
const DECK_COUNTER_ROLL_DURATION: float = 0.34
const DECK_COUNTER_MOTION_BLUR: float = 1.0
const DECK_COUNTER_OFFSET = Vector2(0.0, 0.0)
const DECK_COUNTER_Z_INDEX: int = 952
const TURN_TIMER_LIMIT_SECONDS: int = 300
const TURN_TIMER_COUNTER_KEY: int = 0
const TURN_TIMER_GAP: float = 8.0
const TURN_TIMER_Z_INDEX: int = 961
const PLAYER_NAME_LABEL_SIZE = Vector2(180, 28)
const PLAYER_NAME_LABEL_GAP = 8
const PLAYER_PORTRAIT_SIZE = Vector2(116, 136)
const PLAYER_PORTRAIT_MARGIN = 22
const PLAYER_PORTRAIT_TOP_POSITION = Vector2(70, 4)
const PLAYER_PORTRAIT_Z_INDEX: int = 928
const RULES_INFO_BUTTON_SIZE = Vector2(40, 40)
const RULES_INFO_PANEL_SIZE = Vector2(340, 390)
const RULES_INFO_PANEL_MARGIN = 24
const END_TURN_INDICATOR_PADDING: float = 7.0
const END_TURN_INDICATOR_COLOR = Color(1.0, 1.0, 1.0, 0.92)
const END_TURN_INDICATOR_Z_INDEX: int = 950
const ACTION_STATUS_SIZE = Vector2(132, 46)
const ACTION_STATUS_MARGIN = 22
const ACTION_STATUS_CELL_SIZE = Vector2(36, 42)
const ACTION_STATUS_CELL_GAP: int = 7
const ACTION_STATUS_FLIP_DURATION: float = 0.16
const ACTION_STATUS_ACTIVE_COLOR = Color(1.0, 1.0, 1.0, 1.0)
const ACTION_STATUS_ACTIVE_TEXT_COLOR = Color(0.05, 0.05, 0.045, 1.0)
const ACTION_STATUS_ACTIVE_BORDER_COLOR = Color(0.12, 0.10, 0.075, 1.0)
const ACTION_STATUS_INACTIVE_COLOR = Color(0.94, 0.93, 0.89, 1.0)
const ACTION_STATUS_BLOCKED_COLOR = Color(0.02, 0.02, 0.02, 1.0)
const ACTION_STATUS_STATE_ACTIVE: String = "active"
const ACTION_STATUS_STATE_EMPTY: String = "empty"
const ACTION_STATUS_STATE_BLOCKED: String = "blocked"
const INVALID_BOARD_POS = Vector2(-1, -1)
const WHITE_BASE_FIELD: Vector2 = BoardConfig.WHITE_BASE_FIELD
const BLACK_BASE_FIELD: Vector2 = BoardConfig.BLACK_BASE_FIELD
const MAIN_MENU_SCENE = "res://Scenes/MainMenu.tscn"
const MATCH_END_FEEDBACK_SCENE = "res://Scenes/MatchEndFeedback.tscn"
const STAMP_BURN_SEQUENCE_GAP = 0.08
const TUTORIAL_ACTION_SELECT_PIECE = "select_piece"
const TUTORIAL_ACTION_ATTACH_STAMP = "attach_stamp"
const TUTORIAL_ACTION_MOVE_PIECE = "move_piece"
const TUTORIAL_ACTION_EXCHANGE_STAMP = "exchange_stamp"
const TUTORIAL_ACTION_TURN_PAGE = "turn_page"
const TUTORIAL_ACTION_END_TURN = "end_turn"
# Translation key, not display text - the actual paragraph lives in Localization/translations.csv.
const RULES_INFO_TEXT: String = "RULES_INFO_TEXT"
const PIECE_SHATTER_FRAGMENT_GROUP_NONE: String = ""
const PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM: String = "bottom"
const PIECE_SHATTER_FRAGMENT_GROUP_TOP: String = "top"
const PIECE_SHATTER_FRAGMENT_GROUP_PENDING: String = "pending"
const PIECE_SHATTER_FRAGMENT_LANDING_HOLD_DURATION: float = 0.08
const PIECE_SHATTER_ROUTE_Z_FRONT_OFFSET: int = 2
const PIECE_SHATTER_ROUTE_Z_BACK_OFFSET: int = -1
const PIECE_SHATTER_ROUTE_DIRECT_FALLBACK_OFFSET: float = 0.72
const PIECE_SHATTER_RETURN_ACCELERATION_PROGRESS: float = 0.5
const PIECE_MOVE_ROUTE_Z_FRONT_OFFSET: int = 1
const PIECE_MOVE_ROUTE_Z_BACK_OFFSET: int = -1
const PIECE_MOVE_ROUTE_CORNER_ROUNDING_RATIO: float = 0.28
const PIECE_MOVE_ROUTE_CORNER_SAMPLE_COUNT: int = 4
const BOMB_WARNING_Z_OFFSET: int = 7

@export_group("Piece Shatter")
@export_range(0, 64, 1) var piece_shatter_debris_count: int = 18
@export_range(0, 3, 1) var piece_shatter_returning_debris_count: int = 3
@export_range(0.05, 2.0, 0.01) var piece_shatter_scatter_duration: float = 0.46
@export_range(0.05, 2.0, 0.01) var piece_shatter_fade_duration: float = 0.42
@export_range(0.05, 2.0, 0.01) var piece_shatter_return_duration: float = 0.38
@export_range(0.02, 1.0, 0.01) var piece_shatter_return_fade_duration: float = 0.16
@export_range(0.0, 1.0, 0.01) var piece_shatter_fragment_settle_duration: float = 0.24
@export_range(0.1, 2.0, 0.05) var piece_shatter_scatter_radius: float = 0.84
@export_range(0.0, 1.0, 0.05) var piece_shatter_scatter_jitter: float = 0.28
@export_range(0.05, 1.0, 0.01) var piece_shatter_min_piece_scale: float = 0.16
@export_range(0.05, 1.0, 0.01) var piece_shatter_max_piece_scale: float = 0.32
@export var piece_shatter_avoid_occupied_cells: bool = true
@export_range(0.0, 0.45, 0.01) var piece_shatter_route_jitter_ratio: float = 0.12

@export_group("Capture Flash")
@export var capture_flash_color: Color = Color(1.0, 0.92, 0.56, 1.0)
@export_range(0.05, 1.5, 0.01) var capture_flash_duration: float = 0.75
@export_range(0.2, 5.0, 0.05) var capture_flash_size_ratio: float = 1.95
@export_range(0.05, 1.0, 0.01) var capture_flash_start_scale_ratio: float = 0.16
@export_range(0.0, 180.0, 1.0) var capture_flash_rotation_degrees: float = 22.0

@export_group("Piece Movement")
@export var piece_move_animation_enabled: bool = true
@export var piece_move_avoid_occupied_footprints: bool = true
@export_range(0.05, 1.0, 0.01) var piece_move_duration: float = 0.32
@export_range(0.0, 0.5, 0.01) var piece_move_lift_ratio: float = 0.16
@export_range(0.05, 0.5, 0.01) var piece_move_lift_duration: float = 0.16
@export_range(0.05, 0.5, 0.01) var piece_move_drop_duration: float = 0.18
@export_range(0.03, 0.3, 0.01) var piece_move_wobble_step_duration: float = 0.12
@export_range(0.0, 8.0, 0.1) var piece_move_wobble_rotation_degrees: float = 2.4
@export_range(0.0, 5.0, 0.1) var piece_move_travel_tilt_degrees: float = 1.4
@export_range(0.2, 0.55, 0.01) var piece_move_capture_approach_edge_ratio: float = 0.42
@export_range(0.0, 0.6, 0.01) var piece_move_capture_approach_hold_duration: float = 0.25
@export_range(0.05, 0.35, 0.01) var piece_move_capture_push_duration: float = 0.14
@export_range(0.05, 0.35, 0.01) var piece_move_capture_recoil_duration: float = 0.12
@export_range(0.05, 0.5, 0.01) var piece_move_capture_center_settle_duration: float = 0.24
@export_range(0.0, 18.0, 0.5) var piece_move_capture_push_rotation_degrees: float = 8.0
@export var piece_move_shadow_color: Color = Color(0.03, 0.025, 0.02, 0.30)
@export var piece_move_shadow_radius_scale: Vector2 = Vector2(0.92, 0.72)
@export_range(0.01, 0.9, 0.01) var piece_move_shadow_ground_edge_softness: float = 0.10
@export_range(0.01, 0.9, 0.01) var piece_move_shadow_lifted_edge_softness: float = 0.72
@export var piece_move_shadow_lifted_scale: Vector2 = Vector2(1.38, 1.28)
@export_range(0.05, 1.0, 0.01) var piece_move_shadow_lifted_alpha: float = 0.42
@export_range(0.0, 16.0, 0.5) var piece_move_footprint_clearance: float = 2.0

@export_group("Piece Effect Occlusion")
@export var occluded_piece_effect_dim_color: Color = Color(0.0, 0.0, 0.0, 0.34)

@export_group("Bomb Warning")
@export var bomb_warning_color: Color = Color(1.0, 0.56, 0.56, 1.0)
@export_range(0.2, 3.0, 0.05) var bomb_warning_duration: float = 1.5
@export_range(0.0, 24.0, 0.5) var bomb_warning_rise_distance: float = 7.0
@export_range(0.2, 3.0, 0.05) var bomb_warning_size_ratio: float = 1.15
@export_range(-24.0, 24.0, 0.5) var bomb_warning_target_y_offset: float = -6.0

@export_group("Board Shadow")
@export var board_shadow_enabled: bool = true
@export var board_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.24)
@export var board_shadow_offset: Vector2 = Vector2(9.0, 14.0)
@export_range(0.0, 24.0, 0.5) var board_shadow_spread: float = 7.0
@export_range(1, 8, 1) var board_shadow_steps: int = 4

@export_group("Board Shader")
@export var board_shader_enabled: bool = true
@export_range(0.0, 128.0, 1.0) var board_shader_margin: float = CELL_WIDTH * 3.5
@export var board_shader_offset: Vector3 = Vector3.ZERO

@export_group("Piece Shader")
@export var piece_kuwahara_enabled: bool = false
@export var piece_kuwahara_offset: Vector3 = Vector3.ZERO

@onready var pieces_node = $Pieces
@onready var dots = $Dots
@onready var board_tiles_node = $BoardTiles
@onready var canvas_layer = $"../CanvasLayer"
@onready var white_pieces = $"../CanvasLayer/white_pieces"
@onready var black_pieces = $"../CanvasLayer/black_pieces"

var board : Array
var piece_objects: Dictionary = {}
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2
var hovered_piece : Vector2 = Vector2(-1, -1)
var white_stamp_deck: Array[String] = []
var black_stamp_deck: Array[String] = []
var white_stamp_hand: Array[Stamp] = []
var black_stamp_hand: Array[Stamp] = []
var white_stamp_visuals: Array[StampVisual] = []
var black_stamp_visuals: Array[StampVisual] = []
var white_deck_visual: StampVisual
var black_deck_visual: StampVisual
var attached_stamp_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var attached_stamp_count_this_turn: Dictionary = {0: 0, 1: 0}
var completed_turn_counts: Dictionary = {0: 0, 1: 0}
var moved_piece_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var exchanged_stamp_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var has_turned_page_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var played_stamp_hand_slots_this_turn: Dictionary = {
	1: [],
	-1: [],
}
var pending_stamp_attach_positions: Dictionary = {}
var exchanged_stamp_names_this_turn: Dictionary = {
	1: [],
	-1: [],
}
var game_over: bool = false
var hover_stamp_group: Control
var hover_stamp_preview: StampVisual
var hover_piece_preview: TextureRect
var hover_duration_label: Label
var hover_description_panel: Control
var hover_description_label: Label
var has_received_server_state: bool = false
var quit_confirmation_dialog: ConfirmationDialog
var white_deck_count_override: int = -1
var black_deck_count_override: int = -1
var hidden_stamp_counts: Dictionary = {}
var controller_registry
var board_markers_node: Node2D
var board_frame_node: Node2D
var board_base_tiles_node: Node2D
var board_special_tiles_node: Node2D
var board_special_tile_nodes: Dictionary = {}
var board_special_tile_types: Dictionary = {}
var board_special_tiles_initialized: bool = false
var piece_effects_node: Node2D
var current_last_move: Dictionary = {}
var current_board_effects: Array = []
var current_player_base_fields: Dictionary = {
	0: WHITE_BASE_FIELD,
	1: BLACK_BASE_FIELD,
}
var current_player_names: Dictionary = {
	0: "Player",
	1: "Player",
}
var current_player_portraits: Dictionary = {}
var pending_piece_revert_animations: Array[Dictionary] = []
var pending_piece_shatter_respawn_reveal_counts: Dictionary = {}
var pending_piece_shatter_respawn_reveal_groups: Dictionary = {}
var respawn_piece_shatter_fragment_markers: Dictionary = {}
var pending_edge_respawn_fragment_markers: Dictionary = {}
var local_pending_respawns: Dictionary = {
	1: [],
	-1: [],
}
var local_auto_end_turn_pending: bool = false
var tutorial_mode_active: bool = false
var tutorial_constraints_enabled: bool = false
var tutorial_constraints: Dictionary = {}

var side

func set_turn(_turn):
	get_match_board_lifecycle_controller().set_turn(_turn)

func _ready():
	get_match_board_lifecycle_controller().ready()

func apply_board_visual_scale() -> void:
	get_match_board_lifecycle_controller().apply_board_visual_scale()

func get_controller_registry():
	if controller_registry == null:
		controller_registry = MATCH_BOARD_CONTROLLER_REGISTRY_SCRIPT.new()
	controller_registry.configure({
		"match_board": self,
	})
	return controller_registry

func get_match_board_lifecycle_controller():
	return get_controller_registry().get_match_board_lifecycle_controller()

func get_board_geometry():
	return get_controller_registry().get_board_geometry()

func get_board_visuals():
	return get_controller_registry().get_board_visuals()

func get_board_environment_controller():
	return get_controller_registry().get_board_environment_controller()

func get_visual_process_tracker():
	return get_controller_registry().get_visual_process_tracker()

func begin_visual_process(process_name: String) -> void:
	get_visual_process_tracker().begin(process_name)

func finish_visual_process(process_name: String) -> void:
	get_visual_process_tracker().finish(process_name)

func is_visual_process_active(process_name: String) -> bool:
	return get_visual_process_tracker().is_active(process_name)

func has_active_visual_processes(process_names: Array = []) -> bool:
	return get_visual_process_tracker().has_any_active(process_names)

func get_board_tile_controller():
	return get_controller_registry().get_board_tile_controller()

func get_board_marker_controller():
	return get_controller_registry().get_board_marker_controller()

func get_match_state_sync_controller():
	return get_controller_registry().get_match_state_sync_controller()

func get_server_state_update_controller():
	return get_controller_registry().get_server_state_update_controller()

func get_server_state_visual_update_controller():
	return get_controller_registry().get_server_state_visual_update_controller()

func get_local_state_mutator():
	return get_controller_registry().get_local_state_mutator()

func get_local_move_flow_controller():
	return get_controller_registry().get_local_move_flow_controller()

func get_local_stamp_action_controller():
	return get_controller_registry().get_local_stamp_action_controller()

func get_local_gameplay_controller():
	return get_controller_registry().get_local_gameplay_controller()

func get_tutorial_match_adapter():
	return get_controller_registry().get_tutorial_match_adapter()

func get_game_result_controller():
	return get_controller_registry().get_game_result_controller()

func get_turn_flow_controller():
	return get_controller_registry().get_turn_flow_controller()

func get_turn_action_state_controller():
	return get_controller_registry().get_turn_action_state_controller()

func get_piece_objects() -> Dictionary:
	return piece_objects

func get_current_board_effects() -> Array:
	return current_board_effects

func get_current_last_move() -> Dictionary:
	return current_last_move

func get_pending_stamp_attach_positions() -> Dictionary:
	return pending_stamp_attach_positions

func get_piece_texture_resolver():
	return get_controller_registry().get_piece_texture_resolver()

func get_piece_visuals():
	return get_controller_registry().get_piece_visuals()

func get_piece_effect_geometry_controller():
	return get_controller_registry().get_piece_effect_geometry_controller()

func get_piece_move_animator():
	return get_controller_registry().get_piece_move_animator()

func has_piece_object_at(board_pos: Vector2) -> bool:
	return piece_objects.has(board_pos)

func get_piece_shatter_animator():
	return get_controller_registry().get_piece_shatter_animator()

func get_piece_respawn_fragment_coordinator():
	return get_controller_registry().get_piece_respawn_fragment_coordinator()

func get_piece_display_controller():
	return get_controller_registry().get_piece_display_controller()

func get_piece_effect_animator():
	return get_controller_registry().get_piece_effect_animator()

func get_piece_effect_flow_controller():
	return get_controller_registry().get_piece_effect_flow_controller()

func get_freeze_effect_animator():
	return get_controller_registry().get_freeze_effect_animator()

func get_hidden_stamp_preview_controller():
	return get_controller_registry().get_hidden_stamp_preview_controller()

func get_stamp_hud_controller():
	return get_controller_registry().get_stamp_hud_controller()

func get_match_codex_controller():
	return get_controller_registry().get_match_codex_controller()

func get_stamp_hover_preview_controller():
	return get_controller_registry().get_stamp_hover_preview_controller()

func get_stamp_interaction_controller():
	return get_controller_registry().get_stamp_interaction_controller()

func get_stamp_animation_controller():
	return get_controller_registry().get_stamp_animation_controller()

func get_visible_viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size

func get_board_screen_size() -> float:
	return BOARD_SIZE * CELL_WIDTH * get_board_screen_scale()

func get_game_result_context() -> Dictionary:
	return {
		"is_ai_vs_ai_batch": GameConfig.is_ai_vs_ai_batch,
		"ai_matches_played": GameConfig.ai_vs_ai_matches_played,
		"ai_match_count": GameConfig.ai_vs_ai_match_count,
		"side_is_null": side == null,
	}

func get_deck_counter_controller():
	return get_controller_registry().get_deck_counter_controller()

func get_turn_hud_controller():
	return get_controller_registry().get_turn_hud_controller()

func get_player_portrait_top_position() -> Vector2:
	return scale_canvas_point_from_reference(PLAYER_PORTRAIT_TOP_POSITION)

func get_scaled_player_portrait_size() -> Vector2:
	return scale_canvas_size_from_reference(PLAYER_PORTRAIT_SIZE)

func scale_canvas_point_from_reference(point: Vector2) -> Vector2:
	return point * get_canvas_scale_from_reference()

func scale_canvas_size_from_reference(source_size: Vector2) -> Vector2:
	return source_size * get_canvas_scale_from_reference()

func get_canvas_scale_from_reference() -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Vector2.ONE
	return Vector2(
		viewport_size.x / RESPONSIVE_REFERENCE_VIEWPORT_SIZE.x,
		viewport_size.y / RESPONSIVE_REFERENCE_VIEWPORT_SIZE.y
	)

func get_match_input_controller():
	return get_controller_registry().get_match_input_controller()

func get_stamp_hand_state_controller():
	return get_controller_registry().get_stamp_hand_state_controller()

func is_game_over() -> bool:
	return game_over

func is_end_turn_tutorial_allowed() -> bool:
	return is_tutorial_action_allowed(TUTORIAL_ACTION_END_TURN)

func should_show_first_turn_end_button() -> bool:
	var player_id: int = get_player_id_for_color(get_current_turn_color())
	if int(completed_turn_counts.get(player_id, 0)) == 0:
		return true
	return get_local_state_mutator().current_player_can_end_turn_due_to_frozen_piece()

func can_end_first_turn() -> bool:
	if !should_show_first_turn_end_button():
		return false
	var player_id: int = get_player_id_for_color(get_current_turn_color())
	if int(completed_turn_counts.get(player_id, 0)) == 0:
		return int(attached_stamp_count_this_turn.get(player_id, 0)) >= 1
	return get_local_state_mutator().current_player_can_end_turn_due_to_frozen_piece()

func defer_turn_timer_timeout(expected_turn_color: int) -> void:
	call_deferred("_on_turn_timer_timeout", expected_turn_color)

func set_tutorial_constraints(constraints: Dictionary) -> void:
	get_tutorial_match_adapter().set_constraints(constraints)

func set_tutorial_mode_active(active: bool) -> void:
	get_tutorial_match_adapter().set_mode_active(active)

func clear_tutorial_constraints() -> void:
	get_tutorial_match_adapter().clear_constraints()

func refresh_tutorial_dependent_ui() -> void:
	get_tutorial_match_adapter().refresh_dependent_ui()

func is_tutorial_action_allowed(action_name: String, context: Dictionary = {}, emit_rejection: bool = false) -> bool:
	return get_tutorial_match_adapter().is_action_allowed(action_name, context, emit_rejection)

func can_auto_end_turn_now() -> bool:
	return get_tutorial_match_adapter().can_auto_end_turn_now()

func apply_tutorial_setup(setup: Dictionary) -> void:
	get_tutorial_match_adapter().apply_setup(setup)

func set_tutorial_board_from_array(board_data: Array) -> void:
	get_tutorial_match_adapter().set_board_from_array(board_data)

func set_tutorial_attached_stamps(attached_stamps: Array) -> void:
	get_tutorial_match_adapter().set_attached_stamps(attached_stamps)

func reset_tutorial_turn_state() -> void:
	get_tutorial_match_adapter().reset_turn_state()

func set_tutorial_stamp_hand(owner_color: int, stamp_names: Array) -> void:
	get_tutorial_match_adapter().set_stamp_hand(owner_color, stamp_names)

func set_tutorial_stamp_deck(owner_color: int, stamp_names: Array) -> void:
	get_tutorial_match_adapter().set_stamp_deck(owner_color, stamp_names)

func set_tutorial_turn(owner_color: int) -> void:
	get_tutorial_match_adapter().set_turn(owner_color)

func create_board_markers_node():
	board_markers_node = Node2D.new()
	board_markers_node.name = "BoardMarkers"
	board_markers_node.z_index = 1
	add_child(board_markers_node)
	move_child(board_markers_node, 0)
	pieces_node.z_index = 10
	dots.z_index = 20

func create_piece_effects_node() -> void:
	if piece_effects_node != null and is_instance_valid(piece_effects_node):
		return

	piece_effects_node = Node2D.new()
	piece_effects_node.name = "PieceEffects"
	piece_effects_node.z_index = 12
	add_child(piece_effects_node)

func create_pieces_from_board():
	piece_objects.clear()
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var value = board[i][j]
			if value != 0:
				var pos = Vector2(i, j)
				var color: int = 1 if value > 0 else -1
				var piece = Piece.new(pos, color)
				piece_objects[pos] = piece
				DebugLog.info("Piece created: pos=%s, color=%s" % [pos, "white" if color > 0 else "black"])

	DebugLog.info("Pieces initialized without starting stamps.")

func setup_player_stamp_hands():
	get_stamp_hand_state_controller().setup_player_stamp_hands()

func create_stamp_hand_from_names(stamp_names: Array) -> Array[Stamp]:
	return get_stamp_hand_state_controller().create_stamp_hand_from_names(stamp_names)

func populate_stamp_hand(hand_node: Control, stamps: Array[Stamp], owner_color: int) -> Array[StampVisual]:
	return get_stamp_hand_state_controller().populate_stamp_hand(hand_node, stamps, owner_color)

func setup_deck_visuals():
	get_stamp_hand_state_controller().setup_deck_visuals()

func create_hover_piece_ui():
	var hover_controller = get_stamp_hover_preview_controller()
	hover_controller.create_ui()
	hover_stamp_group = hover_controller.hover_stamp_group
	hover_stamp_preview = hover_controller.hover_stamp_preview
	hover_piece_preview = hover_controller.hover_piece_preview
	hover_duration_label = hover_controller.hover_duration_label
	hover_description_panel = hover_controller.hover_description_panel
	hover_description_label = hover_controller.hover_description_label

func create_quit_confirmation_ui():
	quit_confirmation_dialog = ConfirmationDialog.new()
	canvas_layer.add_child(quit_confirmation_dialog)
	quit_confirmation_dialog.title = tr("Leave Game")
	quit_confirmation_dialog.dialog_text = tr("Do you really want to leave the game?")
	quit_confirmation_dialog.ok_button_text = tr("Yes")
	quit_confirmation_dialog.cancel_button_text = tr("No")
	quit_confirmation_dialog.exclusive = true
	quit_confirmation_dialog.confirmed.connect(_on_quit_confirmed)

func get_stamp_home_position(index: int) -> Vector2:
	return get_stamp_hand_state_controller().get_stamp_home_position(index)

func get_stamp_hand(owner_color: int) -> Array[Stamp]:
	return get_stamp_hand_state_controller().get_stamp_hand(owner_color)

func get_stamp_visuals(owner_color: int) -> Array[StampVisual]:
	return get_stamp_hand_state_controller().get_stamp_visuals(owner_color)

func get_stamp_deck(owner_color: int) -> Array[String]:
	return get_stamp_hand_state_controller().get_stamp_deck(owner_color)

func get_stamp_deck_count(owner_color: int) -> int:
	return get_stamp_hand_state_controller().get_stamp_deck_count(owner_color)

func get_stamp_hand_node(owner_color: int) -> Control:
	return get_stamp_hand_state_controller().get_stamp_hand_node(owner_color)

func get_deck_visual(owner_color: int) -> StampVisual:
	return get_stamp_hand_state_controller().get_deck_visual(owner_color)

func get_stamp_draw_start_position(owner_color: int) -> Vector2:
	return get_stamp_hand_state_controller().get_stamp_draw_start_position(owner_color)

func get_stamp_return_to_deck_target_position(owner_color: int, target_scale: float) -> Vector2:
	return get_stamp_hand_state_controller().get_stamp_return_to_deck_target_position(owner_color, target_scale)

func update_stamp_presentation():
	get_stamp_hand_state_controller().update_stamp_presentation()

func update_stamp_drag_permissions():
	get_stamp_hand_state_controller().update_stamp_drag_permissions()

func update_end_turn_button():
	get_turn_hud_controller().update_end_turn_button()

func begin_stamp_attach_process(piece_position: Vector2) -> void:
	if !pending_stamp_attach_positions.has(piece_position):
		begin_visual_process(VISUAL_PROCESS_STAMP_ATTACH)
	pending_stamp_attach_positions[piece_position] = true

func finish_stamp_attach_process(piece_position: Vector2) -> void:
	var had_pending_attach: bool = pending_stamp_attach_positions.has(piece_position)
	if pending_stamp_attach_positions.has(piece_position):
		pending_stamp_attach_positions.erase(piece_position)
		finish_visual_process(VISUAL_PROCESS_STAMP_ATTACH)
	if had_pending_attach:
		refresh_piece_freeze_overlay(piece_position)
	update_stamp_drag_permissions()
	get_turn_hud_controller().update_action_status_ui()

func has_pending_visual_processes() -> bool:
	return get_turn_flow_controller().has_pending_visual_processes()

func wait_for_pending_visual_processes() -> void:
	await get_turn_flow_controller().wait_for_pending_visual_processes()

func can_switch_action_now() -> bool:
	return get_turn_flow_controller().can_switch_action_now()

func can_attach_action_now() -> bool:
	return get_turn_flow_controller().can_attach_action_now()

func can_move_action_now() -> bool:
	return get_turn_flow_controller().can_move_action_now()

func has_remaining_turn_action_now() -> bool:
	return get_turn_flow_controller().has_remaining_turn_action_now()

func _on_turn_timer_timeout(expected_turn_color: int) -> void:
	await get_turn_flow_controller().on_turn_timer_timeout(expected_turn_color)

func maybe_auto_end_turn_locally() -> void:
	get_turn_flow_controller().maybe_auto_end_turn_locally()

func _auto_end_turn_locally_if_still_needed() -> void:
	await get_turn_flow_controller().auto_end_turn_locally_if_still_needed()

func _on_end_turn_pressed():
	await get_turn_flow_controller().on_end_turn_pressed()

func request_end_turn(emit_tutorial_rejection: bool, expected_turn_color: int = 0) -> void:
	await get_turn_flow_controller().request_end_turn(emit_tutorial_rejection, expected_turn_color)

func end_current_turn_locally():
	get_turn_flow_controller().end_current_turn_locally()

func handle_expired_seeker_stamp_locally(owner_color: int, expired_stamp: Stamp, piece_pos: Vector2) -> void:
	get_stamp_animation_controller().queue_seeker_stamp_return_to_deck_animation(owner_color, expired_stamp, piece_pos)
	get_match_codex_controller().return_local_seeker_stamp(owner_color, expired_stamp)

func update_stamp_face_visibility(local_color: int):
	for stamp_visual in white_stamp_visuals:
		stamp_visual.set_face_down(stamp_visual.owner_color != local_color)
	for stamp_visual in black_stamp_visuals:
		stamp_visual.set_face_down(stamp_visual.owner_color != local_color)

func get_local_view_color() -> int:
	if side == null:
		return get_controllable_color()
	return get_own_color()

func is_local_view_ready() -> bool:
	return side != null or GameConfig.is_singleplayer or tutorial_mode_active

func get_controllable_color() -> int:
	if side == null:
		return 1 if white else -1
	return get_own_color()

func get_current_turn_color() -> int:
	return 1 if white else -1

func get_own_color() -> int:
	if side == null:
		return 1
	return 1 if side else -1

func get_player_id_for_color(owner_color: int) -> int:
	return BoardConfig.get_player_id_for_color(owner_color)

func get_color_for_player_id(player_id: int) -> int:
	return BoardConfig.get_color_for_player_id(player_id)

func get_own_player_id() -> int:
	return get_player_id_for_color(get_own_color())

func show_hover_stamp_description(stamp: Stamp) -> void:
	if stamp == null:
		return

	hide_hover_piece_details()
	var description: String = stamp.description.strip_edges()
	if description.is_empty():
		return

	get_stamp_hover_preview_controller().show_description(description)

func can_exchange_stamp_locally(owner_color: int) -> bool:
	return get_local_stamp_action_controller().can_exchange_stamp_locally(owner_color)

func is_tutorial_exchange_stamp_allowed(owner_color: int, stamp_name: String, hand_index: int, emit_rejection: bool) -> bool:
	return get_local_stamp_action_controller().is_tutorial_exchange_stamp_allowed(owner_color, stamp_name, hand_index, emit_rejection)

func complete_stamp_exchange(owner_color: int, stamp_name: String, hand_index: int, should_record_name: bool, source_global_position = null) -> void:
	get_local_stamp_action_controller().complete_stamp_exchange(owner_color, stamp_name, hand_index, should_record_name, source_global_position)

func send_stamp_exchange_action(owner_color: int, stamp_name: String, hand_index: int) -> bool:
	return get_local_stamp_action_controller().send_stamp_exchange_action(owner_color, stamp_name, hand_index)

func attach_stamp_visual_to_piece(stamp_visual: StampVisual, piece_position: Vector2) -> void:
	await get_local_stamp_action_controller().attach_stamp_visual_to_piece(stamp_visual, piece_position)

func send_stamp_attach_action(owner_color: int, stamp_name: String, piece_position: Vector2, hand_index: int) -> bool:
	return get_local_stamp_action_controller().send_stamp_attach_action(owner_color, stamp_name, piece_position, hand_index)

func can_attach_stamp_to_piece(piece_position: Vector2, stamp_name: String = "", owner_color: int = 0) -> bool:
	return get_local_stamp_action_controller().can_attach_stamp_to_piece(piece_position, stamp_name, owner_color)

func apply_stamp_to_piece(piece_position: Vector2, stamp_name: String) -> bool:
	return get_local_stamp_action_controller().apply_stamp_to_piece(piece_position, stamp_name)

func apply_remote_stamp_attach(piece_position: Vector2, stamp_name: String, owner_color: int, hand_index: int, _replacement_stamp_name: String = ""):
	get_local_stamp_action_controller().apply_remote_stamp_attach(piece_position, stamp_name, owner_color, hand_index, _replacement_stamp_name)

func remove_stamp_from_hand(stamp_visual: StampVisual) -> String:
	return get_stamp_hand_state_controller().remove_stamp_from_hand(stamp_visual)

func remove_stamp_from_hand_index(owner_color: int, hand_index: int, should_draw_replacement: bool = false, replacement_stamp_name: String = "") -> String:
	return get_stamp_hand_state_controller().remove_stamp_from_hand_index(owner_color, hand_index, should_draw_replacement, replacement_stamp_name)

func get_stamp_visual_index(stamp_visual: StampVisual) -> int:
	return get_stamp_hand_state_controller().get_stamp_visual_index(stamp_visual)

func insert_drawn_stamp(owner_color: int, hand_index: int, stamp_name: String):
	get_stamp_hand_state_controller().insert_drawn_stamp(owner_color, hand_index, stamp_name)

func get_stamp_names_from_hand(stamps: Array[Stamp]) -> Array[String]:
	return get_match_state_sync_controller().get_stamp_names_from_hand(stamps)

func get_state_stamp_expiration_events(previous_snapshot: Dictionary, recent_stamp_expirations: Array) -> Array[Dictionary]:
	return get_match_state_sync_controller().get_state_stamp_expiration_events(previous_snapshot, recent_stamp_expirations, piece_objects)

func queue_piece_revert_animation(piece_position: Vector2, start_texture: Texture2D) -> void:
	if start_texture == null or !is_valid_position(piece_position):
		return

	pending_piece_revert_animations.append({
		"position": piece_position,
		"start_texture": start_texture,
	})

func play_pending_piece_revert_animations() -> void:
	if pending_piece_revert_animations.is_empty():
		return

	var animations: Array[Dictionary] = pending_piece_revert_animations.duplicate()
	pending_piece_revert_animations.clear()
	play_piece_revert_animations(animations)

func play_piece_revert_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var board_pos: Vector2 = value_to_vector2(animation.get("position", INVALID_BOARD_POS), INVALID_BOARD_POS)
		var start_texture: Texture2D = animation.get("start_texture", null) as Texture2D
		play_piece_revert_animation(board_pos, start_texture)

func play_piece_revert_animation(piece_position: Vector2, start_texture: Texture2D) -> void:
	if should_skip_visual_animations() or start_texture == null or !is_valid_position(piece_position):
		return

	begin_visual_process(VISUAL_PROCESS_PIECE_REVERT)
	await get_piece_effect_animator().play_piece_revert(piece_position, start_texture)
	finish_visual_process(VISUAL_PROCESS_PIECE_REVERT)

func get_stamp_hand_source_position(owner_color: int) -> Vector2:
	var visuals: Array[StampVisual] = get_stamp_visuals(owner_color)
	for stamp_visual: StampVisual in visuals:
		if stamp_visual != null and is_instance_valid(stamp_visual) and stamp_visual.visible:
			return stamp_visual.global_position

	var hand_node: Control = get_stamp_hand_node(owner_color)
	if hand_node == null:
		return get_viewport().get_visible_rect().size * 0.5

	return hand_node.global_position + get_stamp_home_position(maxi(0, visuals.size() - 1))

func arrange_stamp_visuals(visuals: Array[StampVisual], animate: bool):
	get_stamp_interaction_controller().arrange_stamp_visuals(visuals, animate)

func _process(delta):
	get_match_input_controller().process(delta)

func is_mouse_over_deck(owner_color: int) -> bool:
	return get_deck_counter_controller().is_mouse_over_deck(owner_color)

func select_piece_for_action(piece_pos: Vector2) -> bool:
	return get_match_input_controller().select_piece_for_action(piece_pos)

func try_move_selected_piece(target_pos: Vector2) -> bool:
	return get_match_input_controller().try_move_selected_piece(target_pos)

func clear_piece_selection() -> void:
	get_match_input_controller().clear_piece_selection()

func _input(event):
	get_match_input_controller().handle_input(event)

func show_quit_confirmation():
	if quit_confirmation_dialog == null:
		return
	quit_confirmation_dialog.popup_centered(Vector2i(360, 140))

func _on_quit_confirmed():
	GameConfig.stop_ai_vs_ai_batch()
	if get_parent().has_method("close_game_connection"):
		get_parent().close_game_connection()
	if get_tree():
		SceneTransition.change_scene(MAIN_MENU_SCENE)

func send_move_action(from_pos: Vector2, to_pos: Vector2):
	get_match_input_controller().send_move_action(from_pos, to_pos)

func is_mouse_out():
	return get_match_input_controller().is_mouse_out()

func get_board_rect_local() -> Rect2:
	return get_board_geometry().get_board_rect_local()

func get_board_unprojected_rect_local() -> Rect2:
	return get_board_geometry().get_board_unprojected_rect_local()

func get_projected_board_rect_polygon(horizontal_expand: float = 0.0, vertical_expand: float = -1.0, clamp_to_board: bool = true) -> PackedVector2Array:
	return get_board_geometry().get_projected_board_rect_polygon(horizontal_expand, vertical_expand, clamp_to_board)

func project_board_point_local(point: Vector2, clamp_to_board: bool = true) -> Vector2:
	return get_board_geometry().project_point_local(point, clamp_to_board)

func get_board_projected_depth_factor(linear_depth_factor: float, clamp_to_board: bool = true) -> float:
	return get_board_geometry().get_projected_depth_factor(linear_depth_factor, clamp_to_board)

func get_board_view_color() -> int:
	if side != null && !side:
		return -1
	return 1

func get_board_cell_polygon_local(board_pos: Vector2, inset: float = 0.0, clamp_to_board: bool = true) -> PackedVector2Array:
	return get_board_geometry().get_cell_polygon_local(board_pos, inset, clamp_to_board)

func get_points_bounds_local(points: PackedVector2Array) -> Rect2:
	return get_board_geometry().get_points_bounds_local(points)

func get_mouse_board_position() -> Vector2:
	var local_pos: Vector2 = to_local(get_global_mouse_position())
	return get_board_geometry().get_mouse_board_position(local_pos, INVALID_BOARD_POS)

func update_hovered_piece():
	get_match_input_controller().update_hovered_piece()

func show_hover_piece_details(board_pos: Vector2):
	get_match_input_controller().show_hover_piece_details(board_pos)

func hide_hover_piece_details():
	get_match_input_controller().hide_hover_piece_details()

func update_hover_duration_label_position():
	get_match_input_controller().update_hover_duration_label_position()

func show_hover_piece_preview(stamp: Stamp, piece_color: int) -> void:
	get_match_input_controller().show_hover_piece_preview(stamp, piece_color)

func get_board_position_screen_position(board_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * get_board_position_local_position(board_pos)

func get_board_position_local_position(board_pos: Vector2, clamp_to_board: bool = true) -> Vector2:
	return get_board_geometry().get_position_local(board_pos, clamp_to_board)

func get_piece_holder_at(board_pos: Vector2) -> Sprite2D:
	return get_piece_visuals().get_holder_at(pieces_node, board_pos, INVALID_BOARD_POS)

func refresh_piece_holder_visual(holder: Sprite2D, board_pos: Vector2) -> void:
	get_piece_display_controller().refresh_piece_holder_visual(holder, board_pos)

func apply_piece_respawn_lock_opacity(holder: Sprite2D, board_pos: Vector2) -> void:
	get_piece_display_controller().apply_piece_respawn_lock_opacity(holder, board_pos)

func collect_bomb_warning_animations(recent_bomb_effects: Array, previous_snapshot: Dictionary) -> Array[Dictionary]:
	return get_match_state_sync_controller().collect_bomb_warning_animations(recent_bomb_effects, previous_snapshot, has_received_server_state, should_skip_visual_animations())

func play_bomb_warning_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var target_pos: Vector2 = value_to_vector2(animation.get("target_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
		play_bomb_warning_animation(target_pos)

func play_bomb_warning_animation(target_pos: Vector2) -> void:
	if !is_valid_position(target_pos):
		return
	if piece_effects_node == null or !is_instance_valid(piece_effects_node):
		create_piece_effects_node()
	if piece_effects_node == null:
		return
	get_piece_effect_animator().play_bomb_warning(target_pos)

func defer_server_state_visual_update_for_bomb_warning(bomb_warning_animations: Array[Dictionary], visual_context: Dictionary) -> void:
	get_server_state_visual_update_controller().defer_for_bomb_warning(bomb_warning_animations, visual_context)

func finish_server_state_visual_update(visual_context: Dictionary) -> void:
	await get_server_state_visual_update_controller().finish(visual_context)

func reveal_hidden_last_move_arrow_for_game_over() -> void:
	get_server_state_visual_update_controller().reveal_hidden_last_move_arrow_for_game_over()

func parse_pending_respawn_arrival_animations(recent_pending_respawn_arrivals: Array) -> Array[Dictionary]:
	return get_match_state_sync_controller().parse_pending_respawn_arrival_animations(recent_pending_respawn_arrivals)

func get_attach_animation_positions(animations: Array[Dictionary]) -> Dictionary:
	return get_server_state_visual_update_controller().get_attach_animation_positions(animations)

func finish_resolved_pending_stamp_attach_processes(excluded_positions: Dictionary = {}) -> void:
	get_server_state_visual_update_controller().finish_resolved_pending_stamp_attach_processes(excluded_positions)

func clear_resolved_pending_stamp_attach_positions() -> void:
	get_server_state_visual_update_controller().clear_resolved_pending_stamp_attach_positions()

func display_board():
	get_piece_display_controller().display_board()

func apply_selected_piece_glow(holder: Sprite2D, board_pos: Vector2) -> void:
	get_piece_display_controller().apply_selected_piece_glow(holder, board_pos)

func remove_selected_piece_glow(holder: Sprite2D) -> void:
	get_piece_display_controller().remove_selected_piece_glow(holder)

func update_selected_piece_glow() -> void:
	get_piece_display_controller().update_selected_piece_glow()

func apply_piece_exhausted_material(holder: Sprite2D, board_pos: Vector2) -> void:
	get_piece_display_controller().apply_piece_exhausted_material(holder, board_pos)

func apply_piece_freeze_overlay(holder: Sprite2D, board_pos: Vector2) -> void:
	get_piece_display_controller().apply_piece_freeze_overlay(holder, board_pos)

func refresh_piece_freeze_overlay(board_pos: Vector2) -> void:
	get_piece_display_controller().refresh_piece_freeze_overlay(board_pos)

func remove_piece_freeze_overlay(holder: Sprite2D) -> void:
	get_piece_display_controller().remove_piece_freeze_overlay(holder)

func remove_piece_freeze_square_overlay(board_pos: Vector2) -> void:
	get_piece_display_controller().remove_piece_freeze_square_overlay(board_pos)

func show_options():
	get_match_input_controller().show_options()

func show_dots(source_pos: Vector2 = INVALID_BOARD_POS):
	get_match_input_controller().show_dots(source_pos)

func delete_dots():
	get_match_input_controller().delete_dots()

func set_move(start_pos: Vector2, end_pos: Vector2) -> void:
	await get_local_move_flow_controller().set_move(start_pos, end_pos)

func finish_if_current_player_has_no_valid_turn() -> bool:
	return get_game_result_controller().finish_if_current_player_has_no_valid_turn()

func finish_game(winner_color: int):
	await get_game_result_controller().finish_game(winner_color)

func get_next_scene_after_game(winner_color: int) -> String:
	return get_game_result_controller().get_next_scene_after_game(winner_color)

func award_win_points_if_applicable(winner_color: int) -> void:
	get_game_result_controller().award_win_points_if_applicable(winner_color)

func should_award_win_points(winner_color: int) -> bool:
	return get_game_result_controller().should_award_win_points(winner_color)

func show_result_message(winner_color: int):
	get_game_result_controller().show_result_message(winner_color)

func is_valid_position(pos : Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false

func is_empty(pos : Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false

func is_piece_owned_by(pos: Vector2, owner_color: int) -> bool:
	return board[pos.x][pos.y] * owner_color > 0

func can_player_control_piece_at(pos: Vector2, player_id: int) -> bool:
	if !piece_objects.has(pos):
		return false
	var piece: Piece = piece_objects[pos] as Piece
	return StampEffectResolver.can_player_control_piece(piece, player_id)

func can_control_current_turn() -> bool:
	if game_over:
		return false
	if side == null:
		return GameConfig.is_singleplayer or tutorial_mode_active
	return side == white

func update_from_server_state(pieces_data: Dictionary, player_hands: Dictionary, current_turn: int, server_game_over: bool = false, winner_player: int = -1, player_deck_sizes: Dictionary = {}, player_codex_state: Dictionary = {}, hidden_stamps: Array = [], player_base_fields: Dictionary = {}, board_effects: Array = [], player_names: Dictionary = {}, recent_stamp_transfers: Array = [], recent_stamp_expirations: Array = [], recent_bomb_effects: Array = [], recent_pending_respawn_queues: Array = [], recent_pending_respawn_arrivals: Array = [], last_move: Dictionary = {}, player_portraits: Dictionary = {}, viewer_player_id: int = -1, turn_action_state: Dictionary = {}, player_clock_seconds: Dictionary = {}):
	get_server_state_update_controller().update_from_server_state(
		pieces_data,
		player_hands,
		current_turn,
		server_game_over,
		winner_player,
		player_deck_sizes,
		player_codex_state,
		hidden_stamps,
		player_base_fields,
		board_effects,
		player_names,
		recent_stamp_transfers,
		recent_stamp_expirations,
		recent_bomb_effects,
		recent_pending_respawn_queues,
		recent_pending_respawn_arrivals,
		last_move,
		player_portraits,
		viewer_player_id,
		turn_action_state,
		player_clock_seconds
	)

func should_skip_visual_animations() -> bool:
	return GameConfig.should_skip_ai_vs_ai_delays()

func get_board_screen_scale() -> float:
	var camera: Camera2D = $"../Camera2D"
	if camera == null:
		return absf(global_scale.x)
	return absf(camera.zoom.x) * absf(global_scale.x)

func value_to_vector2(value, fallback: Vector2) -> Vector2:
	return get_match_state_sync_controller().value_to_vector2(value, fallback)

func update_board_markers():
	get_board_marker_controller().update_markers()

func get_board_cell_rect_local(board_pos: Vector2) -> Rect2:
	return get_board_geometry().get_cell_rect_local(board_pos)
