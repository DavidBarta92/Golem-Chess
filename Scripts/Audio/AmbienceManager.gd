extends Node

const AMBIENCE_DIR: String = "res://Audio/Ambience/"
const BUS_NAME: String = "Ambience"
const VALID_EXTENSIONS: Array[String] = ["wav", "ogg", "mp3"]
const CROSSFADE_DURATION: float = 15.0
const SILENT_VOLUME_DB: float = -80.0
const MUFFLED_CUTOFF_HZ: float = 700.0
const OPEN_CUTOFF_HZ: float = 20000.0

var _tracks: Array[AudioStream] = []
var _players: Array[AudioStreamPlayer] = []
var _active_player_index: int = 0
var _last_track_index: int = -1
var _crossfade_in_progress: bool = false
var _lowpass_filter: AudioEffectLowPassFilter
var _lowpass_tween: Tween

func _ready() -> void:
	_scan_ambience_directory()
	_build_players()
	_setup_lowpass_filter()
	_play_track_on(_active_player_index)

func set_muffled(muffled: bool, duration: float = 0.0) -> void:
	if _lowpass_filter == null:
		return
	if _lowpass_tween != null and _lowpass_tween.is_valid():
		_lowpass_tween.kill()

	var target_cutoff: float = MUFFLED_CUTOFF_HZ if muffled else OPEN_CUTOFF_HZ
	if duration <= 0.0:
		_lowpass_filter.cutoff_hz = target_cutoff
		return

	_lowpass_tween = create_tween()
	_lowpass_tween.tween_property(_lowpass_filter, "cutoff_hz", target_cutoff, duration)

func _process(_delta: float) -> void:
	if _tracks.is_empty() or _crossfade_in_progress:
		return

	var active_player: AudioStreamPlayer = _players[_active_player_index]
	if !active_player.playing or active_player.stream == null:
		return

	var remaining: float = active_player.stream.get_length() - active_player.get_playback_position()
	if remaining <= CROSSFADE_DURATION:
		_start_crossfade()

func _scan_ambience_directory() -> void:
	_tracks.clear()
	var dir := DirAccess.open(AMBIENCE_DIR)
	if dir == null:
		return

	for file_name in dir.get_files():
		if !VALID_EXTENSIONS.has(file_name.get_extension().to_lower()):
			continue
		var stream: AudioStream = load(AMBIENCE_DIR + file_name)
		if stream != null:
			_tracks.append(stream)

func _build_players() -> void:
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = BUS_NAME
		add_child(player)
		_players.append(player)

func _setup_lowpass_filter() -> void:
	var bus_index: int = AudioServer.get_bus_index(BUS_NAME)
	if bus_index == -1:
		return

	for effect_index in range(AudioServer.get_bus_effect_count(bus_index)):
		var effect: AudioEffect = AudioServer.get_bus_effect(bus_index, effect_index)
		if effect is AudioEffectLowPassFilter:
			_lowpass_filter = effect
			break

	if _lowpass_filter != null:
		_lowpass_filter.cutoff_hz = MUFFLED_CUTOFF_HZ

func _play_track_on(player_index: int) -> void:
	if _tracks.is_empty():
		return
	var player: AudioStreamPlayer = _players[player_index]
	player.stream = _pick_next_track()
	player.volume_db = 0.0
	player.play()

func _pick_next_track() -> AudioStream:
	var index: int = randi() % _tracks.size()
	if _tracks.size() > 1 and index == _last_track_index:
		index = (index + 1) % _tracks.size()
	_last_track_index = index
	return _tracks[index]

func _start_crossfade() -> void:
	_crossfade_in_progress = true
	var outgoing_player: AudioStreamPlayer = _players[_active_player_index]
	var incoming_index: int = 1 - _active_player_index
	var incoming_player: AudioStreamPlayer = _players[incoming_index]

	incoming_player.stream = _pick_next_track()
	incoming_player.volume_db = SILENT_VOLUME_DB
	incoming_player.play()

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(outgoing_player, "volume_db", SILENT_VOLUME_DB, CROSSFADE_DURATION)
	tween.tween_property(incoming_player, "volume_db", 0.0, CROSSFADE_DURATION)
	tween.chain().tween_callback(Callable(self, "_finish_crossfade").bind(outgoing_player, incoming_index))

func _finish_crossfade(outgoing_player: AudioStreamPlayer, incoming_index: int) -> void:
	outgoing_player.stop()
	_active_player_index = incoming_index
	_crossfade_in_progress = false
