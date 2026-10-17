extends CanvasLayer

const TRANSITION_COLOR := Color("f4f0e6")
const FADE_TO_COLOR_DURATION := 0.35
const FADE_FROM_COLOR_DURATION := 0.45
const FADE_FROM_COLOR_START_SCALE := 0.97
## The finish most scenes print on top of everything - the paper and the
## shaded edges - found by these node names.
const PAPER_OVERLAY_NAME := "PaperTextureOverlay"
const VIGNETTE_OVERLAY_NAME := "VignetteOverlay"
const PAPER_NEUTRAL_COLOR := Color(1.0, 1.0, 1.0, 1.0)

var _overlay: ColorRect
## Copies of the leaving scene's paper and vignette, laid over the fade so the
## screen keeps its finish while the scenes change underneath. They come in
## as the fade comes in and go as it goes; the arriving scene's own finish
## takes over beneath them. Both shaders write their colour outright and
## ignore modulate, so the copies are faded through their own strength.
var _paper: ColorRect
var _vignette: ColorRect
var _paper_opacity: float = 0.0
var _paper_tint: Color = PAPER_NEUTRAL_COLOR
var _vignette_intensity: float = 0.0
var _finish_alpha: float = 0.0
var _scene_base_canvas_transform := Transform2D.IDENTITY
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
	_paper = _create_finish_rect("PaperFinish")
	_vignette = _create_finish_rect("VignetteFinish")


func _create_finish_rect(node_name: String) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	add_child(rect)
	return rect


func change_scene(scene_path: String) -> void:
	if _transition_in_progress:
		return
	if _should_skip_animation():
		get_tree().change_scene_to_file(scene_path)
		return

	_transition_in_progress = true
	_set_global_top_bar_scene_transition_active(true)
	_prepare_global_top_bar_for_scene_change(scene_path)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_borrow_screen_finish(get_tree().current_scene)
	await _fade_to(1.0, FADE_TO_COLOR_DURATION)

	var change_error := get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		push_error("SceneTransition could not load '%s' (error %d)." % [scene_path, change_error])
		await _fade_to(0.0, FADE_FROM_COLOR_DURATION)
		_finish_transition()
		return

	# Let the new scene finish entering the tree while the screen is fully covered.
	await get_tree().process_frame
	await _fade_from_color_with_zoom()
	_finish_transition()


func _fade_to(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_overlay, "color:a", target_alpha, duration)
	tween.parallel().tween_method(_set_finish_alpha, _finish_alpha, target_alpha, duration)
	await tween.finished


func _fade_from_color_with_zoom() -> void:
	_scene_base_canvas_transform = get_viewport().canvas_transform
	_set_scene_zoom(FADE_FROM_COLOR_START_SCALE)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_overlay, "color:a", 0.0, FADE_FROM_COLOR_DURATION)
	tween.tween_method(_set_finish_alpha, _finish_alpha, 0.0, FADE_FROM_COLOR_DURATION)
	tween.tween_method(
		Callable(self, "_set_scene_zoom"),
		FADE_FROM_COLOR_START_SCALE,
		1.0,
		FADE_FROM_COLOR_DURATION
	)
	await tween.finished

	get_viewport().canvas_transform = _scene_base_canvas_transform


func _set_scene_zoom(scale: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var zoom_offset := viewport_size * (1.0 - scale) * 0.5
	var zoom_transform := Transform2D(
		Vector2(scale, 0.0),
		Vector2(0.0, scale),
		zoom_offset
	)
	get_viewport().canvas_transform = zoom_transform * _scene_base_canvas_transform


func _finish_transition() -> void:
	_transition_in_progress = false
	_set_finish_alpha(0.0)
	_paper.material = null
	_vignette.material = null
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_global_top_bar_scene_transition_active(false)


## Copies the leaving scene's paper and vignette materials, if it has them, so
## they outlive the scene. A scene without them leaves the fade plain.
func _borrow_screen_finish(scene: Node) -> void:
	var paper_material := _copy_overlay_material(scene, PAPER_OVERLAY_NAME)
	_paper.material = paper_material
	if paper_material != null:
		_paper_opacity = float(paper_material.get_shader_parameter("effect_opacity"))
		var tint = paper_material.get_shader_parameter("paper_color")
		_paper_tint = tint if tint is Color else PAPER_NEUTRAL_COLOR
		# A cut-out is about something on the leaving screen; the fade has
		# nothing there to keep clear.
		paper_material.set_shader_parameter("cutout_amount", 0.0)

	var vignette_material := _copy_overlay_material(scene, VIGNETTE_OVERLAY_NAME)
	_vignette.material = vignette_material
	if vignette_material != null:
		_vignette_intensity = float(vignette_material.get_shader_parameter("intensity"))
	_set_finish_alpha(0.0)


func _copy_overlay_material(scene: Node, node_name: String) -> ShaderMaterial:
	if scene == null:
		return null
	var overlay := scene.find_child(node_name, true, false) as CanvasItem
	if overlay == null or !overlay.is_visible_in_tree():
		return null
	var material := overlay.material as ShaderMaterial
	return material.duplicate() as ShaderMaterial if material != null else null


## How much of the borrowed finish shows: 0 is none, 1 is the scene's own
## strength - tint, texture and shaded edges alike.
func _set_finish_alpha(alpha: float) -> void:
	_finish_alpha = alpha
	var paper_material := _paper.material as ShaderMaterial
	if paper_material != null:
		paper_material.set_shader_parameter("effect_opacity", _paper_opacity * alpha)
		paper_material.set_shader_parameter("paper_color", PAPER_NEUTRAL_COLOR.lerp(_paper_tint, alpha))
	_paper.visible = paper_material != null and alpha > 0.0
	var vignette_material := _vignette.material as ShaderMaterial
	if vignette_material != null:
		vignette_material.set_shader_parameter("intensity", _vignette_intensity * alpha)
	_vignette.visible = vignette_material != null and alpha > 0.0


func _prepare_global_top_bar_for_scene_change(scene_path: String) -> void:
	var global_top_bar := get_node_or_null("/root/GlobalTopBar")
	if global_top_bar != null and global_top_bar.has_method("prepare_for_scene_change"):
		global_top_bar.prepare_for_scene_change(scene_path)


func _set_global_top_bar_scene_transition_active(active: bool) -> void:
	var global_top_bar := get_node_or_null("/root/GlobalTopBar")
	if global_top_bar != null and global_top_bar.has_method("set_scene_transition_active"):
		global_top_bar.set_scene_transition_active(active)


func _should_skip_animation() -> bool:
	return DisplayServer.get_name() == "headless" or GameConfig.is_dedicated_server or GameConfig.is_ai_vs_ai_batch
