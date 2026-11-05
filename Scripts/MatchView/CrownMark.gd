extends Node2D

## The crown on a crowned golem: the gold ring that formed in the rim's groove,
## hovering around the head with its far side behind it. Around the head and not
## over it - anything over the head lands on the belly of the piece behind and
## reads as that piece's. A child of the golem's holder sprite, so it moves,
## scales and fades with it.

const CrownGold = preload("res://Scripts/MatchView/CrownGold.gd")

const MARK_NODE_NAME: String = "CrownMark"

## In board units: every fitted picture stands 24 tall (DEFAULT_PIECE_VISUAL_HEIGHT).
const WIDTH_UNITS: float = 8.0
const PIECE_HEIGHT_UNITS: float = 24.0
## How far under the top of the head the ring's middle goes, as a share of its width.
const SIT_SHARE: float = 0.08
## Where to measure the head, as a share of the figure's height from its top.
const HEAD_ROW_SHARE: float = 0.04
## How far over the head something that comes off the piece appears, in shares of
## the ring's width.
const OVER_HEAD_SHARE: float = 0.7

## It hovers, barely: this far up and down, as a share of its width.
const FLOAT_SHARE: float = 0.035
const FLOAT_SECONDS: float = 3.2

const DROP_SHARE: float = 0.9
const DROP_SECONDS: float = 0.18
const FLASH_IN_SECONDS: float = 0.08
const FLASH_OUT_SECONDS: float = 0.75
const FLASH_BOARD_ENERGY: float = 1.3
const FLASH_PIECE_ENERGY: float = 0.6

## The centre of the head and the figure's first row, by texture.
static var _heads: Dictionary = {}

var _width: float = WIDTH_UNITS
var _fitted_texture: Texture2D
var _fitted_offset: Vector2
var _rest_position: Vector2 = Vector2.ZERO
## How far above its place it is while it drops on, as a share of its width.
var _drop_height: float = 0.0
var _far_side: Node2D

## The near side is one step over its golem, or the ice that grows on a new
## crown's golem would be drawn across it. The far side goes behind the golem,
## into one of the free slots between the ranks.
func _init() -> void:
	light_mask = 0
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_far_side = Node2D.new()
	_far_side.light_mask = 0
	_far_side.z_index = -2
	_far_side.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_far_side.draw.connect(_draw_far_side)
	add_child(_far_side)

## A stamp's morph changes the picture without a redraw of the board, and the
## crown is measured off the picture. The hover goes by the clock and not by a
## count of its own, as the board may make this node anew at any moment.
func _process(_delta: float) -> void:
	var holder: Sprite2D = get_parent() as Sprite2D
	if holder != null and holder.texture != null and (holder.texture != _fitted_texture or holder.offset != _fitted_offset):
		fit_to_holder(holder)
	var hover: float = FLOAT_SHARE * sin(TAU * float(Time.get_ticks_msec()) * 0.001 / FLOAT_SECONDS)
	position = _rest_position - Vector2(0.0, _width * (hover + _drop_height))

func fit_to_holder(holder: Sprite2D) -> void:
	if holder == null or holder.texture == null:
		return
	_fitted_texture = holder.texture
	_fitted_offset = holder.offset
	_width = _get_width(holder)
	_rest_position = _get_head_position(holder) + Vector2(0.0, _width * SIT_SHARE)
	queue_redraw()
	_far_side.queue_redraw()

## Where something that comes off this golem appears, in world space: just over
## the head, whichever way the view is turned.
static func get_point_over_head(holder: Sprite2D) -> Vector2:
	return holder.to_global(_get_head_position(holder) - Vector2(0.0, _get_width(holder) * OVER_HEAD_SHARE))

static func _get_width(holder: Sprite2D) -> float:
	return maxf(WIDTH_UNITS, holder.texture.get_size().y * WIDTH_UNITS / PIECE_HEIGHT_UNITS)

static func _get_head_position(holder: Sprite2D) -> Vector2:
	var texture_size: Vector2 = holder.texture.get_size()
	var picture_corner: Vector2 = holder.offset - (texture_size * 0.5 if holder.centered else Vector2.ZERO)
	return picture_corner + _get_head(holder.texture, texture_size)

static func _get_head(texture: Texture2D, texture_size: Vector2) -> Vector2:
	if !_heads.has(texture):
		_heads[texture] = _measure_head(texture, texture_size)
	return _heads[texture]

static func _measure_head(texture: Texture2D, texture_size: Vector2) -> Vector2:
	var image: Image = texture.get_image()
	if image == null:
		return Vector2(texture_size.x * 0.5, 0.0)
	if image.is_compressed():
		image.decompress()
	var used: Rect2i = image.get_used_rect()
	var row: int = used.position.y + int(float(used.size.y) * HEAD_ROW_SHARE)
	var left: int = -1
	var right: int = -1
	for x in range(used.position.x, used.end.x):
		if image.get_pixel(x, row).a > 0.5:
			if left < 0:
				left = x
			right = x
	var centre_x: float = float(left + right) * 0.5 if left >= 0 else float(used.get_center().x)
	return Vector2(centre_x, float(used.position.y))

## The picture cut across the ring's middle. Each half runs a pixel past the cut,
## so that no seam shows at the ring's two ends.
func _draw() -> void:
	_draw_side(self, Rect2(0.0, 0.5, 1.0, 0.5))

func _draw_far_side() -> void:
	_draw_side(_far_side, Rect2(0.0, 0.0, 1.0, 0.5))

## `part` is which of the picture, in shares of its size.
func _draw_side(canvas: CanvasItem, part: Rect2) -> void:
	var picture: Texture2D = CrownGold.worn_ring_texture()
	var picture_size: Vector2 = picture.get_size()
	var seam: float = 1.0 / picture_size.y
	part = part.grow_individual(0.0, seam, 0.0, seam)
	part = part.intersection(Rect2(0.0, 0.0, 1.0, 1.0))
	var shown := Vector2(_width, _width * picture_size.y / picture_size.x)
	canvas.draw_texture_rect_region(picture, Rect2(part.position * shown - shown * 0.5, part.size * shown), Rect2(part.position * picture_size, part.size * picture_size))

## The crown drops onto the head, then the light goes off. The board may redraw
## its holders meanwhile, so the flash finds the holder again when it is due.
static func play_crowning(match_board, board_pos: Vector2) -> void:
	var holder: Sprite2D = match_board.get_piece_holder_at(board_pos)
	if holder == null:
		return
	var mark = holder.get_node_or_null(MARK_NODE_NAME)
	if mark != null:
		mark._drop_height = DROP_SHARE
		mark.create_tween().tween_property(mark, "_drop_height", 0.0, DROP_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	match_board.get_tree().create_timer(DROP_SECONDS).timeout.connect(_flash.bind(match_board, board_pos))

static func _flash(match_board, board_pos: Vector2) -> void:
	if !is_instance_valid(match_board):
		return
	var holder: Sprite2D = match_board.get_piece_holder_at(board_pos)
	if holder == null:
		return
	var animator = match_board.get_piece_effect_animator()
	var board_light: PointLight2D = animator.create_attach_point_light(holder)
	var piece_light: PointLight2D = animator.create_affix_sprite_light(holder)
	if board_light == null or piece_light == null:
		animator.cleanup_attach_point_light(holder, board_light, piece_light)
		return
	animator.set_holder_light_occluder_enabled(holder, false)
	var tween: Tween = match_board.create_tween()
	tween.tween_property(board_light, "energy", FLASH_BOARD_ENERGY, FLASH_IN_SECONDS)
	tween.parallel().tween_property(piece_light, "energy", FLASH_PIECE_ENERGY, FLASH_IN_SECONDS)
	tween.tween_property(board_light, "energy", 0.0, FLASH_OUT_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(piece_light, "energy", 0.0, FLASH_OUT_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(animator.cleanup_attach_point_light.bind(holder, board_light, piece_light))
