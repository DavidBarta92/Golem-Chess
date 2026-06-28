extends Node

const DECK_SCHEMA_VERSION: int = 2
const DECKS_PATH: String = "user://decks.json"
const LOCAL_PROVIDER: String = "local_json"
const MAX_DECK_SIZE: int = 15
const MAX_COPIES_PER_STAMP: int = 2
const DEFAULT_DECK_ID: String = "default_new"
const DEFAULT_DECK_NAME: String = "New"

var deck_data: Dictionary = {}
var is_loaded: bool = false

func ensure_loaded() -> void:
	if is_loaded:
		return

	if StampLibrary.all_stamps.is_empty():
		StampLibrary.load_all_stamps()
	StampPrintLibrary.ensure_loaded()

	if FileAccess.file_exists(DECKS_PATH):
		var file := FileAccess.open(DECKS_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			deck_data = _normalize_deck_data(parsed)
			is_loaded = true
			if _ensure_default_deck_exists():
				save_decks()
			return

	deck_data = _create_empty_deck_data()
	is_loaded = true
	_ensure_default_deck_exists()
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

func get_default_deck() -> Dictionary:
	ensure_loaded()
	var default_deck: Dictionary = _find_default_deck()
	return default_deck.duplicate(true) if !default_deck.is_empty() else {}

func get_default_playable_deck() -> Dictionary:
	var default_deck: Dictionary = get_default_deck()
	if !default_deck.is_empty() && is_deck_playable(default_deck):
		return default_deck
	return get_first_playable_deck()

func get_default_playable_deck_id() -> String:
	var default_deck: Dictionary = get_default_playable_deck()
	return str(default_deck.get("deck_id", ""))

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
	var over_copy_limit_count: int = 0
	var missing_stamp_codes: Array[String] = []
	var stamp_counts: Dictionary = {}
	var stamps = deck.get("stamps", [])
	if stamps is Array:
		for deck_stamp in stamps:
			var stamp_code: String = _get_deck_stamp_code(deck_stamp)
			if stamp_code.is_empty():
				continue

			total_count += 1
			var next_count: int = int(stamp_counts.get(stamp_code, 0)) + 1
			stamp_counts[stamp_code] = next_count
			if next_count > MAX_COPIES_PER_STAMP:
				over_copy_limit_count += 1

			if PlayerCollectionStore.owns_stamp_code(stamp_code):
				owned_count += 1
			else:
				missing_stamp_codes.append(stamp_code)

	var missing_count: int = missing_stamp_codes.size()
	return {
		"total_count": total_count,
		"owned_count": owned_count,
		"missing_count": missing_count,
		"duplicate_count": over_copy_limit_count,
		"over_copy_limit_count": over_copy_limit_count,
		"missing_stamp_codes": missing_stamp_codes,
		"is_collection_complete": missing_count == 0,
		"is_playable": total_count == MAX_DECK_SIZE && owned_count == MAX_DECK_SIZE && missing_count == 0 && over_copy_limit_count == 0,
	}

func get_owned_stamps_from_deck(deck: Dictionary) -> Array:
	ensure_loaded()
	PlayerCollectionStore.ensure_loaded()

	var owned_stamps: Array = []
	var stamp_counts: Dictionary = {}
	var stamps = deck.get("stamps", [])
	if !(stamps is Array):
		return owned_stamps

	for deck_stamp in stamps:
		var normalized_stamp: Dictionary = {}
		if deck_stamp is Dictionary:
			normalized_stamp = _normalize_deck_stamp(deck_stamp, owned_stamps.size())
		else:
			normalized_stamp = _create_legacy_deck_stamp(str(deck_stamp), owned_stamps.size())

		var stamp_code: String = str(normalized_stamp.get("stamp_code", "")).strip_edges()
		if stamp_code.is_empty():
			continue
		var next_count: int = int(stamp_counts.get(stamp_code, 0)) + 1
		if next_count > MAX_COPIES_PER_STAMP:
			continue
		stamp_counts[stamp_code] = next_count
		if !PlayerCollectionStore.owns_stamp_code(stamp_code):
			continue

		normalized_stamp["slot"] = owned_stamps.size()
		owned_stamps.append(normalized_stamp)
	return owned_stamps

func get_deck_stamp_names(deck_id: String) -> Array[String]:
	var deck: Dictionary = get_deck(deck_id)
	if deck.is_empty():
		var empty_stamp_names: Array[String] = []
		return empty_stamp_names
	return get_stamp_names_from_deck(deck)

func get_stamp_names_from_deck(deck: Dictionary) -> Array[String]:
	var stamp_names: Array[String] = []
	var stamps = deck.get("stamps", [])
	if !(stamps is Array):
		return stamp_names

	for deck_stamp in stamps:
		var stamp_name: String = ""
		if deck_stamp is Dictionary:
			var stamp_print: StampPrint = StampPrintLibrary.get_print(str(deck_stamp.get("print_id", "")))
			if stamp_print != null:
				var stamp_from_print: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
				stamp_name = stamp_from_print.stamp_name if stamp_from_print != null else ""
			else:
				stamp_name = str(deck_stamp.get("stamp_name", ""))
			if stamp_name.is_empty():
				var stamp: Stamp = StampLibrary.get_stamp_by_code(str(deck_stamp.get("stamp_code", "")))
				stamp_name = stamp.stamp_name if stamp != null else ""
		else:
			stamp_name = str(deck_stamp)

		if !stamp_name.is_empty():
			stamp_names.append(stamp_name)

	return stamp_names

func save_new_deck(deck_name: String, stamps: Array) -> Dictionary:
	ensure_loaded()

	var now := Time.get_datetime_string_from_system(true)
	var deck: Dictionary = {
		"deck_id": _generate_deck_id(),
		"provider": LOCAL_PROVIDER,
		"name": deck_name.strip_edges(),
		"stamps": _normalize_deck_stamps(stamps),
		"created_at": now,
		"updated_at": now,
	}

	var decks: Array = _get_decks()
	decks.append(deck)
	deck_data["decks"] = decks
	save_decks()
	return deck.duplicate(true)

func save_existing_deck(deck_id: String, deck_name: String, stamps: Array) -> bool:
	ensure_loaded()

	var decks: Array = _get_decks()
	for index in range(decks.size()):
		var deck = decks[index]
		if deck is Dictionary && str(deck.get("deck_id", "")) == deck_id:
			deck["name"] = deck_name.strip_edges()
			deck["stamps"] = _normalize_deck_stamps(stamps)
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

func _ensure_default_deck_exists() -> bool:
	var decks: Array = _get_decks()
	for deck in decks:
		if !(deck is Dictionary):
			continue
		if str(deck.get("deck_id", "")) == DEFAULT_DECK_ID:
			return false
		if str(deck.get("name", "")).strip_edges() == DEFAULT_DECK_NAME:
			return false

	decks.insert(0, _create_default_deck())
	deck_data["decks"] = decks
	return true

func _find_default_deck() -> Dictionary:
	for deck in _get_decks():
		if deck is Dictionary && str(deck.get("deck_id", "")) == DEFAULT_DECK_ID:
			return deck

	for deck in _get_decks():
		if deck is Dictionary && str(deck.get("name", "")).strip_edges() == DEFAULT_DECK_NAME:
			return deck

	return {}

func _create_default_deck() -> Dictionary:
	var now := Time.get_datetime_string_from_system(true)
	return {
		"deck_id": DEFAULT_DECK_ID,
		"provider": LOCAL_PROVIDER,
		"name": DEFAULT_DECK_NAME,
		"stamps": _normalize_deck_stamps(DeckManager.STARTING_DECK),
		"created_at": now,
		"updated_at": now,
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
		"name": str(raw_deck.get("name", "Unnamed codex")),
		"stamps": _normalize_deck_stamps(raw_deck.get("stamps", [])),
		"created_at": str(raw_deck.get("created_at", now)),
		"updated_at": str(raw_deck.get("updated_at", now)),
	}

func _normalize_deck_stamps(raw_stamps) -> Array:
	var normalized_stamps: Array = []
	if !(raw_stamps is Array):
		return normalized_stamps

	var stamp_counts: Dictionary = {}
	for index in range(raw_stamps.size()):
		var raw_stamp = raw_stamps[index]
		var normalized_stamp: Dictionary = {}
		if raw_stamp is Dictionary:
			normalized_stamp = _normalize_deck_stamp(raw_stamp, normalized_stamps.size())
		else:
			normalized_stamp = _create_legacy_deck_stamp(str(raw_stamp), normalized_stamps.size())

		var stamp_code: String = str(normalized_stamp.get("stamp_code", "")).strip_edges()
		if stamp_code.is_empty():
			continue

		var next_count: int = int(stamp_counts.get(stamp_code, 0)) + 1
		if next_count > MAX_COPIES_PER_STAMP:
			continue
		stamp_counts[stamp_code] = next_count
		normalized_stamp["slot"] = normalized_stamps.size()
		normalized_stamps.append(normalized_stamp)
		if normalized_stamps.size() >= MAX_DECK_SIZE:
			break

	return normalized_stamps

func _normalize_deck_stamp(raw_stamp: Dictionary, index: int) -> Dictionary:
	var stamp_code: String = str(raw_stamp.get("stamp_code", ""))
	var stamp_name: String = str(raw_stamp.get("stamp_name", stamp_code))
	if stamp_code.is_empty():
		stamp_code = _get_stamp_code_for_name(stamp_name)
	else:
		stamp_code = PlayerCollectionStore._resolve_stamp_code(stamp_code)
	var variant_id: String = StampPrintLibrary.normalize_variant_id(str(raw_stamp.get("variant_id", PlayerCollectionStore.DEFAULT_VARIANT_ID)))
	var print_id: String = str(raw_stamp.get("print_id", ""))
	if !print_id.is_empty():
		print_id = StampPrintLibrary.resolve_print_id_alias(print_id)
	if print_id.is_empty():
		print_id = PlayerCollectionStore.get_item_def_key(stamp_code, variant_id)
	var stamp_print: StampPrint = StampPrintLibrary.get_print(print_id)
	if stamp_print != null:
		print_id = stamp_print.print_id
		stamp_code = stamp_print.stamp_code
		variant_id = stamp_print.variant_id
		var stamp_from_print: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
		if stamp_from_print != null:
			stamp_name = stamp_from_print.stamp_name
	var item_def_key: String = str(raw_stamp.get("item_def_key", "")).strip_edges()
	if item_def_key.is_empty():
		item_def_key = print_id
	else:
		item_def_key = StampPrintLibrary.resolve_print_id_alias(item_def_key)

	return {
		"slot": int(raw_stamp.get("slot", index)),
		"print_id": print_id,
		"stamp_code": stamp_code,
		"stamp_name": stamp_name,
		"variant_id": variant_id,
		"variant_name": str(raw_stamp.get("variant_name", StampPrintLibrary.get_variant_name(variant_id))),
		"collection_instance_id": str(raw_stamp.get("collection_instance_id", raw_stamp.get("instance_id", ""))),
		"item_def_key": item_def_key,
		"steam_item_instance_id": str(raw_stamp.get("steam_item_instance_id", "")),
		"steam_item_def_id": str(raw_stamp.get("steam_item_def_id", "")),
	}

func _create_legacy_deck_stamp(stamp_name: String, index: int) -> Dictionary:
	var legacy_stamp_code: String = _get_stamp_code_for_name(stamp_name)
	return {
		"slot": index,
		"print_id": PlayerCollectionStore.get_item_def_key(legacy_stamp_code, PlayerCollectionStore.DEFAULT_VARIANT_ID),
		"stamp_code": legacy_stamp_code,
		"stamp_name": stamp_name,
		"variant_id": PlayerCollectionStore.DEFAULT_VARIANT_ID,
		"variant_name": PlayerCollectionStore.DEFAULT_VARIANT_NAME,
		"collection_instance_id": "",
		"item_def_key": PlayerCollectionStore.get_item_def_key(legacy_stamp_code, PlayerCollectionStore.DEFAULT_VARIANT_ID),
		"steam_item_instance_id": "",
		"steam_item_def_id": "",
	}

func _get_deck_stamp_code(deck_stamp) -> String:
	if deck_stamp is Dictionary:
		var print_id: String = str(deck_stamp.get("print_id", "")).strip_edges()
		if !print_id.is_empty():
			var stamp_print: StampPrint = StampPrintLibrary.get_print(print_id)
			if stamp_print != null:
				return stamp_print.stamp_code

		var stamp_code: String = str(deck_stamp.get("stamp_code", "")).strip_edges()
		if !stamp_code.is_empty():
			var stamp_by_code: Stamp = StampLibrary.get_stamp_by_code(stamp_code)
			return PlayerCollectionStore.get_stamp_code(stamp_by_code) if stamp_by_code != null else StampLibrary.resolve_stamp_code_alias(stamp_code)

		return _get_stamp_code_for_name(str(deck_stamp.get("stamp_name", "")))

	return _get_stamp_code_for_name(str(deck_stamp))

func _generate_deck_id() -> String:
	return "local_deck_%d" % Time.get_ticks_usec()

func _get_stamp_code_for_name(stamp_name: String) -> String:
	if StampLibrary.all_stamps.is_empty():
		StampLibrary.load_all_stamps()

	var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
	if stamp == null:
		return StampLibrary.resolve_stamp_code_alias(stamp_name)
	return PlayerCollectionStore.get_stamp_code(stamp)
