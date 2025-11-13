# DeckManager.gd - Pakli kezelés
class_name DeckManager

const DECK_SIZE = 5
const HAND_SIZE = 2
const KING_CARD_NAME = "King"

# Kezdő pakli generálás
static func create_starting_deck() -> Array[String]:
	var deck: Array[String] = []
	
	# Király mindig az első
	deck.append(KING_CARD_NAME)
	
	# Többi kártya (most random a CardLibrary-ból)
	var available_cards = CardLibrary.get_all_card_names()
	available_cards.erase(KING_CARD_NAME)  # Király már benne van
	
	for i in range(DECK_SIZE - 1):
		if available_cards.size() > 0:
			var random_card = available_cards[randi() % available_cards.size()]
			deck.append(random_card)
		else:
			push_warning("Nincs elég kártya a paklihoz!")
			break
	
	print("📚 Pakli létrehozva: ", deck)
	return deck

# Húzás
static func draw_card(deck: Array[String], hand: Array[String]) -> bool:
	if deck.size() == 0:
		print("⚠️ Pakli üres, nem lehet húzni!")
		return false
	
	if hand.size() >= HAND_SIZE:
		print("⚠️ Kéz tele van!")
		return false
	
	var drawn_card = deck.pop_front()
	hand.append(drawn_card)
	print("🎴 Kártya húzva: %s (pakli: %d, kéz: %d)" % [drawn_card, deck.size(), hand.size()])
	return true

# Kezdő kéz húzása
static func draw_starting_hand(deck: Array[String], hand: Array[String]):
	for i in range(HAND_SIZE):
		draw_card(deck, hand)

# Kártya kijátszása
static func play_card(hand: Array[String], card_name: String, deck: Array[String]) -> bool:
	var index = hand.find(card_name)
	if index == -1:
		print("⚠️ Kártya nincs a kézben: %s" % card_name)
		return false
	
	hand.remove_at(index)
	print("♠️ Kártya kijátszva: %s" % card_name)
	
	# Húzunk újat ha van
	draw_card(deck, hand)
	return true

# Kártya visszakerül a pakli aljára
static func return_card_to_deck(deck: Array[String], card_name: String):
	deck.append(card_name)
	print("♻️ Kártya visszakerült a pakliba: %s" % card_name)
