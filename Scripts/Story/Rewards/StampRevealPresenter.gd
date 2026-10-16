extends RewardPresenter
class_name StampRevealPresenter

## A single stamp flies in from off-screen (top and to one side), lands face
## down in the middle, and flips over on a click with the attach glow blooming
## behind it. Used after Boss 5, 7, 9 and 12.
##
## Which stamp is the reward's first grant_stamps entry - the one set in the
## editor on the reward scene, which is also what the payout actually gave.

const GLOW_SHADER: Shader = preload("res://Shaders/piece_attach_glow.gdshader")
const CARD_FACE_TEXTURE: Texture2D = preload("res://Assets/stamp_base.svg")

@export_range(0.5, 3.0, 0.05) var card_scale: float = 1.7
@export_range(0.2, 3.0, 0.05) var fly_in_seconds: float = 0.9
@export_range(0.05, 1.0, 0.01) var flip_seconds: float = 0.2
## How far off-screen the card starts, as a fraction of the presenter's size.
@export var start_offset_ratio: Vector2 = Vector2(0.55, -0.7)
@export var glow_color: Color = Color(1.0, 0.82, 0.28, 1.0)
@export_range(0.0, 5.0, 0.1) var glow_peak_strength: float = 3.4
@export_range(0.0, 5.0, 0.1) var glow_rest_strength: float = 1.1
@export var sfx_fly_in: String = "pack_whoosh"
@export var sfx_land: String = "stamp_up"
@export var sfx_flip: String = "codex_fold"
@export var sfx_glow: String = "attach_stamp"

var _card: StampVisual
var _glow: TextureRect
var _glow_material: ShaderMaterial
var _accepting_click: bool = false
var _flipped: bool = false

func _start() -> void:
	var stamp: Stamp = _get_stamp()
	if stamp == null:
		push_warning("StampRevealPresenter: the reward scene has no stamp to show.")
		finish()
		return

	_build_glow()
	_card = _create_stamp_card(stamp, card_scale)
	_card.z_index = 2

	var rest: Vector2 = _get_rest_position()
	_card.position = rest + Vector2(size.x * start_offset_ratio.x, size.y * start_offset_ratio.y)
	_card.rotation = deg_to_rad(28.0)
	_card.home_position = rest
	_glow.position = rest
	_glow.rotation = 0.0

	clicked.connect(_on_clicked)
	_play_sfx(sfx_fly_in)
	var tween := _card.create_tween()
	tween.tween_property(_card, "position", rest, fly_in_seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(_card, "rotation", deg_to_rad(-2.0), fly_in_seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_card, "rotation", 0.0, 0.18).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_landed)

func _get_stamp() -> Stamp:
	if reward_scene == null:
		return null
	for stamp in reward_scene.grant_stamps:
		if stamp != null:
			return stamp
	return null

func _get_rest_position() -> Vector2:
	return (size - CARD_SIZE) * 0.5

func _on_landed() -> void:
	_play_sfx(sfx_land)
	_card.home_position = _card.position
	_card.set_ambient_motion_enabled(true)
	_accepting_click = true

func _on_clicked(_local_position: Vector2) -> void:
	if !_accepting_click or _flipped:
		return
	_accepting_click = false
	_flipped = true
	_card.set_ambient_motion_enabled(false)
	_card.position = _card.home_position
	_play_sfx(sfx_flip)
	_flip_card(_card, flip_seconds, _on_flipped)

func _on_flipped() -> void:
	_play_sfx(sfx_glow)
	_bloom_glow()
	get_tree().create_timer(1.1).timeout.connect(finish)

## The glow is the card's own face silhouette, drawn slightly larger behind it
## with the attach shader, so it hugs the card's outline instead of being a
## square halo.
func _build_glow() -> void:
	_glow = TextureRect.new()
	_glow.texture = CARD_FACE_TEXTURE
	_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_glow.size = CARD_SIZE
	_glow.pivot_offset = CARD_SIZE * 0.5
	_glow.scale = Vector2.ONE * card_scale * 1.06
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.z_index = 1
	_glow.modulate.a = 0.0

	_glow_material = ShaderMaterial.new()
	_glow_material.shader = GLOW_SHADER
	_glow_material.set_shader_parameter("glow_color", glow_color)
	_glow_material.set_shader_parameter("glow_strength", 0.0)
	_glow_material.set_shader_parameter("glow_size", 6.0)
	_glow_material.set_shader_parameter("fill_strength", 0.35)
	_glow.material = _glow_material
	add_child(_glow)

func _bloom_glow() -> void:
	_glow.modulate.a = 1.0
	var tween := _glow.create_tween()
	tween.tween_property(_glow_material, "shader_parameter/glow_strength", glow_peak_strength, 0.22).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_glow, "scale", Vector2.ONE * card_scale * 1.14, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_glow_material, "shader_parameter/glow_strength", glow_rest_strength, 0.7).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_glow, "scale", Vector2.ONE * card_scale * 1.08, 0.7).set_ease(Tween.EASE_IN_OUT)
