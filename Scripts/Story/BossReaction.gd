@tool
extends Resource
class_name BossReaction

## One thing a boss can say, and what makes them say it.
##
## Reactions live in a single list on the BossDefinition rather than in one
## field per trigger, so adding a new trigger later is one more entry in the
## enum below and a case in BossDialogueDirector - not a new field on every
## boss that already exists.
##
## Frequency is deliberately per-trigger rather than per-line: "I took a piece"
## happens constantly and should be rare to hear, while "I am one move from
## losing" happens once a match and should always land. On top of that the
## director enforces a global cooldown, which is what actually stops two
## reactions from piling up on the same chaotic turn.

## Triggers fired by what happened on the board.
const TRIGGER_BOSS_CAPTURED_PIECE: String = "boss_captured_piece"
const TRIGGER_BOSS_PIECE_CAPTURED: String = "boss_piece_captured"
## Fired the turn the boss *enters* one of the AI's strategy modes (see
## AIStrategyDirector) - not every turn it stays there, or it would repeat
## itself for the whole defensive phase.
const TRIGGER_ENTERED_ROUTE_SETUP: String = "entered_route_setup"
const TRIGGER_ENTERED_ACTIVE_SEEKER_PUSH: String = "entered_active_seeker_push"
const TRIGGER_ENTERED_ENDGAME_SEEKER_FINISH: String = "entered_endgame_seeker_finish"
const TRIGGER_ENTERED_SEEKER_ATTACK: String = "entered_seeker_attack"
const TRIGGER_ENTERED_SOFT_DEFENSE: String = "entered_soft_defense"
const TRIGGER_ENTERED_EMERGENCY_DEFENSE: String = "entered_emergency_defense"
## Fired when the boss affixes the specific stamp set in `stamp` below.
const TRIGGER_STAMP_PLAYED: String = "stamp_played"

## Maps the AI's own strategy mode names onto the triggers above, so the
## director never has to know AIStrategyDirector's vocabulary.
const MODE_TRIGGERS: Dictionary = {
	AIStrategyDirector.MODE_ROUTE_SETUP: TRIGGER_ENTERED_ROUTE_SETUP,
	AIStrategyDirector.MODE_ACTIVE_SEEKER_PUSH: TRIGGER_ENTERED_ACTIVE_SEEKER_PUSH,
	AIStrategyDirector.MODE_ENDGAME_SEEKER_FINISH: TRIGGER_ENTERED_ENDGAME_SEEKER_FINISH,
	AIStrategyDirector.MODE_SEEKER_ATTACK: TRIGGER_ENTERED_SEEKER_ATTACK,
	AIStrategyDirector.MODE_SOFT_DEFENSE: TRIGGER_ENTERED_SOFT_DEFENSE,
	AIStrategyDirector.MODE_EMERGENCY_DEFENSE: TRIGGER_ENTERED_EMERGENCY_DEFENSE,
}

# Keep this list in sync with the TRIGGER_* constants above - the annotation
# cannot reference them.
@export_enum(
	"boss_captured_piece",
	"boss_piece_captured",
	"entered_route_setup",
	"entered_active_seeker_push",
	"entered_endgame_seeker_finish",
	"entered_seeker_attack",
	"entered_soft_defense",
	"entered_emergency_defense",
	"stamp_played"
) var trigger: String = TRIGGER_BOSS_CAPTURED_PIECE

## Only used by the "stamp_played" trigger: the stamp whose appearance sets
## this reaction off. A stamp_played reaction with nothing here never fires.
@export var stamp: Stamp

## The variants. One is picked per firing, never the same one twice in a row.
## Translation keys unless the boss has localize_lines turned off.
@export var lines: Array[String] = []

## How often this trigger is allowed to speak at all, before the cooldown is
## even considered.
@export_range(0.0, 1.0, 0.05) var chance: float = 0.5

## Lets a reaction speak even if the boss said something a moment ago. Meant
## for the once-a-match beats, not for anything that fires regularly.
@export var bypass_cooldown: bool = false

## Index of the last line handed out, so the next pick can avoid repeating it.
## Deliberately not exported: this is per-session state, not authored data, and
## it survives between matches because Godot caches the loaded resource.
var _last_line_index: int = -1

func has_lines() -> bool:
	return !get_usable_lines().is_empty()

func matches_stamp(stamp_name: String) -> bool:
	if trigger != TRIGGER_STAMP_PLAYED or stamp == null:
		return false
	return str(stamp.stamp_name).strip_edges() == stamp_name.strip_edges()

## Picks a variant, avoiding the one used last time. Returns "" when this
## reaction has no text authored yet.
func pick_line() -> String:
	var usable_lines: Array[String] = get_usable_lines()
	if usable_lines.is_empty():
		return ""
	if usable_lines.size() == 1:
		_last_line_index = 0
		return usable_lines[0]

	var index: int = randi() % usable_lines.size()
	if index == _last_line_index:
		index = (index + 1 + randi() % (usable_lines.size() - 1)) % usable_lines.size()
	_last_line_index = index
	return usable_lines[index]

func get_usable_lines() -> Array[String]:
	var usable_lines: Array[String] = []
	for line in lines:
		var line_text: String = str(line).strip_edges()
		if !line_text.is_empty():
			usable_lines.append(line_text)
	return usable_lines

## Trigger name for one of the AI's strategy modes, or "" for a mode that has
## no reaction trigger of its own (the opening).
static func get_trigger_for_mode(mode: String) -> String:
	return str(MODE_TRIGGERS.get(mode, ""))
