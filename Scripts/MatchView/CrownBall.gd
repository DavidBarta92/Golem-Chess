extends Node2D

## One gold thing on the board's rim: a crown point's ball or the crown's ring.
## The picture, and the heat it can give off: a glow around it and a light on
## the board. CrownRim says where it goes and when.

const CrownGold = preload("res://Scripts/MatchView/CrownGold.gd")

## At full heat the picture is this many times brighter, which burns gold white.
const HOT_BRIGHTNESS: float = 2.6
const LIGHT_MASK_BOARD: int = 1

var body: Sprite2D
var rest_position: Vector2 = Vector2.ZERO
var rest_scale: Vector2 = Vector2.ONE
## Several lit at once share one light's worth, or together they would burn the
## board white.
var light_share: float = 1.0

var _glow: Sprite2D
var _light: PointLight2D
var _light_energy: float = 1.0

## `light_scale` is the light's reach, as a share of its texture.
func _init(picture: Texture2D, light_texture: Texture2D, light_scale: float, light_energy: float) -> void:
	_light_energy = light_energy
	_light = PointLight2D.new()
	_light.texture = light_texture
	_light.texture_scale = light_scale
	_light.color = CrownGold.GLOW
	_light.range_item_cull_mask = LIGHT_MASK_BOARD
	add_child(_light)

	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow = Sprite2D.new()
	_glow.texture = CrownGold.glow_texture()
	_glow.material = additive
	_glow.modulate = CrownGold.GLOW
	_glow.light_mask = 0
	add_child(_glow)

	body = Sprite2D.new()
	body.texture = picture
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	body.light_mask = 0
	add_child(body)
	reset()

## `glow_width` is how far across the glow reaches at full heat, in board units.
func set_rest(new_position: Vector2, new_scale: Vector2, glow_width: float, lean: float = 0.0) -> void:
	rest_position = new_position
	rest_scale = new_scale
	position = rest_position
	body.scale = rest_scale
	body.skew = lean
	_glow.scale = Vector2.ONE * glow_width / float(CrownGold.GLOW_SIZE)

## Out of sight, back in its place, cold.
func reset() -> void:
	visible = false
	modulate.a = 1.0
	position = rest_position
	z_as_relative = true
	z_index = 0
	body.position = Vector2.ZERO
	body.rotation = 0.0
	body.scale = rest_scale
	body.material = null
	body.modulate.a = 1.0
	light_share = 1.0
	set_glow(0.0)

func appear_at(at: Vector2) -> void:
	position = at
	visible = true

## Above the pieces, for as long as it is in the air over them.
func set_aloft(z: int) -> void:
	z_as_relative = false
	z_index = z

func land() -> void:
	z_as_relative = true
	z_index = 0

func set_glow(amount: float) -> void:
	var brightness: float = lerpf(1.0, HOT_BRIGHTNESS, amount)
	body.self_modulate = Color(brightness, brightness, brightness)
	_glow.modulate.a = amount
	_glow.visible = amount > 0.0
	_light.enabled = amount > 0.0
	_light.energy = amount * _light_energy * light_share
