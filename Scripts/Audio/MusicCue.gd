@tool
extends Resource
class_name MusicCue

## One change to what the music is doing: some stems fading up or down, and
## optionally the ambience bed being pushed back or brought forward with them.
##
## The music is a set of stems under Audio/Music/ that all play the whole time,
## in lock-step, each at its own level (see MusicManager). Nothing is ever
## started or stopped - a cue only moves levels - so whatever comes in lands
## exactly in time with what is already playing.
##
## Cues are authored on whatever triggers them: a comic panel, a dialogue line,
## a page's start or finish, the tutorial intro, a boss, a menu scene.

const MUSIC_DIR: String = "res://Audio/Music/"
const VALID_EXTENSIONS: Array[String] = ["wav", "ogg", "mp3"]
## A stem name that stands for every stem at once.
const ALL_STEMS: String = "*"

enum AmbienceFilter { UNCHANGED, OPEN, MUFFLED }

@export var fades: Array[MusicStemFade] = []

@export_group("Ambience")
## OPEN is the plain street noise; MUFFLED keeps only the low end, as if heard
## from far away or through a wall.
@export var ambience_filter: AmbienceFilter = AmbienceFilter.UNCHANGED
## Off leaves the ambience as loud as it already is.
@export var set_ambience_volume: bool = false
## 0 is the ambience at its normal level. Only used with set_ambience_volume.
@export_range(-40.0, 6.0, 0.5) var ambience_volume_db: float = 0.0
@export_range(0.0, 60.0, 0.1) var ambience_fade_seconds: float = 3.0

## Every stem file in the music folder, sorted by name. ResourceLoader rather
## than DirAccess: exported builds only ship the *.wav.import stubs, not the
## original *.wav files.
static func find_stem_paths() -> Array[String]:
	var paths: Array[String] = []
	var file_names: PackedStringArray = ResourceLoader.list_directory(MUSIC_DIR)
	file_names.sort()
	for file_name in file_names:
		if VALID_EXTENSIONS.has(file_name.get_extension().to_lower()):
			paths.append(MUSIC_DIR + file_name)
	return paths

## What a cue calls a stem: its file name without the extension.
static func stem_name_of(path: String) -> String:
	return path.get_file().get_basename()

static func find_stem_names() -> PackedStringArray:
	var names := PackedStringArray()
	for path in find_stem_paths():
		names.append(stem_name_of(path))
	return names
