extends RefCounted
class_name PortraitLibrary

const PORTRAIT_DIR: String = "res://Portraits"
const PORTRAIT_ASSET_DIR: String = "res://Assets/Portraits"
const GENERATION_CONFIG_PATH: String = "res://Assets/Portraits/portrait_generation.json"
const PORTRAIT_ASSET_MANIFEST = preload("res://Scripts/PortraitAssetManifest.gd")

const PNG_LAYER_ORDER: Array[String] = [
	"hair",
	"facial_hair",
	"eyebrows",
	"pupils",
	"eyelash",
	"eyewhite",
	"nose",
	"mouth",
	"head",
	"body",
	"neck",
]

const REQUIRED_PNG_CATEGORIES: Array[String] = [
	"hair",
	"facial_hair",
	"eyebrows",
	"pupils",
	"eyelash",
	"eyewhite",
	"nose",
	"mouth",
	"head",
	"body",
	"neck",
]

const CATEGORY_ALIASES: Dictionary = {
	"hai": "hair",
	"brows": "eyebrows",
	"eyebrow": "eyebrows",
	"mustache": "facial_hair",
	"pupil": "pupils",
	"torso": "body",
	"eyes": "eyewhite",
}

static var texture_cache: Dictionary = {}
static var part_paths_cache: Dictionary = {}

static func get_part_texture(category: String, part_id: String) -> Texture2D:
	var resolved_path: String = get_part_path(category, part_id)
	if resolved_path.is_empty():
		return null
	if texture_cache.has(resolved_path):
		return texture_cache[resolved_path]

	var normalized_category: String = normalize_category(category)
	var resolved_id: String = resolved_path.get_file().get_basename()
	var manifest_texture: Texture2D = PORTRAIT_ASSET_MANIFEST.get_texture(normalized_category, resolved_id)
	if manifest_texture != null:
		texture_cache[resolved_path] = manifest_texture
		return manifest_texture

	var texture: Texture2D = load(resolved_path) as Texture2D
	if texture != null:
		texture_cache[resolved_path] = texture
	return texture

static func get_part_path(category: String, part_id: String) -> String:
	var normalized_category: String = normalize_category(category)
	var part_paths: Dictionary = get_part_paths()
	if !part_paths.has(normalized_category):
		return ""

	var category_paths: Dictionary = part_paths[normalized_category]
	var resolved_id: String = str(part_id).strip_edges()
	if category_paths.has(resolved_id):
		return str(category_paths[resolved_id])

	var fallback_id: String = get_default_part_id(normalized_category)
	if category_paths.has(fallback_id):
		return str(category_paths[fallback_id])
	return ""

static func get_part_paths() -> Dictionary:
	if !part_paths_cache.is_empty():
		return part_paths_cache

	var paths: Dictionary = {}
	for category in REQUIRED_PNG_CATEGORIES:
		paths[category] = collect_category_part_paths(category)

	part_paths_cache = paths
	return part_paths_cache

static func collect_category_part_paths(category: String) -> Dictionary:
	var output: Dictionary = PORTRAIT_ASSET_MANIFEST.get_part_paths(category)
	var category_dir_path: String = "%s/%s" % [PORTRAIT_ASSET_DIR, category]
	var dir := DirAccess.open(category_dir_path)
	if dir == null:
		return output

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while !file_name.is_empty():
		var resource_file_name: String = file_name.trim_suffix(".remap")
		if !dir.current_is_dir() and resource_file_name.get_extension().to_lower() == "png":
			var part_id: String = resource_file_name.get_basename()
			output[part_id] = "%s/%s" % [category_dir_path, resource_file_name]
		file_name = dir.get_next()
	dir.list_dir_end()

	return output

static func normalize_category(category: String) -> String:
	var normalized: String = str(category).strip_edges().to_lower()
	return str(CATEGORY_ALIASES.get(normalized, normalized))

static func get_default_part_id(category: String) -> String:
	var ids: Array[String] = get_part_ids_for_set(category, PortraitConfig.DEFAULT_PORTRAIT_SET_ID)
	if ids.is_empty():
		return ""
	return ids[0]

static func get_default_player_portrait() -> PortraitConfig:
	var config: PortraitConfig = create_random_portrait(17)
	config.portrait_id = "default_player"
	config.display_name = "Player"
	return config

static func get_default_portrait_for_player_id(player_id: int) -> PortraitConfig:
	if player_id == 0:
		return get_default_player_portrait()
	return create_ai_portrait(player_id, 1)

static func get_tutorial_portrait() -> PortraitConfig:
	var config: PortraitConfig = create_random_portrait(42)
	config.portrait_id = "tutorial_mentor"
	config.display_name = "Mentor"
	return config

static func get_story_portrait(index: int) -> PortraitConfig:
	var safe_index: int = wrapi(index - 1, 0, 12) + 1
	var config: PortraitConfig = create_random_portrait(1000 + safe_index)
	config.portrait_id = "story_opponent_%02d" % safe_index
	config.display_name = "Opponent %02d" % safe_index
	return config

static func create_ai_portrait(player_id: int, difficulty_level: int) -> PortraitConfig:
	var seed: int = 3000 + player_id * 173 + difficulty_level * 31
	var config: PortraitConfig = create_random_portrait(seed)
	config.portrait_id = "ai_%d_%d" % [player_id, difficulty_level]
	config.display_name = "AI %s" % ("White" if player_id == 0 else "Black")
	return config

static func create_level_one_ai_portrait(player_id: int) -> PortraitConfig:
	return create_ai_portrait(player_id, 1)

static func create_random_portrait(seed: int = 0) -> PortraitConfig:
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(1, seed if seed != 0 else int(Time.get_unix_time_from_system()))

	var config: PortraitConfig = create_base_portrait_config(int(rng.seed))
	config.portrait_id = "generated_%d" % config.seed

	var set_id: String = pick(rng, get_enabled_portrait_sets())
	config.portrait_set_id = set_id
	config.png_part_ids = pick_png_parts_for_set(rng, set_id)
	apply_legacy_part_aliases(config)
	return config

static func create_base_portrait_config(seed: int) -> PortraitConfig:
	var config := PortraitConfig.new()
	config.seed = maxi(1, seed)
	config.use_asset_colors = true
	config.portrait_set_id = PortraitConfig.DEFAULT_PORTRAIT_SET_ID
	config.canvas_size = Vector2(249.0, 316.0)
	config.head_origin = Vector2.ZERO
	config.head_pivot = Vector2(124.5, 170.0)
	config.torso_layer_offset = Vector2.ZERO
	config.layer_offsets = get_zero_layer_offsets()
	config.look_down_pupil_offset = Vector2(0.0, 4.0)
	config.look_down_eyelid_drop_pixels = 4.0
	config.look_down_head_offset = Vector2(0.0, 2.2)
	config.look_down_head_scale = Vector2(1.012, 0.985)
	config.look_down_layer_offsets = {
		"hair": Vector2(0.0, -0.8),
		"facial_hair": Vector2(0.0, 1.0),
		"eyebrows": Vector2(0.0, 2.0),
		"eyelash": Vector2(0.0, 2.8),
		"eyewhite": Vector2(0.0, 1.4),
		"pupils": Vector2(0.0, 1.8),
		"nose": Vector2(0.0, 1.3),
		"mouth": Vector2(0.0, 0.8),
	}
	config.png_part_ids = get_default_png_parts_for_set(config.portrait_set_id)
	apply_legacy_part_aliases(config)
	config.expression = "neutral"
	config.blink_style = "move_eyes"
	config.torso_breath_enabled = true
	config.occasional_head_motion_enabled = true
	return config

static func get_zero_layer_offsets() -> Dictionary:
	var output: Dictionary = {}
	for category in REQUIRED_PNG_CATEGORIES:
		output[category] = Vector2.ZERO
	return output

static func get_enabled_portrait_sets() -> Array[String]:
	var configured_sets: Array[String] = []
	if FileAccess.file_exists(GENERATION_CONFIG_PATH):
		var file := FileAccess.open(GENERATION_CONFIG_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				for raw_set in (parsed as Dictionary).get("portrait_sets", []):
					var set_id: String = str(raw_set).strip_edges().to_upper()
					if !set_id.is_empty() and !configured_sets.has(set_id):
						configured_sets.append(set_id)

	var available_sets: Array[String] = get_available_complete_sets()
	var enabled_sets: Array[String] = []
	for set_id in configured_sets:
		if available_sets.has(set_id):
			enabled_sets.append(set_id)

	if enabled_sets.is_empty():
		enabled_sets = available_sets
	if enabled_sets.is_empty():
		enabled_sets.append(PortraitConfig.DEFAULT_PORTRAIT_SET_ID)
	return enabled_sets

static func get_available_complete_sets() -> Array[String]:
	var available_sets: Array[String] = []
	var part_paths: Dictionary = get_part_paths()

	for category in REQUIRED_PNG_CATEGORIES:
		var category_paths: Dictionary = part_paths.get(category, {})
		for part_id in category_paths.keys():
			var set_id: String = get_part_set_id(str(part_id))
			if set_id.is_empty():
				continue
			if !available_sets.has(set_id):
				available_sets.append(set_id)

	for category in REQUIRED_PNG_CATEGORIES:
		var index: int = available_sets.size() - 1
		while index >= 0:
			if get_part_ids_for_set(category, available_sets[index]).is_empty():
				available_sets.remove_at(index)
			index -= 1

	available_sets.sort()
	return available_sets

static func pick_png_parts_for_set(rng: RandomNumberGenerator, set_id: String) -> Dictionary:
	var parts: Dictionary = {}
	for category in REQUIRED_PNG_CATEGORIES:
		var ids: Array[String] = get_part_ids_for_set(category, set_id)
		if ids.is_empty():
			continue
		parts[category] = pick(rng, ids)
	return parts

static func get_default_png_parts_for_set(set_id: String) -> Dictionary:
	var parts: Dictionary = {}
	for category in REQUIRED_PNG_CATEGORIES:
		var ids: Array[String] = get_part_ids_for_set(category, set_id)
		if !ids.is_empty():
			parts[category] = ids[0]
	return parts

static func get_part_ids_for_set(category: String, set_id: String) -> Array[String]:
	var normalized_category: String = normalize_category(category)
	var normalized_set_id: String = str(set_id).strip_edges().to_upper()
	var ids: Array[String] = []
	var category_paths: Dictionary = get_part_paths().get(normalized_category, {})
	for part_id in category_paths.keys():
		var id_string: String = str(part_id)
		if get_part_set_id(id_string) == normalized_set_id:
			ids.append(id_string)
	ids.sort()
	return ids

static func get_part_set_id(part_id: String) -> String:
	var regex := RegEx.new()
	regex.compile("^([A-Za-z]+)")
	var match_result := regex.search(part_id)
	if match_result == null:
		return ""
	return match_result.get_string(1).to_upper()

static func config_from_data_or_default(data, player_id: int = 0) -> PortraitConfig:
	var config: PortraitConfig
	if data is PortraitConfig:
		config = (data as PortraitConfig).duplicate_config()
	elif data is Dictionary and !(data as Dictionary).is_empty():
		config = PortraitConfig.from_dict(data)
	else:
		config = get_default_portrait_for_player_id(player_id)
	apply_base_portrait_rig(config)
	return config

static func data_from_config(config: PortraitConfig) -> Dictionary:
	if config == null:
		return {}
	return config.to_dict()

static func load_portrait_resource(path: String) -> PortraitConfig:
	if !ResourceLoader.exists(path):
		return null
	var resource := load(path)
	if resource is PortraitConfig:
		var config: PortraitConfig = (resource as PortraitConfig).duplicate_config()
		apply_base_portrait_rig(config)
		return config
	return null

static func apply_base_portrait_rig(config: PortraitConfig) -> void:
	if config == null:
		return

	var base: PortraitConfig = create_base_portrait_config(config.seed)
	config.use_asset_colors = true
	config.canvas_size = base.canvas_size
	config.head_origin = base.head_origin
	config.head_pivot = base.head_pivot
	config.torso_layer_offset = base.torso_layer_offset
	config.layer_offsets = base.layer_offsets.duplicate(true)
	config.look_down_pupil_offset = base.look_down_pupil_offset
	config.look_down_eyelid_drop_pixels = base.look_down_eyelid_drop_pixels
	config.look_down_head_offset = base.look_down_head_offset
	config.look_down_head_scale = base.look_down_head_scale
	config.look_down_layer_offsets = base.look_down_layer_offsets.duplicate(true)
	config.portrait_set_id = normalize_set_id(config.portrait_set_id)
	if config.png_part_ids.is_empty():
		config.png_part_ids = get_default_png_parts_for_set(config.portrait_set_id)
	config.png_part_ids = normalize_png_part_ids(config.portrait_set_id, config.png_part_ids)
	apply_legacy_part_aliases(config)
	config.expression = "neutral"
	config.blink_style = "move_eyes"
	config.torso_breath_enabled = true
	config.occasional_head_motion_enabled = true

static func normalize_set_id(set_id: String) -> String:
	var normalized: String = str(set_id).strip_edges().to_upper()
	if normalized.is_empty():
		normalized = PortraitConfig.DEFAULT_PORTRAIT_SET_ID
	var enabled_sets: Array[String] = get_enabled_portrait_sets()
	if enabled_sets.has(normalized):
		return normalized
	if !enabled_sets.is_empty():
		return enabled_sets[0]
	return PortraitConfig.DEFAULT_PORTRAIT_SET_ID

static func normalize_png_part_ids(set_id: String, raw_parts: Dictionary) -> Dictionary:
	var normalized_parts: Dictionary = {}
	for category in REQUIRED_PNG_CATEGORIES:
		var part_id: String = str(raw_parts.get(category, "")).strip_edges()
		if part_id.is_empty() and raw_parts.has("pupil") and category == "pupils":
			part_id = str(raw_parts["pupil"]).strip_edges()
		if !part_id.is_empty() and get_part_set_id(part_id) == set_id and !get_part_path(category, part_id).is_empty():
			normalized_parts[category] = part_id
			continue

		var ids: Array[String] = get_part_ids_for_set(category, set_id)
		if !ids.is_empty():
			normalized_parts[category] = ids[0]
	return normalized_parts

static func apply_legacy_part_aliases(config: PortraitConfig) -> void:
	config.hair_id = str(config.png_part_ids.get("hair", ""))
	config.mustache_id = str(config.png_part_ids.get("facial_hair", ""))
	config.brows_id = str(config.png_part_ids.get("eyebrows", ""))
	config.pupils_id = str(config.png_part_ids.get("pupils", ""))
	config.eyes_id = str(config.png_part_ids.get("eyewhite", ""))
	config.closed_eyes_id = ""
	config.nose_id = str(config.png_part_ids.get("nose", ""))
	config.mouth_id = str(config.png_part_ids.get("mouth", ""))
	config.head_id = str(config.png_part_ids.get("head", ""))
	config.torso_id = str(config.png_part_ids.get("body", ""))

static func get_render_order_z_index(category: String) -> int:
	var normalized_category: String = normalize_category(category)
	var index: int = PNG_LAYER_ORDER.find(normalized_category)
	if index < 0:
		return 0
	return PNG_LAYER_ORDER.size() - index

static func pick(rng: RandomNumberGenerator, values: Array):
	if values.is_empty():
		return null
	return values[rng.randi_range(0, values.size() - 1)]
