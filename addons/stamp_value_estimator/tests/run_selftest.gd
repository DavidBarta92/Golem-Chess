extends SceneTree

# Headless run of the stamp value self-test; the exit code is 1 if a reference stamp is off:
#   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://addons/stamp_value_estimator/tests/run_selftest.gd
# The self-test is loaded by path because a --script file is compiled before the autoloads
# exist, so it must not name project classes itself.

func _initialize() -> void:
	var selftest: Script = load("res://addons/stamp_value_estimator/stamp_value_selftest.gd")
	var failed: int = 0
	for result in selftest.run():
		print(selftest.describe(result))
		if !result.passed:
			failed += 1

	print("Stamp value self-test: %s" % ("passed" if failed == 0 else "%d failed" % failed))
	quit(1 if failed > 0 else 0)
