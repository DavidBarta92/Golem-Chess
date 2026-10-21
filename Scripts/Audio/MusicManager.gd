extends Node

## The music bed: every stem under Audio/Music/ playing at once, in lock-step,
## each at its own level. The stems start silent with the game and never stop;
## the story and the menus only fade them up and down through MusicCue
## resources, so the music never restarts and a stem that comes in lands on the
## beat of whatever is already playing.

const BUS_NAME: String = "Music"
const SILENT_VOLUME_DB: float = -80.0
## The stems are mastered quiet - peaks between -18 and -33 dBFS, all eight
## together still only -17 - so the whole bed is lifted by this much to sit
## over the ambience. All eight at once peak around -11 dBFS with it; +12
## was tried and sounded crackly.
const MUSIC_GAIN_DB: float = 6.0
## AudioStreamSynchronized holds at most this many streams.
const MAX_STEMS: int = 32
## Stems whose loop point can be heard - the end of the file does not run
## cleanly into its start - and how many seconds either side of that point to
## do something about it.
##
## These used to be faded down and back up across the seam. That was worse
## than the seam: a dip is a hole, and the ear finds a hole exactly as easily
## as it finds a join, so the loop was still obvious - only now it breathed.
## The fade is gone; what is left is the reverb below, which fills the moment
## instead of emptying it.
const LOOP_SEAM_SECONDS: Dictionary = {
	"chords_dreamy": 3.0,
}
## A reverb that opens only around the loop point. The bars before the seam
## leave a tail that is still ringing when the stem starts again, so the
## restart has something to arrive under rather than arriving in the clear.
##
## `dry` stays at 1, so away from the seam the effect is literally inaudible:
## the wet send is at zero and nothing else changes. For the few seconds it is
## open it washes every stem, not only the one looping - the stems share one
## player and so one bus, and there is no way to send a single stem.
##
## This is a mask, not a cure. A stem whose last bar ran into its first would
## need none of it.
const LOOP_REVERB_WET: float = 0.5
const LOOP_REVERB_ROOM_SIZE: float = 0.85
const LOOP_REVERB_DAMPING: float = 0.4
## Below this the send is switched off outright rather than left at a trickle.
const LOOP_REVERB_EPSILON: float = 0.01

## One stem's level, as an object so a tween can drive it. A property tween
## reads its starting value when it starts rather than when it is built, which
## is what lets a delayed fade pick up from wherever the earlier one left off.
class Stem extends RefCounted:
	var stream: AudioStreamSynchronized
	var index: int
	var tween: Tween
	## Seconds; only used by a stem listed in LOOP_SEAM_SECONDS.
	var length: float = 0.0
	var seam_seconds: float = 0.0
	## 0 is silent, 1 is the stem as rendered. What the cues drive, and the
	## only thing that touches a stem's level - nothing dips it behind their
	## backs any more.
	var level: float = 0.0:
		set(value):
			level = clampf(value, 0.0, 1.0)
			_apply()

	func _apply() -> void:
		# Squared, so a fade sounds even all the way through instead of
		# rushing up at the start and dropping off a cliff at the end.
		var volume_db: float = linear_to_db(level * level) if level > 0.0 else SILENT_VOLUME_DB
		stream.set_sync_stream_volume(index, maxf(volume_db, SILENT_VOLUME_DB))

var _player: AudioStreamPlayer
var _synchronized_stream: AudioStreamSynchronized
var _stems: Dictionary = {}
var _seam_stems: Array[Stem] = []
var _loop_reverb: AudioEffectReverb
var _loop_reverb_index: int = -1
var _loop_reverb_wet: float = -1.0
var _warned_stem_names: Dictionary = {}
var _mute_tween: Tween
var _is_muted: bool = false

func _ready() -> void:
	var stem_paths: Array[String] = MusicCue.find_stem_paths()
	if stem_paths.size() > MAX_STEMS:
		push_warning("MusicManager: %d stems in %s, only the first %d are played." % [
			stem_paths.size(), MusicCue.MUSIC_DIR, MAX_STEMS])
		stem_paths.resize(MAX_STEMS)

	_synchronized_stream = AudioStreamSynchronized.new()
	_synchronized_stream.stream_count = stem_paths.size()
	for i in range(stem_paths.size()):
		var stream: AudioStream = load(stem_paths[i])
		_loop_seamlessly(stream)
		_synchronized_stream.set_sync_stream(i, stream)
		var stem := Stem.new()
		stem.stream = _synchronized_stream
		stem.index = i
		stem.level = 0.0
		var stem_name: String = MusicCue.stem_name_of(stem_paths[i])
		_stems[stem_name] = stem
		if LOOP_SEAM_SECONDS.has(stem_name) and stream.get_length() > 0.0:
			stem.length = stream.get_length()
			stem.seam_seconds = float(LOOP_SEAM_SECONDS[stem_name])
			_seam_stems.append(stem)
	set_process(!_seam_stems.is_empty())

	_player = AudioStreamPlayer.new()
	_player.bus = BUS_NAME
	_player.stream = _synchronized_stream
	_player.volume_db = MUSIC_GAIN_DB
	add_child(_player)

	if !stem_paths.is_empty():
		# The stems loop on their own; this only catches one that does not.
		_player.finished.connect(Callable(_player, "play"))
		_player.play()

## Follows the loop points, so the reverb knows when one is coming. The
## position comes from the player rather than from a clock of our own, so it
## stays on the audio however long the game runs; wrapped by the stem's length
## in case the player reports the time since play() rather than within the
## loop. Nothing here changes any stem's level.

func _process(_delta: float) -> void:
	if _player == null or !_player.playing:
		return
	var position: float = _player.get_playback_position()
	# 1 well clear of any loop point, 0 right on one.
	var clearance: float = 1.0
	for stem in _seam_stems:
		var within_loop: float = fposmod(position, stem.length)
		var to_edge: float = minf(within_loop, stem.length - within_loop)
		clearance = minf(clearance, clampf(to_edge / stem.seam_seconds, 0.0, 1.0))
	_set_loop_reverb(1.0 - clearance)

## Opens the reverb send as a loop point comes up and closes it again after.
## The effect is built on first use, so a game with no edge-faded stem never
## pays for it.
func _set_loop_reverb(amount: float) -> void:
	var wet: float = clampf(amount, 0.0, 1.0) * LOOP_REVERB_WET
	if is_equal_approx(wet, _loop_reverb_wet):
		return
	_loop_reverb_wet = wet

	var bus_index: int = AudioServer.get_bus_index(BUS_NAME)
	if bus_index < 0:
		return
	if _loop_reverb == null:
		if wet < LOOP_REVERB_EPSILON:
			return
		_loop_reverb = AudioEffectReverb.new()
		_loop_reverb.room_size = LOOP_REVERB_ROOM_SIZE
		_loop_reverb.damping = LOOP_REVERB_DAMPING
		# The dry path is untouched, so the send adds to the bed rather than
		# replacing any of it.
		_loop_reverb.dry = 1.0
		_loop_reverb.wet = 0.0
		AudioServer.add_bus_effect(bus_index, _loop_reverb)
		# Remembered rather than looked up again: the slot is only the last one
		# until something else is added to the bus.
		_loop_reverb_index = AudioServer.get_bus_effect_count(bus_index) - 1
	_loop_reverb.wet = wet
	if _loop_reverb_index >= 0:
		AudioServer.set_bus_effect_enabled(bus_index, _loop_reverb_index, wet >= LOOP_REVERB_EPSILON)

## Plays a cue: its stem fades and its ambience change. A fade replaces
## whatever that stem was already doing; stems the cue does not name carry on.
func apply_cue(cue: MusicCue) -> void:
	if cue == null:
		return

	var fades_by_stem: Dictionary = {}
	for fade in cue.fades:
		if fade == null:
			continue
		for stem in _resolve_stems(fade.stem):
			if !fades_by_stem.has(stem):
				fades_by_stem[stem] = []
			fades_by_stem[stem].append(fade)
	for stem in fades_by_stem:
		_run_fades(stem, fades_by_stem[stem])

	_apply_ambience(cue)

## Fades one stem fully up (fade_in) or down over `seconds`.
func fade_stem(stem_name: String, fade_in: bool, seconds: float, delay_seconds: float = 0.0) -> void:
	var fade := MusicStemFade.new()
	fade.stem = stem_name
	fade.direction = MusicStemFade.Direction.IN if fade_in else MusicStemFade.Direction.OUT
	fade.seconds = seconds
	fade.delay_seconds = delay_seconds
	for stem in _resolve_stems(stem_name):
		_run_fades(stem, [fade])

func is_stem_audible(stem_name: String) -> bool:
	var stem: Stem = _stems.get(stem_name)
	return stem != null and stem.level > 0.0

## Fades the whole music bed out, or back in, without touching the stem levels
## or the player's volume setting (that lives on the bus). A comic page with
## music_mode SILENT uses this.
func set_muted(muted: bool, fade_seconds: float = 0.0) -> void:
	if _player == null:
		return
	_is_muted = muted
	if _mute_tween != null and _mute_tween.is_valid():
		_mute_tween.kill()

	var target_db: float = SILENT_VOLUME_DB if muted else MUSIC_GAIN_DB
	if fade_seconds <= 0.0:
		_player.volume_db = target_db
		return
	_mute_tween = create_tween()
	_mute_tween.tween_property(_player, "volume_db", target_db, fade_seconds)

func is_muted() -> bool:
	return _is_muted

## The stems were rendered as one loop with no loop points in the files, so
## the loop is set up here instead of in each file's import settings - a stem
## dropped into the folder loops without anyone remembering to tick it.
## A real loop authored in the file or the import dock is left alone. Note
## that the importer brings these files in as looping with a loop end of 0
## (their smpl chunk holds no loops), which would never wrap, so "looping" is
## not enough on its own to count as authored.
func _loop_seamlessly(stream: AudioStream) -> void:
	var wav := stream as AudioStreamWAV
	if wav == null:
		if "loop" in stream:
			stream.set("loop", true)
		return
	if wav.loop_mode != AudioStreamWAV.LOOP_DISABLED and wav.loop_end > wav.loop_begin:
		return
	wav.loop_begin = 0
	wav.loop_end = int(round(wav.get_length() * wav.mix_rate))
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD

## Every fade a cue has for one stem, chained on a single tween in delay
## order, so a later one waits for the earlier one instead of cutting it off.
func _run_fades(stem: Stem, fades: Array) -> void:
	fades.sort_custom(func(a: MusicStemFade, b: MusicStemFade) -> bool:
		return a.delay_seconds < b.delay_seconds)

	if stem.tween != null and stem.tween.is_valid():
		stem.tween.kill()
	stem.tween = create_tween()
	var elapsed: float = 0.0
	for fade: MusicStemFade in fades:
		if fade.delay_seconds > elapsed:
			stem.tween.tween_interval(fade.delay_seconds - elapsed)
			elapsed = fade.delay_seconds
		var target: float = 1.0 if fade.direction == MusicStemFade.Direction.IN else 0.0
		stem.tween.tween_property(stem, "level", target, maxf(fade.seconds, 0.0))
		elapsed += maxf(fade.seconds, 0.0)

func _resolve_stems(stem_name: String) -> Array:
	var cleaned: String = stem_name.strip_edges()
	if cleaned == MusicCue.ALL_STEMS:
		return _stems.values()
	if _stems.has(cleaned):
		return [_stems[cleaned]]
	if !_warned_stem_names.has(cleaned):
		_warned_stem_names[cleaned] = true
		push_warning("MusicManager: no stem called '%s' in %s." % [cleaned, MusicCue.MUSIC_DIR])
	return []

func _apply_ambience(cue: MusicCue) -> void:
	match cue.ambience_filter:
		MusicCue.AmbienceFilter.OPEN:
			AmbienceManager.set_muffled(false, cue.ambience_fade_seconds)
		MusicCue.AmbienceFilter.MUFFLED:
			AmbienceManager.set_muffled(true, cue.ambience_fade_seconds)
		_:
			pass
	if cue.set_ambience_volume:
		AmbienceManager.set_volume_db(cue.ambience_volume_db, cue.ambience_fade_seconds)
