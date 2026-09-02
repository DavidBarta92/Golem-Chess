extends RefCounted
class_name StampEffect

const TYPE_NONE: String = "none"
const TYPE_STEAL_STAMP: String = "steal_stamp"
const TYPE_GRANT_STAMP: String = "grant_stamp"
const TYPE_GIVE_STAMP: String = "give_stamp"
const TYPE_MOVE_BASE: String = "move_base"
const TYPE_INVISIBLE_TO_ENEMY: String = "invisible_to_enemy"
const TYPE_INVALID_SQUARES: String = "invalid_squares"
const TYPE_FROZEN_SQUARES: String = "frozen_squares"
const TYPE_BOMB: String = "bomb"
const TYPE_UNCAPTURABLE: String = "uncapturable"
const TYPE_INCREASE_OWN_DURATIONS: String = "increase_own_durations"
const TYPE_INCREASE_ENEMY_DURATIONS: String = "increase_enemy_durations"
const TYPE_DECREASE_OWN_DURATIONS: String = "decrease_own_durations"
const TYPE_DECREASE_ENEMY_DURATIONS: String = "decrease_enemy_durations"
const TYPE_INCREASE_SELF_DURATION: String = "increase_self_duration"

const TRIGGER_ON_AFFIX: String = "on_affix"
const TRIGGER_ON_MOVE: String = "on_move"
const TRIGGER_ON_CAPTURE: String = "on_capture"
const TRIGGER_ON_CAPTURED: String = "on_captured"
const TRIGGER_ON_EXPIRE: String = "on_expire"
const TRIGGER_WHILE_ATTACHED: String = "while_attached"
const TRIGGER_ON_SYMBOL_COUNT: String = "on_symbol_count"

const MOVEMENT_NONE: int = 0
const MOVEMENT_MOVE_AND_CAPTURE: int = 1
const MOVEMENT_MOVE_ONLY: int = 2
const MOVEMENT_CAPTURE_ONLY: int = 3

const EFFECT_ICON_TEXTURES: Dictionary = {
	TYPE_STEAL_STAMP: preload("res://Assets/effect_icon_steal_stamp.svg"),
	TYPE_GRANT_STAMP: preload("res://Assets/effect_icon_grant_stamp.svg"),
	TYPE_GIVE_STAMP: preload("res://Assets/effect_icon_give_stamp.svg"),
	TYPE_MOVE_BASE: preload("res://Assets/effect_icon_move_base.svg"),
	TYPE_INVISIBLE_TO_ENEMY: preload("res://Assets/effect_icon_invisible_to_enemy.svg"),
	TYPE_INVALID_SQUARES: preload("res://Assets/effect_icon_invalid_squares.svg"),
	TYPE_FROZEN_SQUARES: preload("res://Assets/effect_icon_frozen_squares.svg"),
	TYPE_BOMB: preload("res://Assets/effect_icon_bomb.svg"),
	TYPE_UNCAPTURABLE: preload("res://Assets/effect_icon_uncapturable.svg"),
	TYPE_INCREASE_OWN_DURATIONS: preload("res://Assets/effect_icon_incrase_own_duration.svg"),
	TYPE_INCREASE_ENEMY_DURATIONS: preload("res://Assets/effect_icon_incrase_enemy_duration.svg"),
	TYPE_DECREASE_OWN_DURATIONS: preload("res://Assets/effect_icon_decrease_own_duration.svg"),
	TYPE_DECREASE_ENEMY_DURATIONS: preload("res://Assets/effect_icon_decrease_enemy_duration.svg"),
	TYPE_INCREASE_SELF_DURATION: preload("res://Assets/effect_icon_incrase_self_duration.svg"),
}

const EFFECT_ICON_STANDALONE_TEXTURES: Dictionary = {
	TYPE_STEAL_STAMP: preload("res://Assets/effect_icon_steal_stamp_standalone.svg"),
	TYPE_GRANT_STAMP: preload("res://Assets/effect_icon_grant_stamp_standalone.svg"),
	TYPE_GIVE_STAMP: preload("res://Assets/effect_icon_give_stamp_standalone.svg"),
	TYPE_MOVE_BASE: preload("res://Assets/effect_icon_move_base_standalone.svg"),
	TYPE_INVISIBLE_TO_ENEMY: preload("res://Assets/effect_icon_invisible_to_enemy_standalone.svg"),
	TYPE_INVALID_SQUARES: preload("res://Assets/effect_icon_invalid_squares_standalone.svg"),
	TYPE_FROZEN_SQUARES: preload("res://Assets/effect_icon_frozen_squares_standalone.svg"),
	TYPE_BOMB: preload("res://Assets/effect_icon_bomb_standalone.svg"),
	TYPE_UNCAPTURABLE: preload("res://Assets/effect_icon_uncapturable_standalone.svg"),
	TYPE_INCREASE_OWN_DURATIONS: preload("res://Assets/effect_icon_incrase_own_duration_standalone.svg"),
	TYPE_INCREASE_ENEMY_DURATIONS: preload("res://Assets/effect_icon_incrase_enemy_duration_standalone.svg"),
	TYPE_DECREASE_OWN_DURATIONS: preload("res://Assets/effect_icon_decrease_own_duration_standalone.svg"),
	TYPE_DECREASE_ENEMY_DURATIONS: preload("res://Assets/effect_icon_decrease_enemy_duration_standalone.svg"),
	TYPE_INCREASE_SELF_DURATION: preload("res://Assets/effect_icon_incrase_self_duration_standalone.svg"),
}

const TRIGGER_ICON_TEXTURES: Dictionary = {
	TRIGGER_ON_AFFIX: preload("res://Assets/trigger_on_affixed.svg"),
	TRIGGER_ON_MOVE: preload("res://Assets/trigger_on_move.svg"),
	TRIGGER_ON_CAPTURE: preload("res://Assets/trigger_on_captures.svg"),
	TRIGGER_ON_CAPTURED: preload("res://Assets/trigger_on_captured.svg"),
	TRIGGER_ON_EXPIRE: preload("res://Assets/trigger_expired.svg"),
}

static func get_effect_icon_texture(effect_type: String) -> Texture2D:
	return EFFECT_ICON_TEXTURES.get(effect_type)

static func get_effect_icon_standalone_texture(effect_type: String) -> Texture2D:
	return EFFECT_ICON_STANDALONE_TEXTURES.get(effect_type)

static func get_trigger_icon_texture(effect_trigger: String) -> Texture2D:
	return TRIGGER_ICON_TEXTURES.get(effect_trigger)

static func has_effect(effect_type: String) -> bool:
	return !effect_type.is_empty() && effect_type != TYPE_NONE

static func get_effect_label(effect_type: String) -> String:
	match effect_type:
		TYPE_STEAL_STAMP:
			return "ST"
		TYPE_GRANT_STAMP:
			return "GC"
		TYPE_GIVE_STAMP:
			return "GV"
		TYPE_MOVE_BASE:
			return "MB"
		TYPE_INVISIBLE_TO_ENEMY:
			return "IN"
		TYPE_INVALID_SQUARES:
			return "IX"
		TYPE_FROZEN_SQUARES:
			return "FR"
		TYPE_BOMB:
			return "BO"
		TYPE_UNCAPTURABLE:
			return "UC"
		TYPE_INCREASE_OWN_DURATIONS:
			return "O+"
		TYPE_INCREASE_ENEMY_DURATIONS:
			return "E+"
		TYPE_DECREASE_OWN_DURATIONS:
			return "O-"
		TYPE_DECREASE_ENEMY_DURATIONS:
			return "E-"
		TYPE_INCREASE_SELF_DURATION:
			return "S+"
		_:
			return "FX" if has_effect(effect_type) else ""

static func get_effect_display_name(effect_type: String) -> String:
	match effect_type:
		TYPE_STEAL_STAMP:
			return "Steal Stamp"
		TYPE_GRANT_STAMP:
			return "Grant Stamp"
		TYPE_GIVE_STAMP:
			return "Give Stamp"
		TYPE_MOVE_BASE:
			return "Move Base"
		TYPE_INVISIBLE_TO_ENEMY:
			return "Invisible"
		TYPE_INVALID_SQUARES:
			return "Invalid Squares"
		TYPE_FROZEN_SQUARES:
			return "Frozen Squares"
		TYPE_BOMB:
			return "Bomb"
		TYPE_UNCAPTURABLE:
			return "Uncapturable"
		TYPE_INCREASE_OWN_DURATIONS:
			return "Increase Own Durations"
		TYPE_INCREASE_ENEMY_DURATIONS:
			return "Increase Enemy Durations"
		TYPE_DECREASE_OWN_DURATIONS:
			return "Decrease Own Durations"
		TYPE_DECREASE_ENEMY_DURATIONS:
			return "Decrease Enemy Durations"
		TYPE_INCREASE_SELF_DURATION:
			return "Increase Self Duration"
		_:
			return ""
