@tool
extends Resource
class_name BossDefinition

## One story opponent, fully authored in the inspector.
##
## Everything a boss match needs lives here: who the opponent is, what they
## look like, what they play with and how hard they think. Save one .tres per
## boss under Story/Bosses/ and point a BossGameStoryNode at it.
##
## The deck is a list of Stamp resources rather than a saved deck id on
## purpose: a boss must not depend on the player's own decks or on which
## stamps the player happens to own.

@export var boss_id: String = ""

## Shown in the match HUD.
@export var display_name: String = ""

## Off: `display_name` is literal text, used exactly as typed - the right
## choice for a proper name that should read the same in every language.
## On: `display_name` is a translation key looked up in the language files
## (Localization/translations.csv), e.g. "BOSS_01_NAME".
@export var localize_display_name: bool = false

## Built with the same part/colour system as the player portrait, so it
## blinks, breathes and looks around in the match like any other portrait.
## Left empty, the boss falls back to a generated face, so an unfinished boss
## is still playable - tick "Fill portrait from generator" below to turn that
## generated face into a real resource you can then edit part by part.
@export var portrait: PortraitConfig

## Inspector button: seeds `portrait` with a generated face (or re-rolls the
## one that is there) so there is something concrete to start editing.
@export var fill_portrait_from_generator: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_fill_portrait_from_generator()
	get:
		return false

## Drag stamp .tres files in from Stamps/. Order matters - the match deals
## from the top of this list, so the opening hand is the first entries.
## Leave empty and the boss plays the fixed starting deck; either way it never
## depends on which decks the player has saved or which stamps they own.
@export var deck_stamps: Array[Stamp] = []

@export_range(1, 12, 1) var ai_difficulty_level: int = 1

@export_group("The room")
## Which room this boss is played in. KIOSK is the stall the game is normally
## played at; MEMORY is the remembered room, for an opponent the player is not
## really sitting across from.
@export var room_variant: MatchBackgroundController.Variant = MatchBackgroundController.Variant.KIOSK
## Off for an opponent who has no codex of their own on the table yet.
@export var show_opponent_codex: bool = true

@export_group("The match")
## Off for an early opponent the player meets before the clock is part of the
## game: it is not shown, and it does not run either, so there is no time to
## lose on.
@export var show_clock: bool = true

@export_group("Dialogue")
## On: every line below is a translation key looked up in the language files
## (e.g. "BOSS_01_INTRO_1"). Off: the lines are used as literal text, which is
## handy while prototyping before the keys exist.
@export var localize_lines: bool = true

## Variants spoken when the match opens; one is picked, and it is never the
## same one twice in a row.
@export var intro_lines: Array[String] = []
## Variants spoken when the *boss* wins, i.e. the player lost.
@export var victory_lines: Array[String] = []
## Variants spoken when the *boss* loses, i.e. the player won.
@export var defeat_lines: Array[String] = []

## In-match one-liners, one entry per trigger. See BossReaction for what can
## set one off and how often it is allowed to.
@export var reactions: Array[BossReaction] = []

@export_group("Music")
## Played as the match scene opens. Optional.
@export var music_cue_on_match_start: MusicCue
## Played when one of the defeat_lines appears - the boss's parting word after
## the player has won, spoken in the reward scene that follows. Optional.
@export var music_cue_on_defeat_line: MusicCue

## Index of the last line handed out per category, so the next pick can avoid
## repeating it. Not exported: per-session state, not authored data. It carries
## over between matches because Godot caches the loaded resource, so a boss
## does not greet the player with the same line two fights running.
var _last_line_indices: Dictionary = {}

# --- Dialogue ---------------------------------------------------------------

## Applies the language files only when this boss is set up to be localized,
## so a literal line can never be swallowed by a key that happens to match it.
func localize_line(text: String) -> String:
	var line_text: String = text.strip_edges()
	if line_text.is_empty():
		return ""
	return tr(line_text) if localize_lines else line_text

func pick_intro_line() -> String:
	return _pick_line("intro", intro_lines)

func pick_victory_line() -> String:
	return _pick_line("victory", victory_lines)

func pick_defeat_line() -> String:
	return _pick_line("defeat", defeat_lines)

## Every reaction registered for a trigger. More than one entry per trigger is
## allowed - the stamp_played trigger relies on it, one entry per stamp.
func get_reactions_for_trigger(trigger: String) -> Array[BossReaction]:
	var matches: Array[BossReaction] = []
	for reaction in reactions:
		if reaction != null and reaction.trigger == trigger and reaction.has_lines():
			matches.append(reaction)
	return matches

## The reaction bound to a specific stamp, or null when the boss has nothing
## to say about it.
func get_stamp_reaction(stamp_name: String) -> BossReaction:
	for reaction in get_reactions_for_trigger(BossReaction.TRIGGER_STAMP_PLAYED):
		if reaction.matches_stamp(stamp_name):
			return reaction
	return null

## Picks a variant, avoiding the one used last time, and localizes it.
## Returns "" when nothing is authored for that category yet.
func _pick_line(bag_key: String, raw_lines: Array[String]) -> String:
	var usable_lines: Array[String] = []
	for line in raw_lines:
		var line_text: String = str(line).strip_edges()
		if !line_text.is_empty():
			usable_lines.append(line_text)

	if usable_lines.is_empty():
		return ""
	if usable_lines.size() == 1:
		_last_line_indices[bag_key] = 0
		return localize_line(usable_lines[0])

	var last_index: int = int(_last_line_indices.get(bag_key, -1))
	var index: int = randi() % usable_lines.size()
	if index == last_index:
		index = (index + 1 + randi() % (usable_lines.size() - 1)) % usable_lines.size()
	_last_line_indices[bag_key] = index
	return localize_line(usable_lines[index])

# --- Deck -------------------------------------------------------------------

## Deck as plain stamp names, which is the format the match layer speaks.
## Never returns an empty list: an unfinished boss falls back to the fixed
## starting deck rather than to whatever the player happens to have saved.
func get_deck_stamp_names() -> Array[String]:
	var stamp_names: Array[String] = get_authored_deck_stamp_names()
	return stamp_names if !stamp_names.is_empty() else DeckManager.create_starting_deck()

func get_authored_deck_stamp_names() -> Array[String]:
	var stamp_names: Array[String] = []
	for stamp in deck_stamps:
		if stamp == null:
			continue
		var stamp_name: String = str(stamp.stamp_name).strip_edges()
		if stamp_name.is_empty():
			continue
		stamp_names.append(stamp_name)
	return stamp_names

func has_custom_deck() -> bool:
	return !get_authored_deck_stamp_names().is_empty()

## The raw authored name, falling back to the id for an unnamed boss. Use this
## for editor labels and debug output, not for anything the player reads.
func get_display_name() -> String:
	var name_text: String = display_name.strip_edges()
	return name_text if !name_text.is_empty() else boss_id

## The name as the player sees it. Only bosses marked as localized go through
## the language files; everything else is passed through untouched, so a literal
## name can never be swallowed by a translation key that happens to match it.
func get_localized_display_name() -> String:
	var name_text: String = get_display_name()
	return tr(name_text) if localize_display_name else name_text

## Builds a concrete PortraitConfig from the generator and assigns it, giving
## the inspector something real to edit instead of an empty slot. Seeded from
## boss_id so the same boss keeps the same starting face across re-rolls.
func _fill_portrait_from_generator() -> void:
	var id_text: String = boss_id.strip_edges()
	var seed_value: int = absi(hash(id_text)) if !id_text.is_empty() else int(Time.get_unix_time_from_system())
	var generated: PortraitConfig = PortraitLibrary.create_random_portrait(seed_value)
	generated.portrait_id = id_text if !id_text.is_empty() else generated.portrait_id
	generated.display_name = get_display_name()
	portrait = generated
	emit_changed()
	notify_property_list_changed()

## Portrait as the dictionary form the match/network layer passes around.
## Falls back to a generated story portrait when none was authored yet, so an
## unfinished boss still shows a face instead of crashing.
func get_portrait_data(fallback_index: int = 1) -> Dictionary:
	if portrait != null:
		return portrait.to_dict()
	return PortraitLibrary.get_story_portrait(fallback_index).to_dict()
