@tool
extends RefCounted

# Reference stamps of the value formula. With the default weights (StampValueWeights' own
# defaults, not the tuned .tres) each one has to land within TOLERANCE of its expected value.
# Run it with the dock's "Önteszt" button, or headless with tests/run_selftest.gd.

const TOLERANCE: float = 0.1

# Pattern rows from the front: "." empty, "@" the golem, "m" move only, "c" capture only,
# "X" move and capture.
const REFERENCES: Array = [
	{
		"name": "Lance",
		"rows": ["..X..", "..X..", "..@..", "..X..", "....."],
		"duration": 2,
		"expected": 9.4,
	},
	{
		"name": "Archer",
		"rows": ["..c..", ".c.c.", "c.@.c", ".c.c.", "..c.."],
		"duration": 1,
		"expected": 9.0,
	},
	{
		"name": "Berserk",
		"rows": ["..X..", ".X.X.", "..@..", ".X.X.", "..X.."],
		"duration": 1,
		"effect_type": StampEffect.TYPE_INCREASE_SELF_DURATION,
		"effect_trigger": StampEffect.TRIGGER_ON_CAPTURE,
		"expected": 12.5,
	},
	{
		"name": "Knight",
		"rows": [".X.X.", "X...X", "..@..", "X...X", ".X.X."],
		"duration": 4,
		"expected": 45.3,
	},
	{
		"name": "Lance mint Overseal",
		"rows": ["..X..", "..X..", "..@..", "..X..", "....."],
		"duration": 2,
		"role": Stamp.Role.OVERSEAL,
		"expected": 11.3,
	},
	# The crown cases hold for crowns costing "crown_points", and the Se-tenant one for a set of
	# "se_tenant_set_size"; with other rules they are skipped.
	{
		"name": "Koronapont felragasztáskor",
		"rows": [".....", ".....", "..@..", ".....", "....."],
		"duration": 1,
		"effect_type": StampEffect.TYPE_GAIN_CROWN_POINT,
		"effect_trigger": StampEffect.TRIGGER_ON_AFFIX,
		"crown_points": 6,
		"expected": 4.0,
	},
	{
		"name": "Koronapont koronázáskor",
		"rows": [".....", ".....", "..@..", ".....", "....."],
		"duration": 3,
		"effect_type": StampEffect.TYPE_GAIN_CROWN_POINT,
		"effect_trigger": StampEffect.TRIGGER_CROWN_CONDITION,
		"crown_points": 6,
		"expected": 1.0,
	},
	{
		"name": "Lance, lépésenként −1 ellenséges koronapont",
		"rows": ["..X..", "..X..", "..@..", "..X..", "....."],
		"duration": 2,
		"effect_type": StampEffect.TYPE_REMOVE_ENEMY_CROWN_POINT,
		"effect_trigger": StampEffect.TRIGGER_ON_MOVE,
		"crown_points": 6,
		"expected": 17.4,
	},
	{
		"name": "Se-tenant sor, D = 5",
		"rows": [".....", ".....", "..@..", ".....", "....."],
		"duration": 5,
		"role": Stamp.Role.SE_TENANT,
		"crown_points": 6,
		"se_tenant_set_size": 3,
		"expected": 4.0,
	},
]

const CELL_CODES: Dictionary = {
	"m": StampEffect.MOVEMENT_MOVE_ONLY,
	"c": StampEffect.MOVEMENT_CAPTURE_ONLY,
	"X": StampEffect.MOVEMENT_MOVE_AND_CAPTURE,
}

# One entry per reference stamp: {name, expected, actual, passed, skipped}.
# A skipped case counts as passed; skipped is empty unless it was skipped, and then says why.
static func run() -> Array[Dictionary]:
	var weights: StampValueWeights = StampValueWeights.new()
	var crown_points_required: int = StampValueCalculator.crown_points_required(weights)
	var se_tenant_set_size: int = StampValueCalculator.se_tenant_set_size(weights)
	var results: Array[Dictionary] = []
	for reference: Dictionary in REFERENCES:
		var skipped: String = ""
		if reference.has("crown_points") && reference.crown_points != crown_points_required:
			skipped = "a várt érték %d pontos koronára szól, most %d pontba kerül" % [reference.crown_points, crown_points_required]
		elif reference.has("se_tenant_set_size") && reference.se_tenant_set_size != se_tenant_set_size:
			skipped = "a várt érték %d bélyeges Se-tenant sorra szól, most %d bélyeges" % [reference.se_tenant_set_size, se_tenant_set_size]
		if !skipped.is_empty():
			results.append({
				"name": reference.name,
				"expected": reference.expected,
				"actual": 0.0,
				"passed": true,
				"skipped": skipped,
			})
			continue

		var breakdown: StampValueCalculator.Breakdown = StampValueCalculator.calculate_values(
			_parse_pattern(reference.rows),
			reference.duration,
			reference.get("role", Stamp.Role.UNIT),
			reference.get("effect_type", StampEffect.TYPE_NONE),
			reference.get("effect_trigger", StampEffect.TRIGGER_ON_AFFIX),
			[],
			weights
		)
		results.append({
			"name": reference.name,
			"expected": reference.expected,
			"actual": breakdown.total,
			"passed": absf(breakdown.total - reference.expected) <= TOLERANCE,
			"skipped": "",
		})
	return results

static func describe(result: Dictionary) -> String:
	if !result.skipped.is_empty():
		return "KIHAGYVA  %s: %s" % [result.name, result.skipped]
	return "%s  %s: %.2f (várt: %.1f ±%.1f)" % [
		"OK" if result.passed else "HIBA",
		result.name,
		result.actual,
		result.expected,
		TOLERANCE,
	]

static func _parse_pattern(rows: Array) -> Array:
	var pattern: Array = []
	for row: String in rows:
		var cells: Array = []
		for code in row:
			cells.append(CELL_CODES.get(code, StampEffect.MOVEMENT_NONE))
		pattern.append(cells)
	return pattern
