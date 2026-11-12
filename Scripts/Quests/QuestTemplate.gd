@tool
extends Resource
class_name QuestTemplate

## One kind of daily or regular quest the game hands out by itself
## (QuestDirector, Docs/Quests/QUESTS.md). The template says what is asked
## (`condition`, and the XY values `param_pool` may pick from) and how much a
## match's worth of play yields of it (`per_match`); the director turns that
## into the quest's X from the budget in QuestSettings. Story quests are not
## templates: they are written on their story node (QuestStoryNode).
##
## Save new ones under res://Quests/Templates/ (subfolders are fine); every
## enabled one there is in the draw.

const POOL_DAILY: int = 1
const POOL_REWARD: int = 2

## The save remembers which template a quest came from by this; keep it once
## the template has shipped.
@export var template_id: String = ""
@export var enabled: bool = true
@export var condition: QuestCondition.Type = QuestCondition.Type.WIN_MATCHES:
	set(value):
		condition = value
		notify_property_list_changed()
## Which quests it may become: daily ones, regular ones, or both.
@export_flags("Daily", "Regular") var pools: int = POOL_DAILY | POOL_REWARD
## How likely it is drawn, next to the others that could be.
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0

@export_group("Size")
## How many of the condition one match's worth of play brings, measured from
## the match logs (Docs/Quests/QUESTS.md): about 0.55 wins, 7 stamps affixed.
## For things done outside matches, how many fit into the time of a match.
@export var per_match: float = 1.0
@export_range(1, 999) var min_count: int = 1
@export_range(1, 999) var max_count: int = 10
## Counts are rounded to this: 20 stamps rather than 21.
@export_range(1, 50) var round_to: int = 1

@export_group("Parameter")
## The XY values to choose from (QuestCondition.param_options, or stamp
## names); one is picked among those the player can do. Empty: any, or for a
## condition that needs one (QuestCondition.needs_param), one picked from the
## player's codexes and collection (QuestCondition.dynamic_params).
@export var param_pool: Array[String] = []

@export_group("Story")
## StoryFeatures ids that must be unlocked before it is handed out, on top of
## what the condition itself needs (QuestCondition.is_available).
@export var requires_features: Array[String] = []

@export_group("Text")
## Translation keys (or plain text); empty: the condition's own
## (QuestCondition.default_title / default_text). The text may use {count}
## and {param}, with the exact condition in <b>...</b>. A key with a _ONE form
## in the language files uses it for a count of one.
@export var title: String = ""
@export_multiline var text: String = ""

## The quest's X for a budget of `matches` matches' worth of play.
func count_for_budget(matches: float) -> int:
	var raw: float = matches * per_match
	var step: int = maxi(1, round_to)
	var count: int = int(round(raw / float(step))) * step
	return clampi(count, mini(min_count, max_count), max_count)

func is_in_pool(pool: int) -> bool:
	return (pools & pool) != 0

## Only what the chosen condition reads is shown.
func _validate_property(property: Dictionary) -> void:
	if str(property.get("name", "")) == "param_pool" and !QuestCondition.takes_param(condition):
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
