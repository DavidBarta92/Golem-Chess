extends Node
class_name MusicStemCycle

## Brings one stem in now and then and takes it away again, for as long as
## this node is in the tree: the main menu's chords, which come and go rather
## than playing the whole time someone sits on the menu.
##
## Leaving the scene takes the stem away if it is up, so it does not follow
## the player into whatever comes next.

## A stem name, as in MusicStemFade.
@export var stem: String = "chords"
## How long the scene is open before the stem first comes in.
@export_range(0.0, 600.0, 1.0) var first_delay_seconds: float = 20.0
@export_range(0.0, 60.0, 0.5) var fade_in_seconds: float = 5.0
## How long it stays up once it has faded in.
@export_range(0.0, 600.0, 1.0) var hold_seconds: float = 60.0
@export_range(0.0, 60.0, 0.5) var fade_out_seconds: float = 5.0
## The quiet stretch after it has gone is picked between these two each time.
@export_range(0.0, 600.0, 1.0) var min_gap_seconds: float = 60.0
@export_range(0.0, 600.0, 1.0) var max_gap_seconds: float = 120.0
@export_range(0.0, 60.0, 0.5) var fade_out_on_exit_seconds: float = 3.0
## Off waits for the scene's own script to call start() - see
## SceneMusicCue.play_on_ready for why the Main Menu needs that.
@export var autostart: bool = true

## Timer.start() treats zero as "use wait_time", so no wait is ever shorter.
const MIN_WAIT_SECONDS: float = 0.05

var _timer: Timer
var _is_up: bool = false

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	if autostart:
		start()

func start() -> void:
	if _timer == null or !_timer.is_stopped() or _is_up:
		return
	_timer.start(maxf(first_delay_seconds, MIN_WAIT_SECONDS))

func _exit_tree() -> void:
	if _is_up:
		_is_up = false
		MusicManager.fade_stem(stem, false, fade_out_on_exit_seconds)

func _on_timer_timeout() -> void:
	if _is_up:
		_is_up = false
		MusicManager.fade_stem(stem, false, fade_out_seconds)
		var gap: float = randf_range(min_gap_seconds, maxf(min_gap_seconds, max_gap_seconds))
		_timer.start(maxf(fade_out_seconds + gap, MIN_WAIT_SECONDS))
	else:
		_is_up = true
		MusicManager.fade_stem(stem, true, fade_in_seconds)
		_timer.start(maxf(fade_in_seconds + hold_seconds, MIN_WAIT_SECONDS))
