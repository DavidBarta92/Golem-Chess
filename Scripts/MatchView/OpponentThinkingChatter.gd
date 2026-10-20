extends Node

## Lets an AI opponent think out loud while it takes its time.
##
## The AI paces its turns (AITurnPlanner.begin_turn_pacing), so between two of
## its actions it can sit still for several seconds. Every third pause longer
## than LONG_PAUSE_SECONDS puts a short thinking line in the opponent's speech
## panel. Works for every AI opponent the match HUD builds a speech panel for -
## story bosses, random story opponents and quick play alike. The tutorial
## brings its own panel and is left alone.
##
## A line the opponent already has up (a boss reaction, say) is never cut off:
## a due thinking line waits for the next long pause instead.

const LONG_PAUSE_SECONDS: float = 4.0
const LONG_PAUSES_PER_LINE: int = 3
const LINE_KEYS: Array[String] = [
	"AI_THINKING_01", "AI_THINKING_02", "AI_THINKING_03", "AI_THINKING_04", "AI_THINKING_05",
	"AI_THINKING_06", "AI_THINKING_07", "AI_THINKING_08", "AI_THINKING_09", "AI_THINKING_10",
	"AI_THINKING_11", "AI_THINKING_12", "AI_THINKING_13", "AI_THINKING_14", "AI_THINKING_15",
	"AI_THINKING_16", "AI_THINKING_17", "AI_THINKING_18", "AI_THINKING_19", "AI_THINKING_20",
	"AI_THINKING_21", "AI_THINKING_22", "AI_THINKING_23", "AI_THINKING_24", "AI_THINKING_25",
]

@export var multiplayer_node_path: NodePath = NodePath("..")
@export var match_board_path: NodePath = NodePath("../MatchBoard")

var _multiplayer_node: Node
var _match_board: Node
var _long_pause_count: int = 0
var _line_due: bool = false
## Shuffled keys still to be used, so every line is heard once before any repeats.
var _line_bag: Array[String] = []
var _last_line_key: String = ""

func _ready() -> void:
	_multiplayer_node = get_node_or_null(multiplayer_node_path)
	_match_board = get_node_or_null(match_board_path)
	if _multiplayer_node == null or _match_board == null or !_multiplayer_node.has_signal("ai_thinking_pause_started"):
		queue_free()
		return
	_multiplayer_node.ai_thinking_pause_started.connect(_on_ai_thinking_pause_started)

func _on_ai_thinking_pause_started(player_id: int, seconds: float) -> void:
	if seconds <= LONG_PAUSE_SECONDS or !_is_ai_facing_human(player_id) or _is_game_over():
		return

	_long_pause_count += 1
	if _long_pause_count % LONG_PAUSES_PER_LINE == 0:
		_line_due = true
	if !_line_due:
		return

	var turn_hud = _get_turn_hud()
	if turn_hud == null:
		return
	var speech: OpponentSpeechPanel = turn_hud.opponent_speech
	if speech == null or !is_instance_valid(speech) or speech.is_showing():
		return

	_line_due = false
	speech.speak(
		turn_hud.get_display_name_for_player(player_id),
		tr(_draw_line_key()),
		turn_hud.get_portrait_config_for_player(player_id)
	)

func _draw_line_key() -> String:
	if _line_bag.is_empty():
		_line_bag = LINE_KEYS.duplicate()
		_line_bag.shuffle()
		# A fresh bag must not open with the line that closed the previous one.
		if _line_bag.size() > 1 and _line_bag.back() == _last_line_key:
			var first_key: String = _line_bag[0]
			_line_bag[0] = _line_bag.back()
			_line_bag[_line_bag.size() - 1] = first_key
	_last_line_key = _line_bag.pop_back()
	return _last_line_key

func _is_ai_facing_human(player_id: int) -> bool:
	return GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_AI \
		and GameConfig.get_player_controller(1 - player_id) == GameConfig.CONTROLLER_HUMAN

func _is_game_over() -> bool:
	var game_host = _multiplayer_node.get("game_host")
	return game_host == null or game_host.game_state == null or game_host.game_state.game_over

func _get_turn_hud():
	if _match_board == null or !is_instance_valid(_match_board) or !_match_board.has_method("get_turn_hud_controller"):
		return null
	return _match_board.get_turn_hud_controller()
