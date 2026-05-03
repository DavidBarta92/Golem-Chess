extends Node

var all_cards: Dictionary = {}  # card_code -> Card resource

func _ready():
	load_all_cards()
	print("CardLibrary loaded: %d cards" % all_cards.size())

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
					print("  Loaded: %s (duration: %d)" % [card.card_name, card.duration])
		file_name = dir.get_next()

	dir.list_dir_end()

func get_card(card_name: String) -> Card:
	return all_cards.get(card_name)

func get_card_by_code(card_code: String) -> Card:
	if card_code.is_empty():
		return null

	for card_value in all_cards.values():
		if card_value is Card:
			var card := card_value as Card
			if card.card_code == card_code:
				return card
	return null

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
