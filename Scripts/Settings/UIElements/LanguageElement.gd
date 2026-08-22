extends OptionElement
class_name LanguageElement

func _init() -> void:
	IDENTIFIER = "Language"
	OPTION_LIST_ = {
		"English": "en",
		"Magyar": "hu",
	}
	DEFAULT_VALUE = "Magyar" if OS.get_locale_language() == "hu" else "English"

func _apply_settings() -> void:
	TranslationServer.set_locale(OPTION_LIST_[currentValue])
