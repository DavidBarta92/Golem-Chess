extends Control
class_name DialoguePanel

signal continue_requested

const PORTRAIT_VIEW = preload("res://Scenes/PortraitView.tscn")
const TYPEWRITER_CHARS_PER_SECOND: float = 42.0
const DIALOGUE_ROOT_TOP: float = -176.0
const DIALOGUE_ROOT_BOTTOM: float = 176.0
const PROFILE_ROOT_BOTTOM: float = 24.0

@onready var dialogue_root: PanelContainer = $DialogueRoot
@onready var portrait_frame: PanelContainer = $DialogueRoot/DialogueLayout/PortraitFrame
@onready var portrait_initial_label: Label = $DialogueRoot/DialogueLayout/PortraitFrame/PortraitInitial
@onready var portrait_texture: TextureRect = $DialogueRoot/DialogueLayout/PortraitFrame/PortraitTexture
@onready var speaker_label: Label = $DialogueRoot/DialogueLayout/SpeakerLabel
@onready var text_panel: PanelContainer = $DialogueRoot/DialogueLayout/TextPanel
@onready var dialogue_text: RichTextLabel = $DialogueRoot/DialogueLayout/TextPanel/DialogueText
@onready var button_row: HBoxContainer = $DialogueRoot/DialogueLayout/ButtonRow
@onready var continue_button: Button = $DialogueRoot/DialogueLayout/ButtonRow/ContinueButton

var full_text: String = ""
var visible_character_count: int = 0
var is_typing: bool = false
var character_progress: float = 0.0
var portrait_view: PortraitView
var line_allows_continue: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_root.mouse_filter = Control.MOUSE_FILTER_STOP
	continue_button.pressed.connect(_on_continue_pressed)
	dialogue_root.gui_input.connect(_on_dialogue_root_gui_input)
	create_portrait_view()
	set_process(false)

func create_portrait_view() -> void:
	portrait_view = PORTRAIT_VIEW.instantiate() as PortraitView
	portrait_frame.add_child(portrait_view)
	portrait_view.visible = false
	portrait_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_view.custom_minimum_size = Vector2(0.0, 150.0)
	portrait_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_view.show_frame = false
	portrait_view.show_background = true
	portrait_view.use_scene_mask = true

func show_profile(speaker: String, portrait = null) -> void:
	visible = true
	full_text = ""
	is_typing = false
	set_process(false)
	speaker_label.text = speaker
	update_portrait(speaker, portrait)
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
	is_typing = true
	line_allows_continue = allow_continue

	speaker_label.text = speaker
	update_portrait(speaker, portrait)

	dialogue_text.text = text
	dialogue_text.visible_characters = 0
	continue_button.visible = true
	continue_button.text = "Skip"
	set_process(true)

func set_dialogue_content_visible(show_content: bool) -> void:
	text_panel.visible = show_content
	button_row.visible = show_content
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
	visible_character_count = full_text.length()
	dialogue_text.visible_characters = -1
	continue_button.text = "Continue"
	continue_button.visible = line_allows_continue
	set_process(false)

func _process(delta: float) -> void:
	if !is_typing:
		return

	character_progress += TYPEWRITER_CHARS_PER_SECOND * delta
	var next_visible_count: int = mini(full_text.length(), int(character_progress))
	if next_visible_count == visible_character_count:
		return

	visible_character_count = next_visible_count
	dialogue_text.visible_characters = visible_character_count
	if visible_character_count >= full_text.length():
		finish_line()

func _on_continue_pressed() -> void:
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
