extends Resource
class_name StoryNode

@export var id: String = ""
@export var display_name: String = ""
@export var unlocks_feature: String = ""

## If true, finishing this node immediately starts the next one (chained,
## no hub in between - e.g. a comic intro sliding straight into its boss
## fight). If false, finishing it returns to the hub scene and the story
## only continues the next time the player re-enters it (e.g. after a
## boss fight, back to the main menu until "Play" is pressed again).
@export var auto_continue_after_completion: bool = false

## If true and this node isn't completed yet, launching the game jumps
## straight to it instead of showing the hub (main menu) - for mandatory
## onboarding like the base tutorial. Leave false for anything that should
## only start when the player presses Play from the hub.
@export var blocks_hub_until_completed: bool = false

@export_group("Debug")
@export var force_completed: bool = false
