# card.gd
extends Resource
class_name Card

enum Role {
	UNIT,
	NEXUS,
	SHARED,
}

@export var card_name: String = "New Card"
@export var card_code: String = "New Card"
@export_enum("Unit", "Nexus", "Shared") var role: int = Role.UNIT
@export var duration: int = 3
@export var texture: Texture2D
@export var card_art: Texture2D
@export var card_art_mask: Texture2D
@export var piece_visuals: PieceVisualSet
@export_storage var white_piece_texture: Texture2D
@export_storage var black_piece_texture: Texture2D
@export var description: String = ""
@export var symbol: String = ""
@export_enum("none", "shared_control", "steal_card", "grant_card", "give_card", "move_base", "invisible_to_enemy", "invalid_squares", "frozen_squares", "bomb", "uncapturable", "increase_own_durations", "increase_enemy_durations", "decrease_own_durations", "decrease_enemy_durations", "increase_self_duration") var effect_type: String = CardEffect.TYPE_NONE
@export_enum("on_attach", "on_move", "on_capture", "on_captured", "on_expire", "while_attached", "on_symbol_count") var effect_trigger: String = CardEffect.TRIGGER_ON_ATTACH
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

func get_pattern_offsets(pattern: Array, include_center: bool = false) -> Array[Vector2]:
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
			if !include_center and x == center_x and y == center_y:
				continue
			if int(pattern_row[y]) != CardEffect.MOVEMENT_NONE:
				offsets.append(Vector2(center_x - x, y - center_y))

	return offsets

func get_effect_offsets() -> Array[Vector2]:
	return get_pattern_offsets(effect_params, true)

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

func get_piece_texture(piece_color: int, view: String = PieceVisualSet.VIEW_BACK) -> Texture2D:
	if piece_visuals != null:
		var visual_set_texture: Texture2D = piece_visuals.get_texture(piece_color, view)
		if visual_set_texture != null:
			return visual_set_texture
	return get_legacy_piece_texture(piece_color)

func get_piece_preview_texture(piece_color: int) -> Texture2D:
	return get_piece_texture(piece_color, PieceVisualSet.VIEW_PREVIEW)

func get_legacy_piece_texture(piece_color: int) -> Texture2D:
	if piece_color > 0:
		return white_piece_texture
	return black_piece_texture
