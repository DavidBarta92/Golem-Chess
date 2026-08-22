extends Control
class_name SettingsSection

@export var IDENTIFIER: String

var ELEMENT_REFERENCE_TABLE_: Dictionary = {}

func _ready() -> void:
	SettingsDataManager.SECTION_REFERENCE_TABLE_[IDENTIFIER] = self
	if SettingsDataManager.noSaveFile:
		SettingsDataManager.settingsData_[IDENTIFIER] = {}

func load_all() -> void:
	for element in ELEMENT_REFERENCE_TABLE_.values():
		element.load_settings()

func apply_all() -> void:
	if not SettingsDataManager.settingsData_.has(IDENTIFIER):
		SettingsDataManager.settingsData_[IDENTIFIER] = {}

	for identifier in ELEMENT_REFERENCE_TABLE_:
		var element: SettingsElement = ELEMENT_REFERENCE_TABLE_[identifier]
		SettingsDataManager.settingsData_[IDENTIFIER][identifier] = element.currentValue
		element._apply_settings()
