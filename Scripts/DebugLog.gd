extends RefCounted
class_name DebugLog

const ENABLED: bool = false

static func info(message: String) -> void:
	if ENABLED:
		print(message)
