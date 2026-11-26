extends CanvasLayer

## UiPalette.PAPER: what the screen shows while it is covered, after the
## paper finish has printed over the fade (see _sync_fade_colour).
const TRANSITION_COLOR := Color("f4f0e6")
const FADE_TO_COLOR_DURATION := 0.35
const FADE_FROM_COLOR_DURATION := 0.45
const FADE_FROM_COLOR_START_SCALE := 0.97
## The finish most scenes print on top of everything - the paper and the
## shaded edges - found by these node names.
const PAPER_OVERLAY_NAME := "PaperTextureOverlay"
const VIGNETTE_OVERLAY_NAME := "VignetteOverlay"
const PAPER_NEUTRAL_COLOR := Color(1.0, 1.0, 1.0, 1.0)
## An arriving scene settles in over its first frames - the Collection builds
## its page, a match deals and builds its board - and one of those frames can
## take half a second. The fade waits under cover until this many frames in a
## row have each taken no longer than SETTLE_FRAME_SECONDS, so it plays out
## whole instead of jumping half way through in that one frame. It waits at
## least SETTLE_MIN_SECONDS, which covers a match's own 0.1 s wait before it
## deals, and never longer than SETTLE_MAX_SECONDS, for a machine that never
## gets that quick.
const SETTLE_SHORT_FRAMES := 3
const SETTLE_FRAME_SECONDS := 0.05
const SETTLE_MIN_SECONDS := 0.15
const SETTLE_MAX_SECONDS := 1.5

var _overlay: ColorRect
## A copy of the leaving scene's vignette, laid over the fade so the screen
## keeps its shaded edges while the scenes change underneath. It comes in as
## the fade comes in and goes as it goes; the arriving scene's own vignette
## takes over beneath it. The shader writes its colour outright and ignores
## modulate, so the copy is faded through its own strength.
var _vignette: ColorRect
var _vignette_intensity: float = 0.0
var _finish_alpha: float = 0.0
## The paper is printed above the top bar (PaperTextureLayer, 1210), so it is
## already above this fade. The leaving scene's paper is swapped for a copy on
## a layer at the same height, which keeps the screen papered while the scenes
## change and then hands over to the arriving scene's paper, ramped in from
## nothing. _paper_handover 1 is all copy, 0 is all arriving paper.
var _paper_layer: CanvasLayer
var _paper: ColorRect
var _paper_opacity: float = 0.0
var _paper_tint: Color = PAPER_NEUTRAL_COLOR
var _paper_cutout: float = 0.0
var _paper_handover: float = 1.0
var _leaving_paper_overlay: CanvasItem
var _arriving_paper: ShaderMaterial
var _arriving_paper_opacity: float = 0.0
var _arriving_paper_tint: Color = PAPER_NEUTRAL_COLOR
var _scene_base_canvas_transform := Transform2D.IDENTITY
var _transition_in_progress := false
## The paths warm_up() has loaded this session.
var _warmed_up: Dictionary = {}


func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.name = "OffWhiteFade"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(TRANSITION_COLOR, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_vignette = _create_finish_rect("VignetteFinish", self)
	_paper_layer = CanvasLayer.new()
	_paper_layer.name = "PaperFinishLayer"
	add_child(_paper_layer)
	_paper = _create_finish_rect("PaperFinish", _paper_layer)


func _create_finish_rect(node_name: String, parent: Node) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	parent.add_child(rect)
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

	# The scene loads on the main thread, under the paper. Not on a thread: in
	# Godot 4.7.2 a threaded load of this game's scenes now and then never
	# finishes (Docs/SceneTransition/SCENE_TRANSITION.md).
	get_tree().node_added.connect(_catch_arriving_paper)
	var change_error := get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		push_error("SceneTransition could not load '%s' (error %d)." % [scene_path, change_error])
		await _fade_to(0.0, FADE_FROM_COLOR_DURATION)
		_finish_transition()
		return

	# The leaving screen is gone, and with it what its cut-out kept clear.
	_paper_cutout = 0.0
	await _wait_for_arrival_to_settle()
	await _fade_from_color_with_zoom()
	_finish_transition()


## Keeps the screen covered while the arriving scene settles in (SETTLE_*).
func _wait_for_arrival_to_settle() -> void:
	var tree := get_tree()
	var started_msec := Time.get_ticks_msec()
	# The new scene enters the tree at the end of the frame it was changed in.
	while tree.current_scene == null and _seconds_since(started_msec) < SETTLE_MAX_SECONDS:
		await tree.process_frame
	var arrived_msec := Time.get_ticks_msec()
	var short_frames := 0
	var last_frame_usec := Time.get_ticks_usec()
	while short_frames < SETTLE_SHORT_FRAMES or _seconds_since(arrived_msec) < SETTLE_MIN_SECONDS:
		if _seconds_since(arrived_msec) >= SETTLE_MAX_SECONDS:
			return
		await tree.process_frame
		var frame_usec := Time.get_ticks_usec()
		var frame_seconds := float(frame_usec - last_frame_usec) / 1000000.0
		short_frames = short_frames + 1 if frame_seconds <= SETTLE_FRAME_SECONDS else 0
		last_frame_usec = frame_usec


func _seconds_since(msec: int) -> float:
	return float(Time.get_ticks_msec() - msec) / 1000.0


## Loads these scenes (or scripts) once a session and lets them go again. What
## stays is their compiled scripts, which are most of what the first visit to a
## screen waits for. The main menu calls this first thing, and at launch that
## is still under Godot's boot splash: the wait shows as a longer splash rather
## than as a first match or Collection that keeps the paper up. Later calls
## cost nothing. It blocks, on the main thread - not on a thread
## (Docs/SceneTransition/SCENE_TRANSITION.md).
func warm_up(paths: Array[String]) -> void:
	if _should_skip_animation():
		return
	var started_msec := Time.get_ticks_msec()
	var loaded := 0
	for path in paths:
		if _warmed_up.has(path):
			continue
		_warmed_up[path] = true
		if ResourceLoader.exists(path) and !ResourceLoader.has_cached(path):
			load(path)
			loaded += 1
	if loaded > 0:
		DebugLog.info("SceneTransition warmed up %d paths in %d ms" % [loaded, Time.get_ticks_msec() - started_msec])


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
	tween.tween_method(_set_paper_handover, _paper_handover, 0.0, FADE_FROM_COLOR_DURATION)
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
	if get_tree().node_added.is_connected(_catch_arriving_paper):
		get_tree().node_added.disconnect(_catch_arriving_paper)
	_set_finish_alpha(0.0)
	_set_paper_handover(0.0)
	if _arriving_paper != null:
		_arriving_paper.set_shader_parameter("effect_opacity", _arriving_paper_opacity)
		_arriving_paper.set_shader_parameter("paper_color", _arriving_paper_tint)
	# Still around only when the scene change failed.
	if is_instance_valid(_leaving_paper_overlay):
		_leaving_paper_overlay.visible = true
	_leaving_paper_overlay = null
	_arriving_paper = null
	_paper.material = null
	_vignette.material = null
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_global_top_bar_scene_transition_active(false)


## Swaps the leaving scene's paper for a copy that outlives the scene, and
## copies its vignette, if it has them. A scene without them leaves the fade
## plain. The copy shows the same paper the scene did, so the swap is unseen.
func _borrow_screen_finish(scene: Node) -> void:
	var paper_overlay := _find_overlay(scene, PAPER_OVERLAY_NAME)
	var paper_material := _copy_overlay_material(paper_overlay)
	_paper.material = paper_material
	if paper_material != null:
		_paper_opacity = float(paper_material.get_shader_parameter("effect_opacity"))
		var tint = paper_material.get_shader_parameter("paper_color")
		_paper_tint = tint if tint is Color else PAPER_NEUTRAL_COLOR
		var cutout = paper_material.get_shader_parameter("cutout_amount")
		_paper_cutout = float(cutout) if cutout != null else 0.0
		var paper_layer := paper_overlay.get_parent() as CanvasLayer
		_paper_layer.layer = paper_layer.layer if paper_layer != null else layer
		_leaving_paper_overlay = paper_overlay
		paper_overlay.visible = false
	_set_paper_handover(1.0)

	var vignette_material := _copy_overlay_material(_find_overlay(scene, VIGNETTE_OVERLAY_NAME))
	_vignette.material = vignette_material
	if vignette_material != null:
		_vignette_intensity = float(vignette_material.get_shader_parameter("intensity"))
	_set_finish_alpha(0.0)


func _find_overlay(scene: Node, node_name: String) -> CanvasItem:
	if scene == null:
		return null
	var overlay := scene.find_child(node_name, true, false) as CanvasItem
	if overlay == null or !overlay.is_visible_in_tree():
		return null
	return overlay


func _copy_overlay_material(overlay: CanvasItem) -> ShaderMaterial:
	if overlay == null:
		return null
	var material := overlay.material as ShaderMaterial
	return material.duplicate() as ShaderMaterial if material != null else null


## Catches the arriving scene's paper as it enters the tree, before it is first
## drawn, and holds it at the strength the handover is at - nothing, at first.
func _catch_arriving_paper(node: Node) -> void:
	if _arriving_paper != null or node.name != PAPER_OVERLAY_NAME or !(node is CanvasItem):
		return
	var material := (node as CanvasItem).material as ShaderMaterial
	if material == null:
		return
	_arriving_paper = material
	_arriving_paper_opacity = float(material.get_shader_parameter("effect_opacity"))
	var tint = material.get_shader_parameter("paper_color")
	_arriving_paper_tint = tint if tint is Color else PAPER_NEUTRAL_COLOR
	_set_paper_handover(_paper_handover)


## How much of the borrowed vignette shows: 0 is none, 1 is the scene's own
## strength. The paper copy's cut-out closes as the fade comes in, since the
## fade covers what it kept clear.
func _set_finish_alpha(alpha: float) -> void:
	_finish_alpha = alpha
	var paper_material := _paper.material as ShaderMaterial
	if paper_material != null:
		paper_material.set_shader_parameter("cutout_amount", _paper_cutout * (1.0 - alpha))
	var vignette_material := _vignette.material as ShaderMaterial
	if vignette_material != null:
		vignette_material.set_shader_parameter("intensity", _vignette_intensity * alpha)
	_vignette.visible = vignette_material != null and alpha > 0.0


func _set_paper_handover(value: float) -> void:
	_paper_handover = value
	var paper_material := _paper.material as ShaderMaterial
	if paper_material != null:
		_set_paper_strength(paper_material, _paper_opacity, _paper_tint, value)
	_paper.visible = paper_material != null and value > 0.0
	if _arriving_paper != null:
		_set_paper_strength(_arriving_paper, _arriving_paper_opacity, _arriving_paper_tint, 1.0 - value)
	_sync_fade_colour()


## The paper finish multiplies the screen by its tint, and the menus' tint is
## the paper colour itself (their art is white): a fade in the paper colour
## came out a shade darker than the menus. The fade is the colour that, once
## tinted, gives the paper colour - white under a paper tint, the paper colour
## where a scene has no tint.
func _sync_fade_colour() -> void:
	var tint := Color(1.0, 1.0, 1.0)
	if _paper.material != null:
		tint *= PAPER_NEUTRAL_COLOR.lerp(_paper_tint, _paper_handover)
	if _arriving_paper != null:
		tint *= PAPER_NEUTRAL_COLOR.lerp(_arriving_paper_tint, 1.0 - _paper_handover)
	var fade := Color(
		minf(TRANSITION_COLOR.r / maxf(tint.r, 0.001), 1.0),
		minf(TRANSITION_COLOR.g / maxf(tint.g, 0.001), 1.0),
		minf(TRANSITION_COLOR.b / maxf(tint.b, 0.001), 1.0),
		_overlay.color.a
	)
	_overlay.color = fade


## Both paper shaders write their colour outright and ignore modulate, so a
## paper is faded through its own opacity and tint.
func _set_paper_strength(material: ShaderMaterial, opacity: float, tint: Color, strength: float) -> void:
	material.set_shader_parameter("effect_opacity", opacity * strength)
	material.set_shader_parameter("paper_color", PAPER_NEUTRAL_COLOR.lerp(tint, strength))


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
