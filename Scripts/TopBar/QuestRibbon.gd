extends BaseButton

## One active quest as a bookmark hanging from the top edge of the screen,
## past the bar's bottom edge. The cut at its foot tells the kind (slanted =
## story, V-notch = reward, crenellations = daily), the fill the reward (story
## burgundy, coin gold, draw blue), and the reward's icon sits at the bottom so
## colour is never the only signal.
##
## The control's top is the top of the screen and its height is the ribbon's
## length, so hover, done, retracted and open are all just a length. A
## BaseButton, so the UI click and hover sounds pick it up like any button.
## Printed with the ink stamp, its pattern pinned to the foot: pulled down,
## the ribbon carries its specks along.

signal left_bar

const TopBarStyle = preload("res://Scripts/TopBar/TopBarStyle.gd")
const TopBarIcons = preload("res://Scripts/TopBar/TopBarIcons.gd")
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")

const REWARD_ICON: Dictionary = {"story": "book", "coin": "coin", "draw": "draw"}
## x of the crenellation edges on a daily ribbon (design: 6 / 11 / 17 / 22 of 28).
const DAILY_TEETH: Array[float] = [4.5, 8.25, 12.75, 16.5]

var quest_id: String = ""
var kind: String = "story"
var reward: String = "story"
var done: bool = false
var urgent: bool = false
var show_seam: bool = false
var progress_ratio: float = 0.0
var length: float = TopBarStyle.RIBBON_REST:
	set(value):
		length = value
		size = Vector2(TopBarStyle.RIBBON_WIDTH, length)
		InkStampMaterial.set_anchor(self, Vector2(0.0, length))
		queue_redraw()
## 0 = its own colours, 1 = grey; an expiring ribbon fades to grey on its way out.
var desaturation: float = 0.0:
	set(value):
		desaturation = value
		queue_redraw()

var _open: bool = false
var _open_length: float = TopBarStyle.RIBBON_REST
var _retracted: bool = false
var _leaving: bool = false
## Tracked here: the mouse signals fire before BaseButton updates is_hovered().
var _hovered: bool = false
var _length_tween: Tween
var _sway_phase: float = 0.0
var _swaying: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(TopBarStyle.RIBBON_WIDTH, length)
	pivot_offset = Vector2(TopBarStyle.RIBBON_WIDTH * 0.5, 0.0)
	InkStampMaterial.apply(self, true)
	InkStampMaterial.set_anchor(self, Vector2(0.0, length))
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	set_process(false)

## Takes the quest's look from a QuestStore entry.
func configure(quest: Dictionary, is_urgent: bool) -> void:
	quest_id = str(quest.get("id", ""))
	kind = str(quest.get("kind", "story"))
	reward = "story" if kind == "story" else str(quest.get("reward", "coin"))
	done = bool(quest.get("done", false))
	urgent = is_urgent and !done
	var target: int = maxi(1, int(quest.get("target", 1)))
	show_seam = target > 1 and !done
	progress_ratio = clampf(float(quest.get("progress", 0)) / float(target), 0.0, 1.0)
	queue_redraw()
	_refresh_length()
	_refresh_sway()

func is_leaving() -> bool:
	return _leaving

## Open: the ribbon runs down to the bottom of the quest panel beside it.
func set_open(open: bool, open_length: float = TopBarStyle.RIBBON_REST) -> void:
	_open = open
	_open_length = open_length
	_refresh_length()
	_refresh_sway()

## Retracted: pulled up to the bar while another ribbon's panel is open.
func set_retracted(retracted: bool) -> void:
	_retracted = retracted
	_refresh_length()
	_refresh_sway()

## Drops in from above the screen with a slight overshoot.
func play_arrival() -> void:
	position.y = -length * 1.1
	var tween := create_tween()
	tween.tween_property(self, "position:y", 0.0, TopBarStyle.RIBBON_ARRIVE_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Claimed: a small tug down, then pulled up out of sight. Expired: greys
## out, fades and draws up. Emits left_bar when it is gone.
func play_leave(how: String) -> void:
	_leaving = true
	disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_sway()
	if _length_tween != null and _length_tween.is_valid():
		_length_tween.kill()

	var tween := create_tween()
	if how == "expire":
		var grey_seconds: float = TopBarStyle.RIBBON_EXPIRE_SECONDS * 0.45
		var rise_seconds: float = TopBarStyle.RIBBON_EXPIRE_SECONDS - grey_seconds
		tween.set_parallel(true)
		tween.tween_property(self, "desaturation", 1.0, grey_seconds)
		tween.tween_property(self, "modulate:a", 0.7, grey_seconds)
		tween.chain().tween_property(self, "modulate:a", 0.0, rise_seconds).set_ease(Tween.EASE_IN)
		tween.tween_property(self, "position:y", -length * 0.4, rise_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		var tug_seconds: float = TopBarStyle.RIBBON_CLAIM_SECONDS * 0.25
		tween.tween_property(self, "position:y", 6.0, tug_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position:y", -length * 1.15, TopBarStyle.RIBBON_CLAIM_SECONDS - tug_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	left_bar.emit()

func _set_hovered(hovered: bool) -> void:
	_hovered = hovered
	_refresh_length()

func _target_length() -> float:
	if _open:
		return _open_length
	if _retracted:
		return TopBarStyle.RIBBON_RETRACTED
	if done:
		return TopBarStyle.RIBBON_REST + TopBarStyle.RIBBON_DONE_DROP
	if _hovered:
		return TopBarStyle.RIBBON_REST + TopBarStyle.RIBBON_LIFT
	return TopBarStyle.RIBBON_REST

func _refresh_length() -> void:
	if _leaving or !is_inside_tree():
		return
	if _length_tween != null and _length_tween.is_valid():
		_length_tween.kill()
	var target: float = _target_length()
	if is_equal_approx(length, target):
		return
	_length_tween = create_tween()
	_length_tween.tween_property(self, "length", target, TopBarStyle.RIBBON_MOVE_SECONDS).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

## A done ribbon sways slowly until it is claimed; open or retracted it hangs still.
func _refresh_sway() -> void:
	var should_sway: bool = done and !_open and !_retracted and !_leaving
	if should_sway == _swaying:
		return
	_swaying = should_sway
	set_process(should_sway)
	if should_sway:
		_sway_phase = 0.0
	elif is_inside_tree():
		create_tween().tween_property(self, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		rotation = 0.0

func _process(delta: float) -> void:
	_sway_phase = fmod(_sway_phase + delta / TopBarStyle.SWAY_CYCLE_SECONDS, 1.0)
	rotation = deg_to_rad(TopBarStyle.SWAY_DEGREES) * sin(_sway_phase * TAU)

func _tone(color: Color) -> Color:
	if desaturation <= 0.0:
		return color
	var grey: float = color.get_luminance()
	return color.lerp(Color(grey, grey, grey, color.a), desaturation)

func _draw() -> void:
	var width: float = TopBarStyle.RIBBON_WIDTH
	var tail: float = float(TopBarStyle.TAIL_DEPTH.get(kind, 6.75))
	var fill_color: Color = _tone(TopBarStyle.reward_color(reward))
	var ink: Color = _tone(TopBarStyle.INK)
	var on_color: Color = _tone(TopBarStyle.on_reward_color(reward))

	draw_colored_polygon(_shape(width, length, tail), fill_color)
	draw_polyline(_outline(width, length, tail), ink, TopBarStyle.STROKE, true)

	var foot: float = length - tail
	if show_seam:
		_draw_seam(width * 0.5, 6.0, foot - 22.5, on_color)

	if done:
		var seal_center := Vector2(width * 0.5, foot - 3.75 - 7.5)
		draw_circle(seal_center, 7.5, _tone(TopBarStyle.PAPER), true, -1.0, true)
		draw_arc(seal_center, 7.5 - TopBarStyle.STROKE * 0.5, 0.0, TAU, 32, ink, TopBarStyle.STROKE, true)
		TopBarIcons.draw_icon(self, "check", Rect2(seal_center - Vector2.ONE * 4.5, Vector2.ONE * 9.0), ink, true)
	else:
		var icon_size: float = TopBarStyle.ICON_RIBBON
		var icon_rect := Rect2(Vector2(width * 0.5 - icon_size * 0.5, foot - 5.25 - icon_size), Vector2.ONE * icon_size)
		TopBarIcons.draw_icon(self, REWARD_ICON.get(reward, "book"), icon_rect, on_color, true)

	if urgent:
		var badge_center := Vector2(width - 0.75, foot - 18.0 - 6.75)
		draw_circle(badge_center, 6.75, _tone(TopBarStyle.URGENT), true, -1.0, true)
		draw_arc(badge_center, 6.75 - TopBarStyle.STROKE * 0.5, 0.0, TAU, 32, ink, TopBarStyle.STROKE, true)
		TopBarIcons.draw_icon(self, "hourglass", Rect2(badge_center - Vector2.ONE * 3.75, Vector2.ONE * 7.5), _tone(TopBarStyle.PAPER), true)

## Stitching down the middle: solid for the share done, dashed for the rest.
func _draw_seam(x: float, top: float, bottom: float, color: Color) -> void:
	if bottom - top < 4.0:
		return
	var split: float = lerpf(top, bottom, progress_ratio)
	if split > top:
		draw_line(Vector2(x, top), Vector2(x, split), color, 1.5, true)
	var dash_color := Color(color, color.a * 0.55)
	var y: float = split
	while y < bottom:
		draw_line(Vector2(x, y), Vector2(x, minf(y + 2.25, bottom)), dash_color, 1.5, true)
		y += 5.25

func _shape(width: float, height: float, tail: float) -> PackedVector2Array:
	match kind:
		"story":
			return PackedVector2Array([Vector2(0, 0), Vector2(width, 0), Vector2(width, height - tail + 0.75), Vector2(0, height)])
		"daily":
			var points := PackedVector2Array([Vector2(0, 0), Vector2(width, 0), Vector2(width, height)])
			for index in range(DAILY_TEETH.size() - 1, -1, -1):
				var edge: float = DAILY_TEETH[index]
				# Walking right to left: the even edges step up into a gap, the odd ones back down.
				if index % 2 == 1:
					points.append(Vector2(edge, height))
					points.append(Vector2(edge, height - tail))
				else:
					points.append(Vector2(edge, height - tail))
					points.append(Vector2(edge, height))
			points.append(Vector2(0, height))
			return points
	return PackedVector2Array([Vector2(0, 0), Vector2(width, 0), Vector2(width, height), Vector2(width * 0.5, height - tail), Vector2(0, height)])

## The ink line down both sides and along the cut; the top edge has none.
func _outline(width: float, height: float, tail: float) -> PackedVector2Array:
	var inset: float = TopBarStyle.STROKE * 0.5
	var bottom: float = height - inset
	var notch: float = height - tail + inset * 0.6
	match kind:
		"story":
			return PackedVector2Array([Vector2(inset, 0), Vector2(inset, bottom), Vector2(width - inset, height - tail + 0.75), Vector2(width - inset, 0)])
		"daily":
			var points := PackedVector2Array([Vector2(inset, 0), Vector2(inset, bottom)])
			for index in range(DAILY_TEETH.size()):
				var edge: float = DAILY_TEETH[index]
				if index % 2 == 0:
					points.append(Vector2(edge, bottom))
					points.append(Vector2(edge, notch))
				else:
					points.append(Vector2(edge, notch))
					points.append(Vector2(edge, bottom))
			points.append(Vector2(width - inset, bottom))
			points.append(Vector2(width - inset, 0))
			return points
	return PackedVector2Array([Vector2(inset, 0), Vector2(inset, bottom), Vector2(width * 0.5, notch), Vector2(width - inset, bottom), Vector2(width - inset, 0)])
