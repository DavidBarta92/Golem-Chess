extends ConfirmationDialog
class_name MoveEndsTurnDialog

## Stops a player about to move while a stamp is still waiting to go on a
## sleeping golem.
##
## A move always ends the turn, so the click that moves a piece is the last
## moment at which the stamp could have been affixed. That is easy to spend by
## accident, and hard to see coming until it has happened once.
##
## Three ways out, because there are three things a player might mean:
##
##   - **Ok** - yes, move anyway
##   - **Cancel** - no, I had not noticed; let me affix first
##   - **Don't show again** - move, and stop asking
##
## The third is a setting rather than a flag for this match: once a player has
## the rule, they should not have to turn the warning off again every game.

signal move_confirmed

const NEVER_AGAIN_ACTION: StringName = &"never_again"

func _ready() -> void:
	title = tr("MOVE_ENDS_TURN_TITLE")
	dialog_text = tr("MOVE_ENDS_TURN_BODY")
	ok_button_text = tr("Ok")
	cancel_button_text = tr("Cancel")
	exclusive = true
	# On the left, away from the two the player is likely to be aiming for.
	var never_again: Button = add_button(tr("DONT_SHOW_AGAIN"), false, NEVER_AGAIN_ACTION)
	for button: Button in [get_ok_button(), get_cancel_button(), never_again]:
		_shrink(button)
	confirmed.connect(_on_confirmed)
	custom_action.connect(_on_custom_action)

## The dialog's own buttons come out heavier than the rest of the interface,
## which makes a passing warning look like a decision. Smaller type and
## tighter padding settle them down.
func _shrink(button: Button) -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size", 14)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box: StyleBox = button.get_theme_stylebox(state)
		if box == null:
			continue
		var tightened: StyleBox = box.duplicate()
		tightened.content_margin_left = 12
		tightened.content_margin_right = 12
		tightened.content_margin_top = 5
		tightened.content_margin_bottom = 5
		button.add_theme_stylebox_override(state, tightened)

func _on_confirmed() -> void:
	move_confirmed.emit()

func _on_custom_action(action: StringName) -> void:
	if action != NEVER_AGAIN_ACTION:
		return
	SettingsDataManager.set_move_ends_turn_warning_enabled(false)
	hide()
	move_confirmed.emit()
