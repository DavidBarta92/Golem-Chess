extends Resource
class_name StampPrint

enum VisualVariant {
	STANDARD,
	FOIL,
	FULL_ART,
}

@export var print_id: String = ""
@export var stamp_code: String = ""
@export_enum("standard", "foil", "full_art") var variant_id: String = "standard"
@export var variant_name: String = "Standard"
# Off leaves the print out of the game: the collection, packs and pack contents never show
# it. Copies a player already owns stay in their save and come back when it is on again.
@export var enabled: bool = true
@export var stamp_art: Texture2D
@export var stamp_art_mask: Texture2D
@export var stamp_shimmer_enabled: bool = false
# The print's foil look, if any; the styles live in res://FoilStyles/.
@export var foil_style: FoilStyle
@export var grant_in_default_collection: bool = false
@export var default_collection_quantity: int = 1
@export var square_color_a: Color = Color(0, 0, 0, 0)
@export var square_color_b: Color = Color(0, 0, 0, 0)
# The print's own look of the name, the duration number and the pattern markers.
# A transparent color, an empty font or a size of 0 falls back to the stamp's look;
# the duration outline falls back at -1, and 0 turns the outline off.
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

func uses_masked_art() -> bool:
	return true

func get_display_name() -> String:
	if variant_name.strip_edges().is_empty():
		return variant_id.capitalize()
	return variant_name.strip_edges()

func has_square_color_a() -> bool:
	return square_color_a.a > 0.0

func has_square_color_b() -> bool:
	return square_color_b.a > 0.0
