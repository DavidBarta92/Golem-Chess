#!/usr/bin/env python3
"""Bake the UI's ink-stamp prints (Docs/Style/STYLE_PLAN.md, "Ink-stamp texture").

The UI's ink is pressed onto the paper like a rubber stamp: a little ink missing
in small specks, slightly ragged edges, faintly uneven density. Ink is taken
away, never lightened, so the specks show whatever is beneath.

The script reads every InkStampStyleBox in the project's themes, takes its
`shape` (a StyleBoxFlat: fill, border widths and colour, corner radii) and
renders that shape as 9-patch PNGs - several variants per style, each with its
own specks - into ui/themes/stamp/<stamp_name>_<n>.png. The border and any ink
fill get the specks; a paper fill stays whole. Edges and centre are made to
tile seamlessly, because InkStampStyleBox tiles them rather than stretching,
so a speck keeps its size on any control.

It also writes ui/themes/stamp/ink_stamp_mask.png, the tiling mask that
Shaders/ink_stamp.gdshader prints titles and drawn items with, so both share
one look: the line's specks in red, the sparser specks of an ink fill in green.
And ui/themes/stamp/ink_flood_noise.png, the noise that gives a button's
hover fill (Shaders/ink_flood.gdshader) its ragged front.

Usage:
    python tools/generate_ink_stamps.py

Re-run it whenever a stamped style's shape changes (a colour, a border, a
radius) or after adding an InkStampStyleBox to a theme. Godot imports the PNGs
when the editor next gets focus. The look is tuned by the constants below.
"""

from __future__ import annotations

import re
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

ROOT = Path(__file__).resolve().parent.parent
THEMES = [ROOT / "ui/themes/global_theme.tres", ROOT / "ui/themes/collection_theme.tres"]
OUT_DIR = ROOT / "ui/themes/stamp"
STAMP_SCRIPT = "res://Scripts/InkStamp/InkStampStyleBox.gd"

# Keep these two in step with InkStampStyleBox.gd.
PAD = 2
CORNER_EXTRA = 2

# The tiling centre of each print, and so the period of its specks. Edges
# tile along their length with the same period.
CENTRE_WIDTH = 256
CENTRE_HEIGHT = 128
MASK_SIZE = 256

# Specks: the share of ink missing drifts between these two across a control
# ("faintly uneven density"), over patches about DENSITY_SCALE units across.
MISSING_MIN = 0.04
MISSING_MAX = 0.10
DENSITY_SCALE = 22.0
# A speck is a small cluster of one or two dots of these radii, in units at
# the 1280x720 base.
SPECK_RADIUS = (0.35, 0.75)
# Ragged edges: the outline wanders by up to about this much, over this scale.
RAGGED_AMOUNT = 0.35
RAGGED_SCALE = 1.6
# A fill darker than this counts as ink and gets the specks too - fewer of
# them, since paper-coloured specks on a big patch of ink stand out more than
# on a line.
INK_FILL_LUMINANCE = 0.5
FILL_SPECK_SHARE = 0.5
# The inside of a thick border (a window's title bar) counts as a fill: deeper
# than this from both of its edges.
THICK_BORDER_DEPTH = 2.5
# A button's hover fill floods in along a ragged front: blotches about this
# many units across, with a finer wander along their edges.
FLOOD_BLOTCH_SCALE = 9.0
FLOOD_WANDER_SCALE = 2.5
SEED = 1871


def periodic_noise(rng: np.random.Generator, width: int, height: int, sigma: float) -> np.ndarray:
    """Smooth noise in 0..1 that tiles seamlessly over width x height."""
    field = gaussian_filter(rng.standard_normal((height, width)), sigma, mode="wrap")
    field -= field.min()
    return field / max(field.max(), 1e-9)


def speck_keep_mask(rng: np.random.Generator, width: int, height: int, share: float = 1.0) -> np.ndarray:
    """1 where the ink stays, 0 in a speck, anti-aliased; tiles over width x height."""
    density = share * (MISSING_MIN + (MISSING_MAX - MISSING_MIN) * periodic_noise(rng, width, height, DENSITY_SCALE))
    mean_area = np.pi * np.mean(SPECK_RADIUS) ** 2 * 1.6
    count = int(MISSING_MAX * width * height / mean_area * 1.25)
    centres = rng.uniform((0, 0), (width, height), size=(count, 2))
    # Thin the candidates so their density follows the drifting share.
    keep_centre = rng.uniform(0, MISSING_MAX, count) < density[centres[:, 1].astype(int) % height, centres[:, 0].astype(int) % width]
    holes = np.zeros((height, width))
    ys, xs = np.mgrid[-3:4, -3:4]
    for cx, cy in centres[keep_centre]:
        for _ in range(rng.integers(1, 3)):
            dx, dy = rng.uniform(-0.7, 0.7, 2)
            radius = rng.uniform(*SPECK_RADIUS)
            px, py = cx + dx, cy + dy
            ix, iy = int(np.floor(px)), int(np.floor(py))
            dist = np.hypot(xs + ix + 0.5 - px, ys + iy + 0.5 - py)
            coverage = np.clip(radius + 0.5 - dist, 0.0, 1.0)
            rows = (ys + iy) % height
            cols = (xs + ix) % width
            holes[rows, cols] = np.maximum(holes[rows, cols], coverage)
    return 1.0 - holes


def rounded_box_sdf(px: np.ndarray, py: np.ndarray, box: tuple[float, float, float, float], radii: tuple[float, float, float, float]) -> np.ndarray:
    """Signed distance to a rounded box (left, top, right, bottom) with radii (tl, tr, br, bl)."""
    left, top, right, bottom = box
    cx, cy = (left + right) * 0.5, (top + bottom) * 0.5
    hx, hy = max((right - left) * 0.5, 0.0), max((bottom - top) * 0.5, 0.0)
    tl, tr, br, bl = radii
    radius = np.where(px < cx, np.where(py < cy, tl, bl), np.where(py < cy, tr, br))
    radius = np.minimum(radius, min(hx, hy))
    qx = np.abs(px - cx) - hx + radius
    qy = np.abs(py - cy) - hy + radius
    outside = np.hypot(np.maximum(qx, 0.0), np.maximum(qy, 0.0))
    inside = np.minimum(np.maximum(qx, qy), 0.0)
    return outside + inside - radius


def luminance(rgba: np.ndarray) -> float:
    return float(0.2126 * rgba[0] + 0.7152 * rgba[1] + 0.0722 * rgba[2])


def patch_margins(shape: dict) -> tuple[int, int, int, int]:
    w, r = shape["border"], shape["radius"]
    sides = (max(r[0], r[3], w[0]), max(r[0], r[1], w[1]), max(r[1], r[2], w[2]), max(r[3], r[2], w[3]))
    return tuple(PAD + int(np.ceil(side)) + CORNER_EXTRA for side in sides)


def render_print(shape: dict, rng: np.random.Generator) -> np.ndarray:
    left, top, right, bottom = patch_margins(shape)
    width, height = left + CENTRE_WIDTH + right, top + CENTRE_HEIGHT + bottom
    # Specks and raggedness are periodic over the centre tile, so the tiled
    # centre and edges join without seams.
    keep_tile = speck_keep_mask(rng, CENTRE_WIDTH, CENTRE_HEIGHT)
    fill_keep_tile = speck_keep_mask(rng, CENTRE_WIDTH, CENTRE_HEIGHT, FILL_SPECK_SHARE)
    ragged_tile = (periodic_noise(rng, CENTRE_WIDTH, CENTRE_HEIGHT, RAGGED_SCALE) - 0.5) * 2.0 * RAGGED_AMOUNT
    rows = (np.arange(height) - top) % CENTRE_HEIGHT
    cols = (np.arange(width) - left) % CENTRE_WIDTH
    keep = keep_tile[np.ix_(rows, cols)]
    fill_keep_all = fill_keep_tile[np.ix_(rows, cols)]
    ragged = ragged_tile[np.ix_(rows, cols)]

    py, px = np.mgrid[0:height, 0:width] + 0.5
    bw = shape["border"]
    radii = shape["radius"]
    outer_box = (PAD, PAD, width - PAD, height - PAD)
    inner_box = (PAD + bw[0], PAD + bw[1], width - PAD - bw[2], height - PAD - bw[3])
    inner_radii = (
        max(radii[0] - max(bw[0], bw[1]), 0.0),
        max(radii[1] - max(bw[2], bw[1]), 0.0),
        max(radii[2] - max(bw[2], bw[3]), 0.0),
        max(radii[3] - max(bw[0], bw[3]), 0.0),
    )
    outer_sdf = rounded_box_sdf(px, py, outer_box, radii)
    inner_sdf = rounded_box_sdf(px, py, inner_box, inner_radii)
    # The inner edge wanders less than the outer one, so a border's width
    # varies a little - except on a side with no border, where the two edges
    # are one and must wander together, or they would leave a hairline of ink.
    side_distances = np.stack([px - outer_box[0], py - outer_box[1], outer_box[2] - px, outer_box[3] - py])
    no_border_side = np.array([width_on_side <= 0 for width_on_side in bw])[np.argmin(side_distances, axis=0)]
    inner_ragged = np.where(no_border_side, ragged, ragged * 0.6)
    outer = np.clip(0.5 - (outer_sdf + ragged), 0.0, 1.0)
    inner = np.clip(0.5 - (inner_sdf + inner_ragged), 0.0, 1.0)
    inner = np.minimum(inner, outer)
    ring = outer - inner if max(bw) > 0 else np.zeros_like(outer)
    fill = inner if shape["draw_center"] else np.zeros_like(inner)

    border_rgba, fill_rgba = shape["border_color"], shape["bg_color"]
    ring_keep = np.where(np.minimum(-outer_sdf, inner_sdf) > THICK_BORDER_DEPTH, fill_keep_all, keep)
    ring_alpha = ring * border_rgba[3] * ring_keep
    fill_keep = fill_keep_all if luminance(fill_rgba) < INK_FILL_LUMINANCE else 1.0
    fill_alpha = fill * fill_rgba[3] * fill_keep
    alpha = ring_alpha + fill_alpha
    safe = np.maximum(alpha, 1e-6)
    rgb = (ring_alpha[..., None] * border_rgba[:3] + fill_alpha[..., None] * fill_rgba[:3]) / safe[..., None]
    out = np.dstack([rgb, alpha])
    return (np.clip(out, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8)


def parse_color(text: str) -> np.ndarray:
    values = [float(v) for v in re.search(r"Color\(([^)]*)\)", text).group(1).split(",")]
    return np.array(values + [1.0] * (4 - len(values)))


def read_stamps(theme_path: Path) -> list[dict]:
    text = theme_path.read_text(encoding="utf-8")
    script_ids = re.findall(r'\[ext_resource type="Script"[^\]]*path="%s"[^\]]*id="([^"]+)"\]' % re.escape(STAMP_SCRIPT), text)
    if not script_ids:
        return []
    blocks = {}
    for block in re.split(r"\n(?=\[)", text):
        match = re.match(r'\[sub_resource type="[^"]+"[^\]]*id="([^"]+)"\]\n?(.*)', block, re.S)
        if match:
            props = {}
            for line in match.group(2).strip().split("\n"):
                if " = " in line:
                    key, value = line.split(" = ", 1)
                    props[key] = value
            blocks[match.group(1)] = props
    stamps = []
    for props in blocks.values():
        if props.get("script") not in ['ExtResource("%s")' % sid for sid in script_ids]:
            continue
        flat = blocks[re.search(r'SubResource\("([^"]+)"\)', props["shape"]).group(1)]
        sides = ["left", "top", "right", "bottom"]
        corners = ["top_left", "top_right", "bottom_right", "bottom_left"]
        stamps.append({
            "name": props["stamp_name"].strip('"'),
            "variants": int(props.get("variants", "4")),
            "shape": {
                "bg_color": parse_color(flat.get("bg_color", "Color(0.6, 0.6, 0.6, 1)")),
                "border_color": parse_color(flat.get("border_color", "Color(0.8, 0.8, 0.8, 1)")),
                "border": [float(flat.get("border_width_%s" % side, 0)) for side in sides],
                "radius": [float(flat.get("corner_radius_%s" % corner, 0)) for corner in corners],
                "draw_center": flat.get("draw_center", "true") != "false",
            },
        })
    return stamps


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(SEED)
    line_mask = speck_keep_mask(rng, MASK_SIZE, MASK_SIZE)
    fill_mask = speck_keep_mask(rng, MASK_SIZE, MASK_SIZE, FILL_SPECK_SHARE)
    mask = np.stack([line_mask, fill_mask, line_mask], axis=-1)
    Image.fromarray((mask * 255.0 + 0.5).astype(np.uint8), "RGB").save(OUT_DIR / "ink_stamp_mask.png")
    # The ragged front of a button's hover fill (Shaders/ink_flood.gdshader):
    # blotches in red, finer wander in green.
    flood_rng = np.random.default_rng([SEED, sum(map(ord, "flood"))])
    blotches = periodic_noise(flood_rng, MASK_SIZE, MASK_SIZE, FLOOD_BLOTCH_SCALE)
    wander = periodic_noise(flood_rng, MASK_SIZE, MASK_SIZE, FLOOD_WANDER_SCALE)
    flood = np.stack([blotches, wander, np.zeros_like(blotches)], axis=-1)
    Image.fromarray((flood * 255.0 + 0.5).astype(np.uint8), "RGB").save(OUT_DIR / "ink_flood_noise.png")
    written = 2
    for theme_path in THEMES:
        for stamp in read_stamps(theme_path):
            for index in range(stamp["variants"]):
                variant_rng = np.random.default_rng([SEED, index, sum(map(ord, stamp["name"]))])
                pixels = render_print(stamp["shape"], variant_rng)
                Image.fromarray(pixels, "RGBA").save(OUT_DIR / f"{stamp['name']}_{index}.png")
                written += 1
            print(f"{theme_path.name}: {stamp['name']} x{stamp['variants']}")
    print(f"wrote {written} PNGs to {OUT_DIR.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
