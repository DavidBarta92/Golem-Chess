@tool
extends Node2D

# Standalone live preview for Shaders/piece_capture_sparkle.gdshader.
# Open this scene in the editor -- the sparkle animates and loops right here,
# no need to press Play or trigger a real capture. Tune the exported values
# below, then copy the ones you like onto the matching "Capture Sparkle"
# fields on the MatchBoard node.

const SPARKLE_SHADER = preload("res://Shaders/piece_capture_sparkle.gdshader")
const DEFAULT_PIECE_VISUAL_HEIGHT: float = 24.0
const CELL_WIDTH: float = 18.0

@export_range(32.0, 512.0, 1.0) var cell_pixel_size: float = 128.0

@export_group("Capture Sparkle")
@export var sparkle_color: Color = Color(1.0, 0.95, 0.78, 1.0)
@export_range(0.05, 2.0, 0.01) var duration: float = 0.4
@export_range(0.05, 1.0, 0.01) var fade_out_ratio: float = 0.65
@export_range(0.0, 2.0, 0.01) var loop_gap: float = 0.4
@export_range(0.2, 6.0, 0.05) var size_ratio: float = 2.15
@export_range(100.0, 10000.0, 50.0) var shader_scale: float = 10000.0
@export_range(0.0, 1.0, 0.01) var decay_magnitude: float = 0.06
@export_range(-20.0, 20.0, 0.05) var rotate_speed: float = 2.25
@export_range(0.0, 5.0, 0.01) var time_speed: float = 2.76
@export_range(0.0, 10.0, 0.01) var frequency_base: float = 1.0
@export_range(0.0, 10.0, 0.01) var frequency_disturbance_scale: float = 0.16
@export_range(0.0, 20.0, 0.1) var circle_ratio: float = 0.0

@onready var board_tile: Sprite2D = $BoardTile
@onready var piece_texture: Sprite2D = $PieceTexture
@onready var sparkle: Sprite2D = $Sparkle

var _material: ShaderMaterial
var _elapsed: float = 0.0

func _ready() -> void:
	_ensure_material()
	_layout_reference_pieces()
	set_process(true)

func _ensure_material() -> void:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SPARKLE_SHADER
		sparkle.material = _material

func _layout_reference_pieces() -> void:
	board_tile.centered = true
	board_tile.scale = Vector2.ONE * (cell_pixel_size / CELL_WIDTH)

	piece_texture.centered = true
	var piece_native_size: Vector2 = piece_texture.texture.get_size() if piece_texture.texture != null else Vector2.ONE
	piece_texture.scale = Vector2.ONE * ((cell_pixel_size * 1.6) / maxf(piece_native_size.y, 1.0))
	piece_texture.position = Vector2(0.0, -cell_pixel_size * 0.3)

func _process(delta: float) -> void:
	if !is_instance_valid(sparkle) or sparkle.texture == null:
		return
	_ensure_material()
	_apply_shader_parameters()

	var cycle_length: float = maxf(0.05, duration + loop_gap)
	_elapsed = fmod(_elapsed + delta, cycle_length)

	var alpha: float = 0.0
	if _elapsed <= duration:
		var fade_start: float = duration * (1.0 - fade_out_ratio)
		alpha = 1.0 if _elapsed <= fade_start else 1.0 - (_elapsed - fade_start) / maxf(0.001, duration - fade_start)
	_material.set_shader_parameter("alpha_strength", clampf(alpha, 0.0, 1.0))

	var piece_visual_height_px: float = DEFAULT_PIECE_VISUAL_HEIGHT * (cell_pixel_size / CELL_WIDTH)
	sparkle.position = Vector2(0.0, -piece_visual_height_px * 0.18 - cell_pixel_size * 0.3)

	var texture_extent: float = maxf(sparkle.texture.get_size().x, sparkle.texture.get_size().y)
	if texture_extent > 0.0:
		sparkle.scale = Vector2.ONE * ((cell_pixel_size * size_ratio) / texture_extent)

func _apply_shader_parameters() -> void:
	_material.set_shader_parameter("color", sparkle_color)
	_material.set_shader_parameter("scale", shader_scale)
	_material.set_shader_parameter("circle_ratio", circle_ratio)
	_material.set_shader_parameter("decay_magnitude", decay_magnitude)
	_material.set_shader_parameter("rotate_speed", rotate_speed)
	_material.set_shader_parameter("time_speed", time_speed)
	_material.set_shader_parameter("frequency_base", frequency_base)
	_material.set_shader_parameter("frequency_disturbance_scale", frequency_disturbance_scale)
