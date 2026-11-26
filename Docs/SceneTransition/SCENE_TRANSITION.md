# Changing screens

Every screen change goes through `SceneTransition.change_scene(path)`
(`Scripts/SceneTransition.gd`, an autoload). A headless run, the dedicated
server and an AI-vs-AI batch change at once, without any of what follows.

## What the player sees

1. The screen fades to paper (`FADE_TO_COLOR_DURATION`, 0.35 s). The leaving
   screen's paper finish and vignette are copied over the fade, so the edges
   stay shaded throughout.
2. Under the paper, the new scene loads on the main thread and is swapped in.
3. The paper stays until the new scene has settled: three frames in a row of
   no more than 50 ms each, at least 0.15 s and at most 1.5 s after the
   scene arrived (`SETTLE_*`). A scene's first frames are its heaviest (the
   Collection builds its page, a match deals and builds its board), and one
   of them can take half a second. A fade running through such a frame
   jumps half way at once, and that is what used to make changing screens
   look jerky.
4. The paper fades out with a slight zoom (`FADE_FROM_COLOR_DURATION`,
   0.45 s), and hands over to the new screen's own paper finish.

The top bar is above the fade (layer 1200), so its items already show over
the paper while the screen is covered.

## Why not load on a thread

Loading on a thread (`ResourceLoader.load_threaded_request`) was tried on
2026-11-24, both for the scene change itself and for warming the match and
the Collection up in the background while the menu draws itself. It worked
most of the time. But in Godot 4.7.2 a threaded load of `main.tscn` now and
then never finished:

- once with the menu simply idling;
- and reproducibly when the main thread compiled a script that shares
  dependencies with it (`Collection.gd`) at the same time.

A load that never finishes leaves the paper up for good, so the game loads on
the main thread. Try again on a newer Godot before relying on it.

## Warming up at launch

What a first visit waits for is mostly its scripts compiling: a match's
`MatchBoard.gd` and `Multiplayer.gd` about 1.7 s, the AI's script (loaded when
a match deals) about 0.7 s, the Collection's `Collection.gd` about 0.6 s.
Once compiled, they stay compiled for the session, even after the screen is
gone, so later visits load in 0.05-0.2 s.

So the main menu's `_ready` starts with
`SceneTransition.warm_up(MainMenu.WARM_UP_PATHS)`. That loads each path once a
session, on the main thread, and lets it go again: the compiled scripts stay,
the textures do not. The menu is the game's main scene, so at launch this runs
before the first frame, while Godot's boot splash is still up. The launch
takes that much longer (about 3 s on a quiet machine). The menu's intro is
not affected: the first frame's delta does not include the wait. It runs
before the story can take over from the menu, so the story's first match gains
too. Later menu visits skip it, and so do headless runs, the dedicated
server and AI-vs-AI batches.

To warm another screen, add its path to `WARM_UP_PATHS`; each one makes the
launch longer by what it saves later. To warm a script that a scene only
loads later with `load()`, add the script itself, as the AI's is.

## Measured (2026-11-24/25, editor build)

| | before | now |
| --- | --- | --- |
| Collection, building its page | 0.4-1.0 s every visit | ~0.03 s (`StampLibrary` code index) |
| the fade out | jumped half way in one frame | 25-26 frames, the longest ~17 ms |
| first match, load under the paper | ~1.9 s | ~0.2 s, warmed at launch |
| first Collection, load under the paper | ~0.7 s | ~0.1 s, warmed at launch |

What is still heavy is the frame in which a match deals
(`start_singleplayer_game`, 0.45 s on a quiet machine), mostly the board's
first `apply_state_data`. It happens under the paper.
