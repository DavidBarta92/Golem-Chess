extends StoryNode
class_name RandomMatchStoryNode

## A block of warm-up matches against generated opponents, between bosses.
##
## Each press of Play starts one match: a random name, face and single-set
## deck from the Decks/ database, at the difficulty of the last boss beaten.
## Win or lose, the match ends back at the hub. The node completes once
## `match_count` matches have been *started* - the player never has to win
## one - and the next Play moves the story on.
##
## Progress is the existing per-node attempt counter in the save, so this
## needs no state of its own.

@export_range(1, 10, 1) var match_count: int = 1

## Optional: fix the difficulty instead of inheriting it from the last boss.
## 0 means inherit.
@export_range(0, 12, 1) var difficulty_override: int = 0
