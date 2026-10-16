extends RefCounted
class_name StoryFeatures

## Named ids for the parts of the UI that the story unlocks and introduces.
##
## A "feature" is anything a FeatureHint node can gate and point at: a main
## menu button, a top bar button, a panel inside another screen. Adding one
## later means adding a constant here, listing it in ALL_FEATURE_IDS, and
## dropping a FeatureHint into the scene that owns the button - no changes to
## the store or the hint node itself.
##
## Unlocking and hinting are deliberately separate:
##   * unlocked  -> the button works at all (locked buttons are disabled)
##   * hint seen -> the player has clicked it at least once, so the arrow that
##                  points at it can stop showing

const PLAY: String = "play"
const COLLECTION: String = "collection"
const BUY_PACKS: String = "buy_packs"
## The story's own multiplayer entry - a new main menu button, not the
## developer one in the top bar.
const MULTIPLAYER: String = "multiplayer"
const QUESTS: String = "quests"
const TRADE: String = "trade"

## Features that are available from a brand new save. Everything else stays
## locked until a story node (usually a reward scene) unlocks it.
const DEFAULT_UNLOCKED_FEATURE_IDS: Array[String] = [
	PLAY,
]

const ALL_FEATURE_IDS: Array[String] = [
	PLAY,
	COLLECTION,
	BUY_PACKS,
	MULTIPLAYER,
	QUESTS,
	TRADE,
]

static func is_known_feature_id(feature_id: String) -> bool:
	return ALL_FEATURE_IDS.has(feature_id.strip_edges())
