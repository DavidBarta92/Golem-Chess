extends Node

## Hands out the quests the game gives by itself, and moves the story on with
## the story's own (Docs/Quests/QUESTS.md):
##   * story    the current story node's quest, while it is a QuestStoryNode;
##              claiming it completes the node.
##   * daily    one a day, drawn from the templates' daily pool; it runs out
##              at midnight.
##   * regular  kind "reward" in the save: one new a day while there are fewer
##              than QuestSettings.regular_max; they never run out. One swap a
##              day for these (QuestSettings.regular_swaps_per_day).
## It also feeds QuestStore.record_event from the match boards (stamps
## affixed) and from scene changes (screens opened); the other events come
## from where they happen.
##
## A child of QuestStore. Nothing runs before start() - the top bar calls it
## the first time it shows its ribbons - so a dedicated server or an AI batch
## never hands out a quest.

const CHECK_SECONDS: float = 60.0
const STORY_KEY_PREFIX: String = "story:"
## What the schedule in quests.json remembers.
const SCHEDULE_DAILY_DAY: String = "daily_day"
const SCHEDULE_LAST_DAILY: String = "last_daily_template"
const SCHEDULE_REGULAR_DAY: String = "regular_day"
const SCHEDULE_SWAP_DAY: String = "swap_day"
const SCHEDULE_SWAPS_USED: String = "swaps_used"
const TRACKED_META: StringName = &"_quest_tracked"

var _started: bool = false
var _refresh_queued: bool = false
var _rng := RandomNumberGenerator.new()

func is_started() -> bool:
	return _started

func start() -> void:
	if _started:
		return
	_started = true
	_rng.randomize()
	var clock := Timer.new()
	clock.name = "QuestDayClock"
	clock.wait_time = CHECK_SECONDS
	clock.autostart = true
	clock.process_mode = Node.PROCESS_MODE_ALWAYS
	clock.timeout.connect(queue_refresh)
	add_child(clock)
	QuestStore.quest_claimed.connect(_on_quest_claimed)
	QuestStore.quest_removed.connect(_on_quest_removed)
	StoryManager.story_node_finished.connect(_on_story_moved)
	StoryProgressStore.feature_unlocked.connect(_on_story_moved)
	get_tree().node_added.connect(_on_node_added)
	if get_tree().has_signal("scene_changed"):
		get_tree().connect("scene_changed", _on_scene_changed)
	else:
		push_warning("QuestDirector: SceneTree has no scene_changed; screens opened are not tracked.")
	refresh()

func queue_refresh() -> void:
	if !_started or _refresh_queued:
		return
	_refresh_queued = true
	_run_queued_refresh.call_deferred()

func _run_queued_refresh() -> void:
	_refresh_queued = false
	refresh()

## Everything that is due: the story's quest, today's daily, today's regular.
func refresh() -> void:
	if !_started:
		return
	QuestStore.expire_overdue_quests()
	_post_story_quest()
	issue_daily()
	issue_regular()

# --- Story ------------------------------------------------------------------------

func _post_story_quest() -> void:
	var node := StoryManager.get_current_node() as QuestStoryNode
	if node == null or QuestStore.has_quest_key(node.get_quest_key()):
		return
	var count: int = node.get_count()
	var title: String = node.title if !node.title.strip_edges().is_empty() else QuestCondition.default_title(node.condition)
	var text: String = node.text if !node.text.strip_edges().is_empty() else QuestCondition.default_text(node.condition, node.param)
	if QuestStore.add_quest({
		"key": node.get_quest_key(),
		"kind": QuestStore.KIND_STORY,
		"title": QuestCondition.pick_count_form(title, count),
		"text": QuestCondition.pick_count_form(text, count),
		"target": count,
		"condition": QuestCondition.id_of(node.condition),
		"param": node.param,
	}).is_empty():
		push_warning("QuestDirector: no room for the story quest of node '%s'." % node.id)

## A story quest claimed: its node is done.
func _on_quest_claimed(quest: Dictionary) -> void:
	var quest_key: String = str(quest.get("key", ""))
	if quest_key.begins_with(STORY_KEY_PREFIX):
		StoryManager.complete_quest_node(quest_key.trim_prefix(STORY_KEY_PREFIX))
	queue_refresh()

func _on_quest_removed(_quest: Dictionary, _reason: String) -> void:
	queue_refresh()

func _on_story_moved(_id: String) -> void:
	queue_refresh()

# --- Daily and regular ------------------------------------------------------------

## Today's daily, unless it has come already or an unfinished daily is still
## up. `force` (developer tools) skips both checks and leaves the schedule be.
## Returns the new quest's id, or "".
func issue_daily(force: bool = false) -> String:
	if !_started:
		return ""
	var today: String = _today()
	if !force and (str(QuestStore.get_schedule_value(SCHEDULE_DAILY_DAY)) == today or _has_open_quest(QuestStore.KIND_DAILY)):
		return ""
	if !_has_room():
		return ""
	var settings: QuestSettings = QuestLibrary.get_settings()
	var exclude: Array = _active_template_ids()
	var last_daily: String = str(QuestStore.get_schedule_value(SCHEDULE_LAST_DAILY))
	# Not the same as yesterday's, unless nothing else can be done.
	var pick: Dictionary = _draw(QuestTemplate.POOL_DAILY, settings.daily_budget_matches, exclude + [last_daily])
	if pick.is_empty():
		pick = _draw(QuestTemplate.POOL_DAILY, settings.daily_budget_matches, exclude)
	if pick.is_empty():
		return ""
	var spec: Dictionary = _spec_from(pick, QuestStore.KIND_DAILY, settings.daily_reward_kind, settings.daily_reward)
	spec["expires_at"] = _next_midnight()
	var quest_id: String = QuestStore.add_quest(spec)
	if !quest_id.is_empty() and !force:
		QuestStore.set_schedule_values({SCHEDULE_DAILY_DAY: today, SCHEDULE_LAST_DAILY: pick["template"].template_id})
	return quest_id

## Today's regular quest, unless it has come already or there are
## regular_max of them. `force` (developer tools) skips the day check and
## leaves the schedule be. Returns the new quest's id, or "".
func issue_regular(force: bool = false) -> String:
	if !_started:
		return ""
	var settings: QuestSettings = QuestLibrary.get_settings()
	var today: String = _today()
	if !force and str(QuestStore.get_schedule_value(SCHEDULE_REGULAR_DAY)) == today:
		return ""
	if _count_kind(QuestStore.KIND_REWARD) >= settings.regular_max or !_has_room():
		return ""
	var pick: Dictionary = _draw(QuestTemplate.POOL_REWARD, settings.regular_budget_matches, _active_template_ids())
	if pick.is_empty():
		return ""
	var quest_id: String = QuestStore.add_quest(_spec_from(pick, QuestStore.KIND_REWARD, settings.regular_reward_kind, settings.regular_reward))
	if !quest_id.is_empty() and !force:
		QuestStore.set_schedule_values({SCHEDULE_REGULAR_DAY: today})
	return quest_id

## Swaps left today.
func swaps_left() -> int:
	if !_started:
		return 0
	var used: int = int(QuestStore.get_schedule_value(SCHEDULE_SWAPS_USED, 0)) if str(QuestStore.get_schedule_value(SCHEDULE_SWAP_DAY)) == _today() else 0
	return maxi(0, QuestLibrary.get_settings().regular_swaps_per_day - used)

## A regular quest the game handed out, not done yet, while a swap is left today.
func can_swap(quest: Dictionary) -> bool:
	return str(quest.get("kind", "")) == QuestStore.KIND_REWARD \
		and !bool(quest.get("done", false)) \
		and QuestLibrary.get_template(str(quest.get("template", ""))) != null \
		and swaps_left() > 0

## Takes a regular quest down and hands out another in its place: a different
## template from those up, or failing that any but its own. Returns the new
## quest's id, or "" when there is nothing to swap it for.
func swap(quest_id: String) -> String:
	var quest: Dictionary = QuestStore.get_quest(quest_id)
	if !can_swap(quest):
		return ""
	var settings: QuestSettings = QuestLibrary.get_settings()
	var pick: Dictionary = _draw(QuestTemplate.POOL_REWARD, settings.regular_budget_matches, _active_template_ids())
	if pick.is_empty():
		pick = _draw(QuestTemplate.POOL_REWARD, settings.regular_budget_matches, [str(quest.get("template", ""))])
	if pick.is_empty():
		return ""
	var today: String = _today()
	var used: int = int(QuestStore.get_schedule_value(SCHEDULE_SWAPS_USED, 0)) if str(QuestStore.get_schedule_value(SCHEDULE_SWAP_DAY)) == today else 0
	QuestStore.set_schedule_values({SCHEDULE_SWAP_DAY: today, SCHEDULE_SWAPS_USED: used + 1})
	QuestStore.discard_quest(quest_id)
	return QuestStore.add_quest(_spec_from(pick, QuestStore.KIND_REWARD, settings.regular_reward_kind, settings.regular_reward))

## Developer tools: forgets what today has handed out and swapped, and hands
## out what is due.
func start_new_day() -> void:
	QuestStore.set_schedule_values({SCHEDULE_DAILY_DAY: "", SCHEDULE_REGULAR_DAY: "", SCHEDULE_SWAP_DAY: "", SCHEDULE_SWAPS_USED: 0})
	refresh()

## A template the player can do now, weighted: {"template", "param", "count"},
## or {} when there is none.
func _draw(pool: int, budget_matches: float, exclude: Array) -> Dictionary:
	var options: Array[Dictionary] = []
	var total_weight: float = 0.0
	for template in QuestLibrary.get_templates():
		if !template.is_in_pool(pool) or template.weight <= 0.0 or exclude.has(template.template_id):
			continue
		if !_features_unlocked(template.requires_features):
			continue
		var count: int = template.count_for_budget(budget_matches)
		# The template's XY values; else, for a type that needs one, those the
		# player's codexes and collection offer.
		var candidates: Array[String] = template.param_pool.duplicate()
		if candidates.is_empty():
			if QuestCondition.needs_param(template.condition):
				candidates = QuestCondition.dynamic_params(template.condition)
			else:
				candidates.append("")
		var params: Array[String] = []
		for param in candidates:
			if QuestCondition.is_available(template.condition, param, count):
				params.append(param)
		if params.is_empty():
			continue
		options.append({"template": template, "param": params[_rng.randi_range(0, params.size() - 1)], "count": count})
		total_weight += template.weight
	if options.is_empty():
		return {}
	var roll: float = _rng.randf() * total_weight
	for option in options:
		roll -= option["template"].weight
		if roll <= 0.0:
			return option
	return options.back()

func _spec_from(pick: Dictionary, kind: String, reward_kind: String, amount: int) -> Dictionary:
	var template: QuestTemplate = pick["template"]
	var count: int = int(pick["count"])
	var param: String = str(pick["param"])
	var title: String = template.title if !template.title.strip_edges().is_empty() else QuestCondition.default_title(template.condition)
	var text: String = template.text if !template.text.strip_edges().is_empty() else QuestCondition.default_text(template.condition, param)
	return {
		"kind": kind,
		"reward": reward_kind,
		"amount": amount,
		"title": QuestCondition.pick_count_form(title, count),
		"text": QuestCondition.pick_count_form(text, count),
		"target": count,
		"condition": QuestCondition.id_of(template.condition),
		"param": param,
		"template": template.template_id,
	}

func _features_unlocked(feature_ids: Array[String]) -> bool:
	for feature_id in feature_ids:
		if !feature_id.strip_edges().is_empty() and !StoryProgressStore.is_feature_unlocked(feature_id):
			return false
	return true

## One place stays free for the story's quest while it has none up.
func _has_room() -> bool:
	var limit: int = QuestStore.MAX_ACTIVE if _count_kind(QuestStore.KIND_STORY) > 0 else QuestStore.MAX_ACTIVE - 1
	return QuestStore.get_active_count() < limit

func _count_kind(kind: String) -> int:
	var count: int = 0
	for quest in QuestStore.get_active_quests():
		if str(quest.get("kind", "")) == kind:
			count += 1
	return count

func _has_open_quest(kind: String) -> bool:
	for quest in QuestStore.get_active_quests():
		if str(quest.get("kind", "")) == kind and !bool(quest.get("done", false)):
			return true
	return false

func _active_template_ids() -> Array:
	var ids: Array = []
	for quest in QuestStore.get_active_quests():
		var template_id: String = str(quest.get("template", ""))
		if !template_id.is_empty():
			ids.append(template_id)
	return ids

func _today() -> String:
	return Time.get_date_string_from_system()

## The next local midnight, in unix seconds.
func _next_midnight() -> int:
	var now: int = int(Time.get_unix_time_from_system())
	var clock: Dictionary = Time.get_time_dict_from_system()
	var seconds_today: int = int(clock.get("hour", 0)) * 3600 + int(clock.get("minute", 0)) * 60 + int(clock.get("second", 0))
	return now + maxi(60, 24 * 3600 - seconds_today)

# --- Events from the game ---------------------------------------------------------

## A match board coming in: its stamps, captures and crowns count. The board
## has no class of its own, so it is known by what it has. Its crown
## controller is there once the board is ready.
func _on_node_added(node: Node) -> void:
	if node.has_meta(TRACKED_META) or !node.has_signal("stamp_affixed") or !node.has_signal("piece_captured") or !node.has_method("get_own_color"):
		return
	node.set_meta(TRACKED_META, true)
	node.connect("stamp_affixed", _on_board_stamp_affixed.bind(node))
	node.connect("piece_captured", _on_board_piece_captured.bind(node))
	node.ready.connect(_track_board_crowns.bind(node), CONNECT_ONE_SHOT)

func _track_board_crowns(board: Node) -> void:
	if !is_instance_valid(board) or !board.has_method("get_crown_controller"):
		return
	var crowns = board.call("get_crown_controller")
	if crowns != null and crowns.has_signal("crowned"):
		crowns.connect("crowned", _on_board_crowned.bind(board))

func _counts_on(board: Node) -> bool:
	return is_instance_valid(board) and !bool(board.get("tutorial_mode_active")) and !GameConfig.is_ai_vs_ai_batch

func _on_board_stamp_affixed(_piece_pos: Vector2, stamp_name: String, owner_color: int, _hand_index: int, board: Node) -> void:
	if _counts_on(board) and _is_human_color(board, owner_color):
		QuestStore.record_event(QuestCondition.EVENT_STAMP_AFFIXED, {"stamp_name": stamp_name})

## A move took a golem: the player's capture, or the player's loss.
func _on_board_piece_captured(by_color: int, captured_color: int, capturing_stamp_name: String, _captured_stamp_name: String, board: Node) -> void:
	if !_counts_on(board):
		return
	if _is_human_color(board, by_color):
		QuestStore.record_event(QuestCondition.EVENT_PIECE_CAPTURED, {"stamp_name": capturing_stamp_name})
	elif _is_human_color(board, captured_color):
		QuestStore.record_event(QuestCondition.EVENT_PIECE_LOST)

func _on_board_crowned(owner_color: int, board: Node) -> void:
	if _counts_on(board) and _is_human_color(board, owner_color):
		QuestStore.record_event(QuestCondition.EVENT_CROWN_PLACED)

## The colour played at this machine: the board's own side online, the human
## controller's against the AI.
func _is_human_color(board: Node, color: int) -> bool:
	if board.get("side") != null:
		return color == int(board.call("get_own_color"))
	if GameConfig.is_singleplayer:
		return GameConfig.get_player_controller(int(board.call("get_player_id_for_color", color))) == GameConfig.CONTROLLER_HUMAN
	return true

func _on_scene_changed() -> void:
	var scene: Node = get_tree().current_scene
	if scene != null and !scene.scene_file_path.is_empty():
		QuestStore.record_event(QuestCondition.EVENT_SCREEN_OPENED, {"scene_path": scene.scene_file_path})
