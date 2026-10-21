extends RewardPresenter
class_name CardFlipPresenter

## A whole hand of cards deals itself onto the table face down, and the player
## turns each one over with a click - the pack-opening reveal, but for many
## cards. Used after Boss 1, where Grandpa's fifteen become the player's.
##
## The cards are whatever the reward scene says it presents
## (RewardSceneBase.get_presented_stamps()), laid out in a grid that fits the
## presenter's rect.

@export_range(1, 8, 1) var columns: int = 5
@export_range(0.0, 60.0, 1.0) var column_gap: float = 18.0
@export_range(0.0, 60.0, 1.0) var row_gap: float = 14.0
@export_range(0.0, 2.0, 0.05) var deal_seconds: float = 0.5
@export_range(0.0, 0.5, 0.01) var deal_stagger_seconds: float = 0.09
@export_range(0.05, 1.0, 0.01) var flip_seconds: float = 0.18
## Once a card is face up it jumps: up off the table all at once, a touch
## bigger for being nearer, then settles back down into its place.
@export_range(0.0, 0.5, 0.01) var hop_height_ratio: float = 0.14
@export_range(0.0, 0.3, 0.01) var hop_grow: float = 0.06
@export_range(0.02, 1.0, 0.01) var hop_rise_seconds: float = 0.09
@export_range(0.05, 1.0, 0.01) var hop_settle_seconds: float = 0.26
@export var sfx_deal: String = "field_slips"
@export var sfx_flip: String = "codex_fold"
@export var sfx_all_flipped: String = "stamp_up"

var _cards: Array[StampVisual] = []
var _hitboxes: Array[Control] = []
var _flipped: Array[bool] = []
var _cards_landed: int = 0
var _flip_in_progress: bool = false
var _accepting_clicks: bool = false

func _start() -> void:
	var stamps: Array[Stamp] = reward_scene.get_presented_stamps() if reward_scene != null else []
	if stamps.is_empty():
		push_warning("CardFlipPresenter: the reward scene has no stamps to present.")
		finish()
		return

	var rows: int = int(ceil(float(stamps.size()) / float(columns)))
	var scale_factor: float = _fit_scale(rows)
	var card_size: Vector2 = CARD_SIZE * scale_factor
	var grid_size := Vector2(
		columns * card_size.x + (columns - 1) * column_gap,
		rows * card_size.y + (rows - 1) * row_gap
	)
	var origin: Vector2 = (size - grid_size) * 0.5
	# The deck the cards are dealt from: just past the bottom-right corner.
	var deal_from: Vector2 = size + Vector2(120.0, 80.0)

	for i in range(stamps.size()):
		var card: StampVisual = _create_stamp_card(stamps[i], scale_factor)
		# Position is the unscaled top-left; the pivot keeps the scale centred,
		# so the slot's centre has to be turned back into that space.
		var slot_center: Vector2 = origin + Vector2(
			(i % columns) * (card_size.x + column_gap) + card_size.x * 0.5,
			(i / columns) * (card_size.y + row_gap) + card_size.y * 0.5
		)
		var rest: Vector2 = slot_center - CARD_SIZE * 0.5
		card.position = deal_from - CARD_SIZE * 0.5
		card.rotation = deg_to_rad(randf_range(20.0, 40.0))
		card.home_position = rest
		card.z_index = i
		_cards.append(card)
		_flipped.append(false)
		_deal_card(card, rest, i * deal_stagger_seconds)

	_build_hitboxes(card_size)

func _fit_scale(rows: int) -> float:
	var width_scale: float = (size.x - (columns - 1) * column_gap) / (columns * CARD_SIZE.x)
	var height_scale: float = (size.y - (rows - 1) * row_gap) / (rows * CARD_SIZE.y)
	return clampf(minf(width_scale, height_scale), 0.2, 1.5)

func _deal_card(card: StampVisual, rest: Vector2, delay: float) -> void:
	var tween := card.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(_play_sfx.bind(sfx_deal))
	tween.tween_property(card, "position", rest, deal_seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(card, "rotation", deg_to_rad(randf_range(-2.0, 2.0)), deal_seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_on_card_landed.bind(card))

func _on_card_landed(card: StampVisual) -> void:
	card.home_position = card.position
	_cards_landed += 1
	if _cards_landed >= _cards.size():
		_accepting_clicks = true
		_sync_hitboxes()

## One invisible Control per card, sized to the card as it sits on the table.
## Cards themselves are non-interactive (they are scaled and rotated, which
## makes their own hit rect unreliable), so the hitboxes take the clicks.
func _build_hitboxes(card_size: Vector2) -> void:
	for i in range(_cards.size()):
		var hitbox := Control.new()
		hitbox.name = "CardHitbox%d" % (i + 1)
		hitbox.size = card_size
		hitbox.mouse_filter = Control.MOUSE_FILTER_STOP
		hitbox.z_index = 200 + i
		hitbox.gui_input.connect(_on_hitbox_gui_input.bind(i))
		add_child(hitbox)
		_hitboxes.append(hitbox)
	_sync_hitboxes()

func _sync_hitboxes() -> void:
	for i in range(_hitboxes.size()):
		var card: StampVisual = _cards[i]
		var hitbox: Control = _hitboxes[i]
		var card_size: Vector2 = CARD_SIZE * card.rest_scale
		hitbox.position = card.home_position + CARD_SIZE * 0.5 - card_size * 0.5
		hitbox.size = card_size
		hitbox.mouse_filter = Control.MOUSE_FILTER_STOP if (_accepting_clicks and !_flipped[i]) else Control.MOUSE_FILTER_IGNORE

func _on_hitbox_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or !mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if !_accepting_clicks or _flip_in_progress or _flipped[index]:
		return
	_hitboxes[index].accept_event()
	_flip(index)

func _flip(index: int) -> void:
	_flip_in_progress = true
	_flipped[index] = true
	_hitboxes[index].mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card: StampVisual = _cards[index]
	card.z_index = 100 + index
	_play_sfx(sfx_flip)
	_flip_card(card, flip_seconds, _on_flip_done.bind(index))

## The jump after the flip. Runs on its own, so the next card can be turned
## while this one is still in the air.
func _hop_card(card: StampVisual) -> void:
	if card == null or !is_instance_valid(card):
		return
	var rest: Vector2 = card.home_position
	var rest_scale: Vector2 = card.rest_scale
	var height: float = CARD_SIZE.y * rest_scale.y * hop_height_ratio
	var tween := card.create_tween()
	tween.tween_property(card, "position:y", rest.y - height, hop_rise_seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(card, "scale", rest_scale * (1.0 + hop_grow), hop_rise_seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(card, "position:y", rest.y, hop_settle_seconds).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(card, "scale", rest_scale, hop_settle_seconds).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_flip_done(index: int) -> void:
	_hop_card(_cards[index])
	_flip_in_progress = false
	if _flipped.all(func(done: bool) -> bool: return done):
		_accepting_clicks = false
		_play_sfx(sfx_all_flipped)
		get_tree().create_timer(0.8).timeout.connect(finish)
