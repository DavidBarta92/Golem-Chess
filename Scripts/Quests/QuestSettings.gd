extends Resource
class_name QuestSettings

## The numbers behind the quests the game hands out by itself (QuestDirector,
## Docs/Quests/QUESTS.md), in res://Quests/quest_settings.tres.

@export_group("Daily")
## One a day: it comes with the first look at the bar on a new day and runs
## out at midnight.
@export var daily_reward: int = 80
@export_enum("coin", "draw") var daily_reward_kind: String = "coin"
## How much play a daily asks for, in matches (a match is about 5 minutes for
## a practised player, by the match logs).
@export var daily_budget_matches: float = 3.0

@export_group("Regular")
## Regular quests do not run out. One new a day while there are fewer than this.
@export var regular_max: int = 3
@export var regular_reward: int = 40
@export_enum("coin", "draw") var regular_reward_kind: String = "coin"
@export var regular_budget_matches: float = 1.5
## Swaps a day, for regular quests only (not the story's, not the daily).
@export var regular_swaps_per_day: int = 1
