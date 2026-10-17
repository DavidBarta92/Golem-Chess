extends Resource
class_name PackDefinition

@export var pack_id: String = ""
@export var pack_name: String = "New Pack"
## The pack art is named by path, not held as Texture2D: PackDefinitionLibrary
## loads every pack at startup, and Texture2D references would keep all of the
## art (about 6 MB a picture) in memory for the whole session. The getters
## below load a picture when something shows it, and it is freed again once
## nothing does.
@export_file("*.png", "*.webp", "*.svg") var pack_texture_path: String = ""
@export_group("3D Pack Visuals")
@export_file("*.png", "*.webp", "*.svg") var pack_front_texture_path: String = ""
@export_file("*.png", "*.webp", "*.svg") var pack_back_texture_path: String = ""
@export_file("*.png", "*.webp", "*.svg") var pack_height_texture_path: String = ""
@export_file("*.png", "*.webp", "*.svg") var pack_normal_texture_path: String = ""
@export_file("*.png", "*.webp", "*.svg") var pack_roughness_texture_path: String = ""
@export_file("*.png", "*.webp", "*.svg") var pack_foil_mask_texture_path: String = ""
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
	return _load_texture(pack_front_texture_path if !pack_front_texture_path.is_empty() else pack_texture_path)

func get_back_texture() -> Texture2D:
	return _load_texture(pack_back_texture_path)

func get_height_texture() -> Texture2D:
	return _load_texture(pack_height_texture_path)

func get_normal_texture() -> Texture2D:
	return _load_texture(pack_normal_texture_path)

func get_roughness_texture() -> Texture2D:
	return _load_texture(pack_roughness_texture_path)

func get_foil_mask_texture() -> Texture2D:
	return _load_texture(pack_foil_mask_texture_path)

func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return load(path) as Texture2D
