class_name DeckManager

const DECK_SIZE = 15
const HAND_SIZE = 3
const STARTING_HAND_SIZE = 3
const CODEX_PAGE_COUNT = 5
const CODEX_STAMPS_PER_PAGE = 3
const DEFAULT_SEEKER_CARD_NAME = "Prince"
const RANDOM_DATABASE_EXCLUDED_CARD_NAMES: Array[String] = [
	"Training Seal",
	"Test_001",
]
const STARTING_DECK: Array[String] = [
	"Numero_1",
	"Numero_2",
	"Numero_3",
	"Numero_4",
	"Numero_5",
	"Numero_6",
	"Numero_7",
	DEFAULT_SEEKER_CARD_NAME,
	"Rajah",
	"Khan",
	"Debater",
	"Numero_1",
	"Numero_2",
	"Numero_3",
	"Numero_4"
]

static func create_starting_deck() -> Array[String]:
	var deck: Array[String] = []
	deck.assign(STARTING_DECK)
	DebugLog.info("Codex created: %s" % [deck])
	return deck

static func create_random_database_deck() -> Array[String]:
	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()

	var seeker_names: Array[String] = get_database_card_names_by_seeker_role(true)
	var non_seeker_names: Array[String] = get_database_card_names_by_seeker_role(false)
	if seeker_names.is_empty() or non_seeker_names.is_empty():
		return create_starting_deck()

	seeker_names.shuffle()
	var deck: Array[String] = []
	deck.append(seeker_names[0])
	var remaining_cards: Array[String] = []
	remaining_cards.assign(non_seeker_names)
	remaining_cards.shuffle()

	while deck.size() < DECK_SIZE:
		if remaining_cards.is_empty():
			remaining_cards.assign(non_seeker_names)
			remaining_cards.shuffle()
		deck.append(str(remaining_cards.pop_front()))

	deck.shuffle()
	DebugLog.info("Random database codex created: %s" % [deck])
	return deck

static func create_codex_pages(card_names: Array) -> Array:
	var pages: Array = []
	var card_index: int = 0
	for page_index in range(CODEX_PAGE_COUNT):
		var page: Array[String] = []
		for _slot_index in range(CODEX_STAMPS_PER_PAGE):
			if card_index >= card_names.size():
				break
			page.append(str(card_names[card_index]))
			card_index += 1
		pages.append(page)
	return pages

static func flatten_codex_pages(pages: Array, excluded_page_index: int = -1) -> Array[String]:
	var card_names: Array[String] = []
	for page_index in range(pages.size()):
		if page_index == excluded_page_index:
			continue
		var page = pages[page_index]
		if !(page is Array):
			continue
		for card_name_value in page:
			card_names.append(str(card_name_value))
	return card_names

static func get_database_card_names_by_seeker_role(wants_seeker: bool) -> Array[String]:
	var card_names: Array[String] = []
	for card_value in CardLibrary.all_cards.values():
		var card: Card = card_value as Card
		if card == null:
			continue
		if RANDOM_DATABASE_EXCLUDED_CARD_NAMES.has(card.card_name):
			continue
		if !MoveRules.card_can_be_used(card):
			continue
		if MoveRules.is_seeker_card(card) == wants_seeker:
			card_names.append(card.card_name)
	card_names.sort()
	return card_names

static func draw_card(deck: Array, hand: Array) -> bool:
	if deck.is_empty():
		DebugLog.info("Deck is empty, cannot draw.")
		return false

	if hand.size() >= HAND_SIZE:
		DebugLog.info("Hand is full.")
		return false

	var drawn_card: String = deck.pop_front()
	hand.append(drawn_card)
	DebugLog.info("Card drawn: %s (deck: %d, hand: %d)" % [drawn_card, deck.size(), hand.size()])
	return true

static func draw_starting_hand(deck: Array, hand: Array):
	while hand.size() < STARTING_HAND_SIZE:
		if !draw_card(deck, hand):
			return

static func play_card(hand: Array, card_name: String, _deck: Array) -> bool:
	var index: int = hand.find(card_name)
	if index == -1:
		DebugLog.info("Card is not in hand: %s" % card_name)
		return false

	hand.remove_at(index)
	DebugLog.info("Card played: %s" % card_name)
	return true

static func return_card_to_deck(deck: Array, card_name: String):
	deck.append(card_name)
	DebugLog.info("Card returned to deck: %s" % card_name)

static func find_seeker_card_index(deck: Array) -> int:
	for i in deck.size():
		if is_seeker_card_name(deck[i]):
			return i
	return -1

static func is_seeker_card_name(card_name: String) -> bool:
	var card: Card = CardLibrary.get_card(card_name)
	return MoveRules.is_seeker_card(card)

static func has_seeker_card(card_names: Array) -> bool:
	for card_name_value in card_names:
		if is_seeker_card_name(str(card_name_value)):
			return true
	return false
