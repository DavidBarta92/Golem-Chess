extends Control
class_name PortraitFrameLine

## The hand-drawn frame around a speaker's face in a DialoguePanel, and the
## way it draws itself in.
##
## Shared by the opponent's panel in a match (OpponentSpeechPanel) and the
## tutorial's panels, so a face is framed the same way wherever it talks. Put
## one on a panel with attach(); it keeps itself lined up with the picture.
##
## The reveal shader writes COLOR from `line_color` and never reads modulate,
## so the ink keeps its own alpha: it stays visible while the face and name it
## surrounds are faded out, which is what lets it draw first and have the face
## fade in behind it. Fade the ink itself with set_line_alpha().

## Dropped in next to the rest of the line art: a reveal mask generated from a
## `portrait_frame.png` by tools/generate_line_reveal_mask.py. Until that
## drawing exists attach() returns null and the panel goes unframed.
const FRAME_MASK_PATH: String = "res://Assets/portrait_frame_reveal_mask.png"
## The drawn stroke does not start at the png's border, and it is not inset by
## the same amount on every side. Taken as the median of each edge's stroke
## across the 495x200 art: the centre lines run at x 4.5 and 488.5, y 3.5 and
## 194.5. Lining the file up with the picture therefore leaves the frame a few
## pixels inside it - so it is this rectangle that gets lined up, not the file.
## Re-measure it if the drawing is redone.
const FRAME_ART_SIZE: Vector2 = Vector2(495.0, 200.0)
const FRAME_ART_STROKE: Rect2 = Rect2(4.5, 3.5, 484.0, 191.0)

const LINE_REVEAL_SHADER = preload("res://Shaders/mainmenu_line_reveal.gdshader")
const HIDDEN_TIME: float = -1.0
const DRAWN_TIME: float = 1000.0

var reveal_seconds: float = 1.0
var line_color: Color = Color(0.12, 0.12, 0.14, 1.0)

var _panel: DialoguePanel
var _rect: TextureRect
var _material: ShaderMaterial
var _portrait_view: PortraitView
var _tween: Tween

## Frames the panel's portrait. Returns null when the frame drawing does not
## exist yet or the panel has no portrait slot.
static func attach(panel: DialoguePanel, frame_reveal_seconds: float = 1.0) -> PortraitFrameLine:
	if panel == null or !ResourceLoader.exists(FRAME_MASK_PATH):
		return null
	var portrait_frame: Control = panel.get_portrait_frame()
	if portrait_frame == null:
		return null
	var frame := PortraitFrameLine.new()
	frame.name = "PortraitFrameHolder"
	frame.reveal_seconds = frame_reveal_seconds
	frame._panel = panel
	# The frame has to sit on the picture's own edges, not on the slot it is
	# given: the portrait keeps its aspect and is centred in that slot, which
	# leaves ten pixels of slack down each side. The container stretches this
	# holder over the slot, and the drawing inside it is placed by hand.
	portrait_frame.add_child(frame)
	return frame

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect = TextureRect.new()
	_rect.name = "PortraitFrameLine"
	_rect.texture = load(FRAME_MASK_PATH)
	_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_material = ShaderMaterial.new()
	_material.shader = LINE_REVEAL_SHADER
	_material.set_shader_parameter("base_duration", reveal_seconds)
	_material.set_shader_parameter("max_delay", reveal_seconds * 0.6)
	_material.set_shader_parameter("min_duration_frac", 0.45)
	_material.set_shader_parameter("feather", 0.03)
	_material.set_shader_parameter("line_color", line_color)
	_rect.material = _material
	reset()

func _process(_delta: float) -> void:
	_fit_to_portrait()

## From the first stroke to the last.
func get_draw_duration() -> float:
	return reveal_seconds * 1.6

## Draws the frame in. Returns immediately; it takes get_draw_duration().
func draw() -> void:
	_kill_tween()
	visible = true
	_fit_to_portrait()
	var duration: float = get_draw_duration()
	_tween = create_tween()
	_tween.tween_method(_set_time, 0.0, duration, duration)

## Already there, for a speaker who is on screen from the start.
func show_drawn() -> void:
	_kill_tween()
	visible = true
	_fit_to_portrait()
	_set_time(DRAWN_TIME)

func set_line_alpha(alpha: float) -> void:
	if _material == null:
		return
	var faded: Color = line_color
	faded.a = line_color.a * clampf(alpha, 0.0, 1.0)
	_material.set_shader_parameter("line_color", faded)

## Back to undrawn and hidden.
func reset() -> void:
	_kill_tween()
	visible = false
	set_line_alpha(1.0)
	_set_time(HIDDEN_TIME)

func _set_time(value: float) -> void:
	if _material != null:
		_material.set_shader_parameter("time", value)

## Lays the frame over the picture itself. The portrait's backing rect is the
## picture's own edge, so the frame is matched to that rather than to the slot
## around it.
func _fit_to_portrait() -> void:
	if _rect == null:
		return
	var backing: Control = _get_portrait_backing()
	if backing == null:
		return
	var target: Rect2 = backing.get_global_rect()
	if target.size.x <= 0.0 or target.size.y <= 0.0:
		return
	var factor: Vector2 = target.size / FRAME_ART_STROKE.size
	_rect.size = FRAME_ART_SIZE * factor
	_rect.position = target.position - FRAME_ART_STROKE.position * factor - get_global_rect().position

func _get_portrait_backing() -> Control:
	if _portrait_view == null or !is_instance_valid(_portrait_view):
		_portrait_view = null
		var portrait_frame: Control = _panel.get_portrait_frame() if _panel != null else null
		if portrait_frame == null:
			return null
		for child in portrait_frame.get_children():
			if child is PortraitView:
				_portrait_view = child
				break
	if _portrait_view == null:
		return null
	return _portrait_view.background_rect

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
