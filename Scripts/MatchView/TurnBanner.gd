extends Label
class_name TurnBanner

## The words in the middle of the screen when the turn passes. They come up,
## stay a moment and go by themselves. They take no clicks and nothing waits on
## them, so the match carries on underneath.

const FADE_IN_SECONDS: float = 0.15
const HOLD_SECONDS: float = 1.4
const FADE_OUT_SECONDS: float = 0.35

var _tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# A long player name wraps instead of running off both sides of the screen.
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

## self_modulate, because the match intro fades every part of the interface by
## its modulate and would fight this over the same value.
func announce(words: String) -> void:
	_kill_tween()
	text = words
	self_modulate.a = 0.0
	visible = true
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate:a", 1.0, FADE_IN_SECONDS)
	_tween.tween_interval(HOLD_SECONDS)
	_tween.tween_property(self, "self_modulate:a", 0.0, FADE_OUT_SECONDS)
	_tween.tween_callback(hide)

func dismiss() -> void:
	_kill_tween()
	visible = false

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
