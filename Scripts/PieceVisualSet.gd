extends Resource
class_name PieceVisualSet

const VIEW_FRONT: String = "front"
const VIEW_BACK: String = "back"
const VIEW_PREVIEW: String = "preview"

@export_group("White")
@export var white_front: Texture2D
@export var white_back: Texture2D
@export var white_preview: Texture2D

@export_group("Black")
@export var black_front: Texture2D
@export var black_back: Texture2D
@export var black_preview: Texture2D

func get_texture(piece_color: int, view: String) -> Texture2D:
	if piece_color > 0:
		return get_white_texture(view)
	return get_black_texture(view)

func get_white_texture(view: String) -> Texture2D:
	match view:
		VIEW_BACK:
			return first_texture(white_back, white_front, white_preview)
		VIEW_PREVIEW:
			return first_texture(white_preview, white_front, white_back)
		_:
			return first_texture(white_front, white_back, white_preview)

func get_black_texture(view: String) -> Texture2D:
	match view:
		VIEW_BACK:
			return first_texture(black_back, black_front, black_preview)
		VIEW_PREVIEW:
			return first_texture(black_preview, black_front, black_back)
		_:
			return first_texture(black_front, black_back, black_preview)

func first_texture(primary: Texture2D, secondary: Texture2D, fallback: Texture2D) -> Texture2D:
	if primary != null:
		return primary
	if secondary != null:
		return secondary
	return fallback
