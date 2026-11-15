extends TextureButton
class_name ArtworkCroppedButton

## Base for a MainMenu button whose texture is a full background-sized
## image with a small icon drawn somewhere on it (so it lines up with the
## artwork when exported). Crops down to just the icon (plus padding) and
## positions/sizes the control to land exactly on top of the artwork, using
## the same "keep aspect covered" math as the BackgroundLines shader.
## The texture can be the full image itself or, better, the layer as
## tools/build_main_menu_art.py builds it: the drawing trimmed, in an
## AtlasTexture whose margin puts it back in place on the full canvas, so the
## button holds only its drawing in video memory.
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
var _intro_tween: Tween

func _ready() -> void:
	_full_texture = texture_normal
	if _full_texture == null:
		return
	var drawn: Rect2 = drawn_rect_of(_full_texture)
	if drawn.size.x <= 0.0 or drawn.size.y <= 0.0:
		return

	_padded_rect = drawn.grow(hit_padding).intersection(Rect2(Vector2.ZERO, _full_texture.get_size()))
	texture_normal = _cropped_texture(_full_texture, drawn, _padded_rect)
	ignore_texture_size = true
	stretch_mode = 0 # STRETCH_SCALE; control rect already matches the cropped texture 1:1

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_layout_to_artwork()

	get_viewport().size_changed.connect(_layout_to_artwork)
	mouse_entered.connect(_on_hover)
	pressed.connect(_on_pressed)

## Where the drawing sits on the full canvas. A built layer says so itself;
## a full-size image is searched for its drawn pixels.
static func drawn_rect_of(texture: Texture2D) -> Rect2:
	var built := texture as AtlasTexture
	if built != null and built.region.size != Vector2.ZERO:
		return Rect2(built.margin.position, built.region.size)
	var image: Image = texture.get_image()
	if image == null:
		return Rect2()
	var used: Rect2i = image.get_used_rect()
	return Rect2(Vector2(used.position), Vector2(used.size))

## The padded rect of the canvas alone, drawn over the control 1:1.
static func _cropped_texture(texture: Texture2D, drawn: Rect2, padded: Rect2) -> Texture2D:
	var cropped := AtlasTexture.new()
	cropped.filter_clip = true
	var built := texture as AtlasTexture
	if built != null and built.region.size != Vector2.ZERO:
		cropped.atlas = built.atlas
		cropped.region = built.region
		cropped.margin = Rect2(drawn.position - padded.position, padded.size - drawn.size)
	else:
		cropped.atlas = texture
		cropped.region = padded
	return cropped

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

## Fades the button in from nothing after delay: the menu's buttons arriving
## while the room draws itself (MainMenu).
func play_intro(delay: float, seconds: float) -> void:
	_intro_tween = _fade_in([self], delay, seconds)

## Fades the given items in together, from nothing.
func _fade_in(items: Array, delay: float, seconds: float) -> Tween:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	var tween := create_tween()
	tween.set_parallel(true)
	for item in items:
		item.modulate.a = 0.0
		tween.tween_property(item, "modulate:a", 1.0, maxf(0.05, seconds)).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween

## A button that cannot be pressed does not answer the pointer either.
func _on_hover() -> void:
	if disabled:
		return
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
