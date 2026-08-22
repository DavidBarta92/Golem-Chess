extends SettingsElement
class_name PlayerPortraitElement

func _init() -> void:
	IDENTIFIER = "PlayerPortrait"

func get_valid_values() -> Dictionary:
	return {"defaultValue": PortraitLibrary.get_default_player_portrait().to_dict()}

func is_valid_value(_VALUES_: Dictionary, _RETRIEVED_VALUE) -> bool:
	return true

func init_element() -> void:
	currentValue = PortraitLibrary.config_from_data_or_default(currentValue, 0).to_dict()

func _apply_settings() -> void:
	GameConfig.set_local_portrait_data(currentValue)

func get_portrait_data() -> Dictionary:
	var data: Dictionary = currentValue
	return data.duplicate(true)

func set_portrait_data(data: Dictionary) -> void:
	currentValue = PortraitLibrary.config_from_data_or_default(data, 0).to_dict()
