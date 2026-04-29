extends RefCounted
class_name CardEffect

const TYPE_NONE: String = "none"
const TYPE_SHARED_CONTROL: String = "shared_control"
const TYPE_STEAL_CARD: String = "steal_card"
const TYPE_MOVE_BASE: String = "move_base"
const TYPE_INVISIBLE_TO_ENEMY: String = "invisible_to_enemy"
const TYPE_INVALID_SQUARES: String = "invalid_squares"
const TYPE_FROZEN_SQUARES: String = "frozen_squares"
const TYPE_BOMB: String = "bomb"

const TRIGGER_ON_ATTACH: String = "on_attach"
const TRIGGER_ON_MOVE: String = "on_move"
const TRIGGER_ON_CAPTURE: String = "on_capture"
const TRIGGER_ON_CAPTURED: String = "on_captured"
const TRIGGER_ON_EXPIRE: String = "on_expire"
const TRIGGER_WHILE_ATTACHED: String = "while_attached"

const MOVEMENT_NONE: int = 0
const MOVEMENT_MOVE_AND_CAPTURE: int = 1
const MOVEMENT_MOVE_ONLY: int = 2
const MOVEMENT_CAPTURE_ONLY: int = 3

static func has_effect(effect_type: String) -> bool:
	return !effect_type.is_empty() && effect_type != TYPE_NONE

static func get_effect_label(effect_type: String) -> String:
	match effect_type:
		TYPE_SHARED_CONTROL:
			return "SC"
		TYPE_STEAL_CARD:
			return "ST"
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
		_:
			return "FX" if has_effect(effect_type) else ""

static func get_effect_display_name(effect_type: String) -> String:
	match effect_type:
		TYPE_SHARED_CONTROL:
			return "Shared Control"
		TYPE_STEAL_CARD:
			return "Steal Card"
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
		_:
			return ""
