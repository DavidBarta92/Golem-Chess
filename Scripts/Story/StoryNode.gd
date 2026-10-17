extends Resource
class_name StoryNode

@export var id: String = ""
@export var display_name: String = ""

@export_group("Flow")
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

## Where to go after this node completes when it does not auto-continue.
## Empty means the hub. Set it when a beat should land the player somewhere
## specific - the Buy Pack explainer, for instance, drops them into the
## Collection right next to the button it just introduced.
##
## Story nodes name their scenes by path, never as a PackedScene: the
## StoryManager autoload loads the whole story definition at startup, and a
## PackedScene reference would load that scene and all of its art right then
## and keep it in memory for the whole session. The inspector may store the
## path as a uid://; resolve it with ResourceUID.ensure_path().
@export_file("*.tscn") var completion_scene_path: String = ""

@export_group("Unlocks")
## A StoryFeatures id (a menu button) that becomes usable once this node is
## completed. Empty means nothing.
@export var unlocks_feature: String = ""
## Pack ids that become purchasable once this node is completed.
@export var unlocks_packs: Array[String] = []

@export_group("Debug")
@export var force_completed: bool = false
