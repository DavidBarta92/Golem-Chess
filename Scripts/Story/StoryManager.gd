extends Node

## Drives the story: decides what the player plays next, launches the scene
## that plays it, and records the result.
##
## The story is a flat, ordered run of nodes (comic pages, the tutorial, boss
## matches, warm-up matches, reward scenes). "Where the player is" is never
## stored as a number - it is derived every time as the first node whose id is
## not in the completed set, which is what makes inserting or reordering
## chapters safe for existing saves.

const STORY_DEFINITION_PATH: String = "res://Story/story_definition.tres"
const GAME_SCENE_PATH: String = "res://Scenes/main.tscn"
const COMIC_SCENE_PATH: String = "res://Scenes/Comic/StoryComicScene.tscn"
const RETRY_PROMPT_SCENE_PATH: String = "res://Scenes/Story/RetryPromptScene.tscn"
const HUB_SCENE_PATH: String = "res://Scenes/MainMenu.tscn"

## What a run of comic pages does when its last panel has been revealed.
enum ComicEnd { COMPLETE_NODE, RETURN_TO_HUB, RESTART_NODE }

signal story_node_started(node_id: String)
signal story_node_finished(node_id: String)

var story_definition: StoryDefinition
var _flat_nodes: Array[StoryNode] = []
var _debug_completed_override_ids: Dictionary = {}
var _pending_comic_request: Dictionary = {}
var _pending_boss_line: Dictionary = {}
var _active_match_node_id: String = ""

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

func get_node_by_id(node_id: String) -> StoryNode:
	var wanted_id: String = node_id.strip_edges()
	for node in _flat_nodes:
		if node.id == wanted_id:
			return node
	return null

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
	_apply_node_unlocks(node)
	StoryProgressStore.mark_node_completed(node.id)

## The single call a scene makes when its story content is done. Marks the
## node complete, then either chains straight into the next node or leaves
## the story (to the hub, or to the node's own completion scene) - the scene
## itself never needs to know what comes next or where it lives.
func finish_current_node() -> void:
	var finished_node: StoryNode = get_current_node()
	if finished_node == null:
		return_to_hub()
		return

	var finished_node_id: String = finished_node.id
	clear_active_match()
	complete_current_node()
	story_node_finished.emit(finished_node_id)

	if finished_node.auto_continue_after_completion:
		start_current_node()
	elif !finished_node.completion_scene_path.is_empty():
		SceneTransition.change_scene(_resolve_scene_path(finished_node.completion_scene_path))
	else:
		return_to_hub()

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

func return_to_hub() -> void:
	clear_active_match()
	SceneTransition.change_scene(HUB_SCENE_PATH)

## Restarts the current node from scratch - a retried boss fight.
func restart_current_node() -> void:
	clear_active_match()
	start_current_node()

## Loads/configures whatever scene the current node needs.
func start_current_node() -> void:
	var node: StoryNode = get_current_node()
	if node == null:
		return

	story_node_started.emit(node.id)

	if node is BossGameStoryNode:
		_start_boss_node(node)
	elif node is RandomMatchStoryNode:
		_start_random_match_node(node)
	elif node is TutorialStoryNode:
		_start_tutorial_node(node)
	elif node is ComicStoryNode:
		_start_comic_node(node)
	elif node is RewardStoryNode:
		_start_reward_node(node)
	elif node is SceneStoryNode:
		_start_scene_node(node)
	else:
		push_error("StoryManager: unknown story node type for id '%s'." % node.id)

# --- Matches ----------------------------------------------------------------

## True while a story match (boss or warm-up) is the thing currently being
## played, which is what tells the shared match-end code to report back here
## instead of running its normal post-match flow.
func is_story_match_active() -> bool:
	return !_active_match_node_id.is_empty()

func get_active_match_node() -> StoryNode:
	if _active_match_node_id.is_empty():
		return null
	return get_node_by_id(_active_match_node_id)

func get_active_boss_node() -> BossGameStoryNode:
	return get_active_match_node() as BossGameStoryNode

## The boss being fought, or null - including during a warm-up match, which
## has no authored opponent and therefore no dialogue.
func get_active_boss() -> BossDefinition:
	var boss_node: BossGameStoryNode = get_active_boss_node()
	return boss_node.boss if boss_node != null else null

## Whether the match being played keeps time. Only a story boss can turn the
## clock off; any other match - including one with no story behind it, since
## the hub clears the active match - has it.
func should_show_match_clock() -> bool:
	var boss: BossDefinition = get_active_boss()
	return boss == null or boss.show_clock

func clear_active_match() -> void:
	_active_match_node_id = ""
	GameConfig.clear_ai_opponent_override()
	GameConfig.clear_player_deck_override()

## Called by the match when a story fight ends. Returns false when this was
## not a story match at all.
##
## Boss: winning completes the node; losing either prompts for an immediate
## retry or plays the defeat comic and retries, per the node's setting.
## Warm-up: win or lose, the attempt counts; the node completes once enough
## matches have been started, and either way the player goes back to the hub.
func report_story_match_result(player_won: bool) -> bool:
	if !is_story_match_active():
		return false

	var match_node: StoryNode = get_active_match_node()
	clear_active_match()

	if match_node is RandomMatchStoryNode:
		_finish_random_match(match_node)
		return true

	var boss_node: BossGameStoryNode = match_node as BossGameStoryNode
	if player_won:
		finish_current_node()
		return true

	if boss_node != null and boss_node.defeat_behavior == BossGameStoryNode.DefeatBehavior.COMIC_THEN_RETRY:
		if boss_node.defeat_page_paths.is_empty():
			restart_current_node()
		else:
			play_comic_pages(boss_node.defeat_page_paths, ComicEnd.RESTART_NODE)
		return true

	SceneTransition.change_scene(RETRY_PROMPT_SCENE_PATH)
	return true

func _start_boss_node(node: BossGameStoryNode) -> void:
	if node.boss == null:
		push_error("BossGameStoryNode '%s' has no BossDefinition assigned." % node.id)
		return_to_hub()
		return

	_configure_singleplayer_match(node.boss.ai_difficulty_level)
	if !node.force_player_deck_id.strip_edges().is_empty():
		GameConfig.set_selected_deck_id(node.force_player_deck_id)
	if node.lent_player_deck != null:
		GameConfig.set_player_deck_override(node.lent_player_deck.get_deck_stamp_names())
	else:
		GameConfig.clear_player_deck_override()

	# The boss brings their own name, face and stamps. Going through the
	# override rather than set_selected_ai_deck_id() matters: that path resolves
	# against the *player's* saved decks and their collection, so an authored
	# boss deck would silently fall back to whatever the player owns.
	GameConfig.set_ai_opponent_override(
		node.boss.get_localized_display_name(),
		node.boss.get_portrait_data(_get_boss_ordinal(node)),
		node.boss.get_deck_stamp_names()
	)
	GameConfig.set_match_room(int(node.boss.room_variant), node.boss.show_opponent_codex)

	_active_match_node_id = node.id
	_pending_boss_line = {}
	StoryProgressStore.register_node_attempt(node.id)
	SceneTransition.change_scene(GAME_SCENE_PATH)

func _start_random_match_node(node: RandomMatchStoryNode) -> void:
	var difficulty: int = node.difficulty_override if node.difficulty_override > 0 else _get_last_defeated_boss_level(node)
	var opponent: Dictionary = RandomOpponentFactory.create(difficulty)

	_configure_singleplayer_match(int(opponent.get("difficulty_level", difficulty)))
	GameConfig.clear_match_room()
	GameConfig.set_ai_opponent_override(
		str(opponent.get("name", "")),
		opponent.get("portrait_data", {}),
		opponent.get("deck_stamp_names", [])
	)

	_active_match_node_id = node.id
	_pending_boss_line = {}
	StoryProgressStore.register_node_attempt(node.id)
	SceneTransition.change_scene(GAME_SCENE_PATH)

func _finish_random_match(node: RandomMatchStoryNode) -> void:
	if StoryProgressStore.get_node_attempts(node.id) >= node.match_count:
		finish_current_node()
	else:
		return_to_hub()

func _configure_singleplayer_match(ai_difficulty_level: int) -> void:
	GameConfig.stop_ai_vs_ai_batch()
	GameConfig.is_singleplayer = true
	GameConfig.is_hosting = true
	GameConfig.server_ip = ""
	GameConfig.set_singleplayer_controllers(GameConfig.CONTROLLER_HUMAN, GameConfig.CONTROLLER_AI)
	GameConfig.set_player_ai_difficulty_level(1, ai_difficulty_level)

## Difficulty a warm-up match inherits: the level of the nearest boss beaten
## before this node in story order. Falls back to the easiest level when no
## boss has been beaten yet.
func _get_last_defeated_boss_level(before_node: StoryNode) -> int:
	var level: int = GameConfig.MIN_AI_DIFFICULTY_LEVEL
	for candidate in _flat_nodes:
		if candidate == before_node:
			break
		if candidate is BossGameStoryNode and candidate.boss != null and is_node_completed(candidate.id):
			level = candidate.boss.ai_difficulty_level
	return level

## 1-based position of this boss among all boss nodes; only used to pick a
## deterministic fallback portrait for a boss that has none authored yet.
func _get_boss_ordinal(node: BossGameStoryNode) -> int:
	var ordinal: int = 0
	for candidate in _flat_nodes:
		if candidate is BossGameStoryNode:
			ordinal += 1
			if candidate == node:
				return ordinal
	return 1

## The boss's parting line, handed from the match to whatever scene comes
## next. Set when the player wins, since the reward scene is where the boss
## gets the last word; on a loss the line is spoken over the board instead.
func set_pending_boss_line(speaker_name: String, text: String, portrait_data: Dictionary, music_cue: MusicCue = null) -> void:
	if text.strip_edges().is_empty():
		_pending_boss_line = {}
		return
	_pending_boss_line = {
		"speaker_name": speaker_name,
		"text": text,
		"portrait_data": portrait_data.duplicate(true),
		"music_cue": music_cue,
	}

## Read once by the reward scene; empty when the boss had nothing to say.
func consume_pending_boss_line() -> Dictionary:
	var line: Dictionary = _pending_boss_line
	_pending_boss_line = {}
	return line

# --- Other node types -------------------------------------------------------

func _start_tutorial_node(node: TutorialStoryNode) -> void:
	if node.tutorial_scene_path.is_empty():
		push_error("TutorialStoryNode '%s' has no tutorial_scene_path assigned." % node.id)
		return_to_hub()
		return
	SceneTransition.change_scene(_resolve_scene_path(node.tutorial_scene_path))

func _start_comic_node(node: ComicStoryNode) -> void:
	if node.page_paths.is_empty():
		# Not authored yet: treat it as done so the story stays playable.
		finish_current_node()
		return
	play_comic_pages(node.page_paths, ComicEnd.COMPLETE_NODE)

func _start_scene_node(node: SceneStoryNode) -> void:
	if node.scene_path.is_empty():
		push_error("SceneStoryNode '%s' has no scene_path assigned." % node.id)
		finish_current_node()
		return
	SceneTransition.change_scene(_resolve_scene_path(node.scene_path))

func _start_reward_node(node: RewardStoryNode) -> void:
	if node.reward_scene_path.is_empty():
		push_error("RewardStoryNode '%s' has no reward_scene_path assigned." % node.id)
		finish_current_node()
		return
	SceneTransition.change_scene(_resolve_scene_path(node.reward_scene_path))

## A story node's scene path as res://. The inspector stores @export_file
## picks as uid://, while the scene-change code compares res:// paths.
func _resolve_scene_path(path: String) -> String:
	return ResourceUID.ensure_path(path)

# --- Comic playback ---------------------------------------------------------

## Queues a run of comic pages and opens the player scene. `on_end` says what
## happens after the last panel: pages that *are* the current node complete
## it; a defeat comic restarts the fight; anything else just returns to the
## hub with progress untouched.
func play_comic_pages(page_paths: Array[String], on_end: ComicEnd) -> void:
	var resolved_paths: Array[String] = []
	for page_path in page_paths:
		if !page_path.is_empty():
			resolved_paths.append(_resolve_scene_path(page_path))

	if resolved_paths.is_empty():
		_apply_comic_end(on_end)
		return

	_pending_comic_request = {
		"pages": resolved_paths,
		"on_end": on_end,
	}
	SceneTransition.change_scene(COMIC_SCENE_PATH)

## Read once by StoryComicPlayer as it starts up.
func consume_comic_request() -> Dictionary:
	var request: Dictionary = _pending_comic_request
	_pending_comic_request = {}
	return request

## Called by StoryComicPlayer when its pages are done.
func on_comic_finished(on_end: int) -> void:
	_apply_comic_end(on_end as ComicEnd)

func _apply_comic_end(on_end: ComicEnd) -> void:
	match on_end:
		ComicEnd.COMPLETE_NODE:
			finish_current_node()
		ComicEnd.RESTART_NODE:
			restart_current_node()
		_:
			return_to_hub()

# --- Internals --------------------------------------------------------------

func _apply_node_unlocks(node: StoryNode) -> void:
	var feature_id: String = node.unlocks_feature.strip_edges()
	if !feature_id.is_empty():
		StoryProgressStore.unlock_feature(feature_id)
	for pack_id in node.unlocks_packs:
		var cleaned_pack_id: String = str(pack_id).strip_edges()
		if !cleaned_pack_id.is_empty():
			StoryProgressStore.unlock_pack(cleaned_pack_id)

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
