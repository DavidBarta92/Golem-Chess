extends StoryNode
class_name RewardStoryNode

## The "you unlocked something" beat after a boss fight.
##
## Every reward is its own scene (see Scenes/Reward/) because they differ a
## lot: a coin payout, a stamp, a newly unlocked menu item with a character
## explaining it. What they share - the left-hand image + dialogue column,
## the payout guard, the feature unlocks - lives in RewardSceneBase.

@export var reward_scene: PackedScene
