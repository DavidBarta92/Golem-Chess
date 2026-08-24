extends TextureButton
class_name ArtworkCroppedButton

## Base for a MainMenu button whose texture is a full background-sized
## image with a small icon drawn somewhere on it (so it lines up with the
## artwork when exported). Crops down to just the icon (plus padding) and
## positions/sizes the control to land exactly on top of the artwork, using
## the same "keep aspect covered" math as the BackgroundLines shader.
## Subclasses can override _on_hover() / _on_pressed() to add behavior on
## top of (or instead of) the pop animation.

@export var hit_padding: float = 12.0
@export var pop_grow_scale: float = 1.06
@export var pop_shrink_scale: float = 0.97
@export var pop_grow_time: float = 0.08
@export var pop_shrink_time: float = 0.07
@export var pop_settle_time: float = 0.12

var _full_texture: Texture2D
var _padded_rect: Rect2
var _base_position: Vector2
var _pop_tween: Tween

func _ready() -> void:
	_full_texture = texture_normal
	if _full_texture == null:
		return
	var image: Image = _full_texture.get_image()
	if image == null:
		return

	var used_rect: Rect2i = image.get_used_rect()
	_padded_rect = Rect2(Vector2(used_rect.position), Vector2(used_rect.size)).grow(hit_padding)
	_padded_rect = _padded_rect.intersection(Rect2(Vector2.ZERO, _full_texture.get_size()))

	var atlas := AtlasTexture.new()
	atlas.atlas = _full_texture
	atlas.region = _padded_rect
	texture_normal = atlas
	ignore_texture_size = true
	stretch_mode = 0 # STRETCH_SCALE; control rect already matches the atlas region 1:1

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_layout_to_artwork()

	get_viewport().size_changed.connect(_layout_to_artwork)
	mouse_entered.connect(_on_hover)
	pressed.connect(_on_pressed)

func _layout_to_artwork() -> void:
	var parent_control := get_parent() as Control
	var canvas_size: Vector2 = parent_control.size if parent_control != null else get_viewport_rect().size
	var tex_size: Vector2 = _full_texture.get_size()
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0 or tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var cover_scale: float = max(canvas_size.x / tex_size.x, canvas_size.y / tex_size.y)
	var canvas_offset: Vector2 = (canvas_size - tex_size * cover_scale) * 0.5

	_base_position = _padded_rect.position * cover_scale + canvas_offset
	position = _base_position
	size = _padded_rect.size * cover_scale
	pivot_offset = size * 0.5

func _on_hover() -> void:
	_play_pop_animation()

func _on_pressed() -> void:
	_play_pop_animation()

func _play_pop_animation() -> void:
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "scale", Vector2.ONE * pop_grow_scale, pop_grow_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(self, "scale", Vector2.ONE * pop_shrink_scale, pop_shrink_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_pop_tween.tween_property(self, "scale", Vector2.ONE, pop_settle_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
