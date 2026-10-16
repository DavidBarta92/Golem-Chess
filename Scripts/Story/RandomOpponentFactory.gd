extends RefCounted
class_name RandomOpponentFactory

## Builds a throwaway opponent for the story's filler matches: a random name
## from the pools in Data/random_opponent_names.json, a generated face, and a
## random single-set deck from the Decks/ database.
##
## Everything comes back in the same shape GameConfig.set_ai_opponent_override
## takes, so a random opponent and a boss go into the match the same way.

const NAMES_PATH: String = "res://Data/random_opponent_names.json"
const FALLBACK_SURNAMES: Array[String] = ["Kovács", "Nagy", "Szabó"]
const FALLBACK_GIVEN_NAMES: Array[String] = ["Anna", "Péter", "Réka"]

static var _surnames: Array[String] = []
static var _given_names: Array[String] = []
static var _names_loaded: bool = false

## `seed` makes the whole opponent reproducible (name, face and deck together);
## pass 0 for a fresh one every call.
static func create(difficulty_level: int, seed: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed != 0:
		rng.seed = seed
	else:
		rng.randomize()

	_ensure_names_loaded()
	var opponent_name: String = "%s %s" % [_pick(rng, _surnames), _pick(rng, _given_names)]

	var portrait: PortraitConfig = PortraitLibrary.create_random_portrait(int(rng.randi()))
	portrait.display_name = opponent_name

	var deck: DeckDefinition = DeckDefinitionLibrary.pick_random_deck(rng)
	var deck_stamp_names: Array[String] = deck.get_stamp_names() if deck != null else DeckManager.create_starting_deck()

	return {
		"name": opponent_name,
		"portrait_data": portrait.to_dict(),
		"deck_id": deck.deck_id if deck != null else "",
		"deck_stamp_names": deck_stamp_names,
		"difficulty_level": GameConfig.clamp_ai_difficulty_level(difficulty_level),
	}

static func _ensure_names_loaded() -> void:
	if _names_loaded:
		return
	_names_loaded = true
	_surnames.assign(FALLBACK_SURNAMES)
	_given_names.assign(FALLBACK_GIVEN_NAMES)

	if !FileAccess.file_exists(NAMES_PATH):
		push_warning("RandomOpponentFactory: %s is missing; using fallback names." % NAMES_PATH)
		return
	var file := FileAccess.open(NAMES_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file = null
	if !(parsed is Dictionary):
		return

	var surnames: Array[String] = _string_list(parsed.get("surnames", []))
	var given_names: Array[String] = _string_list(parsed.get("given_names", []))
	if !surnames.is_empty():
		_surnames = surnames
	if !given_names.is_empty():
		_given_names = given_names

static func _string_list(raw_value) -> Array[String]:
	var output: Array[String] = []
	if !(raw_value is Array):
		return output
	for value in raw_value:
		var text: String = str(value).strip_edges()
		if !text.is_empty():
			output.append(text)
	return output

static func _pick(rng: RandomNumberGenerator, options: Array[String]) -> String:
	if options.is_empty():
		return ""
	return options[rng.randi_range(0, options.size() - 1)]
