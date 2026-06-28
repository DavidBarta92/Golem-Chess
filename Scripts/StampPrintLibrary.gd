extends Node

const PRINTS_PATH: String = "res://StampPrints/"
const STANDARD_VARIANT_ID: String = "standard"
const STANDARD_VARIANT_NAME: String = "Standard"

var all_prints: Dictionary = {}
var prints_by_stamp_code: Dictionary = {}
var is_loaded: bool = false

func _ready() -> void:
	load_all_prints()

func ensure_loaded() -> void:
	if is_loaded:
		return
	load_all_prints()

func load_all_prints() -> void:
	all_prints.clear()
	prints_by_stamp_code.clear()
	if StampLibrary.all_stamps.is_empty():
		StampLibrary.load_all_stamps()

	_create_implicit_standard_prints()
	_load_explicit_prints()
	is_loaded = true
	DebugLog.info("StampPrintLibrary loaded: %d prints" % all_prints.size())

func get_print(print_id: String) -> StampPrint:
	ensure_loaded()
	return all_prints.get(resolve_print_id_alias(print_id))

func get_prints_for_stamp_code(stamp_code: String) -> Array:
	ensure_loaded()
	var normalized_stamp_code: String = StampLibrary.resolve_stamp_code_alias(stamp_code)
	var prints: Array = prints_by_stamp_code.get(normalized_stamp_code, [])
	return prints.duplicate()

func get_all_prints() -> Array:
	ensure_loaded()
	var prints: Array = all_prints.values()
	prints.sort_custom(_sort_prints)
	return prints

func get_stamp_for_print(stamp_print: StampPrint) -> Stamp:
	if stamp_print == null:
		return null
	return StampLibrary.get_stamp_by_code(stamp_print.stamp_code)

func get_default_print_id_for_stamp_code(stamp_code: String) -> String:
	return get_print_id(stamp_code, STANDARD_VARIANT_ID)

func get_print_id(stamp_code: String, variant_id: String) -> String:
	var normalized_stamp_code: String = StampLibrary.resolve_stamp_code_alias(stamp_code)
	var normalized_variant_id: String = normalize_variant_id(variant_id)
	return "%s.%s" % [normalized_stamp_code, normalized_variant_id]

func resolve_print_id_alias(print_id: String) -> String:
	var normalized_print_id: String = print_id.strip_edges()
	if normalized_print_id.is_empty():
		return ""

	var parts: PackedStringArray = normalized_print_id.split(".", false, 1)
	if parts.size() < 2:
		return StampLibrary.resolve_stamp_code_alias(normalized_print_id)

	var normalized_stamp_code: String = StampLibrary.resolve_stamp_code_alias(parts[0])
	var normalized_variant_id: String = normalize_variant_id(parts[1])
	return get_print_id(normalized_stamp_code, normalized_variant_id)

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
	var stamp_codes: Array = StampLibrary.get_all_stamp_codes()
	stamp_codes.sort()
	for stamp_code_value in stamp_codes:
		var stamp_code: String = str(stamp_code_value)
		var stamp_print := StampPrint.new()
		stamp_print.stamp_code = stamp_code
		stamp_print.variant_id = STANDARD_VARIANT_ID
		stamp_print.variant_name = STANDARD_VARIANT_NAME
		stamp_print.print_id = get_print_id(stamp_code, STANDARD_VARIANT_ID)
		_register_print(stamp_print)

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
				var stamp_print := load(PRINTS_PATH + resource_file_name) as StampPrint
				if stamp_print != null:
					_prepare_explicit_print(stamp_print)
					_register_print(stamp_print)
		file_name = dir.get_next()
	dir.list_dir_end()

func _prepare_explicit_print(stamp_print: StampPrint) -> void:
	stamp_print.stamp_code = StampLibrary.resolve_stamp_code_alias(stamp_print.stamp_code)
	stamp_print.variant_id = normalize_variant_id(stamp_print.variant_id)
	if stamp_print.variant_name.strip_edges().is_empty():
		stamp_print.variant_name = get_variant_name(stamp_print.variant_id)
	if stamp_print.print_id.strip_edges().is_empty():
		stamp_print.print_id = get_print_id(stamp_print.stamp_code, stamp_print.variant_id)
	else:
		stamp_print.print_id = resolve_print_id_alias(stamp_print.print_id)

func _register_print(stamp_print: StampPrint) -> void:
	if stamp_print == null or stamp_print.stamp_code.strip_edges().is_empty():
		return
	stamp_print.stamp_code = StampLibrary.resolve_stamp_code_alias(stamp_print.stamp_code)
	stamp_print.variant_id = normalize_variant_id(stamp_print.variant_id)
	if stamp_print.print_id.strip_edges().is_empty():
		stamp_print.print_id = get_print_id(stamp_print.stamp_code, stamp_print.variant_id)
	else:
		stamp_print.print_id = resolve_print_id_alias(stamp_print.print_id)

	all_prints[stamp_print.print_id] = stamp_print
	var stamp_prints: Array = prints_by_stamp_code.get(stamp_print.stamp_code, [])
	for index in range(stamp_prints.size()):
		var existing := stamp_prints[index] as StampPrint
		if existing != null && existing.print_id == stamp_print.print_id:
			stamp_prints[index] = stamp_print
			prints_by_stamp_code[stamp_print.stamp_code] = stamp_prints
			return

	stamp_prints.append(stamp_print)
	stamp_prints.sort_custom(_sort_prints)
	prints_by_stamp_code[stamp_print.stamp_code] = stamp_prints

func _sort_prints(a: StampPrint, b: StampPrint) -> bool:
	var a_stamp: Stamp = get_stamp_for_print(a)
	var b_stamp: Stamp = get_stamp_for_print(b)
	var a_name: String = a_stamp.stamp_name if a_stamp != null else a.stamp_code
	var b_name: String = b_stamp.stamp_name if b_stamp != null else b.stamp_code
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
