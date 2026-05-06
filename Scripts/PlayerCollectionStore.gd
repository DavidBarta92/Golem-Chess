extends Node

const COLLECTION_SCHEMA_VERSION: int = 2
const COLLECTION_PATH: String = "user://player_collection.json"
const LOCAL_PROVIDER: String = "local_json"
const DEFAULT_VARIANT_ID: String = "standard"
const DEFAULT_VARIANT_NAME: String = "Standard"

var collection_data: Dictionary = {}
var is_loaded: bool = false

func ensure_loaded() -> void:
	if is_loaded:
		return

	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()
	CardPrintLibrary.ensure_loaded()

	if FileAccess.file_exists(COLLECTION_PATH):
		var file := FileAccess.open(COLLECTION_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				collection_data = _normalize_collection(parsed)
				is_loaded = true
				_add_missing_default_collection_prints()
				save_collection()
				return

	collection_data = _create_default_collection()
	is_loaded = true
	save_collection()

func list_items() -> Array:
	ensure_loaded()
	return _get_items().duplicate(true)

func owns_card(card: Card) -> bool:
	return get_owned_count_for_card(card) > 0

func owns_card_code(card_code: String) -> bool:
	return get_owned_count_for_card_code(card_code) > 0

func owns_print(card_print: CardPrint) -> bool:
	return card_print != null && get_owned_count_for_print_id(card_print.print_id) > 0

func owns_print_id(print_id: String) -> bool:
	return get_owned_count_for_print_id(print_id) > 0

func get_owned_count_for_card(card: Card) -> int:
	if card == null:
		return 0

	var card_code: String = get_card_code(card)
	var owned_count: int = 0
	for item in _get_items():
		if item is Dictionary && str(item.get("card_code", "")) == card_code:
			owned_count += int(item.get("quantity", 0))
	return owned_count

func get_owned_count_for_card_code(card_code: String) -> int:
	var normalized_card_code: String = _resolve_card_code(card_code)
	if normalized_card_code.is_empty():
		return 0

	var owned_count: int = 0
	for item in _get_items():
		if item is Dictionary && _resolve_card_code(str(item.get("card_code", ""))) == normalized_card_code:
			owned_count += int(item.get("quantity", 0))
	return owned_count

func get_owned_count_for_print_id(print_id: String) -> int:
	var normalized_print_id: String = print_id.strip_edges()
	if normalized_print_id.is_empty():
		return 0

	for item in _get_items():
		if item is Dictionary && str(item.get("print_id", "")) == normalized_print_id:
			return int(item.get("quantity", 0))
	return 0

func get_first_owned_item_for_card(card: Card) -> Dictionary:
	if card == null:
		return {}

	var card_code: String = get_card_code(card)
	for item in _get_items():
		if item is Dictionary && str(item.get("card_code", "")) == card_code && int(item.get("quantity", 0)) > 0:
			return item.duplicate(true)
	return {}

func get_owned_item_for_print(card_print: CardPrint) -> Dictionary:
	if card_print == null:
		return {}
	return get_owned_item_for_print_id(card_print.print_id)

func get_owned_item_for_print_id(print_id: String) -> Dictionary:
	for item in _get_items():
		if item is Dictionary && str(item.get("print_id", "")) == print_id && int(item.get("quantity", 0)) > 0:
			return item.duplicate(true)
	return {}

func add_local_card_copy(card_name: String, variant_id: String = DEFAULT_VARIANT_ID, _variant_name: String = DEFAULT_VARIANT_NAME) -> Dictionary:
	ensure_loaded()
	var card: Card = CardLibrary.get_card(card_name)
	if card == null:
		return {}

	var card_code: String = get_card_code(card)
	var print_id: String = CardPrintLibrary.get_print_id(card_code, variant_id)
	return add_local_print_copy(print_id)

func add_local_print_copy(print_id: String, amount: int = 1) -> Dictionary:
	ensure_loaded()
	var card_print: CardPrint = CardPrintLibrary.get_print(print_id)
	if card_print == null:
		return {}

	var items: Array = _get_items()
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary && str(item.get("print_id", "")) == card_print.print_id:
			item["quantity"] = maxi(0, int(item.get("quantity", 0))) + maxi(1, amount)
			items[index] = item
			collection_data["items"] = items
			save_collection()
			return item.duplicate(true)

	var new_item: Dictionary = _create_collection_item(card_print, maxi(1, amount))
	items.append(new_item)
	collection_data["items"] = items
	save_collection()
	return new_item.duplicate(true)

func remove_card_instance(instance_id: String) -> bool:
	ensure_loaded()
	var items: Array = _get_items()
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary && str(item.get("instance_id", "")) == instance_id:
			var quantity: int = maxi(0, int(item.get("quantity", 0)) - 1)
			if quantity <= 0:
				items.remove_at(index)
			else:
				item["quantity"] = quantity
				items[index] = item
			collection_data["items"] = items
			return save_collection()
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

func _resolve_card_code(card_code_or_name: String) -> String:
	var normalized_value: String = card_code_or_name.strip_edges()
	if normalized_value.is_empty():
		return ""

	var card_by_code: Card = CardLibrary.get_card_by_code(normalized_value)
	if card_by_code != null:
		return get_card_code(card_by_code)

	var card_by_name: Card = CardLibrary.get_card(normalized_value)
	if card_by_name != null:
		return get_card_code(card_by_name)

	return normalized_value

func get_item_def_key(card_code: String, variant_id: String) -> String:
	return CardPrintLibrary.get_print_id(card_code, variant_id)

func _get_items() -> Array:
	ensure_loaded()
	var items = collection_data.get("items", [])
	return items if items is Array else []

func _normalize_collection(raw_data: Dictionary) -> Dictionary:
	var normalized: Dictionary = {
		"schema_version": COLLECTION_SCHEMA_VERSION,
		"provider": str(raw_data.get("provider", LOCAL_PROVIDER)),
		"items": [],
	}

	var normalized_items: Array = []
	var raw_items = raw_data.get("items", [])
	if raw_items is Array:
		for raw_item in raw_items:
			if raw_item is Dictionary:
				_add_or_merge_item(normalized_items, _normalize_collection_item(raw_item))

	normalized["items"] = normalized_items
	return normalized

func _normalize_collection_item(raw_item: Dictionary) -> Dictionary:
	var print_id: String = str(raw_item.get("print_id", ""))
	var card_code: String = str(raw_item.get("card_code", ""))
	var card_name: String = str(raw_item.get("card_name", ""))

	if card_code.is_empty() && !card_name.is_empty():
		var card_by_name: Card = CardLibrary.get_card(card_name)
		if card_by_name != null:
			card_code = get_card_code(card_by_name)

	var variant_id: String = CardPrintLibrary.normalize_variant_id(str(raw_item.get("variant_id", DEFAULT_VARIANT_ID)))
	if print_id.is_empty() && !card_code.is_empty():
		print_id = CardPrintLibrary.get_print_id(card_code, variant_id)

	var card_print: CardPrint = CardPrintLibrary.get_print(print_id)
	if card_print != null:
		card_code = card_print.card_code
		variant_id = card_print.variant_id
	else:
		card_print = CardPrint.new()
		card_print.print_id = print_id
		card_print.card_code = card_code
		card_print.variant_id = variant_id
		card_print.variant_name = CardPrintLibrary.get_variant_name(variant_id)

	var quantity: int = maxi(1, int(raw_item.get("quantity", 1)))
	var instance_id: String = str(raw_item.get("instance_id", ""))
	if instance_id.is_empty():
		instance_id = _generate_instance_id(card_print)

	return _create_collection_item(card_print, quantity, instance_id)

func _create_default_collection() -> Dictionary:
	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()
	CardPrintLibrary.ensure_loaded()

	var items: Array = []
	var default_prints: Array = _get_default_collection_prints()
	for card_print_value in default_prints:
		var card_print: CardPrint = card_print_value as CardPrint
		if card_print == null:
			continue
		items.append(_create_collection_item(card_print, _get_default_collection_quantity(card_print)))

	return {
		"schema_version": COLLECTION_SCHEMA_VERSION,
		"provider": LOCAL_PROVIDER,
		"items": items,
	}

func _add_missing_default_collection_prints() -> void:
	var items: Array = _get_items()
	var item_index_by_print_id: Dictionary = {}
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary:
			item_index_by_print_id[str(item.get("print_id", ""))] = index

	var default_prints: Array = _get_default_collection_prints()
	for card_print_value in default_prints:
		var card_print: CardPrint = card_print_value as CardPrint
		if card_print == null:
			continue

		var default_quantity: int = _get_default_collection_quantity(card_print)
		if item_index_by_print_id.has(card_print.print_id):
			var item_index: int = int(item_index_by_print_id[card_print.print_id])
			var existing_item: Dictionary = items[item_index]
			if int(existing_item.get("quantity", 0)) < default_quantity:
				existing_item["quantity"] = default_quantity
				items[item_index] = existing_item
			continue

		items.append(_create_collection_item(card_print, default_quantity))

	collection_data["items"] = items

func _get_default_collection_quantity(card_print: CardPrint) -> int:
	if card_print == null:
		return 1
	return maxi(1, card_print.default_collection_quantity)

func _get_default_collection_prints() -> Array:
	var default_prints: Array = []
	var card_codes: Array = CardLibrary.get_all_card_codes()
	card_codes.sort()
	for card_code_value in card_codes:
		var card_code: String = str(card_code_value)
		var card_print: CardPrint = CardPrintLibrary.get_print(CardPrintLibrary.get_default_print_id_for_card_code(card_code))
		if card_print != null:
			default_prints.append(card_print)

	for card_print_value in CardPrintLibrary.get_all_prints():
		var card_print: CardPrint = card_print_value as CardPrint
		if card_print == null or !card_print.grant_in_default_collection:
			continue
		if !_has_print_id(default_prints, card_print.print_id):
			default_prints.append(card_print)
	return default_prints

func _has_print_id(card_prints: Array, print_id: String) -> bool:
	for card_print_value in card_prints:
		var card_print: CardPrint = card_print_value as CardPrint
		if card_print != null && card_print.print_id == print_id:
			return true
	return false

func _create_collection_item(card_print: CardPrint, quantity: int = 1, instance_id: String = "") -> Dictionary:
	var card: Card = CardPrintLibrary.get_card_for_print(card_print)
	if instance_id.is_empty():
		instance_id = _generate_instance_id(card_print)

	return {
		"instance_id": instance_id,
		"provider": LOCAL_PROVIDER,
		"print_id": card_print.print_id,
		"card_code": card_print.card_code,
		"card_name": card.card_name if card != null else card_print.card_code,
		"variant_id": card_print.variant_id,
		"variant_name": card_print.get_display_name(),
		"item_def_key": card_print.print_id,
		"steam_item_instance_id": "",
		"steam_item_def_id": "",
		"quantity": maxi(0, quantity),
	}

func _add_or_merge_item(items: Array, new_item: Dictionary) -> void:
	var print_id: String = str(new_item.get("print_id", ""))
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary && str(item.get("print_id", "")) == print_id:
			item["quantity"] = int(item.get("quantity", 0)) + int(new_item.get("quantity", 0))
			items[index] = item
			return
	items.append(new_item)

func _generate_instance_id(card_print: CardPrint) -> String:
	return "local_%s_%d" % [_sanitize_id(card_print.print_id), Time.get_ticks_usec()]

func _sanitize_id(value: String) -> String:
	return value.to_lower().replace(" ", "_").replace("/", "_").replace("\\", "_").replace(":", "_").replace(".", "_")
