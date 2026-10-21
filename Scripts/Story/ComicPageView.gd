@tool
extends Control
class_name ComicPageView

## One full-screen comic page: a hand-arranged set of ComicPanelView boxes
## that reveal one click at a time.
##
## Make a page by creating an inherited scene of Scenes/Comic/ComicPage.tscn
## under Story/Comic/, then dropping ComicPanel instances into it and placing
## them. The page reads its panels straight out of the scene tree in top-to-
## bottom order, so reordering panels in the Scene dock reorders the reveal -
## there is no separate list to keep in sync.
##
## Panels marked "reveal with previous" join the group above them, which is
## how a beat that needs two boxes at once is authored.
##
## A panel can also be set to make way for a later one: `hide_when_revealed`
## points at the panel whose drawing sends this one away, and the page fades it
## out while that panel draws.
##
## A panel can also carry dialogue - one line or several in a row - and say
## where on the page it should sit. Text appears as its panel starts drawing,
## and a click is the only control: it snaps whatever is mid-animation to its
## end, then moves on.
##
## Two dialogue boxes take turns, because the outgoing text fades over a second
## while the next panel is already drawing its own line somewhere else on the
## page - one box cannot be in both states at once. When such a panel finishes
## drawing, the page shows it in the same dialogue panel the match uses - minus
## the portrait - and then waits for the page's own Continue button rather than
## a click anywhere, so the player cannot skip past unread text.

signal panel_group_revealed(group_index: int)
signal page_finished

## What the ambience bed does while this page is on screen. The match muffles
## it and does not always restore it, so a page that wants the plain street
## noise has to say so.
enum AmbienceMode { UNCHANGED, OPEN, MUFFLED }

## What the music bed does. A page that silences it puts it back on the way
## out, so the scene after the comic is not left mute.
enum MusicMode { UNCHANGED, PLAYING, SILENT }

## Played once when the page appears (an SFXManager group name).
@export var sfx_on_page_start: String = ""
@export var ambience_mode: AmbienceMode = AmbienceMode.OPEN
@export var music_mode: MusicMode = MusicMode.UNCHANGED
@export_range(0.0, 10.0, 0.1) var ambience_fade_seconds: float = 1.2
@export_range(0.0, 10.0, 0.1) var music_fade_seconds: float = 1.0
## Played as the page opens, after ambience_mode has been applied, so a cue
## that changes the ambience has the last word. Optional.
@export var music_cue_on_start: MusicCue
## Played as the page hands control back - on the click after the last panel,
## or on the end button of a page that has one. Optional.
@export var music_cue_on_finish: MusicCue
## How long a line takes to fade away once its panel's turn is over.
@export_range(0.0, 5.0, 0.05) var dialogue_fade_out_seconds: float = 1.0

@export_group("Layout")
## The coordinate space the page is authored in. Everything that is not a panel
## - the dialogue box, the Continue button - lives inside a frame of this size
## that is scaled and centred exactly the way the artwork is, so text sits in a
## fixed spot on the picture however the window is resized.
@export var design_size: Vector2 = Vector2(1280.0, 720.0)
## Seconds before the page advances on its own. 0 means "wait for a click",
## which is the normal case.
@export_range(0.0, 20.0, 0.1) var auto_advance_seconds: float = 0.0
## Extra beat after the final panel before the page hands control back, so the
## last drawing is not cut off by the scene change.
@export_range(0.0, 5.0, 0.05) var end_hold_seconds: float = 0.6

@export_group("Ending")
## Seconds after the last panel before a Continue button appears at the foot of
## the page, which is then the only way on. Negative ends the page the usual
## way - on the click after the last panel - which is what every page but a
## closing title card wants.
@export_range(-1.0, 20.0, 0.1) var end_button_delay_seconds: float = -1.0
@export var end_button_text: String = "Continue"
@export_range(0.0, 5.0, 0.05) var end_button_fade_seconds: float = 0.6

## A line set under the last drawing as the page closes - a credit beneath a
## title card. It arrives before the button does, so the card is complete for a
## moment before the player is asked to move on. Empty for no line.
@export var end_byline_text: String = ""
## Where it sits in the page's design space. Full width, with the text centred
## in it, so the line stays put whatever it says and however long it gets in
## another language.
@export var end_byline_rect: Rect2 = Rect2(0.0, 402.0, 1280.0, 36.0)
## Kept close to the button's own size: large enough to read, small enough that
## it does not argue with the title above it.
## The buttons are set at 15; this sits a shade above them, which is as large
## as it can be without arguing with the title.
@export_range(8, 64, 1) var end_byline_font_size: int = 17
## The buttons' own face, so the credit reads as part of the interface rather
## than as part of the drawing.
@export var end_byline_font: Font = preload("res://Fonts/ElmsSans-ExtraBold.ttf")
@export var end_byline_color: Color = Color(0.33, 0.32, 0.36, 1.0)
@export_range(0.0, 5.0, 0.05) var end_byline_fade_seconds: float = 1.0

@export_group("Idle hint")
## How long a finished page waits for a click before it offers a hand. The
## clock only runs while the page is idle - nothing drawing, nothing typing -
## and any click puts it back to zero.
@export_range(0.0, 60.0, 0.5) var idle_hint_seconds: float = 15.0
@export_range(0.0, 5.0, 0.05) var idle_hint_fade_seconds: float = 1.0
@export var idle_hint_texture: Texture2D = preload("res://Assets/left-click.png")
## Where it sits in the drawing's bottom right corner, and how big.
@export var idle_hint_size: Vector2 = Vector2(72.0, 72.0)
@export var idle_hint_margin: Vector2 = Vector2(28.0, 28.0)

var _panel_groups: Array = []
var _current_group_index: int = -1
var _is_group_revealing: bool = false
var _is_finished: bool = false
var _pending_group_panels: int = 0
var _auto_advance_timer: SceneTreeTimer
var _art_frame: Control
var _idle_hint: TextureRect
var _idle_elapsed: float = 0.0
var _idle_hint_shown: bool = false
var _idle_hint_tween: Tween
var _dialogue_panel: DialoguePanel
var _dialogue_slots: Array[DialoguePanel] = []
var _slot_fade_tweens: Array[Tween] = []
var _active_slot: int = -1
var _dialogue_queue: Array[ComicDialogueLine] = []
var _dialogue_index: int = -1
var _dialogue_base_rect: Rect2 = Rect2()
var _dialogue_rect: Rect2 = Rect2()
var _music_silenced_by_page: bool = false
var _fading_panels: Array[ComicPanelView] = []
var _end_button: Button
var _end_byline: Label
var _input_locked: bool = false
var _panel_advance_timer: SceneTreeTimer

func _ready() -> void:
	_art_frame = get_node_or_null("ArtFrame") as Control
	for slot_name in ["DialogueA", "DialogueB"]:
		var slot := get_node_or_null("ArtFrame/" + slot_name) as DialoguePanel
		if slot != null:
			_dialogue_slots.append(slot)
	_slot_fade_tweens.resize(_dialogue_slots.size())
	_dialogue_panel = _dialogue_slots[0] if !_dialogue_slots.is_empty() else null
	_build_idle_hint()
	set_process(true)
	_update_art_frame()
	if !resized.is_connected(_update_art_frame):
		resized.connect(_update_art_frame)
	var viewport := get_viewport()
	if viewport != null and !viewport.size_changed.is_connected(_update_art_frame):
		viewport.size_changed.connect(_update_art_frame)
	if Engine.is_editor_hint():
		return

	for index in range(_dialogue_slots.size()):
		var slot: DialoguePanel = _dialogue_slots[index]
		var root := slot.get_node_or_null("DialogueRoot") as Control
		if root != null and index == 0:
			# Where the box was placed in the editor, for panels that do not
			# name a spot of their own.
			_dialogue_base_rect = Rect2(root.position, root.size)
		slot.set_portrait_enabled(false)
		# A click anywhere drives the page; the box offers no button of its own.
		slot.set_button_row_enabled(false)
		slot.visible = false
		slot.modulate.a = 1.0

	_collect_panel_groups()
	for panel in get_panels():
		panel.reset_panel()

## Maps the authoring frame onto the rect the artwork actually occupies: the
## design size, scaled to fit and centred, which is what the panels' textures
## do with KEEP_ASPECT_CENTERED. At the project's base window the scale is 1,
## so the page looks exactly as authored.
## A page that has been read waits, and then shows the player what to do: the
## click icon drawn into the corner of the picture, faded up and given a nudge
## so the eye catches it.
##
## The clock runs here rather than off a timer because "idle" is the whole
## condition - nothing drawing, nothing typing, not finished - and that is
## easier to read once, every frame, than to arm and cancel at each of the
## half dozen places the page moves on.
func _process(delta: float) -> void:
	if _idle_hint == null or _is_finished or idle_hint_seconds <= 0.0:
		return
	if _is_group_revealing or (_dialogue_panel != null and _dialogue_panel.is_typing):
		_idle_elapsed = 0.0
		return
	if _idle_hint_shown:
		return
	_idle_elapsed += delta
	if _idle_elapsed >= idle_hint_seconds:
		_show_idle_hint()

func _build_idle_hint() -> void:
	if _art_frame == null or idle_hint_texture == null:
		return
	_idle_hint = TextureRect.new()
	_idle_hint.name = "IdleHint"
	_idle_hint.texture = idle_hint_texture
	_idle_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_idle_hint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_idle_hint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_idle_hint.size = idle_hint_size
	_idle_hint.position = design_size - idle_hint_size - idle_hint_margin
	_idle_hint.pivot_offset = idle_hint_size * 0.5
	_idle_hint.modulate.a = 0.0
	_idle_hint.visible = false
	_art_frame.add_child(_idle_hint)

func _show_idle_hint() -> void:
	_idle_hint_shown = true
	_kill_idle_hint_tween()
	_idle_hint.visible = true
	_idle_hint.modulate.a = 0.0
	_idle_hint.rotation_degrees = 0.0
	_idle_hint_tween = create_tween()
	_idle_hint_tween.tween_property(_idle_hint, "modulate:a", 1.0, idle_hint_fade_seconds)
	# Once it is all the way up, a single rock about its middle. Arriving
	# quietly and then moving is what makes it read as an instruction rather
	# than as part of the drawing.
	_idle_hint_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_hint_tween.tween_property(_idle_hint, "rotation_degrees", -9.0, 0.12)
	_idle_hint_tween.tween_property(_idle_hint, "rotation_degrees", 7.0, 0.16)
	_idle_hint_tween.tween_property(_idle_hint, "rotation_degrees", -3.0, 0.12)
	_idle_hint_tween.tween_property(_idle_hint, "rotation_degrees", 0.0, 0.1)

## Any click puts the clock back to zero and takes the hint away again.
func _reset_idle_hint() -> void:
	_idle_elapsed = 0.0
	if _idle_hint == null or !_idle_hint_shown:
		return
	_idle_hint_shown = false
	_kill_idle_hint_tween()
	_idle_hint.visible = false
	_idle_hint.modulate.a = 0.0
	_idle_hint.rotation_degrees = 0.0

func _kill_idle_hint_tween() -> void:
	if _idle_hint_tween != null and _idle_hint_tween.is_valid():
		_idle_hint_tween.kill()

func _update_art_frame() -> void:
	if _art_frame == null or design_size.x <= 0.0 or design_size.y <= 0.0:
		return
	var viewport_size: Vector2 = size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size

	var frame_scale: float = minf(viewport_size.x / design_size.x, viewport_size.y / design_size.y)
	_art_frame.size = design_size
	_art_frame.scale = Vector2.ONE * frame_scale
	_art_frame.position = (viewport_size - design_size * frame_scale) * 0.5

## Every ComicPanelView under this page, in scene tree order.
func get_panels() -> Array[ComicPanelView]:
	var panels: Array[ComicPanelView] = []
	_collect_panels_recursive(self, panels)
	return panels

func get_group_count() -> int:
	return _panel_groups.size()

func is_finished() -> bool:
	return _is_finished

## Shows the page and reveals its first group.
func begin() -> void:
	_collect_panel_groups()
	_current_group_index = -1
	_is_finished = false
	_input_locked = false
	_fading_panels.clear()
	for panel in get_panels():
		panel.reset_panel()

	_hide_dialogue()
	if !sfx_on_page_start.strip_edges().is_empty():
		SFXManager.play(sfx_on_page_start.strip_edges())
	match ambience_mode:
		AmbienceMode.OPEN:
			AmbienceManager.set_muffled(false, ambience_fade_seconds)
		AmbienceMode.MUFFLED:
			AmbienceManager.set_muffled(true, ambience_fade_seconds)
		_:
			pass
	match music_mode:
		MusicMode.SILENT:
			_music_silenced_by_page = true
			MusicManager.set_muted(true, music_fade_seconds)
		MusicMode.PLAYING:
			MusicManager.set_muted(false, music_fade_seconds)
		_:
			pass
	MusicManager.apply_cue(music_cue_on_start)

	_reveal_next_group()

## The single input entry point. While ink is still flowing a click snaps the
## current group to its finished state instead of skipping ahead, which is what
## an impatient player expects; otherwise it moves on to the next group.
## Returns false once the page has nothing left to show.
func advance() -> bool:
	if _is_finished or _input_locked:
		return false
	_reset_idle_hint()

	# Anything still animating snaps to its end first - the ink, the panels on
	# their way out, and the typewriter.
	var snapped: bool = false
	if _is_group_revealing:
		for panel in _get_group_panels(_current_group_index):
			panel.finish_reveal_now()
		_finish_fades_now()
		snapped = true
	if _dialogue_panel != null and _dialogue_panel.is_typing:
		_dialogue_panel.finish_line()
		snapped = true
	if snapped:
		return true

	# Then the rest of this panel's lines, and only then the next panel.
	if _dialogue_index + 1 < _dialogue_queue.size():
		_show_next_dialogue_line()
		return true

	return _reveal_next_group()

## Leaves the page cleanly. The ambience is left as the page set it - the next
## scene decides what it wants.
func end_page() -> void:
	_cancel_auto_advance()
	_hide_dialogue()
	if _music_silenced_by_page:
		_music_silenced_by_page = false
		MusicManager.set_muted(false, music_fade_seconds)

func _reveal_next_group() -> bool:
	_cancel_auto_advance()
	if _current_group_index + 1 >= _panel_groups.size():
		_finish_page()
		return false

	_current_group_index += 1
	var group_panels: Array = _get_group_panels(_current_group_index)
	if group_panels.is_empty():
		return _reveal_next_group()

	for panel in group_panels:
		if (panel as ComicPanelView).locks_input:
			_input_locked = true
	_start_fades_for(group_panels)
	# The text belongs to the drawing, so it starts with it rather than after.
	var speaking_panel: ComicPanelView = _find_speaking_panel(_current_group_index)
	if speaking_panel != null:
		_show_dialogue(speaking_panel)
	else:
		_hide_dialogue()

	_is_group_revealing = true
	_pending_group_panels = group_panels.size()
	for panel in group_panels:
		if !panel.reveal_finished.is_connected(_on_panel_reveal_finished):
			panel.reveal_finished.connect(_on_panel_reveal_finished, CONNECT_ONE_SHOT)
		panel.reveal()
	return true

func _on_panel_reveal_finished() -> void:
	_pending_group_panels = maxi(0, _pending_group_panels - 1)
	if _pending_group_panels > 0:
		return

	_is_group_revealing = false
	panel_group_revealed.emit(_current_group_index)

	# A panel that drives itself wins over the page's own clock: the page-wide
	# setting is for a page that reads at a steady pace, this is for one beat
	# in the middle of a click-driven page.
	var requested: float = _group_auto_advance_seconds(_current_group_index)
	if requested >= 0.0:
		_arm_panel_auto_advance(requested)
	elif auto_advance_seconds > 0.0:
		_start_auto_advance()

## What the beat just revealed asked for: the speaking panel's wish if it has
## one, otherwise the last panel of the group. Negative means "wait for a
## click", which is the normal case.
func _group_auto_advance_seconds(group_index: int) -> float:
	var speaking: ComicPanelView = _find_speaking_panel(group_index)
	if speaking != null:
		return speaking.auto_advance_after_seconds
	var panels: Array = _get_group_panels(group_index)
	if panels.is_empty():
		return -1.0
	return (panels[panels.size() - 1] as ComicPanelView).auto_advance_after_seconds

## Starts the wait, but not before the words are on screen - the whole point of
## the delay is that it begins once the line has been typed, not while it is
## still arriving.
func _arm_panel_auto_advance(seconds: float) -> void:
	if _dialogue_panel != null and _dialogue_panel.is_typing:
		if !_dialogue_panel.line_finished.is_connected(_on_auto_advance_line_finished):
			_dialogue_panel.line_finished.connect(
				_on_auto_advance_line_finished.bind(seconds), CONNECT_ONE_SHOT)
		return
	_start_panel_auto_advance(seconds)

func _on_auto_advance_line_finished(seconds: float) -> void:
	if _is_finished or _is_group_revealing:
		return
	_start_panel_auto_advance(seconds)

func _start_panel_auto_advance(seconds: float) -> void:
	_cancel_panel_auto_advance()
	if seconds <= 0.0:
		_reveal_next_group()
		return
	_panel_advance_timer = get_tree().create_timer(seconds)
	_panel_advance_timer.timeout.connect(_on_panel_auto_advance_timeout)

func _on_panel_auto_advance_timeout() -> void:
	_panel_advance_timer = null
	if _is_finished or _is_group_revealing:
		return
	_reveal_next_group()

func _cancel_panel_auto_advance() -> void:
	if _panel_advance_timer != null and _panel_advance_timer.timeout.is_connected(_on_panel_auto_advance_timeout):
		_panel_advance_timer.timeout.disconnect(_on_panel_auto_advance_timeout)
	_panel_advance_timer = null

func _start_auto_advance() -> void:
	_cancel_auto_advance()
	_auto_advance_timer = get_tree().create_timer(auto_advance_seconds)
	_auto_advance_timer.timeout.connect(_on_auto_advance_timeout)

func _on_auto_advance_timeout() -> void:
	_auto_advance_timer = null
	if _is_finished or _is_group_revealing:
		return
	_reveal_next_group()

func _cancel_auto_advance() -> void:
	if _auto_advance_timer != null and _auto_advance_timer.timeout.is_connected(_on_auto_advance_timeout):
		_auto_advance_timer.timeout.disconnect(_on_auto_advance_timeout)
	_auto_advance_timer = null

func _finish_page() -> void:
	if _is_finished:
		return
	_is_finished = true
	_cancel_panel_auto_advance()
	if end_button_delay_seconds >= 0.0:
		_show_end_byline()
		await get_tree().create_timer(end_button_delay_seconds).timeout
		_show_end_button()
		return
	if end_hold_seconds > 0.0:
		await get_tree().create_timer(end_hold_seconds).timeout
	_emit_page_finished()

func _emit_page_finished() -> void:
	MusicManager.apply_cue(music_cue_on_finish)
	page_finished.emit()

## The way off a page that does not end on a click: a button at the foot of the
## drawing, faded up once the last thing on the page has settled. A closing
## title card wants to be looked at, and a stray click should not skip it.
func _show_end_button() -> void:
	if _end_button != null and is_instance_valid(_end_button):
		return
	_end_button = Button.new()
	_end_button.name = "EndButton"
	_end_button.text = tr(end_button_text)
	_end_button.focus_mode = Control.FOCUS_NONE
	_end_button.modulate.a = 0.0
	var host: Control = _art_frame if _art_frame != null else self
	host.add_child(_end_button)

	# Placed by its own measured width so it is centred whatever the label
	# says, and lifted off the bottom edge by the same margin the idle hint
	# keeps.
	var button_size: Vector2 = _end_button.get_combined_minimum_size()
	button_size.x = maxf(button_size.x, 160.0)
	_end_button.size = button_size
	_end_button.position = Vector2(
		(design_size.x - button_size.x) * 0.5,
		design_size.y - button_size.y - idle_hint_margin.y * 2.0
	)
	_end_button.pressed.connect(_on_end_button_pressed)

	var tween := _end_button.create_tween()
	tween.tween_property(_end_button, "modulate:a", 1.0, end_button_fade_seconds)

## The credit under the drawing. Faded up rather than switched on, so it reads
## as part of the card settling rather than as something appearing on top of it.
func _show_end_byline() -> void:
	if end_byline_text.strip_edges().is_empty():
		return
	if _end_byline != null and is_instance_valid(_end_byline):
		return

	_end_byline = Label.new()
	_end_byline.name = "EndByline"
	_end_byline.text = tr(end_byline_text)
	_end_byline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_byline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_byline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if end_byline_font != null:
		_end_byline.add_theme_font_override("font", end_byline_font)
	_end_byline.add_theme_font_size_override("font_size", end_byline_font_size)
	_end_byline.add_theme_color_override("font_color", end_byline_color)
	_end_byline.modulate.a = 0.0
	_end_byline.position = end_byline_rect.position
	_end_byline.size = end_byline_rect.size

	var host: Control = _art_frame if _art_frame != null else self
	host.add_child(_end_byline)

	var tween := _end_byline.create_tween()
	tween.tween_property(_end_byline, "modulate:a", 1.0, end_byline_fade_seconds)

func _on_end_button_pressed() -> void:
	if _end_button != null and is_instance_valid(_end_button):
		_end_button.disabled = true
	_emit_page_finished()

## Sends away every panel that was waiting on one of the panels about to draw.
func _start_fades_for(group_panels: Array) -> void:
	for panel in get_panels():
		if panel.hide_when_revealed.is_empty() or panel.is_hidden_by_other():
			continue
		var trigger := panel.get_node_or_null(panel.hide_when_revealed) as ComicPanelView
		if trigger == null or !group_panels.has(trigger):
			continue
		panel.fade_out()
		_fading_panels.append(panel)

func _finish_fades_now() -> void:
	for panel in _fading_panels:
		if is_instance_valid(panel):
			panel.finish_fade_out_now()
	_fading_panels.clear()

## The last panel of a group that carries text - the one whose line belongs to
## this beat.
func _find_speaking_panel(group_index: int) -> ComicPanelView:
	var speaking: ComicPanelView = null
	for panel in _get_group_panels(group_index):
		if panel.has_dialogue():
			speaking = panel
	return speaking

func _show_dialogue(panel: ComicPanelView) -> void:
	if _dialogue_slots.is_empty():
		push_warning("ComicPage '%s' has a panel with dialogue but no dialogue box." % name)
		return

	_dialogue_queue = panel.get_dialogue_lines()
	_dialogue_index = -1
	_dialogue_rect = panel.dialogue_rect if panel.dialogue_rect.size.x > 0.0 else _dialogue_base_rect
	# A new panel gets the other box, so the line it replaces can fade out in
	# its own place while this one types.
	_fade_out_active_slot()
	_active_slot = (_active_slot + 1) % _dialogue_slots.size()
	_dialogue_panel = _dialogue_slots[_active_slot]
	# This box may still be fading from the last time it was used; that tween
	# would carry on and take the new line with it.
	_kill_slot_fade(_active_slot)
	_dialogue_panel.modulate.a = 1.0
	_dialogue_panel.visible = true
	_show_next_dialogue_line()

## Sends the box that is on screen away over dialogue_fade_out_seconds.
func _fade_out_active_slot() -> void:
	if _active_slot < 0:
		return
	var index: int = _active_slot
	var outgoing: DialoguePanel = _dialogue_slots[index]
	if !outgoing.visible:
		return

	_kill_slot_fade(index)
	var tween := outgoing.create_tween()
	tween.tween_property(outgoing, "modulate:a", 0.0, dialogue_fade_out_seconds)
	tween.tween_callback(Callable(self, "_hide_slot").bind(index))
	_slot_fade_tweens[index] = tween

func _kill_slot_fade(index: int) -> void:
	var tween: Tween = _slot_fade_tweens[index]
	if tween != null and tween.is_valid():
		tween.kill()
	_slot_fade_tweens[index] = null

func _hide_slot(index: int) -> void:
	_slot_fade_tweens[index] = null
	# Never hide the box that has since been handed the next line.
	if index == _active_slot:
		return
	var slot: DialoguePanel = _dialogue_slots[index]
	if is_instance_valid(slot):
		slot.visible = false
		slot.modulate.a = 1.0

## Moves the active box to where this panel wants its text.
##
## Only the top-left and the width are taken from the rect; the height is left
## to the text, so a two-word line does not sit in a tall empty frame and a
## long one is never clipped. The authored height is the room the layout
## reserves, and a line that outgrows it is reported.
func _apply_dialogue_rect() -> void:
	var root := _dialogue_panel.get_node_or_null("DialogueRoot") as Control
	if root == null or _dialogue_rect.size.x <= 0.0:
		return
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.custom_minimum_size = Vector2(_dialogue_rect.size.x, 0.0)
	root.size = Vector2(_dialogue_rect.size.x, 0.0)
	root.position = _dialogue_rect.position

func _show_next_dialogue_line() -> void:
	_dialogue_index += 1
	if _dialogue_index >= _dialogue_queue.size():
		return

	var line: ComicDialogueLine = _dialogue_queue[_dialogue_index]
	_dialogue_panel.set_speaker_gap(line.speaker_gap)
	_apply_dialogue_rect()
	_dialogue_panel.show_line(line.get_speaker(), line.get_text(), null)
	MusicManager.apply_cue(line.music_cue)
	_settle_dialogue_box()

## Re-fits the box to the line that is now in it, then reports if that needs
## more room than the page set aside.
##
## The re-fit is not optional: a Control grows to meet its minimum size but
## never shrinks back on its own, so without this the box would keep whatever
## height the longest line so far gave it - and the very first line, measured
## while the box was still hidden and had no width to wrap against, would leave
## it taller than the screen.
func _settle_dialogue_box() -> void:
	var root := _dialogue_panel.get_node_or_null("DialogueRoot") as Control
	if root == null or _dialogue_rect.size.x <= 0.0:
		return

	for _step in range(2):
		await get_tree().process_frame
		root.size = Vector2(_dialogue_rect.size.x, 0.0)
		root.position = _dialogue_rect.position

	if _dialogue_rect.size.y > 0.0 and root.size.y > _dialogue_rect.size.y + 1.0:
		push_warning("ComicPage '%s': a line needs %d px but the layout reserves %d at (%d, %d)." % [
			name, int(root.size.y), int(_dialogue_rect.size.y),
			int(_dialogue_rect.position.x), int(_dialogue_rect.position.y)])

func _hide_dialogue() -> void:
	_dialogue_queue.clear()
	_dialogue_index = -1
	# The index is kept so the next line still lands in the other box.
	_fade_out_active_slot()

func _get_group_panels(group_index: int) -> Array:
	if group_index < 0 or group_index >= _panel_groups.size():
		return []
	return _panel_groups[group_index]

## Consecutive panels marked "reveal with previous" collapse into one group,
## so a group is what a single click reveals.
func _collect_panel_groups() -> void:
	_panel_groups.clear()
	var current_group: Array = []
	for panel in get_panels():
		if current_group.is_empty() or !panel.reveal_with_previous:
			if !current_group.is_empty():
				_panel_groups.append(current_group)
			current_group = []
		current_group.append(panel)
	if !current_group.is_empty():
		_panel_groups.append(current_group)

func _collect_panels_recursive(node: Node, panels: Array[ComicPanelView]) -> void:
	for child in node.get_children():
		if child is ComicPanelView:
			panels.append(child)
		_collect_panels_recursive(child, panels)
