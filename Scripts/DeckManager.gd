class_name DeckManager

const DECK_SIZE = 15
const HAND_SIZE = 5
const STARTING_HAND_SIZE = 3
const KING_CARD_NAME = "King"
const STARTING_DECK: Array[String] = [
	KING_CARD_NAME,
	"Scout",
	"Ranger",
	"Craftsman",
	"Troubadour",
	"Councillor",
	"Bard",
	"Commander",
	"Guardian",
	"Herald",
	"Marshal",
	"Oracle",
	"Scholar",
	"Steward",
	"Traveler"
]

static func create_starting_deck() -> Array[String]:
	var deck: Array[String] = []
	deck.assign(STARTING_DECK)
	deck.shuffle()
	print("Deck created: ", deck)
	return deck

static func draw_card(deck: Array[String], hand: Array[String]) -> bool:
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

static func draw_starting_hand(deck: Array[String], hand: Array[String]):
	var king_index: int = find_king_card_index(deck)
	if king_index != -1 && hand.size() < HAND_SIZE:
		var king_card_name: String = deck[king_index]
		deck.remove_at(king_index)
		hand.append(king_card_name)

	while hand.size() < STARTING_HAND_SIZE:
		if !draw_card(deck, hand):
			return

static func play_card(hand: Array[String], card_name: String, _deck: Array[String]) -> bool:
	var index: int = hand.find(card_name)
	if index == -1:
		print("Card is not in hand: %s" % card_name)
		return false

	hand.remove_at(index)
	print("Card played: %s" % card_name)
	return true

static func return_card_to_deck(deck: Array[String], card_name: String):
	deck.append(card_name)
	print("Card returned to deck: %s" % card_name)

static func find_king_card_index(deck: Array[String]) -> int:
	for i in deck.size():
		if is_king_card_name(deck[i]):
			return i
	return -1

static func is_king_card_name(card_name: String) -> bool:
	var card: Card = CardLibrary.get_card(card_name)
	return card != null && card.is_king_card

static func has_king_card(card_names: Array) -> bool:
	for card_name_value in card_names:
		if is_king_card_name(str(card_name_value)):
			return true
	return false
