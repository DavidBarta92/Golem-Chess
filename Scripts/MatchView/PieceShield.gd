extends Node2D

## The ward over an uncapturable piece (StampEffect.TYPE_UNCAPTURABLE, while
## its protection lasts): a ring of runes drawn on its square and a red bubble
## standing on it. The rules say when (StampEffectResolver.
## piece_has_affixed_effect); PieceDisplayController puts it on and takes it
## off, and tells it when to grow, tremble or go.
##
## The ring is always there; the bubble only shows for a while: as the ward
## comes on, while the cursor is over the piece's square, while it trembles,
## and as it goes, when it shows and then pops.
##
## A child of the piece's holder, so it moves and fades with it. The bubble is
## drawn twice from one shader (Shaders/piece_shield.gdshader): its back behind
## the piece, its front over it. The ring lies on the board under the grid
## (Shaders/piece_shield_ring.gdshader). Everything is placed from where the
## piece rests, not from the holder's transform now, so a squash running when
## it is fitted is not built into it. Sizes are in board units, as the ice's.

const DOME_SHADER: Shader = preload("res://Shaders/piece_shield.gdshader")
const RING_SHADER: Shader = preload("res://Shaders/piece_shield_ring.gdshader")
const NODE_NAME: String = "PieceShield"
## On the board, under the drawn grid, with the contact shadows.
const RING_Z_INDEX: int = 8
## The bubble's back in the free slot behind the piece's rank, its front in
## one in front of it (MATCH_SCENE.md, board layers).
const BACK_Z_OFFSET: int = -1
const FRONT_Z_OFFSET: int = 2
## The ring, in the middle of the square: its radius as a share of a square,
## but at least this much wider than the figure, and this much further out
## than the feet; the room over the head, in board units.
const RING_RADIUS: float = 0.44
const RING_FIGURE_MARGIN: float = 1.25
const RING_FEET_MARGIN: float = 1.3
const HEAD_ROOM: float = 1.8
## Coming on: the ring is drawn round, then the bubble grows up from it, stays
## this long and fades.
const GROW_RING_SECONDS: float = 0.35
const GROW_DOME_SECONDS: float = 0.6
const SHOW_AFTER_GROW_SECONDS: float = 2.5
## The bubble coming into sight and going out of it.
const SHOW_FADE_IN_SECONDS: float = 0.3
const SHOW_FADE_OUT_SECONDS: float = 0.7
## How long it shows for a tremble, and before it pops.
const TREMBLE_SHOW_SECONDS: float = 1.4
const POP_SHOW_SECONDS: float = 0.35
## On its last turn: how strong it still is.
const LAST_TURN_STRENGTH: float = 0.75
## The tremble when a piece that could otherwise take this one is picked up.
const TREMBLE_SECONDS: float = 0.75
## Going, as a soap bubble goes: it swells a little with a last wobble, then
## tears open from a point high on its skin and the hole runs across it in a
## blink, while droplets of its film fly off and fall. Seconds, and how much
## it swells.
const POP_SWELL_SECONDS: float = 0.09
const POP_SWELL: float = 1.05
const POP_TEAR_SECONDS: float = 0.1
## The droplets: how many, how long they fly, how fast they leave and how hard
## they fall (board units a second), and how big they are (board units).
const DROPLET_COUNT: int = 18
const DROPLET_SECONDS: float = 0.42
const DROPLET_SPEED_MIN: float = 9.0
const DROPLET_SPEED_MAX: float = 22.0
const DROPLET_GRAVITY: float = 70.0
const DROPLET_SIZE_MIN: float = 0.7
const DROPLET_SIZE_MAX: float = 1.3
const DROPLET_TEXTURE: Texture2D = preload("res://Assets/dot.svg")
const DROPLET_COLORS: Array[Color] = [Color(0.95, 0.24, 0.28), Color(0.66, 0.38, 1.0), Color(1.0, 0.88, 0.9)]
const SOUND: String = "pack_foil_tease"
const APPEAR_PITCH: float = 0.8
const APPEAR_VOLUME_DB: float = -7.0
## The pop itself: a short click, pitched up.
const POP_SOUND: String = "button_click"
const POP_PITCH: float = 1.7
const POP_VOLUME_DB: float = -4.0

static var _plain_texture: Texture2D

var _match_board
var _board_pos: Vector2
var _back := Sprite2D.new()
var _front := Sprite2D.new()
var _ring := Sprite2D.new()
var _dome_materials: Array[ShaderMaterial] = []
var _ring_material := ShaderMaterial.new()
var _fitted_texture: Texture2D
var _fitted_offset: Vector2
## The bubble as last fitted, in the holder's units: the middle of its base,
## its half width, how tall and how deep it is for that.
var _base_local: Vector2 = Vector2.ZERO
var _half_width_px: float = 1.0
var _height_ratio: float = 2.0
var _depth_ratio: float = 0.4
var _px_per_unit: float = 1.0
var _tremble: Tween
var _going: bool = false
## How much of the bubble shows (0..1), how much longer it is to show for
## (seconds), whether the cursor is over its square, and the fade under way.
var _shown: float = 0.0
var _show_left: float = 0.0
var _hovered: bool = false
var _fade: Tween
var _fade_target: float = -1.0

## Puts a shield on `holder`: its ring drawn at once, or (`standing` false)
## waiting for grow(). Its bubble does not show until something shows it.
static func add_to(match_board, holder: Sprite2D, board_pos: Vector2, standing: bool):
	var shield = new()
	shield._match_board = match_board
	shield._board_pos = board_pos
	holder.add_child(shield)
	shield._set_dome(&"rise", 1.0 if standing else 0.0)
	shield._set_ring(&"draw", 1.0 if standing else 0.0)
	shield._hovered = shield._is_hovered()
	shield._set_shown(1.0 if shield._hovered else 0.0)
	return shield

static func get_on(holder: Sprite2D):
	if holder == null or !is_instance_valid(holder):
		return null
	return holder.get_node_or_null(NODE_NAME)

func _init() -> void:
	name = NODE_NAME
	for sprite: Sprite2D in [_back, _front]:
		var dome_material := ShaderMaterial.new()
		dome_material.shader = DOME_SHADER
		dome_material.set_shader_parameter(&"front", 1.0 if sprite == _front else 0.0)
		sprite.material = dome_material
		sprite.texture = _get_plain_texture()
		sprite.light_mask = 0
		_dome_materials.append(dome_material)
		add_child(sprite)
	_back.name = "Back"
	_back.z_index = BACK_Z_OFFSET
	_front.name = "Front"
	_front.z_index = FRONT_Z_OFFSET
	_ring.name = "Ring"
	_ring_material.shader = RING_SHADER
	_ring.material = _ring_material
	_ring.texture = _get_plain_texture()
	_ring.light_mask = 0
	_ring.z_as_relative = false
	_ring.z_index = RING_Z_INDEX
	add_child(_ring)

func _ready() -> void:
	_fit()

func _process(delta: float) -> void:
	if _going:
		return
	var holder: Sprite2D = get_parent() as Sprite2D
	if holder != null and (holder.texture != _fitted_texture or holder.offset != _fitted_offset):
		_fit()
	var hovered: bool = _is_hovered()
	var was_showing: bool = _show_left > 0.0
	_show_left = maxf(_show_left - delta, 0.0)
	if hovered != _hovered or (was_showing and _show_left <= 0.0):
		_hovered = hovered
		_update_shown(true)

## The bubble shows for `seconds` (as well as while the cursor is over it),
## coming into sight over a moment, or at once without `fade_in`.
func show_for(seconds: float, fade_in: bool = true) -> void:
	if _going:
		return
	_show_left = maxf(_show_left, seconds)
	_update_shown(fade_in)

## How much longer the bubble is to show for, so a redrawn shield can go on.
func get_show_left() -> float:
	return _show_left

## The ring is drawn round, then the bubble grows up from it, stays a while
## and fades.
func grow() -> void:
	if _going:
		return
	SFXManager.play_pitched(SOUND, APPEAR_PITCH, APPEAR_VOLUME_DB)
	_show_left = GROW_RING_SECONDS + GROW_DOME_SECONDS + SHOW_AFTER_GROW_SECONDS
	_update_shown(false)
	var tween: Tween = create_tween()
	tween.tween_method(func(amount: float): _set_ring(&"draw", amount), 0.0, 1.0, GROW_RING_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(amount: float): _set_dome(&"rise", amount), 0.0, 1.0, GROW_DOME_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

## Its last turn: thinner, broken and flickering.
func set_last_turn(last_turn: bool) -> void:
	_set_both(&"strength", LAST_TURN_STRENGTH if last_turn else 1.0)
	_set_both(&"flicker", 1.0 if last_turn else 0.0)

## A ripple runs round it: the piece just picked up could take this one but
## for the ward.
func tremble() -> void:
	if _going:
		return
	show_for(TREMBLE_SHOW_SECONDS)
	if _tremble != null and _tremble.is_valid():
		_tremble.kill()
	_tremble = create_tween()
	_tremble.tween_method(func(amount: float): _set_both(&"tremble", amount), 0.0, 1.0, TREMBLE_SECONDS * 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tremble.tween_method(func(amount: float): _set_both(&"tremble", amount), 1.0, 0.0, TREMBLE_SECONDS * 0.85).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

## Its protection is over: it pops as a soap bubble does.
func pop_and_free() -> void:
	if _going:
		return
	_going = true
	# A new shield may take the name from here on.
	name = NODE_NAME + "Going"
	if _tremble != null and _tremble.is_valid():
		_tremble.kill()
	# Where it tears open: high on its skin, to one side or the other.
	var burst := Vector2(randf_range(-0.55, 0.55), -_height_ratio * randf_range(0.5, 0.8))
	_set_dome(&"burst_at", burst)

	# It comes into sight first.
	if _fade != null and _fade.is_valid():
		_fade.kill()
	var tween: Tween = create_tween()
	if _shown < 1.0:
		tween.tween_method(_set_shown, _shown, 1.0, POP_SHOW_SECONDS * (1.0 - _shown)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(amount: float): _set_both(&"tremble", amount), 0.0, 0.7, POP_SWELL_SECONDS)
	for sprite: Sprite2D in [_back, _front]:
		tween.parallel().tween_property(sprite, "scale", sprite.scale * POP_SWELL, POP_SWELL_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_burst)
	tween.tween_method(func(amount: float): _set_both(&"pop", amount), 0.0, 1.0, POP_TEAR_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(DROPLET_SECONDS)
	tween.tween_callback(queue_free)

## The pop: its sound, and droplets of its film flying off its outline.
func _burst() -> void:
	SFXManager.play_pitched(POP_SOUND, POP_PITCH, POP_VOLUME_DB)
	for index in DROPLET_COUNT:
		# Along its outline: most round the dome, a few along the front of its base.
		var share: float = (float(index) + randf_range(0.2, 0.8)) / float(DROPLET_COUNT)
		var outward: Vector2
		if share < 0.8:
			var around: float = share / 0.8 * PI
			outward = Vector2(cos(around), -_height_ratio * sin(around))
		else:
			var around_base: float = (share - 0.8) / 0.2 * PI
			outward = Vector2(cos(around_base), _depth_ratio * sin(around_base))
		var start: Vector2 = _base_local + outward * _half_width_px
		var heading: Vector2 = Vector2(outward.x, outward.y / maxf(_height_ratio, 0.01)).normalized().rotated(randf_range(-0.35, 0.35))
		var velocity: Vector2 = heading * randf_range(DROPLET_SPEED_MIN, DROPLET_SPEED_MAX) * _px_per_unit
		var size_px: float = randf_range(DROPLET_SIZE_MIN, DROPLET_SIZE_MAX) * _px_per_unit
		var seconds: float = DROPLET_SECONDS * randf_range(0.7, 1.0)

		var droplet := Sprite2D.new()
		droplet.texture = DROPLET_TEXTURE
		droplet.modulate = DROPLET_COLORS[randi() % DROPLET_COLORS.size()]
		droplet.scale = Vector2.ONE * size_px / DROPLET_TEXTURE.get_size().x
		droplet.position = start
		droplet.z_index = FRONT_Z_OFFSET + 1
		droplet.light_mask = 0
		add_child(droplet)
		var start_scale: Vector2 = droplet.scale
		var gravity: float = DROPLET_GRAVITY * _px_per_unit
		var fly := func(time: float) -> void:
			droplet.position = start + velocity * time + Vector2(0.0, 0.5 * gravity * time * time)
			droplet.scale = start_scale * (1.0 - 0.6 * time / seconds)
			droplet.modulate.a = 1.0 - pow(time / seconds, 2.0)
		droplet.create_tween().tween_method(fly, 0.0, seconds, seconds)

func _fit() -> void:
	var holder: Sprite2D = get_parent() as Sprite2D
	if holder == null or _match_board == null:
		return
	_fitted_texture = holder.texture
	_fitted_offset = holder.offset
	visible = holder.texture != null
	if holder.texture == null:
		return
	var visuals = _match_board.get_piece_visuals()
	var shatter = _match_board.get_piece_shatter_animator()
	var metrics: Dictionary = visuals.get_footprint_metrics(holder.texture)
	if metrics.is_empty():
		visible = false
		return

	# Where the piece rests, in the board layer's units.
	var visual: Dictionary = visuals.get_visual_transform_for_texture(holder.texture, _board_pos)
	var rest_scale: Vector2 = visual.get("scale", holder.scale)
	var rest_offset: Vector2 = visual.get("offset", holder.offset)
	var rest := Transform2D(holder.rotation, rest_scale, 0.0, _match_board.get_board_geometry().get_position_local(_board_pos))
	var from_board: Transform2D = rest.affine_inverse()
	var px_per_unit: float = 1.0 / maxf(absf(rest_scale.x), 0.000001)
	var size: Vector2 = holder.texture.get_size()

	# The ring, on the board's plane, in the middle of the square - not round
	# the feet, which stand towards its front edge - and wide enough to take
	# the figure and its feet in.
	var plane: Transform2D = shatter.get_board_plane_transform(_board_pos)
	var center: Vector2 = _match_board.get_board_geometry().get_position_local(_board_pos)
	var feet_from_center: Vector2 = plane.affine_inverse().basis_xform(shatter.get_feet_ground_point(_board_pos, holder.texture) - center)
	var figure_half_px: float = maxf((float(metrics.get("right_x", size.x)) - float(metrics.get("left_x", 0.0))) * 0.5, float(metrics.get("lower_width", 0.0)) * 0.5)
	var radius: float = maxf(float(BoardConfig.CELL_WIDTH) * RING_RADIUS, figure_half_px / px_per_unit * RING_FIGURE_MARGIN)
	radius = maxf(radius, feet_from_center.length() * RING_FEET_MARGIN)
	var half_quad: float = _ring.texture.get_size().x * 0.5
	_ring.transform = from_board * Transform2D(plane.x * radius / half_quad, plane.y * radius / half_quad, center)
	_set_ring(&"radius_units", radius)

	# The bubble, standing on the ring, over the head.
	var base: Vector2 = from_board * center
	var across: Vector2 = from_board.basis_xform(plane.x * radius)
	var along: Vector2 = from_board.basis_xform(plane.y * radius)
	var half_width: float = sqrt(across.x * across.x + along.x * along.x)
	var half_depth: float = sqrt(across.y * across.y + along.y * along.y)
	var top: float = rest_offset.y + float(metrics.get("top_y", 0.0)) - size.y * 0.5 - HEAD_ROOM * px_per_unit
	var height: float = maxf(base.y - top, half_width)
	var margin: float = half_width * 0.12
	var bounds := Rect2(base.x - half_width - margin, base.y - height - margin, (half_width + margin) * 2.0, height + half_depth + margin * 2.0)
	for sprite: Sprite2D in [_back, _front]:
		sprite.position = bounds.get_center()
		sprite.scale = bounds.size / sprite.texture.get_size()
	_set_dome(&"bounds_px", bounds.size)
	_set_dome(&"base_offset_px", base - bounds.get_center())
	_set_dome(&"half_width_px", half_width)
	_set_dome(&"height_ratio", height / half_width)
	_set_dome(&"depth_ratio", half_depth / half_width)
	_set_dome(&"px_per_unit", px_per_unit)
	_base_local = base
	_half_width_px = half_width
	_height_ratio = height / half_width
	_depth_ratio = half_depth / half_width
	_px_per_unit = px_per_unit

## The bubble shows while it has time left to show or the cursor is over its
## square, and fades in or out to match.
func _update_shown(animate: bool) -> void:
	var target: float = 1.0 if (_hovered or _show_left > 0.0) else 0.0
	if target == _fade_target and (animate or is_equal_approx(_shown, target)):
		return
	_fade_target = target
	if _fade != null and _fade.is_valid():
		_fade.kill()
	if !animate or !is_inside_tree():
		_set_shown(target)
		return
	var seconds: float = (SHOW_FADE_IN_SECONDS if target > _shown else SHOW_FADE_OUT_SECONDS) * absf(target - _shown)
	_fade = create_tween()
	_fade.tween_method(_set_shown, _shown, target, maxf(seconds, 0.01)).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _set_shown(amount: float) -> void:
	_shown = amount
	_set_dome(&"shown", amount)

## The cursor is over this piece's square.
func _is_hovered() -> bool:
	if _match_board == null or !is_instance_valid(_match_board):
		return false
	return _match_board.get_mouse_board_position() == _board_pos

func _set_dome(parameter: StringName, value) -> void:
	for dome_material: ShaderMaterial in _dome_materials:
		dome_material.set_shader_parameter(parameter, value)

func _set_ring(parameter: StringName, value) -> void:
	_ring_material.set_shader_parameter(parameter, value)

func _set_both(parameter: StringName, value) -> void:
	_set_dome(parameter, value)
	_set_ring(parameter, value)

static func _get_plain_texture() -> Texture2D:
	if _plain_texture == null:
		var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_plain_texture = ImageTexture.create_from_image(image)
	return _plain_texture
