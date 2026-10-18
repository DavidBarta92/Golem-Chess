extends Node
class_name SceneMusicCue

## Plays a MusicCue as the scene it sits in opens - how a menu says what the
## music should be doing while it is up. Drop one into the scene and fill in
## the cue.

@export var cue: MusicCue
## Off leaves it to the scene's own script to call play(). For a scene that
## can hand straight over to another before it is ever seen: the Main Menu is
## the game's first scene and forwards to the story while the hub is locked,
## and its music must not start under the story.
@export var play_on_ready: bool = true

func _ready() -> void:
	if play_on_ready:
		play()

func play() -> void:
	MusicManager.apply_cue(cue)
