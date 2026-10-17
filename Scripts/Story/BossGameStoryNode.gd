extends StoryNode
class_name BossGameStoryNode

## A story match against one of the authored opponents.
##
## The node itself carries almost nothing: who to fight lives in the
## BossDefinition .tres, so the same opponent can be reused (rematches, a
## boss rush) without duplicating their setup.

## What happens when the player loses.
##   PROMPT_RETRY     - a "play again right away?" prompt; yes restarts the
##                      fight, no returns to the hub. The normal case.
##   COMIC_THEN_RETRY - the defeat pages play, then the fight restarts with no
##                      way out. For the fights before the hub exists.
enum DefeatBehavior { PROMPT_RETRY, COMIC_THEN_RETRY }

@export var boss: BossDefinition

## Optional: forces the player into a specific saved deck for this fight.
## Leave empty to let the player bring whatever they have selected.
@export var force_player_deck_id: String = ""

@export_group("On defeat")
@export var defeat_behavior: DefeatBehavior = DefeatBehavior.PROMPT_RETRY
## Comic pages shown after a loss with COMIC_THEN_RETRY (ignored otherwise).
## Paths, like ComicStoryNode.page_paths.
@export_file("*.tscn") var defeat_page_paths: Array[String] = []

func get_boss_display_name() -> String:
	return boss.get_display_name() if boss != null else display_name
