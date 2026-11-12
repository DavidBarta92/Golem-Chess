@tool
extends RefCounted
class_name QuestCondition

## What a quest asks for (Docs/Quests/QUESTS.md). Each type is moved on by one
## kind of game event (QuestStore.record_event): `param` - the quest's XY -
## narrows down which events count, and the quest's target - its X - is how
## many it takes.
##
##   type              event            param
##   WIN_MATCHES       match_finished   "singleplayer" / "multiplayer"; empty: any
##   PLAY_MATCHES      match_finished   the same
##   AFFIX_STAMPS      stamp_affixed    a set ("Animals", ...); empty: any
##   BUY_PACKS         packs_bought     a pack id; empty: any
##   LIST_LOTS         lot_listed       -
##   SOLVE_PUZZLES     puzzle_solved    -  (first solves only)
##   OPEN_SCREEN       screen_opened    "collection" / "bourse" / "puzzles"
##   AFFIX_ROLE        stamp_affixed    a role ("Seeker", ...)
##   AFFIX_EFFECT      stamp_affixed    an effect type ("bomb", ...)
##   AFFIX_SPECIFIC    stamp_affixed    a stamp's name
##   CAPTURE_PIECES    piece_captured   the capturing stamp's name; empty: any
##   LOSE_PIECES       piece_lost       -
##   PLACE_CROWNS      crown_placed     -
##   WIN_WITH_STAMP    match_finished   a stamp's name, in the codex played
##   CODEX_WITH_STAMP  codex_saved      a stamp's name; X is how many copies
##   SELL_LOTS         lot_sold         -  (when the price is collected)
##   BUY_LOTS          lot_bought       -  (when the stamp is picked)
##
## The XY of a type that needs one (needs_param) comes from the template's
## param_pool, or else from where the player stands (dynamic_params): the
## stamps, roles and effects of their playable codexes, or the stamps they own
## in no codex. Matches count when a player of this machine's own plays them,
## the story's included; never the tutorial, a puzzle board or an AI batch.
## Captures and losses are a move's; a bomb's do not count.

enum Type {
	WIN_MATCHES,
	PLAY_MATCHES,
	AFFIX_STAMPS,
	BUY_PACKS,
	LIST_LOTS,
	SOLVE_PUZZLES,
	OPEN_SCREEN,
	AFFIX_ROLE,
	AFFIX_EFFECT,
	AFFIX_SPECIFIC,
	CAPTURE_PIECES,
	LOSE_PIECES,
	PLACE_CROWNS,
	WIN_WITH_STAMP,
	CODEX_WITH_STAMP,
	SELL_LOTS,
	BUY_LOTS,
}

## Quests are saved with these ids, not with the enum's numbers.
const IDS: Dictionary = {
	Type.WIN_MATCHES: "win_matches",
	Type.PLAY_MATCHES: "play_matches",
	Type.AFFIX_STAMPS: "affix_stamps",
	Type.BUY_PACKS: "buy_packs",
	Type.LIST_LOTS: "list_lots",
	Type.SOLVE_PUZZLES: "solve_puzzles",
	Type.OPEN_SCREEN: "open_screen",
	Type.AFFIX_ROLE: "affix_role",
	Type.AFFIX_EFFECT: "affix_effect",
	Type.AFFIX_SPECIFIC: "affix_specific",
	Type.CAPTURE_PIECES: "capture_pieces",
	Type.LOSE_PIECES: "lose_pieces",
	Type.PLACE_CROWNS: "place_crowns",
	Type.WIN_WITH_STAMP: "win_with_stamp",
	Type.CODEX_WITH_STAMP: "codex_with_stamp",
	Type.SELL_LOTS: "sell_lots",
	Type.BUY_LOTS: "buy_lots",
}

## {"won": bool, "singleplayer": bool, "codex_stamps": Array of stamp names}
const EVENT_MATCH_FINISHED: String = "match_finished"
## {"stamp_name": String} - one the player put on a golem of theirs.
const EVENT_STAMP_AFFIXED: String = "stamp_affixed"
## {"count": int, "pack_id": String}
const EVENT_PACKS_BOUGHT: String = "packs_bought"
const EVENT_LOT_LISTED: String = "lot_listed"
## {"puzzle_id": String} - the first time a puzzle is solved.
const EVENT_PUZZLE_SOLVED: String = "puzzle_solved"
## {"scene_path": String}
const EVENT_SCREEN_OPENED: String = "screen_opened"
## {"stamp_name": String} - the stamp of the player's golem that took one.
const EVENT_PIECE_CAPTURED: String = "piece_captured"
## A golem of the player's taken by a move of the opponent's.
const EVENT_PIECE_LOST: String = "piece_lost"
const EVENT_CROWN_PLACED: String = "crown_placed"
## {"stamp_names": Array} - every copy in the codex saved.
const EVENT_CODEX_SAVED: String = "codex_saved"
## The price of a sold lot collected.
const EVENT_LOT_SOLD: String = "lot_sold"
## A stamp picked from one of the day's lots.
const EVENT_LOT_BOUGHT: String = "lot_bought"

const MODE_SINGLEPLAYER: String = "singleplayer"
const MODE_MULTIPLAYER: String = "multiplayer"
const SETS: Array[String] = ["Animals", "Flora", "Celestials", "Archetypes", "Courtyard", "Structures"]
## Stamp.role, by its number. Unit is every plain stamp: a quest asks for the others.
const ROLES: Array[String] = ["Unit", "Seeker", "Shared", "Se-tenant", "Overseal"]
const ROLE_UNIT: String = "Unit"
const EFFECTS: Array[String] = [
	"steal_stamp", "grant_stamp", "give_stamp", "move_base", "invisible_to_enemy",
	"invalid_squares", "frozen_squares", "bomb", "uncapturable",
	"increase_own_durations", "increase_enemy_durations", "decrease_own_durations",
	"decrease_enemy_durations", "increase_self_duration", "gain_crown_point",
	"remove_enemy_crown_point",
]
const SCREEN_SCENES: Dictionary = {
	"collection": "res://Scenes/Collection.tscn",
	"bourse": "res://Scenes/Bourse.tscn",
	"puzzles": "res://Scenes/Puzzles.tscn",
}
const SCREEN_LABELS: Dictionary = {
	"collection": "QUEST_SCREEN_COLLECTION",
	"bourse": "QUEST_SCREEN_BOURSE",
	"puzzles": "QUEST_SCREEN_PUZZLES",
}
const MODE_LABELS: Dictionary = {
	MODE_SINGLEPLAYER: "QUEST_MODE_SINGLEPLAYER",
	MODE_MULTIPLAYER: "QUEST_MODE_MULTIPLAYER",
}

static func id_of(type: int) -> String:
	return str(IDS.get(type, ""))

## The type saved under an id, or -1.
static func type_from_id(condition_id: String) -> int:
	for type in IDS:
		if IDS[type] == condition_id:
			return type
	return -1

## Whether the type reads a param at all.
static func takes_param(type: int) -> bool:
	return !(type in [Type.LIST_LOTS, Type.SOLVE_PUZZLES, Type.LOSE_PIECES, Type.PLACE_CROWNS, Type.SELL_LOTS, Type.BUY_LOTS])

## Whether the type means nothing without a param.
static func needs_param(type: int) -> bool:
	return type in [Type.OPEN_SCREEN, Type.AFFIX_ROLE, Type.AFFIX_EFFECT, Type.AFFIX_SPECIFIC, Type.WIN_WITH_STAMP, Type.CODEX_WITH_STAMP]

## Whether the type reads a count; opening a screen happens once.
static func takes_count(type: int) -> bool:
	return type != Type.OPEN_SCREEN

## A level reached rather than steps added: the quest's progress is the most
## an event has shown (the copies in a codex saved), not a sum.
static func is_level(type: int) -> bool:
	return type == Type.CODEX_WITH_STAMP

## What `param` can be, for the inspector; empty for a type that takes a
## stamp's name (any stamp) or none.
static func param_options(type: int) -> Array[String]:
	match type:
		Type.WIN_MATCHES, Type.PLAY_MATCHES:
			return [MODE_SINGLEPLAYER, MODE_MULTIPLAYER]
		Type.AFFIX_STAMPS:
			return SETS.duplicate()
		Type.AFFIX_ROLE:
			return ROLES.slice(1)
		Type.AFFIX_EFFECT:
			return EFFECTS.duplicate()
		Type.OPEN_SCREEN:
			var screens: Array[String] = []
			for screen in SCREEN_SCENES:
				screens.append(screen)
			return screens
	return []

## How far one event moves a quest of this type: 0 when it does not count.
## For a level type (is_level), the level the event shows.
static func progress_for(type: int, param: String, event: String, data: Dictionary) -> int:
	match type:
		Type.WIN_MATCHES:
			if event == EVENT_MATCH_FINISHED and bool(data.get("won", false)) and _mode_matches(param, data):
				return 1
		Type.PLAY_MATCHES:
			if event == EVENT_MATCH_FINISHED and _mode_matches(param, data):
				return 1
		Type.AFFIX_STAMPS:
			if event == EVENT_STAMP_AFFIXED and (param.is_empty() or _set_of(_stamp(data)) == param):
				return 1
		Type.AFFIX_ROLE:
			if event == EVENT_STAMP_AFFIXED and _role_of(_stamp(data)) == param:
				return 1
		Type.AFFIX_EFFECT:
			if event == EVENT_STAMP_AFFIXED and _effect_of(_stamp(data)) == param:
				return 1
		Type.AFFIX_SPECIFIC:
			if event == EVENT_STAMP_AFFIXED and str(data.get("stamp_name", "")) == param:
				return 1
		Type.BUY_PACKS:
			if event == EVENT_PACKS_BOUGHT and (param.is_empty() or str(data.get("pack_id", "")) == param):
				return maxi(0, int(data.get("count", 1)))
		Type.LIST_LOTS:
			if event == EVENT_LOT_LISTED:
				return 1
		Type.SOLVE_PUZZLES:
			if event == EVENT_PUZZLE_SOLVED:
				return 1
		Type.OPEN_SCREEN:
			if event == EVENT_SCREEN_OPENED and str(data.get("scene_path", "")) == str(SCREEN_SCENES.get(param, "-")):
				return 1
		Type.CAPTURE_PIECES:
			if event == EVENT_PIECE_CAPTURED and (param.is_empty() or str(data.get("stamp_name", "")) == param):
				return 1
		Type.LOSE_PIECES:
			if event == EVENT_PIECE_LOST:
				return 1
		Type.PLACE_CROWNS:
			if event == EVENT_CROWN_PLACED:
				return 1
		Type.WIN_WITH_STAMP:
			if event == EVENT_MATCH_FINISHED and bool(data.get("won", false)) and (data.get("codex_stamps", []) as Array).has(param):
				return 1
		Type.CODEX_WITH_STAMP:
			if event == EVENT_CODEX_SAVED:
				return (data.get("stamp_names", []) as Array).count(param)
		Type.SELL_LOTS:
			if event == EVENT_LOT_SOLD:
				return 1
		Type.BUY_LOTS:
			if event == EVENT_LOT_BOUGHT:
				return 1
	return 0

## Whether a quest of this type, param and count can be done from where the
## player is now - asked before one is handed out (QuestDirector).
static func is_available(type: int, param: String, count: int) -> bool:
	if needs_param(type) and param.is_empty():
		return false
	match type:
		Type.WIN_MATCHES, Type.PLAY_MATCHES:
			return param != MODE_MULTIPLAYER or StoryProgressStore.is_feature_unlocked(StoryFeatures.MULTIPLAYER)
		Type.AFFIX_STAMPS:
			# A codex holds one set: the set is asked for only with a codex of it to play.
			return param.is_empty() or _codex_stamps().any(func(stamp: Stamp) -> bool: return stamp.Set == param)
		Type.AFFIX_ROLE:
			return _codex_stamps().any(func(stamp: Stamp) -> bool: return _role_of(stamp) == param)
		Type.AFFIX_EFFECT:
			return _codex_stamps().any(func(stamp: Stamp) -> bool: return _effect_of(stamp) == param)
		Type.AFFIX_SPECIFIC, Type.WIN_WITH_STAMP:
			return _codex_stamps().any(func(stamp: Stamp) -> bool: return stamp.stamp_name == param)
		Type.CAPTURE_PIECES:
			return param.is_empty() or _codex_stamps().any(func(stamp: Stamp) -> bool: return stamp.stamp_name == param)
		Type.CODEX_WITH_STAMP:
			return StoryProgressStore.is_feature_unlocked(StoryFeatures.COLLECTION) and _free_copies_of(param) >= count
		Type.BUY_PACKS:
			return StoryProgressStore.is_feature_unlocked(StoryFeatures.BUY_PACKS)
		Type.LIST_LOTS:
			return StoryProgressStore.is_feature_unlocked(StoryFeatures.TRADE) and BourseStore.get_free_slot_count() > 0
		Type.SELL_LOTS, Type.BUY_LOTS:
			return StoryProgressStore.is_feature_unlocked(StoryFeatures.TRADE)
		Type.SOLVE_PUZZLES:
			return StoryProgressStore.is_feature_unlocked(StoryFeatures.PUZZLES) and _unsolved_puzzle_count() >= count
	return true

## The XY values a type that needs one can take from where the player stands,
## for a template that names none.
static func dynamic_params(type: int) -> Array[String]:
	var values: Array[String] = []
	match type:
		Type.AFFIX_ROLE:
			for stamp in _codex_stamps():
				var role: String = _role_of(stamp)
				if role != ROLE_UNIT and !values.has(role):
					values.append(role)
		Type.AFFIX_EFFECT:
			for stamp in _codex_stamps():
				var effect: String = _effect_of(stamp)
				if EFFECTS.has(effect) and !values.has(effect):
					values.append(effect)
		Type.AFFIX_SPECIFIC, Type.WIN_WITH_STAMP:
			for stamp in _codex_stamps():
				if !values.has(stamp.stamp_name):
					values.append(stamp.stamp_name)
		Type.CODEX_WITH_STAMP:
			# A stamp the player owns and has in no codex: a nudge to try it.
			var in_codexes: Dictionary = {}
			for deck in PlayerDeckStore.list_decks():
				for stamp_name in PlayerDeckStore.get_stamp_names_from_deck(deck):
					in_codexes[stamp_name] = true
			for item in PlayerCollectionStore.list_items():
				var stamp_name: String = str(item.get("stamp_name", ""))
				if !stamp_name.is_empty() and !in_codexes.has(stamp_name) and !values.has(stamp_name):
					values.append(stamp_name)
	return values

## What {param} shows in a quest's text: a translation key or a name.
static func param_label(type: int, param: String) -> String:
	match type:
		Type.WIN_MATCHES, Type.PLAY_MATCHES:
			return str(MODE_LABELS.get(param, param))
		Type.OPEN_SCREEN:
			return str(SCREEN_LABELS.get(param, param))
		Type.AFFIX_EFFECT:
			return "QUEST_EFFECT_%s" % param.to_upper()
	return param

## The type's own title and text, for a quest that does not bring its own:
## QUEST_<ID>_TITLE / _TEXT, the text QUEST_<ID>_PARAM_TEXT when a param narrows
## it down. Each may have a _ONE form for a count of one (pick_count_form).
static func default_title(type: int) -> String:
	return "QUEST_%s_TITLE" % id_of(type).to_upper()

static func default_text(type: int, param: String) -> String:
	if type != Type.OPEN_SCREEN and (needs_param(type) or !param.is_empty()):
		return "QUEST_%s_PARAM_TEXT" % id_of(type).to_upper()
	return "QUEST_%s_TEXT" % id_of(type).to_upper()

## A key's _ONE form for a count of one ("Win a match" for "Win 1 matches"),
## when the language files have it.
static func pick_count_form(key: String, count: int) -> String:
	if count != 1:
		return key
	var one_key: String = key + "_ONE"
	return one_key if TranslationServer.translate(one_key) != one_key else key

static func _mode_matches(param: String, data: Dictionary) -> bool:
	match param:
		MODE_SINGLEPLAYER:
			return bool(data.get("singleplayer", false))
		MODE_MULTIPLAYER:
			return !bool(data.get("singleplayer", false))
	return true

static func _stamp(data: Dictionary) -> Stamp:
	return StampLibrary.get_stamp(str(data.get("stamp_name", "")))

static func _set_of(stamp: Stamp) -> String:
	return stamp.Set if stamp != null else ""

static func _role_of(stamp: Stamp) -> String:
	if stamp == null or stamp.role < 0 or stamp.role >= ROLES.size():
		return ""
	return ROLES[stamp.role]

static func _effect_of(stamp: Stamp) -> String:
	return stamp.effect_type if stamp != null else ""

## Every stamp in the player's playable codexes, once each.
static func _codex_stamps() -> Array[Stamp]:
	var stamps: Array[Stamp] = []
	var seen: Dictionary = {}
	for deck in PlayerDeckStore.list_playable_decks():
		for stamp_name in PlayerDeckStore.get_stamp_names_from_deck(deck):
			if seen.has(stamp_name):
				continue
			seen[stamp_name] = true
			var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
			if stamp != null:
				stamps.append(stamp)
	return stamps

## Free copies of a stamp, all its prints together.
static func _free_copies_of(stamp_name: String) -> int:
	var free: int = 0
	var seen_prints: Dictionary = {}
	for item in PlayerCollectionStore.list_items():
		var print_id: String = str(item.get("print_id", ""))
		if str(item.get("stamp_name", "")) != stamp_name or seen_prints.has(print_id):
			continue
		seen_prints[print_id] = true
		free += PlayerCollectionStore.get_free_count_for_print_id(print_id)
	return free

static func _unsolved_puzzle_count() -> int:
	var unsolved: int = 0
	for puzzle in PuzzleLibrary.get_puzzles():
		if !PuzzleStore.is_solved(puzzle.puzzle_id):
			unsolved += 1
	return unsolved
