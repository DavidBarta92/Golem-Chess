extends Node

const PACKS_PATH: String = "res://Packs/"
const DEFAULT_PACK_ID: String = "basic_pack"

var all_packs: Dictionary = {}
var pack_order: Array[String] = []
var is_loaded: bool = false

func _ready() -> void:
	load_all_packs()

func ensure_loaded() -> void:
	if is_loaded:
		return
	load_all_packs()

func load_all_packs() -> void:
	all_packs.clear()
	pack_order.clear()
	StampPrintLibrary.ensure_loaded()

	var dir := DirAccess.open(PACKS_PATH)
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				var resource_file_name: String = file_name.trim_suffix(".remap")
				if resource_file_name.ends_with(".tres"):
					var pack_definition := load(PACKS_PATH + resource_file_name) as PackDefinition
					if pack_definition != null:
						_prepare_pack(pack_definition)
						_register_pack(pack_definition)
			file_name = dir.get_next()
		dir.list_dir_end()

	is_loaded = true
	DebugLog.info("PackDefinitionLibrary loaded: %d packs" % all_packs.size())

func get_pack(pack_id: String) -> PackDefinition:
	ensure_loaded()
	return all_packs.get(resolve_pack_id(pack_id))

func get_all_packs() -> Array[PackDefinition]:
	ensure_loaded()
	var packs: Array[PackDefinition] = []
	for pack_id in pack_order:
		var pack_definition := all_packs.get(pack_id) as PackDefinition
		if pack_definition != null:
			packs.append(pack_definition)
	return packs

## Packs the shop offers right now: switched on in their definition *and*
## unlocked by the story for this save. Opening an already-owned pack goes
## through get_pack() and is not affected.
func get_available_packs() -> Array[PackDefinition]:
	var available_packs: Array[PackDefinition] = []
	for pack_definition in get_all_packs():
		if !pack_definition.available:
			continue
		if !StoryProgressStore.is_pack_unlocked(pack_definition.get_resolved_id()):
			continue
		available_packs.append(pack_definition)
	return available_packs

func get_first_available_pack() -> PackDefinition:
	var available_packs: Array[PackDefinition] = get_available_packs()
	return available_packs[0] if !available_packs.is_empty() else null

func get_default_pack_id() -> String:
	ensure_loaded()
	if all_packs.has(DEFAULT_PACK_ID):
		return DEFAULT_PACK_ID
	if !pack_order.is_empty():
		return pack_order[0]
	return DEFAULT_PACK_ID

func resolve_pack_id(pack_id: String) -> String:
	var trimmed_id: String = pack_id.strip_edges()
	return trimmed_id if !trimmed_id.is_empty() else get_default_pack_id()

func get_pack_texture(pack_id: String, fallback_texture: Texture2D = null) -> Texture2D:
	var pack_definition: PackDefinition = get_pack(pack_id)
	if pack_definition != null and pack_definition.get_front_texture() != null:
		return pack_definition.get_front_texture()
	return fallback_texture

func get_pack_front_texture(pack_id: String, fallback_texture: Texture2D = null) -> Texture2D:
	var pack_definition: PackDefinition = get_pack(pack_id)
	if pack_definition != null and pack_definition.get_front_texture() != null:
		return pack_definition.get_front_texture()
	return fallback_texture

func get_reward_print_pool(pack_definition: PackDefinition) -> Array[StampPrint]:
	StampPrintLibrary.ensure_loaded()
	var pool_by_id: Dictionary = {}
	if pack_definition == null:
		return _get_all_reward_prints()

	if pack_definition.include_all_standard_prints:
		for stamp_code_value in StampLibrary.get_all_stamp_codes():
			var print_id: String = StampPrintLibrary.get_default_print_id_for_stamp_code(str(stamp_code_value))
			_add_print_to_pool(pool_by_id, StampPrintLibrary.get_print(print_id))

	for stamp in pack_definition.possible_stamps:
		if stamp == null:
			continue
		var stamp_code: String = stamp.stamp_code.strip_edges()
		if stamp_code.is_empty():
			stamp_code = stamp.stamp_name
		var print_id: String = StampPrintLibrary.get_default_print_id_for_stamp_code(stamp_code)
		_add_print_to_pool(pool_by_id, StampPrintLibrary.get_print(print_id))

	for stamp_print in pack_definition.possible_stamp_prints:
		_add_print_to_pool(pool_by_id, stamp_print)

	for print_id_value in pack_definition.stamp_print_ids:
		_add_print_to_pool(pool_by_id, StampPrintLibrary.get_print(str(print_id_value)))

	var pool: Array[StampPrint] = []
	for stamp_print_value in pool_by_id.values():
		var stamp_print := stamp_print_value as StampPrint
		if stamp_print != null:
			pool.append(stamp_print)
	return pool

func _prepare_pack(pack_definition: PackDefinition) -> void:
	if pack_definition.pack_id.strip_edges().is_empty():
		pack_definition.pack_id = pack_definition.get_resolved_id()
	pack_definition.pack_id = pack_definition.pack_id.strip_edges()
	if pack_definition.pack_name.strip_edges().is_empty():
		pack_definition.pack_name = pack_definition.pack_id.capitalize()
	pack_definition.price = maxi(0, pack_definition.price)

func _register_pack(pack_definition: PackDefinition) -> void:
	if pack_definition == null:
		return
	var pack_id: String = pack_definition.get_resolved_id()
	if pack_id.is_empty():
		return
	if !all_packs.has(pack_id):
		pack_order.append(pack_id)
	all_packs[pack_id] = pack_definition

## The stamps of one opened pack. Each slot draws its rarity by the pack's odds,
## then a stamp of that rarity that this pack has not given yet: not the same
## print, and not another print of the same stamp either. With nothing left at
## that rarity it takes the next one down, then up.
func roll_rewards(pack_definition: PackDefinition, count: int) -> Array[StampPrint]:
	var prints_by_rarity: Dictionary = {}
	for stamp_print in get_reward_print_pool(pack_definition):
		var rarity: int = stamp_print.get_rarity()
		if !prints_by_rarity.has(rarity):
			prints_by_rarity[rarity] = []
		prints_by_rarity[rarity].append(stamp_print)
	for prints_value in prints_by_rarity.values():
		(prints_value as Array).shuffle()

	var rewards: Array[StampPrint] = []
	var drawn_stamp_codes: Dictionary = {}
	for i in range(count):
		var drawn: StampPrint = _draw_print(prints_by_rarity, _roll_rarity(pack_definition), drawn_stamp_codes)
		if drawn == null:
			break
		rewards.append(drawn)
		drawn_stamp_codes[drawn.stamp_code] = true
	return rewards

func _roll_rarity(pack_definition: PackDefinition) -> int:
	if pack_definition == null:
		return StampPrint.Rarity.BASIC
	var roll: float = randf()
	if roll < pack_definition.full_art_chance:
		return StampPrint.Rarity.FULL_ART
	if roll < pack_definition.full_art_chance + pack_definition.foil_chance:
		return StampPrint.Rarity.FOIL
	return StampPrint.Rarity.BASIC

func _draw_print(prints_by_rarity: Dictionary, rarity: int, drawn_stamp_codes: Dictionary) -> StampPrint:
	var rarities: Array[int] = []
	for lower_rarity in range(rarity, StampPrint.Rarity.BASIC - 1, -1):
		rarities.append(lower_rarity)
	for higher_rarity in range(rarity + 1, StampPrint.Rarity.FULL_ART + 1):
		rarities.append(higher_rarity)

	for candidate_rarity in rarities:
		var prints: Array = prints_by_rarity.get(candidate_rarity, [])
		while !prints.is_empty():
			var candidate: StampPrint = prints.pop_back()
			if !drawn_stamp_codes.has(candidate.stamp_code):
				return candidate
	return null

func _add_print_to_pool(pool_by_id: Dictionary, stamp_print: StampPrint) -> void:
	# A pack can name a print file directly, so a turned-off print is left out here too.
	if stamp_print == null or !stamp_print.enabled:
		return
	if StampPrintLibrary.get_stamp_for_print(stamp_print) == null:
		return
	pool_by_id[stamp_print.print_id] = stamp_print

func _get_all_reward_prints() -> Array[StampPrint]:
	var pool: Array[StampPrint] = []
	for stamp_print_value in StampPrintLibrary.get_all_prints():
		var stamp_print := stamp_print_value as StampPrint
		if stamp_print != null and StampPrintLibrary.get_stamp_for_print(stamp_print) != null:
			pool.append(stamp_print)
	return pool
