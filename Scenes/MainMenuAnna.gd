extends Control

## Anna, standing in the middle of the shop on the main menu, idling the way
## someone standing still does: mostly still, with small moves that set off
## quickly and settle. Her upper body shifts at the waist now and then while
## her legs stay planted, she breathes in her chest only, she glances down
## and up, now and then turning her head a little towards you or the window,
## and every few seconds she lets the arm with the rag hang straight before
## lifting it back. Her head keeps level while her body moves, as a real head
## does, and she blinks if her closed eye is drawn.
##
## The drawing and its bones are MainMenuAnnaRig.tscn, built by
## tools/build_anna_rig.py from her layers in Assets/MainMenu/Anna - re-run that after
## redrawing one. This script lays the rig over the menu art the way the
## artwork buttons are laid (scaled to cover the screen, centred), and moves
## the bones away from their rest pose: at rest she is exactly the drawing.
## Distances are in the art's pixels, which are about screen pixels at 1080p;
## angles in degrees.

## The breath's shape, as shares of one breath: in until this point...
const BREATH_INHALE_END: float = 0.38
## ...out until this one, then a still pause until the next breath.
const BREATH_EXHALE_END: float = 0.82
## Longest frame the motion is worked out for: a hitch must not fling her.
const MAX_FRAME_SECONDS: float = 0.1
## How the springs move. Frequency (radians per second) sets how quickly a
## move happens, damping how it settles: 1 lands without overshooting, less
## overshoots a little and comes back.
const WAIST_FREQUENCY: float = 2.6
const WAIST_DAMPING: float = 0.9
const HEAD_FREQUENCY: float = 11.0
const HEAD_DAMPING: float = 0.72
const TURN_FREQUENCY: float = 8.0
const TURN_DAMPING: float = 0.8
const ARM_DROP_FREQUENCY: float = 3.4
const ARM_DROP_DAMPING: float = 0.55
const ARM_LIFT_FREQUENCY: float = 4.2
const ARM_LIFT_DAMPING: float = 0.8
const RAG_FREQUENCY: float = 6.5
const RAG_DAMPING: float = 0.35
## A blink: the eye stays shut this long; a second blink follows this often.
const BLINK_SECONDS: float = 0.11
const DOUBLE_BLINK_CHANCE: float = 0.15
const DOUBLE_BLINK_GAP_SECONDS: float = 0.16
## A glance this big or bigger often comes with a blink, as it does in life.
const BLINK_WITH_GLANCE_DEGREES: float = 2.0
const BLINK_WITH_GLANCE_CHANCE: float = 0.5

@export_group("Breathing")
## How long one breath takes; each breath picks its own length in this range.
@export var breath_seconds: Vector2 = Vector2(4.2, 5.6)
## How much the back over the ribs widens (x) and lengthens (y) at the top of
## a breath: about a pixel at the shoulders.
@export var breath_swell: Vector2 = Vector2(0.0025, 0.005)

@export_group("Waist")
## How far her upper body leans from the waist at most, either way.
@export var waist_lean: float = 0.5
## How long she holds a lean before shifting again.
@export var waist_hold_seconds: Vector2 = Vector2(3.0, 8.0)
## The share of the body's lean the head takes back, to stay level.
@export_range(0.0, 1.0) var head_steadiness: float = 0.8

@export_group("Head")
## How far she looks down, and up, at most.
@export var look_down: float = 4.5
@export var look_up: float = 2.0
## The small adjustments between glances.
@export var head_settle: float = 0.6
@export var head_hold_seconds: Vector2 = Vector2(1.4, 5.0)
## How often a new glance looks down, looks up, or comes back near level.
@export_range(0.0, 1.0) var look_down_chance: float = 0.45
@export_range(0.0, 1.0) var look_up_chance: float = 0.2
## How far she turns her head towards you, and further towards the window,
## at most. Faked from the head's depth (see tools/build_anna_rig.py), so it
## holds up only for small turns.
@export var turn_to_viewer: float = 4.0
@export var turn_to_window: float = 2.0
## How often a glance comes with a turn; otherwise the head turns back.
@export_range(0.0, 1.0) var turn_chance: float = 0.35

@export_group("Arm")
## How far the elbow opens when she lets the arm hang straight.
@export var arm_straighten: float = 16.0
## How long she holds the rag up between drops, and how long the arm hangs.
@export var arm_hold_seconds: Vector2 = Vector2(5.0, 10.0)
@export var arm_hang_seconds: Vector2 = Vector2(1.0, 2.5)
## How far the shoulder sinks while the arm hangs.
@export var shoulder_drop: float = 0.8
## The share of the forearm's turn the hand takes back, so the rag keeps
## hanging down; it follows a little late and swings.
@export_range(0.0, 1.0) var rag_hang: float = 0.5

@export_group("Blinking")
@export var blink_interval_seconds: Vector2 = Vector2(2.5, 6.0)

@onready var rig: Node2D = $Rig
@onready var waist: Bone2D = $Rig/Skeleton/Hip/Waist
@onready var ribs: Bone2D = $Rig/Skeleton/Hip/Waist/Chest/Ribs
@onready var neck: Bone2D = $Rig/Skeleton/Hip/Waist/Chest/Neck
@onready var head: Bone2D = $Rig/Skeleton/Hip/Waist/Chest/Neck/Head
@onready var head_turn: Bone2D = $Rig/Skeleton/Hip/Waist/Chest/Neck/Head/Turn
## How far the nearest part of the head (the ear) stands out from its
## outline, in art pixels: a turn slides it by this times the turn's sine.
@onready var head_turn_depth: float = rig.get_meta("head_turn_depth", 70.0)
@onready var shoulder: Bone2D = $Rig/Skeleton/Hip/Waist/Chest/Shoulder
@onready var elbow: Bone2D = $Rig/Skeleton/Hip/Waist/Chest/Shoulder/Elbow
@onready var hand: Bone2D = $Rig/Skeleton/Hip/Waist/Chest/Shoulder/Elbow/Hand
## Only there once the closed eye is drawn and the rig rebuilt.
@onready var closed_eye: CanvasItem = get_node_or_null("Rig/EyeClosed")

var rng := RandomNumberGenerator.new()
var breath_phase: float = 0.0
var breath_length: float = 5.0
var waist_spring := Spring.new(WAIST_FREQUENCY, WAIST_DAMPING)
var waist_wait: float = 0.0
var head_spring := Spring.new(HEAD_FREQUENCY, HEAD_DAMPING)
var turn_spring := Spring.new(TURN_FREQUENCY, TURN_DAMPING)
var head_wait: float = 0.0
var arm_spring := Spring.new(ARM_LIFT_FREQUENCY, ARM_LIFT_DAMPING)
var arm_hanging: bool = false
var arm_wait: float = 0.0
var rag_spring := Spring.new(RAG_FREQUENCY, RAG_DAMPING)
var blink_wait: float = 0.0
var blink_left: float = 0.0
var second_blink_in: float = -1.0

## Follows its target like a damped spring: sets off at once and settles,
## overshooting a little when lightly damped.
class Spring:
	## Worked out in steps this long, whatever the frame rate.
	const STEP_SECONDS: float = 1.0 / 120.0

	var value: float = 0.0
	var velocity: float = 0.0
	var target: float = 0.0
	var frequency: float
	var damping: float

	func _init(spring_frequency: float, spring_damping: float) -> void:
		frequency = spring_frequency
		damping = spring_damping

	func step(delta: float) -> float:
		var steps: int = maxi(1, ceili(delta / STEP_SECONDS))
		var h: float = delta / steps
		for _i in steps:
			var acceleration: float = frequency * frequency * (target - value) - 2.0 * damping * frequency * velocity
			velocity += acceleration * h
			value += velocity * h
		return value

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	# Mid-breath, with every habit at a different point of its wait, so no two
	# visits to the menu start alike.
	breath_length = rng.randf_range(breath_seconds.x, breath_seconds.y)
	breath_phase = rng.randf()
	waist_wait = rng.randf_range(0.5, waist_hold_seconds.y)
	head_wait = rng.randf_range(0.3, head_hold_seconds.y)
	arm_wait = rng.randf_range(2.0, arm_hold_seconds.y)
	blink_wait = rng.randf_range(0.5, blink_interval_seconds.y)
	resized.connect(_lay_over_art)
	_lay_over_art()

## Scaled to cover the screen and centred, like the menu's artwork, so she
## stands where she was drawn on the background.
func _lay_over_art() -> void:
	var art_size: Vector2 = rig.get_meta("art_canvas_size", Vector2(1919, 1077))
	var cover: float = maxf(size.x / art_size.x, size.y / art_size.y)
	rig.scale = Vector2.ONE * cover
	rig.position = (size - art_size * cover) * 0.5

func _process(delta: float) -> void:
	var step: float = minf(delta, MAX_FRAME_SECONDS)
	if step <= 0.0:
		return
	_plan_waist(step)
	_plan_head(step)
	_plan_arm(step)
	_blink(step)

	breath_phase += step / breath_length
	if breath_phase >= 1.0:
		breath_phase -= 1.0
		breath_length = rng.randf_range(breath_seconds.x, breath_seconds.y)
	var breath: float = _breath_amount(breath_phase)
	var lean: float = deg_to_rad(waist_spring.step(step))
	var arm: float = arm_spring.step(step)
	rag_spring.target = arm * rag_hang
	var rag: float = rag_spring.step(step)

	_pose(waist, Vector2.ZERO, lean)
	# The breath swells the back alone. The collar and the shoulder ride up
	# with the back under them instead of being scaled with it, so the head
	# and the arm keep their size.
	var swell: Vector2 = breath_swell * breath
	_pose(ribs, Vector2.ZERO, 0.0, Vector2.ONE + swell)
	_pose(neck, _swollen_offset(neck, swell), 0.0)
	var hang: float = clampf(arm / arm_straighten, 0.0, 1.0) if arm_straighten > 0.0 else 0.0
	_pose(shoulder, _swollen_offset(shoulder, swell) + Vector2(0.0, shoulder_drop * hang), 0.0)
	_pose(head, Vector2.ZERO, deg_to_rad(head_spring.step(step)) - lean * head_steadiness)
	# Turning towards the viewer slides what is nearest to them, the ear and
	# the cheek, back towards the bun; the outline stays put.
	_pose(head_turn, Vector2(sin(deg_to_rad(turn_spring.step(step))) * head_turn_depth, 0.0), 0.0)
	# Straightening turns the forearm towards the upper arm: the hand comes
	# right and down, which is a negative turn for a bone pointing down-left.
	_pose(elbow, Vector2.ZERO, deg_to_rad(-arm))
	_pose(hand, Vector2.ZERO, deg_to_rad(rag))

## 0 at rest, 1 at the top of the breath: in, out, then a pause.
func _breath_amount(phase: float) -> float:
	if phase < BREATH_INHALE_END:
		return smoothstep(0.0, 1.0, phase / BREATH_INHALE_END)
	if phase < BREATH_EXHALE_END:
		return 1.0 - smoothstep(0.0, 1.0, (phase - BREATH_INHALE_END) / (BREATH_EXHALE_END - BREATH_INHALE_END))
	return 0.0

## Where a joint resting on the ribs' back ends up when the back swells.
func _swollen_offset(bone: Bone2D, swell: Vector2) -> Vector2:
	return (bone.rest.origin - ribs.rest.origin) * swell

func _plan_waist(step: float) -> void:
	waist_wait -= step
	if waist_wait > 0.0:
		return
	waist_wait = rng.randf_range(waist_hold_seconds.x, waist_hold_seconds.y)
	# Weight goes from one side to the other, never twice the same way.
	var side: float = -1.0 if waist_spring.target > 0.0 else 1.0
	waist_spring.target = side * rng.randf_range(0.35, 1.0) * waist_lean

func _plan_head(step: float) -> void:
	head_wait -= step
	if head_wait > 0.0:
		return
	head_wait = rng.randf_range(head_hold_seconds.x, head_hold_seconds.y)
	# Turning the face side up is a positive turn: the face is left of the joint.
	var roll: float = rng.randf()
	var target: float
	if roll < look_down_chance:
		target = -rng.randf_range(0.45, 1.0) * look_down
	elif roll < look_down_chance + look_up_chance:
		target = rng.randf_range(0.4, 1.0) * look_up
	else:
		target = rng.randf_range(-1.0, 1.0) * head_settle
	var turn_roll: float = rng.randf()
	var turn: float = 0.0
	if turn_roll < turn_chance * 0.65:
		turn = rng.randf_range(0.4, 1.0) * turn_to_viewer
	elif turn_roll < turn_chance:
		turn = -rng.randf_range(0.4, 1.0) * turn_to_window
	var change: float = absf(target - head_spring.target) + absf(turn - turn_spring.target)
	if change >= BLINK_WITH_GLANCE_DEGREES and rng.randf() < BLINK_WITH_GLANCE_CHANCE:
		_start_blink()
	head_spring.target = target
	turn_spring.target = turn

func _plan_arm(step: float) -> void:
	arm_wait -= step
	if arm_wait > 0.0:
		return
	arm_hanging = !arm_hanging
	if arm_hanging:
		arm_wait = rng.randf_range(arm_hang_seconds.x, arm_hang_seconds.y)
		arm_spring.target = arm_straighten * rng.randf_range(0.75, 1.0)
		arm_spring.frequency = ARM_DROP_FREQUENCY
		arm_spring.damping = ARM_DROP_DAMPING
	else:
		arm_wait = rng.randf_range(arm_hold_seconds.x, arm_hold_seconds.y)
		arm_spring.target = 0.0
		arm_spring.frequency = ARM_LIFT_FREQUENCY
		arm_spring.damping = ARM_LIFT_DAMPING

func _blink(step: float) -> void:
	if closed_eye == null:
		return
	if blink_left > 0.0:
		blink_left -= step
		if blink_left <= 0.0:
			closed_eye.visible = false
		return
	if second_blink_in >= 0.0:
		second_blink_in -= step
		if second_blink_in < 0.0:
			_start_blink(false)
		return
	blink_wait -= step
	if blink_wait <= 0.0:
		_start_blink()

func _start_blink(may_double: bool = true) -> void:
	if closed_eye == null:
		return
	closed_eye.visible = true
	blink_left = BLINK_SECONDS
	blink_wait = rng.randf_range(blink_interval_seconds.x, blink_interval_seconds.y)
	second_blink_in = DOUBLE_BLINK_GAP_SECONDS if may_double and rng.randf() < DOUBLE_BLINK_CHANCE else -1.0

## The bone at its rest pose, moved by `offset`, turned by `angle` and scaled
## by `scale_by`, all about its own joint.
func _pose(bone: Bone2D, offset: Vector2, angle: float, scale_by: Vector2 = Vector2.ONE) -> void:
	bone.transform = bone.rest * Transform2D(angle, scale_by, 0.0, offset)
