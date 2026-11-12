@tool
extends StoryNode
class_name QuestStoryNode

## A story beat that is a quest (Docs/Quests/QUESTS.md). When the story gets
## here, the quest hangs in the top bar as a story ribbon (burgundy, slanted
## cut, "the story continues"); claiming it once it is done completes the
## node, and the story goes on from the next one. Until then Play starts an
## ordinary match, as it does when the story has nothing waiting, and the
## node's unlocks (unlocks_feature, unlocks_packs) come with the claim.
##
## The node never blocks the hub, whatever blocks_hub_until_completed says:
## the quest is done there.

## What it asks for; the inspector shows only the fields it reads.
@export var condition: QuestCondition.Type = QuestCondition.Type.OPEN_SCREEN:
	set(value):
		condition = value
		notify_property_list_changed()
## How many (the quest's X).
@export_range(1, 999) var count: int = 1
## What it narrows down to (the quest's XY): the inspector offers what the
## condition takes, or a stamp's name is typed in. Empty: any - except for the
## conditions that need one (a screen, a role, an effect, a stamp).
@export var param: String = ""
## Translation keys (or plain text); empty: the condition's own. The text may
## use {count} and {param}, with the exact condition in <b>...</b>.
@export var title: String = ""
@export_multiline var text: String = ""

## The quest's key in QuestStore: the story's quests are told apart by node.
func get_quest_key() -> String:
	return "story:" + id

func get_count() -> int:
	return count if QuestCondition.takes_count(condition) else 1

func _validate_property(property: Dictionary) -> void:
	match str(property.get("name", "")):
		"param":
			var options: Array[String] = QuestCondition.param_options(condition)
			if !QuestCondition.takes_param(condition):
				property["usage"] = PROPERTY_USAGE_NO_EDITOR
			elif !options.is_empty():
				property["hint"] = PROPERTY_HINT_ENUM_SUGGESTION
				property["hint_string"] = ",".join(options)
		"count":
			if !QuestCondition.takes_count(condition):
				property["usage"] = PROPERTY_USAGE_NO_EDITOR
