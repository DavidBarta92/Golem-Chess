extends Resource
class_name PackDefinition

@export var pack_id: String = ""
@export var pack_name: String = "New Pack"
@export var pack_texture: Texture2D
@export_group("3D Pack Visuals")
@export var pack_front_texture: Texture2D
@export var pack_back_texture: Texture2D
@export var pack_height_texture: Texture2D
@export var pack_normal_texture: Texture2D
@export var pack_roughness_texture: Texture2D
@export var pack_foil_mask_texture: Texture2D
@export_group("")
@export var possible_stamps: Array[Stamp] = []
@export var possible_stamp_prints: Array[StampPrint] = []
@export var stamp_print_ids: PackedStringArray = []
@export var include_all_standard_prints: bool = false
@export var available: bool = true
@export var price: int = 15

func get_display_name() -> String:
	var trimmed_name: String = pack_name.strip_edges()
	return trimmed_name if !trimmed_name.is_empty() else "Pack"

func get_resolved_id() -> String:
	var trimmed_id: String = pack_id.strip_edges()
	if !trimmed_id.is_empty():
		return trimmed_id
	if !resource_path.is_empty():
		return resource_path.get_file().get_basename()
	return get_display_name().to_snake_case()

func get_front_texture() -> Texture2D:
	return pack_front_texture if pack_front_texture != null else pack_texture
