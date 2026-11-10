extends Control
class_name EnvelopeView

## One part of an envelope (EnvelopeArt), drawn to fill this control's width;
## its height follows the envelope's shape (get_envelope_height). The front
## carries the puzzle's mark: the reward stamp itself, stuck on a little
## crooked, a postmark for coins, a wax seal for draw points.

const STAMP_VISUAL_SCENE: PackedScene = preload("res://Scenes/StampVisual.tscn")
const InkStampMaterial = preload("res://Scripts/InkStamp/InkStampMaterial.gd")
## StampVisual's own size (Collection.STAMP_VISUAL_SIZE).
const STAMP_CARD_SIZE: Vector2 = Vector2(168.7, 229.0)
const STAMP_TILT_DEGREES: float = 3.0

enum Part { FRONT, BACK, LINING, FLAP_OPEN, FLAP_CLOSED, POCKET }

var style: int = PuzzleDefinition.EnvelopeStyle.BRITISH
var part: Part = Part.FRONT
var reward_kind: int = -1
var reward_stamp: Stamp
var reward_print: StampPrint
var _stamp_card: StampVisual
## The postmark, on a layer of its own so it takes the UI's ink stamp while
## the envelope's paper does not.
var _postmark: Control

func _init(envelope_style: int = PuzzleDefinition.EnvelopeStyle.BRITISH, envelope_part: Part = Part.FRONT) -> void:
	style = envelope_style
	part = envelope_part
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	resized.connect(_on_resized)
	_on_resized()

## The puzzle's mark on the front.
func set_mark(kind: int, stamp: Stamp = null, stamp_print: StampPrint = null) -> void:
	reward_kind = kind
	reward_stamp = stamp
	reward_print = stamp_print
	_update_stamp_card()
	_update_postmark()
	queue_redraw()

func get_envelope_height(width: float) -> float:
	return EnvelopeArt.get_height(style, width)

func _on_resized() -> void:
	_update_stamp_card()
	_update_postmark()
	queue_redraw()

func _update_postmark() -> void:
	var wants_postmark: bool = part == Part.FRONT and reward_kind == PuzzleDefinition.RewardKind.COINS
	if !wants_postmark:
		if _postmark != null:
			_postmark.queue_free()
			_postmark = null
		return
	if _postmark == null:
		_postmark = Control.new()
		_postmark.name = "Postmark"
		_postmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_postmark.draw.connect(func() -> void: EnvelopeArt.draw_postmark(_postmark, size.x))
		add_child(_postmark)
		InkStampMaterial.apply(_postmark)
	_postmark.size = size
	_postmark.queue_redraw()

func _draw() -> void:
	var width: float = size.x
	if width <= 0.0:
		return
	match part:
		Part.FRONT:
			EnvelopeArt.draw_front(self, style, width)
			_draw_mark(width)
		Part.BACK:
			EnvelopeArt.draw_back(self, style, width)
		Part.LINING:
			EnvelopeArt.draw_lining(self, style, width)
		Part.FLAP_OPEN:
			EnvelopeArt.draw_flap(self, style, width, true)
		Part.FLAP_CLOSED:
			EnvelopeArt.draw_flap(self, style, width, false)
		Part.POCKET:
			EnvelopeArt.draw_pocket(self, style, width)

func _draw_mark(width: float) -> void:
	match reward_kind:
		# The postmark draws on its own layer (_update_postmark).
		PuzzleDefinition.RewardKind.DRAW_POINTS:
			EnvelopeArt.draw_wax_seal(self, width)
		# The stamp is a child of its own (_update_stamp_card).

## The reward stamp as the game draws it, small and a little crooked in the
## corner, where a postage stamp goes.
func _update_stamp_card() -> void:
	var wants_card: bool = part == Part.FRONT and reward_kind == PuzzleDefinition.RewardKind.STAMP and (reward_stamp != null or reward_print != null)
	if !wants_card:
		if _stamp_card != null:
			_stamp_card.queue_free()
			_stamp_card = null
		return
	if _stamp_card == null:
		_stamp_card = STAMP_VISUAL_SCENE.instantiate() as StampVisual
		add_child(_stamp_card)
		_stamp_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stamp_card.size = STAMP_CARD_SIZE
		_stamp_card.custom_minimum_size = STAMP_CARD_SIZE
		_stamp_card.pivot_offset = STAMP_CARD_SIZE * 0.5
		_stamp_card.draggable = false
		_stamp_card.disabled = true
		_stamp_card.set_hover_raise_enabled(false)
		_stamp_card.set_ambient_motion_enabled(false)
		_stamp_card.set_collection_owned(true)
	if reward_stamp != null:
		_stamp_card.set_stamp(reward_stamp)
	if reward_print != null:
		_stamp_card.set_stamp_print(reward_print)
	var rect: Rect2 = EnvelopeArt.get_stamp_rect(size.x)
	var card_scale: float = rect.size.x / STAMP_CARD_SIZE.x
	_stamp_card.set_rest_scale(Vector2.ONE * card_scale)
	_stamp_card.scale = Vector2.ONE * card_scale
	_stamp_card.position = rect.get_center() - STAMP_CARD_SIZE * 0.5
	_stamp_card.rotation = deg_to_rad(STAMP_TILT_DEGREES)
