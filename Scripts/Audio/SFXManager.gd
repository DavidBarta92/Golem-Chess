extends Node

const SFX_DIR: String = "res://Audio/SFX/"
const BUS_NAME: String = "SFX"
const POOL_SIZE: int = 12
const VALID_EXTENSIONS: Array[String] = ["wav", "ogg", "mp3"]

var _groups: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player_index: int = 0
var _last_played_variant: Dictionary = {}

func _ready() -> void:
	_scan_sfx_directory()
	_build_player_pool()

func get_stream(sound_name: String) -> AudioStream:
	if !_groups.has(sound_name):
		return null

	var variants: Array = _groups[sound_name]
	if variants.is_empty():
		return null

	return _pick_variant(sound_name, variants)

func play(sound_name: String) -> AudioStreamPlayer:
	if !_groups.has(sound_name):
		return null

	var variants: Array = _groups[sound_name]
	if variants.is_empty():
		return null

	var player: AudioStreamPlayer = _get_free_player()
	player.stream = _pick_variant(sound_name, variants)
	player.play()
	return player

## The same sound, played slower and lower. Pitch below 1 stretches it as well
## as deepening it, which is how a short effect is made into a heavier one
## without a second recording.
##
## The pool hands the same players round, so the pitch is put back when the
## sound ends - otherwise the next thing to borrow that player would inherit it.
func play_pitched(sound_name: String, pitch: float) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = play(sound_name)
	if player == null:
		return null
	player.pitch_scale = maxf(0.01, pitch)
	player.finished.connect(func() -> void:
		if is_instance_valid(player):
			player.pitch_scale = 1.0
	, CONNECT_ONE_SHOT)
	return player

func _build_player_pool() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = BUS_NAME
		add_child(player)
		_players.append(player)

func _scan_sfx_directory() -> void:
	_groups.clear()
	# ResourceLoader.list_directory instead of DirAccess: exported builds only
	# ship the *.wav.import stubs, not the original *.wav files.
	for file_name in ResourceLoader.list_directory(SFX_DIR):
		if !VALID_EXTENSIONS.has(file_name.get_extension().to_lower()):
			continue

		var stream: AudioStream = load(SFX_DIR + file_name)
		if stream == null:
			continue

		var group_name: String = _get_group_name(file_name.get_basename())
		if !_groups.has(group_name):
			_groups[group_name] = []
		_groups[group_name].append(stream)

func _get_group_name(base_name: String) -> String:
	var last_underscore: int = base_name.rfind("_")
	if last_underscore == -1:
		return base_name
	if !base_name.substr(last_underscore + 1).is_valid_int():
		return base_name
	return base_name.substr(0, last_underscore)

func _pick_variant(sound_name: String, variants: Array) -> AudioStream:
	if variants.size() == 1:
		return variants[0]

	var index: int = randi() % variants.size()
	if _last_played_variant.get(sound_name) == index:
		index = (index + 1) % variants.size()
	_last_played_variant[sound_name] = index
	return variants[index]

func _get_free_player() -> AudioStreamPlayer:
	for i in range(_players.size()):
		var candidate_index: int = (_next_player_index + i) % _players.size()
		if !_players[candidate_index].playing:
			_next_player_index = (candidate_index + 1) % _players.size()
			return _players[candidate_index]

	var player: AudioStreamPlayer = _players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % _players.size()
	return player
