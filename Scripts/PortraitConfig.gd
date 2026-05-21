extends Resource
class_name PortraitConfig

const DEFAULT_HEAD_ID: String = "head_01"
const DEFAULT_TORSO_ID: String = "torso_01"
const DEFAULT_HAIR_ID: String = "hair_01"
const DEFAULT_EYES_ID: String = "eyes_01"
const DEFAULT_CLOSED_EYES_ID: String = "closed_01"
const DEFAULT_PUPILS_ID: String = "pupils_01"
const DEFAULT_NOSE_ID: String = "nose_01"
const DEFAULT_MOUTH_ID: String = "mouth_neutral"
const DEFAULT_BROWS_ID: String = "brows_01"
const DEFAULT_MUSTACHE_ID: String = ""

@export var portrait_id: String = "portrait"
@export var display_name: String = ""
@export var seed: int = 1
@export var use_asset_colors: bool = false

@export_group("Parts")
@export var head_id: String = DEFAULT_HEAD_ID
@export var torso_id: String = DEFAULT_TORSO_ID
@export var hair_id: String = DEFAULT_HAIR_ID
@export var eyes_id: String = DEFAULT_EYES_ID
@export var closed_eyes_id: String = DEFAULT_CLOSED_EYES_ID
@export var pupils_id: String = DEFAULT_PUPILS_ID
@export var nose_id: String = DEFAULT_NOSE_ID
@export var mouth_id: String = DEFAULT_MOUTH_ID
@export var brows_id: String = DEFAULT_BROWS_ID
@export var mustache_id: String = DEFAULT_MUSTACHE_ID

@export_group("Colors")
@export var skin_color: Color = Color(0.86, 0.62, 0.47, 1.0)
@export var hair_color: Color = Color(0.16, 0.105, 0.075, 1.0)
@export var eye_color: Color = Color(0.16, 0.34, 0.32, 1.0)
@export var clothing_color: Color = Color(0.18, 0.22, 0.31, 1.0)
@export var accent_color: Color = Color(0.86, 0.67, 0.25, 1.0)
@export var mouth_color: Color = Color(0.36, 0.10, 0.11, 1.0)

@export_group("Mood")
@export_enum("neutral", "happy", "stern", "worried") var expression: String = "neutral"

@export_group("Layout")
@export var canvas_size: Vector2 = Vector2(512, 512)
@export var head_origin: Vector2 = Vector2.ZERO
@export var head_pivot: Vector2 = Vector2(256, 296)
@export var torso_layer_offset: Vector2 = Vector2.ZERO
@export var layer_offsets: Dictionary = {}

@export_group("Look Down Pose")
@export var look_down_pupil_offset: Vector2 = Vector2(0.0, 7.0)
@export var look_down_eyelid_drop_pixels: float = 5.5
@export var look_down_head_offset: Vector2 = Vector2(0.0, 3.5)
@export var look_down_head_scale: Vector2 = Vector2(1.012, 0.985)
@export var look_down_layer_offsets: Dictionary = {}

@export_group("Animation")
@export_enum("swap_closed", "move_eyes") var blink_style: String = "swap_closed"
@export var torso_breath_enabled: bool = true
@export var occasional_head_motion_enabled: bool = true

func duplicate_config() -> PortraitConfig:
	var config := PortraitConfig.new()
	config.apply_dict(to_dict())
	return config

func to_dict() -> Dictionary:
	return {
		"portrait_id": portrait_id,
		"display_name": display_name,
		"seed": seed,
		"use_asset_colors": use_asset_colors,
		"head_id": head_id,
		"torso_id": torso_id,
		"hair_id": hair_id,
		"eyes_id": eyes_id,
		"closed_eyes_id": closed_eyes_id,
		"pupils_id": pupils_id,
		"nose_id": nose_id,
		"mouth_id": mouth_id,
		"brows_id": brows_id,
		"mustache_id": mustache_id,
		"skin_color": color_to_array(skin_color),
		"hair_color": color_to_array(hair_color),
		"eye_color": color_to_array(eye_color),
		"clothing_color": color_to_array(clothing_color),
		"accent_color": color_to_array(accent_color),
		"mouth_color": color_to_array(mouth_color),
		"expression": expression,
		"canvas_size": vector2_to_array(canvas_size),
		"head_origin": vector2_to_array(head_origin),
		"head_pivot": vector2_to_array(head_pivot),
		"torso_layer_offset": vector2_to_array(torso_layer_offset),
		"layer_offsets": vector2_dict_to_array_dict(layer_offsets),
		"look_down_pupil_offset": vector2_to_array(look_down_pupil_offset),
		"look_down_eyelid_drop_pixels": look_down_eyelid_drop_pixels,
		"look_down_head_offset": vector2_to_array(look_down_head_offset),
		"look_down_head_scale": vector2_to_array(look_down_head_scale),
		"look_down_layer_offsets": vector2_dict_to_array_dict(look_down_layer_offsets),
		"blink_style": blink_style,
		"torso_breath_enabled": torso_breath_enabled,
		"occasional_head_motion_enabled": occasional_head_motion_enabled,
	}

func apply_dict(data: Dictionary) -> void:
	portrait_id = sanitize_string(data.get("portrait_id", portrait_id), portrait_id)
	display_name = sanitize_string(data.get("display_name", display_name), display_name)
	seed = int(data.get("seed", seed))
	use_asset_colors = bool(data.get("use_asset_colors", use_asset_colors))
	head_id = sanitize_string(data.get("head_id", head_id), DEFAULT_HEAD_ID)
	torso_id = sanitize_string(data.get("torso_id", torso_id), DEFAULT_TORSO_ID)
	hair_id = sanitize_string(data.get("hair_id", hair_id), DEFAULT_HAIR_ID)
	eyes_id = sanitize_string(data.get("eyes_id", eyes_id), DEFAULT_EYES_ID)
	closed_eyes_id = sanitize_optional_string(data.get("closed_eyes_id", closed_eyes_id))
	pupils_id = sanitize_string(data.get("pupils_id", pupils_id), DEFAULT_PUPILS_ID)
	nose_id = sanitize_string(data.get("nose_id", nose_id), DEFAULT_NOSE_ID)
	mouth_id = sanitize_string(data.get("mouth_id", mouth_id), DEFAULT_MOUTH_ID)
	brows_id = sanitize_string(data.get("brows_id", brows_id), DEFAULT_BROWS_ID)
	mustache_id = sanitize_optional_string(data.get("mustache_id", mustache_id))
	skin_color = value_to_color(data.get("skin_color", skin_color), skin_color)
	hair_color = value_to_color(data.get("hair_color", hair_color), hair_color)
	eye_color = value_to_color(data.get("eye_color", eye_color), eye_color)
	clothing_color = value_to_color(data.get("clothing_color", clothing_color), clothing_color)
	accent_color = value_to_color(data.get("accent_color", accent_color), accent_color)
	mouth_color = value_to_color(data.get("mouth_color", mouth_color), mouth_color)
	expression = sanitize_expression(str(data.get("expression", expression)))
	canvas_size = value_to_vector2(data.get("canvas_size", canvas_size), canvas_size)
	head_origin = value_to_vector2(data.get("head_origin", head_origin), head_origin)
	head_pivot = value_to_vector2(data.get("head_pivot", head_pivot), head_pivot)
	torso_layer_offset = value_to_vector2(data.get("torso_layer_offset", torso_layer_offset), torso_layer_offset)
	layer_offsets = value_to_vector2_dict(data.get("layer_offsets", layer_offsets))
	look_down_pupil_offset = value_to_vector2(data.get("look_down_pupil_offset", look_down_pupil_offset), look_down_pupil_offset)
	look_down_eyelid_drop_pixels = float(data.get("look_down_eyelid_drop_pixels", look_down_eyelid_drop_pixels))
	look_down_head_offset = value_to_vector2(data.get("look_down_head_offset", look_down_head_offset), look_down_head_offset)
	look_down_head_scale = value_to_vector2(data.get("look_down_head_scale", look_down_head_scale), look_down_head_scale)
	look_down_layer_offsets = value_to_vector2_dict(data.get("look_down_layer_offsets", look_down_layer_offsets))
	blink_style = sanitize_blink_style(str(data.get("blink_style", blink_style)))
	torso_breath_enabled = bool(data.get("torso_breath_enabled", torso_breath_enabled))
	occasional_head_motion_enabled = bool(data.get("occasional_head_motion_enabled", occasional_head_motion_enabled))

static func from_dict(data: Dictionary) -> PortraitConfig:
	var config := PortraitConfig.new()
	config.apply_dict(data)
	return config

static func sanitize_string(value, fallback: String) -> String:
	var cleaned_value: String = str(value).strip_edges()
	return fallback if cleaned_value.is_empty() else cleaned_value

static func sanitize_optional_string(value) -> String:
	return str(value).strip_edges()

static func sanitize_expression(value: String) -> String:
	var cleaned_value: String = value.strip_edges().to_lower()
	if cleaned_value in ["neutral", "happy", "stern", "worried"]:
		return cleaned_value
	return "neutral"

static func sanitize_blink_style(value: String) -> String:
	var cleaned_value: String = value.strip_edges().to_lower()
	if cleaned_value in ["swap_closed", "move_eyes"]:
		return cleaned_value
	return "swap_closed"

static func color_to_array(color: Color) -> Array:
	return [color.r, color.g, color.b, color.a]

static func vector2_to_array(vector: Vector2) -> Array:
	return [vector.x, vector.y]

static func vector2_dict_to_array_dict(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in source:
		output[key] = vector2_to_array(value_to_vector2(source[key], Vector2.ZERO))
	return output

static func value_to_color(value, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is Array and value.size() >= 3:
		var alpha: float = float(value[3]) if value.size() >= 4 else fallback.a
		return Color(float(value[0]), float(value[1]), float(value[2]), alpha)
	if value is Dictionary:
		return Color(
			float(value.get("r", fallback.r)),
			float(value.get("g", fallback.g)),
			float(value.get("b", fallback.b)),
			float(value.get("a", fallback.a))
		)
	if value is String:
		return Color.from_string(str(value), fallback)
	return fallback

static func value_to_vector2(value, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		var vector_value: Vector2i = value
		return Vector2(vector_value.x, vector_value.y)
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is Dictionary:
		return Vector2(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)))
	return fallback

static func value_to_vector2_dict(value) -> Dictionary:
	var output: Dictionary = {}
	if !(value is Dictionary):
		return output

	for key in value:
		output[str(key)] = value_to_vector2(value[key], Vector2.ZERO)
	return output
