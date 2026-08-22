extends SliderElement
class_name VolumeElement

@export var AUDIO_BUS: String = "Master"

func _apply_settings() -> void:
	var bus_index: int = AudioServer.get_bus_index(AUDIO_BUS)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(currentValue))
