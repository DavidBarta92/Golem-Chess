extends RefCounted
class_name DebugLog

const ENABLED: bool = false
const NETWORK_LOG_ENABLED: bool = true
const NETWORK_LOG_PATH: String = "user://logs/multiplayer.log"

static func info(message: String) -> void:
	if ENABLED:
		print(message)

static func network(message: String) -> void:
	var line: String = "[NET] %s" % message
	if ENABLED:
		print(line)
	if NETWORK_LOG_ENABLED:
		_write_line(line)

static func network_error(message: String) -> void:
	var line: String = "[NET][ERROR] %s" % message
	if ENABLED:
		push_warning(line)
	if NETWORK_LOG_ENABLED:
		_write_line(line)

static func get_network_log_path() -> String:
	return ProjectSettings.globalize_path(NETWORK_LOG_PATH)

static func _write_line(message: String) -> void:
	var absolute_dir: String = ProjectSettings.globalize_path(NETWORK_LOG_PATH.get_base_dir())
	DirAccess.make_dir_recursive_absolute(absolute_dir)

	var file: FileAccess = null
	if FileAccess.file_exists(NETWORK_LOG_PATH):
		file = FileAccess.open(NETWORK_LOG_PATH, FileAccess.READ_WRITE)
		if file != null:
			file.seek_end()
	else:
		file = FileAccess.open(NETWORK_LOG_PATH, FileAccess.WRITE)

	if file == null:
		return

	var timestamp: String = Time.get_datetime_string_from_system(false, true)
	file.store_line("%s %s" % [timestamp, message])
