extends Control
class_name RewardPresenter

## The animated centrepiece of a reward scene - the coins that drop onto the
## table, the stamp that flies in and flips, the deck that deals itself out.
##
## One lives in a reward scene's RightColumn; RewardSceneBase finds it, calls
## begin() once the payout is recorded, and will not leave the scene until
## presentation_finished has fired (and the dialogue is done). Everything the
## presenter needs to show comes from the scene it was handed, so the same
## presenter works for every reward of its kind.

signal presentation_finished

## Left-click anywhere on the presenter's area. Presenters that need finer
## input (a click per card) add their own hitboxes and leave this alone.
signal clicked(local_position: Vector2)

## Same card size the collection uses (Collection.STAMP_VISUAL_SIZE).
const CARD_SIZE: Vector2 = Vector2(168.7, 229.0)
const STAMP_VISUAL_SCENE: PackedScene = preload("res://Scenes/StampVisual.tscn")

var reward_scene: RewardSceneBase
var granted_now: bool = true
var is_finished: bool = false
var _has_begun: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

## Starts the show. `granted_now` is false when the player has seen this
## reward before - the payout has already happened, so counters must not move
## again, but the animation still plays so the scene never looks broken.
func begin(scene: RewardSceneBase, was_granted_now: bool) -> void:
	if _has_begun:
		return
	_has_begun = true
	reward_scene = scene
	granted_now = was_granted_now
	_start()

## Override point.
func _start() -> void:
	finish()

func finish() -> void:
	if is_finished:
		return
	is_finished = true
	presentation_finished.emit()

func _on_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		clicked.emit(mouse_event.position)

func _play_sfx(sound_name: String) -> void:
	var cleaned: String = sound_name.strip_edges()
	if !cleaned.is_empty():
		SFXManager.play(cleaned)

## A stamp card ready to be animated: face down, no hover/drag behaviour, no
## ambient float, sized from the shared card size.
func _create_stamp_card(stamp: Stamp, scale_factor: float) -> StampVisual:
	var card := STAMP_VISUAL_SCENE.instantiate() as StampVisual
	add_child(card)
	card.size = CARD_SIZE
	card.custom_minimum_size = CARD_SIZE
	card.pivot_offset = card.size * 0.5
	card.set_stamp(stamp)
	card.set_collection_owned(true)
	card.set_face_down(true)
	card.set_hover_raise_enabled(false)
	card.set_ambient_motion_enabled(false)
	card.set_rest_scale(Vector2.ONE * scale_factor)
	card.draggable = false
	card.disabled = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card

## The pack-opening flip: squash to a sliver, swap the face, pop back out.
func _flip_card(card: StampVisual, seconds: float, on_done: Callable = Callable()) -> void:
	if card == null or !is_instance_valid(card):
		return
	var target_scale: Vector2 = card.rest_scale
	var tween := card.create_tween()
	tween.tween_property(card, "scale", Vector2(0.0, target_scale.y * 1.02), seconds).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_turn_card_face_up.bind(card))
	tween.tween_property(card, "scale", target_scale, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(card, "rotation", deg_to_rad(randf_range(-1.6, 1.6)), seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if on_done.is_valid():
		tween.tween_callback(on_done)

func _turn_card_face_up(card: StampVisual) -> void:
	if card == null or !is_instance_valid(card):
		return
	card.set_face_down(false)
	card.scale = Vector2(0.0, card.scale.y)
