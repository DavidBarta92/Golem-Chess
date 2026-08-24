extends Resource
class_name StoryDefinition

@export var chapters: Array[StoryChapter] = []

## Debug-only: while set, every node before the matching id is treated as
## completed on load, so play can start from that point. Ignored in release
## (non-debug) builds. Clear the field when you're done testing.
@export_group("Debug")
@export var debug_jump_to_node_id: String = ""
