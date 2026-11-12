# Pack opening

The overlay in `Scripts/PackOpening/PackOpeningOverlay.gd`, on a CanvasLayer between
the top bar (1200) and the paper texture (1210): over the bar, and printed on the
same paper as the rest. The stamps out of the packs are on its `PackRewardTable`
(same folder): building them, dealing, turning, captions, the description, and the
flight into the album. In the collection, `Scenes/CollectionPackController.gd` ties
both to the room (the packs lying in it, the click on them, the counters), and
`Scenes/CollectionPackShopController.gd` is the shop window. The steps are
`overlay_state`:

| state | what happens | how it moves on |
| --- | --- | --- |
| `selection` | the packs fly in, with Back and Open all under them | a click on a pack; Open all goes straight to the table |
| `focused` | the pack comes to the middle, then is framed on the whole screen (`Pack3DView.frame_on_stage`) | a click beside it goes back; a press on it starts the tear |
| `tearing` | the mouse has the pack (`PackTearInteraction`, see [CUTTING.md](../Cutting/CUTTING.md)). The stamps are in the collection from this moment | the tear reaches the far edge |
| `opening` | the strip flies off, the light shows, the stamps rise out of the torn top, the pack falls, the stamps are dealt | by itself; a click runs it at `PACK_SKIP_SPEED` |
| `rewards` | the stamps lie face down; a click turns one, and the mouse on a turned stamp shows its description | once all are turned, a click sends them into the album |

The stamps stand behind the pack's face from the start, so the torn edge hides them
until they rise over it. They stay one stack, narrower than the pack, until it has
fallen clear (`_get_pack_clear_seconds`): a stamp showing beside the pack would look
as if it had come from behind it. Rendering the pack on the whole screen is what
lets the torn strip fly anywhere; it costs more than the small picture, so only the
opened pack does it.

## Keeping it smooth

The player must never see a stop, least of all when the mouse comes down on a pack.

- Stamps are built ahead and a few a frame (`PackRewardTable.prepare`), and the
  selection's packs one a frame. An opened pack only gets its prints assigned.
- `_claim_packs` saves once, however many packs it opens.
- The room behind the overlay is refreshed once, when the stamps have landed in the
  album (`_refresh_room_behind_overlay`): nothing moves at that moment.
- `PlayerCollectionStore` answers "how many of this?" from lookups rebuilt after a
  change. Walking its list for each question took 1.4 s for one codex list.
- A stamp's ink blot is a plain uniform on each layer's own material. Instance
  uniforms are limited to 256 items under the Compatibility renderer: past that
  every new item logs an error, and a page of 40 stamps was past it.

## Rarity

`StampPrint.get_rarity()` follows the print's variant. Packs roll each slot by
their own odds (`PackDefinition.foil_chance`, `full_art_chance`, in the inspector),
through `PackDefinitionLibrary.roll_rewards`. No stamp comes twice in a pack, not
even as two prints of the same stamp. A rarity the pack has none of falls back to
the next one down. A print has to be listed in a pack to drop from it.

| | in the pack | face down | turned |
| --- | --- | --- | --- |
| basic | a short pause, no light | plain | the turn and its hop |
| foil | silver-blue light, 0.5 s | silver-blue aura | lifts, turns, a run of light and flecks |
| full art | gold light and trembling, 0.95 s | gold aura | `PackFullArtStage`: to the middle, shudder, turn, ink floods the screen, name, back to its place |

The row is sorted rarest last, so it builds from left to right. The light never
lies: a pack shows it only when something of that rarity is inside.

## Tuning

- Timings and sizes: the `PACK_` constants at the top of `PackOpeningOverlay`
  (the packs, the tear, the light, the rise and the fall) and of `PackRewardTable`
  (the stamps on the table: dealing, turning, captions, leaving), the constants
  of `PackTearInteraction` and `PackFullArtStage`.
- Colours: `FOIL_LIGHT`, `FULL_ART_LIGHT` in `Scripts/PackOpening/PackRevealFx.gd`.
- Effects stay added light or plain flecks, in the stamp's own nodes: reading the
  screen back on a stamp gives stale pixels under the Compatibility renderer.
- Trembling follows the Screen Shake setting.

## Sounds

`pack_tear`, `pack_crinkle`, `pack_tear_finish`, `pack_foil_tease`,
`pack_foil_reveal`, `pack_full_art_tease` and `pack_full_art_reveal` in
`Audio/SFX/` are synthesised by `tools/generate_pack_sounds.py`, as placeholders. A
recording under the same name replaces one without touching the code. `pack_tear`
is one short grain, played every few percent of the tear's way, so a slow drag
rustles and a fast one runs together.
