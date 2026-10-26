#!/usr/bin/env python3
"""Generate the grayscale height maps behind the foil styles (FoilStyles/*.tres).

Light is high, dark is low; Shaders/foil.gdshaderinc shifts the foil's colour bands
by the height, so the pattern shows up as the bands bend around it. Writes 512x512
grayscale PNGs into Assets/FoilPatterns/:

    cracked_ice.png  shards with their own tilt and dark cracks between them (tiles)
    starlight.png    scattered four-pointed stars over a faint grain (tiles)
    waves.png        rings rippling out from the middle (centred, one tile per stamp)
    sunburst.png     rays fanning out from the middle (centred, one tile per stamp)

Any of them can be swapped for a hand-drawn grayscale image of any size.

Usage:
    python tools/generate_foil_patterns.py
"""
import os
import numpy as np
from PIL import Image

SIZE = 512
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "Assets", "FoilPatterns")


def grid():
    coords = (np.arange(SIZE) + 0.5) / SIZE
    return np.meshgrid(coords, coords)  # x, y in 0..1


def wrapped_delta(a, b):
    """Shortest offset from b to a on a torus of size 1, so tiling patterns join up."""
    d = a - b
    return d - np.round(d)


def cracked_ice(rng):
    x, y = grid()
    count = 34
    seeds = rng.random((count, 2))
    base = rng.uniform(0.15, 0.85, count)
    tilt = rng.normal(0.0, 1.0, (count, 2))
    tilt /= np.linalg.norm(tilt, axis=1, keepdims=True)
    slope = rng.uniform(0.8, 2.0, count)

    dists = np.empty((count, SIZE, SIZE))
    deltas = np.empty((count, 2, SIZE, SIZE))
    for i, (sx, sy) in enumerate(seeds):
        dx, dy = wrapped_delta(x, sx), wrapped_delta(y, sy)
        deltas[i] = (dx, dy)
        dists[i] = np.hypot(dx, dy)
    order = np.argsort(dists, axis=0)
    nearest, second = order[0], order[1]
    d1 = np.take_along_axis(dists, nearest[None], 0)[0]
    d2 = np.take_along_axis(dists, second[None], 0)[0]

    # Each shard is a tilted plane, so the bands run across it at its own angle.
    dx = np.take_along_axis(deltas[:, 0], nearest[None], 0)[0]
    dy = np.take_along_axis(deltas[:, 1], nearest[None], 0)[0]
    height = base[nearest] + (dx * tilt[nearest, 0] + dy * tilt[nearest, 1]) * slope[nearest]
    height = np.clip(height, 0.0, 1.0)
    crack = np.clip((d2 - d1) / 0.006, 0.0, 1.0)
    return height * (0.25 + 0.75 * crack)


def starlight(rng):
    x, y = grid()
    height = rng.random((SIZE, SIZE)) * 0.06
    for _ in range(170):
        sx, sy = rng.random(2)
        radius = rng.uniform(0.0025, 0.009)
        brightness = rng.uniform(0.45, 1.0)
        dx, dy = wrapped_delta(x, sx), wrapped_delta(y, sy)
        core = np.exp(-(dx * dx + dy * dy) / (2.0 * radius * radius))
        ray_len = radius * rng.uniform(3.0, 6.0)
        rays = (np.exp(-(dy / (radius * 0.25)) ** 2) * np.exp(-(dx / ray_len) ** 2)
                + np.exp(-(dx / (radius * 0.25)) ** 2) * np.exp(-(dy / ray_len) ** 2))
        height = np.maximum(height, brightness * np.clip(core + rays * 0.55, 0.0, 1.0))
    return height


def waves(rng):
    x, y = grid()
    dx, dy = x - 0.5, y - 0.5
    radius = np.hypot(dx, dy)
    angle = np.arctan2(dy, dx)
    # The wobble fades in away from the middle, where it would pinch the rings into a star.
    wobble = (0.012 * np.sin(angle * 5.0 + 0.7) + 0.008 * np.sin(angle * 9.0 + 2.1)) * np.clip(radius / 0.2, 0.0, 1.0)
    rings = 0.5 + 0.5 * np.sin((radius + wobble) * 2.0 * np.pi * 9.0)
    return rings ** 1.4


def sunburst(rng):
    x, y = grid()
    dx, dy = x - 0.5, y - 0.5
    radius = np.hypot(dx, dy)
    angle = np.arctan2(dy, dx)
    rays = 28
    turn = (angle / (2.0 * np.pi) + 0.5) * rays
    triangle = np.abs((turn % 1.0) * 2.0 - 1.0)
    height = triangle ** 0.8
    centre = np.clip(1.0 - radius / 0.05, 0.0, 1.0)
    return np.maximum(height, centre)


def save(name, height):
    image = Image.fromarray((np.clip(height, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8), "L")
    path = os.path.join(OUT_DIR, name + ".png")
    image.save(path, optimize=True)
    print("wrote", os.path.normpath(path))


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    rng = np.random.default_rng(1977)
    for name, make in (("cracked_ice", cracked_ice), ("starlight", starlight),
                       ("waves", waves), ("sunburst", sunburst)):
        save(name, make(rng))


if __name__ == "__main__":
    main()
