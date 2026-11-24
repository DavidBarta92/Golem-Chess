extends Node

## The selected piece tips a little towards the cursor (on trial: switch it
## off with PieceDisplayController.SELECTION_LEAN_ENABLED). It rocks onto the
## edge of its base on the cursor's side, so the far side of its base comes up
## off the board: a turn of the holder about that edge. What its grounding
## lays on the board - the darkening at its feet, the cast shadow - stays on
## the board and follows only part of the way (SHADOW_FOLLOW). Only sideways: tipping towards or away from the camera cannot
## be drawn with a flat picture. A child of the holder; release() lets it
## settle back and then goes.
##
## Applied as a change on top of whatever else moves the holder: the edge is
## kept in place by adding only the difference in the correction from frame to
## frame, so a squash or a press that sets the holder's position meanwhile
## keeps its own numbers, and taking the tilt off leaves them as they were.

const NODE_NAME: String = "SelectionLean"
## The most it tips, in radians; how far to the side of its base the cursor
## has to be for that, and how close it can be with none, in squares.
const MAX_TILT: float = 0.08
const FULL_TILT_SQUARES: float = 1.4
const DEAD_ZONE_SQUARES: float = 0.15
## How quickly it follows the cursor, and settles back when let go (per second).
const FOLLOW_RATE: float = 9.0
const RELEASE_RATE: float = 12.0
## What the grounding lays on the board (PieceGrounding's `_ground`).
const GROUND_PATH: NodePath = ^"PieceGrounding/Ground"
## How much the shadow on the board follows the tilt. A shadow is the piece
## laid down on the board, mirrored, so it swings the other way about the same
## edge: the head goes right, and so does the far end of its shadow.
const SHADOW_FOLLOW: float = 0.6
## The base's edge is no further up than this share of the figure's height,
## as PieceGrounding's flip row.
const MAX_ROUND_DEPTH_SHARE: float = 0.3

var _metrics_provider: Callable
var _tilt: float = 0.0
var _base_rotation: float = 0.0
var _applied_shift: Vector2 = Vector2.ZERO
var _releasing: bool = false

## `metrics_provider` measures a picture's figure
## (PieceVisualController.get_footprint_metrics).
func _init(metrics_provider: Callable = Callable()) -> void:
	name = NODE_NAME
	_metrics_provider = metrics_provider

func _ready() -> void:
	var holder: Sprite2D = get_parent() as Sprite2D
	if holder != null:
		_base_rotation = holder.rotation

func release() -> void:
	if _releasing:
		return
	_releasing = true
	# A new tilt may take the name from here on.
	name = NODE_NAME + "Releasing"

func _process(delta: float) -> void:
	var holder: Sprite2D = get_parent() as Sprite2D
	if holder == null or holder.texture == null:
		return
	var target: float = 0.0
	if !_releasing:
		var base: Dictionary = _get_base(holder)
		var sideways_squares: float = (holder.get_local_mouse_position().x - float(base["center_x"])) * absf(holder.scale.x) / float(BoardConfig.CELL_WIDTH)
		var reach: float = maxf(absf(sideways_squares) - DEAD_ZONE_SQUARES, 0.0) / (FULL_TILT_SQUARES - DEAD_ZONE_SQUARES)
		target = signf(sideways_squares) * clampf(reach, 0.0, 1.0) * MAX_TILT
	var rate: float = RELEASE_RATE if _releasing else FOLLOW_RATE
	_tilt = lerpf(_tilt, target, 1.0 - exp(-rate * delta))
	if _releasing and absf(_tilt) < 0.0005:
		_tilt = 0.0
		_apply(holder)
		queue_free()
		return
	_apply(holder)

func _notification(what: int) -> void:
	# Taken off before it settled: the holder is put back upright.
	if what == NOTIFICATION_PREDELETE and _tilt != 0.0:
		var holder: Sprite2D = get_parent() as Sprite2D
		if holder != null and is_instance_valid(holder) and !holder.is_queued_for_deletion():
			_tilt = 0.0
			_apply(holder)

func _apply(holder: Sprite2D) -> void:
	var base: Dictionary = _get_base(holder)
	# The edge of the base it rocks onto, on the side it tips to.
	var edge := Vector2(float(base["center_x"]) + signf(_tilt) * float(base["half_width"]), float(base["edge_y"]))
	var upright := Transform2D(_base_rotation, holder.scale, 0.0, Vector2.ZERO)
	var tipped := Transform2D(_base_rotation + _tilt, holder.scale, 0.0, Vector2.ZERO)
	var shift: Vector2 = upright.basis_xform(edge) - tipped.basis_xform(edge)
	holder.rotation = _base_rotation + _tilt
	holder.position += shift - _applied_shift
	_applied_shift = shift

	# What lies on the board stays on it, where the upright piece had it, and
	# swings part of the way after the tilt.
	var ground: Node2D = holder.get_node_or_null(GROUND_PATH) as Node2D
	if ground != null:
		if _tilt == 0.0:
			ground.transform = Transform2D.IDENTITY
		else:
			var resting := Transform2D(_base_rotation, holder.scale, 0.0, holder.position - shift)
			var pivot: Vector2 = resting * edge
			var swing := Transform2D(-_tilt * SHADOW_FOLLOW, pivot) * Transform2D(0.0, -pivot)
			ground.transform = holder.transform.affine_inverse() * swing * resting

## The bottom of the figure in the holder's units: the middle of its base, its
## half width, and the row its edges are on (the widest row of a round base
## drawn as an ellipse, the feet of a flat one).
func _get_base(holder: Sprite2D) -> Dictionary:
	var size: Vector2 = holder.texture.get_size()
	var metrics: Dictionary = _metrics_provider.call(holder.texture) if _metrics_provider.is_valid() else {}
	var bottom: float = float(metrics.get("bottom_y", size.y))
	var top: float = float(metrics.get("top_y", 0.0))
	var round_depth: float = clampf(float(metrics.get("base_round_depth", 0.0)), 0.0, (bottom - top) * MAX_ROUND_DEPTH_SHARE)
	var corner: Vector2 = holder.offset - size * 0.5
	return {
		"center_x": corner.x + float(metrics.get("lower_center_x", size.x * 0.5)),
		"half_width": float(metrics.get("lower_width", size.x * 0.5)) * 0.5,
		"edge_y": corner.y + bottom - round_depth,
	}
