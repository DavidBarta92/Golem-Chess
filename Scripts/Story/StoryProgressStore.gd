extends Node

## Everything the story mode needs to remember between sessions.
##
## Progress is stored as *sets of ids*, never as an index into the chapter
## list, so reordering or inserting story nodes never invalidates an existing
## save. "Where am I" is derived by StoryManager (the first node whose id is
## not in completed_node_ids); this store only records facts.

const PROGRESS_SCHEMA_VERSION: int = 3
const PROGRESS_FILE_NAME: String = "story_progress.json"

const KEY_COMPLETED_NODES: String = "completed_node_ids"
const KEY_UNLOCKED_FEATURES: String = "unlocked_features"
const KEY_SEEN_HINTS: String = "seen_feature_hints"
const KEY_GRANTED_REWARDS: String = "granted_reward_ids"
const KEY_NODE_ATTEMPTS: String = "node_attempts"
const KEY_UNLOCKED_PACKS: String = "unlocked_pack_ids"

signal node_completed(node_id: String)
signal feature_unlocked(feature_id: String)
signal feature_hint_seen(feature_id: String)
signal pack_unlocked(pack_id: String)

var progress_data: Dictionary = {}
var is_loaded: bool = false

func ensure_loaded() -> void:
	if is_loaded:
		return

	var raw_data: Dictionary = SaveIO.read_json(PROGRESS_FILE_NAME)
	if raw_data.is_empty():
		progress_data = _create_default_progress()
		is_loaded = true
		save_progress()
		return

	progress_data = _normalize_progress(raw_data)
	is_loaded = true
	save_progress()

# --- Story nodes ------------------------------------------------------------

func is_node_completed(node_id: String) -> bool:
	ensure_loaded()
	return _get_id_list(KEY_COMPLETED_NODES).has(node_id.strip_edges())

func mark_node_completed(node_id: String) -> void:
	if _add_id(KEY_COMPLETED_NODES, node_id):
		save_progress()
		node_completed.emit(node_id.strip_edges())

func get_completed_node_ids() -> Array[String]:
	ensure_loaded()
	return _get_id_list(KEY_COMPLETED_NODES).duplicate()

## Bumps and returns how many times the player has started a given node.
## Boss dialogue can use this to react to a repeated attempt ("back again?").
func register_node_attempt(node_id: String) -> int:
	ensure_loaded()
	var normalized_id: String = node_id.strip_edges()
	if normalized_id.is_empty():
		return 0

	var attempts: Dictionary = progress_data.get(KEY_NODE_ATTEMPTS, {})
	var next_count: int = maxi(0, int(attempts.get(normalized_id, 0))) + 1
	attempts[normalized_id] = next_count
	progress_data[KEY_NODE_ATTEMPTS] = attempts
	save_progress()
	return next_count

func get_node_attempts(node_id: String) -> int:
	ensure_loaded()
	var attempts: Dictionary = progress_data.get(KEY_NODE_ATTEMPTS, {})
	return maxi(0, int(attempts.get(node_id.strip_edges(), 0)))

# --- Feature unlocks --------------------------------------------------------

func is_feature_unlocked(feature_id: String) -> bool:
	ensure_loaded()
	return _get_id_list(KEY_UNLOCKED_FEATURES).has(feature_id.strip_edges())

## Returns true only when this call is what unlocked it, so a reward scene can
## tell "just unlocked, play the fanfare" from "already had it".
func unlock_feature(feature_id: String) -> bool:
	if !_add_id(KEY_UNLOCKED_FEATURES, feature_id):
		return false
	save_progress()
	feature_unlocked.emit(feature_id.strip_edges())
	return true

func get_unlocked_feature_ids() -> Array[String]:
	ensure_loaded()
	return _get_id_list(KEY_UNLOCKED_FEATURES).duplicate()

# --- Feature hints (the arrow that points at a freshly unlocked button) -----

func should_show_feature_hint(feature_id: String) -> bool:
	var normalized_id: String = feature_id.strip_edges()
	if normalized_id.is_empty():
		return false
	return is_feature_unlocked(normalized_id) and !has_seen_feature_hint(normalized_id)

func has_seen_feature_hint(feature_id: String) -> bool:
	ensure_loaded()
	return _get_id_list(KEY_SEEN_HINTS).has(feature_id.strip_edges())

func mark_feature_hint_seen(feature_id: String) -> void:
	if !_add_id(KEY_SEEN_HINTS, feature_id):
		return
	save_progress()
	feature_hint_seen.emit(feature_id.strip_edges())

# --- Pack unlocks -----------------------------------------------------------

## Packs the story has made purchasable. The shop shows only these (and only
## while the pack's own `available` flag is on), so a fresh save sees an empty
## shop until the story opens it.
func is_pack_unlocked(pack_id: String) -> bool:
	ensure_loaded()
	return _get_id_list(KEY_UNLOCKED_PACKS).has(pack_id.strip_edges())

func unlock_pack(pack_id: String) -> bool:
	if !_add_id(KEY_UNLOCKED_PACKS, pack_id):
		return false
	save_progress()
	pack_unlocked.emit(pack_id.strip_edges())
	return true

func get_unlocked_pack_ids() -> Array[String]:
	ensure_loaded()
	return _get_id_list(KEY_UNLOCKED_PACKS).duplicate()

# --- Reward payouts ---------------------------------------------------------

## Rewards must only ever pay out once. A reward scene can be re-entered after
## a crash, an alt-f4 or a retry, so every payout is guarded by an id.
func is_reward_granted(reward_id: String) -> bool:
	ensure_loaded()
	return _get_id_list(KEY_GRANTED_REWARDS).has(reward_id.strip_edges())

func mark_reward_granted(reward_id: String) -> bool:
	if !_add_id(KEY_GRANTED_REWARDS, reward_id):
		return false
	save_progress()
	return true

# --- Persistence ------------------------------------------------------------

func save_progress() -> bool:
	if progress_data.is_empty():
		progress_data = _create_default_progress()
	return SaveIO.write_json(PROGRESS_FILE_NAME, progress_data, PROGRESS_SCHEMA_VERSION)

## Debug helper: wipes story progress and starts over from the first node.
func reset_progress() -> void:
	progress_data = _create_default_progress()
	is_loaded = true
	save_progress()

func _create_default_progress() -> Dictionary:
	var default_features: Array[String] = []
	default_features.assign(StoryFeatures.DEFAULT_UNLOCKED_FEATURE_IDS)
	var empty_nodes: Array[String] = []
	var empty_hints: Array[String] = []
	var empty_rewards: Array[String] = []
	var empty_packs: Array[String] = []
	return {
		"schema_version": PROGRESS_SCHEMA_VERSION,
		KEY_COMPLETED_NODES: empty_nodes,
		KEY_UNLOCKED_FEATURES: default_features,
		KEY_SEEN_HINTS: empty_hints,
		KEY_GRANTED_REWARDS: empty_rewards,
		KEY_NODE_ATTEMPTS: {},
		KEY_UNLOCKED_PACKS: empty_packs,
	}

func _normalize_progress(raw_data: Dictionary) -> Dictionary:
	var normalized: Dictionary = {
		"schema_version": PROGRESS_SCHEMA_VERSION,
		KEY_COMPLETED_NODES: _normalize_id_list(raw_data.get(KEY_COMPLETED_NODES, [])),
		KEY_UNLOCKED_FEATURES: _normalize_id_list(raw_data.get(KEY_UNLOCKED_FEATURES, [])),
		KEY_SEEN_HINTS: _normalize_id_list(raw_data.get(KEY_SEEN_HINTS, [])),
		KEY_GRANTED_REWARDS: _normalize_id_list(raw_data.get(KEY_GRANTED_REWARDS, [])),
		KEY_NODE_ATTEMPTS: _normalize_attempts(raw_data.get(KEY_NODE_ATTEMPTS, {})),
		KEY_UNLOCKED_PACKS: _normalize_id_list(raw_data.get(KEY_UNLOCKED_PACKS, [])),
	}

	# Schema 1 had no feature list at all; anything saved before features
	# existed still has to come back with the baseline unlocked.
	var unlocked: Array[String] = normalized[KEY_UNLOCKED_FEATURES]
	for feature_id in StoryFeatures.DEFAULT_UNLOCKED_FEATURE_IDS:
		if !unlocked.has(feature_id):
			unlocked.append(feature_id)
	return normalized

func _normalize_id_list(raw_value) -> Array[String]:
	var ids: Array[String] = []
	var seen_ids: Dictionary = {}
	if !(raw_value is Array):
		return ids

	for id_value in raw_value:
		var id_text: String = str(id_value).strip_edges()
		if id_text.is_empty() or seen_ids.has(id_text):
			continue
		seen_ids[id_text] = true
		ids.append(id_text)
	return ids

func _normalize_attempts(raw_value) -> Dictionary:
	var attempts: Dictionary = {}
	if !(raw_value is Dictionary):
		return attempts

	for key in raw_value:
		var node_id: String = str(key).strip_edges()
		var count: int = maxi(0, int(raw_value[key]))
		if node_id.is_empty() or count <= 0:
			continue
		attempts[node_id] = count
	return attempts

## Always hands back a typed, de-duplicated list and writes the normalized
## version back, so the rest of the store never has to care whether the value
## came from a fresh default or straight out of the save file.
func _get_id_list(key: String) -> Array[String]:
	var ids: Array[String] = _normalize_id_list(progress_data.get(key, []))
	progress_data[key] = ids
	return ids

## Returns true when the id was actually added (i.e. it wasn't there yet).
func _add_id(key: String, raw_id: String) -> bool:
	ensure_loaded()
	var id_text: String = raw_id.strip_edges()
	if id_text.is_empty():
		return false

	var ids: Array[String] = _get_id_list(key)
	if ids.has(id_text):
		return false
	ids.append(id_text)
	progress_data[key] = ids
	return true
