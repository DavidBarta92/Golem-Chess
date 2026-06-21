extends Sprite2D

signal piece_selected(piece_pos: Vector2, player_id: int)
signal card_attached(piece_pos: Vector2, card_name: String, owner_color: int, hand_index: int)
signal piece_moved(from_pos: Vector2, to_pos: Vector2, owner_color: int)
signal card_exchanged(card_name: String, owner_color: int, hand_index: int)
signal turn_ended(ending_color: int, next_color: int)
signal tutorial_action_rejected(action_name: String, context: Dictionary)

const BOARD_SIZE: int = BoardConfig.BOARD_SIZE
const CELL_WIDTH: int = BoardConfig.CELL_WIDTH

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")
const CARD_VISUAL = preload("res://Scenes/CardVisual.tscn")
const BOARD_GEOMETRY_SCRIPT = preload("res://Scripts/MatchView/BoardGeometry.gd")
const BOARD_VISUAL_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/BoardVisualController.gd")
const BOARD_TILE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/BoardTileController.gd")
const BOARD_MARKER_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/BoardMarkerController.gd")
const MATCH_STATE_SYNC_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/MatchStateSyncController.gd")
const SERVER_STATE_UPDATE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/ServerStateUpdateController.gd")
const LOCAL_STATE_MUTATOR_SCRIPT = preload("res://Scripts/MatchState/LocalStateMutator.gd")
const LOCAL_MOVE_FLOW_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/LocalMoveFlowController.gd")
const TUTORIAL_MATCH_ADAPTER_SCRIPT = preload("res://Scripts/MatchState/TutorialMatchAdapter.gd")
const GAME_RESULT_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/GameResultController.gd")
const TURN_FLOW_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/TurnFlowController.gd")
const TURN_ACTION_STATE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchState/TurnActionStateController.gd")
const PIECE_VISUAL_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/PieceVisualController.gd")
const PIECE_MOVE_ANIMATOR_SCRIPT = preload("res://Scripts/MatchView/PieceMoveAnimator.gd")
const PIECE_SHATTER_ANIMATOR_SCRIPT = preload("res://Scripts/MatchView/PieceShatterAnimator.gd")
const PIECE_RESPAWN_FRAGMENT_COORDINATOR_SCRIPT = preload("res://Scripts/MatchView/PieceRespawnFragmentCoordinator.gd")
const PIECE_DISPLAY_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/PieceDisplayController.gd")
const PIECE_EFFECT_ANIMATOR_SCRIPT = preload("res://Scripts/MatchView/PieceEffectAnimator.gd")
const FREEZE_EFFECT_ANIMATOR_SCRIPT = preload("res://Scripts/MatchView/FreezeEffectAnimator.gd")
const HIDDEN_CARD_PREVIEW_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/HiddenCardPreviewController.gd")
const MATCH_CARD_HUD_SCRIPT = preload("res://Scripts/MatchView/MatchCardHud.gd")
const CARD_HOVER_PREVIEW_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/CardHoverPreviewController.gd")
const CARD_INTERACTION_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/CardInteractionController.gd")
const CARD_ANIMATION_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/CardAnimationController.gd")
const TURN_HUD_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/TurnHudController.gd")
const DECK_COUNTER_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/DeckCounterController.gd")
const MATCH_INPUT_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/MatchInputController.gd")
const MATCH_BOARD_LIFECYCLE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/MatchBoardLifecycleController.gd")
const CARD_HAND_STATE_CONTROLLER_SCRIPT = preload("res://Scripts/MatchView/CardHandStateController.gd")
const PORTRAIT_PLACEMENT_PREVIEW_PATH: NodePath = NodePath("PortraitPreviewLayer/PortraitPlacementPreview")
const RESPONSIVE_REFERENCE_VIEWPORT_SIZE = Vector2(1280.0, 720.0)
const HOVER_DESCRIPTION_CARD_BASE_TEXTURE = preload("res://Assets/stamp_base.svg")

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
const CAPTURE_FLASH_TEXTURE = preload("res://Assets/card_pattern_capture_only.svg")
const BOMB_WARNING_TEXTURE = preload("res://Assets/card_pattern_bomb.svg")

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
const HIDDEN_CARD_INVISIBILITY_SHADER = preload("res://Shaders/hidden_card_invisibility.gdshader")
const BOARD_KUWAHARA_SHADER = preload("res://Shaders/board_kuwahara.gdshader")
const PIECE_KUWAHARA_SHADER = preload("res://Shaders/piece_kuwahara.gdshader")
const MOVE_OPTION_DOT_CELL_WIDTH_RATIO: float = 0.45
const MOVE_OPTION_DOT_SHADER_SPEED: float = 0.24
const MOVE_OPTION_DOT_SHADER_GLOW_STRENGTH: float = 2.0
const MOVE_OPTION_DOT_SHADER_EDGE_SOFTNESS: float = 0.85
const MOVE_OPTION_DOT_SHADER_COLOR = Color(1.0, 0.94, 0.78, 1.0)
const HIDDEN_CARD_INVISIBILITY_RADIUS: float = 0.32
const HIDDEN_CARD_INVISIBILITY_EFFECT_CONTROL: float = 0.76
const HIDDEN_CARD_INVISIBILITY_BURN_SPEED: float = 0.0
const HIDDEN_CARD_INVISIBILITY_SHAPE: float = 0.2
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
const CARD_UI_SIZE = Vector2(164, 229)
const CARD_HAND_SCALE = 0.648
const DECK_CARD_SCALE = CARD_HAND_SCALE
const CARD_RETURN_TO_DECK_START_SCALE: float = 0.74 * 0.75
const CARD_RETURN_TO_DECK_END_SCALE: float = DECK_CARD_SCALE * 0.50
const CARD_RETURN_TO_DECK_DURATION: float = 0.62
const CARD_UI_GAP = 10
const TOP_CARD_HAND_MARGIN = -28
const BOTTOM_CARD_HAND_MARGIN = 34
const HOVER_CARD_MARGIN = 24
const HOVER_CARD_PREVIEW_SCALE: float = 0.82
const HOVER_CARD_VERTICAL_OFFSET: float = 54.0
const HOVER_CARD_ROTATION_DEGREES: float = -4.0
const HOVER_PIECE_PREVIEW_SIZE = Vector2(188, 224)
const HOVER_PIECE_PREVIEW_VERTICAL_OFFSET: float = -78.0
const HOVER_DESCRIPTION_TEXT_MARGIN = Vector2(22, 30)
const HOVER_DESCRIPTION_FRAME_EDGE_COLOR = Color(0.12, 0.085, 0.055, 0.62)
const HOVER_DESCRIPTION_FRAME_EDGE_THICKNESS: float = 2.0
const HOVER_DESCRIPTION_FRAME_EDGE_HORIZONTAL_INSET: float = 18.0
const HOVER_DESCRIPTION_FRAME_EDGE_VERTICAL_INSET: float = 19.0
const HIDDEN_CARD_MARGIN = 24
const HIDDEN_CARD_GAP = 10
const HIDDEN_CARD_SCALE = 0.70 * 0.75
const HIDDEN_CARD_PREVIEW_ALPHA: float = 0.70
const BOARD_MARKER_LINE_WIDTH = 1.8
const CARD_ATTACH_TARGET_FILL_COLOR = Color(1.0, 0.92, 0.58, 0.24)
const CARD_ATTACH_TARGET_FILL_INSET: float = 1.0
const CARD_ATTACH_TARGET_WIGGLE_RISE: float = 2.2
const CARD_ATTACH_TARGET_WIGGLE_ROTATION_DEGREES: float = 2.2
const CARD_ATTACH_TARGET_WIGGLE_STEP_DURATION: float = 0.105
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
const TURN_TIMER_LIMIT_SECONDS: int = 20
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
const RULES_INFO_PANEL_SIZE = Vector2(310, 286)
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
const CARD_BURN_SEQUENCE_GAP = 0.08
const TUTORIAL_ACTION_SELECT_PIECE = "select_piece"
const TUTORIAL_ACTION_ATTACH_CARD = "attach_card"
const TUTORIAL_ACTION_MOVE_PIECE = "move_piece"
const TUTORIAL_ACTION_EXCHANGE_CARD = "exchange_card"
const TUTORIAL_ACTION_END_TURN = "end_turn"
const RULES_INFO_TEXT: String = "Goal: attach a Nexus card to one of your pieces, then move that Nexus onto the opponent's base square.\n\nTurn flow:\n1. Play any number of cards from your hand onto your empty pieces.\n2. Move one ready piece using its attached card pattern.\n3. End your turn. Each card you played is replaced from your deck.\n\nCards:\n- Your hand holds up to 3 cards.\n- Once per turn, drag a hand card onto your deck to replace it.\n- Duration only drops when that piece moves.\n\nCaptures:\n- The first captured piece respawns locked on an empty non-base home-row square. If none is available, its fragments wait at the board edge until one opens. The next captured piece unlocks the waiting respawn instead of creating another.\n- Their attached card is removed. Nexus cards return to their owner's deck."
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
@export_range(0.0, 0.5, 0.01) var piece_move_lift_ratio: float = 0.08
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
var white_card_deck: Array[String] = []
var black_card_deck: Array[String] = []
var white_card_hand: Array[Card] = []
var black_card_hand: Array[Card] = []
var white_card_visuals: Array[CardVisual] = []
var black_card_visuals: Array[CardVisual] = []
var white_deck_visual: CardVisual
var black_deck_visual: CardVisual
var attached_card_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var moved_piece_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var exchanged_card_this_turn: Dictionary = {
	1: false,
	-1: false,
}
var played_card_hand_slots_this_turn: Dictionary = {
	1: [],
	-1: [],
}
var pending_card_attach_positions: Dictionary = {}
var active_card_attach_process_count: int = 0
var exchanged_card_names_this_turn: Dictionary = {
	1: [],
	-1: [],
}
var game_over: bool = false
var hover_card_group: Control
var hover_card_preview: CardVisual
var hover_piece_preview: TextureRect
var hover_duration_label: Label
var hover_description_panel: Control
var hover_description_label: Label
var has_received_server_state: bool = false
var quit_confirmation_dialog: ConfirmationDialog
var white_deck_count_override: int = -1
var black_deck_count_override: int = -1
var hidden_card_counts: Dictionary = {}
var board_geometry
var board_visuals
var board_tile_controller
var board_marker_controller
var match_state_sync_controller
var server_state_update_controller
var local_state_mutator
var local_move_flow_controller
var tutorial_match_adapter
var game_result_controller
var turn_flow_controller
var turn_action_state_controller
var piece_visuals
var piece_move_animator
var piece_shatter_animator
var piece_respawn_fragment_coordinator
var piece_display_controller
var piece_effect_animator
var freeze_effect_animator
var hidden_card_preview_controller
var card_hud_controller
var card_hover_preview_controller
var card_interaction_controller
var card_animation_controller
var turn_hud_controller
var deck_counter_controller
var match_input_controller
var match_board_lifecycle_controller
var card_hand_state_controller
var board_markers_node: Node2D
var board_frame_node: Node2D
var board_base_tiles_node: Node2D
var board_special_tiles_node: Node2D
var board_special_tile_nodes: Dictionary = {}
var board_special_tile_types: Dictionary = {}
var board_special_tiles_initialized: bool = false
var piece_effects_node: Node2D
var attach_point_light_texture: Texture2D
var ambient_board_light: PointLight2D
var ambient_board_fill_light: PointLight2D
var board_shader_backbuffer: BackBufferCopy
var board_shader_overlay: ColorRect
var board_shader_material: ShaderMaterial
var piece_kuwahara_material: ShaderMaterial
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
var active_piece_revert_animation_count: int = 0
var pending_piece_shatter_respawn_reveal_counts: Dictionary = {}
var pending_piece_shatter_respawn_reveal_groups: Dictionary = {}
var respawn_piece_shatter_fragment_markers: Dictionary = {}
var pending_edge_respawn_fragment_markers: Dictionary = {}
var local_pending_respawns: Dictionary = {
	1: [],
	-1: [],
}
var active_piece_move_animation_count: int = 0
var active_piece_shatter_animation_count: int = 0
var active_bomb_warning_animation_count: int = 0
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

func initialize_match_board_lifecycle_controller() -> void:
	if match_board_lifecycle_controller == null:
		match_board_lifecycle_controller = MATCH_BOARD_LIFECYCLE_CONTROLLER_SCRIPT.new()
	sync_match_board_lifecycle_controller()

func sync_match_board_lifecycle_controller() -> void:
	if match_board_lifecycle_controller == null:
		return
	match_board_lifecycle_controller.configure({
		"match_board": self,
		"board_visual_scale": BOARD_VISUAL_SCALE,
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
		"board_size": BOARD_SIZE,
		"cell_width": CELL_WIDTH,
		"perspective_enabled": BOARD_PERSPECTIVE_ENABLED,
		"perspective_top_scale": BOARD_PERSPECTIVE_TOP_SCALE,
		"perspective_bottom_scale": BOARD_PERSPECTIVE_BOTTOM_SCALE,
		"perspective_vertical_scale": BOARD_PERSPECTIVE_VERTICAL_SCALE,
		"tile_slide_distance_factor": BOARD_TILE_SLIDE_DISTANCE_FACTOR,
		"tile_sink_offset": BOARD_TILE_SINK_OFFSET,
		"view_color": get_board_view_color(),
	})

func get_board_geometry():
	initialize_board_view_helpers()
	board_geometry.set_view_color(get_board_view_color())
	return board_geometry

func get_board_visuals():
	initialize_board_view_helpers()
	return board_visuals

func initialize_board_tile_controller() -> void:
	if board_tile_controller == null:
		board_tile_controller = BOARD_TILE_CONTROLLER_SCRIPT.new()
	sync_board_tile_controller()

func sync_board_tile_controller() -> void:
	if board_tile_controller == null:
		return
	board_tile_controller.configure({
		"match_board": self,
		"visuals": get_board_visuals(),
		"geometry": get_board_geometry(),
		"board_size": BOARD_SIZE,
		"invalid_board_pos": INVALID_BOARD_POS,
		"board_tile_texture": BOARD_TILE_TEXTURE,
		"board_tile_base_white_texture": BOARD_TILE_BASE_WHITE_TEXTURE,
		"board_tile_base_black_texture": BOARD_TILE_BASE_BLACK_TEXTURE,
		"board_tile_freeze_texture": BOARD_TILE_FREEZE_TEXTURE,
		"board_tile_disabled_texture": BOARD_TILE_DISABLED_TEXTURE,
		"special_tile_none": BOARD_SPECIAL_TILE_NONE,
		"special_tile_base_white": BOARD_SPECIAL_TILE_BASE_WHITE,
		"special_tile_base_black": BOARD_SPECIAL_TILE_BASE_BLACK,
		"special_tile_freeze": BOARD_SPECIAL_TILE_FREEZE,
		"special_tile_disabled": BOARD_SPECIAL_TILE_DISABLED,
		"special_tile_z_index": BOARD_SPECIAL_TILE_Z_INDEX,
		"tile_swap_duration": BOARD_TILE_SWAP_DURATION,
		"tile_sunk_alpha": BOARD_TILE_SUNK_ALPHA,
		"tile_depth_wall_color": BOARD_TILE_DEPTH_WALL_COLOR,
		"tile_occlusion_lip_color": BOARD_TILE_OCCLUSION_LIP_COLOR,
		"tile_occlusion_lip_inset_factor": BOARD_TILE_OCCLUSION_LIP_INSET_FACTOR,
		"tile_transition_cover_z_index": BOARD_TILE_TRANSITION_COVER_Z_INDEX,
		"frame_width": BOARD_FRAME_WIDTH,
		"frame_vertical_extension": BOARD_FRAME_VERTICAL_EXTENSION,
		"frame_color": BOARD_FRAME_COLOR,
		"side_thickness": BOARD_SIDE_THICKNESS,
		"side_color": BOARD_SIDE_COLOR,
		"shadow_enabled": board_shadow_enabled,
		"shadow_color": board_shadow_color,
		"shadow_offset": board_shadow_offset,
		"shadow_spread": board_shadow_spread,
		"shadow_steps": board_shadow_steps,
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
		"dots_node": dots,
		"board_markers_node": board_markers_node,
		"texture_holder_scene": TEXTURE_HOLDER,
		"move_option_dot_texture": MOVE_OPTION_DOT_TEXTURE,
		"move_option_dot_shader": MOVE_OPTION_DOT_SHADER,
		"cell_width": CELL_WIDTH,
		"board_size": BOARD_SIZE,
		"move_option_dot_cell_width_ratio": MOVE_OPTION_DOT_CELL_WIDTH_RATIO,
		"move_option_dot_shader_speed": MOVE_OPTION_DOT_SHADER_SPEED,
		"move_option_dot_shader_glow_strength": MOVE_OPTION_DOT_SHADER_GLOW_STRENGTH,
		"move_option_dot_shader_edge_softness": MOVE_OPTION_DOT_SHADER_EDGE_SOFTNESS,
		"move_option_dot_shader_color": MOVE_OPTION_DOT_SHADER_COLOR,
		"last_move_arrow_color": LAST_MOVE_ARROW_COLOR,
		"last_move_arrow_width": LAST_MOVE_ARROW_WIDTH,
		"last_move_arrow_endpoint_inset": LAST_MOVE_ARROW_ENDPOINT_INSET,
		"last_move_arrow_head_length": LAST_MOVE_ARROW_HEAD_LENGTH,
		"last_move_arrow_head_half_width": LAST_MOVE_ARROW_HEAD_HALF_WIDTH,
		"piece_objects_provider": Callable(self, "get_piece_objects"),
		"board_effects_provider": Callable(self, "get_current_board_effects"),
		"current_last_move_provider": Callable(self, "get_current_last_move"),
		"local_view_color_provider": Callable(self, "get_local_view_color"),
		"local_view_ready_provider": Callable(self, "is_local_view_ready"),
		"own_player_id_provider": Callable(self, "get_own_player_id"),
		"can_move_action_now_provider": Callable(self, "can_move_action_now"),
		"can_player_control_piece_at_provider": Callable(self, "can_player_control_piece_at"),
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
		"board_size": BOARD_SIZE,
		"invalid_board_pos": INVALID_BOARD_POS,
		"white_base_field": WHITE_BASE_FIELD,
		"black_base_field": BLACK_BASE_FIELD,
		"fragment_group_none": PIECE_SHATTER_FRAGMENT_GROUP_NONE,
		"fragment_group_bottom": PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM,
		"fragment_group_top": PIECE_SHATTER_FRAGMENT_GROUP_TOP,
		"fragment_group_pending": PIECE_SHATTER_FRAGMENT_GROUP_PENDING,
		"default_piece_texture_provider": Callable(self, "get_default_piece_texture"),
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
		"match_board": self,
	})

func get_server_state_update_controller():
	initialize_server_state_update_controller()
	return server_state_update_controller

func initialize_local_state_mutator() -> void:
	if local_state_mutator == null:
		local_state_mutator = LOCAL_STATE_MUTATOR_SCRIPT.new()
	sync_local_state_mutator()

func sync_local_state_mutator() -> void:
	if local_state_mutator == null:
		return
	local_state_mutator.configure({
		"board": board,
		"piece_objects": piece_objects,
		"local_pending_respawns": local_pending_respawns,
		"moved_piece_this_turn": moved_piece_this_turn,
		"played_card_hand_slots_this_turn": played_card_hand_slots_this_turn,
		"player_base_fields": current_player_base_fields,
		"board_effects": current_board_effects,
		"board_size": BOARD_SIZE,
		"invalid_board_pos": INVALID_BOARD_POS,
		"fragment_group_none": PIECE_SHATTER_FRAGMENT_GROUP_NONE,
		"fragment_group_bottom": PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM,
		"fragment_group_top": PIECE_SHATTER_FRAGMENT_GROUP_TOP,
		"fragment_group_pending": PIECE_SHATTER_FRAGMENT_GROUP_PENDING,
		"player_id_for_color_provider": Callable(self, "get_player_id_for_color"),
		"card_hand_provider": Callable(self, "get_card_hand"),
		"card_deck_provider": Callable(self, "get_card_deck"),
		"current_turn_color_provider": Callable(self, "get_current_turn_color"),
		"moved_piece_this_turn_provider": Callable(get_turn_action_state_controller(), "has_moved_piece_this_turn"),
		"can_exchange_card_provider": Callable(self, "can_exchange_card_locally"),
		"create_board_tiles_callback": Callable(self, "create_board_tiles"),
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
		"match_board": self,
		"invalid_board_pos": INVALID_BOARD_POS,
		"fragment_group_none": PIECE_SHATTER_FRAGMENT_GROUP_NONE,
	})

func get_local_move_flow_controller():
	initialize_local_move_flow_controller()
	return local_move_flow_controller

func initialize_tutorial_match_adapter() -> void:
	if tutorial_match_adapter == null:
		tutorial_match_adapter = TUTORIAL_MATCH_ADAPTER_SCRIPT.new()
	sync_tutorial_match_adapter()

func sync_tutorial_match_adapter() -> void:
	if tutorial_match_adapter == null:
		return
	tutorial_match_adapter.configure({
		"match_board": self,
		"invalid_board_pos": INVALID_BOARD_POS,
		"board_size": BOARD_SIZE,
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
		"match_board": self,
		"main_menu_scene": MAIN_MENU_SCENE,
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
		"match_board": self,
		"board_size": BOARD_SIZE,
		"invalid_board_pos": INVALID_BOARD_POS,
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
		"match_board": self,
	})

func get_turn_action_state_controller():
	initialize_turn_action_state_controller()
	return turn_action_state_controller

func get_piece_objects() -> Dictionary:
	return piece_objects

func get_current_board_effects() -> Array:
	return current_board_effects

func get_current_last_move() -> Dictionary:
	return current_last_move

func get_pending_card_attach_positions() -> Dictionary:
	return pending_card_attach_positions

func initialize_piece_visual_controller() -> void:
	if piece_visuals == null:
		piece_visuals = PIECE_VISUAL_CONTROLLER_SCRIPT.new()
	sync_piece_visual_controller()

func sync_piece_visual_controller() -> void:
	if piece_visuals == null:
		return
	piece_visuals.configure({
		"geometry": get_board_geometry(),
		"board_size": BOARD_SIZE,
		"cell_width": CELL_WIDTH,
		"view_color": get_board_view_color(),
		"texture_filter": PIECE_TEXTURE_FILTER,
		"default_piece_texture": DEFAULT_PIECE_TEXTURE,
		"own_default_piece_texture": OWN_DEFAULT_PIECE_TEXTURE,
		"default_piece_visual_height": DEFAULT_PIECE_VISUAL_HEIGHT,
		"piece_auto_fit_height_threshold": PIECE_AUTO_FIT_HEIGHT_THRESHOLD,
		"default_piece_bottom_inset": DEFAULT_PIECE_BOTTOM_INSET,
		"piece_perspective_scale_variation": PIECE_PERSPECTIVE_SCALE_VARIATION,
		"piece_shadow_name": PIECE_SHADOW_NAME,
		"piece_shadow_light_texture_scale": PIECE_SHADOW_LIGHT_TEXTURE_SCALE,
		"piece_shadow_light_source_offset": PIECE_SHADOW_LIGHT_SOURCE_OFFSET,
		"piece_shadow_light_energy": PIECE_SHADOW_LIGHT_ENERGY,
		"piece_shadow_light_color": PIECE_SHADOW_LIGHT_COLOR,
		"piece_shadow_light_shadow_color": PIECE_SHADOW_LIGHT_SHADOW_COLOR,
		"piece_shadow_light_shadow_smooth": PIECE_SHADOW_LIGHT_SHADOW_SMOOTH,
		"board_light_receive_mask": BOARD_LIGHT_RECEIVE_MASK,
		"piece_light_occluder_mask": PIECE_LIGHT_OCCLUDER_MASK,
		"piece_light_receive_mask": PIECE_LIGHT_RECEIVE_MASK,
		"piece_effect_light_receive_mask": PIECE_EFFECT_LIGHT_RECEIVE_MASK,
		"piece_light_occluder_name": PIECE_LIGHT_OCCLUDER_NAME,
		"piece_light_occluder_footprint_width_factor": PIECE_LIGHT_OCCLUDER_FOOTPRINT_WIDTH_FACTOR,
		"piece_light_occluder_footprint_fixed_radius_y": PIECE_LIGHT_OCCLUDER_FOOTPRINT_FIXED_RADIUS_Y,
		"piece_light_occluder_footprint_bottom_inset_factor": PIECE_LIGHT_OCCLUDER_FOOTPRINT_BOTTOM_INSET_FACTOR,
		"piece_light_occluder_footprint_offset": PIECE_LIGHT_OCCLUDER_FOOTPRINT_OFFSET,
		"piece_light_occluder_footprint_segments": PIECE_LIGHT_OCCLUDER_FOOTPRINT_SEGMENTS,
		"piece_footprint_alpha_threshold": PIECE_FOOTPRINT_ALPHA_THRESHOLD,
		"piece_footprint_width_scan_start_ratio": PIECE_FOOTPRINT_WIDTH_SCAN_START_RATIO,
		"piece_footprint_stable_width_band_ratio": PIECE_FOOTPRINT_STABLE_WIDTH_BAND_RATIO,
		"piece_footprint_stable_row_sample_count": PIECE_FOOTPRINT_STABLE_ROW_SAMPLE_COUNT,
		"piece_light_occluder_footprint_min_radius_bounds_factor": PIECE_LIGHT_OCCLUDER_FOOTPRINT_MIN_RADIUS_BOUNDS_FACTOR,
		"attach_effect_names": [PIECE_ATTACH_GLOW_NAME, PIECE_ATTACH_TARGET_GLOW_NAME, PIECE_ATTACH_RAYS_NAME, PIECE_ATTACH_MORPH_NAME],
	})

func get_piece_visuals():
	initialize_piece_visual_controller()
	return piece_visuals

func initialize_piece_move_animator() -> void:
	if piece_move_animator == null:
		piece_move_animator = PIECE_MOVE_ANIMATOR_SCRIPT.new()
	sync_piece_move_animator()

func sync_piece_move_animator() -> void:
	if piece_move_animator == null:
		return
	piece_move_animator.configure({
		"geometry": get_board_geometry(),
		"piece_visuals": get_piece_visuals(),
		"cell_width": CELL_WIDTH,
		"board_size": BOARD_SIZE,
		"move_duration": piece_move_duration,
		"move_lift_ratio": piece_move_lift_ratio,
		"corner_rounding_ratio": PIECE_MOVE_ROUTE_CORNER_ROUNDING_RATIO,
		"corner_sample_count": PIECE_MOVE_ROUTE_CORNER_SAMPLE_COUNT,
		"pieces_node": pieces_node,
		"local_space_node": self,
		"avoid_occupied_footprints": piece_move_avoid_occupied_footprints,
		"footprint_clearance": piece_move_footprint_clearance,
		"footprint_fixed_radius_y": PIECE_LIGHT_OCCLUDER_FOOTPRINT_FIXED_RADIUS_Y,
		"route_z_front_offset": PIECE_MOVE_ROUTE_Z_FRONT_OFFSET,
		"route_z_back_offset": PIECE_MOVE_ROUTE_Z_BACK_OFFSET,
		"view_color": get_board_view_color(),
		"invalid_board_pos": INVALID_BOARD_POS,
		"piece_exists_provider": Callable(self, "has_piece_object_at"),
		"sprite_bounds_provider": Callable(self, "get_sprite_texture_bounds_local"),
	})

func get_piece_move_animator():
	initialize_piece_move_animator()
	return piece_move_animator

func has_piece_object_at(board_pos: Vector2) -> bool:
	return piece_objects.has(board_pos)

func initialize_piece_shatter_animator() -> void:
	if piece_shatter_animator == null:
		piece_shatter_animator = PIECE_SHATTER_ANIMATOR_SCRIPT.new()
	sync_piece_shatter_animator()

func sync_piece_shatter_animator() -> void:
	if piece_shatter_animator == null:
		return
	piece_shatter_animator.configure({
		"geometry": get_board_geometry(),
		"piece_visuals": get_piece_visuals(),
		"pieces_node": pieces_node,
		"piece_effects_node": piece_effects_node,
		"tween_owner": self,
		"board_size": BOARD_SIZE,
		"cell_width": CELL_WIDTH,
		"view_color": get_board_view_color(),
		"invalid_board_pos": INVALID_BOARD_POS,
		"texture_filter": PIECE_TEXTURE_FILTER,
		"piece_effect_light_receive_mask": PIECE_EFFECT_LIGHT_RECEIVE_MASK,
		"flipped_view": side != null && !side,
		"returning_debris_count": piece_shatter_returning_debris_count,
		"scatter_duration": piece_shatter_scatter_duration,
		"fade_duration": piece_shatter_fade_duration,
		"return_duration": piece_shatter_return_duration,
		"return_fade_duration": piece_shatter_return_fade_duration,
		"fragment_settle_duration": piece_shatter_fragment_settle_duration,
		"scatter_radius": piece_shatter_scatter_radius,
		"scatter_jitter": piece_shatter_scatter_jitter,
		"min_piece_scale": piece_shatter_min_piece_scale,
		"max_piece_scale": piece_shatter_max_piece_scale,
		"avoid_occupied_cells": piece_shatter_avoid_occupied_cells,
		"route_jitter_ratio": piece_shatter_route_jitter_ratio,
		"fragment_landing_hold_duration": PIECE_SHATTER_FRAGMENT_LANDING_HOLD_DURATION,
		"route_z_front_offset": PIECE_SHATTER_ROUTE_Z_FRONT_OFFSET,
		"route_z_back_offset": PIECE_SHATTER_ROUTE_Z_BACK_OFFSET,
		"route_direct_fallback_offset": PIECE_SHATTER_ROUTE_DIRECT_FALLBACK_OFFSET,
		"return_acceleration_progress": PIECE_SHATTER_RETURN_ACCELERATION_PROGRESS,
		"fragment_group_bottom": PIECE_SHATTER_FRAGMENT_GROUP_BOTTOM,
		"route_cell_blocked_provider": Callable(self, "is_piece_shatter_route_cell_blocked"),
		"finish_respawn_fragment_callback": Callable(self, "finish_piece_shatter_respawn_fragment"),
		"player_id_for_color_provider": Callable(self, "get_player_id_for_color"),
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
		"match_board": self,
		"invalid_board_pos": INVALID_BOARD_POS,
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
		"match_board": self,
		"texture_holder_scene": TEXTURE_HOLDER,
		"board_size": BOARD_SIZE,
		"piece_light_receive_mask": PIECE_LIGHT_RECEIVE_MASK,
		"selected_piece_glow_name": SELECTED_PIECE_GLOW_NAME,
		"selected_piece_glow_z_index": SELECTED_PIECE_GLOW_Z_INDEX,
		"selected_piece_glow_strength": SELECTED_PIECE_GLOW_STRENGTH,
		"invalid_board_pos": INVALID_BOARD_POS,
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
	piece_effect_animator.configure({
		"geometry": get_board_geometry(),
		"piece_visuals": get_piece_visuals(),
		"pieces_node": pieces_node,
		"piece_effects_node": piece_effects_node,
		"tween_owner": self,
		"texture_holder_scene": TEXTURE_HOLDER,
		"cell_width": CELL_WIDTH,
		"board_size": BOARD_SIZE,
		"texture_filter": PIECE_TEXTURE_FILTER,
		"board_light_receive_mask": BOARD_LIGHT_RECEIVE_MASK,
		"piece_light_receive_mask": PIECE_LIGHT_RECEIVE_MASK,
		"piece_effect_light_receive_mask": PIECE_EFFECT_LIGHT_RECEIVE_MASK,
		"piece_light_occluder_mask": PIECE_LIGHT_OCCLUDER_MASK,
		"flipped_view": side != null && !side,
		"capture_flash_texture": CAPTURE_FLASH_TEXTURE,
		"capture_flash_color": capture_flash_color,
		"capture_flash_duration": capture_flash_duration,
		"capture_flash_size_ratio": capture_flash_size_ratio,
		"capture_flash_start_scale_ratio": capture_flash_start_scale_ratio,
		"capture_flash_rotation_degrees": capture_flash_rotation_degrees,
		"default_piece_visual_height": DEFAULT_PIECE_VISUAL_HEIGHT,
		"bomb_warning_texture": BOMB_WARNING_TEXTURE,
		"bomb_warning_color": bomb_warning_color,
		"bomb_warning_duration": bomb_warning_duration,
		"bomb_warning_rise_distance": bomb_warning_rise_distance,
		"bomb_warning_size_ratio": bomb_warning_size_ratio,
		"bomb_warning_target_y_offset": bomb_warning_target_y_offset,
		"bomb_warning_z_offset": BOMB_WARNING_Z_OFFSET,
		"piece_expire_dissolve_shader": PIECE_EXPIRE_DISSOLVE_SHADER,
		"piece_expire_dissolve_duration": PIECE_EXPIRE_DISSOLVE_DURATION,
		"piece_expire_dissolve_beam_size": PIECE_EXPIRE_DISSOLVE_BEAM_SIZE,
		"piece_expire_dissolve_noise_density": PIECE_EXPIRE_DISSOLVE_NOISE_DENSITY,
		"piece_expire_dissolve_color": PIECE_EXPIRE_DISSOLVE_COLOR,
		"piece_invisibility_refract_shader": PIECE_INVISIBILITY_REFRACT_SHADER,
		"piece_invisibility_visible_hold_duration": PIECE_INVISIBILITY_VISIBLE_HOLD_DURATION,
		"piece_invisibility_refract_in_duration": PIECE_INVISIBILITY_REFRACT_IN_DURATION,
		"piece_invisibility_fade_out_duration": PIECE_INVISIBILITY_FADE_OUT_DURATION,
		"piece_invisibility_refract_distance": PIECE_INVISIBILITY_REFRACT_DISTANCE,
		"attach_point_light_name": ATTACH_POINT_LIGHT_NAME,
		"attach_piece_light_name": ATTACH_PIECE_LIGHT_NAME,
		"attach_point_light_texture_scale": ATTACH_POINT_LIGHT_TEXTURE_SCALE,
		"attach_point_light_color": ATTACH_POINT_LIGHT_COLOR,
		"attach_point_light_shadow_color": ATTACH_POINT_LIGHT_SHADOW_COLOR,
		"attach_point_light_shadow_smooth": ATTACH_POINT_LIGHT_SHADOW_SMOOTH,
		"attach_piece_light_texture_scale": ATTACH_PIECE_LIGHT_TEXTURE_SCALE,
		"attach_piece_light_color": ATTACH_PIECE_LIGHT_COLOR,
		"attach_point_light_energy": ATTACH_POINT_LIGHT_ENERGY,
		"attach_piece_light_energy": ATTACH_PIECE_LIGHT_ENERGY,
		"piece_attach_glow_name": PIECE_ATTACH_GLOW_NAME,
		"piece_attach_target_glow_name": PIECE_ATTACH_TARGET_GLOW_NAME,
		"piece_attach_rays_name": PIECE_ATTACH_RAYS_NAME,
		"piece_attach_morph_name": PIECE_ATTACH_MORPH_NAME,
		"piece_effect_occlusion_dim_name": PIECE_EFFECT_OCCLUSION_DIM_NAME,
		"piece_attach_glow_z_index": PIECE_ATTACH_GLOW_Z_INDEX,
		"piece_attach_rays_z_index": PIECE_ATTACH_RAYS_Z_INDEX,
		"piece_attach_morph_z_index": PIECE_ATTACH_MORPH_Z_INDEX,
		"piece_effect_occlusion_dim_z_index": PIECE_EFFECT_OCCLUSION_DIM_Z_INDEX,
		"piece_attach_glow_shader": PIECE_ATTACH_GLOW_SHADER,
		"piece_attach_rays_shader": PIECE_ATTACH_RAYS_SHADER,
		"piece_texture_morph_shader": PIECE_TEXTURE_MORPH_SHADER,
		"piece_attach_glow_color": PIECE_ATTACH_GLOW_COLOR,
		"occluded_piece_effect_dim_color": occluded_piece_effect_dim_color,
		"piece_attach_glow_size": PIECE_ATTACH_GLOW_SIZE,
		"piece_attach_glow_fill_strength": PIECE_ATTACH_GLOW_FILL_STRENGTH,
		"piece_attach_glow_base_strength": PIECE_ATTACH_GLOW_BASE_STRENGTH,
		"piece_attach_glow_switch_strength": PIECE_ATTACH_GLOW_SWITCH_STRENGTH,
		"piece_attach_glow_switch_duration": PIECE_ATTACH_GLOW_SWITCH_DURATION,
		"piece_attach_in_duration": PIECE_ATTACH_IN_DURATION,
		"piece_attach_pre_switch_hold_duration": PIECE_ATTACH_PRE_SWITCH_HOLD_DURATION,
		"piece_attach_morph_duration": PIECE_ATTACH_MORPH_DURATION,
		"piece_attach_target_appear_duration": PIECE_ATTACH_TARGET_APPEAR_DURATION,
		"piece_attach_post_switch_hold_duration": PIECE_ATTACH_POST_SWITCH_HOLD_DURATION,
		"piece_attach_morph_noise_strength": PIECE_ATTACH_MORPH_NOISE_STRENGTH,
		"piece_attach_morph_shine_strength": PIECE_ATTACH_MORPH_SHINE_STRENGTH,
		"piece_attach_out_duration": PIECE_ATTACH_OUT_DURATION,
		"piece_attach_rays_start_size": PIECE_ATTACH_RAYS_START_SIZE,
		"piece_attach_rays_switch_size": PIECE_ATTACH_RAYS_SWITCH_SIZE,
		"piece_attach_rays_texture_size": PIECE_ATTACH_RAYS_TEXTURE_SIZE,
		"piece_attach_rays_overlay_scale": PIECE_ATTACH_RAYS_OVERLAY_SCALE,
		"piece_attach_rays_local_offset": PIECE_ATTACH_RAYS_LOCAL_OFFSET,
		"piece_attach_rays_spread": PIECE_ATTACH_RAYS_SPREAD,
		"piece_attach_rays_cutoff": PIECE_ATTACH_RAYS_CUTOFF,
		"piece_attach_rays_speed": PIECE_ATTACH_RAYS_SPEED,
		"piece_attach_rays_ray1_density": PIECE_ATTACH_RAYS_RAY1_DENSITY,
		"piece_attach_rays_ray2_density": PIECE_ATTACH_RAYS_RAY2_DENSITY,
		"piece_attach_rays_ray2_intensity": PIECE_ATTACH_RAYS_RAY2_INTENSITY,
		"piece_attach_rays_core_intensity": PIECE_ATTACH_RAYS_CORE_INTENSITY,
		"piece_attach_rays_seed": PIECE_ATTACH_RAYS_SEED,
		"piece_attach_rays_fade_in_delay_ratio": PIECE_ATTACH_RAYS_FADE_IN_DELAY_RATIO,
		"piece_attach_rays_fade_in_duration_ratio": PIECE_ATTACH_RAYS_FADE_IN_DURATION_RATIO,
		"attach_point_light_texture_provider": Callable(self, "get_attach_point_light_texture"),
		"piece_light_global_position_provider": Callable(self, "get_piece_light_global_position_for_texture"),
		"sprite_bounds_provider": Callable(self, "get_sprite_texture_bounds_local"),
	})

func get_piece_effect_animator():
	initialize_piece_effect_animator()
	return piece_effect_animator

func initialize_freeze_effect_animator() -> void:
	if freeze_effect_animator == null:
		freeze_effect_animator = FREEZE_EFFECT_ANIMATOR_SCRIPT.new()
	sync_freeze_effect_animator()

func sync_freeze_effect_animator() -> void:
	if freeze_effect_animator == null:
		return
	var effect_animator = get_piece_effect_animator()
	freeze_effect_animator.configure({
		"tween_owner": self,
		"geometry": get_board_geometry(),
		"visuals": get_board_visuals(),
		"board_markers_node": board_markers_node,
		"freeze_shader": PIECE_FREEZE_CRACK_SHADER,
		"square_texture_provider": Callable(effect_animator, "get_attach_rays_square_texture"),
		"sync_overlay_to_holder_callback": Callable(effect_animator, "sync_sprite_overlay_to_holder"),
		"piece_holder_provider": Callable(self, "get_piece_holder_at"),
		"should_skip_visual_animations_provider": Callable(self, "should_skip_visual_animations"),
		"pending_attach_positions_provider": Callable(self, "get_pending_card_attach_positions"),
		"piece_objects_provider": Callable(self, "get_piece_objects"),
		"board_effects_provider": Callable(self, "get_current_board_effects"),
		"player_id_for_color_callback": Callable(self, "get_player_id_for_color"),
		"is_valid_position_callback": Callable(self, "is_valid_position"),
		"crack_name": PIECE_FREEZE_CRACK_NAME,
		"release_name": PIECE_FREEZE_RELEASE_NAME,
		"square_name": PIECE_FREEZE_SQUARE_NAME,
		"square_release_name": PIECE_FREEZE_SQUARE_RELEASE_NAME,
		"crack_z_index": PIECE_FREEZE_CRACK_Z_INDEX,
		"square_z_index": PIECE_FREEZE_SQUARE_Z_INDEX,
		"crack_duration": PIECE_FREEZE_CRACK_DURATION,
		"crack_release_duration": PIECE_FREEZE_CRACK_RELEASE_DURATION,
		"crack_start_width": PIECE_FREEZE_CRACK_START_WIDTH,
		"crack_end_width": PIECE_FREEZE_CRACK_END_WIDTH,
		"crack_depth": PIECE_FREEZE_CRACK_DEPTH,
		"crack_scale": PIECE_FREEZE_CRACK_SCALE,
		"crack_zebra_scale": PIECE_FREEZE_CRACK_ZEBRA_SCALE,
		"crack_zebra_amp": PIECE_FREEZE_CRACK_ZEBRA_AMP,
		"crack_profile": PIECE_FREEZE_CRACK_PROFILE,
		"crack_slope": PIECE_FREEZE_CRACK_SLOPE,
		"refraction_offset": PIECE_FREEZE_REFRACTION_OFFSET,
		"reflection_offset": PIECE_FREEZE_REFLECTION_OFFSET,
		"square_inset": PIECE_FREEZE_SQUARE_INSET,
		"square_alpha": PIECE_FREEZE_SQUARE_ALPHA,
		"piece_effect_light_receive_mask": PIECE_EFFECT_LIGHT_RECEIVE_MASK,
	})

func get_freeze_effect_animator():
	initialize_freeze_effect_animator()
	return freeze_effect_animator

func initialize_hidden_card_preview_controller() -> void:
	if hidden_card_preview_controller == null:
		hidden_card_preview_controller = HIDDEN_CARD_PREVIEW_CONTROLLER_SCRIPT.new()
	sync_hidden_card_preview_controller()

func sync_hidden_card_preview_controller() -> void:
	if hidden_card_preview_controller == null:
		return
	hidden_card_preview_controller.configure({
		"canvas_layer": canvas_layer,
		"card_visual_scene": CARD_VISUAL,
		"card_ui_size": CARD_UI_SIZE,
		"hidden_card_margin": HIDDEN_CARD_MARGIN,
		"hidden_card_gap": HIDDEN_CARD_GAP,
		"hidden_card_scale": HIDDEN_CARD_SCALE,
		"hidden_card_preview_alpha": HIDDEN_CARD_PREVIEW_ALPHA,
		"board_size": BOARD_SIZE,
		"cell_width": CELL_WIDTH,
		"hidden_card_invisibility_shader": HIDDEN_CARD_INVISIBILITY_SHADER,
		"hidden_card_invisibility_radius": HIDDEN_CARD_INVISIBILITY_RADIUS,
		"hidden_card_invisibility_effect_control": HIDDEN_CARD_INVISIBILITY_EFFECT_CONTROL,
		"hidden_card_invisibility_burn_speed": HIDDEN_CARD_INVISIBILITY_BURN_SPEED,
		"hidden_card_invisibility_shape": HIDDEN_CARD_INVISIBILITY_SHAPE,
		"board_screen_scale_provider": Callable(self, "get_board_screen_scale"),
	})

func get_hidden_card_preview_controller():
	initialize_hidden_card_preview_controller()
	return hidden_card_preview_controller

func initialize_card_hud_controller() -> void:
	if card_hud_controller == null:
		card_hud_controller = MATCH_CARD_HUD_SCRIPT.new()
	sync_card_hud_controller()

func sync_card_hud_controller() -> void:
	if card_hud_controller == null:
		return
	card_hud_controller.configure({
		"card_visual_scene": CARD_VISUAL,
		"card_ui_size": CARD_UI_SIZE,
		"player_hand_size": PLAYER_HAND_SIZE,
		"card_hand_scale": CARD_HAND_SCALE,
		"deck_card_scale": DECK_CARD_SCALE,
		"card_ui_gap": CARD_UI_GAP,
		"top_card_hand_margin": TOP_CARD_HAND_MARGIN,
		"bottom_card_hand_margin": BOTTOM_CARD_HAND_MARGIN,
	})

func get_card_hud_controller():
	initialize_card_hud_controller()
	return card_hud_controller

func initialize_card_hover_preview_controller() -> void:
	if card_hover_preview_controller == null:
		card_hover_preview_controller = CARD_HOVER_PREVIEW_CONTROLLER_SCRIPT.new()
	sync_card_hover_preview_controller()

func sync_card_hover_preview_controller() -> void:
	if card_hover_preview_controller == null:
		return
	card_hover_preview_controller.configure({
		"canvas_layer": canvas_layer,
		"card_visual_scene": CARD_VISUAL,
		"card_ui_size": CARD_UI_SIZE,
		"card_base_texture": HOVER_DESCRIPTION_CARD_BASE_TEXTURE,
		"hover_card_margin": HOVER_CARD_MARGIN,
		"hover_card_preview_scale": HOVER_CARD_PREVIEW_SCALE,
		"hover_card_vertical_offset": HOVER_CARD_VERTICAL_OFFSET,
		"hover_card_rotation_degrees": HOVER_CARD_ROTATION_DEGREES,
		"hover_piece_preview_size": HOVER_PIECE_PREVIEW_SIZE,
		"hover_piece_preview_vertical_offset": HOVER_PIECE_PREVIEW_VERTICAL_OFFSET,
		"description_text_margin": HOVER_DESCRIPTION_TEXT_MARGIN,
		"description_frame_edge_color": HOVER_DESCRIPTION_FRAME_EDGE_COLOR,
		"description_frame_edge_thickness": HOVER_DESCRIPTION_FRAME_EDGE_THICKNESS,
		"description_frame_edge_horizontal_inset": HOVER_DESCRIPTION_FRAME_EDGE_HORIZONTAL_INSET,
		"description_frame_edge_vertical_inset": HOVER_DESCRIPTION_FRAME_EDGE_VERTICAL_INSET,
	})

func get_card_hover_preview_controller():
	initialize_card_hover_preview_controller()
	return card_hover_preview_controller

func initialize_card_interaction_controller() -> void:
	if card_interaction_controller == null:
		card_interaction_controller = CARD_INTERACTION_CONTROLLER_SCRIPT.new()
	sync_card_interaction_controller()

func sync_card_interaction_controller() -> void:
	if card_interaction_controller == null:
		return
	card_interaction_controller.configure({
		"tween_owner": self,
		"geometry": get_board_geometry(),
		"visuals": get_board_visuals(),
		"board_markers_node": board_markers_node,
		"card_attach_target_fill_color": CARD_ATTACH_TARGET_FILL_COLOR,
		"card_attach_target_fill_inset": CARD_ATTACH_TARGET_FILL_INSET,
		"card_attach_target_wiggle_rise": CARD_ATTACH_TARGET_WIGGLE_RISE,
		"card_attach_target_wiggle_rotation_degrees": CARD_ATTACH_TARGET_WIGGLE_ROTATION_DEGREES,
		"card_attach_target_wiggle_step_duration": CARD_ATTACH_TARGET_WIGGLE_STEP_DURATION,
		"hide_hover_callback": Callable(self, "hide_hover_piece_details"),
		"show_hover_card_description_callback": Callable(self, "show_hover_card_description"),
		"can_control_current_turn_provider": Callable(self, "can_control_current_turn"),
		"controllable_color_provider": Callable(self, "get_controllable_color"),
		"is_mouse_out_provider": Callable(self, "is_mouse_out"),
		"mouse_board_position_provider": Callable(self, "get_mouse_board_position"),
		"is_valid_position_callback": Callable(self, "is_valid_position"),
		"is_piece_owned_by_callback": Callable(self, "is_piece_owned_by"),
		"can_attach_card_to_piece_callback": Callable(self, "can_attach_card_to_piece"),
		"can_exchange_card_locally_callback": Callable(self, "can_exchange_card_locally"),
		"is_mouse_over_deck_callback": Callable(self, "is_mouse_over_deck"),
		"attach_card_visual_to_piece_callback": Callable(self, "attach_card_visual_to_piece"),
		"card_visuals_provider": Callable(self, "get_card_visuals"),
		"card_hand_provider": Callable(self, "get_card_hand"),
		"card_home_position_provider": Callable(self, "get_card_home_position"),
		"piece_holder_provider": Callable(self, "get_piece_holder_at"),
		"card_visual_index_provider": Callable(self, "get_card_visual_index"),
		"tutorial_exchange_allowed_callback": Callable(self, "is_tutorial_exchange_card_allowed"),
		"send_card_exchange_callback": Callable(self, "send_card_exchange_action"),
		"card_deck_provider": Callable(self, "get_card_deck"),
		"remove_card_from_hand_index_callback": Callable(self, "remove_card_from_hand_index"),
		"complete_card_exchange_callback": Callable(self, "complete_card_exchange"),
	})

func get_card_interaction_controller():
	initialize_card_interaction_controller()
	return card_interaction_controller

func initialize_card_animation_controller() -> void:
	if card_animation_controller == null:
		card_animation_controller = CARD_ANIMATION_CONTROLLER_SCRIPT.new()
	sync_card_animation_controller()

func sync_card_animation_controller() -> void:
	if card_animation_controller == null:
		return
	card_animation_controller.configure({
		"canvas_layer": canvas_layer,
		"tween_owner": self,
		"card_visual_scene": CARD_VISUAL,
		"card_ui_size": CARD_UI_SIZE,
		"card_burn_sequence_gap": CARD_BURN_SEQUENCE_GAP,
		"return_to_deck_start_scale": CARD_RETURN_TO_DECK_START_SCALE,
		"return_to_deck_end_scale": CARD_RETURN_TO_DECK_END_SCALE,
		"return_to_deck_duration": CARD_RETURN_TO_DECK_DURATION,
		"color_for_player_provider": Callable(self, "get_color_for_player_id"),
		"player_id_for_color_provider": Callable(self, "get_player_id_for_color"),
		"local_view_color_provider": Callable(self, "get_local_view_color"),
		"is_valid_position_callback": Callable(self, "is_valid_position"),
		"board_screen_position_provider": Callable(self, "get_board_position_screen_position"),
		"card_draw_start_position_provider": Callable(self, "get_card_draw_start_position"),
		"card_return_to_deck_target_position_provider": Callable(self, "get_card_return_to_deck_target_position"),
		"card_hand_source_position_provider": Callable(self, "get_card_hand_source_position"),
		"deck_visual_provider": Callable(self, "get_deck_visual"),
		"viewport_size_provider": Callable(self, "get_visible_viewport_size"),
		"value_to_vector2_provider": Callable(self, "value_to_vector2"),
		"card_visuals_provider": Callable(self, "get_card_visuals"),
	})

func get_card_animation_controller():
	initialize_card_animation_controller()
	return card_animation_controller

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

func initialize_deck_counter_controller() -> void:
	if deck_counter_controller == null:
		deck_counter_controller = DECK_COUNTER_CONTROLLER_SCRIPT.new()
	sync_deck_counter_controller()

func sync_deck_counter_controller() -> void:
	if deck_counter_controller == null:
		return
	deck_counter_controller.configure({
		"canvas_layer": canvas_layer,
		"tween_owner": self,
		"deck_count_label_size": DECK_COUNT_LABEL_SIZE,
		"deck_count_label_gap": DECK_COUNT_LABEL_GAP,
		"deck_counter_background_size": DECK_COUNTER_BACKGROUND_SIZE,
		"deck_counter_digit_size": DECK_COUNTER_DIGIT_SIZE,
		"deck_counter_digit_gap": DECK_COUNTER_DIGIT_GAP,
		"deck_counter_frame_size": DECK_COUNTER_FRAME_SIZE,
		"deck_counter_content_offset": DECK_COUNTER_CONTENT_OFFSET,
		"deck_counter_size": DECK_COUNTER_SIZE,
		"deck_counter_roll_duration": DECK_COUNTER_ROLL_DURATION,
		"deck_counter_motion_blur": DECK_COUNTER_MOTION_BLUR,
		"deck_counter_offset": DECK_COUNTER_OFFSET,
		"deck_counter_z_index": DECK_COUNTER_Z_INDEX,
		"deck_counter_digits_texture": DECK_COUNTER_DIGITS_TEXTURE,
		"deck_counter_background_texture": DECK_COUNTER_BACKGROUND_TEXTURE,
		"deck_counter_frame_texture": DECK_COUNTER_FRAME_TEXTURE,
		"deck_counter_shadow_texture": DECK_COUNTER_SHADOW_TEXTURE,
		"deck_counter_digit_shader": DECK_COUNTER_DIGIT_SHADER,
		"deck_visual_provider": Callable(self, "get_deck_visual"),
		"card_deck_count_provider": Callable(self, "get_card_deck_count"),
		"game_over_provider": Callable(self, "is_game_over"),
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
		"canvas_layer": canvas_layer,
		"tween_owner": self,
		"turn_timer_limit_seconds": TURN_TIMER_LIMIT_SECONDS,
		"turn_timer_counter_key": TURN_TIMER_COUNTER_KEY,
		"turn_timer_gap": TURN_TIMER_GAP,
		"turn_timer_z_index": TURN_TIMER_Z_INDEX,
		"deck_counter_size": DECK_COUNTER_SIZE,
		"action_status_size": ACTION_STATUS_SIZE,
		"action_status_margin": ACTION_STATUS_MARGIN,
		"action_status_cell_size": ACTION_STATUS_CELL_SIZE,
		"action_status_cell_gap": ACTION_STATUS_CELL_GAP,
		"action_status_flip_duration": ACTION_STATUS_FLIP_DURATION,
		"action_status_active_color": ACTION_STATUS_ACTIVE_COLOR,
		"action_status_active_text_color": ACTION_STATUS_ACTIVE_TEXT_COLOR,
		"action_status_active_border_color": ACTION_STATUS_ACTIVE_BORDER_COLOR,
		"action_status_inactive_color": ACTION_STATUS_INACTIVE_COLOR,
		"action_status_blocked_color": ACTION_STATUS_BLOCKED_COLOR,
		"action_status_state_active": ACTION_STATUS_STATE_ACTIVE,
		"action_status_state_empty": ACTION_STATUS_STATE_EMPTY,
		"action_status_state_blocked": ACTION_STATUS_STATE_BLOCKED,
		"end_turn_indicator_padding": END_TURN_INDICATOR_PADDING,
		"end_turn_indicator_color": END_TURN_INDICATOR_COLOR,
		"end_turn_indicator_z_index": END_TURN_INDICATOR_Z_INDEX,
		"player_name_label_size": PLAYER_NAME_LABEL_SIZE,
		"player_name_label_gap": PLAYER_NAME_LABEL_GAP,
		"player_portrait_size": get_scaled_player_portrait_size(),
		"player_portrait_margin": PLAYER_PORTRAIT_MARGIN,
		"player_portrait_top_position": get_player_portrait_top_position(),
		"player_portrait_z_index": PLAYER_PORTRAIT_Z_INDEX,
		"rules_info_button_size": RULES_INFO_BUTTON_SIZE,
		"rules_info_panel_size": RULES_INFO_PANEL_SIZE,
		"rules_info_panel_margin": RULES_INFO_PANEL_MARGIN,
		"rules_info_text": RULES_INFO_TEXT,
		"current_player_names": current_player_names,
		"current_player_portraits": current_player_portraits,
		"create_digit_counter_callback": Callable(get_deck_counter_controller(), "create_digit_counter_container"),
		"set_digit_counter_value_callback": Callable(get_deck_counter_controller(), "set_deck_counter_value"),
		"end_turn_pressed_callback": Callable(self, "_on_end_turn_pressed"),
		"game_over_provider": Callable(self, "is_game_over"),
		"can_control_current_turn_provider": Callable(self, "can_control_current_turn"),
		"tutorial_end_turn_allowed_provider": Callable(self, "is_end_turn_tutorial_allowed"),
		"can_switch_action_provider": Callable(self, "can_switch_action_now"),
		"can_attach_action_provider": Callable(self, "can_attach_action_now"),
		"can_move_action_provider": Callable(self, "can_move_action_now"),
		"current_turn_color_provider": Callable(self, "get_current_turn_color"),
		"player_id_for_color_provider": Callable(self, "get_player_id_for_color"),
		"turn_timer_timeout_callback": Callable(self, "defer_turn_timer_timeout"),
		"deck_visual_provider": Callable(self, "get_deck_visual"),
		"local_view_color_provider": Callable(self, "get_local_view_color"),
		"own_color_provider": Callable(self, "get_own_color"),
		"visible_viewport_size_provider": Callable(self, "get_visible_viewport_size"),
		"board_screen_size_provider": Callable(self, "get_board_screen_size"),
		"game_result_context_provider": Callable(self, "get_game_result_context"),
	})

func get_turn_hud_controller():
	initialize_turn_hud_controller()
	return turn_hud_controller

func get_player_portrait_top_position() -> Vector2:
	var preview := get_node_or_null(PORTRAIT_PLACEMENT_PREVIEW_PATH) as Control
	if preview != null:
		return scale_canvas_point_from_reference(preview.position)
	return scale_canvas_point_from_reference(PLAYER_PORTRAIT_TOP_POSITION)

func get_scaled_player_portrait_size() -> Vector2:
	var preview := get_node_or_null(PORTRAIT_PLACEMENT_PREVIEW_PATH) as Control
	if preview != null and preview.size.x > 0.0 and preview.size.y > 0.0:
		return scale_canvas_size_from_reference(preview.size)
	return scale_canvas_size_from_reference(PLAYER_PORTRAIT_SIZE)

func update_portrait_placement_preview_mask() -> void:
	var preview := get_node_or_null(PORTRAIT_PLACEMENT_PREVIEW_PATH) as PortraitView
	if preview != null:
		preview.use_scene_mask = true

func hide_portrait_placement_preview() -> void:
	update_portrait_placement_preview_mask()
	var preview_layer := get_node_or_null("PortraitPreviewLayer") as CanvasLayer
	if preview_layer != null:
		preview_layer.visible = false

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

func initialize_match_input_controller() -> void:
	if match_input_controller == null:
		match_input_controller = MATCH_INPUT_CONTROLLER_SCRIPT.new()
	sync_match_input_controller()

func sync_match_input_controller() -> void:
	if match_input_controller == null:
		return
	match_input_controller.configure({
		"match_board": self,
		"invalid_board_pos": INVALID_BOARD_POS,
		"main_menu_scene": MAIN_MENU_SCENE,
	})

func get_match_input_controller():
	initialize_match_input_controller()
	return match_input_controller

func initialize_card_hand_state_controller() -> void:
	if card_hand_state_controller == null:
		card_hand_state_controller = CARD_HAND_STATE_CONTROLLER_SCRIPT.new()
	sync_card_hand_state_controller()

func sync_card_hand_state_controller() -> void:
	if card_hand_state_controller == null:
		return
	card_hand_state_controller.configure({
		"match_board": self,
		"card_visual_scene": CARD_VISUAL,
		"card_ui_size": CARD_UI_SIZE,
		"card_hand_scale": CARD_HAND_SCALE,
	})

func get_card_hand_state_controller():
	initialize_card_hand_state_controller()
	return card_hand_state_controller

func is_game_over() -> bool:
	return game_over

func is_end_turn_tutorial_allowed() -> bool:
	return is_tutorial_action_allowed(TUTORIAL_ACTION_END_TURN)

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

func set_tutorial_attached_cards(attached_cards: Array) -> void:
	get_tutorial_match_adapter().set_attached_cards(attached_cards)

func reset_tutorial_turn_state() -> void:
	get_tutorial_match_adapter().reset_turn_state()

func set_tutorial_card_hand(owner_color: int, card_names: Array) -> void:
	get_tutorial_match_adapter().set_card_hand(owner_color, card_names)

func set_tutorial_card_deck(owner_color: int, card_names: Array) -> void:
	get_tutorial_match_adapter().set_card_deck(owner_color, card_names)

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

func create_ambient_board_light() -> void:
	if ambient_board_light != null and is_instance_valid(ambient_board_light) and ambient_board_fill_light != null and is_instance_valid(ambient_board_fill_light):
		return

	if ambient_board_fill_light == null or !is_instance_valid(ambient_board_fill_light):
		ambient_board_fill_light = PointLight2D.new()
		ambient_board_fill_light.name = AMBIENT_BOARD_FILL_LIGHT_NAME
		ambient_board_fill_light.texture = get_attach_point_light_texture()
		ambient_board_fill_light.texture_scale = AMBIENT_BOARD_FILL_LIGHT_TEXTURE_SCALE
		ambient_board_fill_light.color = AMBIENT_BOARD_LIGHT_COLOR
		ambient_board_fill_light.energy = AMBIENT_BOARD_FILL_LIGHT_ENERGY
		ambient_board_fill_light.range_item_cull_mask = BOARD_LIGHT_RECEIVE_MASK
		ambient_board_fill_light.shadow_enabled = false
		ambient_board_fill_light.position = AMBIENT_BOARD_LIGHT_OFFSET
		add_child(ambient_board_fill_light)

	if ambient_board_light == null or !is_instance_valid(ambient_board_light):
		ambient_board_light = PointLight2D.new()
		ambient_board_light.name = AMBIENT_BOARD_LIGHT_NAME
		ambient_board_light.texture = get_attach_point_light_texture()
		ambient_board_light.texture_scale = AMBIENT_BOARD_LIGHT_TEXTURE_SCALE
		ambient_board_light.color = AMBIENT_BOARD_LIGHT_COLOR
		ambient_board_light.energy = AMBIENT_BOARD_LIGHT_ENERGY
		ambient_board_light.range_item_cull_mask = BOARD_LIGHT_RECEIVE_MASK
		ambient_board_light.shadow_enabled = false
		ambient_board_light.shadow_color = AMBIENT_BOARD_LIGHT_SHADOW_COLOR
		ambient_board_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		ambient_board_light.shadow_filter_smooth = AMBIENT_BOARD_LIGHT_SHADOW_SMOOTH
		ambient_board_light.shadow_item_cull_mask = PIECE_LIGHT_OCCLUDER_MASK
		ambient_board_light.position = AMBIENT_BOARD_LIGHT_OFFSET
		add_child(ambient_board_light)

func create_board_shader_overlay() -> void:
	if !board_shader_enabled:
		remove_board_shader_overlay()
		return

	if board_shader_material == null:
		board_shader_material = ShaderMaterial.new()
		board_shader_material.shader = BOARD_KUWAHARA_SHADER
	update_board_shader_material()

	if board_shader_backbuffer == null or !is_instance_valid(board_shader_backbuffer):
		board_shader_backbuffer = BackBufferCopy.new()
		board_shader_backbuffer.name = "BoardShaderBackBuffer"
		board_shader_backbuffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		board_shader_backbuffer.z_as_relative = false
		board_shader_backbuffer.z_index = BOARD_SHADER_OVERLAY_Z_INDEX - 1
		add_child(board_shader_backbuffer)

	if board_shader_overlay == null or !is_instance_valid(board_shader_overlay):
		board_shader_overlay = ColorRect.new()
		board_shader_overlay.name = "BoardShaderOverlay"
		board_shader_overlay.color = Color.WHITE
		board_shader_overlay.material = board_shader_material
		board_shader_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board_shader_overlay.z_as_relative = false
		board_shader_overlay.z_index = BOARD_SHADER_OVERLAY_Z_INDEX
		board_shader_overlay.light_mask = 0
		add_child(board_shader_overlay)

	update_board_shader_overlay_rect()

func remove_board_shader_overlay() -> void:
	if board_shader_overlay != null and is_instance_valid(board_shader_overlay):
		board_shader_overlay.queue_free()
	if board_shader_backbuffer != null and is_instance_valid(board_shader_backbuffer):
		board_shader_backbuffer.queue_free()
	board_shader_overlay = null
	board_shader_backbuffer = null

func update_board_shader_material() -> void:
	if board_shader_material == null:
		return
	board_shader_material.set_shader_parameter("radius", BOARD_SHADER_RADIUS)
	board_shader_material.set_shader_parameter("offset", board_shader_offset)

func update_board_shader_overlay_rect() -> void:
	if board_shader_overlay == null or !is_instance_valid(board_shader_overlay):
		return

	var overlay_rect: Rect2 = get_board_shader_overlay_rect()
	board_shader_overlay.position = overlay_rect.position
	board_shader_overlay.size = overlay_rect.size

func get_board_shader_overlay_rect() -> Rect2:
	var board_polygon: PackedVector2Array = get_projected_board_rect_polygon(
		BOARD_FRAME_WIDTH,
		BOARD_FRAME_VERTICAL_EXTENSION,
		false
	)
	if board_polygon.size() == 0:
		return BoardConfig.get_board_rect_local().grow(board_shader_margin)

	return get_board_geometry().get_points_bounds_local(board_polygon).grow(board_shader_margin)

func get_piece_kuwahara_material() -> ShaderMaterial:
	if !piece_kuwahara_enabled:
		return null
	if piece_kuwahara_material == null:
		piece_kuwahara_material = ShaderMaterial.new()
		piece_kuwahara_material.shader = PIECE_KUWAHARA_SHADER
	piece_kuwahara_material.set_shader_parameter("radius", PIECE_KUWAHARA_RADIUS)
	piece_kuwahara_material.set_shader_parameter("offset", piece_kuwahara_offset)
	return piece_kuwahara_material

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

	DebugLog.info("Pieces initialized without starting cards.")

func setup_player_card_hands():
	get_card_hand_state_controller().setup_player_card_hands()

func create_card_hand_from_names(card_names: Array) -> Array[Card]:
	return get_card_hand_state_controller().create_card_hand_from_names(card_names)

func populate_card_hand(hand_node: Control, cards: Array[Card], owner_color: int) -> Array[CardVisual]:
	return get_card_hand_state_controller().populate_card_hand(hand_node, cards, owner_color)

func setup_deck_visuals():
	get_card_hand_state_controller().setup_deck_visuals()

func create_hover_piece_ui():
	var hover_controller = get_card_hover_preview_controller()
	hover_controller.create_ui()
	hover_card_group = hover_controller.hover_card_group
	hover_card_preview = hover_controller.hover_card_preview
	hover_piece_preview = hover_controller.hover_piece_preview
	hover_duration_label = hover_controller.hover_duration_label
	hover_description_panel = hover_controller.hover_description_panel
	hover_description_label = hover_controller.hover_description_label

func create_quit_confirmation_ui():
	quit_confirmation_dialog = ConfirmationDialog.new()
	canvas_layer.add_child(quit_confirmation_dialog)
	quit_confirmation_dialog.title = "Leave Game"
	quit_confirmation_dialog.dialog_text = "Do you really want to leave the game?"
	quit_confirmation_dialog.ok_button_text = "Yes"
	quit_confirmation_dialog.cancel_button_text = "No"
	quit_confirmation_dialog.exclusive = true
	quit_confirmation_dialog.confirmed.connect(_on_quit_confirmed)

func get_card_home_position(index: int) -> Vector2:
	return get_card_hand_state_controller().get_card_home_position(index)

func get_card_hand(owner_color: int) -> Array[Card]:
	return get_card_hand_state_controller().get_card_hand(owner_color)

func get_card_visuals(owner_color: int) -> Array[CardVisual]:
	return get_card_hand_state_controller().get_card_visuals(owner_color)

func get_card_deck(owner_color: int) -> Array[String]:
	return get_card_hand_state_controller().get_card_deck(owner_color)

func get_card_deck_count(owner_color: int) -> int:
	return get_card_hand_state_controller().get_card_deck_count(owner_color)

func get_card_hand_node(owner_color: int) -> Control:
	return get_card_hand_state_controller().get_card_hand_node(owner_color)

func get_deck_visual(owner_color: int) -> CardVisual:
	return get_card_hand_state_controller().get_deck_visual(owner_color)

func get_card_draw_start_position(owner_color: int) -> Vector2:
	return get_card_hand_state_controller().get_card_draw_start_position(owner_color)

func get_card_return_to_deck_target_position(owner_color: int, target_scale: float) -> Vector2:
	return get_card_hand_state_controller().get_card_return_to_deck_target_position(owner_color, target_scale)

func update_card_presentation():
	get_card_hand_state_controller().update_card_presentation()

func update_card_drag_permissions():
	get_card_hand_state_controller().update_card_drag_permissions()

func update_end_turn_button():
	get_turn_hud_controller().update_end_turn_button()

func begin_card_attach_process(piece_position: Vector2) -> void:
	if !pending_card_attach_positions.has(piece_position):
		active_card_attach_process_count += 1
	pending_card_attach_positions[piece_position] = true

func finish_card_attach_process(piece_position: Vector2) -> void:
	var had_pending_attach: bool = pending_card_attach_positions.has(piece_position)
	if pending_card_attach_positions.has(piece_position):
		pending_card_attach_positions.erase(piece_position)
		active_card_attach_process_count = maxi(0, active_card_attach_process_count - 1)
	if had_pending_attach:
		refresh_piece_freeze_overlay(piece_position)
	update_card_drag_permissions()
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

func handle_expired_nexus_card_locally(owner_color: int, expired_card: Card, piece_pos: Vector2) -> void:
	get_card_animation_controller().queue_nexus_card_return_to_deck_animation(owner_color, expired_card, piece_pos)
	DeckManager.return_card_to_deck(get_card_deck(owner_color), expired_card.card_name)

func update_card_face_visibility(local_color: int):
	for card_visual in white_card_visuals:
		card_visual.set_face_down(card_visual.owner_color != local_color)
	for card_visual in black_card_visuals:
		card_visual.set_face_down(card_visual.owner_color != local_color)

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

func show_hover_card_description(card: Card) -> void:
	if card == null:
		return

	hide_hover_piece_details()
	var description: String = card.description.strip_edges()
	if description.is_empty():
		return

	get_card_hover_preview_controller().show_description(description)

func can_exchange_card_locally(owner_color: int) -> bool:
	if !can_control_current_turn():
		return false
	if owner_color != get_controllable_color():
		return false
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_EXCHANGE_CARD, {
		"owner_color": owner_color,
	}):
		return false
	if get_turn_action_state_controller().has_exchanged_card_this_turn(owner_color):
		return false
	if get_card_hand(owner_color).is_empty():
		return false
	return get_card_deck_count(owner_color) > 0

func is_tutorial_exchange_card_allowed(owner_color: int, card_name: String, hand_index: int, emit_rejection: bool) -> bool:
	return is_tutorial_action_allowed(TUTORIAL_ACTION_EXCHANGE_CARD, {
		"owner_color": owner_color,
		"card_name": card_name,
		"hand_index": hand_index,
	}, emit_rejection)

func complete_card_exchange(owner_color: int, card_name: String, hand_index: int, should_record_name: bool, source_global_position = null) -> void:
	if should_record_name:
		get_card_hand_state_controller().record_exchanged_card_name_this_turn(owner_color, card_name)
		var return_animation: Dictionary = {
			"source_player_id": get_player_id_for_color(owner_color),
			"target_player_id": get_player_id_for_color(owner_color),
			"card_name": card_name,
			"source_zone": "hand",
			"target_zone": "deck",
		}
		if source_global_position is Vector2:
			return_animation["source_global_position"] = source_global_position
		get_card_animation_controller().queue_card_return_to_deck_animation(return_animation)
	get_turn_action_state_controller().mark_card_exchanged_this_turn(owner_color)
	card_exchanged.emit(card_name, owner_color, hand_index)

func send_card_exchange_action(owner_color: int, card_name: String, hand_index: int) -> bool:
	return bool(GameController.send_action({
		"type": "exchange_card",
		"player_id": get_player_id_for_color(owner_color),
		"card_name": card_name,
		"hand_index": hand_index,
	}))

func attach_card_visual_to_piece(card_visual: CardVisual, piece_position: Vector2) -> void:
	if card_visual == null or !is_instance_valid(card_visual):
		return
	if not piece_objects.has(piece_position) or card_visual.card == null:
		card_visual.fly_home()
		return
	var attach_card: Card = card_visual.card
	var card_name: String = attach_card.card_name
	var owner_color: int = card_visual.owner_color
	var hand_index: int = get_card_visual_index(card_visual)
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_ATTACH_CARD, {
		"owner_color": owner_color,
		"piece_pos": piece_position,
		"card_name": card_name,
		"hand_index": hand_index,
	}, true):
		card_visual.fly_home()
		return
	if !can_attach_card_to_piece(piece_position, card_name, owner_color):
		card_visual.fly_home()
		return

	var start_texture: Texture2D = null
	var holder: Sprite2D = get_piece_holder_at(piece_position)
	if holder != null and is_instance_valid(holder):
		start_texture = holder.texture

	begin_card_attach_process(piece_position)

	if GameController.current_game_host:
		get_local_state_mutator().record_played_card_hand_slot(owner_color, hand_index)
		card_visual.assign_and_hide()
		if !send_card_attach_action(owner_color, card_name, piece_position, hand_index):
			finish_card_attach_process(piece_position)
			return
		get_turn_action_state_controller().mark_card_attached_this_turn(owner_color)
		card_attached.emit(piece_position, card_name, owner_color, hand_index)
		return

	if !apply_card_to_piece(piece_position, card_name):
		finish_card_attach_process(piece_position)
		if is_instance_valid(card_visual):
			card_visual.fly_home()
		return

	get_local_state_mutator().record_played_card_hand_slot(owner_color, hand_index)
	if is_instance_valid(card_visual):
		remove_card_from_hand(card_visual)
	else:
		get_card_hand_state_controller().remove_card_from_hand_index(owner_color, hand_index, false)
	get_turn_action_state_controller().mark_card_attached_this_turn(owner_color)
	card_attached.emit(piece_position, card_name, owner_color, hand_index)

	if get_parent().has_method("send_card_attach"):
		get_parent().send_card_attach(piece_position, card_name, owner_color, hand_index, "")

	await play_piece_card_attach_animation(piece_position, attach_card, start_texture)
	finish_card_attach_process(piece_position)

func send_card_attach_action(owner_color: int, card_name: String, piece_position: Vector2, hand_index: int) -> bool:
	var action: Dictionary = {
		"type": "attach_card",
		"player_id": get_player_id_for_color(owner_color),
		"card_name": card_name,
		"piece_pos": piece_position,
		"hand_index": hand_index,
	}
	return bool(GameController.send_action(action))

func can_attach_card_to_piece(piece_position: Vector2, card_name: String = "", owner_color: int = 0) -> bool:
	if not piece_objects.has(piece_position):
		return false
	if pending_card_attach_positions.has(piece_position):
		return false
	var action_owner_color: int = owner_color if owner_color != 0 else get_controllable_color()
	if !is_tutorial_action_allowed(TUTORIAL_ACTION_ATTACH_CARD, {
		"owner_color": action_owner_color,
		"piece_pos": piece_position,
		"card_name": card_name,
	}):
		return false

	var piece: Piece = piece_objects[piece_position] as Piece
	return piece.can_receive_card()

func apply_card_to_piece(piece_position: Vector2, card_name: String) -> bool:
	if not piece_objects.has(piece_position):
		return false

	var piece: Piece = piece_objects[piece_position] as Piece
	if !piece.can_receive_card():
		push_warning("This piece cannot receive a card right now: %s" % piece_position)
		return false

	var card: Card = CardLibrary.duplicate_card(card_name)
	if card == null:
		push_warning("Card not found for attach: %s" % card_name)
		return false

	piece.attach_card(card)
	var pending_respawn_arrivals: Array[Dictionary] = []
	if !GameController.current_game_host:
		pending_respawn_arrivals = get_local_state_mutator().apply_card_effect_trigger(CardEffect.TRIGGER_ON_ATTACH, piece_position, piece, card)
	prepare_pending_edge_respawn_arrival_reveals(pending_respawn_arrivals)
	display_board()
	if !pending_respawn_arrivals.is_empty():
		play_pending_edge_respawn_arrival_animations(pending_respawn_arrivals)
	return true

func apply_remote_card_attach(piece_position: Vector2, card_name: String, owner_color: int, hand_index: int, _replacement_card_name: String = ""):
	if apply_card_to_piece(piece_position, card_name):
		get_card_hand_state_controller().remove_card_from_hand_index(owner_color, hand_index, false, _replacement_card_name)

func remove_card_from_hand(card_visual: CardVisual) -> String:
	return get_card_hand_state_controller().remove_card_from_hand(card_visual)

func remove_card_from_hand_index(owner_color: int, hand_index: int, should_draw_replacement: bool = false, replacement_card_name: String = "") -> String:
	return get_card_hand_state_controller().remove_card_from_hand_index(owner_color, hand_index, should_draw_replacement, replacement_card_name)

func get_card_visual_index(card_visual: CardVisual) -> int:
	return get_card_hand_state_controller().get_card_visual_index(card_visual)

func insert_drawn_card(owner_color: int, hand_index: int, card_name: String):
	get_card_hand_state_controller().insert_drawn_card(owner_color, hand_index, card_name)

func get_card_names_from_hand(cards: Array[Card]) -> Array[String]:
	return get_match_state_sync_controller().get_card_names_from_hand(cards)

func get_state_card_expiration_events(previous_snapshot: Dictionary, recent_card_expirations: Array) -> Array[Dictionary]:
	return get_match_state_sync_controller().get_state_card_expiration_events(previous_snapshot, recent_card_expirations, piece_objects)

func get_previous_state_texture(previous_state: Dictionary, piece_color: int) -> Texture2D:
	var texture_value: Texture2D = previous_state.get("texture", null) as Texture2D
	if texture_value != null:
		return texture_value
	return get_default_piece_texture(piece_color)

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

	active_piece_revert_animation_count += 1
	await get_piece_effect_animator().play_piece_revert(piece_position, start_texture)
	active_piece_revert_animation_count = maxi(0, active_piece_revert_animation_count - 1)

func get_card_hand_source_position(owner_color: int) -> Vector2:
	var visuals: Array[CardVisual] = get_card_visuals(owner_color)
	for card_visual: CardVisual in visuals:
		if card_visual != null and is_instance_valid(card_visual) and card_visual.visible:
			return card_visual.global_position

	var hand_node: Control = get_card_hand_node(owner_color)
	if hand_node == null:
		return get_viewport().get_visible_rect().size * 0.5

	return hand_node.global_position + get_card_home_position(maxi(0, visuals.size() - 1))

func arrange_card_visuals(visuals: Array[CardVisual], animate: bool):
	get_card_interaction_controller().arrange_card_visuals(visuals, animate)

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
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

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

func show_hover_piece_preview(card: Card, piece_color: int) -> void:
	get_match_input_controller().show_hover_piece_preview(card, piece_color)

func get_board_position_screen_position(board_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * get_board_position_local_position(board_pos)

func get_board_position_local_position(board_pos: Vector2, clamp_to_board: bool = true) -> Vector2:
	return get_board_geometry().get_position_local(board_pos, clamp_to_board)

func get_default_piece_texture(piece_value: int) -> Texture2D:
	if piece_value == 0:
		return null
	if piece_value * get_own_color() > 0:
		return OWN_DEFAULT_PIECE_TEXTURE
	return DEFAULT_PIECE_TEXTURE

func is_default_piece_texture(texture_value: Texture2D) -> bool:
	return get_piece_visuals().is_default_piece_texture(texture_value)

func should_fit_piece_texture_to_default_height(texture_value: Texture2D) -> bool:
	return get_piece_visuals().should_fit_piece_texture_to_default_height(texture_value)

func get_piece_visual_transform_for_texture(texture_value: Texture2D, board_pos: Vector2) -> Dictionary:
	return get_piece_visuals().get_visual_transform_for_texture(texture_value, board_pos)

func get_piece_light_global_position_for_texture(holder: Sprite2D, texture_value: Texture2D) -> Vector2:
	if holder == null or !is_instance_valid(holder):
		return Vector2.ZERO

	var board_pos: Vector2 = value_to_vector2(holder.get_meta("board_pos", INVALID_BOARD_POS), INVALID_BOARD_POS)
	if !is_valid_position(board_pos):
		return holder.to_global(holder.offset)

	var visual_transform: Dictionary = get_piece_visual_transform_for_texture(texture_value, board_pos)
	var visual_scale: Vector2 = visual_transform.get("scale", holder.scale)
	var visual_offset: Vector2 = visual_transform.get("offset", holder.offset)
	var scaled_offset := Vector2(visual_offset.x * visual_scale.x, visual_offset.y * visual_scale.y)
	var parent_node := holder.get_parent()
	if parent_node is Node2D:
		var parent_2d := parent_node as Node2D
		return parent_2d.to_global(holder.position + scaled_offset.rotated(holder.rotation))

	return holder.to_global(visual_offset)

func apply_piece_visual_size(holder: Sprite2D, board_pos: Vector2) -> void:
	get_piece_visuals().apply_visual_size(holder, board_pos)

func apply_piece_texture_filter(holder: Sprite2D) -> void:
	get_piece_visuals().apply_texture_filter(holder)

func get_piece_perspective_scale(board_pos: Vector2) -> float:
	return get_piece_visuals().get_perspective_scale(board_pos)

func get_piece_depth_z_index(board_pos: Vector2) -> int:
	return get_piece_visuals().get_depth_z_index(board_pos)

func apply_piece_shadow(holder: Sprite2D, board_pos: Vector2) -> void:
	var piece_color: int = 0
	if piece_objects.has(board_pos):
		var piece: Piece = piece_objects[board_pos] as Piece
		if piece != null:
			piece_color = piece.color
	get_piece_visuals().apply_shadow(holder, board_pos, piece_color, get_own_color(), get_attach_point_light_texture())

func remove_piece_shadow(holder: Sprite2D) -> void:
	get_piece_visuals().remove_shadow(holder)

func apply_piece_light_occluder(holder: Sprite2D, board_pos: Vector2) -> void:
	get_piece_visuals().apply_light_occluder(holder, piece_objects.has(board_pos))

func remove_piece_light_occluder(holder: Sprite2D) -> void:
	get_piece_visuals().remove_light_occluder(holder)

func get_piece_footprint_geometry(holder: Sprite2D) -> Dictionary:
	return get_piece_visuals().get_footprint_geometry(holder)

func get_piece_footprint_fixed_radius_y(holder: Sprite2D) -> float:
	return get_piece_visuals().get_footprint_fixed_radius_y(holder)

func get_fallback_piece_footprint_geometry(holder: Sprite2D, texture_size: Vector2) -> Dictionary:
	return get_piece_visuals().get_fallback_footprint_geometry(holder, texture_size)

func get_piece_footprint_metrics(texture_value: Texture2D) -> Dictionary:
	return get_piece_visuals().get_footprint_metrics(texture_value)

func get_piece_footprint_metrics_cache_key(texture_value: Texture2D) -> String:
	return get_piece_visuals().get_footprint_metrics_cache_key(texture_value)

func measure_piece_footprint_metrics(texture_value: Texture2D) -> Dictionary:
	return get_piece_visuals().measure_footprint_metrics(texture_value)

func set_piece_light_occluder_enabled(holder: Sprite2D, is_enabled: bool) -> void:
	get_piece_visuals().set_light_occluder_enabled(holder, is_enabled)

func get_attached_card_piece_texture(piece: Piece) -> Texture2D:
	if piece == null or piece.attached_card == null:
		return null
	return piece.attached_card.get_piece_texture(piece.color, get_piece_board_view(piece.color))

func get_piece_texture_for_position(board_pos: Vector2, piece_value: int) -> Texture2D:
	var attached_texture: Texture2D = null
	if piece_objects.has(board_pos):
		var piece: Piece = piece_objects[board_pos] as Piece
		if piece != null and piece.hidden_from_viewer:
			return null
		attached_texture = get_attached_card_piece_texture(piece)
	if attached_texture != null:
		return attached_texture
	return get_default_piece_texture(piece_value)

func get_card_piece_texture_for_color(card: Card, piece_color: int) -> Texture2D:
	if card == null:
		return null
	return card.get_piece_texture(piece_color, get_piece_board_view(piece_color))

func get_card_piece_preview_texture(card: Card, piece_color: int) -> Texture2D:
	if card == null:
		return null
	return card.get_piece_preview_texture(piece_color)

func get_piece_board_view(piece_color: int) -> String:
	if piece_color * get_own_color() > 0:
		return PieceVisualSet.VIEW_BACK
	return PieceVisualSet.VIEW_FRONT

func get_piece_visual_texture(piece: Piece) -> Texture2D:
	if piece == null:
		return null
	if piece.hidden_from_viewer:
		return null

	var attached_texture: Texture2D = get_attached_card_piece_texture(piece)
	if attached_texture != null:
		return attached_texture
	return get_default_piece_texture(piece.color)

func get_piece_visual_state_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for position_value in piece_objects:
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		var piece: Piece = piece_objects[position_value] as Piece
		if piece == null or piece.hidden_from_viewer:
			continue

		snapshot[board_pos] = {
			"color": piece.color,
			"card_name": piece.attached_card.card_name if piece.attached_card != null else "",
			"texture": get_piece_visual_texture(piece),
			"respawn_cooldown_turns": piece.respawn_cooldown_turns,
		}

	return snapshot

func play_state_attach_animations(animations: Array[Dictionary]) -> void:
	for animation: Dictionary in animations:
		var board_pos: Vector2 = value_to_vector2(animation.get("position", INVALID_BOARD_POS), INVALID_BOARD_POS)
		var card: Card = animation.get("card", null) as Card
		var start_texture: Texture2D = animation.get("start_texture", null) as Texture2D
		var hide_after_attach: bool = bool(animation.get("hide_after_attach", false))
		if !is_valid_position(board_pos) or card == null:
			finish_card_attach_process(board_pos)
			continue

		if hide_after_attach:
			var piece_color: int = int(animation.get("piece_color", 0))
			if piece_color == 0:
				piece_color = get_color_for_player_id(1 - get_own_player_id())
			await play_hidden_piece_invisibility_attach_animation(board_pos, card, start_texture, piece_color)
		else:
			await play_piece_card_attach_animation(board_pos, card, start_texture)
		finish_card_attach_process(board_pos)

func get_piece_holder_at(board_pos: Vector2) -> Sprite2D:
	return get_piece_visuals().get_holder_at(pieces_node, board_pos, INVALID_BOARD_POS)

func refresh_piece_holder_visual(holder: Sprite2D, board_pos: Vector2) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	get_piece_visuals().apply_holder_base_visual(holder, board_pos)
	apply_piece_respawn_lock_opacity(holder, board_pos)
	if should_hide_piece_for_shatter_respawn(board_pos):
		apply_piece_exhausted_material(holder, board_pos)
		remove_piece_light_occluder(holder)
		remove_piece_shadow(holder)
		remove_piece_freeze_overlay(holder)
		remove_piece_freeze_square_overlay(board_pos)
		remove_selected_piece_glow(holder)
		return
	apply_piece_light_occluder(holder, board_pos)
	apply_piece_shadow(holder, board_pos)
	apply_piece_exhausted_material(holder, board_pos)
	apply_piece_freeze_overlay(holder, board_pos)
	apply_selected_piece_glow(holder, board_pos)

func apply_piece_respawn_lock_opacity(holder: Sprite2D, board_pos: Vector2) -> void:
	var is_respawn_locked: bool = false
	if piece_objects.has(board_pos):
		var piece: Piece = piece_objects[board_pos] as Piece
		is_respawn_locked = piece != null and piece.is_respawn_locked()
	get_piece_visuals().apply_respawn_lock_opacity(holder, should_hide_piece_for_shatter_respawn(board_pos), is_respawn_locked)

func get_attach_point_light_texture() -> Texture2D:
	if attach_point_light_texture != null:
		return attach_point_light_texture

	var texture_size: int = ATTACH_POINT_LIGHT_TEXTURE_SIZE
	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(texture_size) * 0.5, float(texture_size) * 0.5)
	var radius: float = float(texture_size) * 0.5
	var grain_noise := FastNoiseLite.new()
	grain_noise.seed = 91357
	grain_noise.frequency = LIGHT_TEXTURE_GRAIN_FREQUENCY
	grain_noise.fractal_octaves = 3
	grain_noise.fractal_gain = 0.52
	var fine_grain_noise := FastNoiseLite.new()
	fine_grain_noise.seed = 24731
	fine_grain_noise.frequency = LIGHT_TEXTURE_FINE_GRAIN_FREQUENCY
	fine_grain_noise.fractal_octaves = 2
	fine_grain_noise.fractal_gain = 0.44
	for y in texture_size:
		for x in texture_size:
			var pixel_pos := Vector2(float(x) + 0.5, float(y) + 0.5)
			var distance_ratio: float = clampf(pixel_pos.distance_to(center) / radius, 0.0, 1.0)
			var alpha: float = pow(1.0 - distance_ratio, 1.85)
			var grain: float = grain_noise.get_noise_2d(float(x), float(y)) * LIGHT_TEXTURE_GRAIN_STRENGTH
			grain += fine_grain_noise.get_noise_2d(float(x), float(y)) * LIGHT_TEXTURE_FINE_GRAIN_STRENGTH
			alpha = clampf(alpha * (1.0 + grain), 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	attach_point_light_texture = ImageTexture.create_from_image(image)
	return attach_point_light_texture

func get_sprite_texture_bounds_local(sprite: Sprite2D) -> Rect2:
	if sprite == null or !is_instance_valid(sprite) or sprite.texture == null:
		return Rect2()

	var texture_size: Vector2 = sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2()

	var local_top_left: Vector2 = sprite.offset
	if sprite.centered:
		local_top_left -= texture_size * 0.5
	var local_bottom_right: Vector2 = local_top_left + texture_size
	var corners := PackedVector2Array([
		local_top_left,
		Vector2(local_bottom_right.x, local_top_left.y),
		local_bottom_right,
		Vector2(local_top_left.x, local_bottom_right.y),
	])
	var board_points := PackedVector2Array()
	for corner: Vector2 in corners:
		board_points.append(to_local(sprite.to_global(corner)))

	return get_points_bounds_local(board_points)

func play_piece_card_attach_animation(piece_position: Vector2, card: Card, start_texture: Texture2D = null) -> void:
	if should_skip_visual_animations() or !is_inside_tree():
		return
	if card == null or !piece_objects.has(piece_position):
		return

	var piece: Piece = piece_objects[piece_position] as Piece
	if piece == null:
		return

	var attached_texture: Texture2D = get_card_piece_texture_for_color(card, piece.color)
	if attached_texture == null:
		return

	var holder: Sprite2D = get_piece_holder_at(piece_position)
	if holder == null or holder.texture == null:
		return

	if start_texture != null and holder.texture != start_texture:
		holder.texture = start_texture
		refresh_piece_holder_visual(holder, piece_position)

	await get_piece_effect_animator().play_attach_sequence(holder, piece_position, attached_texture, {
		"post_morph_callback": Callable(self, "apply_visible_piece_attach_morph_result").bind(piece_position, attached_texture),
		"disable_holder_occluder": true,
	})

func apply_visible_piece_attach_morph_result(holder: Sprite2D, piece_position: Vector2, attached_texture: Texture2D) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	holder.texture = attached_texture
	refresh_piece_holder_visual(holder, piece_position)

func play_hidden_piece_invisibility_attach_animation(piece_position: Vector2, card: Card, start_texture: Texture2D, piece_color: int) -> void:
	if should_skip_visual_animations() or !is_inside_tree():
		return
	if card == null or !is_valid_position(piece_position):
		return
	if start_texture == null:
		start_texture = get_default_piece_texture(piece_color)
	if start_texture == null:
		return

	var holder: Sprite2D = create_hidden_invisibility_animation_holder(piece_position, start_texture)
	if holder == null:
		return

	var attached_texture: Texture2D = get_card_piece_texture_for_color(card, piece_color)
	if attached_texture == null:
		attached_texture = start_texture

	var completed: bool = await get_piece_effect_animator().play_attach_sequence(holder, piece_position, attached_texture, {
		"post_morph_callback": Callable(self, "apply_hidden_piece_attach_morph_result").bind(piece_position, attached_texture),
		"disable_holder_occluder": false,
	})
	if !completed:
		return

	await get_piece_effect_animator().play_invisibility_exit(holder)

func apply_hidden_piece_attach_morph_result(holder: Sprite2D, piece_position: Vector2, attached_texture: Texture2D) -> void:
	if holder == null or !is_instance_valid(holder):
		return

	holder.texture = attached_texture
	apply_piece_visual_size(holder, piece_position)

func create_piece_effect_holder(piece_position: Vector2, texture_value: Texture2D, holder_name: String = "PieceEffect") -> Sprite2D:
	if texture_value == null or !is_valid_position(piece_position):
		return null
	if piece_effects_node == null or !is_instance_valid(piece_effects_node):
		create_piece_effects_node()
	if piece_effects_node == null:
		return null
	return get_piece_effect_animator().create_effect_holder(piece_position, texture_value, holder_name)

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
	active_bomb_warning_animation_count += 1
	play_bomb_warning_animations(bomb_warning_animations)

	var tween: Tween = create_tween()
	tween.tween_interval(bomb_warning_duration)
	tween.tween_callback(Callable(self, "finish_server_state_visual_update").bind(visual_context))
	tween.finished.connect(func():
		active_bomb_warning_animation_count = maxi(0, active_bomb_warning_animation_count - 1)
	)

func finish_server_state_visual_update(visual_context: Dictionary) -> void:
	display_board()

	var state_piece_move_animation: Dictionary = visual_context.get("state_piece_move_animation", {})
	if !state_piece_move_animation.is_empty():
		var move_to_pos: Vector2 = value_to_vector2(state_piece_move_animation.get("to", INVALID_BOARD_POS), INVALID_BOARD_POS)
		var move_from_pos: Vector2 = value_to_vector2(state_piece_move_animation.get("from", INVALID_BOARD_POS), INVALID_BOARD_POS)
		var move_piece_color: int = int(state_piece_move_animation.get("piece_color", 0))
		var capture_placeholder: Sprite2D = create_piece_move_capture_placeholder(
			move_to_pos,
			state_piece_move_animation.get("captured_texture", null) as Texture2D
		)
		await play_piece_move_animation(
			move_from_pos,
			move_to_pos,
			state_piece_move_animation.get("start_texture", null) as Texture2D,
			bool(state_piece_move_animation.get("visible_to_enemy", true))
		)
		if is_instance_valid(capture_placeholder):
			capture_placeholder.queue_free()
		if move_piece_color != 0:
			piece_moved.emit(move_from_pos, move_to_pos, move_piece_color)

	var animated_attach_positions: Dictionary = visual_context.get("animated_attach_positions", {})
	finish_resolved_pending_card_attach_processes(animated_attach_positions)

	var state_attach_animations: Array = visual_context.get("state_attach_animations", [])
	var state_piece_revert_animations: Array = visual_context.get("state_piece_revert_animations", [])
	var state_piece_shatter_animations: Array = visual_context.get("state_piece_shatter_animations", [])
	var pending_respawn_arrival_animations: Array = visual_context.get("pending_respawn_arrival_animations", [])
	if !state_attach_animations.is_empty():
		call_deferred("play_state_attach_animations", state_attach_animations)
	if !state_piece_revert_animations.is_empty():
		call_deferred("play_piece_revert_animations", state_piece_revert_animations)
	if !state_piece_shatter_animations.is_empty():
		call_deferred("play_piece_shatter_animations", state_piece_shatter_animations)
	if !pending_respawn_arrival_animations.is_empty():
		call_deferred("play_pending_edge_respawn_arrival_animations", pending_respawn_arrival_animations)

	if bool(visual_context.get("should_play_post_state_animations", false)):
		var recent_card_transfers: Array = visual_context.get("recent_card_transfers", [])
		var previous_white_hand_names: Array = visual_context.get("previous_white_hand_names", [])
		var current_white_hand_names: Array = visual_context.get("current_white_hand_names", [])
		var previous_black_hand_names: Array = visual_context.get("previous_black_hand_names", [])
		var current_black_hand_names: Array = visual_context.get("current_black_hand_names", [])
		if recent_card_transfers.is_empty():
			get_card_animation_controller().animate_state_draw_if_needed(1, previous_white_hand_names, current_white_hand_names)
			get_card_animation_controller().animate_state_draw_if_needed(-1, previous_black_hand_names, current_black_hand_names)
		else:
			get_card_animation_controller().animate_recent_card_transfers(recent_card_transfers, previous_white_hand_names, current_white_hand_names, previous_black_hand_names, current_black_hand_names)
		get_card_animation_controller().animate_recent_card_expirations(visual_context.get("card_expiration_events", []))

	if bool(visual_context.get("should_emit_turn_ended", false)):
		turn_ended.emit(int(visual_context.get("server_ending_color", 0)), get_current_turn_color())
	has_received_server_state = true

	if bool(visual_context.get("server_game_over", false)) && int(visual_context.get("winner_player", -1)) != -1:
		finish_game(get_color_for_player_id(int(visual_context.get("winner_player", -1))))

func prepare_piece_shatter_respawn_reveals(animations: Array[Dictionary]) -> void:
	get_piece_respawn_fragment_coordinator().prepare_piece_shatter_respawn_reveals(animations)

func parse_pending_respawn_arrival_animations(recent_pending_respawn_arrivals: Array) -> Array[Dictionary]:
	return get_match_state_sync_controller().parse_pending_respawn_arrival_animations(recent_pending_respawn_arrivals)

func prepare_pending_edge_respawn_arrival_reveals(animations: Array) -> void:
	get_piece_respawn_fragment_coordinator().prepare_pending_edge_respawn_arrival_reveals(animations)

func is_piece_shatter_respawn_reveal_pending(board_pos: Vector2) -> bool:
	return get_piece_respawn_fragment_coordinator().is_piece_shatter_respawn_reveal_pending(board_pos)

func has_piece_shatter_respawn_fragment_markers(board_pos: Vector2) -> bool:
	return get_piece_respawn_fragment_coordinator().has_piece_shatter_respawn_fragment_markers(board_pos)

func should_hide_piece_for_shatter_respawn(board_pos: Vector2) -> bool:
	return get_piece_respawn_fragment_coordinator().should_hide_piece_for_shatter_respawn(board_pos)

func add_piece_shatter_respawn_fragment_marker(respawn_pos: Vector2, fragment: Sprite2D) -> void:
	get_piece_respawn_fragment_coordinator().add_piece_shatter_respawn_fragment_marker(respawn_pos, fragment)

func clear_piece_shatter_respawn_fragment_markers(respawn_pos: Vector2) -> void:
	get_piece_respawn_fragment_coordinator().clear_piece_shatter_respawn_fragment_markers(respawn_pos)

func get_piece_shatter_return_fragment_count(fragment_group: String) -> int:
	return get_piece_respawn_fragment_coordinator().get_piece_shatter_return_fragment_count(fragment_group)

func begin_piece_shatter_respawn_reveal(respawn_pos: Vector2, fragment_group: String) -> int:
	return get_piece_respawn_fragment_coordinator().begin_piece_shatter_respawn_reveal(respawn_pos, fragment_group)

func adjust_piece_shatter_respawn_reveal_count(respawn_pos: Vector2, fragment_count: int) -> void:
	get_piece_respawn_fragment_coordinator().adjust_piece_shatter_respawn_reveal_count(respawn_pos, fragment_count)

func cancel_piece_shatter_respawn_reveal(respawn_pos: Vector2) -> void:
	get_piece_respawn_fragment_coordinator().cancel_piece_shatter_respawn_reveal(respawn_pos)

func finish_piece_shatter_respawn_fragment(respawn_pos: Vector2) -> void:
	get_piece_respawn_fragment_coordinator().finish_piece_shatter_respawn_fragment(respawn_pos)

func refresh_piece_shatter_respawn_piece_visibility(respawn_pos: Vector2) -> void:
	get_piece_respawn_fragment_coordinator().refresh_piece_shatter_respawn_piece_visibility(respawn_pos)

func reveal_piece_shatter_respawn_piece(respawn_pos: Vector2) -> void:
	get_piece_respawn_fragment_coordinator().reveal_piece_shatter_respawn_piece(respawn_pos)

func should_play_piece_move_animation(from_pos: Vector2, to_pos: Vector2, visible_to_enemy: bool = true) -> bool:
	if !piece_move_animation_enabled or should_skip_visual_animations() or !is_inside_tree():
		return false
	if !is_valid_position(from_pos) or !is_valid_position(to_pos):
		return false
	return from_pos != to_pos

func play_piece_move_animation(from_pos: Vector2, to_pos: Vector2, start_texture: Texture2D = null, visible_to_enemy: bool = true) -> void:
	if !should_play_piece_move_animation(from_pos, to_pos, visible_to_enemy):
		return

	var holder: Sprite2D = get_piece_holder_at(to_pos)
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return

	active_piece_move_animation_count += 1
	var end_texture: Texture2D = holder.texture
	var display_texture: Texture2D = start_texture if start_texture != null else end_texture
	var start_transform: Dictionary = get_piece_visual_transform_for_texture(display_texture, from_pos)
	var end_transform: Dictionary = get_piece_visual_transform_for_texture(end_texture, to_pos)
	var start_scale: Vector2 = start_transform.get("scale", holder.scale)
	var end_scale: Vector2 = end_transform.get("scale", holder.scale)
	var start_offset: Vector2 = start_transform.get("offset", holder.offset)
	var end_offset: Vector2 = end_transform.get("offset", holder.offset)

	holder.texture = display_texture
	holder.position = get_board_position_local_position(from_pos)
	holder.scale = start_scale
	holder.offset = start_offset
	var move_animator = get_piece_move_animator()
	holder.z_index = move_animator.get_z_index_for_local_position(holder.position, holder)
	var route_points: Array[Vector2] = move_animator.get_route_points(from_pos, to_pos, holder)
	route_points = move_animator.get_smoothed_route_points(route_points)
	var move_duration: float = move_animator.get_animation_duration(route_points, from_pos, to_pos)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(progress: float): move_animator.update_holder_motion(
			holder,
			route_points,
			to_pos,
			start_scale,
			end_scale,
			start_offset,
			end_offset,
			move_animator.get_arrival_progress(progress, route_points, from_pos, to_pos)
		),
		0.0,
		1.0,
		move_duration
	)
	await tween.finished

	if is_instance_valid(holder):
		holder.texture = end_texture
		refresh_piece_holder_visual(holder, to_pos)
	active_piece_move_animation_count = maxi(0, active_piece_move_animation_count - 1)

func create_piece_move_capture_placeholder(board_pos: Vector2, texture_value: Texture2D) -> Sprite2D:
	if texture_value == null or !is_valid_position(board_pos):
		return null

	var placeholder: Sprite2D = create_piece_effect_holder(board_pos, texture_value, "PieceMoveCaptureTarget")
	if placeholder == null:
		return null
	placeholder.z_index = pieces_node.z_index + get_piece_depth_z_index(board_pos)
	return placeholder

func play_piece_shatter_animations(animations: Array[Dictionary]) -> void:
	get_piece_respawn_fragment_coordinator().play_piece_shatter_animations(animations)

func play_piece_shatter_animation(source_pos: Vector2, respawn_pos: Vector2, piece_color: int, fragment_group: String = PIECE_SHATTER_FRAGMENT_GROUP_NONE) -> void:
	get_piece_respawn_fragment_coordinator().play_piece_shatter_animation(source_pos, respawn_pos, piece_color, fragment_group)

func play_capture_flash_animation(board_pos: Vector2) -> void:
	get_piece_respawn_fragment_coordinator().play_capture_flash_animation(board_pos)

func get_piece_shatter_fragment_textures(fragment_group: String) -> Array[Texture2D]:
	return get_piece_respawn_fragment_coordinator().get_piece_shatter_fragment_textures(fragment_group)

func add_pending_edge_respawn_fragment_marker(piece_color: int, fragment: Sprite2D) -> void:
	get_piece_respawn_fragment_coordinator().add_pending_edge_respawn_fragment_marker(piece_color, fragment)

func take_pending_edge_respawn_fragment_markers(piece_color: int) -> Array[Sprite2D]:
	return get_piece_respawn_fragment_coordinator().take_pending_edge_respawn_fragment_markers(piece_color)

func play_pending_edge_respawn_arrival_animations(animations: Array) -> void:
	get_piece_respawn_fragment_coordinator().play_pending_edge_respawn_arrival_animations(animations)

func create_pending_edge_respawn_fragment_markers(piece_color: int) -> Array[Sprite2D]:
	return get_piece_respawn_fragment_coordinator().create_pending_edge_respawn_fragment_markers(piece_color)

func is_piece_shatter_route_cell_blocked(board_pos: Vector2, source_pos: Vector2, respawn_pos: Vector2) -> bool:
	return get_piece_respawn_fragment_coordinator().is_piece_shatter_route_cell_blocked(board_pos, source_pos, respawn_pos)

func create_hidden_invisibility_animation_holder(piece_position: Vector2, start_texture: Texture2D) -> Sprite2D:
	return create_piece_effect_holder(piece_position, start_texture, "HiddenInvisibilityPiece")

func get_attach_animation_positions(animations: Array[Dictionary]) -> Dictionary:
	var positions: Dictionary = {}
	for animation: Dictionary in animations:
		var board_pos: Vector2 = value_to_vector2(animation.get("position", INVALID_BOARD_POS), INVALID_BOARD_POS)
		if is_valid_position(board_pos):
			positions[board_pos] = true
	return positions

func finish_resolved_pending_card_attach_processes(excluded_positions: Dictionary = {}) -> void:
	for position_value in pending_card_attach_positions.keys():
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if excluded_positions.has(board_pos):
			continue
		if !piece_objects.has(board_pos):
			finish_card_attach_process(position_value)
			continue

		finish_card_attach_process(position_value)

func clear_resolved_pending_card_attach_positions() -> void:
	for position_value in pending_card_attach_positions.keys():
		var board_pos: Vector2 = value_to_vector2(position_value, INVALID_BOARD_POS)
		if !piece_objects.has(board_pos):
			finish_card_attach_process(position_value)

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

func refill_played_cards_locally(owner_color: int) -> void:
	var played_slots: Array = played_card_hand_slots_this_turn.get(owner_color, [])
	if played_slots.is_empty():
		return

	played_slots.sort()
	for slot_value in played_slots:
		var hand: Array[Card] = get_card_hand(owner_color)
		if hand.size() >= DeckManager.HAND_SIZE:
			break

		var card_name: String = get_card_hand_state_controller().draw_refill_card_name(owner_color)
		if card_name.is_empty():
			break
		insert_drawn_card(owner_color, int(slot_value), card_name)

	played_card_hand_slots_this_turn[owner_color] = []

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

func get_moves(selected : Vector2):
	if piece_objects.has(selected):
		var piece: Piece = piece_objects[selected] as Piece
		if piece.can_move():
			DebugLog.info("Using card movement: %s" % piece.get_info())
			return get_card_based_moves(selected, piece, get_move_preview_player_id(selected, piece))
		else:
			DebugLog.info("No usable card on this piece.")
			return []

	return []

func get_move_preview_player_id(piece_position: Vector2, piece: Piece) -> int:
	var own_player_id: int = get_own_player_id()
	if can_control_current_turn() && can_player_control_piece_at(piece_position, own_player_id):
		return own_player_id
	return get_player_id_for_color(piece.color)

func get_card_based_moves(piece_position: Vector2, piece: Piece, player_id: int) -> Array:
	var valid_moves: Array[Vector2] = MoveRules.get_piece_moves_for_player(piece_objects, piece_position, player_id, BOARD_SIZE, current_board_effects)
	valid_moves = filter_tutorial_move_targets(piece_position, valid_moves, piece.color)
	DebugLog.info("  Valid moves: %s" % [valid_moves])
	return valid_moves

func filter_tutorial_move_targets(from_pos: Vector2, candidate_moves: Array[Vector2], owner_color: int) -> Array[Vector2]:
	if !tutorial_constraints_enabled:
		return candidate_moves

	var filtered_moves: Array[Vector2] = []
	for to_pos: Vector2 in candidate_moves:
		if is_tutorial_action_allowed(TUTORIAL_ACTION_MOVE_PIECE, {
			"owner_color": owner_color,
			"from_pos": from_pos,
			"to_pos": to_pos,
		}):
			filtered_moves.append(to_pos)
	return filtered_moves

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
	return CardEffectResolver.can_player_control_piece(piece, player_id)

func can_control_current_turn() -> bool:
	if game_over:
		return false
	if side == null:
		return GameConfig.is_singleplayer or tutorial_mode_active
	return side == white

func update_from_server_state(pieces_data: Dictionary, player_hands: Dictionary, current_turn: int, server_game_over: bool = false, winner_player: int = -1, player_deck_sizes: Dictionary = {}, hidden_cards: Array = [], player_base_fields: Dictionary = {}, board_effects: Array = [], player_names: Dictionary = {}, recent_card_transfers: Array = [], recent_card_expirations: Array = [], recent_bomb_effects: Array = [], recent_pending_respawn_queues: Array = [], recent_pending_respawn_arrivals: Array = [], last_move: Dictionary = {}, player_portraits: Dictionary = {}, viewer_player_id: int = -1, turn_action_state: Dictionary = {}):
	get_server_state_update_controller().update_from_server_state(
		pieces_data,
		player_hands,
		current_turn,
		server_game_over,
		winner_player,
		player_deck_sizes,
		hidden_cards,
		player_base_fields,
		board_effects,
		player_names,
		recent_card_transfers,
		recent_card_expirations,
		recent_bomb_effects,
		recent_pending_respawn_queues,
		recent_pending_respawn_arrivals,
		last_move,
		player_portraits,
		viewer_player_id,
		turn_action_state
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
