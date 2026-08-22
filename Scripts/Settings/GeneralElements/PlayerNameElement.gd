extends TextElement
class_name PlayerNameElement

func _init() -> void:
	IDENTIFIER = "PlayerName"
	DEFAULT_VALUE = GameConfig.DEFAULT_PLAYER_NAME

func _ready() -> void:
	super._ready()
	TextRef.placeholder_text = GameConfig.DEFAULT_PLAYER_NAME
	TextRef.max_length = GameConfig.MAX_PLAYER_NAME_LENGTH

func init_element() -> void:
	currentValue = GameConfig.sanitize_player_name(currentValue)
	super.init_element()
	GameConfig.set_local_player_name(currentValue)

func _apply_settings() -> void:
	currentValue = GameConfig.sanitize_player_name(TextRef.text)
	TextRef.text = currentValue
	GameConfig.set_local_player_name(currentValue)
