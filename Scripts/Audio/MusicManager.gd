extends Node

const MUSIC_DIR: String = "res://Audio/Music/"
const BUS_NAME: String = "Music"
const VALID_EXTENSIONS: Array[String] = ["wav", "ogg", "mp3"]
const TRACK_COUNT: int = 3

const SILENT_VOLUME_DB: float = -80.0

var _player: AudioStreamPlayer
var _synchronized_stream: AudioStreamSynchronized
var _mute_tween: Tween
var _is_muted: bool = false

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

## Fades the music bed out, or back in, without touching the player's volume
## setting (that lives on the bus). The opening comic runs on ambience alone.
func set_muted(muted: bool, fade_seconds: float = 0.0) -> void:
	if _player == null:
		return
	_is_muted = muted
	if _mute_tween != null and _mute_tween.is_valid():
		_mute_tween.kill()

	var target_db: float = SILENT_VOLUME_DB if muted else 0.0
	if fade_seconds <= 0.0:
		_player.volume_db = target_db
		return
	_mute_tween = create_tween()
	_mute_tween.tween_property(_player, "volume_db", target_db, fade_seconds)

func is_muted() -> bool:
	return _is_muted

func set_stem_volume(stem_index: int, volume_db: float) -> void:
	if _synchronized_stream == null or stem_index < 0 or stem_index >= TRACK_COUNT:
		return
	_synchronized_stream.set_sync_stream_volume(stem_index, volume_db)

func _find_stem_paths() -> Array[String]:
	var paths: Array[String] = []
	# ResourceLoader.list_directory instead of DirAccess: exported builds only
	# ship the *.wav.import stubs, not the original *.wav files.
	var file_names: PackedStringArray = ResourceLoader.list_directory(MUSIC_DIR)
	file_names.sort()
	for file_name in file_names:
		if VALID_EXTENSIONS.has(file_name.get_extension().to_lower()):
			paths.append(MUSIC_DIR + file_name)
	return paths
