extends RewardPresenter
class_name SequencePresenter

## Runs its child presenters one after another - the final reward drops a pile
## of coins first and only then flies the stamp in. Only the active child takes
## clicks; the rest stay out of the way.

var _steps: Array[RewardPresenter] = []
var _index: int = -1

func _start() -> void:
	for child in get_children():
		if child is RewardPresenter:
			_steps.append(child)
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The sequence itself is just a host; clicks belong to the active step.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_next()

func _next() -> void:
	if _index >= 0 and _index < _steps.size():
		_steps[_index].mouse_filter = Control.MOUSE_FILTER_IGNORE
	_index += 1
	if _index >= _steps.size():
		finish()
		return
	var step: RewardPresenter = _steps[_index]
	step.mouse_filter = Control.MOUSE_FILTER_STOP
	step.presentation_finished.connect(_next, CONNECT_ONE_SHOT)
	step.begin(reward_scene, granted_now)
