extends Node

var all_stamps: Dictionary = {}  # stamp_code -> Stamp resource

const STAMP_CODE_ALIASES: Dictionary = {
	"grandmaster": "architect",
	"scholar": "logician",
	"jester": "debater",
	"oracle": "advocate",
	"bard": "mediator",
	"herald": "protagonist",
	"traveler": "campaigner",
	"steward": "logistician",
	"guardian": "defender",
	"marshal": "executive",
	"councillor": "consul",
	"craftsman": "virtuoso",
	"ranger": "adventurer",
	"scout": "entrepreneur",
	"troubadour": "entertainer",
}

const STAMP_NAME_ALIASES: Dictionary = {
	"grandmaster": "Architect",
	"scholar": "Logician",
	"jester": "Debater",
	"oracle": "Advocate",
	"bard": "Mediator",
	"herald": "Protagonist",
	"traveler": "Campaigner",
	"steward": "Logistician",
	"guardian": "Defender",
	"marshal": "Executive",
	"councillor": "Consul",
	"craftsman": "Virtuoso",
	"ranger": "Adventurer",
	"scout": "Entrepreneur",
	"troubadour": "Entertainer",
}

func _ready():
	load_all_stamps()
	DebugLog.info("StampLibrary loaded: %d stamps" % all_stamps.size())

func load_all_stamps():
	all_stamps.clear()
	var stamps_path: String = "res://Stamps/"
	var dir: DirAccess = DirAccess.open(stamps_path)

	if dir == null:
		push_error("Stamps folder not found.")
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if !dir.current_is_dir():
			var resource_file_name: String = file_name.trim_suffix(".remap")
			if resource_file_name.ends_with(".tres"):
				var stamp_path: String = stamps_path + resource_file_name
				var stamp: Stamp = load(stamp_path) as Stamp
				if stamp:
					all_stamps[stamp.stamp_name] = stamp
					DebugLog.info("  Loaded: %s (duration: %d)" % [stamp.stamp_name, stamp.duration])
		file_name = dir.get_next()

	dir.list_dir_end()

func get_stamp(stamp_name: String) -> Stamp:
	var normalized_name: String = stamp_name.strip_edges()
	if normalized_name.is_empty():
		return null

	var stamp: Stamp = all_stamps.get(normalized_name)
	if stamp != null:
		return stamp

	var alias_name: String = resolve_stamp_name_alias(normalized_name)
	if alias_name != normalized_name:
		stamp = all_stamps.get(alias_name)
		if stamp != null:
			return stamp

	return get_stamp_by_code(normalized_name)

func get_stamp_by_code(stamp_code: String) -> Stamp:
	var normalized_stamp_code: String = resolve_stamp_code_alias(stamp_code)
	if normalized_stamp_code.is_empty():
		return null

	for stamp_value in all_stamps.values():
		if stamp_value is Stamp:
			var stamp := stamp_value as Stamp
			if resolve_stamp_code_alias(stamp.stamp_code) == normalized_stamp_code:
				return stamp
	return null

func resolve_stamp_code_alias(stamp_code: String) -> String:
	var normalized_stamp_code: String = stamp_code.strip_edges().to_lower()
	if normalized_stamp_code.is_empty():
		return ""
	return str(STAMP_CODE_ALIASES.get(normalized_stamp_code, normalized_stamp_code))

func resolve_stamp_name_alias(stamp_name: String) -> String:
	var normalized_name: String = stamp_name.strip_edges()
	if normalized_name.is_empty():
		return ""
	return str(STAMP_NAME_ALIASES.get(normalized_name.to_lower(), normalized_name))

func get_all_stamp_names() -> Array:
	return all_stamps.keys()

func get_all_stamp_codes() -> Array:
	var stamp_codes: Array = []
	for stamp_value in all_stamps.values():
		if stamp_value is Stamp:
			var stamp := stamp_value as Stamp
			var stamp_code := stamp.stamp_code.strip_edges()
			stamp_codes.append(stamp_code if !stamp_code.is_empty() else stamp.stamp_name)
	return stamp_codes

func duplicate_stamp(stamp_name: String) -> Stamp:
	var original = get_stamp(stamp_name)
	if original:
		return original.duplicate()
	return null
