extends CanvasLayer
class_name TutorialOutro

## Grandpa's last word once the tutorial game is won: the paper comes back
## over the board, he asks whether the player is ready for a real game, and
## the answer button takes the story on to it.
##
## The picture that goes with it is still to be drawn; when it is, it belongs
## in Root, between the paper and the dialogue.

signal answered

@export var line_key: String = "TUTORIAL_OUTRO_1"
@export var answer_key: String = "TUTORIAL_OUTRO_YES"
@export_range(0.0, 5.0, 0.05) var fade_in_seconds: float = 1.0
@export_range(0.0, 5.0, 0.05) var line_delay: float = 0.4

@onready var _root: Control = $Root
@onready var _dialogue: DialoguePanel = $Root/DialoguePanel

var _speaker_name: String = ""

func _ready() -> void:
	visible = false
	_root.modulate.a = 0.0
	# Dressed like the tutorial's own panel: name and words, no face, centred,
	# printed on the room's paper.
	_dialogue.set_portrait_enabled(false)
	_dialogue.centre_on_screen_middle()
	_dialogue.modulate = MatchBackgroundController.PAPER_TINT
	_dialogue.visible = false

## Fades in over whatever is on screen and asks. Returns immediately; listen
## to `answered`.
func play(speaker_name: String) -> void:
	_speaker_name = speaker_name
	visible = true
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, maxf(0.05, fade_in_seconds))
	tween.tween_interval(line_delay)
	tween.tween_callback(_ask)

## Only listened to from here on, so nothing answers a question not yet asked.
func _ask() -> void:
	_dialogue.set_continue_text(tr(answer_key))
	_dialogue.continue_requested.connect(_on_answered, CONNECT_ONE_SHOT)
	_dialogue.show_line(_speaker_name, tr(line_key), null, true)

func _on_answered() -> void:
	answered.emit()
