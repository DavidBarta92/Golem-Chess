# card.gd
extends Resource
class_name Card

@export var card_name: String = "New Card"
@export var card_code: String = "New Card"
@export var duration: int = 2
@export var texture: Texture2D
@export var white_piece_texture: Texture2D
@export var black_piece_texture: Texture2D
@export var description: String = ""
@export var is_owned: bool = true
@export_enum("none", "shared_control", "steal_card", "grant_card", "move_base", "invisible_to_enemy", "invalid_squares", "frozen_squares", "bomb") var effect_type: String = CardEffect.TYPE_NONE
@export_enum("on_attach", "on_move", "on_capture", "on_captured", "on_expire", "while_attached") var effect_trigger: String = CardEffect.TRIGGER_ON_ATTACH
@export var effect_icon: Texture2D
@export var effect_params: Array[Array] = [
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0]
]
@export var effect_settings: Dictionary = {}
@export var movement_pattern: Array[Array] = [
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0]
]

func get_directions() -> Array:
	var directions: Array[Vector2] = []
	directions.assign(get_pattern_offsets(movement_pattern))
	return directions

func get_pattern_offsets(pattern: Array) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	var rows: int = pattern.size()
	if rows == 0:
		return offsets

	var first_row: Array = pattern[0]
	var cols: int = first_row.size()
	var center_x: int = int(rows / 2)
	var center_y: int = int(cols / 2)

	for x in range(rows):
		var pattern_row: Array = pattern[x]
		for y in range(pattern_row.size()):
			if x == center_x and y == center_y:
				continue
			if int(pattern_row[y]) != CardEffect.MOVEMENT_NONE:
				offsets.append(Vector2(center_x - x, y - center_y))

	return offsets

func get_effect_offsets() -> Array[Vector2]:
	return get_pattern_offsets(effect_params)

func get_movement_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var rows: int = movement_pattern.size()
	if rows == 0:
		return options

	var cols: int = movement_pattern[0].size()
	var center_x: int = int(rows / 2)
	var center_y: int = int(cols / 2)

	for x in range(rows):
		for y in range(cols):
			if x == center_x and y == center_y:
				continue

			var movement_type: int = int(movement_pattern[x][y])
			if movement_type == CardEffect.MOVEMENT_NONE:
				continue

			options.append({
				"offset": Vector2(center_x - x, y - center_y),
				"movement_type": movement_type,
			})

	return options

func has_effect() -> bool:
	return CardEffect.has_effect(effect_type)
