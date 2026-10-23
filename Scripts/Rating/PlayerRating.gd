extends RefCounted

## The player's rating: Glicko-2 (Glickman, 2012), kept as a rating, a
## deviation and a volatility but shown to the player as the one number.
##
## Glicko-2 rather than plain Elo because a player meets only about a dozen
## rated opponents in the story: a fixed Elo K would leave everyone close to
## the starting value, while the deviation here lets the first games move the
## rating a lot and later ones less, as the system grows surer of it.
##
## So far the only rated opponents are the story bosses, whose ratings
## (BossDefinition.rating) are fixed anchors measured from AI-vs-AI matches.
## Every attempt at a boss counts, a lost one included: how hard a player found
## the bosses is exactly what matchmaking should know about them.
##
## Loaded with preload (no class_name) so headless tools that never refresh the
## editor's global class list can still use the autoloads that depend on it.

const START_RATING: float = 1000.0
## How unsure the system is of a new player: the first rated game against an
## equal opponent is worth about +/-100.
const START_DEVIATION: float = 200.0
## The deviation never shrinks below this, so the rating keeps following the
## player's form instead of freezing after many games.
const MIN_DEVIATION: float = 60.0
const START_VOLATILITY: float = 0.06
## A boss's rating is measured, not guessed: with a small deviation every game
## against one counts in full.
const ANCHOR_DEVIATION: float = 30.0
## How quickly the volatility itself may change (Glickman suggests 0.3-1.2).
const TAU: float = 0.5
const GLICKO2_SCALE: float = 173.7178
const GLICKO2_CENTER: float = 1500.0
const CONVERGENCE_EPSILON: float = 0.000001
const MAX_ITERATIONS: int = 100

static func create_state() -> Dictionary:
	return {
		"value": START_RATING,
		"deviation": START_DEVIATION,
		"volatility": START_VOLATILITY,
		"games": 0,
	}

static func normalize_state(raw_state) -> Dictionary:
	var state: Dictionary = create_state()
	if !(raw_state is Dictionary):
		return state
	state["value"] = float(raw_state.get("value", START_RATING))
	state["deviation"] = clampf(float(raw_state.get("deviation", START_DEVIATION)), MIN_DEVIATION, START_DEVIATION)
	var volatility: float = float(raw_state.get("volatility", START_VOLATILITY))
	state["volatility"] = volatility if volatility > 0.0 and volatility < 1.0 else START_VOLATILITY
	state["games"] = maxi(0, int(raw_state.get("games", 0)))
	return state

static func get_display_rating(state: Dictionary) -> int:
	return int(round(float(state.get("value", START_RATING))))

## How much the shown number would change with this result - what the player
## is told before the match. Computed on the rounded numbers, so it adds up
## with the rating they see before and after.
static func preview_change(state: Dictionary, opponent_rating: float, opponent_deviation: float, player_won: bool) -> int:
	var after: Dictionary = apply_result(state, opponent_rating, opponent_deviation, player_won)
	return get_display_rating(after) - get_display_rating(state)

## One game as one Glicko-2 rating period.
static func apply_result(state: Dictionary, opponent_rating: float, opponent_deviation: float, player_won: bool) -> Dictionary:
	var score: float = 1.0 if player_won else 0.0
	var mu: float = (float(state.get("value", START_RATING)) - GLICKO2_CENTER) / GLICKO2_SCALE
	var phi: float = float(state.get("deviation", START_DEVIATION)) / GLICKO2_SCALE
	var sigma: float = float(state.get("volatility", START_VOLATILITY))
	var opponent_mu: float = (opponent_rating - GLICKO2_CENTER) / GLICKO2_SCALE
	var opponent_phi: float = opponent_deviation / GLICKO2_SCALE

	var g: float = 1.0 / sqrt(1.0 + 3.0 * opponent_phi * opponent_phi / (PI * PI))
	var expected: float = 1.0 / (1.0 + exp(-g * (mu - opponent_mu)))
	var variance: float = 1.0 / (g * g * expected * (1.0 - expected))
	var improvement: float = variance * g * (score - expected)

	var new_sigma: float = solve_volatility(phi, variance, improvement, sigma)
	var pre_period_phi: float = sqrt(phi * phi + new_sigma * new_sigma)
	var new_phi: float = 1.0 / sqrt(1.0 / (pre_period_phi * pre_period_phi) + 1.0 / variance)
	var new_mu: float = mu + new_phi * new_phi * g * (score - expected)

	return {
		"value": new_mu * GLICKO2_SCALE + GLICKO2_CENTER,
		"deviation": clampf(new_phi * GLICKO2_SCALE, MIN_DEVIATION, START_DEVIATION),
		"volatility": new_sigma,
		"games": int(state.get("games", 0)) + 1,
	}

## Step 5 of Glickman's Glicko-2 paper: the new volatility, found with the
## Illinois variant of regula falsi.
static func solve_volatility(phi: float, variance: float, improvement: float, sigma: float) -> float:
	var a: float = log(sigma * sigma)
	var volatility_equation: Callable = func(x: float) -> float:
		var ex: float = exp(x)
		var denominator: float = phi * phi + variance + ex
		return ex * (improvement * improvement - phi * phi - variance - ex) / (2.0 * denominator * denominator) - (x - a) / (TAU * TAU)

	var lower: float = a
	var upper: float
	if improvement * improvement > phi * phi + variance:
		upper = log(improvement * improvement - phi * phi - variance)
	else:
		var k: int = 1
		while float(volatility_equation.call(a - k * TAU)) < 0.0 and k < MAX_ITERATIONS:
			k += 1
		upper = a - k * TAU

	var f_lower: float = volatility_equation.call(lower)
	var f_upper: float = volatility_equation.call(upper)
	var iteration: int = 0
	while absf(upper - lower) > CONVERGENCE_EPSILON and iteration < MAX_ITERATIONS:
		var candidate: float = lower + (lower - upper) * f_lower / (f_upper - f_lower)
		var f_candidate: float = volatility_equation.call(candidate)
		if f_candidate * f_upper <= 0.0:
			lower = upper
			f_lower = f_upper
		else:
			f_lower /= 2.0
		upper = candidate
		f_upper = f_candidate
		iteration += 1
	return exp(lower / 2.0)
