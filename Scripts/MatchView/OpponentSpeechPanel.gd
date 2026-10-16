extends Node
class_name OpponentSpeechPanel

## When the opponent is on screen in a match, and how they leave.
##
## In a match the opponent is not a permanent fixture of the interface: they
## appear because they have something to say, and they go once it has been
## read. The panel they speak through is a `DialoguePanel`, shared with the
## comics and the tutorial, so none of this belongs there - it lives here and
## drives that panel from outside.
##
## One line's life:
##
##   1. the frame draws itself, the face fades in behind it, then the words
##   2. the words hold for `line_seconds`, counted down by the dial beneath
##      them; pointing at the face or the words stops that clock, so a line
##      being read never goes out from under the pointer
##   3. the face and the words fade out together over `fade_seconds`
##
## A second line arriving mid-hold does not restart any of that. Only the words
## leave and come back - the speaker has not gone anywhere.

signal finished

@export_group("Timing")
## How long a line stays up on its own. The clock stops while the pointer is
## on the line, so this is how long it gets from a player who is not looking.
@export_range(1.0, 30.0, 0.5) var line_seconds: float = 15.0
## Every disappearance, of the words alone or of the whole panel.
@export_range(0.0, 3.0, 0.05) var fade_seconds: float = 1.0
@export_range(0.0, 4.0, 0.05) var frame_reveal_seconds: float = 1.0
## The beat between the frame landing and the face behind it.
@export_range(0.0, 2.0, 0.05) var portrait_delay: float = 0.2
@export_range(0.0, 3.0, 0.05) var portrait_fade_seconds: float = 0.5
## The beat between the face and the first words.
@export_range(0.0, 2.0, 0.05) var speech_delay: float = 0.25
@export_range(0.0, 3.0, 0.05) var speech_fade_seconds: float = 0.35

var _panel: DialoguePanel
var _countdown: SpeechCountdown
## Null until the frame drawing exists; every step that would draw it is then
## skipped and the face opens the sequence instead.
var _frame: PortraitFrameLine

## Bumped by every speak() and dismiss(), so a hold or a fade that belongs to a
## line the player has already moved past knows to stop.
var _token: int = 0
var _showing: bool = false
var _identity_up: bool = false
var _hold_left: float = 0.0
var _holding: bool = false

func setup(panel: DialoguePanel) -> void:
	_panel = panel
	if _panel == null or !is_instance_valid(_panel):
		return
	_build_frame()
	_build_countdown()
	# The text box is built to stretch, which parks the dial at the bottom of
	# the panel a long way under a short line. Here it should sit just beneath
	# the words it is counting down.
	var text_panel: Control = _panel.get_text_panel()
	if text_panel != null:
		text_panel.size_flags_vertical = Control.SIZE_FILL
	_panel.set_interactive(false)
	_panel.visible = false
	_identity_up = false
	_showing = false
	set_process(true)

func is_showing() -> bool:
	return _showing

# --- Saying something --------------------------------------------------------

func speak(speaker: String, text: String, portrait) -> void:
	if _panel == null or !is_instance_valid(_panel) or text.strip_edges().is_empty():
		return

	_token += 1
	var token: int = _token
	_showing = true
	_holding = false

	if _identity_up:
		await _replace_words(token, speaker, text)
	else:
		await _arrive(token, speaker, text, portrait)
	if token != _token or !is_inside_tree():
		return

	_hold_left = line_seconds
	_holding = true

## Everything arrives: the frame draws, the face follows it, the words follow
## the face.
func _arrive(token: int, speaker: String, text: String, portrait) -> void:
	_panel.visible = true
	_panel.show_line(speaker, text, portrait, false)
	_panel.set_interactive(false)
	_set_identity_alpha(0.0)
	_set_frame_alpha(1.0)
	_panel.set_speech_alpha(0.0)
	_countdown.set_remaining(1.0)

	await _draw_frame(token)
	if token != _token:
		return

	await _wait(portrait_delay, token)
	if token != _token:
		return
	_fade(_set_identity_alpha, 0.0, 1.0, portrait_fade_seconds)
	_identity_up = true

	await _wait(portrait_fade_seconds + speech_delay, token)
	if token != _token:
		return
	_fade(_panel.set_speech_alpha, 0.0, 1.0, speech_fade_seconds)

## The speaker is already here: only their words change.
func _replace_words(token: int, speaker: String, text: String) -> void:
	_fade(_panel.set_speech_alpha, 1.0, 0.0, fade_seconds)
	await _wait(fade_seconds, token)
	if token != _token:
		return
	_panel.show_line(speaker, text, null, false, true)
	_panel.set_interactive(false)
	_panel.set_speech_alpha(0.0)
	_countdown.set_remaining(1.0)
	_fade(_panel.set_speech_alpha, 0.0, 1.0, speech_fade_seconds)

# --- Going away --------------------------------------------------------------

## Fades the whole thing out, whether the line ran its course or the player
## waved it away.
func dismiss() -> void:
	if !_showing or _panel == null or !is_instance_valid(_panel):
		return
	_token += 1
	var token: int = _token
	_holding = false
	_showing = false

	_fade(_set_identity_alpha, _panel_identity_alpha(), 0.0, fade_seconds)
	_fade(_set_frame_alpha, 1.0, 0.0, fade_seconds)
	_fade(_panel.set_speech_alpha, _panel_speech_alpha(), 0.0, fade_seconds)
	await _wait(fade_seconds, token)
	if token != _token:
		return
	_identity_up = false
	_panel.visible = false
	_reset_frame()
	finished.emit()

# --- The hold and the dial ---------------------------------------------------

func _process(delta: float) -> void:
	if !_holding or _panel == null or !is_instance_valid(_panel):
		return

	# Pointing at a line is as good as saying you are still reading it, so the
	# clock stops rather than runs out under the pointer. Move away and it
	# starts again where it left off.
	if _pointer_is_on_the_line():
		return

	_hold_left = maxf(_hold_left - delta, 0.0)
	_countdown.set_remaining(_hold_left / maxf(line_seconds, 0.001))

	if _hold_left <= 0.0:
		_holding = false
		dismiss()

## True while the pointer is over the face or the words. Read from the mouse
## position rather than from mouse_entered, because the panel is set to let
## every click through to the board underneath it - it cannot be told when the
## pointer arrives if it never receives the event.
func _pointer_is_on_the_line() -> bool:
	var mouse: Vector2 = _panel.get_global_mouse_position()
	for part: Control in [_panel.get_portrait_frame(), _panel.get_text_panel()]:
		if part != null and is_instance_valid(part) and part.get_global_rect().has_point(mouse):
			return true
	return false

# --- The frame ---------------------------------------------------------------

func _build_frame() -> void:
	_frame = PortraitFrameLine.attach(_panel, frame_reveal_seconds)

func _draw_frame(token: int) -> void:
	if _frame == null:
		return
	_frame.draw()
	await _wait(_frame.get_draw_duration(), token)

## The speaker's name and face. The drawn frame keeps its own alpha, because
## it has to be visible while they are not: it draws itself first, and they
## fade in behind it.
func _set_identity_alpha(alpha: float) -> void:
	_panel.set_identity_alpha(alpha)

func _set_frame_alpha(alpha: float) -> void:
	if _frame != null:
		_frame.set_line_alpha(alpha)

func _reset_frame() -> void:
	if _frame != null:
		_frame.reset()

# --- Odds and ends -----------------------------------------------------------

func _build_countdown() -> void:
	var row: Control = _panel.get_button_row()
	if row == null:
		return
	_countdown = SpeechCountdown.new()
	_countdown.name = "SpeechCountdown"
	row.add_child(_countdown)

func _fade(setter: Callable, from_alpha: float, to_alpha: float, seconds: float) -> void:
	if seconds <= 0.0:
		setter.call(to_alpha)
		return
	setter.call(from_alpha)
	var tween := create_tween()
	tween.tween_method(setter, from_alpha, to_alpha, seconds)

func _wait(seconds: float, token: int) -> void:
	if seconds <= 0.0:
		return
	await get_tree().create_timer(seconds).timeout
	if token != _token:
		return

func _panel_identity_alpha() -> float:
	var frame: Control = _panel.get_portrait_frame()
	return frame.modulate.a if frame != null else 1.0

func _panel_speech_alpha() -> float:
	var text_panel: Control = _panel.get_text_panel()
	return text_panel.modulate.a if text_panel != null else 1.0
