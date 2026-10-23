extends Node

## The quests the player has on the go - what the top bar's ribbons show.
##
## A quest is one dictionary, kept oldest first:
##   id        "q<n>", unique within the save
##   key       optional; a quest with a key can be active only once, so
##             whatever hands quests out can offer the same one again safely
##   kind      "story" | "reward" | "daily" (daily runs out after a day)
##   reward    "coin" | "draw" - what claiming pays; story quests pay nothing
##             here (finishing one moves the story on) and keep ""
##   amount    how much of the reward
##   title     translation key (or plain text) of the quest's short name
##   text      translation key (or plain text) of its description, the exact
##             condition in <b>...</b>
##   progress / target   steps done / needed; done once progress reaches target
##   done      waiting to be claimed
##   created_at / expires_at   unix seconds; expires_at is 0 unless it runs out
##
## At most MAX_ACTIVE quests are active at once. Whatever assigns quests is
## expected to respect that; add_quest() refuses past it, and the bar has no
## overflow state. Nothing here decides which quests to hand out or tracks the
## game events that move them on yet - callers do that through add_quest(),
## add_progress() and complete_quest().

const SCHEMA_VERSION: int = 1
const FILE_NAME: String = "quests.json"
const MAX_ACTIVE: int = 6
const DAILY_SECONDS: int = 24 * 60 * 60
const URGENT_SECONDS: int = 60 * 60
const EXPIRY_CHECK_SECONDS: float = 15.0

const KIND_STORY: String = "story"
const KIND_REWARD: String = "reward"
const KIND_DAILY: String = "daily"
const REWARD_COIN: String = "coin"
const REWARD_DRAW: String = "draw"

## Why a quest left the list.
const REASON_CLAIMED: String = "claim"
const REASON_EXPIRED: String = "expire"
const REASON_DISCARDED: String = "discard"

signal quest_added(quest: Dictionary)
signal quest_changed(quest: Dictionary)
## Emitted after the reward is paid, before quest_removed.
signal quest_claimed(quest: Dictionary)
signal quest_removed(quest: Dictionary, reason: String)

var quest_data: Dictionary = {}
var is_loaded: bool = false

func _ready() -> void:
	var expiry_timer := Timer.new()
	expiry_timer.name = "ExpiryTimer"
	expiry_timer.wait_time = EXPIRY_CHECK_SECONDS
	expiry_timer.autostart = true
	expiry_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	expiry_timer.timeout.connect(_on_expiry_timer_timeout)
	add_child(expiry_timer)

func ensure_loaded() -> void:
	if is_loaded:
		return
	var raw_data: Dictionary = SaveIO.read_json(FILE_NAME)
	quest_data = _normalize_data(raw_data) if !raw_data.is_empty() else _create_default_data()
	is_loaded = true
	save_quests()

# --- Reading ------------------------------------------------------------------

## Copies of the active quests, oldest first.
func get_active_quests() -> Array[Dictionary]:
	ensure_loaded()
	var quests: Array[Dictionary] = []
	for quest in _active():
		quests.append(quest.duplicate(true))
	return quests

func get_quest(quest_id: String) -> Dictionary:
	var index: int = _index_of(quest_id)
	return _active()[index].duplicate(true) if index >= 0 else {}

func get_active_count() -> int:
	ensure_loaded()
	return _active().size()

func can_add_quest() -> bool:
	return get_active_count() < MAX_ACTIVE

func has_quest_key(quest_key: String) -> bool:
	return !find_quest_id(quest_key).is_empty()

func find_quest_id(quest_key: String) -> String:
	ensure_loaded()
	var normalized_key: String = quest_key.strip_edges()
	if normalized_key.is_empty():
		return ""
	for quest in _active():
		if str(quest.get("key", "")) == normalized_key:
			return str(quest.get("id", ""))
	return ""

## Seconds until the quest runs out, or -1 when it does not.
func get_seconds_left(quest: Dictionary) -> int:
	var expires_at: int = int(quest.get("expires_at", 0))
	if expires_at <= 0:
		return -1
	return maxi(0, expires_at - int(Time.get_unix_time_from_system()))

## A daily quest with less than an hour left.
func is_urgent(quest: Dictionary) -> bool:
	var seconds_left: int = get_seconds_left(quest)
	return seconds_left >= 0 and seconds_left < URGENT_SECONDS and !bool(quest.get("done", false))

## "17 h 05 m left" / "48 min left", or "" for a quest that does not run out.
func format_time_left(quest: Dictionary) -> String:
	var seconds_left: int = get_seconds_left(quest)
	if seconds_left < 0:
		return ""
	if seconds_left < URGENT_SECONDS:
		return tr("QUEST_TIME_LEFT_MINUTES") % maxi(1, int(ceil(seconds_left / 60.0)))
	@warning_ignore("integer_division")
	var hours: int = seconds_left / 3600
	@warning_ignore("integer_division")
	var minutes: int = (seconds_left % 3600) / 60
	return tr("QUEST_TIME_LEFT_HOURS") % [hours, minutes]

# --- Changing -----------------------------------------------------------------

## Adds a quest built from spec (the fields above; id, done and the times are
## filled in). Returns its id, or "" when the list is full, the key is already
## active or the spec makes no sense. A daily quest runs out DAILY_SECONDS
## after it is added unless spec gives "seconds_left".
func add_quest(spec: Dictionary) -> String:
	ensure_loaded()
	if !can_add_quest():
		push_warning("QuestStore: already %d active quests, not adding another." % MAX_ACTIVE)
		return ""
	var quest_key: String = str(spec.get("key", "")).strip_edges()
	if !quest_key.is_empty() and has_quest_key(quest_key):
		return ""

	var now: int = int(Time.get_unix_time_from_system())
	var raw: Dictionary = spec.duplicate(true)
	raw["id"] = "q%d" % _take_next_sequence()
	raw["created_at"] = now
	if str(raw.get("kind", "")) == KIND_DAILY and int(raw.get("expires_at", 0)) <= 0:
		raw["expires_at"] = now + maxi(1, int(raw.get("seconds_left", DAILY_SECONDS)))
	raw.erase("seconds_left")
	var quest: Dictionary = _normalize_quest(raw)
	if quest.is_empty():
		return ""

	_active().append(quest)
	save_quests()
	quest_added.emit(quest.duplicate(true))
	return str(quest["id"])

## Sets how many steps are done; reaching the target makes the quest done.
func set_progress(quest_id: String, progress: int) -> void:
	var index: int = _index_of(quest_id)
	if index < 0:
		return
	var quest: Dictionary = _active()[index]
	if bool(quest.get("done", false)):
		return
	var target: int = int(quest.get("target", 1))
	var next_progress: int = clampi(progress, 0, target)
	if next_progress == int(quest.get("progress", 0)):
		return
	quest["progress"] = next_progress
	quest["done"] = next_progress >= target
	save_quests()
	quest_changed.emit(quest.duplicate(true))

func add_progress(quest_id: String, amount: int = 1) -> void:
	var quest: Dictionary = get_quest(quest_id)
	if quest.is_empty():
		return
	set_progress(quest_id, int(quest.get("progress", 0)) + amount)

func complete_quest(quest_id: String) -> void:
	var quest: Dictionary = get_quest(quest_id)
	if quest.is_empty():
		return
	set_progress(quest_id, int(quest.get("target", 1)))

## Pays a done quest's reward and takes it off the list. False when the quest
## is missing or not done yet.
func claim_quest(quest_id: String) -> bool:
	var index: int = _index_of(quest_id)
	if index < 0:
		return false
	var quest: Dictionary = _active()[index]
	if !bool(quest.get("done", false)):
		return false

	_active().remove_at(index)
	save_quests()
	var amount: int = maxi(0, int(quest.get("amount", 0)))
	match str(quest.get("reward", "")):
		REWARD_COIN:
			PlayerProgressStore.add_points(amount)
		REWARD_DRAW:
			PlayerProgressStore.add_draw_points(amount)
	quest_claimed.emit(quest.duplicate(true))
	quest_removed.emit(quest.duplicate(true), REASON_CLAIMED)
	return true

func expire_quest(quest_id: String) -> void:
	_remove(quest_id, REASON_EXPIRED)

## Takes a quest off the list without paying anything.
func discard_quest(quest_id: String) -> void:
	_remove(quest_id, REASON_DISCARDED)

## Removes every quest whose time has run out and that was not finished.
## Done quests wait to be claimed whatever the clock says.
func expire_overdue_quests() -> void:
	ensure_loaded()
	var now: int = int(Time.get_unix_time_from_system())
	var overdue_ids: Array[String] = []
	for quest in _active():
		var expires_at: int = int(quest.get("expires_at", 0))
		if expires_at > 0 and expires_at <= now and !bool(quest.get("done", false)):
			overdue_ids.append(str(quest.get("id", "")))
	for quest_id in overdue_ids:
		expire_quest(quest_id)

## Debug helper: drops every active quest.
func clear_all_quests() -> void:
	ensure_loaded()
	var ids: Array[String] = []
	for quest in _active():
		ids.append(str(quest.get("id", "")))
	for quest_id in ids:
		discard_quest(quest_id)

func save_quests() -> bool:
	if quest_data.is_empty():
		quest_data = _create_default_data()
	return SaveIO.write_json(FILE_NAME, quest_data, SCHEMA_VERSION)

# --- Internals ----------------------------------------------------------------

## Only once something has loaded the quests: a dedicated server or an AI
## batch never touches the file.
func _on_expiry_timer_timeout() -> void:
	if is_loaded:
		expire_overdue_quests()

func _remove(quest_id: String, reason: String) -> void:
	var index: int = _index_of(quest_id)
	if index < 0:
		return
	var quest: Dictionary = _active()[index]
	_active().remove_at(index)
	save_quests()
	quest_removed.emit(quest.duplicate(true), reason)

func _active() -> Array:
	var active = quest_data.get("active", [])
	if !(active is Array):
		active = []
		quest_data["active"] = active
	return active

func _index_of(quest_id: String) -> int:
	ensure_loaded()
	var active: Array = _active()
	for index in range(active.size()):
		if str(active[index].get("id", "")) == quest_id:
			return index
	return -1

func _take_next_sequence() -> int:
	var sequence: int = maxi(1, int(quest_data.get("next_sequence", 1)))
	quest_data["next_sequence"] = sequence + 1
	return sequence

func _create_default_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"next_sequence": 1,
		"active": [],
	}

func _normalize_data(raw_data: Dictionary) -> Dictionary:
	var active: Array = []
	var seen_ids: Dictionary = {}
	var highest_sequence: int = 0
	var raw_active = raw_data.get("active", [])
	if raw_active is Array:
		for raw_quest in raw_active:
			if !(raw_quest is Dictionary) or active.size() >= MAX_ACTIVE:
				continue
			var quest: Dictionary = _normalize_quest(raw_quest)
			if quest.is_empty() or seen_ids.has(quest["id"]):
				continue
			seen_ids[quest["id"]] = true
			highest_sequence = maxi(highest_sequence, int(str(quest["id"]).trim_prefix("q")))
			active.append(quest)
	return {
		"schema_version": SCHEMA_VERSION,
		"next_sequence": maxi(int(raw_data.get("next_sequence", 1)), highest_sequence + 1),
		"active": active,
	}

## A clean copy of one quest, or {} when it cannot be one.
func _normalize_quest(raw: Dictionary) -> Dictionary:
	var quest_id: String = str(raw.get("id", "")).strip_edges()
	var kind: String = str(raw.get("kind", "")).strip_edges()
	if quest_id.is_empty() or ![KIND_STORY, KIND_REWARD, KIND_DAILY].has(kind):
		return {}
	var reward: String = ""
	if kind != KIND_STORY:
		reward = REWARD_DRAW if str(raw.get("reward", "")) == REWARD_DRAW else REWARD_COIN
	var target: int = maxi(1, int(raw.get("target", 1)))
	var progress: int = clampi(int(raw.get("progress", 0)), 0, target)
	var done: bool = bool(raw.get("done", false)) or progress >= target
	if done:
		progress = target
	return {
		"id": quest_id,
		"key": str(raw.get("key", "")).strip_edges(),
		"kind": kind,
		"reward": reward,
		"amount": maxi(0, int(raw.get("amount", 0))),
		"title": str(raw.get("title", "")),
		"text": str(raw.get("text", "")),
		"progress": progress,
		"target": target,
		"done": done,
		"created_at": maxi(0, int(raw.get("created_at", 0))),
		"expires_at": maxi(0, int(raw.get("expires_at", 0))) if kind == KIND_DAILY else 0,
	}
