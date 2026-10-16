extends RefCounted
class_name CollectionIntroController

## The Collection's opening. The drawn parts of the room - background, book,
## tabs, the magnifier's case - draw themselves the way the main menu and the
## comic panels do, with each picture's own fill fading in under the ink. Once
## the drawing has landed, the rest (stamps, control bar, packs) fades in.
##
## A drawn node needs a reveal mask next to its texture:
##     python tools/generate_line_reveal_mask.py Assets/collection_book.png
## writes collection_book_reveal_mask.png, which is picked up by name. A node
## without one simply fades in with the fills.

const LINE_REVEAL_SHADER = preload("res://Shaders/mainmenu_line_reveal.gdshader")
const REVEAL_MASK_SUFFIX: String = "_reveal_mask.png"
## The whole drawing, ink and fill together.
const DRAW_SECONDS: float = 1.5
## A stroke takes up to STROKE_SECONDS and starts up to STROKE_MAX_DELAY in;
## together they fill DRAW_SECONDS.
const STROKE_SECONDS: float = 0.9
const STROKE_MAX_DELAY: float = 0.6
const STROKE_MIN_DURATION_FRACTION: float = 0.45
const STROKE_FEATHER: float = 0.03
const LINE_COLOR: Color = Color(0.06, 0.06, 0.08, 1.0)
## When the fills fade in under the ink, as shares of DRAW_SECONDS. The ink
## layer then fades out over the rest, leaving the pictures exactly as drawn.
const FILL_FADE_START: float = 0.5
const FILL_FADE_END: float = 0.88
const LATE_FADE_SECONDS: float = 0.45
## Shader time for "nothing drawn yet": every stroke's start is at or after 0.
const HIDDEN_TIME: float = -1.0

var collection: Control
## CanvasItems whose texture draws itself (TextureRect or TextureButton).
var drawn_nodes: Array = []
## CanvasItems that only fade in with the fills (the book's shadow).
var fill_only_nodes: Array = []
## Controls that fade in after the drawing.
var late_nodes: Array = []

var _line_material: ShaderMaterial
var _line_layers: Array[TextureRect] = []
var _tween: Tween

func bind(config: Dictionary) -> void:
	collection = config.get("collection", collection) as Control
	drawn_nodes = _valid_items(config.get("drawn_nodes", drawn_nodes))
	fill_only_nodes = _valid_items(config.get("fill_only_nodes", fill_only_nodes))
	late_nodes = _valid_items(config.get("late_nodes", late_nodes))

## Puts everything in its "not there yet" state. Call before the first frame
## is drawn so nothing flashes.
func prepare() -> void:
	_line_material = ShaderMaterial.new()
	_line_material.shader = LINE_REVEAL_SHADER
	_line_material.set_shader_parameter("base_duration", STROKE_SECONDS)
	_line_material.set_shader_parameter("min_duration_frac", STROKE_MIN_DURATION_FRACTION)
	_line_material.set_shader_parameter("max_delay", STROKE_MAX_DELAY)
	_line_material.set_shader_parameter("feather", STROKE_FEATHER)
	_line_material.set_shader_parameter("line_color", LINE_COLOR)
	_line_material.set_shader_parameter("time", HIDDEN_TIME)

	for item in drawn_nodes:
		_add_line_layer(item as CanvasItem)
	_set_fill_alpha(0.0)
	for item in late_nodes:
		(item as CanvasItem).modulate.a = 0.0

func play(delay: float = 0.0) -> void:
	if collection == null or !collection.is_inside_tree():
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var fill_start: float = DRAW_SECONDS * FILL_FADE_START
	var fill_end: float = DRAW_SECONDS * FILL_FADE_END
	_tween = collection.create_tween()
	_tween.set_parallel(true)
	_tween.tween_method(_set_reveal_time, 0.0, STROKE_SECONDS + STROKE_MAX_DELAY, DRAW_SECONDS).set_delay(delay)
	_tween.tween_method(_set_fill_alpha, 0.0, 1.0, fill_end - fill_start) \
		.set_delay(delay + fill_start).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_line_alpha, 1.0, 0.0, DRAW_SECONDS - fill_end).set_delay(delay + fill_end)
	_tween.chain().tween_callback(_on_drawn)

func _on_drawn() -> void:
	_set_fill_alpha(1.0)
	for layer in _line_layers:
		if is_instance_valid(layer):
			layer.queue_free()
	_line_layers.clear()
	if late_nodes.is_empty():
		return
	_tween = collection.create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	for item in late_nodes:
		if is_instance_valid(item):
			_tween.tween_property(item, "modulate:a", 1.0, LATE_FADE_SECONDS)

## The ink layer sits on top of its picture, the same size and stretch, so the
## mask's strokes land on the picture's own lines.
func _add_line_layer(item: CanvasItem) -> void:
	var texture: Texture2D = null
	var expand_mode: int = TextureRect.EXPAND_IGNORE_SIZE
	var stretch_mode: int = TextureRect.STRETCH_SCALE
	if item is TextureRect:
		var picture := item as TextureRect
		texture = picture.texture
		expand_mode = picture.expand_mode
		stretch_mode = picture.stretch_mode
	elif item is TextureButton:
		texture = (item as TextureButton).texture_normal
	if texture == null:
		return
	var mask_path: String = texture.resource_path.get_basename() + REVEAL_MASK_SUFFIX
	if !ResourceLoader.exists(mask_path):
		return

	var layer := TextureRect.new()
	layer.name = "IntroInk"
	layer.texture = load(mask_path) as Texture2D
	layer.expand_mode = expand_mode
	layer.stretch_mode = stretch_mode
	layer.texture_filter = item.texture_filter
	layer.material = _line_material
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_line_layers.append(layer)

func _set_reveal_time(time: float) -> void:
	_line_material.set_shader_parameter("time", time)

func _set_line_alpha(alpha: float) -> void:
	var faded_line_color: Color = LINE_COLOR
	faded_line_color.a = alpha
	_line_material.set_shader_parameter("line_color", faded_line_color)

## The node's own drawing only (self_modulate), so its ink layer child keeps
## showing while the fill is still transparent.
func _set_fill_alpha(alpha: float) -> void:
	for item in drawn_nodes + fill_only_nodes:
		if is_instance_valid(item):
			(item as CanvasItem).self_modulate.a = alpha

func _valid_items(items: Array) -> Array:
	var valid: Array = []
	for item in items:
		if item is CanvasItem and is_instance_valid(item):
			valid.append(item)
	return valid
