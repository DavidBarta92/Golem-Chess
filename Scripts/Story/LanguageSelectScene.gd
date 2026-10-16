extends Control

## The very first thing a new player sees: pick a language, and the story
## begins. Writes the choice where the settings menu keeps it, so the two never
## disagree, then completes its story node.
##
## Deliberately bare - this screen is a placeholder for a proper first-run
## panel, and only the language part is real.

## Keys must match LanguageElement: section, identifier and the option labels
## the settings menu stores.
const SETTINGS_SECTION: String = "UI"
const SETTINGS_IDENTIFIER: String = "Language"
const OPTIONS: Dictionary = {
	"English": "en",
	"Magyar": "hu",
}

@onready var buttons: VBoxContainer = $ArtFrame/Layout/Buttons

var _is_choosing: bool = false

func _ready() -> void:
	for option_label in OPTIONS:
		var button := Button.new()
		button.name = option_label
		button.custom_minimum_size = Vector2(260.0, 56.0)
		button.text = option_label
		button.pressed.connect(_on_option_pressed.bind(option_label))
		buttons.add_child(button)

func _on_option_pressed(option_label: String) -> void:
	if _is_choosing:
		return
	_is_choosing = true
	_apply_language(option_label)
	StoryManager.finish_current_node()

func _apply_language(option_label: String) -> void:
	var locale: String = str(OPTIONS.get(option_label, "en"))
	TranslationServer.set_locale(locale)

	# Same store the settings menu reads on load, so reopening Settings shows
	# the language that was picked here.
	if !SettingsDataManager.settingsData_.has(SETTINGS_SECTION):
		SettingsDataManager.settingsData_[SETTINGS_SECTION] = {}
	SettingsDataManager.settingsData_[SETTINGS_SECTION][SETTINGS_IDENTIFIER] = option_label
	SettingsDataManager.save_data()
