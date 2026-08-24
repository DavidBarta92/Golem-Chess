extends Node

const STORY_DEFINITION_PATH: String = "res://Story/story_definition.tres"
const GAME_SCENE_PATH: String = "res://Scenes/main.tscn"
const COMIC_SCENE_PATH: String = "res://Scenes/StoryComicScene.tscn"
const HUB_SCENE_PATH: String = "res://Scenes/MainMenu.tscn"

var story_definition: StoryDefinition
var _flat_nodes: Array[StoryNode] = []
var _debug_completed_override_ids: Dictionary = {}

func _ready() -> void:
	reload_definition()

## Re-reads Story/story_definition.tres. Call this after editing the
## resource while the game is already running (e.g. from a debug menu).
func reload_definition() -> void:
	var loaded = load(STORY_DEFINITION_PATH)
	story_definition = loaded if loaded is StoryDefinition else StoryDefinition.new()
	_rebuild_flat_nodes()

func get_current_node() -> StoryNode:
	for node in _flat_nodes:
		if !is_node_completed(node.id):
			return node
	return null

func get_current_node_id() -> String:
	var node: StoryNode = get_current_node()
	return node.id if node != null else ""

func is_node_completed(node_id: String) -> bool:
	if _debug_completed_override_ids.has(node_id):
		return true
	return StoryProgressStore.is_node_completed(node_id)

## Marks the current node done and saves, without deciding where to go next.
## Prefer finish_current_node() from scenes; this is the lower-level primitive.
func complete_current_node() -> void:
	var node: StoryNode = get_current_node()
	if node == null:
		return
	StoryProgressStore.mark_node_completed(node.id)

## The single call a scene makes when its story content is done. Marks the
## node complete, then either chains straight into the next node or returns
## to the hub, based on that node's auto_continue_after_completion flag -
## the scene itself never needs to know what comes next or where it lives.
func finish_current_node() -> void:
	var finished_node: StoryNode = get_current_node()
	if finished_node == null:
		return

	complete_current_node()
	if finished_node.auto_continue_after_completion:
		start_current_node()
	else:
		SceneTransition.change_scene(HUB_SCENE_PATH)

## For the hub's "Play" button: if a story node is waiting and unlocked,
## starts it and returns true. Otherwise returns false so the caller can
## fall back to its normal (non-story) flow.
func continue_story_if_ready() -> bool:
	var node: StoryNode = get_current_node()
	if node == null or !is_current_node_unlocked():
		return false
	start_current_node()
	return true

func has_pending_node() -> bool:
	return get_current_node() != null

## For the hub's boot check: true when the current node must be played
## before the hub itself is shown (see StoryNode.blocks_hub_until_completed).
func should_block_hub() -> bool:
	var node: StoryNode = get_current_node()
	return node != null and node.blocks_hub_until_completed

## Stub seam for future prerequisites (e.g. "only after collecting N stamps").
## Always true for now - nothing gates story continuation yet.
func is_current_node_unlocked() -> bool:
	return true

## Loads/configures whatever scene the current node needs.
func start_current_node() -> void:
	var node: StoryNode = get_current_node()
	if node == null:
		return

	if node is BossGameStoryNode:
		_start_boss_node(node)
	elif node is TutorialStoryNode:
		_start_tutorial_node(node)
	elif node is ComicStoryNode:
		_start_comic_node(node)
	else:
		push_error("StoryManager: unknown story node type for id '%s'." % node.id)

func _start_boss_node(node: BossGameStoryNode) -> void:
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = true
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.set_singleplayer_controllers(GameConfig.CONTROLLER_HUMAN, GameConfig.CONTROLLER_AI)
	GameConfig.set_player_ai_difficulty_level(1, node.boss_ai_difficulty_level)
	if !node.force_player_deck_id.strip_edges().is_empty():
		GameConfig.set_selected_deck_id(node.force_player_deck_id)
	GameConfig.set_selected_ai_deck_id(node.boss_deck_id)
	SceneTransition.change_scene(GAME_SCENE_PATH)

func _start_tutorial_node(node: TutorialStoryNode) -> void:
	if node.tutorial_scene == null:
		push_error("TutorialStoryNode '%s' has no tutorial_scene assigned." % node.id)
		return
	SceneTransition.change_scene(node.tutorial_scene.resource_path)

func _start_comic_node(_node: ComicStoryNode) -> void:
	if !ResourceLoader.exists(COMIC_SCENE_PATH):
		push_error("Comic story scene not implemented yet at %s" % COMIC_SCENE_PATH)
		return
	SceneTransition.change_scene(COMIC_SCENE_PATH)

func _rebuild_flat_nodes() -> void:
	_flat_nodes.clear()
	_debug_completed_override_ids.clear()

	for chapter in story_definition.chapters:
		if chapter == null:
			continue
		for node in chapter.nodes:
			if node == null or node.id.strip_edges().is_empty():
				continue
			_flat_nodes.append(node)

	if !OS.is_debug_build():
		return

	for node in _flat_nodes:
		if node.force_completed:
			_debug_completed_override_ids[node.id] = true

	var jump_to_id: String = story_definition.debug_jump_to_node_id.strip_edges()
	if jump_to_id.is_empty():
		return
	for node in _flat_nodes:
		if node.id == jump_to_id:
			break
		_debug_completed_override_ids[node.id] = true
