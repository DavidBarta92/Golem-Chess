extends Node

var all_cards: Dictionary = {}  # card_code -> Card resource

const CARD_CODE_ALIASES: Dictionary = {
	"grandmaster": "architect",
	"scholar": "logician",
	"jester": "debater",
	"oracle": "advocate",
	"bard": "mediator",
	"herald": "protagonist",
	"traveler": "campaigner",
	"steward": "logistician",
	"guardian": "defender",
	"marshal": "executive",
	"councillor": "consul",
	"craftsman": "virtuoso",
	"ranger": "adventurer",
	"scout": "entrepreneur",
	"troubadour": "entertainer",
}

const CARD_NAME_ALIASES: Dictionary = {
	"grandmaster": "Architect",
	"scholar": "Logician",
	"jester": "Debater",
	"oracle": "Advocate",
	"bard": "Mediator",
	"herald": "Protagonist",
	"traveler": "Campaigner",
	"steward": "Logistician",
	"guardian": "Defender",
	"marshal": "Executive",
	"councillor": "Consul",
	"craftsman": "Virtuoso",
	"ranger": "Adventurer",
	"scout": "Entrepreneur",
	"troubadour": "Entertainer",
}

func _ready():
	load_all_cards()
	DebugLog.info("CardLibrary loaded: %d cards" % all_cards.size())

func load_all_cards():
	all_cards.clear()
	var cards_path: String = "res://Cards/"
	var dir: DirAccess = DirAccess.open(cards_path)

	if dir == null:
		push_error("Cards folder not found.")
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if !dir.current_is_dir():
			var resource_file_name: String = file_name.trim_suffix(".remap")
			if resource_file_name.ends_with(".tres"):
				var card_path: String = cards_path + resource_file_name
				var card: Card = load(card_path) as Card
				if card:
					all_cards[card.card_name] = card
					DebugLog.info("  Loaded: %s (duration: %d)" % [card.card_name, card.duration])
		file_name = dir.get_next()

	dir.list_dir_end()

func get_card(card_name: String) -> Card:
	var normalized_name: String = card_name.strip_edges()
	if normalized_name.is_empty():
		return null

	var card: Card = all_cards.get(normalized_name)
	if card != null:
		return card

	var alias_name: String = resolve_card_name_alias(normalized_name)
	if alias_name != normalized_name:
		card = all_cards.get(alias_name)
		if card != null:
			return card

	return get_card_by_code(normalized_name)

func get_card_by_code(card_code: String) -> Card:
	var normalized_card_code: String = resolve_card_code_alias(card_code)
	if normalized_card_code.is_empty():
		return null

	for card_value in all_cards.values():
		if card_value is Card:
			var card := card_value as Card
			if resolve_card_code_alias(card.card_code) == normalized_card_code:
				return card
	return null

func resolve_card_code_alias(card_code: String) -> String:
	var normalized_card_code: String = card_code.strip_edges().to_lower()
	if normalized_card_code.is_empty():
		return ""
	return str(CARD_CODE_ALIASES.get(normalized_card_code, normalized_card_code))

func resolve_card_name_alias(card_name: String) -> String:
	var normalized_name: String = card_name.strip_edges()
	if normalized_name.is_empty():
		return ""
	return str(CARD_NAME_ALIASES.get(normalized_name.to_lower(), normalized_name))

func get_all_card_names() -> Array:
	return all_cards.keys()

func get_all_card_codes() -> Array:
	var card_codes: Array = []
	for card_value in all_cards.values():
		if card_value is Card:
			var card := card_value as Card
			var card_code := card.card_code.strip_edges()
			card_codes.append(card_code if !card_code.is_empty() else card.card_name)
	return card_codes

func duplicate_card(card_name: String) -> Card:
	var original = get_card(card_name)
	if original:
		return original.duplicate()
	return null
