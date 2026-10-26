# stamp.gd
extends Resource
class_name Stamp

enum Role {
	UNIT,
	SEEKER,
	SHARED,
	SE_TENANT,
	OVERSEAL,
}

@export var stamp_name: String = "New Stamp"
@export var stamp_code: String = "New Stamp"
@export_enum("Unit", "Seeker", "Shared", "Se-tenant", "Overseal") var role: int = Role.UNIT
@export_enum("Animals", "Flora", "Celestials", "Archetypes", "Courtyard", "Structures") var Set: String = "Archetypes"
@export var enabled: bool = true
@export var duration: int = 3
@export var texture: Texture2D
@export var stamp_art: Texture2D
@export var stamp_art_mask: Texture2D
@export var piece_visuals: PieceVisualSet
@export_storage var white_piece_texture: Texture2D
@export_storage var black_piece_texture: Texture2D
@export var description: String = ""
@export var symbol: String = ""
@export_enum("none", "steal_stamp", "grant_stamp", "give_stamp", "move_base", "invisible_to_enemy", "invalid_squares", "frozen_squares", "bomb", "uncapturable", "increase_own_durations", "increase_enemy_durations", "decrease_own_durations", "decrease_enemy_durations", "increase_self_duration") var effect_type: String = StampEffect.TYPE_NONE
@export_enum("on_affix", "on_move", "on_capture", "on_captured", "on_expire", "while_attached", "on_symbol_count") var effect_trigger: String = StampEffect.TRIGGER_ON_AFFIX
@export var effect_icon: Texture2D
@export var square_color_a: Color = Color(0, 0, 0, 0)
@export var square_color_b: Color = Color(0, 0, 0, 0)
# Per-stamp look of the name, the duration number and the pattern markers.
# A transparent color, an empty font or a size of 0 keeps StampVisual's default;
# the duration outline keeps it at -1, and 0 turns the outline off.
@export_group("Text & Markers")
@export var name_color: Color = Color(0, 0, 0, 0)
@export var name_font: Font
@export var name_font_size: int = 0
@export var duration_color: Color = Color(0, 0, 0, 0)
@export var duration_outline_color: Color = Color(0, 0, 0, 0)
@export_range(-1, 64) var duration_outline_size: int = -1
# One color for every movement and effect marker in the pattern.
@export var marker_color: Color = Color(0, 0, 0, 0)
@export_group("")
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
			if int(pattern_row[y]) != StampEffect.MOVEMENT_NONE:
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
			if movement_type == StampEffect.MOVEMENT_NONE:
				continue

			options.append({
				"offset": Vector2(center_x - x, y - center_y),
				"movement_type": movement_type,
			})

	return options

func has_effect() -> bool:
	return StampEffect.has_effect(effect_type)

# Player-facing text lives in Localization/translations.csv under STAMP_DESC_<STAMP_CODE>;
# `description` is only the fallback for stamps without a row there.
func get_display_description() -> String:
	var key: String = "STAMP_DESC_%s" % stamp_code.strip_edges().to_upper()
	var translated: String = tr(key)
	if translated == key:
		return description
	return translated

func has_square_color_a() -> bool:
	return square_color_a.a > 0.0

func has_square_color_b() -> bool:
	return square_color_b.a > 0.0

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
