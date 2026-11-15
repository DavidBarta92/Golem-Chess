extends ArtworkCroppedButton

## A main menu button drawn into the room that the story unlocks
## (StoryFeatures). Until then, by locked_look, it is
##   SHOWN   - there, but takes no clicks (the collection)
##   HIDDEN  - not there at all, nor its extras (the puzzles' parcel, the
##             Bourse's notices)
##   COVERED - under its cover drawing, which hides it (the phone, the drawing
##             things)
## Once unlocked it pops on hover and opens target_scene_path. The glow behind
## a button that is new to the player is its FeatureHint's; the hint leaves
## locking to this script (lock_target_until_unlocked off), since a button can
## also stay off for a reason of its own (available).
##
## When the menu opens, every button fades in while the room draws itself
## (MainMenu). A cover comes in alone, and the button behind it is put there
## only once the cover is whole, so it never shows through.

enum LockedLook { SHOWN, HIDDEN, COVERED }

## The story unlock this button waits for; empty for none.
@export var feature_id: String = ""
@export var locked_look: LockedLook = LockedLook.SHOWN
## The drawing over the button while it is locked (COVERED).
@export var cover_path: NodePath
## Drawings that come and go with the button (HIDDEN): the Bourse's notices
## on the wall.
@export var extra_paths: Array[NodePath] = []
@export_file("*.tscn") var target_scene_path: String = ""
## Off: unlocked, the button shows, but takes no clicks yet - for a screen
## that is still to be built (the phone, until matches with friends are).
@export var available: bool = true

var _cover: CanvasItem
var _extras: Array[CanvasItem] = []

func _ready() -> void:
	super()
	_cover = get_node_or_null(cover_path) as CanvasItem
	for path in extra_paths:
		var extra := get_node_or_null(path) as CanvasItem
		if extra != null:
			_extras.append(extra)
	# A feature can also be unlocked with the menu open (the developer window).
	StoryProgressStore.feature_unlocked.connect(_on_feature_unlocked)
	_apply_story_state()

func is_unlocked() -> bool:
	var id: String = feature_id.strip_edges()
	return id.is_empty() or StoryProgressStore.is_feature_unlocked(id)

func _apply_story_state() -> void:
	var unlocked: bool = is_unlocked()
	disabled = !unlocked or !available
	match locked_look:
		LockedLook.HIDDEN:
			visible = unlocked
			for extra in _extras:
				extra.visible = unlocked
		LockedLook.COVERED:
			if _cover != null:
				_cover.visible = !unlocked

func _on_feature_unlocked(unlocked_feature_id: String) -> void:
	if unlocked_feature_id == feature_id.strip_edges():
		_apply_story_state()

func play_intro(delay: float, seconds: float) -> void:
	if _cover != null and _cover.visible:
		modulate.a = 0.0
		_intro_tween = _fade_in([_cover], delay, seconds)
		_intro_tween.chain().tween_property(self, "modulate:a", 1.0, 0.0)
		return
	if !visible:
		return
	var items: Array = [self]
	for extra in _extras:
		if extra.visible:
			items.append(extra)
	_intro_tween = _fade_in(items, delay, seconds)

func _on_pressed() -> void:
	super()
	if !target_scene_path.is_empty():
		SceneTransition.change_scene(target_scene_path)
