#!/usr/bin/env python3
"""Bake the two textures behind the frozen look (Docs/Style/FREEZE_ICE.md).

Writes into Assets/Ice/:

    ice_surface.png  the shape of the ice, 512x512, tiles:
                       R, G  how far the surface leans along x and y (0.5 is level)
                       B     cracks, 1 on a crack
                       A     how milky the ice is
    ice_room.png     the match's room, small, grey and blurred: what the ice reflects

Run it again after a change to the kiosk room's art, so the reflection still
shows that room.

Usage:
    python tools/generate_ice_textures.py
"""
import os
import numpy as np
from PIL import Image, ImageFilter
from scipy.ndimage import gaussian_filter

SIZE = 512
SHARD_COUNT = 34
ROOM_SIZE = (192, 108)
ASSETS = os.path.join(os.path.dirname(__file__), "..", "Assets")
OUT_DIR = os.path.join(ASSETS, "Ice")

# The kiosk room's layers, back to front, as MatchBackground.tscn stacks them.
ROOM_LAYERS = ["bg3", "bg_body", "bg_table_base", "bg_table_color", "bg_window_color", "bg_window_line"]
ROOM_PAPER = (244, 240, 230, 255)


def grid():
    coords = (np.arange(SIZE) + 0.5) / SIZE
    return np.meshgrid(coords, coords)  # x, y in 0..1


def wrapped_delta(a, b):
    """Shortest offset from b to a on a torus of size 1, so the tile joins up."""
    d = a - b
    return d - np.round(d)


def soft_noise(rng, sigma):
    """Tiling noise with blobs about sigma pixels across, scaled to unit deviation."""
    field = gaussian_filter(rng.standard_normal((SIZE, SIZE)), sigma, mode="wrap")
    return field / field.std()


def slope_of(field):
    """How steeply a tiling height field rises along x and y."""
    dx = (np.roll(field, -1, axis=1) - np.roll(field, 1, axis=1)) * 0.5
    dy = (np.roll(field, -1, axis=0) - np.roll(field, 1, axis=0)) * 0.5
    return dx, dy


def surface(rng):
    x, y = grid()

    # Bent a little first, so the shards do not have ruler-straight sides.
    wander = 0.018
    bent_x = x + soft_noise(rng, 20.0) * wander
    bent_y = y + soft_noise(rng, 20.0) * wander

    seeds = rng.random((SHARD_COUNT, 2))
    dists = np.empty((SHARD_COUNT, SIZE, SIZE))
    deltas = np.empty((SHARD_COUNT, 2, SIZE, SIZE))
    for i, (sx, sy) in enumerate(seeds):
        dx, dy = wrapped_delta(bent_x, sx), wrapped_delta(bent_y, sy)
        deltas[i] = (dx, dy)
        dists[i] = np.hypot(dx, dy)
    order = np.argsort(dists, axis=0)
    nearest, second = order[0], order[1]
    d1 = np.take_along_axis(dists, nearest[None], 0)[0]
    d2 = np.take_along_axis(dists, second[None], 0)[0]
    to_seed_x = np.take_along_axis(deltas[:, 0], nearest[None], 0)[0]
    to_seed_y = np.take_along_axis(deltas[:, 1], nearest[None], 0)[0]

    # Every shard leans its own way and is slightly domed, so what lies behind
    # it jumps at a crack and bends across a shard.
    lean = rng.normal(0.0, 1.0, (SHARD_COUNT, 2))
    lean /= np.linalg.norm(lean, axis=1, keepdims=True)
    lean *= rng.uniform(0.2, 0.75, (SHARD_COUNT, 1))
    shard_radius = 0.5 / np.sqrt(SHARD_COUNT)
    slope_x = lean[nearest, 0] + to_seed_x / shard_radius * 0.35
    slope_y = lean[nearest, 1] + to_seed_y / shard_radius * 0.35

    # Over that, the frozen surface's own slow lumps.
    lump_x, lump_y = slope_of(soft_noise(rng, 26.0) * 26.0 + soft_noise(rng, 9.0) * 5.0)
    slope_x += lump_x * 0.45
    slope_y += lump_y * 0.45

    # Level on average, or the whole picture behind the ice would slide one way.
    slope_x -= slope_x.mean()
    slope_y -= slope_y.mean()

    # Not every side of a shard is a crack: the rest stay as a change of lean.
    keeps = rng.random((SHARD_COUNT, SHARD_COUNT))
    keeps = (keeps + keeps.T) * 0.5 > 0.42
    gap = d2 - d1
    crack = np.exp(-((gap / 0.0065) ** 2)) * keeps[nearest, second]
    crack = gaussian_filter(crack, 0.7, mode="wrap")

    milk = soft_noise(rng, 34.0) * 0.6 + soft_noise(rng, 11.0) * 0.3 + soft_noise(rng, 4.0) * 0.15
    milk = np.clip(0.5 + milk * 0.34, 0.02, 1.0)

    channels = (
        np.clip(slope_x * 0.5 + 0.5, 0.0, 1.0),
        np.clip(slope_y * 0.5 + 0.5, 0.0, 1.0),
        np.clip(crack, 0.0, 1.0),
        milk,
    )
    pixels = np.stack(channels, axis=-1)
    return Image.fromarray((pixels * 255.0 + 0.5).astype(np.uint8))


def room():
    picture = Image.new("RGBA", (1920, 1080), ROOM_PAPER)
    for layer in ROOM_LAYERS:
        path = os.path.join(ASSETS, layer + ".png")
        picture = Image.alpha_composite(picture, Image.open(path).convert("RGBA"))
    small = picture.convert("L").resize(ROOM_SIZE, Image.LANCZOS)
    return small.filter(ImageFilter.GaussianBlur(1.6))


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    surface(np.random.default_rng(1147)).save(os.path.join(OUT_DIR, "ice_surface.png"))
    room().save(os.path.join(OUT_DIR, "ice_room.png"))


if __name__ == "__main__":
    main()
