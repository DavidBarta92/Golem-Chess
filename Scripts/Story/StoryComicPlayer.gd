extends Control
class_name StoryComicPlayer

## Plays a run of comic pages and hands control back to StoryManager.
##
## Deliberately thin: it knows about clicks, page order and fades, and nothing
## at all about what a page looks like. Layout lives entirely in the page
## scenes, so a new page never needs a change here.

const PAGE_FADE_OUT_SECONDS: float = 0.35
const PAGE_FADE_IN_SECONDS: float = 0.4
const INPUT_LOCKOUT_SECONDS: float = 0.25

@onready var page_host: Control = $PageHost
@onready var fade_overlay: ColorRect = $FadeLayer/FadeOverlay

## Page scene paths. Each page is loaded only when it comes up, behind the
## black fade, so a run of pages never holds more than one page's art.
var _page_paths: Array[String] = []
var _on_end: int = StoryManager.ComicEnd.COMPLETE_NODE
var _page_index: int = -1
var _current_page: ComicPageView
var _input_locked_until_msec: int = 0
var _is_leaving: bool = false

func _ready() -> void:
	var request: Dictionary = StoryManager.consume_comic_request()
	_page_paths.assign(request.get("pages", []))
	_on_end = int(request.get("on_end", StoryManager.ComicEnd.COMPLETE_NODE))

	fade_overlay.color.a = 1.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _page_paths.is_empty():
		push_warning("StoryComicPlayer opened with no pages; returning to the story flow.")
		call_deferred("_leave")
		return

	_show_next_page()

func _unhandled_input(event: InputEvent) -> void:
	if _is_leaving or _current_page == null:
		return
	if Time.get_ticks_msec() < _input_locked_until_msec:
		return
	if !_is_advance_event(event):
		return

	get_viewport().set_input_as_handled()
	_current_page.advance()

func _is_advance_event(event: InputEvent) -> bool:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null:
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("ui_accept"):
		return true
	var key_event := event as InputEventKey
	return key_event != null and key_event.pressed and !key_event.echo and key_event.keycode == KEY_SPACE

func _show_next_page() -> void:
	_page_index += 1
	if _page_index >= _page_paths.size():
		_leave()
		return

	var page_path: String = _page_paths[_page_index]
	var page_scene: PackedScene = load(page_path) as PackedScene
	if page_scene == null:
		push_error("Comic page '%s' could not be loaded; skipping it." % page_path)
		_show_next_page()
		return

	var page_instance: Node = page_scene.instantiate()
	_current_page = page_instance as ComicPageView
	if _current_page == null:
		push_error("Comic page '%s' does not use a ComicPageView root; skipping it." % page_path)
		page_instance.queue_free()
		_show_next_page()
		return

	_current_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_host.add_child(_current_page)
	_current_page.page_finished.connect(_on_page_finished, CONNECT_ONE_SHOT)

	await _fade(0.0, PAGE_FADE_IN_SECONDS)
	if !is_instance_valid(_current_page):
		return
	_lock_input_briefly()
	_current_page.begin()

func _on_page_finished() -> void:
	if _is_leaving:
		return
	await _fade(1.0, PAGE_FADE_OUT_SECONDS)
	_clear_current_page()
	_show_next_page()

func _clear_current_page() -> void:
	if _current_page == null:
		return
	if is_instance_valid(_current_page):
		_current_page.end_page()
		_current_page.queue_free()
	_current_page = null

func _leave() -> void:
	if _is_leaving:
		return
	_is_leaving = true
	_clear_current_page()

	# What happens next was decided by whoever queued these pages: a comic
	# that *is* the current node completes it, a defeat comic restarts the
	# fight, a one-off just goes back to the hub.
	StoryManager.on_comic_finished(_on_end)

func _lock_input_briefly() -> void:
	# Swallows the click that started the scene, so a fast double click cannot
	# blow through the first panel before it is even visible.
	_input_locked_until_msec = Time.get_ticks_msec() + int(INPUT_LOCKOUT_SECONDS * 1000.0)

func _fade(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_overlay, "color:a", target_alpha, duration)
	await tween.finished
