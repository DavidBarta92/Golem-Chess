extends Node

var all_cards: Dictionary = {}  # card_code -> Card resource

func _ready():
	load_all_cards()
	print("đź“š CardLibrary betĂ¶ltve: %d kĂˇrtya" % all_cards.size())

func load_all_cards():
	all_cards.clear()
	var cards_path: String = "res://Cards/"
	var dir: DirAccess = DirAccess.open(cards_path)

	if dir == null:
		push_error("âťŚ Nem talĂˇlhatĂł a Cards mappa!")
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
					print("  âś“ BetĂ¶ltve: %s (duration: %d)" % [card.card_name, card.duration])
		file_name = dir.get_next()

	dir.list_dir_end()

func get_card(card_name: String) -> Card:
	return all_cards.get(card_name)

func get_all_card_names() -> Array:
	return all_cards.keys()

func get_all_card_codes() -> Array:
	return all_cards.keys()

func duplicate_card(card_name: String) -> Card:
	var original = get_card(card_name)
	if original:
		return original.duplicate()
	return null
