# Working on the match scene

Notes for whoever picks up `Scenes/main.tscn` next. The first half is about
adding things without the scene getting heavier; the second is a list of what
is worth untangling later, and what each one costs.

## The shape of it

| | |
| --- | --- |
| `Scenes/MatchBoard.gd` | 878 lines, 115 functions, 75 constants |
| `Scripts/MatchView/MatchBoardControllerRegistry.gd` | 1166 lines, 361 config entries |
| `Scripts/MatchView/` + `Scripts/MatchState/` | 18 608 lines across 62 files |

The work is split across controllers that each own one job. They are
`RefCounted`, built and configured by the registry, and they reach each other
through `match_board`. That is a sound arrangement; the weight is not in the
controllers but in the two files that wire them together, and both grow by a
fixed amount every time anything is added. The rules below are mostly about
not paying that toll when it buys nothing.

## Adding things without the line count growing

**Do not add a forwarding stub to `MatchBoard.gd`.** The hundred or so it had
were taken out on 2026-11-12: every caller now goes through the controller's
accessor. Call through the accessor at the call site:

```gdscript
match_board.get_match_codex_controller().update_ui()   # yes
match_board.update_codex_ui()                          # no: another stub
```

What is left of one-line functions on the board is meant to be there: the
accessors themselves, Godot's own `_ready`, `_process` and `_input`, and a few
adapters that hand the controller something of the board's own
(`get_piece_holder_at` passes `pieces_node`). A controller that needs another
one's method as a `Callable` in its config gets it from the registry's
`_created()`, not from the board.

**A number that only one class uses is a constant on that class**, not a
`MatchBoard` const sent through a registry key into a controller var. That
route costs three lines in three files and a name repeated four times, and the
controller's var default ends up a second, wrong copy of the number. On
2026-11-12, 187 such numbers were moved onto the controller that reads them,
under their old names (`AMBIENT_BOARD_LIGHT_ENERGY` is now in
`BoardEnvironmentController`, the perspective fit in `BoardGeometry`). So look
for a tuning number in the controller that uses it first:

```gdscript
# MatchClock.gd
const ART_SIZE: Vector2 = Vector2(1211.0, 431.0)
```

What still goes through the registry: values several controllers share
(`CELL_WIDTH`, `INVALID_BOARD_POS`, the fragment groups), the board's `@export`
vars that are tuned in the inspector, node and controller references, and the
`Callable`s.

**A config value that changes during a match needs a refresh.** Once the
board's `_ready` is over, each controller is configured once, the first time it
is asked for, not again on every ask. What changes after that is refreshed
where it changes: the view by `MatchBoard.side`'s setter
(`MatchBoardControllerRegistry.apply_view()`), the turn HUD's names, portraits
and portrait spot by its getter (`_turn_hud_live_config()`), and a node the
board makes again by `reconfigure_all()`. A new value of that kind goes into one of these, or the
controller keeps the first one it got. The same holds for an inspector value
changed on the running game: it reaches the controllers only at the next match.
Better still, let the controller read it off `match_board` when it needs it.

**Put behaviour on the thing it belongs to.** `MatchClock` used to know only
how it moved, while the HUD held four constants describing the artwork and a
64-line method assembling it. Moving that into `MatchClock.build()` took the
HUD from 548 lines to 505 and means the next clock change lands in one file.
When a method in a controller is mostly about one node, it usually wants to be
on that node.

**Measurements taken off artwork live next to what they describe**, as named
constants, with a line saying to re-measure if the drawing changes. The board's
perspective constants, `CLOCK_WINDOW_TOP`, `FRAME_ART_STROKE` and
`TABLE_EDGE_CANVAS_Y` are all of this kind. Several of them have been re-fitted
two or three times; the comment saying so is what makes that cheap.

**One source for a shared value.** `MatchBackgroundController.PAPER_TINT`,
`MatchClock.SWITCH_SOUND` and `BoardCanvas` all exist because the same
number was about to be written down twice.

**Anything placed against the drawn room goes through `BoardCanvas`**, never
screen pixels. The art is scaled to cover the viewport, so a screen-pixel
position is right at one window shape and wrong at every other. See
`BoardCanvas.to_viewport` and the section in `Story/README.md`.

**Never read `position` to remember where something rests.** For an anchored
control it depends on the viewport, so a value captured at `_ready` is stale
the moment the window changes shape. Compute it from the anchors and compute it
again on resize. This is what made the codex jump sideways the first time a
stamp was affixed.

**Board layers:** anything painted onto the board goes below z 9, anything
standing on a square above it. The grid drawing is at 9 and the gap either side
of it is one slot wide. The table says which is which:

```
 -24 board shadow · -2 frame · 0 base tiles · 1-8 special tiles, tints, markers, contact shadows
 --- 9  the drawn grid ---
 10-34 pieces, one rank every BoardConfig.DEPTH_Z_STRIDE · 46 move dots
```

**Ranks are four apart in z, not one** (`BoardConfig.DEPTH_Z_STRIDE`), and the
three free slots between them are what a piece in flight uses: the near/far side
offset, the lift, and the occlusion check that puts it just behind the piece it
is passing. Two rules keep that working. `lifted_z_offset + route_z_front_offset`
must stay under the stride, or a piece in the air over one rank outranks a piece
resting on the next one in. And the occlusion check has to be the *last* word -
hand the lift to `get_z_index_for_local_position` rather than adding it to the
answer, or it outvotes the check and the piece only goes behind on the frame it
lands, which reads as walking through whatever it passed. Anything that sits
above the pieces, the move dots included, is placed off the top of the band
rather than at a number typed in by hand.

**The scenes share the interface, not the sequencing.** The tutorial, a
puzzle (`Scenes/PuzzleMatch.tscn`, [Docs/Puzzles/PUZZLES.md](Docs/Puzzles/PUZZLES.md))
and a match build the same HUD from the same controllers and carry the same
nodes, so they look alike without any copying another. They share the rules
too: every board plays on a `NetworkGameHost` - the tutorial and a puzzle on one
of their own, with no network (`TutorialMatchAdapter.start_local_host`) - and
a board never changes the match itself, it sends the host an action and shows
the state that comes back. What differs is
when each piece arrives: `TurnHudController.set_hud_element_visible()` takes
`codex`, `opponent_codex`, `page_counter`, `turn_page`, `end_turn`, `clock` or
`opponent_panel`, and the tutorial uses it to bring them in one at a time. A
match leaves them all up.

**Shared scenes get per-instance tweaks from the caller.** `DialoguePanel` is
used by the comics, the tutorial and the opponent in a match. Three of those
want it where it is. Hence `set_vertical_nudge`, `set_portrait_background_color`
and `OpponentSpeechPanel` driving it from outside rather than edits to the
scene.

## Worth untangling later

Ordered by what they cost to live with, not by effort.

**1. The forwarding stubs in `MatchBoard.gd`.** Done on 2026-11-12: 103
stubs gone, callers in 28 files rewritten, the registry's Callables pointed at
the controllers. Checked by playing four puzzles and the tutorial's first eight
steps on the code before and after (same board, step for step, at a fixed frame
rate) and an AI-vs-AI match.

**2. The registry's config keys.** Done on 2026-11-12, in two parts. The 187
numbers that only one controller read are now that controller's constants (the
rule above): the registry went from 548 config entries to 361 and `MatchBoard`
from 262 constants to 75. And a getter no longer reconfigures its controller:
before, every `get_*()` re-ran the whole configure() with a freshly built
dictionary, about ten times a frame in a running match (the deck counter alone
six), and `get_controller_registry()` reconfigured the registry too. Now it is
none a frame once the board is ready, with the live values refreshed as the
rule above says. Checked: all 187 values identical, type included; four puzzles
(and two of them seen from black, screenshots too) and the tutorial's first
eight steps the same as before, step for step, at a fixed frame rate; an
AI-vs-AI match without an error.

What is left is wiring: references, `Callable`s, shared values and the
inspector-tuned exports. Letting controllers read those off `match_board`, or
a tuning `Resource`, is still possible, but no longer pays for itself.

**3. The opponent's codex is positioned in viewport coordinates**, not canvas
ones, so it drifts across the drawn room as the window changes shape. Fixing it
means making its slot a canvas-space container and rescaling the four constants
that drive its page-turn animation.

**4. Turn changes are found by polling.** `TurnHudController` compares the turn
colour every frame to drive the clock's knock, the rocker and the end-of-turn
sound, and raises `MatchBoard.turn_changed` for what else follows the turn: the
board's light, the vignette, the player's crown. It works and costs nothing
measurable, but the state sync could raise that signal itself. Still open: it
was left out of (1) so that (1) stayed a rewrite with nothing new in it.

**5. The tutorial is reached by a path that skips
`_configure_singleplayer_match`**, which is why `GameConfig.is_singleplayer` is
false there and the turn clock behaves as though it were a networked match.
Worth settling when the tutorial's own flow is next touched.
