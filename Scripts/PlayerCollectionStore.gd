extends Node

const COLLECTION_SCHEMA_VERSION: int = 4
const COLLECTION_PATH: String = "user://player_collection.json"
const LOCAL_PROVIDER: String = "local_json"
const DEFAULT_VARIANT_ID: String = "standard"
const DEFAULT_VARIANT_NAME: String = "Standard"
## Stamps every new save owns outright. Empty on purpose: the story hands the
## player their first cards (Grandpa's deck) in the first reward scene. The
## default saved deck still comes with the copies it plays (settle_codex_copies),
## so the starting deck is always playable.
const DEFAULT_COLLECTION_STAMP_NAMES: Array[String] = []
## Set once the codexes' copies were made good (settle_codex_copies). Before the
## free-copy rule a codex only had to own a stamp, not a copy per slot; the first
## load under the rule gives every codex what it plays, and never again after.
const CODEX_COPIES_SETTLED_KEY: String = "codex_copies_settled"

## A copy is free when it is neither glued into a codex nor out on a Bourse lot.
## Emitted when that may have changed: a copy came or went, a codex was saved
## or deleted, a lot was listed or settled.
signal copies_changed

var collection_data: Dictionary = {}
var is_loaded: bool = false

# Copies held by codexes and lots, by print id: {"codexes": {deck_id: count},
# "lot": count, "total": count}. Rebuilt on the first question after a change.
var _reserved_by_print_id: Dictionary = {}
var _deck_names_by_id: Dictionary = {}
var _reserved_ready: bool = false

# The collection by stamp and by print. It is a flat list, and a codex list asks
# about every stamp of every codex: walking the list each time adds up to seconds.
# Every change to the collection ends in save_collection(), which drops these.
var _owned_by_stamp_code: Dictionary = {}
var _items_by_print_id: Dictionary = {}
var _lookups_ready: bool = false

func ensure_loaded() -> void:
	if is_loaded:
		return

	if StampLibrary.all_stamps.is_empty():
		StampLibrary.load_all_stamps()
	StampPrintLibrary.ensure_loaded()

	var raw_data: Dictionary = SaveIO.read_json(COLLECTION_PATH)
	if !raw_data.is_empty():
		var previous_schema_version: int = int(raw_data.get("schema_version", 1))
		collection_data = _normalize_collection(raw_data)
		is_loaded = true
		if _should_reset_outdated_local_collection(previous_schema_version, collection_data):
			collection_data = _create_default_collection()
		else:
			_add_missing_default_collection_prints()
		_settle_codex_copies_once()
		save_collection()
		return

	collection_data = _create_default_collection()
	is_loaded = true
	_settle_codex_copies_once()
	save_collection()

# --- Free copies ---------------------------------------------------------------

## Copies of the print the player can still use: owned, less those in codexes
## and on Bourse lots. `ignore_deck_id` leaves that codex's copies out of the
## reckoning, for the codex being edited.
func get_free_count_for_print_id(print_id: String, ignore_deck_id: String = "") -> int:
	var normalized_print_id: String = _resolve_print_id(print_id)
	if normalized_print_id.is_empty():
		return 0
	var owned: int = get_owned_count_for_print_id(normalized_print_id)
	var reserved: int = get_reserved_count_for_print_id(normalized_print_id)
	if !ignore_deck_id.is_empty():
		var codexes: Dictionary = _get_reservation(normalized_print_id).get("codexes", {})
		reserved -= int(codexes.get(ignore_deck_id, 0))
	return maxi(0, owned - reserved)

func get_reserved_count_for_print_id(print_id: String) -> int:
	return int(_get_reservation(_resolve_print_id(print_id)).get("total", 0))

## Where the print's taken copies are, for a hover line: codexes by name, then
## the Bourse. [{"kind": "codex", "name": ..., "count": n}, {"kind": "lot", "count": n}]
func get_copy_locations(print_id: String) -> Array[Dictionary]:
	var locations: Array[Dictionary] = []
	var reservation: Dictionary = _get_reservation(_resolve_print_id(print_id))
	var codexes: Dictionary = reservation.get("codexes", {})
	for deck_id in codexes.keys():
		locations.append({
			"kind": "codex",
			"deck_id": str(deck_id),
			"name": str(_deck_names_by_id.get(deck_id, "")),
			"count": int(codexes[deck_id]),
		})
	if int(reservation.get("lot", 0)) > 0:
		locations.append({"kind": "lot", "count": int(reservation.get("lot", 0))})
	return locations

## Drops the cached reservations; the stores that hold copies call it after a change.
func invalidate_reserved_copies() -> void:
	_reserved_ready = false
	copies_changed.emit()

## Gives every print at least as many copies as the codexes and lots hold, and
## returns how many copies that took. The caller saves.
func settle_codex_copies() -> int:
	_reserved_ready = false
	_prepare_reservations()
	var granted: int = 0
	for print_id in _reserved_by_print_id.keys():
		var missing: int = int(_reserved_by_print_id[print_id].get("total", 0)) - get_owned_count_for_print_id(str(print_id))
		if missing > 0 and !_add_print_copy(str(print_id), missing).is_empty():
			granted += missing
			_lookups_ready = false
	return granted

## Takes one copy out of the collection for good (a Bourse sale). Only a free
## copy can go; false when there is none.
func remove_free_print_copy(print_id: String) -> bool:
	var normalized_print_id: String = _resolve_print_id(print_id)
	if get_free_count_for_print_id(normalized_print_id) <= 0:
		return false
	return _remove_print_copies(normalized_print_id, 1)

func _remove_print_copies(print_id: String, amount: int) -> bool:
	var items: Array = _get_items()
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary and _resolve_print_id(str(item.get("print_id", ""))) == print_id:
			var quantity: int = maxi(0, int(item.get("quantity", 0)) - amount)
			if quantity <= 0:
				items.remove_at(index)
			else:
				item["quantity"] = quantity
			collection_data["items"] = items
			var saved: bool = save_collection()
			invalidate_reserved_copies()
			return saved
	return false

func _settle_codex_copies_once() -> void:
	if bool(collection_data.get(CODEX_COPIES_SETTLED_KEY, false)):
		return
	var granted: int = settle_codex_copies()
	collection_data[CODEX_COPIES_SETTLED_KEY] = true
	if granted > 0:
		print("PlayerCollectionStore: gave the codexes the %d copies they were short of." % granted)

func _get_reservation(print_id: String) -> Dictionary:
	if print_id.is_empty():
		return {}
	_prepare_reservations()
	return _reserved_by_print_id.get(print_id, {})

## Built into locals and swapped in at the end: loading the codexes can ask
## about free copies on its own (PlayerDeckStore puts its default codex back
## only when the copies are free), and that inner build must not be counted twice.
func _prepare_reservations() -> void:
	if _reserved_ready:
		return
	var decks: Array = PlayerDeckStore.list_decks()
	var lot_counts: Dictionary = BourseStore.get_reserved_print_counts()
	var reserved: Dictionary = {}
	var deck_names: Dictionary = {}
	for deck in decks:
		if !(deck is Dictionary):
			continue
		var deck_id: String = str(deck.get("deck_id", ""))
		deck_names[deck_id] = str(deck.get("name", ""))
		var stamps = deck.get("stamps", [])
		if !(stamps is Array):
			continue
		for deck_stamp in stamps:
			if deck_stamp is Dictionary:
				_reserve(reserved, _resolve_print_id(str(deck_stamp.get("print_id", ""))), 1, deck_id)
	for print_id_value in lot_counts.keys():
		_reserve(reserved, _resolve_print_id(str(print_id_value)), int(lot_counts[print_id_value]), "")
	_reserved_by_print_id = reserved
	_deck_names_by_id = deck_names
	_reserved_ready = true

## Adds `count` copies of the print to the reservations, for a codex or (with
## no deck id) for the Bourse.
func _reserve(reserved: Dictionary, print_id: String, count: int, deck_id: String) -> void:
	if print_id.is_empty() or count <= 0:
		return
	var reservation: Dictionary = reserved.get(print_id, {"codexes": {}, "lot": 0, "total": 0})
	if deck_id.is_empty():
		reservation["lot"] = int(reservation["lot"]) + count
	else:
		var codexes: Dictionary = reservation["codexes"]
		codexes[deck_id] = int(codexes.get(deck_id, 0)) + count
	reservation["total"] = int(reservation["total"]) + count
	reserved[print_id] = reservation


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

	_prepare_lookups()
	return int(_owned_by_stamp_code.get(get_stamp_code(stamp), 0))

func get_owned_count_for_stamp_code(stamp_code: String) -> int:
	var normalized_stamp_code: String = _resolve_stamp_code(stamp_code)
	if normalized_stamp_code.is_empty():
		return 0

	_prepare_lookups()
	return int(_owned_by_stamp_code.get(normalized_stamp_code, 0))

func get_owned_count_for_print_id(print_id: String) -> int:
	var normalized_print_id: String = _resolve_print_id(print_id)
	if normalized_print_id.is_empty():
		return 0

	_prepare_lookups()
	return int(_items_by_print_id.get(normalized_print_id, {}).get("quantity", 0))

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
	var item: Dictionary = _add_print_copy(print_id, amount)
	if item.is_empty():
		return {}
	save_collection()
	return item.duplicate(true)

## Many copies with a single save, for what comes in together: a save takes long
## enough to be felt when each copy has its own.
func add_local_print_copies(print_ids: Array[String]) -> void:
	ensure_loaded()
	for print_id in print_ids:
		_add_print_copy(print_id, 1)
	save_collection()

## The caller saves.
func _add_print_copy(print_id: String, amount: int) -> Dictionary:
	var stamp_print: StampPrint = StampPrintLibrary.get_print(print_id)
	if stamp_print == null:
		return {}

	_prepare_lookups()
	var item: Dictionary = _items_by_print_id.get(stamp_print.print_id, {})
	if !item.is_empty():
		item["quantity"] = maxi(0, int(item.get("quantity", 0))) + maxi(1, amount)
		return item

	var new_item: Dictionary = _create_collection_item(stamp_print, maxi(1, amount))
	var items: Array = _get_items()
	items.append(new_item)
	collection_data["items"] = items
	_items_by_print_id[stamp_print.print_id] = new_item
	return new_item

## Takes a copy off a stack by its instance id, free or not; nothing in the game
## calls it today. remove_free_print_copy is the one that keeps codexes whole.
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
	_lookups_ready = false
	var saved: bool = SaveIO.write_json(COLLECTION_PATH, collection_data, COLLECTION_SCHEMA_VERSION)
	copies_changed.emit()
	return saved

func _prepare_lookups() -> void:
	if _lookups_ready:
		return
	_owned_by_stamp_code.clear()
	_items_by_print_id.clear()
	for item in _get_items():
		if !(item is Dictionary):
			continue
		var stamp_code: String = _resolve_stamp_code(str(item.get("stamp_code", "")))
		_owned_by_stamp_code[stamp_code] = int(_owned_by_stamp_code.get(stamp_code, 0)) + int(item.get("quantity", 0))
		var print_id: String = _resolve_print_id(str(item.get("print_id", "")))
		if !_items_by_print_id.has(print_id):
			_items_by_print_id[print_id] = item
	_lookups_ready = true

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
	if bool(raw_data.get(CODEX_COPIES_SETTLED_KEY, false)):
		normalized[CODEX_COPIES_SETTLED_KEY] = true


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
