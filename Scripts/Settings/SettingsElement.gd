extends Control
class_name SettingsElement

@export var IDENTIFIER: String = "Element"

@onready var SECTION: String = ParentRef.IDENTIFIER

var ParentRef: SettingsSection
var currentValue

func _enter_tree() -> void:
	ParentRef = owner

func _ready() -> void:
	SettingsDataManager.connect("settings_retrieved", load_settings)
	ParentRef.ELEMENT_REFERENCE_TABLE_[IDENTIFIER] = self

func init_element() -> void:
	return

func load_settings() -> void:
	var VALUES_: Dictionary = get_valid_values()

	if SettingsDataManager.noSaveFile or not verify_settings_data(VALUES_):
		currentValue = VALUES_["defaultValue"]
		SettingsDataManager.settingsData_[SECTION][IDENTIFIER] = currentValue
		if not SettingsDataManager.noSaveFile:
			SettingsDataManager.invalidSaveFile = true
	else:
		currentValue = SettingsDataManager.settingsData_[SECTION][IDENTIFIER]

	init_element()
	call_deferred("_apply_settings")

func get_valid_values() -> Dictionary:
	return {}

func verify_settings_data(VALUES_: Dictionary) -> bool:
	if not entry_exists():
		return false

	var RETRIEVED_VALUE = SettingsDataManager.settingsData_[SECTION][IDENTIFIER]
	if not is_valid_type(VALUES_, RETRIEVED_VALUE):
		return false
	if not is_valid_value(VALUES_, RETRIEVED_VALUE):
		return false

	return true

func entry_exists() -> bool:
	if not SettingsDataManager.settingsData_.has(SECTION):
		return false
	if not SettingsDataManager.settingsData_[SECTION].has(IDENTIFIER):
		return false
	return true

func is_valid_type(VALUES_: Dictionary, RETRIEVED_VALUE) -> bool:
	return typeof(RETRIEVED_VALUE) == typeof(VALUES_["defaultValue"])

func is_valid_value(VALUES_: Dictionary, RETRIEVED_VALUE) -> bool:
	match typeof(VALUES_["defaultValue"]):
		TYPE_STRING, TYPE_BOOL:
			if not VALUES_["validOptions"].has(RETRIEVED_VALUE):
				return false
		TYPE_INT, TYPE_FLOAT:
			if RETRIEVED_VALUE < VALUES_["minValue"] or RETRIEVED_VALUE > VALUES_["maxValue"]:
				if IDENTIFIER == "MaxFPS" and RETRIEVED_VALUE == 0:
					return true
				return false
	return true

func _apply_settings() -> void:
	return
