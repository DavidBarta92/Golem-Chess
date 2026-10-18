extends Node

const AMBIENCE_DIR: String = "res://Audio/Ambience/"
const BUS_NAME: String = "Ambience"
const VALID_EXTENSIONS: Array[String] = ["wav", "ogg", "mp3"]
## When a track is about to end, the next one - drawn at random from the
## folder - starts this long before the end, and the two overlap: the old one
## fades away while the new one comes up.
const CROSSFADE_DURATION: float = 5.0
const SILENT_VOLUME_DB: float = -80.0
const MUFFLED_CUTOFF_HZ: float = 700.0
const OPEN_CUTOFF_HZ: float = 20000.0
## Where the bed sits normally. Story cues (set_volume_db) are relative to
## this. Set by ear against the music with a street recording at -37 dBFS
## RMS, where -4 was right; Subn_Residential_Area is -44, so it gets the 7 dB
## back to sit at the same place under the music. A new recording that is
## much louder or quieter than that will want this looked at again.
const NORMAL_LEVEL_DB: float = 3.0

var _tracks: Array[AudioStream] = []
var _players: Array[AudioStreamPlayer] = []
var _active_player_index: int = 0
var _last_track_index: int = -1
var _crossfade_in_progress: bool = false
var _lowpass_filter: AudioEffectLowPassFilter
var _lowpass_tween: Tween
## Pushes the whole bed back or forward for a story beat (MusicCue). An effect
## on the bus rather than the players' own volume, which the crossfade owns,
## and rather than the bus volume, which is the player's setting.
var _level_effect: AudioEffectAmplify
var _level_tween: Tween

func _ready() -> void:
	_scan_ambience_directory()
	_build_players()
	_setup_lowpass_filter()
	_setup_level_effect()
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

## 0 is the bed at its normal level (NORMAL_LEVEL_DB).
func set_volume_db(volume_db: float, duration: float = 0.0) -> void:
	if _level_effect == null:
		return
	if _level_tween != null and _level_tween.is_valid():
		_level_tween.kill()

	var target_db: float = NORMAL_LEVEL_DB + volume_db
	if duration <= 0.0:
		_level_effect.volume_db = target_db
		return

	_level_tween = create_tween()
	_level_tween.tween_property(_level_effect, "volume_db", target_db, duration)

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
	# ResourceLoader.list_directory instead of DirAccess: exported builds only
	# ship the *.wav.import stubs, not the original *.wav files.
	for file_name in ResourceLoader.list_directory(AMBIENCE_DIR):
		if !VALID_EXTENSIONS.has(file_name.get_extension().to_lower()):
			continue
		var stream: AudioStream = load(AMBIENCE_DIR + file_name)
		if stream != null:
			_play_through_once(stream)
			_tracks.append(stream)

## The crossfade is what carries the bed on from one track to the next, so a
## track must actually reach its end rather than loop on its own - the
## importer can bring a WAV in as looping.
func _play_through_once(stream: AudioStream) -> void:
	var wav := stream as AudioStreamWAV
	if wav != null:
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif "loop" in stream:
		stream.set("loop", false)

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

## Added at runtime, so the bus layout stays as authored.
func _setup_level_effect() -> void:
	var bus_index: int = AudioServer.get_bus_index(BUS_NAME)
	if bus_index == -1:
		return
	_level_effect = AudioEffectAmplify.new()
	_level_effect.volume_db = NORMAL_LEVEL_DB
	AudioServer.add_bus_effect(bus_index, _level_effect)

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
	tween.tween_method(Callable(self, "_set_crossfade").bind(outgoing_player, incoming_player), 0.0, 1.0, CROSSFADE_DURATION)
	tween.tween_callback(Callable(self, "_finish_crossfade").bind(outgoing_player, incoming_index))

## Equal-power: the two tracks together stay as loud as one all the way
## across. Fading volume_db in a straight line instead would keep the new
## track inaudible for most of the five seconds and leave a hole in the middle.
func _set_crossfade(progress: float, outgoing_player: AudioStreamPlayer, incoming_player: AudioStreamPlayer) -> void:
	outgoing_player.volume_db = _gain_to_db(cos(progress * PI * 0.5))
	incoming_player.volume_db = _gain_to_db(sin(progress * PI * 0.5))

func _gain_to_db(gain: float) -> float:
	return maxf(linear_to_db(gain), SILENT_VOLUME_DB) if gain > 0.0 else SILENT_VOLUME_DB

func _finish_crossfade(outgoing_player: AudioStreamPlayer, incoming_index: int) -> void:
	outgoing_player.stop()
	_active_player_index = incoming_index
	_crossfade_in_progress = false
