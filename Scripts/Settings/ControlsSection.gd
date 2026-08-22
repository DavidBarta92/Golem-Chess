extends SettingsSection
class_name ControlsSection

const ACTION_NAME: String = "ui_cancel"
const DEFAULT_KEYCODE: Key = KEY_ESCAPE

func _ready() -> void:
	super._ready()
	SettingsDataManager.connect("settings_retrieved", apply_saved_keybind)

func get_saved_keycode() -> Key:
	var section_data: Dictionary = SettingsDataManager.settingsData_.get(IDENTIFIER, {})
	var value = section_data.get("CancelKey")
	if typeof(value) == TYPE_INT:
		return value as Key
	return DEFAULT_KEYCODE

func apply_saved_keybind() -> void:
	set_action_keycode(get_saved_keycode())

func save_keycode(keycode: Key) -> void:
	if not SettingsDataManager.settingsData_.has(IDENTIFIER):
		SettingsDataManager.settingsData_[IDENTIFIER] = {}
	SettingsDataManager.settingsData_[IDENTIFIER]["CancelKey"] = int(keycode)
	SettingsDataManager.save_data()
	set_action_keycode(keycode)

func set_action_keycode(keycode: Key) -> void:
	for event in InputMap.action_get_events(ACTION_NAME):
		if event is InputEventKey:
			InputMap.action_erase_event(ACTION_NAME, event)

	var new_event := InputEventKey.new()
	new_event.keycode = keycode
	InputMap.action_add_event(ACTION_NAME, new_event)
