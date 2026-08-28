extends ArtworkCroppedButton

## Hover: pop animation (inherited).
## Click: slides from slide_start_offset to slide_end_offset (both relative
## to the button's natural resting position, tweak in the Inspector),
## easing in from a standstill up to full speed. The scene change starts
## scene_change_lead_distance pixels before the slide actually reaches the
## end point, so the fade overlaps the tail end of the movement.

@export var slide_start_offset: Vector2 = Vector2.ZERO
@export var slide_end_offset: Vector2 = Vector2(0.0, -40.0)
@export var slide_duration: float = 0.5
@export var scene_change_lead_distance: float = 25.0

const TARGET_SCENE_PATH: String = "res://Scenes/QuickPlayMenu.tscn"

var _slide_tween: Tween
var _slide_start_pos: Vector2
var _slide_end_pos: Vector2
var _scene_change_triggered: bool = false

func _on_pressed() -> void:
	if _slide_tween != null and _slide_tween.is_valid():
		return
	AmbienceManager.set_muffled(false, 2.0)
	_scene_change_triggered = false
	_slide_start_pos = _base_position + slide_start_offset
	_slide_end_pos = _base_position + slide_end_offset
	position = _slide_start_pos
	_slide_tween = create_tween()
	_slide_tween.tween_method(_on_slide_step, 0.0, 1.0, slide_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_slide_step(t: float) -> void:
	position = _slide_start_pos.lerp(_slide_end_pos, t)
	if !_scene_change_triggered and position.distance_to(_slide_end_pos) <= scene_change_lead_distance:
		_scene_change_triggered = true
		_trigger_play_scene_change()

func _trigger_play_scene_change() -> void:
	if StoryManager.continue_story_if_ready():
		return
	SceneTransition.change_scene(TARGET_SCENE_PATH)
