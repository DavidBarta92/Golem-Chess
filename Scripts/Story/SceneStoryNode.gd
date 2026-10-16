extends StoryNode
class_name SceneStoryNode

## A story beat that is simply its own scene.
##
## For anything that is not a comic, a match or a reward screen: the language
## picker that opens the game, and later the quest and trade beats. The scene
## calls StoryManager.finish_current_node() when it is done; everything else
## (what comes next, where it lands) is the node's business, not the scene's.

@export var scene: PackedScene
