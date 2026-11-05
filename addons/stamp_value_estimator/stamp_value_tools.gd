@tool
extends RefCounted

# Editor-side helpers of the Stamp Value Estimator: finding the stamps, keeping
# Stamp.estimated_value in step with the weights, and the Hungarian breakdown text of the
# Inspector field and the dock.

const STAMPS_PATH: String = "res://Stamps/"

static func find_stamp_paths(directory_path: String = STAMPS_PATH) -> PackedStringArray:
	var paths: PackedStringArray = PackedStringArray()
	var dir: DirAccess = DirAccess.open(directory_path)
	if dir == null:
		return paths

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var path: String = directory_path.path_join(file_name)
		if dir.current_is_dir():
			paths.append_array(find_stamp_paths(path))
		elif file_name.ends_with(".tres"):
			paths.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()
	return paths

static func load_stamps() -> Array[Stamp]:
	var stamps: Array[Stamp] = []
	for path in find_stamp_paths():
		var stamp: Stamp = load(path) as Stamp
		if stamp != null:
			stamps.append(stamp)
	return stamps

# Two decimals, so the .tres files stay readable.
static func stored_value(breakdown: StampValueCalculator.Breakdown) -> float:
	return ("%.2f" % breakdown.total).to_float()

static func is_stale(stamp: Stamp, breakdown: StampValueCalculator.Breakdown) -> bool:
	return !is_equal_approx(stamp.estimated_value, stored_value(breakdown))

static func are_weights_unsaved(weights: StampValueWeights) -> bool:
	return EditorInterface.is_object_edited(weights)

# Whether the file holds something other than this copy, the estimate aside. The editor
# reloads a file changed outside it (git, a script) only after it has reported the new
# files, so a sync can run on the old copy, and saving that would undo the change.
static func is_file_different(stamp: Stamp) -> bool:
	var on_disk: Stamp = ResourceLoader.load(stamp.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Stamp
	if on_disk == null:
		return false
	for property: Dictionary in stamp.get_script().get_script_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or property.name == "estimated_value":
			continue
		if !_is_same_stored_value(stamp.get(property.name), on_disk.get(property.name)):
			return true
	return false

# A built-in subresource is a new object on every load, so only a file's path can be compared.
static func _is_same_stored_value(left: Variant, right: Variant) -> bool:
	if left is Resource and right is Resource:
		return left.resource_path.contains("::") or left.resource_path == right.resource_path
	return left == right

# Brings every stamp's estimated_value in line with the weights, without letting a file and
# the memory drift apart:
# - a stamp with unsaved edits gets the value in memory, and the user's next save writes it;
# - a clean stamp is saved right away, but only while the weights are saved too, so no file
#   ever holds a value from unsaved weights. It waits for the weights' save instead;
# - a clean stamp whose file has changed is left alone: the reload that follows syncs it.
# Returns {saved, pending, waiting, reloading, failed} stamp counts.
static func sync_stamps(stamps: Array[Stamp]) -> Dictionary:
	var weights: StampValueWeights = StampValueCalculator.load_weights()
	var weights_unsaved: bool = are_weights_unsaved(weights)
	var counts: Dictionary = {"saved": 0, "pending": 0, "waiting": 0, "reloading": 0, "failed": 0}
	for stamp in stamps:
		var breakdown: StampValueCalculator.Breakdown = StampValueCalculator.calculate(stamp, weights)
		if !is_stale(stamp, breakdown):
			continue

		if EditorInterface.is_object_edited(stamp):
			stamp.estimated_value = stored_value(breakdown)
			counts.pending += 1
		elif weights_unsaved:
			counts.waiting += 1
		elif is_file_different(stamp):
			counts.reloading += 1
		else:
			stamp.estimated_value = stored_value(breakdown)
			if ResourceSaver.save(stamp) == OK:
				counts.saved += 1
			else:
				counts.failed += 1
	return counts

static func report(counts: Dictionary) -> void:
	var parts: PackedStringArray = PackedStringArray()
	if counts.saved > 0:
		parts.append("%d bélyeg becsült értéke mentve." % counts.saved)
	if counts.pending > 0:
		parts.append("%d mentetlen bélyegen a memóriában frissült, a mentésükkel kerül a fájlba." % counts.pending)
	if counts.waiting > 0:
		parts.append("%d bélyeg a súlyok mentésekor frissül." % counts.waiting)
	if counts.reloading > 0:
		parts.append("%d bélyeg fájlja megváltozott, az újratöltése után frissül." % counts.reloading)
	if counts.failed > 0:
		parts.append("%d bélyeget nem sikerült menteni." % counts.failed)
	if parts.is_empty():
		parts.append("minden mentett érték naprakész.")

	var severity: EditorToaster.Severity = EditorToaster.SEVERITY_INFO
	if counts.failed > 0:
		severity = EditorToaster.SEVERITY_ERROR
	EditorInterface.get_editor_toaster().push_toast("Bélyegértékek: " + " ".join(parts), severity)

static func role_name(role: int) -> String:
	var key: Variant = Stamp.Role.find_key(role)
	return String(key).capitalize() if key != null else str(role)

static func describe(breakdown: StampValueCalculator.Breakdown) -> PackedStringArray:
	var duration_text: String = _format_number(breakdown.duration)
	if breakdown.is_infinite_duration:
		duration_text = "∞ → %s" % duration_text

	var lines: PackedStringArray = PackedStringArray()
	lines.append("M = %.2f    T(D) = %.2f  (D = %s)    S = %.2f" % [
		breakdown.movement,
		breakdown.duration_factor,
		duration_text,
		breakdown.role_factor,
	])
	lines.append("Mozgásrész: M × T(D) × S = %.2f" % breakdown.movement_part)
	if breakdown.se_tenant_set_size > 0:
		lines.append("Szerepképesség: R = %.2f  (Se-tenant sor, %d bélyeg)" % [
			breakdown.role_part,
			breakdown.se_tenant_set_size,
		])
	lines.append("Hatásrész: ΣE = %.2f" % breakdown.effect_part)
	for effect in breakdown.effects:
		lines.append("    %s · %s: %.2f × %.2f = %.2f" % [
			effect.type,
			effect.trigger,
			effect.base,
			effect.trigger_factor,
			effect.value,
		])
	if breakdown.crown_points_required > 0:
		lines.append("Korona: %d pontba kerül, 1 pont = %.2f" % [
			breakdown.crown_points_required,
			breakdown.crown_point_value,
		])
	lines.append("Mozgásminta: %d cella, ebből %d ütő (c/X) és %d távoli" % [
		breakdown.cell_count,
		breakdown.capture_cell_count,
		breakdown.far_cell_count,
	])
	return lines

static func warning_lines(breakdown: StampValueCalculator.Breakdown) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for effect_type in breakdown.unknown_effect_types:
		lines.append("Ismeretlen hatástípus: \"%s\", az értéke 0." % effect_type)
	for effect_trigger in breakdown.unknown_triggers:
		lines.append("Ismeretlen kiváltó: \"%s\", a hatás értéke 0." % effect_trigger)
	if breakdown.crown_rules_missing:
		lines.append("Nem olvasható, hány pontba kerül a korona (GameConfig.crown_points_required), ezért a koronás rész értéke 0. A súlyok crown_points_required mezőjében megadhatod.")
	if breakdown.se_tenant_rules_missing:
		lines.append("Nem olvasható, hány bélyeg a Se-tenant sor (GameStateData.SE_TENANT_SET_SIZE), ezért R = 0. A súlyok se_tenant_set_size mezőjében megadhatod.")
	return lines

static func _format_number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.2f" % value
