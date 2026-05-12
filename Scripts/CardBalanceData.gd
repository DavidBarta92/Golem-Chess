extends Resource
class_name CardBalanceData

const CURRENT_SCHEMA_VERSION: int = 1

@export var schema_version: int = CURRENT_SCHEMA_VERSION
@export var session_id: String = ""
@export var source_match_count: int = 0
@export var generated_unix: int = 0
@export var promoted_sessions: Array[String] = []
@export var win_condition_counts: Dictionary = {}
@export var cards: Dictionary = {}

func get_card_value(card_name: String, fallback: float = 0.0) -> float:
	var stats = cards.get(card_name, {})
	if stats is Dictionary:
		return float(stats.get("v", fallback))
	return fallback

func get_card_weight(card_name: String) -> int:
	var stats = cards.get(card_name, {})
	if stats is Dictionary:
		return int(stats.get("w", 0))
	return 0

func has_promoted_session(id: String) -> bool:
	return promoted_sessions.has(id)
