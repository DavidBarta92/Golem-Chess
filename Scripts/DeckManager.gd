class_name DeckManager

const DECK_SIZE = 15
const HAND_SIZE = 3
const STARTING_HAND_SIZE = 3
const DEFAULT_NEXUS_CARD_NAME = "Prince"
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
	DEFAULT_NEXUS_CARD_NAME,
	"Rajah",
	"Khan",
	"Jester",
	"Numero_1",
	"Numero_2",
	"Numero_3",
	"Numero_4"
]

static func create_starting_deck() -> Array[String]:
	var deck: Array[String] = []
	deck.assign(STARTING_DECK)
	deck.shuffle()
	DebugLog.info("Deck created: %s" % [deck])
	return deck

static func create_random_database_deck() -> Array[String]:
	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()

	var nexus_names: Array[String] = get_database_card_names_by_nexus_role(true)
	var non_nexus_names: Array[String] = get_database_card_names_by_nexus_role(false)
	if nexus_names.is_empty() or non_nexus_names.is_empty():
		return create_starting_deck()

	nexus_names.shuffle()
	var deck: Array[String] = []
	deck.append(nexus_names[0])
	var remaining_cards: Array[String] = []
	remaining_cards.assign(non_nexus_names)
	remaining_cards.shuffle()

	while deck.size() < DECK_SIZE:
		if remaining_cards.is_empty():
			remaining_cards.assign(non_nexus_names)
			remaining_cards.shuffle()
		deck.append(str(remaining_cards.pop_front()))

	deck.shuffle()
	DebugLog.info("Random database deck created: %s" % [deck])
	return deck

static func get_database_card_names_by_nexus_role(wants_nexus: bool) -> Array[String]:
	var card_names: Array[String] = []
	for card_value in CardLibrary.all_cards.values():
		var card: Card = card_value as Card
		if card == null:
			continue
		if RANDOM_DATABASE_EXCLUDED_CARD_NAMES.has(card.card_name):
			continue
		if !MoveRules.card_can_be_used(card):
			continue
		if MoveRules.is_nexus_card(card) == wants_nexus:
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

static func find_nexus_card_index(deck: Array) -> int:
	for i in deck.size():
		if is_nexus_card_name(deck[i]):
			return i
	return -1

static func is_nexus_card_name(card_name: String) -> bool:
	var card: Card = CardLibrary.get_card(card_name)
	return MoveRules.is_nexus_card(card)

static func has_nexus_card(card_names: Array) -> bool:
	for card_name_value in card_names:
		if is_nexus_card_name(str(card_name_value)):
			return true
	return false
