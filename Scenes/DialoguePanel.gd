extends Control
class_name DialoguePanel

signal continue_requested
## The current line has finished typing itself out, whether it ran its course
## or was skipped. A caller that supplies its own Continue button waits for
## this before showing it.
signal line_finished

const PORTRAIT_VIEW = preload("res://Scenes/PortraitView.tscn")
const TYPEWRITER_CHARS_PER_SECOND: float = 42.0
const DIALOGUE_LINE_WIDTH: float = 1.5
const DIALOGUE_LINE_MIN_HEIGHT: float = 14.0
const DIALOGUE_LINE_DRAW_PIXELS_PER_SECOND: float = 420.0
const SPEECH_BACKGROUND_COLOR: Color = Color(0.93, 0.93, 0.9, 0.96)
# How far the fade runs past the text panel's right edge, as a share of the
# band's width there.
const SPEECH_BACKGROUND_FADE_OVERRUN: float = 0.15
const SPEECH_BACKGROUND_FADE_SECONDS: float = 0.35

@onready var dialogue_root: PanelContainer = $DialogueRoot
@onready var portrait_frame: PanelContainer = $DialogueRoot/DialogueLayout/PortraitFrame
@onready var portrait_initial_label: Label = $DialogueRoot/DialogueLayout/PortraitFrame/PortraitInitial
@onready var portrait_texture: TextureRect = $DialogueRoot/DialogueLayout/PortraitFrame/PortraitTexture
@onready var dialogue_layout: VBoxContainer = $DialogueRoot/DialogueLayout
@onready var speaker_label: Label = $DialogueRoot/DialogueLayout/SpeakerLabel
@onready var text_panel: PanelContainer = $DialogueRoot/DialogueLayout/TextPanel
@onready var dialogue_line_box: Control = $DialogueRoot/DialogueLayout/TextPanel/DialogueTextRow/DialogueLineBox
@onready var dialogue_line: ColorRect = $DialogueRoot/DialogueLayout/TextPanel/DialogueTextRow/DialogueLineBox/DialogueLine
@onready var dialogue_text: RichTextLabel = $DialogueRoot/DialogueLayout/TextPanel/DialogueTextRow/DialogueText
@onready var button_row: HBoxContainer = $DialogueRoot/DialogueLayout/ButtonRow
@onready var continue_button: Button = $DialogueRoot/DialogueLayout/ButtonRow/ContinueButton

var full_text: String = ""
var visible_character_count: int = 0
var is_typing: bool = false
var character_progress: float = 0.0
var portrait_view: PortraitView
var portrait_background_color: Color = Color(0.909804, 0.694118, 0.486275, 1.0)
var line_allows_continue: bool = true
## Off puts the panel in "talking head" mode: the box shows and types, but it
## swallows no clicks and offers no Continue button, so a line can play out
## while the match carries on underneath it.
var is_interactive: bool = true
var _default_speaker_min_height: float = 0.0
## Off hides the portrait frame entirely - for a speaker with no face to show,
## like the narration and dialogue on comic pages.
var portrait_enabled: bool = true
## Off hides the panel's own Continue/Skip row, for a context that puts its own
## button somewhere else (a comic page uses the page corner).
var button_row_enabled: bool = true
var dialogue_line_target_height: float = 0.0
var dialogue_line_visible_height: float = 0.0
var dialogue_line_is_animating: bool = false
var waiting_for_line_before_typing: bool = false
var dialogue_line_prepare_version: int = 0
var skip_line_intro_requested: bool = false
## Set by centre_on_screen_middle(): the box's resting height, and what gives
## the line its bottom must stay above (in this panel's own coordinates).
var _centred_height: float = 0.0
var _bottom_limit_provider: Callable = Callable()
var _top_margin: float = 0.0
var _lifting: bool = false
## What the Continue button says once a line is written out; empty for the
## usual "Continue".
var _continue_text: String = ""
var speech_background_texture: GradientTexture2D
var speech_background_alpha: float = 0.0
var speech_background_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_root.mouse_filter = Control.MOUSE_FILTER_STOP
	continue_button.pressed.connect(_on_continue_pressed)
	dialogue_root.gui_input.connect(_on_dialogue_root_gui_input)
	_default_speaker_min_height = speaker_label.custom_minimum_size.y
	speech_background_texture = _create_speech_background_texture()
	text_panel.draw.connect(_draw_speech_background)
	create_portrait_view()
	reset_dialogue_line()
	set_process(false)

func create_portrait_view() -> void:
	portrait_view = PORTRAIT_VIEW.instantiate() as PortraitView
	portrait_frame.add_child(portrait_view)
	portrait_view.visible = false
	portrait_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_view.custom_minimum_size = Vector2(0.0, 128.0)
	portrait_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_view.show_frame = false
	portrait_view.show_background = true
	portrait_view.use_scene_mask = true
	portrait_view.background_color = portrait_background_color

## The colour behind the face. Defaults to the warm card the mentor and the
## comics use; the opponent's panel in a match asks for plain white.
func set_portrait_background_color(color: Color) -> void:
	portrait_background_color = color
	if portrait_view != null and is_instance_valid(portrait_view):
		portrait_view.background_color = color

func show_profile(speaker: String, portrait = null) -> void:
	visible = true
	full_text = ""
	is_typing = false
	waiting_for_line_before_typing = false
	skip_line_intro_requested = false
	dialogue_line_prepare_version += 1
	set_process(false)
	speaker_label.text = speaker
	update_portrait(speaker, portrait)
	reset_dialogue_line()
	set_dialogue_content_visible(false)

# --- Parts, for a caller that fades them separately -------------------------
#
# A match shows the opponent's face and their words on different clocks: the
# face arrives first and stays between lines, the words come and go. These let
# that caller address the two halves without reaching into the scene tree.

## The speaker's name and face.
func set_identity_alpha(alpha: float) -> void:
	speaker_label.modulate.a = alpha
	portrait_frame.modulate.a = alpha

## The words and whatever sits under them.
func set_speech_alpha(alpha: float) -> void:
	text_panel.modulate.a = alpha
	button_row.modulate.a = alpha

## Shifts the whole panel down the screen, for a caller that needs it clear of
## something the room has drawn behind it.
func set_vertical_nudge(pixels: float) -> void:
	dialogue_root.offset_top += pixels
	dialogue_root.offset_bottom += pixels

func get_portrait_frame() -> Control:
	return portrait_frame

func get_text_panel() -> Control:
	return text_panel

func get_button_row() -> Control:
	return button_row

func set_turn_focus(enabled: bool) -> void:
	if portrait_view != null:
		portrait_view.set_turn_focus(enabled)

## `keep_portrait` leaves the face and its frame exactly as they are, for a
## speaker who stays on screen while their words are replaced.
func show_line(speaker: String, text: String, portrait = null, allow_continue: bool = true, keep_portrait: bool = false) -> void:
	visible = true
	set_dialogue_content_visible(true)
	full_text = text
	visible_character_count = 0
	character_progress = 0.0
	is_typing = false
	waiting_for_line_before_typing = true
	skip_line_intro_requested = false
	dialogue_line_prepare_version += 1
	line_allows_continue = allow_continue
	var prepare_version: int = dialogue_line_prepare_version

	speaker_label.text = speaker
	if !keep_portrait:
		update_portrait(speaker, portrait)

	dialogue_text.text = text
	dialogue_text.visible_characters = -1
	dialogue_text.modulate.a = 0.0
	reset_dialogue_line()
	dialogue_line.visible = true
	continue_button.visible = is_interactive and button_row_enabled
	continue_button.text = tr("Skip")
	call_deferred("prepare_dialogue_line_before_typing", prepare_version)
	set_process(true)

## For a panel with no face above the words: the box is centred on the
## screen's middle line and its contents within the box, so the words sit
## level with the middle of the picture instead of up where a face would
## start. A long line grows the box both ways; if that would take its bottom
## past the line `bottom_limit_provider` returns (something below it on
## screen, like the codex), the box is lifted until it clears it. The limit is
## asked for each time, so it follows whatever it is taken from. The lift
## never takes the top of the box above `top_margin`: if a line is too long
## for both, the speaker's name stays on screen. Each new line starts centred
## again.
func centre_on_screen_middle(bottom_limit_provider: Callable = Callable(), top_margin: float = 0.0) -> void:
	_centred_height = dialogue_root.offset_bottom - dialogue_root.offset_top
	_bottom_limit_provider = bottom_limit_provider
	_top_margin = top_margin
	dialogue_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	text_panel.size_flags_vertical = Control.SIZE_FILL
	if !dialogue_root.resized.is_connected(_keep_above_bottom_limit):
		dialogue_root.resized.connect(_keep_above_bottom_limit)
	_recentre()

func _recentre() -> void:
	if _centred_height <= 0.0:
		return
	dialogue_root.offset_top = -_centred_height * 0.5
	dialogue_root.offset_bottom = _centred_height * 0.5
	call_deferred("_keep_above_bottom_limit")

## Moves the box rather than resizing it - moving one edge at a time would
## resize it, which calls this again.
func _keep_above_bottom_limit() -> void:
	if _centred_height <= 0.0 or !_bottom_limit_provider.is_valid() or _lifting:
		return
	var root_rect: Rect2 = dialogue_root.get_rect()
	var overflow: float = root_rect.end.y - float(_bottom_limit_provider.call())
	var lift: float = minf(overflow, root_rect.position.y - _top_margin)
	if lift > 0.5:
		_lifting = true
		dialogue_root.position.y -= lift
		_lifting = false

## What the Continue button says, for a line that ends in an answer ("Yes!")
## rather than a plain Continue. Empty puts the usual word back.
func set_continue_text(text: String) -> void:
	_continue_text = text

## Lets the current line be continued (or not) after it was shown, for a
## caller that holds the player on a line until something else has finished.
func set_continue_allowed(allowed: bool) -> void:
	line_allows_continue = allowed
	if !is_typing and !waiting_for_line_before_typing:
		continue_button.visible = allowed and is_interactive and button_row_enabled

## Hides the portrait frame. Call before showing a line.
func set_portrait_enabled(enabled: bool) -> void:
	portrait_enabled = enabled
	if !enabled:
		portrait_frame.visible = false
		if portrait_view != null:
			portrait_view.visible = false
		portrait_texture.visible = false
		portrait_initial_label.visible = false
	else:
		portrait_frame.visible = true

## Tightens (or restores) the gap between the speaker's name and their words.
## Pass a negative value to go back to the panel's own spacing.
func set_speaker_gap(gap: float) -> void:
	if gap < 0.0:
		dialogue_layout.remove_theme_constant_override("separation")
		speaker_label.custom_minimum_size.y = _default_speaker_min_height
		return
	dialogue_layout.add_theme_constant_override("separation", int(gap))
	# The label reserves a line box taller than its text, which is most of the
	# gap; let it hug the name instead.
	speaker_label.custom_minimum_size.y = 0.0

## Hides the panel's own Continue/Skip row.
func set_button_row_enabled(enabled: bool) -> void:
	button_row_enabled = enabled
	button_row.visible = enabled and text_panel.visible

func set_dialogue_content_visible(show_content: bool) -> void:
	text_panel.visible = show_content
	button_row.visible = show_content and button_row_enabled
	var accepts_clicks: bool = show_content and is_interactive
	dialogue_root.mouse_filter = Control.MOUSE_FILTER_STOP if accepts_clicks else Control.MOUSE_FILTER_IGNORE

## Toggles whether the panel takes clicks and offers a Continue button.
func set_interactive(enabled: bool) -> void:
	is_interactive = enabled
	set_dialogue_content_visible(text_panel.visible)
	if !enabled:
		continue_button.visible = false
	elif !is_typing:
		continue_button.visible = line_allows_continue

func update_portrait(speaker: String, portrait) -> void:
	if !portrait_enabled:
		portrait_frame.visible = false
		return

	portrait_initial_label.text = get_speaker_initials(speaker)
	portrait_texture.texture = null
	portrait_texture.visible = false
	portrait_initial_label.visible = false
	if portrait_view != null:
		portrait_view.visible = false

	if portrait is PortraitConfig:
		if portrait_view != null:
			portrait_view.set_portrait_config(portrait)
			portrait_view.visible = true
		return

	if portrait is Texture2D:
		portrait_texture.texture = portrait
		portrait_texture.visible = true
		return

	portrait_initial_label.visible = true

func finish_line() -> void:
	is_typing = false
	waiting_for_line_before_typing = false
	skip_line_intro_requested = false
	visible_character_count = full_text.length()
	dialogue_text.modulate.a = 1.0
	dialogue_text.visible_characters = -1
	dialogue_line_visible_height = dialogue_line_target_height
	apply_dialogue_line_size()
	continue_button.text = _continue_text if !_continue_text.is_empty() else tr("Continue")
	continue_button.visible = line_allows_continue and is_interactive and button_row_enabled
	set_process(false)
	line_finished.emit()

func _process(delta: float) -> void:
	if is_typing:
		character_progress += TYPEWRITER_CHARS_PER_SECOND * delta
		var next_visible_count: int = mini(full_text.length(), int(character_progress))
		if next_visible_count != visible_character_count:
			visible_character_count = next_visible_count
			dialogue_text.visible_characters = visible_character_count
			if visible_character_count >= full_text.length():
				finish_line()

	if dialogue_line_is_animating:
		dialogue_line_visible_height = minf(
			dialogue_line_target_height,
			dialogue_line_visible_height + DIALOGUE_LINE_DRAW_PIXELS_PER_SECOND * delta
		)
		apply_dialogue_line_size()
		if dialogue_line_visible_height >= dialogue_line_target_height:
			dialogue_line_is_animating = false
			if waiting_for_line_before_typing:
				start_typewriter_text()

	if !is_typing and !dialogue_line_is_animating:
		set_process(false)

func reset_dialogue_line() -> void:
	dialogue_line_target_height = 0.0
	dialogue_line_visible_height = 0.0
	dialogue_line_is_animating = false
	_hide_speech_background()
	if dialogue_line != null:
		dialogue_line.visible = false
		dialogue_line.pivot_offset = Vector2.ZERO
		dialogue_line.size = Vector2(DIALOGUE_LINE_WIDTH, 0.0)
	if dialogue_line_box != null:
		dialogue_line_box.custom_minimum_size = Vector2(DIALOGUE_LINE_WIDTH, 0.0)

func prepare_dialogue_line_before_typing(prepare_version: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	if prepare_version != dialogue_line_prepare_version or !waiting_for_line_before_typing:
		return
	# The words have been laid out by now, so the box can be sized for them
	# rather than for the line before.
	_recentre()
	if dialogue_line == null or dialogue_line_box == null or dialogue_text == null:
		return
	if !text_panel.visible or full_text.is_empty():
		dialogue_line_target_height = 0.0
		dialogue_line_visible_height = 0.0
		waiting_for_line_before_typing = false
		apply_dialogue_line_size()
		finish_line()
		return

	dialogue_text.visible_characters = -1
	dialogue_text.modulate.a = 0.0
	var content_rect: Rect2i = dialogue_text.get_visible_content_rect()
	var measured_height: float = maxf(float(content_rect.size.y), float(dialogue_text.get_content_height()))

	dialogue_line_target_height = maxf(DIALOGUE_LINE_MIN_HEIGHT, measured_height)
	_fade_in_speech_background()
	if skip_line_intro_requested:
		dialogue_line_visible_height = dialogue_line_target_height
		dialogue_line_is_animating = false
		apply_dialogue_line_size()
		start_typewriter_text()
		return

	dialogue_line_visible_height = 0.0
	dialogue_line_is_animating = dialogue_line_target_height > 0.0
	apply_dialogue_line_size()
	set_process(true)

func start_typewriter_text() -> void:
	waiting_for_line_before_typing = false
	skip_line_intro_requested = false
	is_typing = true
	visible_character_count = 0
	character_progress = 0.0
	dialogue_text.modulate.a = 1.0
	dialogue_text.visible_characters = 0
	set_process(true)

func apply_dialogue_line_size() -> void:
	if dialogue_line == null or dialogue_line_box == null:
		return

	dialogue_line.visible = dialogue_line_target_height > 0.0
	dialogue_line_box.custom_minimum_size = Vector2(DIALOGUE_LINE_WIDTH, dialogue_line_target_height)
	dialogue_line.position = Vector2.ZERO
	dialogue_line.size = Vector2(DIALOGUE_LINE_WIDTH, dialogue_line_visible_height)
	text_panel.queue_redraw()

# --- Band behind the words ---------------------------------------------------
#
# The words sit on a band that starts at the line in the panel colour and fades
# out to the right, like the Collection's stamp descriptions. It is exactly as
# tall as the line (not the whole text panel, which can be stretched taller)
# and fades in as each line starts drawing.

func _create_speech_background_texture() -> GradientTexture2D:
	var faded_color: Color = SPEECH_BACKGROUND_COLOR
	faded_color.a = 0.0
	var gradient := Gradient.new()
	gradient.set_color(0, SPEECH_BACKGROUND_COLOR)
	gradient.set_color(1, faded_color)
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 256
	gradient_texture.height = 1
	return gradient_texture

func _draw_speech_background() -> void:
	if speech_background_alpha <= 0.0 or dialogue_line_target_height <= 0.0 or speech_background_texture == null:
		return
	var text_row: Control = dialogue_line_box.get_parent() as Control
	var line_top_left: Vector2 = text_row.position + dialogue_line_box.position + dialogue_line.position
	var band := Rect2(
		line_top_left,
		Vector2(
			maxf(0.0, text_panel.size.x - line_top_left.x) * (1.0 + SPEECH_BACKGROUND_FADE_OVERRUN),
			dialogue_line_target_height
		)
	)
	text_panel.draw_texture_rect(speech_background_texture, band, false, Color(1.0, 1.0, 1.0, speech_background_alpha))

func _set_speech_background_alpha(alpha: float) -> void:
	speech_background_alpha = alpha
	if text_panel != null:
		text_panel.queue_redraw()

func _fade_in_speech_background() -> void:
	if speech_background_tween != null and speech_background_tween.is_valid():
		speech_background_tween.kill()
	speech_background_tween = create_tween()
	speech_background_tween.set_trans(Tween.TRANS_SINE)
	speech_background_tween.set_ease(Tween.EASE_OUT)
	speech_background_tween.tween_method(_set_speech_background_alpha, speech_background_alpha, 1.0, SPEECH_BACKGROUND_FADE_SECONDS)

func _hide_speech_background() -> void:
	if speech_background_tween != null and speech_background_tween.is_valid():
		speech_background_tween.kill()
	_set_speech_background_alpha(0.0)

func _on_continue_pressed() -> void:
	if waiting_for_line_before_typing:
		if dialogue_line_target_height <= 0.0:
			skip_line_intro_requested = true
			return
		dialogue_line_visible_height = dialogue_line_target_height
		dialogue_line_is_animating = false
		apply_dialogue_line_size()
		start_typewriter_text()
		return
	if is_typing:
		finish_line()
		return
	if !line_allows_continue:
		return
	continue_requested.emit()

func _on_dialogue_root_gui_input(event: InputEvent) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null or !mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	_on_continue_pressed()
	accept_event()

func get_speaker_initials(speaker: String) -> String:
	var trimmed_speaker: String = speaker.strip_edges()
	if trimmed_speaker.is_empty():
		return "?"
	return trimmed_speaker.substr(0, 1).to_upper()
