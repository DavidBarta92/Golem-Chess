extends Window
class_name InputRebindDialog

@onready var action_button: Button = $Root/ActionRow/ActionButton
@onready var reset_button: Button = $Root/ButtonRow/ResetButton
@onready var close_button: Button = $Root/ButtonRow/CloseButton

var controls_section: ControlsSection
var is_remapping: bool = false

func _ready() -> void:
	close_requested.connect(_on_close_pressed)
	close_button.pressed.connect(_on_close_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	action_button.pressed.connect(_on_action_button_pressed)

func open() -> void:
	is_remapping = false
	refresh_action_button()
	popup_centered()

func refresh_action_button() -> void:
	action_button.text = OS.get_keycode_string(controls_section.get_saved_keycode())

func _on_action_button_pressed() -> void:
	if is_remapping:
		return
	is_remapping = true
	action_button.text = tr("Press a key…")

func _input(event: InputEvent) -> void:
	if not is_remapping or not visible:
		return

	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or !key_event.pressed or key_event.echo:
		return

	is_remapping = false
	controls_section.save_keycode(key_event.keycode)
	refresh_action_button()
	get_viewport().set_input_as_handled()

func _on_reset_pressed() -> void:
	is_remapping = false
	controls_section.save_keycode(controls_section.DEFAULT_KEYCODE)
	refresh_action_button()

func _on_close_pressed() -> void:
	is_remapping = false
	hide()
