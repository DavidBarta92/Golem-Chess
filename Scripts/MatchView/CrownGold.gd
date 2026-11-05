extends RefCounted

## The gold everything to do with the crown is made of: the shades of
## Assets/coin.svg, and the pictures of a crown point's ball and of the crown's
## ring, lying in its groove and worn on a golem. Painted here rather than
## loaded, so that the burn a lost point goes out with
## (Shaders/stamp_burn.gdshader) has a texture to work on: a stand-in until they
## have their own art.

const LIGHT: Color = Color("#f9df99")
const BODY: Color = Color("#f7ca50")
const SHADE: Color = Color("#c39333")
const DEEP: Color = Color("#90753a")
const OUTLINE: Color = Color("#20415d")
## What the gold gives off on the board.
const GLOW: Color = Color(1.0, 0.8, 0.42)

const BALL_SIZE: int = 48
const RING_SIZE: int = 96
## The ring on a golem, the same torus seen from low down: as wide as RING_SIZE
## and as tall as it then comes out.
const WORN_RING_HEIGHT: int = 52
const WORN_RING_TILT: float = 0.42
const GLOW_SIZE: int = 128
const OUTLINE_PIXELS: float = 2.5

## Where the light falls on the ball, from -1 to 1 across the picture.
const BALL_LIT_POINT: Vector2 = Vector2(-0.36, -0.42)
## The ring's tube, as shares of the picture's half width.
const RING_MIDDLE: float = 0.78
const RING_TUBE: float = 0.2
const RING_LIGHT_FROM: Vector2 = Vector2(-0.6, -0.8)

static var _ball: Texture2D
static var _ring: Texture2D
static var _worn_ring: Texture2D
static var _glow: Texture2D

static func ball_texture() -> Texture2D:
	if _ball == null:
		_ball = _paint(Vector2i(BALL_SIZE, BALL_SIZE), _ball_pixel)
	return _ball

static func ring_texture() -> Texture2D:
	if _ring == null:
		_ring = _paint(Vector2i(RING_SIZE, RING_SIZE), _ring_pixel)
	return _ring

static func worn_ring_texture() -> Texture2D:
	if _worn_ring == null:
		_worn_ring = _paint(Vector2i(RING_SIZE, WORN_RING_HEIGHT), _worn_ring_pixel)
	return _worn_ring

static func glow_texture() -> Texture2D:
	if _glow == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		gradient.add_point(0.3, Color(1.0, 1.0, 1.0, 0.38))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = GLOW_SIZE
		texture.height = GLOW_SIZE
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		_glow = texture
	return _glow

## Each pixel is asked for by where it lies from the middle of the picture, in
## shares of half its width.
static func _paint(size: Vector2i, pixel: Callable) -> Texture2D:
	var image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var half: float = float(size.x) * 0.5
	var middle: Vector2 = Vector2(size) * 0.5
	for y in size.y:
		for x in size.x:
			image.set_pixel(x, y, pixel.call((Vector2(x, y) + Vector2.ONE * 0.5 - middle) / half, half))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

static func _ball_pixel(at: Vector2, half: float) -> Color:
	var inside: float = (1.0 - at.length()) * half
	return _gold_or_outline(_ball_shade(at.distance_to(BALL_LIT_POINT)), inside)

static func _ball_shade(distance_from_light: float) -> Color:
	if distance_from_light < 0.34:
		return LIGHT
	if distance_from_light < 1.02:
		return BODY
	return SHADE if distance_from_light < 1.42 else DEEP

static func _ring_pixel(at: Vector2, half: float) -> Color:
	return _tube_pixel(at - at.normalized() * RING_MIDDLE, half)

## The tube keeps its round section however far over the ring is tipped, so it is
## as thick all the way round: squashing the flat picture would make a washer.
static func _worn_ring_pixel(at: Vector2, half: float) -> Color:
	return _tube_pixel(at - _nearest_on_worn_ring(at), half)

## The middle of the worn ring's tube, nearest to this point: an ellipse has no
## neat answer, so a guess and a few steps towards it.
static func _nearest_on_worn_ring(at: Vector2) -> Vector2:
	var reach := Vector2(RING_MIDDLE, RING_MIDDLE * WORN_RING_TILT)
	var angle: float = atan2(at.y / reach.y, at.x / reach.x)
	for step in 4:
		var along := Vector2(-reach.x * sin(angle), reach.y * cos(angle))
		var point := Vector2(reach.x * cos(angle), reach.y * sin(angle))
		angle += (at - point).dot(along) / along.length_squared()
	return Vector2(reach.x * cos(angle), reach.y * sin(angle))

## `from_middle` is how far this pixel lies from the middle of the tube, and which way.
static func _tube_pixel(from_middle: Vector2, half: float) -> Color:
	var inside: float = (RING_TUBE - from_middle.length()) * half
	return _gold_or_outline(_ring_shade((from_middle / RING_TUBE).dot(RING_LIGHT_FROM)), inside)

static func _ring_shade(leaning_towards_light: float) -> Color:
	if leaning_towards_light > 0.42:
		return LIGHT
	if leaning_towards_light > -0.22:
		return BODY
	return SHADE if leaning_towards_light > -0.62 else DEEP

## `inside` is how many pixels in from the edge this pixel lies.
static func _gold_or_outline(gold: Color, inside: float) -> Color:
	var colour: Color = OUTLINE.lerp(gold, clampf(inside - OUTLINE_PIXELS + 0.5, 0.0, 1.0))
	colour.a = clampf(inside + 0.5, 0.0, 1.0)
	return colour
