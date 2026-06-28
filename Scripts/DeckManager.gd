class_name DeckManager

const DECK_SIZE = 15
const HAND_SIZE = 3
const STARTING_HAND_SIZE = 3
const CODEX_PAGE_COUNT = 5
const CODEX_STAMPS_PER_PAGE = 3
const DEFAULT_SEEKER_STAMP_NAME = "Prince"
const RANDOM_DATABASE_EXCLUDED_STAMP_NAMES: Array[String] = [
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
	DEFAULT_SEEKER_STAMP_NAME,
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
	if StampLibrary.all_stamps.is_empty():
		StampLibrary.load_all_stamps()

	var seeker_names: Array[String] = get_database_stamp_names_by_seeker_role(true)
	var non_seeker_names: Array[String] = get_database_stamp_names_by_seeker_role(false)
	if seeker_names.is_empty() or non_seeker_names.is_empty():
		return create_starting_deck()

	seeker_names.shuffle()
	var deck: Array[String] = []
	deck.append(seeker_names[0])
	var remaining_stamps: Array[String] = []
	remaining_stamps.assign(non_seeker_names)
	remaining_stamps.shuffle()

	while deck.size() < DECK_SIZE:
		if remaining_stamps.is_empty():
			remaining_stamps.assign(non_seeker_names)
			remaining_stamps.shuffle()
		deck.append(str(remaining_stamps.pop_front()))

	deck.shuffle()
	DebugLog.info("Random database codex created: %s" % [deck])
	return deck

static func create_codex_pages(stamp_names: Array) -> Array:
	var pages: Array = []
	var stamp_index: int = 0
	for page_index in range(CODEX_PAGE_COUNT):
		var page: Array[String] = []
		for _slot_index in range(CODEX_STAMPS_PER_PAGE):
			if stamp_index >= stamp_names.size():
				break
			page.append(str(stamp_names[stamp_index]))
			stamp_index += 1
		pages.append(page)
	return pages

static func flatten_codex_pages(pages: Array, excluded_page_index: int = -1) -> Array[String]:
	var stamp_names: Array[String] = []
	for page_index in range(pages.size()):
		if page_index == excluded_page_index:
			continue
		var page = pages[page_index]
		if !(page is Array):
			continue
		for stamp_name_value in page:
			stamp_names.append(str(stamp_name_value))
	return stamp_names

static func get_database_stamp_names_by_seeker_role(wants_seeker: bool) -> Array[String]:
	var stamp_names: Array[String] = []
	for stamp_value in StampLibrary.all_stamps.values():
		var stamp: Stamp = stamp_value as Stamp
		if stamp == null:
			continue
		if RANDOM_DATABASE_EXCLUDED_STAMP_NAMES.has(stamp.stamp_name):
			continue
		if !MoveRules.stamp_can_be_used(stamp):
			continue
		if MoveRules.is_seeker_stamp(stamp) == wants_seeker:
			stamp_names.append(stamp.stamp_name)
	stamp_names.sort()
	return stamp_names

static func draw_stamp(deck: Array, hand: Array) -> bool:
	if deck.is_empty():
		DebugLog.info("Deck is empty, cannot draw.")
		return false

	if hand.size() >= HAND_SIZE:
		DebugLog.info("Hand is full.")
		return false

	var drawn_stamp: String = deck.pop_front()
	hand.append(drawn_stamp)
	DebugLog.info("Stamp drawn: %s (deck: %d, hand: %d)" % [drawn_stamp, deck.size(), hand.size()])
	return true

static func draw_starting_hand(deck: Array, hand: Array):
	while hand.size() < STARTING_HAND_SIZE:
		if !draw_stamp(deck, hand):
			return

static func play_stamp(hand: Array, stamp_name: String, _deck: Array) -> bool:
	var index: int = hand.find(stamp_name)
	if index == -1:
		DebugLog.info("Stamp is not in hand: %s" % stamp_name)
		return false

	hand.remove_at(index)
	DebugLog.info("Stamp played: %s" % stamp_name)
	return true

static func return_stamp_to_deck(deck: Array, stamp_name: String):
	deck.append(stamp_name)
	DebugLog.info("Stamp returned to deck: %s" % stamp_name)

static func find_seeker_stamp_index(deck: Array) -> int:
	for i in deck.size():
		if is_seeker_stamp_name(deck[i]):
			return i
	return -1

static func is_seeker_stamp_name(stamp_name: String) -> bool:
	var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
	return MoveRules.is_seeker_stamp(stamp)

static func has_seeker_stamp(stamp_names: Array) -> bool:
	for stamp_name_value in stamp_names:
		if is_seeker_stamp_name(str(stamp_name_value)):
			return true
	return false
