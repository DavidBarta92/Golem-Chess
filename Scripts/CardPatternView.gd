extends Control
class_name CardPatternView

const GRID_SIZE: int = 5

@export var dot_texture: Texture2D
@export var active_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var move_only_color: Color = Color(0.35, 0.72, 1.0, 1.0)
@export var capture_only_color: Color = Color(1.0, 0.32, 0.28, 1.0)
@export var invalid_color: Color = Color(1.0, 0.15, 0.12, 1.0)
@export var frozen_color: Color = Color(0.16, 0.5, 1.0, 1.0)
@export var base_color: Color = Color(1.0, 0.84, 0.12, 1.0)
@export var bomb_color: Color = Color(1.0, 0.36, 0.08, 1.0)
@export var center_color: Color = Color(0.08, 0.08, 0.08, 0.9)
@export var guide_color: Color = Color(0.1, 0.1, 0.1, 0.13)

var movement_pattern: Array = []
var effect_pattern: Array = []
var effect_type: String = CardEffect.TYPE_NONE
var has_effect_pattern: bool = false

func set_pattern(pattern: Array) -> void:
	movement_pattern = pattern
	effect_pattern = []
	effect_type = CardEffect.TYPE_NONE
	has_effect_pattern = false
	queue_redraw()

func set_card(card: Card) -> void:
	if card == null:
		set_pattern([])
		return

	movement_pattern = card.movement_pattern
	effect_pattern = card.effect_params if _should_show_effect_pattern(card) else []
	effect_type = card.effect_type
	has_effect_pattern = !effect_pattern.is_empty()
	queue_redraw()

func _draw() -> void:
	var cell_size: float = minf(size.x, size.y) / float(GRID_SIZE)
	var grid_size: float = cell_size * GRID_SIZE
	var origin: Vector2 = (size - Vector2(grid_size, grid_size)) * 0.5

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var cell_origin: Vector2 = origin + Vector2(col, row) * cell_size
			var center: Vector2 = cell_origin + Vector2.ONE * cell_size * 0.5
			draw_circle(center, cell_size * 0.08, guide_color)

			if row == 2 and col == 2:
				draw_circle(center, cell_size * 0.16, center_color)
			else:
				var movement_type: int = _get_pattern_value(movement_pattern, row, col)
				if movement_type != CardEffect.MOVEMENT_NONE:
					_draw_move_dot(center, cell_size, _get_movement_color(movement_type))

				if has_effect_pattern && _get_pattern_value(effect_pattern, row, col) != CardEffect.MOVEMENT_NONE:
					_draw_effect_marker(center, cell_size)

func _should_show_effect_pattern(card: Card) -> bool:
	return card.effect_type in [
		CardEffect.TYPE_INVALID_SQUARES,
		CardEffect.TYPE_FROZEN_SQUARES,
		CardEffect.TYPE_MOVE_BASE,
		CardEffect.TYPE_BOMB,
	]

func _get_pattern_value(pattern: Array, row: int, col: int) -> int:
	if row < 0 or row >= pattern.size():
		return CardEffect.MOVEMENT_NONE

	var pattern_row: Array = pattern[row]
	if col < 0 or col >= pattern_row.size():
		return CardEffect.MOVEMENT_NONE

	return int(pattern_row[col])

func _get_movement_color(movement_type: int) -> Color:
	match movement_type:
		CardEffect.MOVEMENT_MOVE_ONLY:
			return move_only_color
		CardEffect.MOVEMENT_CAPTURE_ONLY:
			return capture_only_color
		_:
			return active_color

func _draw_move_dot(center: Vector2, cell_size: float, dot_color: Color) -> void:
	var dot_size: float = cell_size * 0.62
	var rect: Rect2 = Rect2(center - Vector2.ONE * dot_size * 0.5, Vector2.ONE * dot_size)

	if dot_texture:
		draw_texture_rect(dot_texture, rect, false, dot_color)
	else:
		draw_circle(center, dot_size * 0.45, dot_color)

func _draw_effect_marker(center: Vector2, cell_size: float) -> void:
	match effect_type:
		CardEffect.TYPE_INVALID_SQUARES:
			_draw_x_marker(center, cell_size, invalid_color)
		CardEffect.TYPE_FROZEN_SQUARES:
			_draw_x_marker(center, cell_size, frozen_color)
		CardEffect.TYPE_MOVE_BASE:
			_draw_base_marker(center, cell_size)
		CardEffect.TYPE_BOMB:
			_draw_bomb_marker(center, cell_size)
		_:
			_draw_move_dot(center, cell_size, active_color)

func _draw_x_marker(center: Vector2, cell_size: float, marker_color: Color) -> void:
	var half_size: float = cell_size * 0.28
	var width: float = maxf(2.0, cell_size * 0.12)
	draw_line(center + Vector2(-half_size, -half_size), center + Vector2(half_size, half_size), marker_color, width)
	draw_line(center + Vector2(-half_size, half_size), center + Vector2(half_size, -half_size), marker_color, width)

func _draw_base_marker(center: Vector2, cell_size: float) -> void:
	var square_size: float = cell_size * 0.5
	var rect: Rect2 = Rect2(center - Vector2.ONE * square_size * 0.5, Vector2.ONE * square_size)
	draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.28), true)
	draw_rect(rect, base_color, false, maxf(2.0, cell_size * 0.1))

func _draw_bomb_marker(center: Vector2, cell_size: float) -> void:
	var radius: float = cell_size * 0.24
	draw_circle(center, radius, Color(bomb_color.r, bomb_color.g, bomb_color.b, 0.22))
	draw_arc(center, radius, 0.0, TAU, 18, bomb_color, maxf(2.0, cell_size * 0.08))
	var spark_radius: float = cell_size * 0.34
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var from_point: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius * 0.65
		var to_point: Vector2 = center + Vector2(cos(angle), sin(angle)) * spark_radius
		draw_line(from_point, to_point, bomb_color, maxf(1.5, cell_size * 0.07))
