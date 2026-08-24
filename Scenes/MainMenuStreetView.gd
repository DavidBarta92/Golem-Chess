extends Control
class_name MainMenuStreetView

## Opponent silhouette that walks up to the booth window on the main menu.
## mainmenu_opponent.png is a full-background-sized artwork with the
## character drawn at its final resting spot (transparent elsewhere), so the
## arrival point is derived from that artwork's used_rect and the same
## "cover" scaling math ArtworkCroppedButton uses to line buttons up with
## the background art. That keeps the arrival point correct regardless of
## viewport size.

signal opponent_arrived

@export var arrival_delay: float = 10.0
@export var arrival_duration: float = 3.2
@export var start_offset: Vector2 = Vector2(-460.0, -320.0)
@export var arrived_opacity: float = 0.5

@onready var opponent_sprite: TextureRect = $OpponentSprite

var _full_texture: Texture2D
var _used_rect: Rect2
var _end_position: Vector2
var _start_position: Vector2
var _arrival_timer: Timer
var _move_tween: Tween

func _ready() -> void:
	_full_texture = opponent_sprite.texture
	if _full_texture == null:
		return
	var image: Image = _full_texture.get_image()
	if image == null:
		return

	var used_rect_i: Rect2i = image.get_used_rect()
	_used_rect = Rect2(Vector2(used_rect_i.position), Vector2(used_rect_i.size))

	var atlas := AtlasTexture.new()
	atlas.atlas = _full_texture
	atlas.region = _used_rect
	opponent_sprite.texture = atlas
	opponent_sprite.ignore_texture_size = true
	opponent_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	opponent_sprite.visible = false

	_layout_to_artwork()
	get_viewport().size_changed.connect(_layout_to_artwork)

	_arrival_timer = Timer.new()
	_arrival_timer.one_shot = true
	_arrival_timer.wait_time = arrival_delay
	add_child(_arrival_timer)
	_arrival_timer.timeout.connect(_start_arrival)
	_arrival_timer.start()

func _layout_to_artwork() -> void:
	if _full_texture == null:
		return
	var canvas_size: Vector2 = size
	var tex_size: Vector2 = _full_texture.get_size()
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0 or tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var cover_scale: float = max(canvas_size.x / tex_size.x, canvas_size.y / tex_size.y)
	var canvas_offset: Vector2 = (canvas_size - tex_size * cover_scale) * 0.5

	_end_position = _used_rect.position * cover_scale + canvas_offset
	_start_position = _end_position + start_offset * cover_scale
	opponent_sprite.size = _used_rect.size * cover_scale
	opponent_sprite.pivot_offset = opponent_sprite.size * 0.5

	if _move_tween == null or !_move_tween.is_valid():
		opponent_sprite.position = _end_position if opponent_sprite.visible else _start_position

func _start_arrival() -> void:
	# Kuwahara ("oil paint") pass is deactivated for now in favor of the blur
	# alone, but left wired in the shader so it can be re-enabled later —
	# just leave shader_parameter/paint_amount at 0.0 in the material.
	var material: ShaderMaterial = opponent_sprite.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("blur_amount", 1.0)

	opponent_sprite.position = _start_position
	opponent_sprite.modulate.a = 0.0
	opponent_sprite.visible = true

	_move_tween = create_tween()
	_move_tween.set_parallel(true)
	_move_tween.tween_property(opponent_sprite, "position", _end_position, arrival_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(opponent_sprite, "modulate:a", arrived_opacity, arrival_duration).set_trans(Tween.TRANS_LINEAR)
	if material != null:
		_move_tween.tween_property(material, "shader_parameter/blur_amount", 0.0, arrival_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_move_tween.chain().tween_callback(_on_arrival_complete)

func _on_arrival_complete() -> void:
	opponent_arrived.emit()
