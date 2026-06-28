extends RefCounted
class_name PortraitAssetManifest

const TEXTURES: Dictionary = {
	"body": {
		"A1": preload("res://Assets/Portraits/body/A1.png"),
		"B1": preload("res://Assets/Portraits/body/B1.png"),
	},
	"eyebrows": {
		"A1": preload("res://Assets/Portraits/eyebrows/A1.png"),
		"A2": preload("res://Assets/Portraits/eyebrows/A2.png"),
		"A3": preload("res://Assets/Portraits/eyebrows/A3.png"),
		"B3": preload("res://Assets/Portraits/eyebrows/B3.png"),
	},
	"eyelash": {
		"A1": preload("res://Assets/Portraits/eyelash/A1.png"),
		"A2": preload("res://Assets/Portraits/eyelash/A2.png"),
		"A3": preload("res://Assets/Portraits/eyelash/A3.png"),
		"A4": preload("res://Assets/Portraits/eyelash/A4.png"),
		"A5": preload("res://Assets/Portraits/eyelash/A5.png"),
		"B1": preload("res://Assets/Portraits/eyelash/B1.png"),
	},
	"eyewhite": {
		"A1": preload("res://Assets/Portraits/eyewhite/A1.png"),
		"A2": preload("res://Assets/Portraits/eyewhite/A2.png"),
		"A3": preload("res://Assets/Portraits/eyewhite/A3.png"),
		"A4": preload("res://Assets/Portraits/eyewhite/A4.png"),
		"A5": preload("res://Assets/Portraits/eyewhite/A5.png"),
		"B1": preload("res://Assets/Portraits/eyewhite/B1.png"),
	},
	"facial_hair": {
		"A1": preload("res://Assets/Portraits/facial_hair/A1.png"),
		"A2": preload("res://Assets/Portraits/facial_hair/A2.png"),
		"A3": preload("res://Assets/Portraits/facial_hair/A3.png"),
		"A4": preload("res://Assets/Portraits/facial_hair/A4.png"),
		"A5": preload("res://Assets/Portraits/facial_hair/A5.png"),
		"A6": preload("res://Assets/Portraits/facial_hair/A6.png"),
		"A7": preload("res://Assets/Portraits/facial_hair/A7.png"),
		"A8": preload("res://Assets/Portraits/facial_hair/A8.png"),
		"A9": preload("res://Assets/Portraits/facial_hair/A9.png"),
		"A10": preload("res://Assets/Portraits/facial_hair/A10.png"),
		"A11": preload("res://Assets/Portraits/facial_hair/A11.png"),
		"B2": preload("res://Assets/Portraits/facial_hair/B2.png"),
	},
	"hair": {
		"A1": preload("res://Assets/Portraits/hair/A1.png"),
		"A2": preload("res://Assets/Portraits/hair/A2.png"),
		"A3": preload("res://Assets/Portraits/hair/A3.png"),
		"B1": preload("res://Assets/Portraits/hair/B1.png"),
	},
	"head": {
		"A1": preload("res://Assets/Portraits/head/A1.png"),
		"A2": preload("res://Assets/Portraits/head/A2.png"),
		"A3": preload("res://Assets/Portraits/head/A3.png"),
		"A4": preload("res://Assets/Portraits/head/A4.png"),
		"A5": preload("res://Assets/Portraits/head/A5.png"),
		"A6": preload("res://Assets/Portraits/head/A6.png"),
		"B1": preload("res://Assets/Portraits/head/B1.png"),
	},
	"mouth": {
		"A1": preload("res://Assets/Portraits/mouth/A1.png"),
		"A2": preload("res://Assets/Portraits/mouth/A2.png"),
		"B1": preload("res://Assets/Portraits/mouth/B1.png"),
	},
	"neck": {
		"A1": preload("res://Assets/Portraits/neck/A1.png"),
		"B1": preload("res://Assets/Portraits/neck/B1.png"),
	},
	"nose": {
		"A1": preload("res://Assets/Portraits/nose/A1.png"),
		"A2": preload("res://Assets/Portraits/nose/A2.png"),
		"A3": preload("res://Assets/Portraits/nose/A3.png"),
		"A4": preload("res://Assets/Portraits/nose/A4.png"),
		"A5": preload("res://Assets/Portraits/nose/A5.png"),
		"B2": preload("res://Assets/Portraits/nose/B2.png"),
	},
	"pupils": {
		"A1": preload("res://Assets/Portraits/pupils/A1.png"),
		"B1": preload("res://Assets/Portraits/pupils/B1.png"),
	},
}

static func get_texture(category: String, part_id: String) -> Texture2D:
	var category_textures: Dictionary = TEXTURES.get(category, {})
	return category_textures.get(part_id, null) as Texture2D

static func get_part_paths(category: String) -> Dictionary:
	var output: Dictionary = {}
	var category_textures: Dictionary = TEXTURES.get(category, {})
	for part_id in category_textures.keys():
		output[str(part_id)] = "res://Assets/Portraits/%s/%s.png" % [category, part_id]
	return output
