#!/usr/bin/env python3
"""Build the main menu's art for the game from the drawn layers in Assets/MainMenu.

Every layer is drawn on the menu art's full canvas (1919x1077) in its final
place, so it lines up with the room by itself. Loaded as it is, though, each
button would hold a screen-sized texture in video memory (8 MB) for a few
hundred pixels of drawing. This script

  * trims every button, cover and extra layer (mainmenu_*_button.png,
    mainmenu_*_cover.png, mainmenu_*_extra.png) down to its drawing and saves
    it to Assets/MainMenu/Built/, with an AtlasTexture (.tres) beside it that
    puts the drawing back in its place on a canvas of the full size. The scene
    uses those, so to the game each layer is still the full picture;
  * remakes the background's line reveal mask
    (tools/generate_line_reveal_mask.py) when mainmenu_bg_1.png is newer than
    the mask.

Re-run it after changing any of these layers, then let the editor import the
new files:

    python tools/build_main_menu_art.py

A new layer is picked up by its name; add it to the scene by its .tres in
Built/. Anna has a build of her own (tools/build_anna_rig.py).
"""

from __future__ import annotations

import hashlib
import subprocess
import sys
from io import BytesIO
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ART_DIR = ROOT / "Assets" / "MainMenu"
BUILT_DIR = ART_DIR / "Built"
LAYER_PATTERNS = ["mainmenu_*_button.png", "mainmenu_*_cover.png", "mainmenu_*_extra.png"]
BACKGROUND = ART_DIR / "mainmenu_bg_1.png"
BACKGROUND_MASK = ART_DIR / "mainmenu_bg_1_reveal_mask.png"
# Leftover specks fainter than this (eraser crumbs) do not count as drawing.
MIN_ALPHA = 16
# Transparent pixels kept round the drawing, so its edge filters smoothly.
PAD = 2
UID_CHARACTERS = "abcdefghijklmnopqrstuvwxyz0123456789"


def res_path(path: Path) -> str:
    return "res://" + path.relative_to(ROOT).as_posix()


def stable_uid(name: str) -> str:
    """A uid that stays the same across builds, so the scene keeps finding it."""
    value = int(hashlib.md5(f"mainmenu-art:{name}".encode("utf-8")).hexdigest(), 16) & ((1 << 62) - 1)
    text = ""
    while value > 0:
        text = UID_CHARACTERS[value % len(UID_CHARACTERS)] + text
        value //= len(UID_CHARACTERS)
    return "uid://" + text


def write_if_changed(path: Path, data: bytes) -> bool:
    if path.exists() and path.read_bytes() == data:
        return False
    path.write_bytes(data)
    return True


def trim_layer(source: Path) -> tuple[Image.Image, tuple[int, int, int, int], tuple[int, int]]:
    image = Image.open(source).convert("RGBA")
    alpha = np.asarray(image)[..., 3]
    ys, xs = np.nonzero(alpha >= MIN_ALPHA)
    if len(xs) == 0:
        raise SystemExit(f"{source.name}: nothing drawn")
    left = max(0, int(xs.min()) - PAD)
    top = max(0, int(ys.min()) - PAD)
    right = min(image.width, int(xs.max()) + 1 + PAD)
    bottom = min(image.height, int(ys.max()) + 1 + PAD)
    return image.crop((left, top, right, bottom)), (left, top, right, bottom), image.size


def atlas_texture_text(name: str, png: Path, box: tuple[int, int, int, int], canvas: tuple[int, int]) -> str:
    left, top, right, bottom = box
    width, height = right - left, bottom - top
    return "\n".join([
        f'[gd_resource type="AtlasTexture" format=3 uid="{stable_uid(name)}"]',
        "",
        f'[ext_resource type="Texture2D" path="{res_path(png)}" id="1_art"]',
        "",
        "[resource]",
        f'resource_name = "{name}"',
        'atlas = ExtResource("1_art")',
        f"region = Rect2(0, 0, {width}, {height})",
        # The margin's position is where the drawing sits on the canvas, its
        # size what the canvas has beyond the drawing: together the full size.
        f"margin = Rect2({left}, {top}, {canvas[0] - width}, {canvas[1] - height})",
        "filter_clip = true",
        "",
    ])


def build_layers() -> None:
    BUILT_DIR.mkdir(exist_ok=True)
    sources = sorted({path for pattern in LAYER_PATTERNS for path in ART_DIR.glob(pattern)})
    for source in sources:
        trimmed, box, canvas = trim_layer(source)
        png = BUILT_DIR / source.name
        tres = BUILT_DIR / (source.stem + ".tres")
        buffer = BytesIO()
        trimmed.save(buffer, format="PNG", optimize=True)
        png_changed = write_if_changed(png, buffer.getvalue())
        tres_changed = write_if_changed(tres, atlas_texture_text(source.stem, png, box, canvas).encode("utf-8"))
        state = "updated" if png_changed or tres_changed else "unchanged"
        print(f"{source.name}: {trimmed.width}x{trimmed.height} at ({box[0]}, {box[1]}) - {state}")


def build_background_mask() -> None:
    if BACKGROUND_MASK.exists() and BACKGROUND_MASK.stat().st_mtime >= BACKGROUND.stat().st_mtime:
        print(f"{BACKGROUND_MASK.name}: up to date")
        return
    print(f"{BACKGROUND.name} changed: remaking its line reveal mask")
    subprocess.run([sys.executable, str(ROOT / "tools" / "generate_line_reveal_mask.py"), str(BACKGROUND)], check=True, cwd=ROOT)


def main() -> int:
    build_layers()
    build_background_mask()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
