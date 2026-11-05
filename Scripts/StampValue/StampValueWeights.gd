@tool
extends Resource
class_name StampValueWeights

# Every number of the stamp value formula (see StampValueCalculator):
#   value = M × T(D) × S + R + ΣE
# The tuned set lives in Data/Balance/stamp_value_weights.tres; the defaults below are the
# formula's reference values, and the self-test checks the reference stamps against them.

@export_group("Movement cell type")
# m: move only, c: capture only, X: move and capture.
@export var cell_move_only: float = 1.0
@export var cell_capture_only: float = 1.0
@export var cell_move_and_capture: float = 1.6

@export_group("Movement distance")
# Chebyshev distance from the golem: 1 is the near ring, 2 the outer ring.
@export var distance_near: float = 1.0
@export var distance_far: float = 1.25

@export_group("Movement direction")
# By row offset from the golem; the pattern's top row is forward.
@export var direction_forward: float = 1.2
@export var direction_side: float = 1.0
@export var direction_backward: float = 0.8

@export_group("Duration")
# T(D) = D ^ duration_exponent. An infinite (-1) duration counts as infinite_duration.
@export var duration_exponent: float = 0.75
@export var infinite_duration: float = 10.0

@export_group("Role")
@export var role_seeker: float = 1.4
@export var role_shared: float = 0.6
# Se-tenant's worth is its set's share (the Se-tenant group), not this factor.
@export var role_se_tenant: float = 1.0
# An Overseal goes onto any own golem, stamped or not: onto the one where it does the most,
# and also when every golem already carries a stamp.
@export var role_overseal: float = 1.2
@export var role_other: float = 1.0

@export_group("Trigger")
# E = effect base value × trigger factor. The *_per_duration factors are multiplied by D.
@export var trigger_on_affix: float = 1.0
@export var trigger_on_move_per_duration: float = 1.0
@export var trigger_on_capture_per_duration: float = 0.3
@export var trigger_on_captured: float = 0.35
@export var trigger_on_expire: float = 0.6
@export var trigger_on_symbol_count: float = 0.3
# crown_condition fires once, when the golem carrying the stamp is crowned. A crown comes
# ready about every (points a crown costs) own turns, so about D / that many chances fall
# within the stamp's life (counted up to one). This is the share of them on which the player
# crowns this golem rather than another one.
@export var trigger_crown_condition_pick_chance: float = 0.5

@export_group("Effect")
# increase_self_duration has no fixed value: M × (T(D + amount) − T(D)) × S.
@export var increase_self_duration_amount: float = 1.0
@export var effect_increase_own_durations: float = 6.0
@export var effect_increase_enemy_durations: float = -6.0
@export var effect_decrease_own_durations: float = -6.0
@export var effect_decrease_enemy_durations: float = 7.0
@export var effect_steal_stamp: float = 6.0
@export var effect_grant_stamp: float = 3.0
@export var effect_give_stamp: float = -5.0
@export var effect_invisible_to_enemy: float = 3.0
@export var effect_uncapturable: float = 4.0
@export var effect_move_base: float = 4.0
# Per marked cell of the effect pattern.
@export var invalid_squares_per_cell: float = 0.5
@export var frozen_squares_per_cell: float = 1.0

@export_group("Crown")
# The points a crown costs. 0 follows GameConfig.crown_points_required; any other number
# overrides it, to see the values under other crown rules.
@export var crown_points_required: int = 0
# A full crown meter. One crown point is worth crown_meter_value / the points a crown costs
# (GameConfig.crown_points_required), so the crown effects follow the point rules. 24 makes a
# point worth 4 at today's 6 points: the AI's 40 a point, on the scale where steal_stamp,
# invisible_to_enemy and uncapturable stand to the AI's scores at about 1 : 10.
@export var crown_meter_value: float = 24.0
# Points each effect moves on average. Lower them for the share of uses that go to waste:
# gain_crown_point on a full meter, remove_enemy_crown_point on an empty one.
@export var gain_crown_point_amount: float = 1.0
@export var remove_enemy_crown_point_amount: float = 1.0

@export_group("Se-tenant")
# With Se-tenant stamps on (set size) own golems at once, the crown meter stays full; when the
# set breaks it drops to 0. A Se-tenant stamp gets its share of what the set is worth:
#   R = chance × (D × whole_share × crown_use_rate × (N − 1) − break_meter_share × N)
#       × (one point's value) / set size
# with N the points a crown costs.
# The set size. 0 follows GameStateData.SE_TENANT_SET_SIZE; any other number overrides it.
@export var se_tenant_set_size: int = 0
# Share of a Se-tenant stamp's plays on which the whole set gets onto the board.
@export var se_tenant_set_chance: float = 0.5
# Share of the stamp's duration the set stays whole once it is.
@export var se_tenant_whole_share: float = 0.6
# Share of the whole set's turns on which the full meter is used: a crown placed or moved, or
# an enemy crown point taken without effect. Such a turn is worth N − 1 points, as the turn's
# own point comes anyway.
@export var se_tenant_crown_use_rate: float = 0.5
# Share of a full meter lost when the set breaks: the meter drops to 0 instead of holding the
# points it would have gathered.
@export var se_tenant_break_meter_share: float = 0.25

@export_group("Bomb")
# Per marked cell: enemy_density × enemy_golem_value − own_density × own_golem_value.
@export var bomb_enemy_density: float = 0.15
@export var bomb_own_density: float = 0.15
@export var bomb_enemy_golem_value: float = 6.0
@export var bomb_own_golem_value: float = 6.0
