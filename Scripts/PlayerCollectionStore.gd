extends Node

const COLLECTION_SCHEMA_VERSION: int = 4
const COLLECTION_PATH: String = "user://player_collection.json"
const SAVED_DECKS_PATH: String = "user://decks.json"
const LOCAL_PROVIDER: String = "local_json"
const DEFAULT_VARIANT_ID: String = "standard"
const DEFAULT_VARIANT_NAME: String = "Standard"
const DEFAULT_COLLECTION_STAMP_NAMES: Array[String] = [
	"Numero_1",
	"Numero_2",
	"Numero_3",
	"Numero_4",
	"Numero_5",
	"Numero_6",
	"Numero_7",
	"Prince",
	"Rajah",
	"Khan",
	"Debater",
]

var collection_data: Dictionary = {}
var is_loaded: bool = false

func ensure_loaded() -> void:
	if is_loaded:
		return

	if StampLibrary.all_stamps.is_empty():
		StampLibrary.load_all_stamps()
	StampPrintLibrary.ensure_loaded()

	if FileAccess.file_exists(COLLECTION_PATH):
		var file := FileAccess.open(COLLECTION_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				var previous_schema_version: int = int(parsed.get("schema_version", 1))
				collection_data = _normalize_collection(parsed)
				is_loaded = true
				if _should_reset_outdated_local_collection(previous_schema_version, collection_data):
					collection_data = _create_default_collection()
				else:
					_add_missing_default_collection_prints()
				_add_missing_saved_deck_prints()
				save_collection()
				return

	collection_data = _create_default_collection()
	is_loaded = true
	_add_missing_saved_deck_prints()
	save_collection()

func list_items() -> Array:
	ensure_loaded()
	return _get_items().duplicate(true)

func owns_stamp(stamp: Stamp) -> bool:
	return get_owned_count_for_stamp(stamp) > 0

func owns_stamp_code(stamp_code: String) -> bool:
	return get_owned_count_for_stamp_code(stamp_code) > 0

func owns_print(stamp_print: StampPrint) -> bool:
	return stamp_print != null && get_owned_count_for_print_id(stamp_print.print_id) > 0

func owns_print_id(print_id: String) -> bool:
	return get_owned_count_for_print_id(print_id) > 0

func get_owned_count_for_stamp(stamp: Stamp) -> int:
	if stamp == null:
		return 0

	var stamp_code: String = get_stamp_code(stamp)
	var owned_count: int = 0
	for item in _get_items():
		if item is Dictionary && _resolve_stamp_code(str(item.get("stamp_code", ""))) == stamp_code:
			owned_count += int(item.get("quantity", 0))
	return owned_count

func get_owned_count_for_stamp_code(stamp_code: String) -> int:
	var normalized_stamp_code: String = _resolve_stamp_code(stamp_code)
	if normalized_stamp_code.is_empty():
		return 0

	var owned_count: int = 0
	for item in _get_items():
		if item is Dictionary && _resolve_stamp_code(str(item.get("stamp_code", ""))) == normalized_stamp_code:
			owned_count += int(item.get("quantity", 0))
	return owned_count

func get_owned_count_for_print_id(print_id: String) -> int:
	var normalized_print_id: String = _resolve_print_id(print_id)
	if normalized_print_id.is_empty():
		return 0

	for item in _get_items():
		if item is Dictionary && _resolve_print_id(str(item.get("print_id", ""))) == normalized_print_id:
			return int(item.get("quantity", 0))
	return 0

func get_first_owned_item_for_stamp(stamp: Stamp) -> Dictionary:
	if stamp == null:
		return {}

	var stamp_code: String = get_stamp_code(stamp)
	for item in _get_items():
		if item is Dictionary && _resolve_stamp_code(str(item.get("stamp_code", ""))) == stamp_code && int(item.get("quantity", 0)) > 0:
			return item.duplicate(true)
	return {}

func get_owned_item_for_print(stamp_print: StampPrint) -> Dictionary:
	if stamp_print == null:
		return {}
	return get_owned_item_for_print_id(stamp_print.print_id)

func get_owned_item_for_print_id(print_id: String) -> Dictionary:
	var normalized_print_id: String = _resolve_print_id(print_id)
	for item in _get_items():
		if item is Dictionary && _resolve_print_id(str(item.get("print_id", ""))) == normalized_print_id && int(item.get("quantity", 0)) > 0:
			return item.duplicate(true)
	return {}

func add_local_stamp_copy(stamp_name: String, variant_id: String = DEFAULT_VARIANT_ID, _variant_name: String = DEFAULT_VARIANT_NAME) -> Dictionary:
	ensure_loaded()
	var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
	if stamp == null:
		return {}

	var stamp_code: String = get_stamp_code(stamp)
	var print_id: String = StampPrintLibrary.get_print_id(stamp_code, variant_id)
	return add_local_print_copy(print_id)

func add_local_print_copy(print_id: String, amount: int = 1) -> Dictionary:
	ensure_loaded()
	var stamp_print: StampPrint = StampPrintLibrary.get_print(print_id)
	if stamp_print == null:
		return {}

	var items: Array = _get_items()
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary && _resolve_print_id(str(item.get("print_id", ""))) == stamp_print.print_id:
			item["quantity"] = maxi(0, int(item.get("quantity", 0))) + maxi(1, amount)
			items[index] = item
			collection_data["items"] = items
			save_collection()
			return item.duplicate(true)

	var new_item: Dictionary = _create_collection_item(stamp_print, maxi(1, amount))
	items.append(new_item)
	collection_data["items"] = items
	save_collection()
	return new_item.duplicate(true)

func remove_stamp_instance(instance_id: String) -> bool:
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
		push_error("Could not save player stamp collection to %s" % COLLECTION_PATH)
		return false

	file.store_string(JSON.stringify(collection_data, "\t"))
	return true

func get_stamp_code(stamp: Stamp) -> String:
	if stamp == null:
		return ""

	var stamp_code := stamp.stamp_code.strip_edges()
	return stamp_code if !stamp_code.is_empty() else stamp.stamp_name.strip_edges()

func _resolve_stamp_code(stamp_code_or_name: String) -> String:
	var normalized_value: String = stamp_code_or_name.strip_edges()
	if normalized_value.is_empty():
		return ""

	var stamp_by_code: Stamp = StampLibrary.get_stamp_by_code(normalized_value)
	if stamp_by_code != null:
		return get_stamp_code(stamp_by_code)

	var stamp_by_name: Stamp = StampLibrary.get_stamp(normalized_value)
	if stamp_by_name != null:
		return get_stamp_code(stamp_by_name)

	var alias_stamp_code: String = StampLibrary.resolve_stamp_code_alias(normalized_value)
	if alias_stamp_code != normalized_value.to_lower():
		return alias_stamp_code

	return normalized_value

func _resolve_print_id(print_id: String) -> String:
	var normalized_print_id: String = print_id.strip_edges()
	if normalized_print_id.is_empty():
		return ""

	var stamp_print: StampPrint = StampPrintLibrary.get_print(normalized_print_id)
	if stamp_print != null:
		return stamp_print.print_id

	return StampPrintLibrary.resolve_print_id_alias(normalized_print_id)

func get_item_def_key(stamp_code: String, variant_id: String) -> String:
	return StampPrintLibrary.get_print_id(stamp_code, variant_id)

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
	var stamp_code: String = str(raw_item.get("stamp_code", ""))
	var stamp_name: String = str(raw_item.get("stamp_name", ""))
	var variant_id: String = StampPrintLibrary.normalize_variant_id(str(raw_item.get("variant_id", DEFAULT_VARIANT_ID)))

	if stamp_code.is_empty() && !stamp_name.is_empty():
		stamp_code = _resolve_stamp_code(stamp_name)
	else:
		stamp_code = _resolve_stamp_code(stamp_code)

	if !print_id.is_empty():
		print_id = _resolve_print_id(print_id)
	if print_id.is_empty() && !stamp_code.is_empty():
		print_id = StampPrintLibrary.get_print_id(stamp_code, variant_id)

	var stamp_print: StampPrint = StampPrintLibrary.get_print(print_id)
	if stamp_print != null:
		print_id = stamp_print.print_id
		stamp_code = stamp_print.stamp_code
		variant_id = stamp_print.variant_id
	else:
		stamp_print = StampPrint.new()
		stamp_print.print_id = print_id
		stamp_print.stamp_code = stamp_code
		stamp_print.variant_id = variant_id
		stamp_print.variant_name = StampPrintLibrary.get_variant_name(variant_id)

	var quantity: int = maxi(1, int(raw_item.get("quantity", 1)))
	var instance_id: String = str(raw_item.get("instance_id", ""))
	if instance_id.is_empty():
		instance_id = _generate_instance_id(stamp_print)

	return _create_collection_item(stamp_print, quantity, instance_id)

func _create_default_collection() -> Dictionary:
	if StampLibrary.all_stamps.is_empty():
		StampLibrary.load_all_stamps()
	StampPrintLibrary.ensure_loaded()

	var items: Array = []
	var default_prints: Array = _get_default_collection_prints()
	for stamp_print_value in default_prints:
		var stamp_print: StampPrint = stamp_print_value as StampPrint
		if stamp_print == null:
			continue
		items.append(_create_collection_item(stamp_print, _get_default_collection_quantity(stamp_print)))

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
			item_index_by_print_id[_resolve_print_id(str(item.get("print_id", "")))] = index

	var default_prints: Array = _get_default_collection_prints()
	for stamp_print_value in default_prints:
		var stamp_print: StampPrint = stamp_print_value as StampPrint
		if stamp_print == null:
			continue

		var default_quantity: int = _get_default_collection_quantity(stamp_print)
		if item_index_by_print_id.has(stamp_print.print_id):
			var item_index: int = int(item_index_by_print_id[stamp_print.print_id])
			var existing_item: Dictionary = items[item_index]
			if int(existing_item.get("quantity", 0)) < default_quantity:
				existing_item["quantity"] = default_quantity
				items[item_index] = existing_item
			continue

		items.append(_create_collection_item(stamp_print, default_quantity))

	collection_data["items"] = items

func _add_missing_saved_deck_prints() -> void:
	if str(collection_data.get("provider", LOCAL_PROVIDER)) != LOCAL_PROVIDER:
		return

	var items: Array = _get_items()
	var item_index_by_print_id: Dictionary = {}
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary:
			item_index_by_print_id[_resolve_print_id(str(item.get("print_id", "")))] = index

	for stamp_print_value in _get_saved_deck_prints():
		var stamp_print: StampPrint = stamp_print_value as StampPrint
		if stamp_print == null:
			continue

		if item_index_by_print_id.has(stamp_print.print_id):
			var item_index: int = int(item_index_by_print_id[stamp_print.print_id])
			var existing_item: Dictionary = items[item_index]
			if int(existing_item.get("quantity", 0)) < 1:
				existing_item["quantity"] = 1
				items[item_index] = existing_item
			continue

		items.append(_create_collection_item(stamp_print, 1))
		item_index_by_print_id[stamp_print.print_id] = items.size() - 1

	collection_data["items"] = items

func _get_saved_deck_prints() -> Array:
	var saved_prints: Dictionary = {}
	if !FileAccess.file_exists(SAVED_DECKS_PATH):
		return []

	var file := FileAccess.open(SAVED_DECKS_PATH, FileAccess.READ)
	if file == null:
		return []

	var parsed = JSON.parse_string(file.get_as_text())
	var decks: Array = []
	if parsed is Dictionary:
		var parsed_decks = parsed.get("decks", [])
		if parsed_decks is Array:
			decks = parsed_decks
	elif parsed is Array:
		decks = parsed

	for deck_value in decks:
		if !(deck_value is Dictionary):
			continue

		var deck: Dictionary = deck_value
		var stamps = deck.get("stamps", [])
		if !(stamps is Array):
			continue

		for deck_stamp in stamps:
			var stamp_print: StampPrint = _get_saved_deck_stamp_print(deck_stamp)
			if stamp_print != null:
				saved_prints[stamp_print.print_id] = stamp_print

	return saved_prints.values()

func _get_saved_deck_stamp_print(deck_stamp) -> StampPrint:
	if deck_stamp is Dictionary:
		var print_id: String = str(deck_stamp.get("print_id", "")).strip_edges()
		if !print_id.is_empty():
			var stamp_print: StampPrint = StampPrintLibrary.get_print(print_id)
			if stamp_print != null:
				return stamp_print

		var stamp_code: String = str(deck_stamp.get("stamp_code", "")).strip_edges()
		if stamp_code.is_empty():
			stamp_code = _get_stamp_code_for_name(str(deck_stamp.get("stamp_name", "")))
		else:
			stamp_code = _resolve_stamp_code(stamp_code)
		if stamp_code.is_empty():
			return null

		var variant_id: String = StampPrintLibrary.normalize_variant_id(str(deck_stamp.get("variant_id", DEFAULT_VARIANT_ID)))
		var stamp_print_by_variant: StampPrint = StampPrintLibrary.get_print(StampPrintLibrary.get_print_id(stamp_code, variant_id))
		if stamp_print_by_variant != null:
			return stamp_print_by_variant
		return StampPrintLibrary.get_print(StampPrintLibrary.get_default_print_id_for_stamp_code(stamp_code))

	var legacy_stamp_code: String = _get_stamp_code_for_name(str(deck_stamp))
	if legacy_stamp_code.is_empty():
		return null
	return StampPrintLibrary.get_print(StampPrintLibrary.get_default_print_id_for_stamp_code(legacy_stamp_code))

func _get_default_collection_quantity(stamp_print: StampPrint) -> int:
	if stamp_print == null:
		return 1
	var default_quantities: Dictionary = _get_default_collection_stamp_code_quantities()
	return maxi(1, int(default_quantities.get(stamp_print.stamp_code, 1)))

func _get_default_collection_prints() -> Array:
	var default_prints: Array = []
	var stamp_codes: Array = _get_default_collection_stamp_code_quantities().keys()
	stamp_codes.sort()
	for stamp_code_value in stamp_codes:
		var stamp_code: String = str(stamp_code_value)
		var stamp_print: StampPrint = StampPrintLibrary.get_print(StampPrintLibrary.get_default_print_id_for_stamp_code(stamp_code))
		if stamp_print != null:
			default_prints.append(stamp_print)

	return default_prints

func _get_default_collection_stamp_code_quantities() -> Dictionary:
	var quantities: Dictionary = {}
	for stamp_name_value in DEFAULT_COLLECTION_STAMP_NAMES:
		var stamp_code: String = _get_stamp_code_for_name(str(stamp_name_value))
		if stamp_code.is_empty():
			continue
		quantities[stamp_code] = 1

	return quantities

func _get_stamp_code_for_name(stamp_name: String) -> String:
	var stamp: Stamp = StampLibrary.get_stamp(stamp_name)
	if stamp == null:
		push_warning("Default collection stamp not found: %s" % stamp_name)
		return ""
	return get_stamp_code(stamp)

func _should_reset_outdated_local_collection(previous_schema_version: int, normalized_collection: Dictionary) -> bool:
	if previous_schema_version >= COLLECTION_SCHEMA_VERSION:
		return false
	return str(normalized_collection.get("provider", LOCAL_PROVIDER)) == LOCAL_PROVIDER

func _create_collection_item(stamp_print: StampPrint, quantity: int = 1, instance_id: String = "") -> Dictionary:
	var stamp: Stamp = StampPrintLibrary.get_stamp_for_print(stamp_print)
	if instance_id.is_empty():
		instance_id = _generate_instance_id(stamp_print)

	return {
		"instance_id": instance_id,
		"provider": LOCAL_PROVIDER,
		"print_id": stamp_print.print_id,
		"stamp_code": stamp_print.stamp_code,
		"stamp_name": stamp.stamp_name if stamp != null else stamp_print.stamp_code,
		"variant_id": stamp_print.variant_id,
		"variant_name": stamp_print.get_display_name(),
		"item_def_key": stamp_print.print_id,
		"steam_item_instance_id": "",
		"steam_item_def_id": "",
		"quantity": maxi(0, quantity),
	}

func _add_or_merge_item(items: Array, new_item: Dictionary) -> void:
	var print_id: String = _resolve_print_id(str(new_item.get("print_id", "")))
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary && _resolve_print_id(str(item.get("print_id", ""))) == print_id:
			item["quantity"] = int(item.get("quantity", 0)) + int(new_item.get("quantity", 0))
			items[index] = item
			return
	items.append(new_item)

func _generate_instance_id(stamp_print: StampPrint) -> String:
	return "local_%s_%d" % [_sanitize_id(stamp_print.print_id), Time.get_ticks_usec()]

func _sanitize_id(value: String) -> String:
	return value.to_lower().replace(" ", "_").replace("/", "_").replace("\\", "_").replace(":", "_").replace(".", "_")
