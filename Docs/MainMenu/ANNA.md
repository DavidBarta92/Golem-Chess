# Anna on the main menu

Anna stands in the middle of the shop, her back to the player, looking at the
window. She is a drawing on a 2D skeleton, idling the way someone standing
still does: mostly still, with small moves that set off quickly and settle.
Her upper body shifts at the waist while her legs stay planted, she breathes
in her chest only, glances down and up, and every few seconds lets the arm with
the rag hang straight before lifting it back. Her head keeps level while her
body moves. At rest she is exactly the drawing.

| | |
| --- | --- |
| `Assets/MainMenu/Anna/legs.png`, `body.png`, `arm.png`, `head.png` | the drawing, back to front: full-size layers on the menu art's canvas (1919x1077), each in its final place, line and colour together |
| `Assets/MainMenu/Anna/eye_shut.png` | the closed eye with the skin round it, a small opaque patch over the open eye on the same canvas; shown for a blink, and moved with the head. Without it she does not blink |
| `Assets/MainMenu/Anna/head_depth.png` | once painted: how far each part of the head stands out towards the viewer, for turning it (below). Until then the build guesses it and saves the guess as `head_depth_auto.png` |
| `tools/build_anna_rig.py` | builds the rig from those layers |
| `Assets/MainMenu/Anna/Rig/` | the layers trimmed to the drawing (built) |
| `Scenes/MainMenuAnnaRig.tscn` | the skeleton and one mesh per layer (built: changes made there are lost on the next build) |
| `Scenes/MainMenuAnna.tscn`, `.gd` | lays the rig over the menu art and moves it; `MainMenu.tscn` holds it over the room and its buttons ([MAIN_MENU.md](MAIN_MENU.md)) |

## Redrawing her

Draw on the full canvas, so a layer lands in place by itself, and give every
layer its fill: she covers the shop behind her. Where one part goes under
another, carry the lower one on under it (the neck under the head, the
waistband under the shirt, the near sleeve under the arm's), with no outline
where they meet. Then:

    python tools/build_anna_rig.py

and let the editor import the new textures. If a joint moved in the drawing
(the hip, the elbow...), move it in `JOINTS` at the top of the script first:
the weights are worked out from the joints.

## How the rig is made

Each layer is a `Polygon2D` covered by a grid of small squares (12 px, the arm
10 px), only where something is drawn; the head 8 px and the closed eye 6 px,
both weighted between `Head` and `Turn` by the head's depth. Each vertex
is weighted to the bones by where it is: a layer's rule in the script says
where one bone's hold hands over to the next.

| bone | moves |
| --- | --- |
| `Ground`, `Hip` | nothing: the legs, the waistband and the shirt's hem stay planted |
| `Waist` | the upper body's lean, from the waist |
| `Chest` | nothing itself: it carries the neck and the shoulder |
| `Ribs` | the breath: it swells the back alone. The neck and the shoulder ride up with the back instead of being scaled with it, so the head and the arm keep their size |
| `Neck`, `Head` | glancing down and up (in profile that is a turn in the picture's plane); the neck just under the head turns with it, so its outline does not break where the head layer ends |
| `Turn` | turning the head a little to the left or right, by sliding sideways (below) |
| `Shoulder`, `Elbow`, `Hand` | the near arm and the rag; the near sleeve drawn on the body goes with the shoulder, or its edge would show beside the arm's own |

## Turning the head

A head seen side-on keeps its outline when it turns a little: what moves is
what lies inside it, the more the nearer it is to the viewer. Turning towards
the viewer, the ear, the cheek, the eye and the hairline slide back towards
the bun while the profile stays put. The head is a fine mesh, and each of its
points follows the `Turn` bone by its depth, 0 to 1, so sliding that bone
sideways gives just that. It holds up for a few degrees (`turn_to_viewer`,
`turn_to_window`); further, the lines along the outline stretch and the side
that is out of sight would have to show, which needs a drawn head.

The depth comes from `Assets/MainMenu/Anna/head_depth.png` if it is there: greyscale on
the full canvas, white where the head stands out most towards the viewer (the
ear, the cheek, the side of the hair), black on the outline (the profile, the
top and back of the head, the bun's edge), soft in between. Start from
`head_depth_auto.png`, the build's guess: it blows the outline up like a
balloon, so it rises towards the middle of the head rather than the ear. The
bottom of the neck never turns, whatever is painted there, so it meets the
body's neck. Rebuild after painting.

## Tuning the motion

On the `MainMenuAnna` node, in groups: breathing, waist, head, arm, blinking.
Distances are in the art's pixels, about screen pixels at 1080p; angles in
degrees. Each habit picks a new target after a random hold, and a damped
spring carries the bone there: it sets off at once and settles. How quick and
how bouncy each spring is are the `*_FREQUENCY` and `*_DAMPING` constants in
`MainMenuAnna.gd` - the head's are quick, the arm's drop bounces a little, the
rag swings late.

Two-dimensional skinning works under the Compatibility renderer the project
uses (tried in Godot 4.7.2).
