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
# The winning step: the ring swells and springs back, a star of gold breaks
# out around it, and the crowning's light comes on brighter and stays longer.
const VICTORY_SWELL: float = 1.45
const VICTORY_SWELL_SECONDS: float = 0.14
const VICTORY_SETTLE_SECONDS: float = 0.6
const VICTORY_FLASH_BOARD_ENERGY: float = 1.3
const VICTORY_FLASH_PIECE_ENERGY: float = 0.6
const VICTORY_FLASH_OUT_SECONDS: float = 1.4
const VICTORY_SPARKLE_COLOR: Color = Color(1.0, 0.82, 0.36, 1.0)
## The star's size, in shares of the ring's width.
const VICTORY_SPARKLE_SIZE: float = 5.5
const VICTORY_SPARKLE_SECONDS: float = 1.1
# Knocked off with its golem: it flies off the way the blow went, bounces on
# the board and goes in a flash. Board units (a square is
# BoardConfig.CELL_WIDTH) and seconds.
const KNOCK_DISTANCE: float = 16.0
## Off to one side of the blow, in radians, not straight along it: the striker
## now standing on the square would hide where it lands, and its flash would
## read as the striker's.
const KNOCK_SIDE_ANGLE_MIN: float = 1.0
const KNOCK_SIDE_ANGLE_MAX: float = 1.3
const KNOCK_UP_SPEED: float = 60.0
const KNOCK_GRAVITY: float = 420.0
## How much of its speed a bounce gives back, and below what speed it lies still.
const KNOCK_BOUNCE: float = 0.42
const KNOCK_REST_SPEED: float = 9.0
## The tumble while it flies, in radians, dying away by its rest.
const KNOCK_TUMBLE: float = 0.9
const KNOCK_TUMBLE_SPEED: float = 15.0
const KNOCK_TUMBLE_DECAY: float = 4.0
const KNOCK_REST_SECONDS: float = 0.22
## The flash it goes in: brighter, a little larger, gone.
const KNOCK_FLASH_COLOR: Color = Color(1.9, 1.7, 1.25, 1.0)
const KNOCK_FLASH_IN_SECONDS: float = 0.05
const KNOCK_FLASH_OUT_SECONDS: float = 0.22
const KNOCK_FLASH_GROW: float = 1.35
const KNOCK_SPARKLE_SIZE: float = 3.2
const KNOCK_SPARKLE_SECONDS: float = 0.6
const KNOCK_CLINK_PITCH: float = 1.8
const KNOCK_CLINK_VOLUME_DB: float = -9.0
const KNOCK_VANISH_VOLUME_DB: float = -8.0

## The centre of the head and the figure's first row, by texture.
static var _heads: Dictionary = {}

var _width: float = WIDTH_UNITS
var _fitted_texture: Texture2D
var _fitted_offset: Vector2
var _rest_position: Vector2 = Vector2.ZERO
## How far above its place it is while it drops on, as a share of its width.
var _drop_height: float = 0.0
var _far_side: Node2D
## Off its golem (knock_off): it no longer sits on a head, the flight places it.
var _loose: bool = false

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
	if _loose:
		return
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

## Puts a crown on `holder`'s golem, one that is not on the board: the struck
## golem of a capture, until it breaks.
static func put_on(holder: Sprite2D):
	if holder == null or holder.texture == null:
		return null
	var mark = holder.get_node_or_null(MARK_NODE_NAME)
	if mark == null:
		mark = new()
		mark.name = MARK_NODE_NAME
		holder.add_child(mark)
	mark.fit_to_holder(holder)
	return mark

## The golem under the crown on `holder` has been struck on `board_pos` and
## breaks: the crown flies off it the way the blow went (`blow_direction`, in
## board steps), bounces on the board and goes in a flash. It does not come
## back: the crown is lost.
static func knock_off(match_board, holder: Sprite2D, board_pos: Vector2, blow_direction: Vector2) -> void:
	if holder == null or !is_instance_valid(holder) or holder.texture == null:
		return
	var mark = holder.get_node_or_null(MARK_NODE_NAME)
	var effects: Node2D = match_board.piece_effects_node
	if mark == null or effects == null or !is_instance_valid(effects):
		return
	var shatter = match_board.get_piece_shatter_animator()
	var ground: Vector2 = shatter.get_feet_ground_point(board_pos, holder.texture)
	var plane: Transform2D = shatter.get_board_plane_transform(board_pos)
	var flat_blow := Vector2.ZERO
	if blow_direction != Vector2.ZERO:
		flat_blow = (BoardConfig.get_cell_center_local(board_pos + blow_direction) - BoardConfig.get_cell_center_local(board_pos)).normalized()
	var up: Vector2 = shatter.get_screen_up()
	# Knocked away from the viewer, it goes behind the striker now standing on
	# the square, and the pieces further off are behind it; knocked towards
	# the viewer or sideways, it is in front of the striker.
	var away: bool = flat_blow != Vector2.ZERO and plane.basis_xform(flat_blow).dot(up) > 0.0
	var depth_z: int = holder.z_index if !holder.z_as_relative else match_board.pieces_node.z_index + match_board.get_piece_visuals().get_depth_z_index(board_pos)
	mark._loose = true
	mark.name = "KnockedOffCrown"
	mark.reparent(effects, true)
	mark.z_as_relative = false
	mark.z_index = depth_z - 1 if away else depth_z + 1
	mark._fly(match_board, ground, plane, flat_blow, up)

## The flight, worked out at the start: how high it is over the board at each
## moment, from the head down to the board and through its bounces, and how
## far along the board it has slid.
func _fly(match_board, ground: Vector2, plane: Transform2D, flat_blow: Vector2, up: Vector2) -> void:
	var start: Vector2 = position
	var height: float = maxf((start - ground).dot(up), 0.0)
	var beside: Vector2 = (start - ground) - up * height
	var along: Vector2 = flat_blow if flat_blow != Vector2.ZERO else Vector2.RIGHT.rotated(randf() * TAU)
	along = along.rotated((1.0 if randf() < 0.5 else -1.0) * randf_range(KNOCK_SIDE_ANGLE_MIN, KNOCK_SIDE_ANGLE_MAX))
	var travel: Vector2 = plane.basis_xform(along * KNOCK_DISTANCE)
	var tumble_side: float = 1.0 if randf() < 0.5 else -1.0
	var resting_rotation: float = rotation

	# Each hop: when it leaves the board and how fast. The first leaves the head.
	var hops: Array[Vector2] = []
	var speed: float = KNOCK_UP_SPEED
	var hop_start: float = 0.0
	var first_fall: float = (speed + sqrt(speed * speed + 2.0 * KNOCK_GRAVITY * height)) / KNOCK_GRAVITY
	hops.append(Vector2(0.0, speed))
	hop_start = first_fall
	speed = (KNOCK_GRAVITY * first_fall - speed) * KNOCK_BOUNCE
	var landings: Array[float] = [first_fall]
	while speed > KNOCK_REST_SPEED:
		hops.append(Vector2(hop_start, speed))
		hop_start += 2.0 * speed / KNOCK_GRAVITY
		landings.append(hop_start)
		speed *= KNOCK_BOUNCE
	var settled: float = hop_start

	var place := func(time: float) -> void:
		var lift: float = 0.0
		for hop_index in range(hops.size() - 1, -1, -1):
			var hop: Vector2 = hops[hop_index]
			if time >= hop.x:
				var since: float = time - hop.x
				lift = (height if hop_index == 0 else 0.0) + hop.y * since - 0.5 * KNOCK_GRAVITY * since * since
				break
		var slide: float = 1.0 - pow(1.0 - clampf(time / settled, 0.0, 1.0), 2.0)
		position = ground + beside + travel * slide + up * maxf(lift, 0.0)
		rotation = resting_rotation + tumble_side * KNOCK_TUMBLE * exp(-KNOCK_TUMBLE_DECAY * time) * sin(KNOCK_TUMBLE_SPEED * time)

	var flight: Tween = create_tween()
	flight.tween_method(place, 0.0, settled, settled)
	for landing: float in landings:
		flight.parallel().tween_callback(SFXManager.play_pitched.bind("piece_placed", KNOCK_CLINK_PITCH, KNOCK_CLINK_VOLUME_DB)).set_delay(landing)
	flight.tween_interval(KNOCK_REST_SECONDS)
	flight.tween_callback(_vanish.bind(match_board))

func _vanish(match_board) -> void:
	SFXManager.play_pitched("pack_foil_tease", 1.0, KNOCK_VANISH_VOLUME_DB)
	if is_instance_valid(match_board):
		var animator = match_board.get_piece_effect_animator()
		animator.play_sparkle_at(position, z_index + 1, _width * absf(scale.x) * KNOCK_SPARKLE_SIZE, VICTORY_SPARKLE_COLOR, KNOCK_SPARKLE_SECONDS)
	var flash: Tween = create_tween()
	flash.tween_property(self, "modulate", KNOCK_FLASH_COLOR, KNOCK_FLASH_IN_SECONDS)
	flash.tween_property(self, "scale", scale * KNOCK_FLASH_GROW, KNOCK_FLASH_OUT_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	flash.parallel().tween_property(self, "modulate:a", 0.0, KNOCK_FLASH_OUT_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	flash.tween_callback(queue_free)

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

## The crowned golem has made its winning step. Nothing happens on a golem
## without a crown.
static func play_victory_flare(match_board, board_pos: Vector2) -> void:
	var holder: Sprite2D = match_board.get_piece_holder_at(board_pos)
	if holder == null:
		return
	var mark = holder.get_node_or_null(MARK_NODE_NAME)
	if mark == null:
		return
	var swell: Tween = mark.create_tween()
	swell.tween_property(mark, "scale", Vector2.ONE * VICTORY_SWELL, VICTORY_SWELL_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	swell.tween_property(mark, "scale", Vector2.ONE, VICTORY_SETTLE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var animator = match_board.get_piece_effect_animator()
	var effects: Node2D = match_board.piece_effects_node
	if effects != null and is_instance_valid(effects):
		# The ring's width is in its golem's picture pixels; the star is drawn in board units.
		var ring_width: float = mark._width * absf(holder.scale.x)
		animator.play_sparkle_at(effects.to_local(mark.global_position), animator.get_piece_effect_z_index(board_pos) + 3, ring_width * VICTORY_SPARKLE_SIZE, VICTORY_SPARKLE_COLOR, VICTORY_SPARKLE_SECONDS)
	_flash(match_board, board_pos, VICTORY_FLASH_BOARD_ENERGY, VICTORY_FLASH_PIECE_ENERGY, VICTORY_FLASH_OUT_SECONDS)

static func _flash(match_board, board_pos: Vector2, board_energy: float = FLASH_BOARD_ENERGY, piece_energy: float = FLASH_PIECE_ENERGY, out_seconds: float = FLASH_OUT_SECONDS) -> void:
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
	tween.tween_property(board_light, "energy", board_energy, FLASH_IN_SECONDS)
	tween.parallel().tween_property(piece_light, "energy", piece_energy, FLASH_IN_SECONDS)
	tween.tween_property(board_light, "energy", 0.0, out_seconds).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(piece_light, "energy", 0.0, out_seconds).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(animator.cleanup_attach_point_light.bind(holder, board_light, piece_light))
