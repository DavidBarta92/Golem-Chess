# Working on the match scene

Notes for whoever picks up `Scenes/main.tscn` next. The first half is about
adding things without the scene getting heavier; the second is a list of what
is worth untangling later, and what each one costs.

## The shape of it

| | |
| --- | --- |
| `Scenes/MatchBoard.gd` | 1339 lines, 214 functions |
| `Scripts/MatchView/MatchBoardControllerRegistry.gd` | 1266 lines, 338 config keys |
| `Scripts/MatchView/` + `Scripts/MatchState/` | 15 600 lines across 50 files |

The work is split across controllers that each own one job. They are
`RefCounted`, built and configured by the registry, and they reach each other
through `match_board`. That is a sound arrangement; the weight is not in the
controllers but in the two files that wire them together, and both grow by a
fixed amount every time anything is added. The rules below are mostly about
not paying that toll when it buys nothing.

## Adding things without the line count growing

**Do not add a forwarding stub to `MatchBoard.gd`.** 147 of its 214 functions
are one line that forwards to a controller. Call through the accessor at the
call site instead:

```gdscript
match_board.get_match_codex_controller().update_ui()   # yes
match_board.update_codex_ui()                          # no: another stub
```

The layer is there for historical reasons and should shrink as code moves, not
grow. Thirteen of these were deleted recently because nothing called them at
all.

**Only put a tuning number through the registry if someone will tune it.** A
value that goes `MatchBoard` const → registry key → controller var costs three
lines in three files and a name repeated four times. Pay that for things an
artist or designer will actually reach for. For a number that only one class
uses, make it a constant on that class:

```gdscript
# MatchClock.gd
const ART_SIZE: Vector2 = Vector2(1211.0, 431.0)
```

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
 -24 board shadow · -2 frame · 0 base tiles · 1-8 special tiles, tints, markers
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

**The two scenes share the interface, not the sequencing.** The tutorial and a
match build the same HUD from the same controllers and now carry the same
nodes, so they look alike without either copying the other. What differs is
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

**1. The 147 forwarding stubs in `MatchBoard.gd`.** The one real structural
smell. Removing them means rewriting every `match_board.x()` call as
`match_board.get_y_controller().x()` across roughly twenty files. Mechanical,
testable, and worth about 150 lines plus the clarity of seeing which controller
owns what. No behaviour changes, so it is safe — but it touches everything, so
it wants a quiet week, not an afternoon between visual tweaks.

**2. The registry's 338 config keys.** Every controller gets a dictionary
copied out of `MatchBoard`'s constants. It works and nothing in it is stale
(all 338 are read), but it is 1266 lines of transcription. The honest options
are to let controllers read the constants off `match_board` directly, or to
move the tuning surface into a `Resource` that the editor can show. Either is a
bigger change than (1) and should follow it, not precede it.

**3. The opponent's codex is positioned in viewport coordinates**, not canvas
ones, so it drifts across the drawn room as the window changes shape. Fixing it
means making its slot a canvas-space container and rescaling the four constants
that drive its page-turn animation.

**4. Turn changes are polled, not signalled.** `TurnHudController` compares the
turn colour every frame to drive the clock's knock, the rocker and the
end-of-turn sound. It works and costs nothing measurable, but a
`turn_changed(colour)` signal on `MatchBoard` would say what is happening. Do
this while doing (1); it is the same kind of work.

**5. The tutorial is reached by a path that skips
`_configure_singleplayer_match`**, which is why `GameConfig.is_singleplayer` is
false there and the turn clock behaves as though it were a networked match.
Worth settling when the tutorial's own flow is next touched.
