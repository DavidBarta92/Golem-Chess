extends RefCounted
class_name PortraitLibrary

const PORTRAIT_DIR: String = "res://Portraits"
const PLACEHOLDER_ASSET_DIR: String = "res://Assets/Portraits/Placeholders"

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
		},
		"torso": {
			"torso_01": "%s/torso_01.svg" % PLACEHOLDER_ASSET_DIR,
			"torso_02": "%s/torso_02.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"hair": {
			"hair_01": "%s/hair_01.svg" % PLACEHOLDER_ASSET_DIR,
			"hair_02": "%s/hair_02.svg" % PLACEHOLDER_ASSET_DIR,
			"hair_03": "%s/hair_03.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"eyes": {
			"eyes_01": "%s/eyes_01.svg" % PLACEHOLDER_ASSET_DIR,
			"eyes_02": "%s/eyes_02.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"closed_eyes": {
			"closed_01": "%s/closed_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"pupils": {
			"pupils_01": "%s/pupils_01.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"nose": {
			"nose_01": "%s/nose_01.svg" % PLACEHOLDER_ASSET_DIR,
			"nose_02": "%s/nose_02.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"mouth": {
			"mouth_neutral": "%s/mouth_neutral.svg" % PLACEHOLDER_ASSET_DIR,
			"mouth_smile": "%s/mouth_smile.svg" % PLACEHOLDER_ASSET_DIR,
			"mouth_frown": "%s/mouth_frown.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"brows": {
			"brows_01": "%s/brows_01.svg" % PLACEHOLDER_ASSET_DIR,
			"brows_02": "%s/brows_02.svg" % PLACEHOLDER_ASSET_DIR,
		},
		"mustache": {
			"mustage_01": "%s/mustage_01.svg" % PLACEHOLDER_ASSET_DIR,
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
	var loaded_config: PortraitConfig = load_portrait_resource("%s/default_player.tres" % PORTRAIT_DIR)
	if loaded_config != null:
		return loaded_config

	var config := PortraitConfig.new()
	config.portrait_id = "default_player"
	config.display_name = "Player"
	config.seed = 17
	config.hair_id = "hair_01"
	config.eyes_id = "eyes_01"
	config.nose_id = "nose_01"
	config.mouth_id = "mouth_neutral"
	config.brows_id = "brows_01"
	config.skin_color = Color(0.84, 0.62, 0.48, 1.0)
	config.hair_color = Color(0.18, 0.11, 0.08, 1.0)
	config.eye_color = Color(0.14, 0.36, 0.32, 1.0)
	config.clothing_color = Color(0.15, 0.19, 0.28, 1.0)
	config.accent_color = Color(0.86, 0.68, 0.26, 1.0)
	return config

static func get_default_portrait_for_player_id(player_id: int) -> PortraitConfig:
	if player_id == 0:
		return get_default_player_portrait()
	var loaded_config: PortraitConfig = load_portrait_resource("%s/default_ai.tres" % PORTRAIT_DIR)
	if loaded_config != null:
		loaded_config.display_name = "AI %s" % ("White" if player_id == 0 else "Black")
		return loaded_config
	return create_ai_portrait(player_id, 8)

static func get_tutorial_portrait() -> PortraitConfig:
	var loaded_config: PortraitConfig = load_portrait_resource("%s/tutorial_mentor.tres" % PORTRAIT_DIR)
	if loaded_config != null:
		return loaded_config

	var config := PortraitConfig.new()
	config.portrait_id = "tutorial_mentor"
	config.display_name = "Mentor"
	config.seed = 42
	config.hair_id = "hair_03"
	config.eyes_id = "eyes_02"
	config.nose_id = "nose_02"
	config.mouth_id = "mouth_smile"
	config.brows_id = "brows_01"
	config.expression = "happy"
	config.skin_color = Color(0.78, 0.57, 0.43, 1.0)
	config.hair_color = Color(0.82, 0.78, 0.66, 1.0)
	config.eye_color = Color(0.20, 0.34, 0.48, 1.0)
	config.clothing_color = Color(0.20, 0.16, 0.30, 1.0)
	config.accent_color = Color(0.92, 0.72, 0.28, 1.0)
	return config

static func get_story_portrait(index: int) -> PortraitConfig:
	var safe_index: int = wrapi(index - 1, 0, 12) + 1
	var loaded_config: PortraitConfig = load_portrait_resource("%s/story_opponent_%02d.tres" % [PORTRAIT_DIR, safe_index])
	if loaded_config != null:
		return loaded_config
	return create_random_portrait(1000 + safe_index)

static func create_ai_portrait(player_id: int, difficulty_level: int) -> PortraitConfig:
	if difficulty_level == 1:
		return create_level_one_ai_portrait(player_id)

	var seed: int = 3000 + player_id * 173 + difficulty_level * 31
	var config: PortraitConfig = create_random_portrait(seed)
	config.portrait_id = "ai_%d_%d" % [player_id, difficulty_level]
	config.display_name = "AI %s" % ("White" if player_id == 0 else "Black")
	return config

static func create_level_one_ai_portrait(player_id: int) -> PortraitConfig:
	var config := PortraitConfig.new()
	config.portrait_id = "ai_level_1_%d" % player_id
	config.display_name = "AI %s" % ("White" if player_id == 0 else "Black")
	config.seed = 3204 + player_id
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

static func create_random_portrait(seed: int = 0) -> PortraitConfig:
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(1, seed if seed != 0 else int(Time.get_unix_time_from_system()))

	var config := PortraitConfig.new()
	config.seed = int(rng.seed)
	config.portrait_id = "generated_%d" % config.seed
	config.torso_id = pick(rng, ["torso_01", "torso_02"])
	config.hair_id = pick(rng, ["hair_01", "hair_02", "hair_03"])
	config.eyes_id = pick(rng, ["eyes_01", "eyes_02"])
	config.nose_id = pick(rng, ["nose_01", "nose_02"])
	config.brows_id = pick(rng, ["brows_01", "brows_02"])
	config.mouth_id = pick(rng, ["mouth_neutral", "mouth_smile", "mouth_frown"])
	config.expression = pick(rng, ["neutral", "happy", "stern", "worried"])
	config.skin_color = pick(rng, [
		Color(0.92, 0.68, 0.50, 1.0),
		Color(0.76, 0.52, 0.39, 1.0),
		Color(0.58, 0.38, 0.28, 1.0),
		Color(0.86, 0.71, 0.58, 1.0),
	])
	config.hair_color = pick(rng, [
		Color(0.12, 0.08, 0.06, 1.0),
		Color(0.34, 0.20, 0.11, 1.0),
		Color(0.64, 0.50, 0.28, 1.0),
		Color(0.78, 0.76, 0.68, 1.0),
		Color(0.08, 0.09, 0.12, 1.0),
	])
	config.eye_color = pick(rng, [
		Color(0.13, 0.30, 0.47, 1.0),
		Color(0.18, 0.38, 0.29, 1.0),
		Color(0.40, 0.25, 0.14, 1.0),
		Color(0.38, 0.35, 0.28, 1.0),
	])
	config.clothing_color = pick(rng, [
		Color(0.18, 0.23, 0.34, 1.0),
		Color(0.28, 0.12, 0.16, 1.0),
		Color(0.12, 0.24, 0.20, 1.0),
		Color(0.32, 0.28, 0.20, 1.0),
	])
	config.accent_color = pick(rng, [
		Color(0.86, 0.68, 0.26, 1.0),
		Color(0.58, 0.76, 0.88, 1.0),
		Color(0.82, 0.38, 0.30, 1.0),
		Color(0.72, 0.72, 0.76, 1.0),
	])
	return config

static func config_from_data_or_default(data, player_id: int = 0) -> PortraitConfig:
	if data is PortraitConfig:
		return (data as PortraitConfig).duplicate_config()
	if data is Dictionary and !(data as Dictionary).is_empty():
		return PortraitConfig.from_dict(data)
	return get_default_portrait_for_player_id(player_id)

static func data_from_config(config: PortraitConfig) -> Dictionary:
	if config == null:
		return {}
	return config.to_dict()

static func load_portrait_resource(path: String) -> PortraitConfig:
	if !ResourceLoader.exists(path):
		return null
	var resource := load(path)
	if resource is PortraitConfig:
		return (resource as PortraitConfig).duplicate_config()
	return null

static func pick(rng: RandomNumberGenerator, values: Array):
	if values.is_empty():
		return null
	return values[rng.randi_range(0, values.size() - 1)]
