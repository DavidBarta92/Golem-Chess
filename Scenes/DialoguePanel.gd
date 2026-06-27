extends Control
class_name DialoguePanel

signal continue_requested

const PORTRAIT_VIEW = preload("res://Scenes/PortraitView.tscn")
const TYPEWRITER_CHARS_PER_SECOND: float = 42.0
const DIALOGUE_ROOT_LEFT: float = 24.0
const DIALOGUE_ROOT_RIGHT: float = 392.0
const DIALOGUE_ROOT_TOP: float = -150.0
const DIALOGUE_ROOT_BOTTOM: float = 150.0
const PROFILE_ROOT_BOTTOM: float = 20.0
const DIALOGUE_LINE_WIDTH: float = 1.5
const DIALOGUE_LINE_MIN_HEIGHT: float = 14.0
const DIALOGUE_LINE_DRAW_PIXELS_PER_SECOND: float = 420.0

@onready var dialogue_root: PanelContainer = $DialogueRoot
@onready var portrait_frame: PanelContainer = $DialogueRoot/DialogueLayout/PortraitFrame
@onready var portrait_initial_label: Label = $DialogueRoot/DialogueLayout/PortraitFrame/PortraitInitial
@onready var portrait_texture: TextureRect = $DialogueRoot/DialogueLayout/PortraitFrame/PortraitTexture
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
var line_allows_continue: bool = true
var dialogue_line_target_height: float = 0.0
var dialogue_line_visible_height: float = 0.0
var dialogue_line_is_animating: bool = false
var waiting_for_line_before_typing: bool = false
var dialogue_line_prepare_version: int = 0
var skip_line_intro_requested: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_root.mouse_filter = Control.MOUSE_FILTER_STOP
	continue_button.pressed.connect(_on_continue_pressed)
	dialogue_root.gui_input.connect(_on_dialogue_root_gui_input)
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

func set_turn_focus(enabled: bool) -> void:
	if portrait_view != null:
		portrait_view.set_turn_focus(enabled)

func show_line(speaker: String, text: String, portrait = null, allow_continue: bool = true) -> void:
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
	update_portrait(speaker, portrait)

	dialogue_text.text = text
	dialogue_text.visible_characters = -1
	dialogue_text.modulate.a = 0.0
	reset_dialogue_line()
	dialogue_line.visible = true
	continue_button.visible = true
	continue_button.text = "Skip"
	call_deferred("prepare_dialogue_line_before_typing", prepare_version)
	set_process(true)

func set_dialogue_content_visible(show_content: bool) -> void:
	text_panel.visible = show_content
	button_row.visible = show_content
	dialogue_root.offset_left = DIALOGUE_ROOT_LEFT
	dialogue_root.offset_right = DIALOGUE_ROOT_RIGHT
	dialogue_root.offset_top = DIALOGUE_ROOT_TOP
	dialogue_root.offset_bottom = DIALOGUE_ROOT_BOTTOM if show_content else PROFILE_ROOT_BOTTOM
	dialogue_root.mouse_filter = Control.MOUSE_FILTER_STOP if show_content else Control.MOUSE_FILTER_IGNORE

func update_portrait(speaker: String, portrait) -> void:
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
	continue_button.text = "Continue"
	continue_button.visible = line_allows_continue
	set_process(false)

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
