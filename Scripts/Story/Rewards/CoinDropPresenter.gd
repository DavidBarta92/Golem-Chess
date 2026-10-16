extends RewardPresenter
class_name CoinDropPresenter

## Coins fall in from above, bounce and wobble to rest on the table, and on a
## click fly up to the coin counter in the top bar, which counts up as each
## one lands. Used after Boss 4 (three coins) and Boss 11/12 (a lot of them).
##
## The number of coins on the table follows the reward's grant_points, capped
## so a big payout still reads as "a pile" rather than a wall of sprites; each
## coin then carries an equal share of the points into the counter.

const COIN_TEXTURE: Texture2D = preload("res://Assets/coin.svg")
const HIGH_LAYER: int = 1250

@export_range(1, 60, 1) var max_visible_coins: int = 30
@export_range(24.0, 96.0, 1.0) var coin_size: float = 52.0
## Where the coins come to rest, as a fraction of the presenter's height.
@export_range(0.2, 1.0, 0.01) var table_line_ratio: float = 0.72
@export_range(0.0, 2.0, 0.05) var drop_seconds: float = 0.55
@export_range(0.0, 1.0, 0.01) var drop_stagger_seconds: float = 0.08
@export_range(0.0, 2.0, 0.05) var fly_seconds: float = 0.6
@export_range(0.0, 0.5, 0.01) var fly_stagger_seconds: float = 0.05
@export var sfx_land: String = "piece_placed"
@export var sfx_fly: String = "pack_whoosh"
@export var sfx_count: String = "buy"

var _coins: Array[TextureRect] = []
var _coins_landed: int = 0
var _coins_arrived: int = 0
var _points_total: int = 0
var _points_start: int = 0
var _accepting_click: bool = false
var _fly_layer: CanvasLayer

func _start() -> void:
	var points: int = reward_scene.grant_points if reward_scene != null else 0
	var coin_count: int = clampi(points, 1, max_visible_coins)

	# The payout is already in the store; the counter starts from before it
	# and climbs as the coins arrive. On a re-entry nothing was paid, so the
	# counter simply stays where it is.
	_points_total = PlayerProgressStore.get_points()
	_points_start = _points_total - points if granted_now else _points_total
	GlobalTopBar.show_points_only()
	GlobalTopBar.set_displayed_points(_points_start)

	clicked.connect(_on_clicked)
	_spawn_and_drop(coin_count)

func _spawn_and_drop(coin_count: int) -> void:
	var table_y: float = size.y * table_line_ratio
	var spread: float = minf(size.x * 0.6, coin_count * coin_size * 0.55)
	var left: float = size.x * 0.5 - spread * 0.5

	for i in range(coin_count):
		var coin := TextureRect.new()
		coin.texture = COIN_TEXTURE
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		coin.size = Vector2.ONE * coin_size
		coin.pivot_offset = coin.size * 0.5
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(coin)
		_coins.append(coin)

		var t: float = float(i) / maxf(1.0, coin_count - 1) if coin_count > 1 else 0.5
		var rest_x: float = left + spread * t + randf_range(-coin_size * 0.25, coin_size * 0.25) - coin_size * 0.5
		var rest_y: float = table_y - coin_size * 0.5 + randf_range(-coin_size * 0.18, coin_size * 0.18)
		coin.position = Vector2(rest_x + randf_range(-30.0, 30.0), -coin_size * 1.5 - randf_range(0.0, 80.0))
		coin.rotation = randf_range(-0.6, 0.6)
		coin.modulate.a = 0.0

		_drop_coin(coin, Vector2(rest_x, rest_y), i * drop_stagger_seconds + randf_range(0.0, 0.04))

## Fall, hit the table, two shrinking bounces with a little sideways skid and
## a wobble, then lie still.
func _drop_coin(coin: TextureRect, rest: Vector2, delay: float) -> void:
	var tween := coin.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(_show_coin.bind(coin))
	tween.tween_property(coin, "position", rest, drop_seconds).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(coin, "rotation", coin.rotation + randf_range(-1.2, 1.2), drop_seconds)
	tween.tween_callback(_play_sfx.bind(sfx_land))

	var bounce_height: float = coin_size * randf_range(0.45, 0.8)
	var skid: float = randf_range(-coin_size * 0.35, coin_size * 0.35)
	for bounce in range(2):
		var up: Vector2 = rest + Vector2(skid * 0.5, -bounce_height)
		var down: Vector2 = rest + Vector2(skid, 0.0)
		var up_time: float = 0.16 - bounce * 0.05
		tween.tween_property(coin, "position", up, up_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(coin, "rotation", coin.rotation + randf_range(-0.5, 0.5), up_time)
		tween.tween_property(coin, "position", down, up_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		bounce_height *= 0.38
		rest = down

	# A last shiver as it settles flat.
	tween.tween_property(coin, "scale", Vector2(1.08, 0.94), 0.06)
	tween.tween_property(coin, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(_on_coin_landed)

func _show_coin(coin: TextureRect) -> void:
	if is_instance_valid(coin):
		coin.modulate.a = 1.0

func _on_coin_landed() -> void:
	_coins_landed += 1
	if _coins_landed >= _coins.size():
		_accepting_click = true

func _on_clicked(_local_position: Vector2) -> void:
	if !_accepting_click:
		return
	_accepting_click = false
	_fly_to_counter()

## Every coin arcs up to the counter; each arrival bumps the number and gives
## the counter a little pulse. The coins are lifted into their own high layer
## first so they pass over the top bar rather than under it.
func _fly_to_counter() -> void:
	_fly_layer = CanvasLayer.new()
	_fly_layer.layer = HIGH_LAYER
	add_child(_fly_layer)
	var target: Vector2 = GlobalTopBar.get_coin_global_center()
	_play_sfx(sfx_fly)

	for i in range(_coins.size()):
		var coin: TextureRect = _coins[i]
		coin.reparent(_fly_layer, true)
		var start: Vector2 = coin.global_position
		var end: Vector2 = target - coin.size * 0.5
		var lift: Vector2 = Vector2(randf_range(-60.0, 60.0), -randf_range(90.0, 160.0))
		var tween := coin.create_tween()
		tween.tween_interval(i * fly_stagger_seconds)
		tween.tween_method(_fly_step.bind(coin, start, start.lerp(end, 0.5) + lift, end), 0.0, 1.0, fly_seconds).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(_on_coin_arrived.bind(coin))

## One step along a quadratic arc: up and over, then into the counter.
func _fly_step(t: float, coin: TextureRect, p0: Vector2, p1: Vector2, p2: Vector2) -> void:
	if !is_instance_valid(coin):
		return
	coin.global_position = p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)
	coin.scale = Vector2.ONE.lerp(Vector2.ONE * 0.5, t)
	coin.rotation += 0.12

func _on_coin_arrived(coin: TextureRect) -> void:
	_coins_arrived += 1
	if is_instance_valid(coin):
		coin.queue_free()
	_play_sfx(sfx_count)

	var shown: int = _points_start + int(round(float(_points_total - _points_start) * float(_coins_arrived) / float(maxi(1, _coins.size()))))
	GlobalTopBar.set_displayed_points(shown)
	GlobalTopBar.pulse_points_hud()

	if _coins_arrived >= _coins.size():
		GlobalTopBar.set_displayed_points(_points_total)
		get_tree().create_timer(0.35).timeout.connect(finish)
