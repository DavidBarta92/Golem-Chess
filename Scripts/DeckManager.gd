class_name DeckManager

const DECK_SIZE = 15
const HAND_SIZE = 3
const STARTING_HAND_SIZE = 3
const DEFAULT_NEXUS_CARD_NAME = "Prince"
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
	print("Deck created: ", deck)
	return deck

static func draw_card(deck: Array, hand: Array) -> bool:
	if deck.is_empty():
		print("Deck is empty, cannot draw.")
		return false

	if hand.size() >= HAND_SIZE:
		print("Hand is full.")
		return false

	var drawn_card: String = deck.pop_front()
	hand.append(drawn_card)
	print("Card drawn: %s (deck: %d, hand: %d)" % [drawn_card, deck.size(), hand.size()])
	return true

static func draw_starting_hand(deck: Array, hand: Array):
	while hand.size() < STARTING_HAND_SIZE:
		if !draw_card(deck, hand):
			return

static func play_card(hand: Array, card_name: String, _deck: Array) -> bool:
	var index: int = hand.find(card_name)
	if index == -1:
		print("Card is not in hand: %s" % card_name)
		return false

	hand.remove_at(index)
	print("Card played: %s" % card_name)
	return true

static func return_card_to_deck(deck: Array, card_name: String):
	deck.append(card_name)
	print("Card returned to deck: %s" % card_name)

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
