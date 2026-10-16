extends Node
class_name BossDialogueDirector

## Gives a story boss a voice during the match.
##
## Sits in the match scene next to the Multiplayer node and listens to two
## things it publishes: every host state change (which is how both sides'
## captures are seen, from one place, regardless of who moved) and the end of
## each AI turn (which is how the AI's strategy mode and the stamps it just
## played are seen). Nothing in the match or the AI knows this exists - in a
## non-story match the director finds no boss and removes itself.
##
## Lines are spoken through the opponent panel the match HUD already builds
## (TurnHudController.opponent_panel), so there is no second dialogue UI: the
## box simply opens under the opponent's name and portrait, types itself out,
## and closes again. It never takes clicks - the match carries on underneath.
##
## What keeps it from becoming noise is a global cooldown counted in the
## boss's own turns, on top of a per-trigger chance. The cooldown is what
## actually stops two reactions landing on one chaotic turn; the chance is
## what makes "I took a piece" rare and "I am one move from losing" certain.

const GROUP_NAME: String = "boss_dialogue_director"
const INTRO_DELAY_SECONDS: float = 0.9
const LINE_VISIBLE_SECONDS: float = 3.4
const OUTCOME_LINE_VISIBLE_SECONDS: float = 5.5
const REACTION_COOLDOWN_TURNS: int = 2

## Which trigger wins when several fire on the same turn. Lower goes first: a
## strategy shift is a bigger beat than a stamp, which is a bigger beat than
## yet another capture.
const TRIGGER_PRIORITY: Dictionary = {
	BossReaction.TRIGGER_ENTERED_EMERGENCY_DEFENSE: 0,
	BossReaction.TRIGGER_ENTERED_ENDGAME_SEEKER_FINISH: 1,
	BossReaction.TRIGGER_ENTERED_ACTIVE_SEEKER_PUSH: 2,
	BossReaction.TRIGGER_ENTERED_SOFT_DEFENSE: 3,
	BossReaction.TRIGGER_ENTERED_ROUTE_SETUP: 4,
	BossReaction.TRIGGER_STAMP_PLAYED: 5,
	BossReaction.TRIGGER_BOSS_CAPTURED_PIECE: 6,
	BossReaction.TRIGGER_BOSS_PIECE_CAPTURED: 7,
}

@export var multiplayer_node_path: NodePath = NodePath("..")
@export var match_board_path: NodePath = NodePath("../MatchBoard")

var _boss: BossDefinition
var _boss_player_id: int = 1
var _multiplayer_node: Node
var _match_board: Node

var _boss_turn_index: int = 0
var _last_spoken_turn_index: int = -99
var _last_strategy_mode: String = ""
var _last_move_signature: String = ""
var _current_turn_player: int = -1
var _pending_triggers: Array[String] = []
var _is_speaking: bool = false
var _match_finished: bool = false
var _speech_token: int = 0

func _ready() -> void:
	_boss = StoryManager.get_active_boss()
	if _boss == null:
		# Not a story fight - quick play, multiplayer, AI vs AI. Nothing to say.
		queue_free()
		return

	_multiplayer_node = get_node_or_null(multiplayer_node_path)
	_match_board = get_node_or_null(match_board_path)
	if _multiplayer_node == null or _match_board == null:
		push_error("BossDialogueDirector could not find the multiplayer node or the match board.")
		queue_free()
		return

	add_to_group(GROUP_NAME)
	_boss_player_id = _resolve_boss_player_id()
	_multiplayer_node.host_state_changed.connect(_on_host_state_changed)
	_multiplayer_node.ai_turn_finished.connect(_on_ai_turn_finished)
	call_deferred("_speak_intro_line")

# --- Match events -----------------------------------------------------------

## Fires on every host broadcast, for both sides. Captures are read here rather
## than from a board signal so the player's move and the boss's move come
## through the same path.
func _on_host_state_changed() -> void:
	var game_state = _get_game_state()
	if game_state == null or _match_finished:
		return

	_track_turn_changes(game_state)
	_track_capture(game_state)

func _track_turn_changes(game_state) -> void:
	var turn_player: int = int(game_state.current_turn_player)
	if turn_player == _current_turn_player:
		return

	_current_turn_player = turn_player
	if turn_player == _boss_player_id:
		_boss_turn_index += 1

func _track_capture(game_state) -> void:
	var last_move: Dictionary = game_state.last_move
	var signature: String = _build_move_signature(last_move)
	if signature == _last_move_signature:
		return

	_last_move_signature = signature
	if int(last_move.get("captured_piece_color", 0)) == 0:
		return

	if int(last_move.get("player_id", -1)) == _boss_player_id:
		# The boss took something. Its own turn is still running, so hold the
		# trigger until the turn ends and the bigger beats are known too.
		_pending_triggers.append(BossReaction.TRIGGER_BOSS_CAPTURED_PIECE)
		return

	# The player took something: nothing else can happen this turn, so there is
	# nothing to wait for.
	_evaluate_triggers([BossReaction.TRIGGER_BOSS_PIECE_CAPTURED], [])

## Identifies one move well enough to tell a fresh broadcast from a repeat of
## the same one. The host re-broadcasts state several times per turn, and a
## capture must only ever be reacted to once.
func _build_move_signature(last_move: Dictionary) -> String:
	if last_move.is_empty():
		return ""
	return "%s|%s|%s|%s" % [
		str(last_move.get("from", "")),
		str(last_move.get("to", "")),
		str(last_move.get("player_id", -1)),
		str(last_move.get("captured_piece_color", 0)),
	]

## Everything the AI did this turn is known by now, so this is where the turn's
## triggers are weighed against each other and at most one line comes out.
func _on_ai_turn_finished(player_id: int, report: Dictionary) -> void:
	if player_id != _boss_player_id or _match_finished:
		return

	var triggers: Array[String] = _pending_triggers.duplicate()
	_pending_triggers.clear()

	var mode_trigger: String = _consume_strategy_mode_change(str(report.get("strategy_mode", "")))
	if !mode_trigger.is_empty():
		triggers.append(mode_trigger)

	var stamp_names: Array[String] = []
	var reported_stamp_names = report.get("affixed_stamp_names", [])
	if reported_stamp_names is Array:
		for stamp_name_value in reported_stamp_names:
			stamp_names.append(str(stamp_name_value))
	if !stamp_names.is_empty():
		triggers.append(BossReaction.TRIGGER_STAMP_PLAYED)

	_evaluate_triggers(triggers, stamp_names)

## Returns the trigger for a mode the boss has just moved into, or "" when the
## mode is unchanged (or is one with no reaction of its own, like the opening).
## A mode that persists must not re-fire, or the boss would repeat itself for
## the whole defensive phase.
func _consume_strategy_mode_change(mode: String) -> String:
	var new_mode: String = mode.strip_edges()
	if new_mode.is_empty() or new_mode == _last_strategy_mode:
		return ""

	_last_strategy_mode = new_mode
	return BossReaction.get_trigger_for_mode(new_mode)

## Called by GameResultController when a story match ends.
func on_match_finished(player_won: bool) -> void:
	if _match_finished or _boss == null:
		return
	_match_finished = true
	_pending_triggers.clear()

	if player_won:
		# The player is on their way to the reward scene; the boss gets the
		# last word there rather than over a board that is about to disappear.
		StoryManager.set_pending_boss_line(
			_boss.get_localized_display_name(),
			_boss.pick_defeat_line(),
			_boss.get_portrait_data()
		)
		return

	# On a loss there is no reward scene to speak in, so the boss gloats over
	# the finished board during the wait before the defeat comic.
	_speak(_boss.pick_victory_line(), OUTCOME_LINE_VISIBLE_SECONDS)

# --- Choosing a line --------------------------------------------------------

## Weighs this turn's triggers in priority order and speaks the first one that
## passes both its cooldown and its chance roll. Rolling on through a failed
## chance is deliberate: the point of a low chance is that this *kind* of event
## is rarely worth a line, not that the turn goes quiet.
func _evaluate_triggers(triggers: Array[String], stamp_names: Array[String]) -> void:
	if _boss == null or _match_finished or triggers.is_empty():
		return

	var ordered_triggers: Array[String] = triggers.duplicate()
	ordered_triggers.sort_custom(_compare_trigger_priority)

	for trigger in ordered_triggers:
		var reaction: BossReaction = _find_reaction(trigger, stamp_names)
		if reaction == null:
			continue
		if _try_speak_reaction(reaction):
			return

func _compare_trigger_priority(a: String, b: String) -> bool:
	return int(TRIGGER_PRIORITY.get(a, 99)) < int(TRIGGER_PRIORITY.get(b, 99))

func _find_reaction(trigger: String, stamp_names: Array[String]) -> BossReaction:
	if trigger == BossReaction.TRIGGER_STAMP_PLAYED:
		for stamp_name in stamp_names:
			var stamp_reaction: BossReaction = _boss.get_stamp_reaction(stamp_name)
			if stamp_reaction != null:
				return stamp_reaction
		return null

	var reactions: Array[BossReaction] = _boss.get_reactions_for_trigger(trigger)
	return reactions[0] if !reactions.is_empty() else null

func _try_speak_reaction(reaction: BossReaction) -> bool:
	# A line already up is no longer a reason to stay quiet: the panel keeps the
	# speaker on screen and swaps their words. The cooldown below is what keeps
	# the boss from chattering.
	if !reaction.bypass_cooldown and _boss_turn_index - _last_spoken_turn_index < REACTION_COOLDOWN_TURNS:
		return false
	if randf() > reaction.chance:
		return false

	var text: String = _boss.localize_line(reaction.pick_line())
	if text.is_empty():
		return false

	_speak(text, LINE_VISIBLE_SECONDS)
	return true

func _speak_intro_line() -> void:
	if _boss == null or _match_finished:
		return
	await get_tree().create_timer(INTRO_DELAY_SECONDS).timeout
	if _boss == null or _match_finished or !is_inside_tree():
		return
	_speak(_boss.pick_intro_line(), LINE_VISIBLE_SECONDS)

# --- Saying it --------------------------------------------------------------

## Opens the opponent panel's text box, types the line out, and closes it again
## after `visible_seconds`. Non-blocking throughout.
func _speak(text: String, visible_seconds: float) -> void:
	if text.strip_edges().is_empty():
		return

	var turn_hud = _get_turn_hud()
	var panel: DialoguePanel = _get_opponent_panel()
	if turn_hud == null or panel == null:
		return

	_speech_token += 1
	var token: int = _speech_token
	_is_speaking = true
	_last_spoken_turn_index = _boss_turn_index

	# How long the words stay, when the face arrives and how both leave is the
	# speech panel's business, not this one's - all it is handed is the line.
	var speech: OpponentSpeechPanel = turn_hud.opponent_speech
	if speech != null and is_instance_valid(speech):
		speech.speak(_boss.get_localized_display_name(), text, _get_boss_portrait())
		return

	# No speech panel - a panel the HUD did not build, driven by hand.
	panel.show_line(_boss.get_localized_display_name(), text, _get_boss_portrait(), false)
	panel.set_interactive(false)

	await get_tree().create_timer(visible_seconds).timeout
	if token != _speech_token or !is_inside_tree():
		return
	_stop_speaking()

func _stop_speaking() -> void:
	_is_speaking = false

	var panel: DialoguePanel = _get_opponent_panel()
	if panel != null:
		panel.set_interactive(true)

	var turn_hud = _get_turn_hud()
	if turn_hud == null:
		return
	# Hands the panel back to the HUD, which restores the plain name-and-face
	# profile it normally shows.
	turn_hud.update_opponent_panel()

func _get_boss_portrait() -> PortraitConfig:
	if _boss.portrait != null:
		return _boss.portrait
	return PortraitLibrary.config_from_data_or_default(_boss.get_portrait_data(), _boss_player_id)

# --- Lookups ----------------------------------------------------------------

func _get_game_state():
	if _multiplayer_node == null or !is_instance_valid(_multiplayer_node):
		return null
	var game_host = _multiplayer_node.get("game_host")
	return game_host.game_state if game_host != null else null

func _get_turn_hud():
	if _match_board == null or !is_instance_valid(_match_board):
		return null
	if !_match_board.has_method("get_turn_hud_controller"):
		return null
	return _match_board.get_turn_hud_controller()

func _get_opponent_panel() -> DialoguePanel:
	var turn_hud = _get_turn_hud()
	if turn_hud == null:
		return null
	return turn_hud.opponent_panel as DialoguePanel

func _resolve_boss_player_id() -> int:
	for player_id in [1, 0]:
		if GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_AI:
			return player_id
	return 1
