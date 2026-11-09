# Stamp value estimate

Every stamp carries an estimated value, `Stamp.estimated_value`, worked out
from its movement pattern, duration, role and effect:

    value = M × T(D) × S + R + ΣE

| part | |
| --- | --- |
| M | each reachable cell: type (m, c, X) × distance (near/outer ring) × direction (forward/side/back), summed |
| T(D) | D ^ exponent; an infinite (-1) duration counts as a fixed D |
| S | role factor: Seeker, Shared, Se-tenant, Overseal, or Unit |
| R | role ability: a Se-tenant stamp's share of its set; 0 for the other roles |
| E | effect base value × trigger factor; `on_move` and `on_capture` scale with D |

The formula lives in `Scripts/StampValue/StampValueCalculator.gd` and returns
a breakdown (M, T(D), S, the movement, role and effect parts, the total).
Unknown effect types and triggers count as 0 and show a warning.

The game itself only reads the stored field. Besides the AI, the Bourse
prices stamps from it ([BOURSE.md](../Bourse/BOURSE.md)).

## In the AI

The AI works out each stamp's parts once, when its first evaluator is made
(`AIMoveEvaluator.prepare_stamp_values`). It uses only the part that still
lies ahead of a stamp on the board:

    remaining = M × S × T(t) + (on_move and on_capture effects) × t / D

with t the turns the stamp has left. `on_affix` effects have fired by then.
The `on_captured`, `on_expire` and `crown_condition` effects and the Se-tenant
set depend on the board and on whom they help, so the AI scores them where
they happen instead.

One estimate point is worth 5 score points
(`AIMoveEvaluator.STAMP_ESTIMATE_POINT_SCORE`):

- A captured stamp is worth 10 + 5 × remaining. A Seeker goes back to its
  owner's codex, so it counts at half of the 5 × remaining. At 5, an average
  fresh stamp is worth what the old flat 75 + 8 per turn was. On top comes the
  `on_expire` effect it has still to set off, scored on the board for its
  owner (`score_expiry_at_stake`): a harmful one in full, since the owner
  either pays it or leaves the last step unused; a helpful one × 0.6 for
  each step still to make. The stamp never counts below 0, so a Ballista on
  its last step is worth only its golem.
- Affix, exchange and hand scoring use 5 × (fresh value − the average enabled
  stamp's fresh value), so an average stamp does not shift them.

The estimate's fixed rates are replaced by what the board shows in two places:

- **Capture chance** (`AIMoveEvaluator.get_expected_captures`). An `on_capture`
  effect put on with a stamp counts for the captures its golem can expect
  before the stamp runs out, not at the estimate's 0.3 a turn. On each of its
  turns, every enemy golem it could take by then (on its pattern, ignoring
  what stands in the way) is a 0.4 chance, and each later turn counts 0.8 of
  the one before. A Warlord put on in the opening expects nothing; one put on
  next to two enemy golems expects about 0.6.
- **Duration changes** (`get_duration_step_value`). A +1 or −1 counts, per
  golem, as the step it adds or takes away at the end of the stamp: that
  step's part of the remaining value, × 0.6 for every step the golem has to
  make before it. A stamp on its last step also counts 15 (110 on the crowned
  golem), because the change decides whether its golem stands bare. So War
  Drummer is worth most when many stamps are about to run out, and little
  when they are fresh. A −1 that ends a stamp sets off its `on_expire`
  effect, which counts for the stamp's owner: a Black Hole step next to an
  own Nova on its last step is worth the Nova's blast.
- **Own drain** (`score_own_drain_step`). A −1 at the far end of a stamp looks
  cheap on each move, but a stamp that drains its own side on every plain step
  empties the board and the codex over a game. Such a step costs 120 and 60 for
  each other stamped golem on top, so the stamp captures rather than walks.
  Without the crown it costs 3000 more whenever there is another stamped golem
  to drain, unless the stamp is walking out of an attack with fewer than 3 of
  them. The crowned golem pays nothing when it reaches the base or lands one
  step from it. Its walk away from an attack costs 3000 more when the step would
  drain 3 or more other stamped golems, or when its crown can move to a golem
  that has a route and that the enemy cannot take.
- **Se-tenant grants** (`get_se_tenant_sources`). A stamp that grants a
  Se-tenant into its owner's codex (Advocate a Sun, Consul a Moon, Logician a
  Bicycle) counts as a Se-tenant on its way, × 0.8 for every turn it is off:
  the page turns to it, the steps until it goes off (one Se-tenant per step
  for a grant on each step), the chance of a capture for a grant on a
  capture, and the page turns to the free slot the new stamp lands on. While
  the golems and these stamps can make a whole set, each Se-tenant golem
  counts 90 and each stamp the set still needs 30 × its weight; a grant that
  goes off counts 60 more (× its landing weight), putting on a granting stamp
  30 more, and turning the page away from a Se-tenant the set needs costs 60.
  So the AI plays the granting stamps first, puts the Se-tenants on as they
  come, and keeps a free slot on the open page for them.

An effect of a stamp already on a golem counts when it goes off: on the step,
on a capture, or when the step runs the stamp out. A `crown_condition` effect
counts when the crown goes down, and the golem's route and safety are read from
the board it leaves: Mercury's freeze can take the attacker off it, Goat cannot
be captured, The Golem's +1 lengthens its own walk.

## Tuning

Every number is in `Data/Balance/stamp_value_weights.tres`
(`StampValueWeights`), grouped as in the formula. The script's own defaults
are the reference values.

### Crown effects

The crown effects follow the crown rules, so they need no retuning when a
crown's price changes:

- `gain_crown_point` and `remove_enemy_crown_point` are worth
  `crown_meter_value` / the points a crown costs, per point moved. The default
  of 24 makes a point worth 4 at today's 6 points. That matches the AI, which
  scores a point at 40, on the scale where `steal_stamp`, `invisible_to_enemy`
  and `uncapturable` stand to the AI's scores at about 1 : 10.
- `crown_condition` fires at most once. Its factor is
  min(1, D / the points a crown costs) × `trigger_crown_condition_pick_chance`.
  That is about one crown chance per crown's price in own turns, times how
  often the player crowns this golem rather than another one.

The points a crown costs come from `GameConfig.crown_points_required`. In the
editor, where that autoload does not run, the default is read from
`GameConfig.gd`'s source. A non-zero `crown_points_required` in the weights
overrides it, to see the values under other crown rules. The
`*_crown_point_amount` weights lower an effect's points for the share of uses
that go to waste: a full meter, or an empty enemy meter.

### Role abilities

- **Overseal** goes onto any own golem, stamped or not. That shows in its role
  factor, `role_overseal` (1.2): it can go where it does the most, and it can
  be played when every golem already carries a stamp. Covering a stamp is the
  player's choice, so the stamp it covers is not counted against it.
- **Se-tenant** keeps the crown meter full while the set (3 golems, from
  `GameStateData.SE_TENANT_SET_SIZE`) is on the board, and drops it to 0 when
  the set breaks. Each Se-tenant stamp carries an equal share of the set:

      R = chance × (D × whole_share × crown_use_rate × (N − 1) − break_meter_share × N)
          × (one point's value) / set size

  with N the points a crown costs. A turn with a whole set is worth N − 1
  points if the full meter gets used then, because the turn's own point comes
  anyway. Breaking the set costs the points the meter would otherwise hold.
  With the defaults (chance 0.5, whole share 0.6, use rate 0.5, break share
  0.25) and a 6-point crown this comes to R = D − 1. A D = 5 stamp gets 4, as
  much as one crown point. A one-turn stamp gets 0, because its set breaks
  before it pays for the drop. `role_se_tenant` (1.0) tunes a Se-tenant's
  movement part on its own. A non-zero `se_tenant_set_size` overrides the
  game's set size.

## The editor plugin

`addons/stamp_value_estimator` (Project Settings > Plugins > Stamp Value
Estimator):

- **Inspector**: a stamp's read-only "Becsült érték" field shows the live
  value with its breakdown, and a link to the weights.
- **Bélyegértékek dock** (bottom panel): every stamp under `res://Stamps`,
  sortable by any column title, with a set filter, per-set averages
  (value, duration, capture ratio, outer ring ratio), a target value with a
  tolerance band (values outside it are red above, blue below), CSV export
  and the self-test. Double-click a row to open the stamp.
- **Stored value**: after every edit, undo, save or reload the plugin brings
  `estimated_value` in line with the weights. A stamp with unsaved edits gets
  it in memory and keeps it with the next save. A clean stamp is saved right
  away, but only once the weights are saved too, so tuning a weight rewrites
  the changed stamps when the weights .tres is saved. A stamp whose file differs
  from the copy in memory, because git or a script changed it while the editor
  was open, is left alone until the editor has reloaded it.

Export the CSV outside the project: Godot imports a `.csv` under `res://` as
translations.

## Self-test

Four reference stamps (Lance 9.4, Archer 9.0, Berserk 12.5, Knight 45.3) and
the Lance as an Overseal (11.3) must come out within ±0.1 with the default
weights. Three crown cases (a point on affix 4.0, a point on crowning 1.0, the
Lance taking an enemy point on every move 17.4) hold for a 6-point crown. The
Se-tenant case (D = 5, no movement, 4.0) also needs a set of 3. These cases
are skipped under other rules.
Run it with the dock's "Önteszt" button, or headless:

    Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://addons/stamp_value_estimator/tests/run_selftest.gd

A headless run starts the autoloads, which touch the save in `user://`.
