extends Node2D

## What stands a piece on the board, drawn rather than cast by a light: the
## board darkened right at its feet, the bottom of the piece a little darker,
## and, for a piece seen from behind - lit from the far side of the board, as
## its dark back shows - a soft shadow falling forward from its feet. A piece
## seen from the front is lit from our side, so nothing may fall in front of
## it: its darkening sits behind its feet, under itself.
##
## A child of the piece's holder, so it moves, fades and turns with it. What
## lies on the board is a node of its own (`_ground`), so that it can stay on
## the board while the piece is lifted off it (`lift_off`) and come in under it
## before it has landed (`settle_in`). The holder's light occluder - its
## footprint - is not this node's business and stays: the flashes (an affix, a
## crowning) cast their shadows with it. A stamp's morph swaps the holder's
## picture without a redraw, so the node fits itself again whenever the
## picture or its offset changes.

const CONTACT_SHADER = preload("res://Shaders/piece_ground_contact.gdshader")
const CAST_SHADER = preload("res://Shaders/piece_cast_shadow.gdshader")
const FOOT_SHADER = preload("res://Shaders/piece_foot_shade.gdshader")
const NODE_NAME: String = "PieceGrounding"
## On the board, under the drawn grid (BoardGridOverlay.Z_INDEX).
const GROUND_Z_INDEX: int = 8
## The darkening where the piece stands: a soft band round its base - as wide
## as the bottom of the picture, as deep as the footprint - fading out by
## `CONTACT_SPREAD` times the base's size along each axis. A piece seen from
## the front has its band pulled back until its outer edge is at the feet, so
## nothing of it lies in front. How dark it is at the base's edge, the front's
## lighter, being mostly in the light.
const CONTACT_SPREAD: Vector2 = Vector2(1.3, 1.6)
const CONTACT_BACK_LIT_AMOUNT: float = 0.55
const CONTACT_FRONT_LIT_AMOUNT: float = 0.45
## The forward shadow: how far it reaches out in front of the feet, as a share
## of the piece's height, and how far it leans, in radians. It is the picture
## flipped about the row where the bottom of the figure gets to its full width
## (`base_round_depth` above its lowest pixel), not about its lowest pixel: a
## round base is drawn as an ellipse, and a shadow hung from its lowest point
## leaves a gap either side. Flat feet are at full width at once, so a golem's
## hangs from its feet. Hung higher, it is stretched to reach as far in front
## of the feet. Not the footprint's middle for every piece: that hid the
## golem's legs under it and showed its hips at its feet.
const CAST_LENGTH: float = 0.32
const CAST_LEAN: float = -0.6
## How far up the piece its foot shade reaches, as a share of its height.
const FOOT_SHADE_BAND: float = 0.14

static var _plain_texture: Texture2D
static var _contact_materials: Dictionary = {}

var _metrics_provider: Callable
var _footprint_provider: Callable
var _seen_from_front: bool = false
var _with_foot_shade: bool = true
var _fitted_texture: Texture2D
var _fitted_offset: Vector2
var _ground := Node2D.new()
var _shade := Node2D.new()
var _fade: Tween
var _leaving: bool = false

## `metrics_provider` measures a picture's figure, `footprint_provider` a
## holder's footprint (PieceVisualController.get_footprint_metrics and
## get_footprint_geometry). Without `with_foot_shade` only what lies on the
## board is drawn: for a picture burning away over the piece, whose bottom
## would stay dark where it is already gone.
func _init(metrics_provider: Callable = Callable(), footprint_provider: Callable = Callable(), seen_from_front: bool = false, with_foot_shade: bool = true) -> void:
	name = NODE_NAME
	_metrics_provider = metrics_provider
	_footprint_provider = footprint_provider
	_seen_from_front = seen_from_front
	_with_foot_shade = with_foot_shade
	_ground.name = "Ground"
	_shade.name = "Shade"
	add_child(_ground)
	add_child(_shade)

func _ready() -> void:
	_fit()

func _notification(what: int) -> void:
	# The ground is put on the board while the piece is off it; if the piece
	# goes meanwhile, it goes too.
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_ground) and _ground.get_parent() != self:
		_ground.queue_free()

func _process(_delta: float) -> void:
	var holder: Sprite2D = get_parent() as Sprite2D
	if !_leaving and holder != null and (holder.texture != _fitted_texture or holder.offset != _fitted_offset):
		_fit()

func is_seen_from_front() -> bool:
	return _seen_from_front

## Fades the shadow to `alpha` over `seconds` (at once for 0).
func fade_to(alpha: float, seconds: float) -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	if seconds <= 0.0:
		modulate.a = alpha
		return
	_fade = create_tween()
	_fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade.tween_property(self, "modulate:a", alpha, seconds)

## The piece is going up off the board: what lies on the board stays where it
## stood and fades over `seconds`, the foot shade fades with the piece, and
## this node goes.
func lift_off(seconds: float) -> void:
	if _leaving:
		return
	_leaving = true
	# A new shadow may take the name from here on.
	name = NODE_NAME + "Leaving"
	# Fitted to what the piece leaves with: the move sets the picture it shows
	# on the way just before.
	_fit()
	var board_layer: Node = get_parent().get_parent() if get_parent() != null else null
	if board_layer != null:
		_ground.reparent(board_layer, true)
		_ground.modulate.a = modulate.a
		var ground_fade: Tween = _ground.create_tween()
		ground_fade.tween_property(_ground, "modulate:a", 0.0, maxf(seconds, 0.01))
		ground_fade.tween_callback(_ground.queue_free)
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 0.0, maxf(seconds, 0.01))
	_fade.tween_callback(queue_free)

## The piece is coming down onto its square, `lift_height` above it: what lies
## on the board comes in on the ground under it over `seconds`, as it drops,
## and joins the piece again as it lands. Call it once the node is in place.
func settle_in(seconds: float, lift_height: float) -> void:
	var board_layer: Node = get_parent().get_parent() if get_parent() != null else null
	modulate.a = 0.0
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 1.0, maxf(seconds, 0.01))
	if board_layer == null:
		return
	_ground.reparent(board_layer, true)
	_ground.position += Vector2(0.0, lift_height)
	_ground.modulate.a = 0.0
	var ground_fade: Tween = _ground.create_tween()
	ground_fade.tween_property(_ground, "modulate:a", 1.0, maxf(seconds, 0.01))
	ground_fade.tween_callback(_take_ground_back)

func _take_ground_back() -> void:
	if !is_instance_valid(_ground) or _ground.get_parent() == self:
		return
	_ground.reparent(self, true)
	_ground.modulate.a = 1.0

func _fit() -> void:
	for layer: Node2D in [_ground, _shade]:
		for child in layer.get_children():
			child.queue_free()
	var holder: Sprite2D = get_parent() as Sprite2D
	if holder == null:
		return
	_fitted_texture = holder.texture
	_fitted_offset = holder.offset
	if holder.texture == null or !_metrics_provider.is_valid():
		return
	var metrics: Dictionary = _metrics_provider.call(holder.texture)
	if metrics.is_empty():
		return

	var size: Vector2 = holder.texture.get_size()
	var feet_x: float = float(metrics.get("lower_center_x", size.x * 0.5))
	var feet_y: float = float(metrics.get("bottom_y", size.y - 1.0))
	var head_y: float = float(metrics.get("top_y", 0.0))
	var feet_width: float = maxf(float(metrics.get("lower_width", 0.0)), (float(metrics.get("right_x", size.x)) - float(metrics.get("left_x", 0.0))) * 0.42)
	var feet: Vector2 = holder.offset + Vector2(feet_x, feet_y) - size * 0.5
	# The footprint's depth is the base's.
	var footprint: Dictionary = _footprint_provider.call(holder) if _footprint_provider.is_valid() else {}
	var has_footprint: bool = !bool(footprint.get("empty", true))
	var base_depth: float = float(footprint.get("radius_y", 0.0)) if has_footprint else 0.0
	# Where the cast shadow is flipped about, in the holder's units.
	var round_depth: float = clampf(float(metrics.get("base_round_depth", 0.0)), 0.0, (feet_y - head_y) * 0.3)
	var pivot := Vector2(feet.x, feet.y - round_depth)
	if base_depth <= 0.0:
		base_depth = feet_width * 0.2

	_add_contact(feet, Vector2(feet_width * 0.5, base_depth))
	if _with_foot_shade:
		_add_foot_shade(holder, feet_y / size.y, (feet_y - head_y) * FOOT_SHADE_BAND / size.y)
	if !_seen_from_front:
		_add_cast(holder, pivot, feet.y, head_y)

## `base` is the half-size of the base, whose front edge is at the feet.
func _add_contact(feet: Vector2, base: Vector2) -> void:
	var outer: Vector2 = base * CONTACT_SPREAD
	var middle: Vector2 = feet - Vector2(0.0, outer.y if _seen_from_front else base.y)
	var contact := Sprite2D.new()
	contact.texture = _get_plain_texture()
	contact.scale = outer * 2.0 / contact.texture.get_size()
	contact.position = middle
	contact.material = _get_contact_material(_seen_from_front)
	contact.z_as_relative = false
	contact.z_index = GROUND_Z_INDEX
	contact.light_mask = 0
	_ground.add_child(contact)

func _add_foot_shade(holder: Sprite2D, feet_v: float, band: float) -> void:
	var shade_material := ShaderMaterial.new()
	shade_material.shader = FOOT_SHADER
	shade_material.set_shader_parameter(&"feet_v", feet_v)
	shade_material.set_shader_parameter(&"band", band)
	var shade := Sprite2D.new()
	shade.texture = holder.texture
	shade.offset = holder.offset
	shade.texture_filter = holder.texture_filter
	shade.material = shade_material
	shade.light_mask = 0
	_shade.add_child(shade)

## The picture flipped about the base's full-width row, so the shadow starts
## under the piece and the rest is laid out over the board in front of it. It
## leans from the feet line, as a shadow hung from the feet would: above that
## line it is under the piece. `feet_y` is in the holder's units, `head_y` in
## the picture's.
func _add_cast(holder: Sprite2D, pivot: Vector2, feet_y: float, head_y: float) -> void:
	var size: Vector2 = holder.texture.get_size()
	var pivot_in_picture: Vector2 = pivot - holder.offset + size * 0.5
	var head_to_pivot: float = pivot_in_picture.y - head_y
	if head_to_pivot <= 0.0:
		return
	var pivot_to_feet: float = maxf(feet_y - pivot.y, 0.0)
	# The lean tilts the shadow's length, so only the cosine of it goes down
	# the screen. How far it reaches below the feet - as far as when it was
	# hung from them - and the stretch that gets the head there from the pivot.
	var lean_cos: float = cos(CAST_LEAN)
	var reach: float = (head_to_pivot + pivot_to_feet) * CAST_LENGTH * lean_cos
	var stretch: float = (reach + pivot_to_feet) / (head_to_pivot * lean_cos)
	# The pivot row sits this far above the feet line, in the shadow's own
	# (unstretched, unleaned) rows.
	var pivot_rows_up: float = pivot_to_feet / (lean_cos * stretch)
	var cast_material := ShaderMaterial.new()
	cast_material.shader = CAST_SHADER
	# Full strength from the row that comes out at the feet.
	cast_material.set_shader_parameter(&"feet_v", (pivot_in_picture.y - pivot_rows_up) / size.y)
	cast_material.set_shader_parameter(&"head_v", head_y / size.y)
	var cast := Sprite2D.new()
	cast.texture = holder.texture
	cast.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	cast.flip_v = true
	cast.offset = Vector2(size.x * 0.5 - pivot_in_picture.x, pivot_in_picture.y - size.y * 0.5 - pivot_rows_up)
	cast.position = Vector2(pivot.x, feet_y)
	cast.scale = Vector2(1.0, stretch)
	cast.skew = CAST_LEAN
	cast.material = cast_material
	cast.z_as_relative = false
	cast.z_index = GROUND_Z_INDEX
	cast.light_mask = 0
	_ground.add_child(cast)

static func _get_plain_texture() -> Texture2D:
	if _plain_texture == null:
		var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_plain_texture = ImageTexture.create_from_image(image)
	return _plain_texture

static func _get_contact_material(front_lit: bool) -> ShaderMaterial:
	if !_contact_materials.has(front_lit):
		var contact_material := ShaderMaterial.new()
		contact_material.shader = CONTACT_SHADER
		contact_material.set_shader_parameter(&"amount", CONTACT_FRONT_LIT_AMOUNT if front_lit else CONTACT_BACK_LIT_AMOUNT)
		contact_material.set_shader_parameter(&"outer_to_base", CONTACT_SPREAD)
		_contact_materials[front_lit] = contact_material
	return _contact_materials[front_lit]
