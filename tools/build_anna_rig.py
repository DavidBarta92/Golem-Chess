#!/usr/bin/env python3
"""Build the main menu's Anna rig from her drawn layers.

Anna is drawn in four layers, each a full-size PNG on the main menu art's own
canvas (1919x1077) with the drawing in its final place:

    Assets/MainMenu/Anna/legs.png, body.png, arm.png, head.png   (back to front)

and, once drawn, eye_shut.png: the closed eye with the skin round it,
covering the open eye, shown for a blink.

This script

  * trims each layer down to the drawing, dropping the near-invisible eraser
    leftovers, and saves it to Assets/MainMenu/Anna/Rig/ - the game then holds four
    small textures for her instead of four screen-sized ones;
  * covers each layer with a mesh - a grid of small squares over the drawn
    part - and weights every vertex to the bones that move it;
  * writes Scenes/MainMenuAnnaRig.tscn: a Skeleton2D with one Bone2D per
    joint, and one Polygon2D per layer.

Scenes/MainMenuAnna.tscn lays that rig over the menu art and
Scenes/MainMenuAnna.gd moves its bones; neither is touched here, so what is
tuned there survives a rebuild. Re-run this after redrawing a layer:

    python tools/build_anna_rig.py

If a joint moved in the drawing, move it in JOINTS first. The weights follow
the joints: each layer's rule below says, in terms of them, where one bone's
hold hands over to the next.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / "Assets" / "MainMenu" / "Anna"
RIG_TEXTURE_DIR = SOURCE_DIR / "Rig"
SCENE_PATH = ROOT / "Scenes" / "MainMenuAnnaRig.tscn"
# Fixed, so the scenes that hold the rig keep finding it after a rebuild.
SCENE_UID = "uid://bannarig1menu"

# Pixels fainter than this, in a patch with nothing stronger, are eraser
# leftovers: invisible, but they would stretch the trimmed texture.
STRAY_MAX_ALPHA = 16
TRIM_PADDING = 2

# Joint positions on the art canvas, in pixels. Each is a Bone2D.
JOINTS: dict[str, tuple[float, float]] = {
    "Ground": (1100.0, 1077.0),  # the canvas's bottom edge: the legs' far end stays put
    "Hip": (1095.0, 785.0),
    "Waist": (1093.0, 752.0),  # where the upper body bends over the hips
    "Chest": (1090.0, 680.0),  # carries the neck and the shoulder; never scaled itself
    "Neck": (1085.0, 490.0),  # the collar
    "Head": (1078.0, 452.0),  # the base of the skull
    "Shoulder": (1035.0, 535.0),  # the near arm, the one holding the rag
    "Elbow": (1025.0, 695.0),
    "Hand": (975.0, 795.0),
    # Last, so the chest's drawn bone points at the neck rather than at this.
    "Ribs": (1090.0, 680.0),  # the back over the ribcage, swelling with each breath
    # Slid sideways, it turns the head a little to the left or right: see
    # build_head_depth.
    "Turn": (1078.0, 452.0),
}
PARENTS: dict[str, str | None] = {
    "Ground": None,
    "Hip": None,
    "Waist": "Hip",
    "Chest": "Waist",
    "Ribs": "Chest",
    "Neck": "Chest",
    "Head": "Neck",
    "Shoulder": "Chest",
    "Elbow": "Shoulder",
    "Hand": "Elbow",
    "Turn": "Head",
}
# Bones with no child bone get a drawn length and direction by hand (radians).
LEAF_GIZMOS: dict[str, tuple[float, float]] = {
    "Ground": (40.0, -math.pi / 2.0),
    "Ribs": (40.0, -math.pi / 2.0),
    "Head": (60.0, -math.pi / 2.0),
    "Hand": (60.0, math.pi / 2.0 + 0.2),
    "Turn": (30.0, 0.0),
}

# How far each canvas pixel of the head stands out towards the viewer, 0..1;
# set by build_head_depth before the layers are weighted.
head_depth: np.ndarray | None = None


def smooth(t: float) -> float:
    t = min(max(t, 0.0), 1.0)
    return t * t * (3.0 - 2.0 * t)


def band(value: float, start: float, end: float) -> float:
    """0 at `start`, 1 at `end`, eased in between (either direction)."""
    return smooth((value - start) / (end - start))


def j(name: str) -> tuple[float, float]:
    return JOINTS[name]


def legs_weights(x: float, y: float) -> dict[str, float]:
    # The waistband goes with the hips, the legs' far end with the ground, so
    # a weight shift leans the legs instead of sliding them.
    hip = band(y, j("Ground")[1], j("Hip")[1] + 15.0)
    return {"Ground": 1.0 - hip, "Hip": hip}


def body_weights(x: float, y: float) -> dict[str, float]:
    neck_y = j("Neck")[1]
    # The hem stays with the hips, on the waistband it overlaps; the belly
    # goes with the waist, the back above it with the breathing ribs.
    waist = band(y, j("Hip")[1] - 10.0, j("Waist")[1] - 7.0)
    ribs = band(y, j("Ribs")[1] + 25.0, j("Ribs")[1] - 5.0)
    neck = band(y, neck_y + 45.0, neck_y)
    # The neck just under the head turns with the head, or its outline would
    # break where the head layer's neck ends.
    head = band(y, neck_y - 2.0, j("Head")[1] + 14.0)
    upper = waist * ribs
    weights = {
        "Hip": 1.0 - waist,
        "Waist": waist * (1.0 - ribs),
        "Ribs": upper * (1.0 - neck),
        "Neck": upper * neck * (1.0 - head),
        "Head": upper * neck * head,
    }
    # The near sleeve is drawn on the body too, under the arm's own: it swings
    # with the arm, or its edge would show beside the arm's sleeve.
    shoulder_x, shoulder_y = j("Shoulder")
    sleeve = (
        band(x, shoulder_x + 41.0, shoulder_x + 31.0)
        * band(y, shoulder_y - 25.0, shoulder_y - 15.0)
        * band(y, j("Elbow")[1] - 40.0, j("Elbow")[1] - 50.0)
    )
    weights = {bone: weight * (1.0 - sleeve) for bone, weight in weights.items()}
    weights["Shoulder"] = sleeve
    return weights


def arm_weights(x: float, y: float) -> dict[str, float]:
    elbow = band(y, j("Elbow")[1] - 30.0, j("Elbow")[1] + 25.0)
    hand = band(y, j("Hand")[1] - 25.0, j("Hand")[1] + 5.0)
    return {"Shoulder": 1.0 - elbow, "Elbow": elbow * (1.0 - hand), "Hand": elbow * hand}


def head_weights(x: float, y: float) -> dict[str, float]:
    depth = float(ndimage.map_coordinates(head_depth, [[y], [x]], order=1)[0])
    # The neck at the head layer's lower edge does not turn, so it meets the
    # body's neck under it.
    turn = depth * band(y, j("Head")[1] + 18.0, j("Head")[1] - 4.0)
    return {"Head": 1.0 - turn, "Turn": turn}


def build_head_depth() -> float:
    """Sets head_depth, and returns how many pixels a depth of 1 stands for.

    A head seen side-on keeps its outline when it turns a little; what moves is
    what lies inside it, the more the nearer it is to the viewer - the ear, the
    cheek, the eye. The depth is painted in Assets/MainMenu/Anna/head_depth.png (white
    nearest, black on the outline) if that exists. Otherwise it is guessed from
    the head's outline, as if the drawing were blown up like a balloon: 0 on
    the outline, rising inwards. The guess is saved as head_depth_auto.png
    either way, to paint over.
    """
    global head_depth
    alpha = np.array(Image.open(SOURCE_DIR / "head.png").convert("RGBA"))[..., 3]
    inside = alpha >= 128
    distance = ndimage.distance_transform_edt(inside)
    radius = float(distance.max())
    rise = np.clip(distance / radius, 0.0, 1.0)
    # Rounded like a ball, but without a ball's steep edge, which would
    # stretch the lines along the outline.
    guess = np.where(inside, 1.0 - (1.0 - rise) ** 2, 0.0)
    save_if_changed((guess * 255.0).round().astype(np.uint8), SOURCE_DIR / "head_depth_auto.png")
    painted = SOURCE_DIR / "head_depth.png"
    depth = np.asarray(Image.open(painted).convert("L"), dtype=np.float64) / 255.0 if painted.exists() else guess
    head_depth = ndimage.gaussian_filter(depth, 2.0)
    return radius


# Back to front: node name, file, cell size (None makes the layer one rigid
# quad), weights, and whether the layer starts hidden.
LAYERS = [
    ("Legs", "legs", 12.0, legs_weights, False),
    ("Body", "body", 12.0, body_weights, False),
    ("Arm", "arm", 10.0, arm_weights, False),
    ("Head", "head", 8.0, head_weights, False),
]
# Drawn on top of the head when they exist: the script shows them for a blink.
OPTIONAL_LAYERS = [
    ("EyeClosed", "eye_shut", 6.0, head_weights, True),
]


def bone_path(name: str) -> str:
    chain = []
    while name is not None:
        chain.append(name)
        name = PARENTS[name]
    return "/".join(reversed(chain))


def trim_layer(file_stem: str) -> tuple[np.ndarray, tuple[int, int], tuple[int, int]]:
    """Returns the trimmed RGBA pixels, their top-left on the canvas, and the canvas size."""
    image = Image.open(SOURCE_DIR / f"{file_stem}.png").convert("RGBA")
    pixels = np.array(image)
    alpha = pixels[..., 3]
    labels, count = ndimage.label(alpha > 0)
    if count:
        strongest = ndimage.maximum(alpha, labels, range(1, count + 1))
        for index, value in enumerate(strongest, start=1):
            if value < STRAY_MAX_ALPHA:
                pixels[labels == index] = 0
    ys, xs = np.nonzero(pixels[..., 3])
    if len(xs) == 0:
        raise SystemExit(f"{file_stem}.png has nothing drawn on it")
    height, width = alpha.shape
    left = max(int(xs.min()) - TRIM_PADDING, 0)
    top = max(int(ys.min()) - TRIM_PADDING, 0)
    right = min(int(xs.max()) + 1 + TRIM_PADDING, width)
    bottom = min(int(ys.max()) + 1 + TRIM_PADDING, height)
    return pixels[top:bottom, left:right], (left, top), (width, height)


def save_if_changed(pixels: np.ndarray, path: Path) -> None:
    """Leaves an unchanged image alone, so the editor has nothing to reimport."""
    if path.exists():
        existing = np.array(Image.open(path))
        if existing.shape == pixels.shape and np.array_equal(existing, pixels):
            return
    Image.fromarray(pixels).save(path)


def build_mesh(alpha: np.ndarray, origin: tuple[int, int], cell: float | None):
    """Grid cells over the drawn part. Returns canvas points, UVs and triangles."""
    height, width = alpha.shape
    if cell is None:
        corners = [(0.0, 0.0), (width, 0.0), (width, height), (0.0, height)]
        points = [(origin[0] + u, origin[1] + v) for u, v in corners]
        return points, corners, [(0, 1, 2), (0, 2, 3)]

    columns = max(1, math.ceil(width / cell))
    rows = max(1, math.ceil(height / cell))
    step_x = width / columns
    step_y = height / rows
    # A cell is kept if it, or the 2 px round it, has any ink.
    covered = ndimage.binary_dilation(alpha > 0, iterations=2)
    index_of: dict[tuple[int, int], int] = {}
    uvs: list[tuple[float, float]] = []
    triangles: list[tuple[int, int, int]] = []

    def vertex(column: int, row: int) -> int:
        key = (column, row)
        if key not in index_of:
            index_of[key] = len(uvs)
            uvs.append((column * step_x, row * step_y))
        return index_of[key]

    for row in range(rows):
        for column in range(columns):
            x0, x1 = int(column * step_x), int(math.ceil((column + 1) * step_x))
            y0, y1 = int(row * step_y), int(math.ceil((row + 1) * step_y))
            if not covered[y0:y1, x0:x1].any():
                continue
            a = vertex(column, row)
            b = vertex(column + 1, row)
            c = vertex(column + 1, row + 1)
            d = vertex(column, row + 1)
            triangles.append((a, b, c))
            triangles.append((a, c, d))
    points = [(origin[0] + u, origin[1] + v) for u, v in uvs]
    return points, uvs, triangles


def num(value: float) -> str:
    text = f"{value:.3f}".rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def vector_array(values) -> str:
    return "PackedVector2Array(" + ", ".join(f"{num(x)}, {num(y)}" for x, y in values) + ")"


def write_scene(layers: list[dict], canvas_size: tuple[int, int], head_turn_depth: float) -> None:
    lines = [f'[gd_scene format=3 uid="{SCENE_UID}"]', ""]
    for index, layer in enumerate(layers, start=1):
        lines.append(
            f'[ext_resource type="Texture2D" path="res://Assets/MainMenu/Anna/Rig/{layer["file"]}.png" id="{index}_{layer["file"]}"]'
        )
    lines += [
        "",
        '[node name="Rig" type="Node2D"]',
        'editor_description = "Generated by tools/build_anna_rig.py from Assets/MainMenu/Anna: changes made here are lost on the next build."',
        f"metadata/art_canvas_size = Vector2({canvas_size[0]}, {canvas_size[1]})",
        f"metadata/head_turn_depth = {num(head_turn_depth)}",
        "",
        '[node name="Skeleton" type="Skeleton2D" parent="."]',
        "",
    ]
    for name, (x, y) in JOINTS.items():
        parent = PARENTS[name]
        local = (x - JOINTS[parent][0], y - JOINTS[parent][1]) if parent else (x, y)
        parent_path = "Skeleton" + ("/" + bone_path(parent) if parent else "")
        lines.append(f'[node name="{name}" type="Bone2D" parent="{parent_path}"]')
        lines.append(f"position = Vector2({num(local[0])}, {num(local[1])})")
        lines.append(f"rest = Transform2D(1, 0, 0, 1, {num(local[0])}, {num(local[1])})")
        if name in LEAF_GIZMOS:
            length, angle = LEAF_GIZMOS[name]
            lines.append("auto_calculate_length_and_angle = false")
            lines.append(f"length = {num(length)}")
            lines.append(f"bone_angle = {num(angle)}")
        lines.append("")
    for index, layer in enumerate(layers, start=1):
        lines.append(f'[node name="{layer["name"]}" type="Polygon2D" parent="."]')
        if layer["hidden"]:
            lines.append("visible = false")
        lines.append(f'texture = ExtResource("{index}_{layer["file"]}")')
        lines.append('skeleton = NodePath("../Skeleton")')
        lines.append(f"polygon = {vector_array(layer['points'])}")
        lines.append(f"uv = {vector_array(layer['uvs'])}")
        lines.append(
            "polygons = [" + ", ".join(f"PackedInt32Array({a}, {b}, {c})" for a, b, c in layer["triangles"]) + "]"
        )
        bone_entries = []
        for bone, weights in layer["weights"].items():
            bone_entries.append(f'NodePath("{bone_path(bone)}")')
            bone_entries.append("PackedFloat32Array(" + ", ".join(num(w) for w in weights) + ")")
        lines.append("bones = [" + ", ".join(bone_entries) + "]")
        lines.append("")
    SCENE_PATH.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def main() -> None:
    RIG_TEXTURE_DIR.mkdir(exist_ok=True)
    built = []
    canvas_size = None
    head_turn_depth = build_head_depth()
    present =[layer for layer in OPTIONAL_LAYERS if (SOURCE_DIR / f"{layer[1]}.png").exists()]
    for name, file_stem, cell, rule, hidden in LAYERS + present:
        pixels, origin, size = trim_layer(file_stem)
        if canvas_size is None:
            canvas_size = size
        elif size != canvas_size:
            raise SystemExit(f"{file_stem}.png is {size}, the other layers are {canvas_size}")
        save_if_changed(pixels, RIG_TEXTURE_DIR / f"{file_stem}.png")
        points, uvs, triangles = build_mesh(pixels[..., 3], origin, cell)
        per_vertex = [rule(x, y) for x, y in points]
        weights = {}
        for bone in JOINTS:
            column = [w.get(bone, 0.0) for w in per_vertex]
            if max(column) > 0.0005:
                weights[bone] = column
        built.append({"name": name, "file": file_stem, "points": points, "uvs": uvs,
                      "triangles": triangles, "weights": weights, "hidden": hidden})
        print(f"{name}: {pixels.shape[1]}x{pixels.shape[0]} at {origin}, "
              f"{len(points)} vertices, {len(triangles)} triangles, bones {', '.join(weights)}")
    write_scene(built, canvas_size, head_turn_depth)
    print(f"wrote {SCENE_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
