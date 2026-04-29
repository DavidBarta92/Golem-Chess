class_name DeckManager

const DECK_SIZE = 15
const HAND_SIZE = 5
const STARTING_HAND_SIZE = 3
const KING_CARD_NAME = "King"
const STARTING_DECK: Array[String] = [
	"Rook", "Rook", "Rook",
	"Bishop", "Bishop", "Bishop",
	KING_CARD_NAME,
	"Knight", "Knight", "Knight",
	"Pawn", "Pawn", "Pawn", "Pawn", "Pawn"
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
	var king_index: int = deck.find(KING_CARD_NAME)
	if king_index != -1 && hand.size() < HAND_SIZE:
		deck.remove_at(king_index)
		hand.append(KING_CARD_NAME)

	while hand.size() < STARTING_HAND_SIZE:
		if !draw_card(deck, hand):
			return

static func play_card(hand: Array[String], card_name: String, deck: Array[String]) -> bool:
	var index: int = hand.find(card_name)
	if index == -1:
		print("Card is not in hand: %s" % card_name)
		return false

	hand.remove_at(index)
	print("Card played: %s" % card_name)
	draw_card(deck, hand)
	return true

static func return_card_to_deck(deck: Array[String], card_name: String):
	deck.append(card_name)
	print("Card returned to deck: %s" % card_name)
