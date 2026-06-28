extends Control
class_name StampPatternView

const PATTERN_SHIMMER_SHADER = preload("res://Shaders/pattern_shimmer.gdshader")
const GRID_SIZE: int = 5
const GUIDE_MARKER_SIZE_RATIO: float = 0.135
const MARKER_SIZE_SCALE: float = 1.0
const MARKER_SIZE_RATIO: float = 0.52 * MARKER_SIZE_SCALE
const DOT_TEXTURE_FILTER: TextureFilter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

const DEFAULT_MOVE_ONLY_TEXTURE = preload("res://Assets/stamp_pattern_move_only.svg")
const DEFAULT_ACTIVE_TEXTURE = preload("res://Assets/stamp_pattern_active.svg")
const DEFAULT_CAPTURE_ONLY_TEXTURE = preload("res://Assets/stamp_pattern_capture_only.svg")
const DEFAULT_INVALID_TEXTURE = preload("res://Assets/stamp_pattern_invalid.svg")
const DEFAULT_FROZEN_TEXTURE = preload("res://Assets/stamp_pattern_frozen.svg")
const DEFAULT_BASE_TEXTURE = preload("res://Assets/stamp_pattern_base.svg")
const DEFAULT_BOMB_TEXTURE = preload("res://Assets/stamp_pattern_bomb.svg")

@export_group("Marker Textures")
@export var guide_texture: Texture2D = DEFAULT_MOVE_ONLY_TEXTURE
@export var center_texture: Texture2D = DEFAULT_MOVE_ONLY_TEXTURE
@export var move_only_texture: Texture2D = DEFAULT_MOVE_ONLY_TEXTURE
@export var active_texture: Texture2D = DEFAULT_ACTIVE_TEXTURE
@export var capture_only_texture: Texture2D = DEFAULT_CAPTURE_ONLY_TEXTURE
@export var invalid_texture: Texture2D = DEFAULT_INVALID_TEXTURE
@export var frozen_texture: Texture2D = DEFAULT_FROZEN_TEXTURE
@export var base_texture: Texture2D = DEFAULT_BASE_TEXTURE
@export var bomb_texture: Texture2D = DEFAULT_BOMB_TEXTURE

@export_group("Marker Colors")
@export var active_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var move_only_color: Color = Color(0.35, 0.72, 1.0, 1.0)
@export var capture_only_color: Color = Color(1.0, 0.32, 0.28, 1.0)
@export var invalid_color: Color = Color(1.0, 0.15, 0.12, 1.0)
@export var frozen_color: Color = Color(0.16, 0.5, 1.0, 1.0)
@export var base_color: Color = Color(1.0, 0.84, 0.12, 1.0)
@export var bomb_color: Color = Color(1.0, 0.36, 0.08, 1.0)
@export var center_color: Color = Color(0.08, 0.08, 0.08, 0.9)
@export var guide_color: Color = Color(0.42, 0.48, 0.46, 0.5)

var movement_pattern: Array = []
var effect_pattern: Array = []
var effect_type: String = StampEffect.TYPE_NONE
var has_effect_pattern: bool = false
var pattern_shimmer_material: ShaderMaterial

func _ready() -> void:
	texture_filter = DOT_TEXTURE_FILTER
	pattern_shimmer_material = ShaderMaterial.new()
	pattern_shimmer_material.shader = PATTERN_SHIMMER_SHADER
	material = pattern_shimmer_material

func set_pattern(pattern: Array) -> void:
	movement_pattern = pattern
	effect_pattern = []
	effect_type = StampEffect.TYPE_NONE
	has_effect_pattern = false
	queue_redraw()

func set_stamp(stamp: Stamp) -> void:
	if stamp == null:
		set_pattern([])
		return

	movement_pattern = stamp.movement_pattern
	effect_pattern = stamp.effect_params if _should_show_effect_pattern(stamp) else []
	effect_type = stamp.effect_type
	has_effect_pattern = !effect_pattern.is_empty()
	queue_redraw()

func set_shimmer_time(value: float) -> void:
	if pattern_shimmer_material != null:
		pattern_shimmer_material.set_shader_parameter("shimmer_time", value)

func set_shimmer_space(origin: Vector2, visual_size: Vector2) -> void:
	if pattern_shimmer_material == null:
		return

	pattern_shimmer_material.set_shader_parameter("shimmer_origin", origin)
	pattern_shimmer_material.set_shader_parameter("shimmer_size", visual_size)

func _draw() -> void:
	var cell_size: float = minf(size.x, size.y) / float(GRID_SIZE)
	var grid_size: float = cell_size * GRID_SIZE
	var origin: Vector2 = (size - Vector2(grid_size, grid_size)) * 0.5

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var cell_origin: Vector2 = origin + Vector2(col, row) * cell_size
			var center: Vector2 = cell_origin + Vector2.ONE * cell_size * 0.5
			var movement_type: int = _get_pattern_value(movement_pattern, row, col)
			var has_effect_marker: bool = has_effect_pattern && _get_pattern_value(effect_pattern, row, col) != StampEffect.MOVEMENT_NONE
			var has_marker: bool = movement_type != StampEffect.MOVEMENT_NONE || has_effect_marker

			if row == 2 and col == 2:
				if !has_marker:
					_draw_marker_texture(center_texture, center, cell_size * GUIDE_MARKER_SIZE_RATIO, center_color)
			else:
				if !has_marker:
					_draw_marker_texture(guide_texture, center, cell_size * GUIDE_MARKER_SIZE_RATIO, guide_color)

			if movement_type != StampEffect.MOVEMENT_NONE:
				_draw_movement_marker(center, cell_size, movement_type)

			if has_effect_marker:
				_draw_effect_marker(center, cell_size)

func _should_show_effect_pattern(stamp: Stamp) -> bool:
	return stamp.effect_type in [
		StampEffect.TYPE_INVALID_SQUARES,
		StampEffect.TYPE_FROZEN_SQUARES,
		StampEffect.TYPE_MOVE_BASE,
		StampEffect.TYPE_BOMB,
	]

func _get_pattern_value(pattern: Array, row: int, col: int) -> int:
	if row < 0 or row >= pattern.size():
		return StampEffect.MOVEMENT_NONE

	var pattern_row: Array = pattern[row]
	if col < 0 or col >= pattern_row.size():
		return StampEffect.MOVEMENT_NONE

	return int(pattern_row[col])

func _draw_movement_marker(center: Vector2, cell_size: float, movement_type: int) -> void:
	match movement_type:
		StampEffect.MOVEMENT_MOVE_ONLY:
			_draw_marker_texture(move_only_texture, center, cell_size * MARKER_SIZE_RATIO, move_only_color)
		StampEffect.MOVEMENT_CAPTURE_ONLY:
			_draw_marker_texture(capture_only_texture, center, cell_size * MARKER_SIZE_RATIO, capture_only_color)
		_:
			_draw_marker_texture(active_texture, center, cell_size * MARKER_SIZE_RATIO, active_color)

func _draw_effect_marker(center: Vector2, cell_size: float) -> void:
	match effect_type:
		StampEffect.TYPE_INVALID_SQUARES:
			_draw_marker_texture(invalid_texture, center, cell_size * MARKER_SIZE_RATIO, invalid_color)
		StampEffect.TYPE_FROZEN_SQUARES:
			_draw_marker_texture(frozen_texture, center, cell_size * MARKER_SIZE_RATIO, frozen_color)
		StampEffect.TYPE_MOVE_BASE:
			_draw_marker_texture(base_texture, center, cell_size * MARKER_SIZE_RATIO, base_color)
		StampEffect.TYPE_BOMB:
			_draw_marker_texture(bomb_texture, center, cell_size * MARKER_SIZE_RATIO, bomb_color)
		_:
			_draw_marker_texture(active_texture, center, cell_size * MARKER_SIZE_RATIO, active_color)

func _draw_marker_texture(texture: Texture2D, center: Vector2, marker_size: float, marker_color: Color) -> void:
	if texture == null or marker_size <= 0.0:
		return

	var rect: Rect2 = Rect2(center - Vector2.ONE * marker_size * 0.5, Vector2.ONE * marker_size)
	draw_texture_rect(texture, rect, false, marker_color)
