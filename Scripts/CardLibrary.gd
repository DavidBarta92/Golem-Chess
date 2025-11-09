extends Node

var all_cards: Dictionary = {}  # card_name -> Card resource

func _ready():
	load_all_cards()
	print("📚 CardLibrary betöltve: %d kártya" % all_cards.size())

func load_all_cards():
	var cards_path = "res://Cards/"
	var dir = DirAccess.open(cards_path)
	
	if dir == null:
		push_error("❌ Nem található a Cards mappa!")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card_path = cards_path + file_name
			var card = load(card_path) as Card
			if card:
				all_cards[card.card_name] = card
				print("  ✓ Betöltve: %s (duration: %d)" % [card.card_name, card.duration])
		file_name = dir.get_next()
	
	dir.list_dir_end()

func get_card(card_name: String) -> Card:
	return all_cards.get(card_name)

func get_all_card_names() -> Array:
	return all_cards.keys()

func duplicate_card(card_name: String) -> Card:
	var original = get_card(card_name)
	if original:
		return original.duplicate()
	return null
