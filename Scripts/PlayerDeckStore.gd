extends Node

const DECK_SCHEMA_VERSION: int = 2
const DECKS_PATH: String = "user://decks.json"
const LOCAL_PROVIDER: String = "local_json"
const MAX_DECK_SIZE: int = 15

var deck_data: Dictionary = {}
var is_loaded: bool = false

func ensure_loaded() -> void:
	if is_loaded:
		return

	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()
	CardPrintLibrary.ensure_loaded()

	if FileAccess.file_exists(DECKS_PATH):
		var file := FileAccess.open(DECKS_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			deck_data = _normalize_deck_data(parsed)
			is_loaded = true
			return

	deck_data = _create_empty_deck_data()
	is_loaded = true
	save_decks()

func list_decks() -> Array:
	ensure_loaded()
	return _get_decks().duplicate(true)

func get_deck(deck_id: String) -> Dictionary:
	ensure_loaded()
	for deck in _get_decks():
		if deck is Dictionary && str(deck.get("deck_id", "")) == deck_id:
			return deck.duplicate(true)
	return {}

func get_first_deck() -> Dictionary:
	ensure_loaded()
	var decks: Array = _get_decks()
	for deck in decks:
		if deck is Dictionary:
			return deck.duplicate(true)
	return {}

func list_playable_decks() -> Array:
	ensure_loaded()
	PlayerCollectionStore.ensure_loaded()

	var playable_decks: Array = []
	for deck in _get_decks():
		if deck is Dictionary && is_deck_playable(deck):
			playable_decks.append(deck.duplicate(true))
	return playable_decks

func get_first_playable_deck() -> Dictionary:
	ensure_loaded()
	var playable_decks: Array = list_playable_decks()
	if playable_decks.is_empty():
		return {}
	return playable_decks[0].duplicate(true)

func is_deck_playable_id(deck_id: String) -> bool:
	var deck: Dictionary = get_deck(deck_id)
	return !deck.is_empty() && is_deck_playable(deck)

func is_deck_playable(deck: Dictionary) -> bool:
	var ownership_info: Dictionary = get_deck_ownership_info(deck)
	return bool(ownership_info.get("is_playable", false))

func get_deck_ownership_info(deck: Dictionary) -> Dictionary:
	ensure_loaded()
	PlayerCollectionStore.ensure_loaded()

	var total_count: int = 0
	var owned_count: int = 0
	var duplicate_count: int = 0
	var missing_card_codes: Array[String] = []
	var seen_card_codes: Dictionary = {}
	var cards = deck.get("cards", [])
	if cards is Array:
		for deck_card in cards:
			var card_code: String = _get_deck_card_code(deck_card)
			if card_code.is_empty():
				continue

			total_count += 1
			if seen_card_codes.has(card_code):
				duplicate_count += 1
			else:
				seen_card_codes[card_code] = true

			if PlayerCollectionStore.owns_card_code(card_code):
				owned_count += 1
			else:
				missing_card_codes.append(card_code)

	var missing_count: int = missing_card_codes.size()
	return {
		"total_count": total_count,
		"owned_count": owned_count,
		"missing_count": missing_count,
		"duplicate_count": duplicate_count,
		"missing_card_codes": missing_card_codes,
		"is_collection_complete": missing_count == 0,
		"is_playable": total_count == MAX_DECK_SIZE && owned_count == MAX_DECK_SIZE && missing_count == 0 && duplicate_count == 0,
	}

func get_owned_cards_from_deck(deck: Dictionary) -> Array:
	ensure_loaded()
	PlayerCollectionStore.ensure_loaded()

	var owned_cards: Array = []
	var seen_card_codes: Dictionary = {}
	var cards = deck.get("cards", [])
	if !(cards is Array):
		return owned_cards

	for deck_card in cards:
		var normalized_card: Dictionary = {}
		if deck_card is Dictionary:
			normalized_card = _normalize_deck_card(deck_card, owned_cards.size())
		else:
			normalized_card = _create_legacy_deck_card(str(deck_card), owned_cards.size())

		var card_code: String = str(normalized_card.get("card_code", "")).strip_edges()
		if card_code.is_empty() or seen_card_codes.has(card_code):
			continue
		seen_card_codes[card_code] = true
		if !PlayerCollectionStore.owns_card_code(card_code):
			continue

		normalized_card["slot"] = owned_cards.size()
		owned_cards.append(normalized_card)
	return owned_cards

func get_deck_card_names(deck_id: String) -> Array[String]:
	var deck: Dictionary = get_deck(deck_id)
	if deck.is_empty():
		var empty_card_names: Array[String] = []
		return empty_card_names
	return get_card_names_from_deck(deck)

func get_card_names_from_deck(deck: Dictionary) -> Array[String]:
	var card_names: Array[String] = []
	var cards = deck.get("cards", [])
	if !(cards is Array):
		return card_names

	for deck_card in cards:
		var card_name: String = ""
		if deck_card is Dictionary:
			var card_print: CardPrint = CardPrintLibrary.get_print(str(deck_card.get("print_id", "")))
			if card_print != null:
				var card_from_print: Card = CardPrintLibrary.get_card_for_print(card_print)
				card_name = card_from_print.card_name if card_from_print != null else ""
			else:
				card_name = str(deck_card.get("card_name", ""))
			if card_name.is_empty():
				var card: Card = CardLibrary.get_card_by_code(str(deck_card.get("card_code", "")))
				card_name = card.card_name if card != null else ""
		else:
			card_name = str(deck_card)

		if !card_name.is_empty():
			card_names.append(card_name)

	return card_names

func save_new_deck(deck_name: String, cards: Array) -> Dictionary:
	ensure_loaded()

	var now := Time.get_datetime_string_from_system(true)
	var deck: Dictionary = {
		"deck_id": _generate_deck_id(),
		"provider": LOCAL_PROVIDER,
		"name": deck_name.strip_edges(),
		"cards": _normalize_deck_cards(cards),
		"created_at": now,
		"updated_at": now,
	}

	var decks: Array = _get_decks()
	decks.append(deck)
	deck_data["decks"] = decks
	save_decks()
	return deck.duplicate(true)

func save_existing_deck(deck_id: String, deck_name: String, cards: Array) -> bool:
	ensure_loaded()

	var decks: Array = _get_decks()
	for index in range(decks.size()):
		var deck = decks[index]
		if deck is Dictionary && str(deck.get("deck_id", "")) == deck_id:
			deck["name"] = deck_name.strip_edges()
			deck["cards"] = _normalize_deck_cards(cards)
			deck["updated_at"] = Time.get_datetime_string_from_system(true)
			decks[index] = deck
			deck_data["decks"] = decks
			return save_decks()
	return false

func delete_deck(deck_id: String) -> bool:
	ensure_loaded()

	var decks: Array = _get_decks()
	for index in range(decks.size()):
		var deck = decks[index]
		if deck is Dictionary && str(deck.get("deck_id", "")) == deck_id:
			decks.remove_at(index)
			deck_data["decks"] = decks
			return save_decks()
	return false

func save_decks() -> bool:
	ensure_loaded()

	var file := FileAccess.open(DECKS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save player decks to %s" % DECKS_PATH)
		return false

	file.store_string(JSON.stringify(deck_data, "\t"))
	return true

func _get_decks() -> Array:
	ensure_loaded()
	var decks = deck_data.get("decks", [])
	return decks if decks is Array else []

func _create_empty_deck_data() -> Dictionary:
	return {
		"schema_version": DECK_SCHEMA_VERSION,
		"provider": LOCAL_PROVIDER,
		"decks": [],
	}

func _normalize_deck_data(raw_data) -> Dictionary:
	if raw_data is Array:
		return _migrate_legacy_deck_array(raw_data)

	var normalized := _create_empty_deck_data()
	if !(raw_data is Dictionary):
		return normalized

	normalized["schema_version"] = int(raw_data.get("schema_version", DECK_SCHEMA_VERSION))
	normalized["provider"] = str(raw_data.get("provider", LOCAL_PROVIDER))

	var raw_decks = raw_data.get("decks", [])
	var normalized_decks: Array = []
	if raw_decks is Array:
		for raw_deck in raw_decks:
			if raw_deck is Dictionary:
				normalized_decks.append(_normalize_deck(raw_deck))

	normalized["decks"] = normalized_decks
	return normalized

func _migrate_legacy_deck_array(raw_decks: Array) -> Dictionary:
	var normalized := _create_empty_deck_data()
	var normalized_decks: Array = []
	for raw_deck in raw_decks:
		if raw_deck is Dictionary:
			normalized_decks.append(_normalize_deck(raw_deck))
	normalized["decks"] = normalized_decks
	return normalized

func _normalize_deck(raw_deck: Dictionary) -> Dictionary:
	var now := Time.get_datetime_string_from_system(true)
	return {
		"deck_id": str(raw_deck.get("deck_id", raw_deck.get("id", _generate_deck_id()))),
		"provider": str(raw_deck.get("provider", LOCAL_PROVIDER)),
		"name": str(raw_deck.get("name", "Unnamed deck")),
		"cards": _normalize_deck_cards(raw_deck.get("cards", [])),
		"created_at": str(raw_deck.get("created_at", now)),
		"updated_at": str(raw_deck.get("updated_at", now)),
	}

func _normalize_deck_cards(raw_cards) -> Array:
	var normalized_cards: Array = []
	if !(raw_cards is Array):
		return normalized_cards

	var used_card_codes: Dictionary = {}
	for index in range(raw_cards.size()):
		var raw_card = raw_cards[index]
		var normalized_card: Dictionary = {}
		if raw_card is Dictionary:
			normalized_card = _normalize_deck_card(raw_card, normalized_cards.size())
		else:
			normalized_card = _create_legacy_deck_card(str(raw_card), normalized_cards.size())

		var card_code: String = str(normalized_card.get("card_code", "")).strip_edges()
		if card_code.is_empty() or used_card_codes.has(card_code):
			continue

		used_card_codes[card_code] = true
		normalized_card["slot"] = normalized_cards.size()
		normalized_cards.append(normalized_card)
		if normalized_cards.size() >= MAX_DECK_SIZE:
			break

	return normalized_cards

func _normalize_deck_card(raw_card: Dictionary, index: int) -> Dictionary:
	var card_code: String = str(raw_card.get("card_code", ""))
	var card_name: String = str(raw_card.get("card_name", card_code))
	if card_code.is_empty():
		card_code = _get_card_code_for_name(card_name)
	var variant_id: String = CardPrintLibrary.normalize_variant_id(str(raw_card.get("variant_id", PlayerCollectionStore.DEFAULT_VARIANT_ID)))
	var print_id: String = str(raw_card.get("print_id", ""))
	if print_id.is_empty():
		print_id = PlayerCollectionStore.get_item_def_key(card_code, variant_id)
	var card_print: CardPrint = CardPrintLibrary.get_print(print_id)
	if card_print != null:
		card_code = card_print.card_code
		variant_id = card_print.variant_id
		var card_from_print: Card = CardPrintLibrary.get_card_for_print(card_print)
		if card_from_print != null:
			card_name = card_from_print.card_name

	return {
		"slot": int(raw_card.get("slot", index)),
		"print_id": print_id,
		"card_code": card_code,
		"card_name": card_name,
		"variant_id": variant_id,
		"variant_name": str(raw_card.get("variant_name", CardPrintLibrary.get_variant_name(variant_id))),
		"collection_instance_id": str(raw_card.get("collection_instance_id", raw_card.get("instance_id", ""))),
		"item_def_key": str(raw_card.get("item_def_key", print_id)),
		"steam_item_instance_id": str(raw_card.get("steam_item_instance_id", "")),
		"steam_item_def_id": str(raw_card.get("steam_item_def_id", "")),
	}

func _create_legacy_deck_card(card_name: String, index: int) -> Dictionary:
	var legacy_card_code: String = _get_card_code_for_name(card_name)
	return {
		"slot": index,
		"print_id": PlayerCollectionStore.get_item_def_key(legacy_card_code, PlayerCollectionStore.DEFAULT_VARIANT_ID),
		"card_code": legacy_card_code,
		"card_name": card_name,
		"variant_id": PlayerCollectionStore.DEFAULT_VARIANT_ID,
		"variant_name": PlayerCollectionStore.DEFAULT_VARIANT_NAME,
		"collection_instance_id": "",
		"item_def_key": PlayerCollectionStore.get_item_def_key(legacy_card_code, PlayerCollectionStore.DEFAULT_VARIANT_ID),
		"steam_item_instance_id": "",
		"steam_item_def_id": "",
	}

func _get_deck_card_code(deck_card) -> String:
	if deck_card is Dictionary:
		var print_id: String = str(deck_card.get("print_id", "")).strip_edges()
		if !print_id.is_empty():
			var card_print: CardPrint = CardPrintLibrary.get_print(print_id)
			if card_print != null:
				return card_print.card_code

		var card_code: String = str(deck_card.get("card_code", "")).strip_edges()
		if !card_code.is_empty():
			var card_by_code: Card = CardLibrary.get_card_by_code(card_code)
			return PlayerCollectionStore.get_card_code(card_by_code) if card_by_code != null else card_code

		return _get_card_code_for_name(str(deck_card.get("card_name", "")))

	return _get_card_code_for_name(str(deck_card))

func _generate_deck_id() -> String:
	return "local_deck_%d" % Time.get_ticks_usec()

func _get_card_code_for_name(card_name: String) -> String:
	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()

	var card: Card = CardLibrary.get_card(card_name)
	if card == null:
		return card_name
	return PlayerCollectionStore.get_card_code(card)
