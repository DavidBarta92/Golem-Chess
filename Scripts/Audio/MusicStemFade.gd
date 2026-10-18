@tool
extends Resource
class_name MusicStemFade

## One stem of a MusicCue fading up or down.

enum Direction { IN, OUT }

## The stem's file name under Audio/Music/ without the extension ("chords"),
## or "*" for every stem at once. The inspector suggests what is in the folder.
@export var stem: String = ""
@export var direction: Direction = Direction.IN
@export_range(0.0, 120.0, 0.1) var seconds: float = 3.0
## Waits this long after the cue fires. Two fades on the same stem in one cue
## run one after the other in delay order, which is how "fade everything out,
## then bring this one back slowly" is written.
@export_range(0.0, 300.0, 0.1) var delay_seconds: float = 0.0

func _validate_property(property: Dictionary) -> void:
	if property.name != "stem":
		return
	var names: PackedStringArray = MusicCue.find_stem_names()
	names.append(MusicCue.ALL_STEMS)
	property.hint = PROPERTY_HINT_ENUM_SUGGESTION
	property.hint_string = ",".join(names)
