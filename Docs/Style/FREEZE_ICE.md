# Freeze ice

A frozen piece sits under a layer of uneven ice: what is behind it bends, the
room shows in it faintly, and it catches the light. The square under the piece
gets a thin sheet of the same ice.

## When it shows

`FreezeEffectAnimator.get_visual_signature()` decides. A piece is frozen while
`piece.exhausted_this_turn` is set (a fresh stamp, a new crown) or while it
stands on a frozen square (`StampEffectResolver.is_square_frozen`). A
respawn-locked golem has that flag too but gets no ice: it is not waiting out
the turn, and it has its own look. When that turns on, the ice grows; when it
turns off, the ice melts. The animator only draws this: the rules live in
`MoveRules`.

## How it is put together

| | |
| --- | --- |
| `Scripts/MatchView/FreezeEffectAnimator.gd` | makes the overlays and runs the tween; durations at the top |
| `Shaders/freeze_ice.gdshaderinc` | what the two share: surface, reflection, glints, cracks, sparkles, the spreading edge |
| `Shaders/piece_freeze_ice.gdshader` | the layer on the piece |
| `Shaders/square_freeze_ice.gdshader` | the sheet on the square |
| `Shaders/piece_freeze_ice.tres`, `square_freeze_ice.tres` | the materials, holding the two textures and any tuned values |
| `Assets/Ice/` | the textures, baked by `tools/generate_ice_textures.py` |

Each frozen piece has two overlays: a `Sprite2D` child of the piece's holder,
showing the same picture as the piece, and a `Polygon2D` on the board's markers
layer. Each gets its own copy of its material, because the tween and the
per-piece values live on it.

**The animation** is one number. A tween takes `ice_freeze` from 0 to 1 on both
materials (`tween_ice`), and the melt takes it back to 0. The shaders turn that
number into the movement: every pixel has a `place` from 0 to 1 saying when its
turn comes, and `ice_reveal(place)` shows it once `ice_freeze` gets there. So
the floor freezes first, from under the piece outwards, then the ice climbs
from the feet to the head. The melt is the same thing backwards. To change the
order, change how `place` is worked out at the end of each shader's
`fragment()`.

The sparkles and the drifting glint run on `TIME`, not on the tween, so they
keep going while the piece stays frozen.

## Tuning

Open a material in the inspector, or change a default in the shader to change
it everywhere. The materials are copied when a piece freezes, so a change shows
on the next piece that does. Shared values have to be set on both materials,
which is why a default in the `.gdshaderinc` is usually the better place.

| to change | value | |
| --- | --- | --- |
| how much it bends | `refraction`, `rim_refraction` | in board units; a square is about 18 |
| how thick the layer is | `shell_thickness`, `shell_lumps` | |
| the piece's colour showing through | `keep_colour`, `veil`, `milk` | low values lose the player's colour, which is game information |
| how strong the reflection is | `ice_room_dark_strength`, `ice_room_bright_strength` | |
| how much the reflection follows the figure | `figure_roundness` | towards 0 it breaks up into patches |
| the highlights | `ice_glint_size`, `ice_glint_strength`, `ice_glint_drift` | |
| the sparkles | `ice_sparkle_amount`, `ice_sparkle_speed` | keep them thick: see below |
| the shards' size | `ice_surface_size` | |
| the palette | `ice_light`, `ice_body`, `ice_deep` | |
| the sheet on the square | `sheet_alpha`, `edge_alpha`, `edge_width` | |
| the timing | `FREEZE_DURATION`, `RELEASE_DURATION` | on the animator |

Run `python tools/generate_ice_textures.py` after changing the kiosk room's
art, or to change the ice's shape. `ice_surface.png` needs its mipmaps and
`fix_alpha_border` off: its alpha is data, not transparency.

## Why it is built this way

**The distortion does not read the screen.** The piece overlay has the piece's
own picture, so it samples that at a pushed UV. A `hint_screen_texture` would
need a `BackBufferCopy` per piece, and those read stale pixels in this
renderer. It also keeps the ice on the piece when several overlap in depth.
The sheet on the square has no picture of its own, so it does not bend the
tile, only lets it show through.

**The reflection is the room itself, drawn once.** A real reflection means
rendering the scene a second time, which is what the
[2D mirror shader](https://godotshaders.com/shader/2d-mirror-effect/) does with
a `Viewport` holding a copy of the world: heavy, and here the world is split
across a `CanvasLayer` and the camera's board. `ice_room.png` is the kiosk room
small, grey and blurred. The ice looks at it through its surface, using
`SCREEN_UV` as a coordinate only, so a piece by the window shows the window and
one in the middle shows the opponent's dark coat. The tutorial's room reflects
the kiosk too; at this size nobody can tell.

**The reflection is flattened into washes.** The room's greys become one flat
shadow tone and one flat light tone with hard edges (`ice_reflection`), and
highlights are hard-edged too. A smooth gradient looks like a render on top of
a drawing; flat tones look painted. The colours are the world's paper and ink.

**Pieces reflect as one rounded lump** (`figure_roundness`). Led by the shards
alone, the highlights land anywhere and the figure breaks into camouflage.

**Sizes are in board units**, worked out from `holder.scale`. The pictures run
from 16 px to 1578 px tall, and a piece still has to get the same ice.

**The sprite's quad grows in `vertex()`.** Some figures touch the edge of their
picture, and the ice has to stand past it. Anything read outside 0..1 is masked
out, or the sampler smears the picture's edge.

**The figure is found by sampling alpha on two rings**, not from mipmaps: the
SVG pieces have none.

**The board's painterly filter runs over all of this.** Anything a pixel wide
disappears into it, which is why the sparkles are thick for their size.

**`self_modulate` is not inherited**, and the ice hides the piece. So
`create_piece_overlay` copies it, and `apply_piece_hover_dim` keeps the two
together. Without that a frozen piece stops dimming and a respawn-locked one
looks solid.

**The square's UV is not plain 0..1 by accident.** `Polygon2D` divides `uv` by
the texture's size, which is why `create_square_overlay` scales it first. The
pattern uses the position instead, because UV bends at the diagonal of a
slanted square.

## Cost

About twenty texture reads per pixel on the piece, on some 13 000 pixels a
piece, and four on the square. There are no noise loops, no screen copies and
no extra viewports.
