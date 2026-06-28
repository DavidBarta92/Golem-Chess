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
@export var stamp_art: Texture2D
@export var stamp_art_mask: Texture2D
@export var stamp_shimmer_enabled: bool = false
@export var grant_in_default_collection: bool = false
@export var default_collection_quantity: int = 1

func uses_masked_art() -> bool:
	return true

func get_display_name() -> String:
	if variant_name.strip_edges().is_empty():
		return variant_id.capitalize()
	return variant_name.strip_edges()
