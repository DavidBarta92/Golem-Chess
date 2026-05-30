extends RefCounted
class_name PortraitLibrary

const PORTRAIT_DIR: String = "res://Portraits"
const PLACEHOLDER_ASSET_DIR: String = "res://Assets/Portraits/Placeholders"

const HEAD_LIGHT_IDS: Array[String] = ["head_01", "head_narrow_01", "head_round_01", "head_long_01", "head_square_01"]
const HEAD_DARK_IDS: Array[String] = ["head_dark_01", "head_dark_narrow_01", "head_dark_round_01", "head_dark_long_01", "head_dark_square_01"]
const TORSO_IDS: Array[String] = ["torso_01", "torso_dark_01"]
const HAIR_IDS: Array[String] = ["hair_01", "hair_brown_01", "hair_blond_01"]
const BROWS_IDS: Array[String] = ["brows_01", "brows_brown_01", "brows_blond_01"]
const PUPILS_IDS: Array[String] = ["pupils_01", "pupils_blue_01", "pupils_brown_01"]
const NOSE_LIGHT_IDS: Array[String] = ["nose_01", "nose_narrow_01", "nose_wide_01", "nose_round_01"]
const NOSE_DARK_IDS: Array[String] = ["nose_dark_01", "nose_dark_narrow_01", "nose_dark_wide_01", "nose_dark_round_01"]
const MUSTACHE_IDS: Array[String] = ["mustage_01", "mustage_brown_01", "mustage_blond_01"]

static var texture_cache: Dictionary = {}

static func get_part_texture(category: String, part_id: String) -> Texture2D:
	var resolved_path: String = get_part_path(category, part_id)
	if resolved_path.is_empty():
		return null
	if texture_cache.has(resolved_path):
		return texture_cache[resolved_path]

	var texture: Texture2D = load(resolved_path) as Texture2D
	if texture != null:
		texture_cache[resolved_path] = texture
	return texture

static func get_part_path(category: String, part_id: String) -> String:
	var part_paths: Dictionary = get_part_paths()
	if !part_paths.has(category):
		return ""

	var category_paths: Dictionary = part_paths[category]
	var resolved_id: String = str(part_id).strip_edges()
	if category_paths.has(resolved_id):
		return str(category_paths[resolved_id])

	var fallback_id: String = get_default_part_id(category)
	if category_paths.has(fallback_id):
		return str(category_paths[fallback_id])
	return ""

static func get_part_paths() -> Dictionary:
	return {
		"head": {
			"head_01": "%s/head_01.svg" % PLACEHOLDER_ASSET_DIR,
			"head_narrow_01": "%s/head_narrow_01.svg" % PLACEHOLDER_ASSET_DIR,
			"head_round_01": "%s/head_round_01.svg" % PLACEHOLDER_ASSET_DIR,
			"head_long_01": "%s/head_long_01.svg" % PLACEHOLDER_ASSET_DIR,
			"head_square_01": "%s/head_square_01.svg" % PLACEHOLDER_ASSET_DIR,
			"head_dark_01": "%s/head_dark_01.svg" % PLACEHOLDER_ASSET_DIR,
			"head_dark_narrow_01": "%s/head_dark_narrow_01.svg" % PLACEHOLDER_ASSET_DIR,
			"head_dark_round_01": "%s/head_dark_round_01.svg" % PLACEHOLDER_ASSET_DIR,
			"head_dark_long_01": "%s/head_dark_long_01.svg" % PLACEHOLDER_ASSET_DIR,
			"head_dark_square_01": "%s/head_dark_square_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"torso": {
			"torso_01": "%s/torso_01.svg" % PLACEHOLDER_ASSET_DIR,
			"torso_dark_01": "%s/torso_dark_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"hair": {
			"hair_01": "%s/hair_01.svg" % PLACEHOLDER_ASSET_DIR,
			"hair_brown_01": "%s/hair_brown_01.svg" % PLACEHOLDER_ASSET_DIR,
			"hair_blond_01": "%s/hair_blond_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"eyes": {
			"eyes_01": "%s/eyes_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"closed_eyes": {
			"closed_01": "%s/closed_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"pupils": {
			"pupils_01": "%s/pupils_01.svg" % PLACEHOLDER_ASSET_DIR,
			"pupils_blue_01": "%s/pupils_blue_01.svg" % PLACEHOLDER_ASSET_DIR,
			"pupils_brown_01": "%s/pupils_brown_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"nose": {
			"nose_01": "%s/nose_01.svg" % PLACEHOLDER_ASSET_DIR,
			"nose_narrow_01": "%s/nose_narrow_01.svg" % PLACEHOLDER_ASSET_DIR,
			"nose_wide_01": "%s/nose_wide_01.svg" % PLACEHOLDER_ASSET_DIR,
			"nose_round_01": "%s/nose_round_01.svg" % PLACEHOLDER_ASSET_DIR,
			"nose_dark_01": "%s/nose_dark_01.svg" % PLACEHOLDER_ASSET_DIR,
			"nose_dark_narrow_01": "%s/nose_dark_narrow_01.svg" % PLACEHOLDER_ASSET_DIR,
			"nose_dark_wide_01": "%s/nose_dark_wide_01.svg" % PLACEHOLDER_ASSET_DIR,
			"nose_dark_round_01": "%s/nose_dark_round_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"mouth": {
			"mouth_neutral": "%s/mouth_neutral.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"brows": {
			"brows_01": "%s/brows_01.svg" % PLACEHOLDER_ASSET_DIR,
			"brows_brown_01": "%s/brows_brown_01.svg" % PLACEHOLDER_ASSET_DIR,
			"brows_blond_01": "%s/brows_blond_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"mustache": {
			"mustage_01": "%s/mustage_01.svg" % PLACEHOLDER_ASSET_DIR,
			"mustage_brown_01": "%s/mustage_brown_01.svg" % PLACEHOLDER_ASSET_DIR,
			"mustage_blond_01": "%s/mustage_blond_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
	}

static func get_default_part_id(category: String) -> String:
	match category:
		"head":
			return PortraitConfig.DEFAULT_HEAD_ID
		"torso":
			return PortraitConfig.DEFAULT_TORSO_ID
		"hair":
			return PortraitConfig.DEFAULT_HAIR_ID
		"eyes":
			return PortraitConfig.DEFAULT_EYES_ID
		"closed_eyes":
			return PortraitConfig.DEFAULT_CLOSED_EYES_ID
		"pupils":
			return PortraitConfig.DEFAULT_PUPILS_ID
		"nose":
			return PortraitConfig.DEFAULT_NOSE_ID
		"mouth":
			return PortraitConfig.DEFAULT_MOUTH_ID
		"brows":
			return PortraitConfig.DEFAULT_BROWS_ID
		"mustache":
			return PortraitConfig.DEFAULT_MUSTACHE_ID
	return ""

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

	var skin_index: int = rng.randi_range(0, 1)
	config.head_id = pick(rng, get_head_ids_for_skin_index(skin_index))
	config.torso_id = TORSO_IDS[mini(skin_index, TORSO_IDS.size() - 1)]
	config.nose_id = pick(rng, get_nose_ids_for_skin_index(skin_index))

	var hair_index: int = rng.randi_range(0, HAIR_IDS.size() - 1)
	config.hair_id = HAIR_IDS[hair_index]
	config.brows_id = BROWS_IDS[mini(hair_index, BROWS_IDS.size() - 1)]
	config.mustache_id = MUSTACHE_IDS[mini(hair_index, MUSTACHE_IDS.size() - 1)]
	config.pupils_id = pick(rng, PUPILS_IDS)
	return config

static func create_base_portrait_config(seed: int) -> PortraitConfig:
	var config := PortraitConfig.new()
	config.seed = maxi(1, seed)
	config.use_asset_colors = true
	config.canvas_size = Vector2(595.28, 841.89)
	config.head_origin = Vector2(51.72, 63.89)
	config.head_pivot = Vector2(307.72, 359.89)
	config.torso_layer_offset = Vector2(2.13, 262.35)
	config.layer_offsets = {
		"torso": Vector2(2.13, 262.35),
		"head": Vector2(51.72, 63.89),
		"hair": Vector2(57.10, 61.52),
		"eyes": Vector2(51.17, 81.91),
		"pupils": Vector2(53.70, 71.90),
		"brows": Vector2(57.22, 111.52),
		"nose": Vector2(40.16, 65.22),
		"mouth": Vector2(50.89, 73.23),
		"mustache": Vector2(51.12, 165.30),
	}
	config.look_down_pupil_offset = Vector2(0.0, 7.0)
	config.look_down_eyelid_drop_pixels = 5.5
	config.look_down_head_offset = Vector2(0.0, 3.5)
	config.look_down_head_scale = Vector2(1.012, 0.985)
	config.look_down_layer_offsets = {
		"hair": Vector2(0.0, -1.0),
		"brows": Vector2(0.0, 3.0),
		"eyes": Vector2(0.0, 4.0),
		"pupils": Vector2(0.0, 2.0),
		"nose": Vector2(0.0, 2.2),
		"mouth": Vector2(0.0, 1.2),
		"mustache": Vector2(0.0, 1.6),
	}
	config.torso_id = "torso_01"
	config.head_id = "head_01"
	config.hair_id = "hair_01"
	config.eyes_id = "eyes_01"
	config.closed_eyes_id = ""
	config.pupils_id = "pupils_01"
	config.nose_id = "nose_01"
	config.mouth_id = "mouth_neutral"
	config.brows_id = "brows_01"
	config.mustache_id = "mustage_01"
	config.expression = "neutral"
	config.blink_style = "move_eyes"
	config.torso_breath_enabled = true
	config.occasional_head_motion_enabled = true
	return config

static func get_head_ids_for_skin_index(skin_index: int) -> Array[String]:
	if skin_index <= 0:
		return HEAD_LIGHT_IDS
	return HEAD_DARK_IDS

static func get_nose_ids_for_skin_index(skin_index: int) -> Array[String]:
	if skin_index <= 0:
		return NOSE_LIGHT_IDS
	return NOSE_DARK_IDS

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
	config.eyes_id = normalize_part_id("eyes", config.eyes_id)
	config.closed_eyes_id = ""
	config.mouth_id = normalize_part_id("mouth", config.mouth_id)
	config.head_id = normalize_part_id("head", config.head_id)
	config.torso_id = normalize_part_id("torso", config.torso_id)
	config.hair_id = normalize_part_id("hair", config.hair_id)
	config.pupils_id = normalize_part_id("pupils", config.pupils_id)
	config.nose_id = normalize_part_id("nose", config.nose_id)
	config.brows_id = normalize_part_id("brows", config.brows_id)
	config.mustache_id = normalize_part_id("mustache", config.mustache_id)
	config.expression = "neutral"
	config.blink_style = "move_eyes"
	config.torso_breath_enabled = true
	config.occasional_head_motion_enabled = true

static func normalize_part_id(category: String, part_id: String) -> String:
	var category_paths: Dictionary = get_part_paths().get(category, {})
	var resolved_id: String = str(part_id).strip_edges()
	if category_paths.has(resolved_id):
		return resolved_id
	return get_default_part_id(category)

static func pick(rng: RandomNumberGenerator, values: Array):
	if values.is_empty():
		return null
	return values[rng.randi_range(0, values.size() - 1)]
