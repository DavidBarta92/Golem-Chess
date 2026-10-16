extends Control
class_name MatchClock

## The pair of clocks, hanging on their tag beside the board.
##
## The drawn tag and both counters are children of this, so whatever this does
## they all do together - there is one object here, not three that happen to
## overlap.
##
## Two movements, and they are not the same kind:
##
##   - **the idle sway** is a gentle tilt about the clock's middle, the codex's
##     own rhythm. A tilt rather than a slide because a slide has to go through
##     the layout, which rounds it to whole pixels and makes three pixels over
##     four seconds look like stepping rather than floating.
##   - **the knock**, when the turn passes, is a sideways swing. It is large
##     and quick enough that the rounding does not show.
##
## The sideways offset is published rather than applied, because the clock's
## place on screen is worked out from the canvas every frame by whoever owns
## it; one writer for the position, and this is not it. The tilt has no such
## problem, so it is set here.

## The drawn tag and where its two windows sit inside it. Measured on
## Assets/clock_frame_double.png - re-measure if that is redrawn. The tag
## carries its own colon, so the counters leave a gap for it and print none of
## their own.
const ART_SIZE: Vector2 = Vector2(1211.0, 431.0)
const WINDOW_TOP: Rect2 = Rect2(31.0, 68.0, 653.0, 143.0)
const WINDOW_BOTTOM: Rect2 = Rect2(33.0, 261.0, 653.0, 143.0)
## The middle of the two faces. The clock is placed by this rather than by the
## middle of the image, so that drawing more tag - a longer string, say - moves
## the artwork without moving the thing the player reads.
const FACE_CENTRE: Vector2 = Vector2(358.0, 235.5)

const SWAY_ANGLE_DEGREES: float = 0.7
const SWAY_HALF_DURATION: float = 4.0

## The knock. Swings out, comes back past the middle, and settles - a floating
## thing does not stop dead.
const NUDGE_OFFSET: float = 10.0
const NUDGE_OUT_DURATION: float = 0.22
const NUDGE_SETTLE_DURATION: float = 0.34

## How far sideways it currently sits, for the caller to add to its position.
var sway_offset: float = 0.0

## The rocker on the clock's left side. Drawn at the same scale as the tag and
## tucked behind it, with its pivot - the red dot on the art - just inside the
## tag's edge, so the dot itself never shows and the wedges either side of it
## swing out past it. White out means it is the player's move, black out means
## the opponent's; it tips between the two like a switch being thrown.
const BUTTON_ART_SIZE: Vector2 = Vector2(211.0, 309.0)
const BUTTON_PIVOT: Vector2 = Vector2(62.9, 149.9)
## Where that pivot sits on the tag: just behind its left edge, half way down.
const BUTTON_PIVOT_ON_FRAME: Vector2 = Vector2(20.0, 238.0)
## Enough to carry the black wedge across to the side the white one is on.
const BUTTON_TILT_DEGREES: float = -28.0
const BUTTON_FLIP_SECONDS: float = 0.2
## The switch being thrown is what the player hears when a turn closes - the
## sound belongs to this movement rather than to whatever caused it, so a turn
## ended by the button, by a move, or by the opponent all sound the same, and a
## rocker that does not tip makes no sound.
const SWITCH_SOUND: String = "end_turn_button_click"

var _sway: Tween
var _nudge: Tween
var _button: TextureRect
var _button_tween: Tween
var _scale: float = 1.0

## Assembles the clock: the two counters in their windows, the drawn tag over
## them, the rocker behind, and the sway running.
##
## `make_counter` is handed the name, the key and the width to fill, and gives
## back a four digit counter with no frame and no colon of its own. It builds
## that counter wherever it likes; this takes it in afterwards.
func build(
	back_texture: Texture2D,
	frame_texture: Texture2D,
	button_texture: Texture2D,
	make_counter: Callable,
	counter_height: float,
	opponent_key: int,
	player_key: int
) -> void:
	# Scaled so a window is exactly as tall as a counter, which makes the
	# digits fill it without any fitting of their own.
	_scale = counter_height / WINDOW_TOP.size.y
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = ART_SIZE * _scale

	# Behind everything, on the same canvas as the tag, so the two line up
	# without being fitted to each other. It is what the digit cards sit on,
	# which is what stops their edges showing against the room.
	_add_layer("ClockBack", back_texture, -2)

	for row in [
		{"key": opponent_key, "name": "OpponentClock", "window": WINDOW_TOP},
		{"key": player_key, "name": "PlayerClock", "window": WINDOW_BOTTOM},
	]:
		var window: Rect2 = row["window"]
		var counter: Control = make_counter.call(
			str(row["name"]), int(row["key"]), window.size.x * _scale) as Control
		if counter == null:
			continue
		counter.get_parent().remove_child(counter)
		add_child(counter)
		counter.position = window.position * _scale
		counter.visible = true
		# The counter brings the deck counters' own layer with it, which would
		# put it over the tag. Inside here the container's layer is the one
		# that counts.
		counter.z_index = 0

	# Over the digits, not behind them: the outline and the colon are the part
	# that has to read on top.
	_add_layer("ClockFrame", frame_texture, 1)

	add_rocker(button_texture, _scale)
	begin_sway()

## One of the drawn sheets that make up the clock. They share the artwork's
## canvas, so each one simply fills this and they need no fitting to each
## other.
func _add_layer(layer_name: String, texture: Texture2D, layer_z: int) -> void:
	if texture == null:
		return
	var sheet := TextureRect.new()
	add_child(sheet)
	sheet.name = layer_name
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.texture = texture
	sheet.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet.stretch_mode = TextureRect.STRETCH_SCALE
	sheet.size = size
	sheet.z_index = layer_z

## Where the middle of the two faces sits inside this, for a caller placing the
## clock by what the player reads rather than by the artwork's corner.
func face_offset() -> Vector2:
	return FACE_CENTRE * _scale

func begin_sway() -> void:
	# About its own middle: anywhere else and one end of a clock this wide
	# swings far more than the other.
	pivot_offset = size * 0.5
	_start_sway()

## Hangs the rocker behind the tag. `scale_factor` is the one the tag itself is
## drawn at, so the two are the same size relative to each other as they are on
## the artwork.
func add_rocker(texture: Texture2D, scale_factor: float) -> void:
	if texture == null:
		return
	_button = TextureRect.new()
	_button.name = "ClockRocker"
	_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.texture = texture
	_button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_button.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_button.stretch_mode = TextureRect.STRETCH_SCALE
	_button.size = BUTTON_ART_SIZE * scale_factor
	_button.pivot_offset = BUTTON_PIVOT * scale_factor
	_button.position = BUTTON_PIVOT_ON_FRAME * scale_factor - _button.pivot_offset
	# Behind the tag, which is what hides the pivot and the inner half of each
	# wedge.
	_button.z_index = -1
	add_child(_button)

## Throws the switch: upright for the player's move, tipped for the opponent's.
func set_player_to_move(is_player: bool) -> void:
	if _button == null or !is_instance_valid(_button):
		return
	var target: float = 0.0 if is_player else BUTTON_TILT_DEGREES
	if is_equal_approx(_button.rotation_degrees, target):
		return
	SFXManager.play(SWITCH_SOUND)
	_kill(_button_tween)
	_button_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_button_tween.tween_property(_button, "rotation_degrees", target, BUTTON_FLIP_SECONDS)

func _start_sway() -> void:
	_kill(_sway)
	_sway = create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_sway.tween_property(self, "rotation_degrees", SWAY_ANGLE_DEGREES, SWAY_HALF_DURATION)
	_sway.tween_property(self, "rotation_degrees", -SWAY_ANGLE_DEGREES, SWAY_HALF_DURATION * 2.0)
	_sway.tween_property(self, "rotation_degrees", 0.0, SWAY_HALF_DURATION)

## Knocks it sideways. `direction` is which way it is pushed, so a turn passing
## one way and then the other does not look like the same canned animation.
func nudge(direction: float = 1.0) -> void:
	_kill(_nudge)
	var swing: float = NUDGE_OFFSET * signf(direction if direction != 0.0 else 1.0)
	_nudge = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_nudge.tween_method(_set_offset, sway_offset, swing, NUDGE_OUT_DURATION)
	_nudge.tween_method(_set_offset, swing, -swing * 0.45, NUDGE_SETTLE_DURATION)
	_nudge.tween_method(_set_offset, -swing * 0.45, swing * 0.15, NUDGE_SETTLE_DURATION * 0.8)
	_nudge.tween_method(_set_offset, swing * 0.15, 0.0, NUDGE_SETTLE_DURATION * 0.6)

func _set_offset(value: float) -> void:
	sway_offset = value

func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
