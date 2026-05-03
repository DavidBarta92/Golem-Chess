extends Node

const COLLECTION_SCHEMA_VERSION: int = 1
const COLLECTION_PATH: String = "user://player_collection.json"
const LOCAL_PROVIDER: String = "local_json"
const DEFAULT_VARIANT_ID: String = "basic"
const DEFAULT_VARIANT_NAME: String = "Basic"

var collection_data: Dictionary = {}
var is_loaded: bool = false

func ensure_loaded() -> void:
	if is_loaded:
		return

	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()

	if FileAccess.file_exists(COLLECTION_PATH):
		var file := FileAccess.open(COLLECTION_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				collection_data = _normalize_collection(parsed)
				is_loaded = true
				return

	collection_data = _create_default_collection()
	is_loaded = true
	save_collection()

func list_items() -> Array:
	ensure_loaded()
	return _get_items().duplicate(true)

func owns_card(card: Card) -> bool:
	return get_owned_count_for_card(card) > 0

func get_owned_count_for_card(card: Card) -> int:
	if card == null:
		return 0

	var card_code: String = get_card_code(card)
	var owned_count: int = 0
	for item in _get_items():
		if item is Dictionary && str(item.get("card_code", "")) == card_code:
			owned_count += 1
	return owned_count

func get_first_owned_item_for_card(card: Card) -> Dictionary:
	if card == null:
		return {}

	var card_code: String = get_card_code(card)
	for item in _get_items():
		if item is Dictionary && str(item.get("card_code", "")) == card_code:
			return item.duplicate(true)
	return {}

func add_local_card_copy(card_name: String, variant_id: String = DEFAULT_VARIANT_ID, variant_name: String = DEFAULT_VARIANT_NAME) -> Dictionary:
	ensure_loaded()

	var card: Card = CardLibrary.get_card(card_name)
	if card == null:
		return {}

	var item := _create_collection_item(card, variant_id, variant_name, _generate_local_instance_id(card, variant_id))
	var items: Array = _get_items()
	items.append(item)
	collection_data["items"] = items
	save_collection()
	return item.duplicate(true)

func remove_card_instance(instance_id: String) -> bool:
	ensure_loaded()

	var items: Array = _get_items()
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary && str(item.get("instance_id", "")) == instance_id:
			items.remove_at(index)
			collection_data["items"] = items
			save_collection()
			return true
	return false

func save_collection() -> bool:
	ensure_loaded()

	var file := FileAccess.open(COLLECTION_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save player card collection to %s" % COLLECTION_PATH)
		return false

	file.store_string(JSON.stringify(collection_data, "\t"))
	return true

func get_card_code(card: Card) -> String:
	if card == null:
		return ""

	var card_code := card.card_code.strip_edges()
	return card_code if !card_code.is_empty() else card.card_name.strip_edges()

func get_item_def_key(card_code: String, variant_id: String) -> String:
	return "%s.%s" % [card_code, variant_id]

func _get_items() -> Array:
	ensure_loaded()
	var items = collection_data.get("items", [])
	return items if items is Array else []

func _normalize_collection(raw_data: Dictionary) -> Dictionary:
	var normalized: Dictionary = {
		"schema_version": int(raw_data.get("schema_version", COLLECTION_SCHEMA_VERSION)),
		"provider": str(raw_data.get("provider", LOCAL_PROVIDER)),
		"items": [],
	}

	var normalized_items: Array = []
	var raw_items = raw_data.get("items", [])
	if raw_items is Array:
		for raw_item in raw_items:
			if raw_item is Dictionary:
				normalized_items.append(_normalize_collection_item(raw_item))

	normalized["items"] = normalized_items
	return normalized

func _normalize_collection_item(raw_item: Dictionary) -> Dictionary:
	var card_name: String = str(raw_item.get("card_name", ""))
	var card_code: String = str(raw_item.get("card_code", ""))
	var card: Card = CardLibrary.get_card(card_name)
	if card == null && !card_code.is_empty():
		card = CardLibrary.get_card_by_code(card_code)
	if card != null:
		card_code = get_card_code(card)
		card_name = card.card_name

	var variant_id: String = str(raw_item.get("variant_id", DEFAULT_VARIANT_ID))
	if variant_id.is_empty():
		variant_id = DEFAULT_VARIANT_ID
	var instance_id: String = str(raw_item.get("instance_id", ""))
	if instance_id.is_empty():
		instance_id = "local_%s_%s_legacy" % [_sanitize_id(card_code), _sanitize_id(variant_id)]

	return {
		"instance_id": instance_id,
		"provider": str(raw_item.get("provider", LOCAL_PROVIDER)),
		"card_code": card_code,
		"card_name": card_name,
		"variant_id": variant_id,
		"variant_name": str(raw_item.get("variant_name", DEFAULT_VARIANT_NAME)),
		"item_def_key": str(raw_item.get("item_def_key", get_item_def_key(card_code, variant_id))),
		"steam_item_instance_id": str(raw_item.get("steam_item_instance_id", "")),
		"steam_item_def_id": str(raw_item.get("steam_item_def_id", "")),
		"quantity": 1,
	}

func _create_default_collection() -> Dictionary:
	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()

	var card_names: Array = CardLibrary.get_all_card_names()
	card_names.sort()

	var items: Array = []
	for card_name in card_names:
		var card: Card = CardLibrary.get_card(str(card_name))
		if card == null:
			continue
		items.append(_create_collection_item(card, DEFAULT_VARIANT_ID, DEFAULT_VARIANT_NAME, _generate_default_instance_id(card)))

	return {
		"schema_version": COLLECTION_SCHEMA_VERSION,
		"provider": LOCAL_PROVIDER,
		"items": items,
	}

func _create_collection_item(card: Card, variant_id: String, variant_name: String, instance_id: String) -> Dictionary:
	var card_code: String = get_card_code(card)
	return {
		"instance_id": instance_id,
		"provider": LOCAL_PROVIDER,
		"card_code": card_code,
		"card_name": card.card_name,
		"variant_id": variant_id,
		"variant_name": variant_name,
		"item_def_key": get_item_def_key(card_code, variant_id),
		"steam_item_instance_id": "",
		"steam_item_def_id": "",
		"quantity": 1,
	}

func _generate_default_instance_id(card: Card) -> String:
	return "local_%s_%s_001" % [_sanitize_id(get_card_code(card)), DEFAULT_VARIANT_ID]

func _generate_local_instance_id(card: Card, variant_id: String) -> String:
	return "local_%s_%s_%d" % [_sanitize_id(get_card_code(card)), _sanitize_id(variant_id), Time.get_ticks_usec()]

func _sanitize_id(value: String) -> String:
	return value.to_lower().replace(" ", "_").replace("/", "_").replace("\\", "_").replace(":", "_")
