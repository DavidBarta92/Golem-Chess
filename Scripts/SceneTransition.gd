extends CanvasLayer

const TRANSITION_COLOR := Color("f4f0e6")
const FADE_TO_COLOR_DURATION := 0.35
const FADE_FROM_COLOR_DURATION := 0.45

var _overlay: ColorRect
var _transition_in_progress := false


func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.name = "OffWhiteFade"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(TRANSITION_COLOR, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


func change_scene(scene_path: String) -> void:
	if _transition_in_progress:
		return
	if _should_skip_animation():
		get_tree().change_scene_to_file(scene_path)
		return

	_transition_in_progress = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, FADE_TO_COLOR_DURATION)

	var change_error := get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		push_error("SceneTransition could not load '%s' (error %d)." % [scene_path, change_error])
		await _fade_to(0.0, FADE_FROM_COLOR_DURATION)
		_finish_transition()
		return

	# Let the new scene finish entering the tree while the screen is fully covered.
	await get_tree().process_frame
	await _fade_to(0.0, FADE_FROM_COLOR_DURATION)
	_finish_transition()


func _fade_to(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_overlay, "color:a", target_alpha, duration)
	await tween.finished


func _finish_transition() -> void:
	_transition_in_progress = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _should_skip_animation() -> bool:
	return DisplayServer.get_name() == "headless" or GameConfig.is_dedicated_server or GameConfig.is_ai_vs_ai_batch
