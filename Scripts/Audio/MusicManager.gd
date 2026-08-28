extends Node

const MUSIC_DIR: String = "res://Audio/Music/"
const BUS_NAME: String = "Music"
const VALID_EXTENSIONS: Array[String] = ["wav", "ogg", "mp3"]
const TRACK_COUNT: int = 3

var _player: AudioStreamPlayer
var _synchronized_stream: AudioStreamSynchronized

func _ready() -> void:
	_synchronized_stream = AudioStreamSynchronized.new()
	_synchronized_stream.stream_count = TRACK_COUNT

	var stem_paths: Array[String] = _find_stem_paths()
	for i in range(mini(TRACK_COUNT, stem_paths.size())):
		_synchronized_stream.set_sync_stream(i, load(stem_paths[i]))

	_player = AudioStreamPlayer.new()
	_player.bus = BUS_NAME
	_player.stream = _synchronized_stream
	add_child(_player)

	if !stem_paths.is_empty():
		_player.finished.connect(Callable(_player, "play"))
		_player.play()

func set_stem_volume(stem_index: int, volume_db: float) -> void:
	if _synchronized_stream == null or stem_index < 0 or stem_index >= TRACK_COUNT:
		return
	_synchronized_stream.set_sync_stream_volume(stem_index, volume_db)

func _find_stem_paths() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(MUSIC_DIR)
	if dir == null:
		return paths

	var file_names: PackedStringArray = dir.get_files()
	file_names.sort()
	for file_name in file_names:
		if VALID_EXTENSIONS.has(file_name.get_extension().to_lower()):
			paths.append(MUSIC_DIR + file_name)
	return paths
