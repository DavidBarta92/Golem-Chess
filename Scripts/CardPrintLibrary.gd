extends Node

const PRINTS_PATH: String = "res://CardPrints/"
const STANDARD_VARIANT_ID: String = "standard"
const STANDARD_VARIANT_NAME: String = "Standard"

var all_prints: Dictionary = {}
var prints_by_card_code: Dictionary = {}
var is_loaded: bool = false

func _ready() -> void:
	load_all_prints()

func ensure_loaded() -> void:
	if is_loaded:
		return
	load_all_prints()

func load_all_prints() -> void:
	all_prints.clear()
	prints_by_card_code.clear()
	if CardLibrary.all_cards.is_empty():
		CardLibrary.load_all_cards()

	_create_implicit_standard_prints()
	_load_explicit_prints()
	is_loaded = true
	DebugLog.info("CardPrintLibrary loaded: %d prints" % all_prints.size())

func get_print(print_id: String) -> CardPrint:
	ensure_loaded()
	return all_prints.get(print_id)

func get_prints_for_card_code(card_code: String) -> Array:
	ensure_loaded()
	var prints: Array = prints_by_card_code.get(card_code, [])
	return prints.duplicate()

func get_all_prints() -> Array:
	ensure_loaded()
	var prints: Array = all_prints.values()
	prints.sort_custom(_sort_prints)
	return prints

func get_card_for_print(card_print: CardPrint) -> Card:
	if card_print == null:
		return null
	return CardLibrary.get_card_by_code(card_print.card_code)

func get_default_print_id_for_card_code(card_code: String) -> String:
	return get_print_id(card_code, STANDARD_VARIANT_ID)

func get_print_id(card_code: String, variant_id: String) -> String:
	var normalized_variant_id: String = normalize_variant_id(variant_id)
	return "%s.%s" % [card_code.strip_edges(), normalized_variant_id]

func normalize_variant_id(variant_id: String) -> String:
	var normalized: String = variant_id.strip_edges()
	if normalized.is_empty() or normalized == "basic" or normalized == "common":
		return STANDARD_VARIANT_ID
	return normalized

func get_variant_name(variant_id: String) -> String:
	match normalize_variant_id(variant_id):
		"foil":
			return "Foil"
		"full_art":
			return "Full Art"
		_:
			return STANDARD_VARIANT_NAME

func _create_implicit_standard_prints() -> void:
	var card_codes: Array = CardLibrary.get_all_card_codes()
	card_codes.sort()
	for card_code_value in card_codes:
		var card_code: String = str(card_code_value)
		var card_print := CardPrint.new()
		card_print.card_code = card_code
		card_print.variant_id = STANDARD_VARIANT_ID
		card_print.variant_name = STANDARD_VARIANT_NAME
		card_print.print_id = get_print_id(card_code, STANDARD_VARIANT_ID)
		_register_print(card_print)

func _load_explicit_prints() -> void:
	var dir := DirAccess.open(PRINTS_PATH)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			var resource_file_name: String = file_name.trim_suffix(".remap")
			if resource_file_name.ends_with(".tres"):
				var card_print := load(PRINTS_PATH + resource_file_name) as CardPrint
				if card_print != null:
					_prepare_explicit_print(card_print)
					_register_print(card_print)
		file_name = dir.get_next()
	dir.list_dir_end()

func _prepare_explicit_print(card_print: CardPrint) -> void:
	card_print.card_code = card_print.card_code.strip_edges()
	card_print.variant_id = normalize_variant_id(card_print.variant_id)
	if card_print.variant_name.strip_edges().is_empty():
		card_print.variant_name = get_variant_name(card_print.variant_id)
	if card_print.print_id.strip_edges().is_empty():
		card_print.print_id = get_print_id(card_print.card_code, card_print.variant_id)

func _register_print(card_print: CardPrint) -> void:
	if card_print == null or card_print.card_code.strip_edges().is_empty():
		return
	if card_print.print_id.strip_edges().is_empty():
		card_print.print_id = get_print_id(card_print.card_code, card_print.variant_id)

	all_prints[card_print.print_id] = card_print
	var card_prints: Array = prints_by_card_code.get(card_print.card_code, [])
	for index in range(card_prints.size()):
		var existing := card_prints[index] as CardPrint
		if existing != null && existing.print_id == card_print.print_id:
			card_prints[index] = card_print
			prints_by_card_code[card_print.card_code] = card_prints
			return

	card_prints.append(card_print)
	card_prints.sort_custom(_sort_prints)
	prints_by_card_code[card_print.card_code] = card_prints

func _sort_prints(a: CardPrint, b: CardPrint) -> bool:
	var a_card: Card = get_card_for_print(a)
	var b_card: Card = get_card_for_print(b)
	var a_name: String = a_card.card_name if a_card != null else a.card_code
	var b_name: String = b_card.card_name if b_card != null else b.card_code
	if a_name == b_name:
		return _variant_sort_key(a.variant_id) < _variant_sort_key(b.variant_id)
	return a_name < b_name

func _variant_sort_key(variant_id: String) -> int:
	match normalize_variant_id(variant_id):
		STANDARD_VARIANT_ID:
			return 0
		"foil":
			return 1
		"full_art":
			return 2
		_:
			return 99
