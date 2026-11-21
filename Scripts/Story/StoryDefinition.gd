extends Resource
class_name StoryDefinition

@export var chapters: Array[StoryChapter] = []

## How far this version's story goes. The node with this id and every node
## after it are locked: the story stops there as if it had ended - the Play
## window's story button goes inactive and a story quest from there on is not
## posted - until the unlock code is typed. Empty means the whole story is
## open. Move it on before an export to open more of the story. Unlike the
## Debug group, this holds in every build, the editor included.
@export_group("Release")
@export var locked_from_node_id: String = ""
## Typed on the main menu, it lifts the lock above for that save, for good.
## Letters as typed, case does not matter. Empty means the lock cannot be
## lifted.
@export var unlock_code: String = ""

## Debug-only: while set, every node before the matching id is treated as
## completed on load, so play can start from that point. Ignored in release
## (non-debug) builds. Clear the field when you're done testing.
@export_group("Debug")
@export var debug_jump_to_node_id: String = ""
