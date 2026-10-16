extends Button
class_name SceneLinkButton

## A button that opens a scene. Used for the story-unlocked menu entries
## (Quests, Trade, the story's multiplayer) until they get artwork of their
## own; pair it with a FeatureHint to gate and introduce it.

@export_file("*.tscn") var target_scene_path: String = ""

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if target_scene_path.strip_edges().is_empty():
		push_warning("SceneLinkButton '%s' has no target scene." % name)
		return
	disabled = true
	SceneTransition.change_scene(target_scene_path)
