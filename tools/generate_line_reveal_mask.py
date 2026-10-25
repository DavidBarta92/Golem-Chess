#!/usr/bin/env python3
"""Generate a "line reveal" mask texture for a self-drawing line-art shader.

The input is a black-lines-on-white (or transparent) sketch PNG. The script
skeletonizes the artwork, splits it into individual strokes at intersections
(rejoining straight-through crossings so a line isn't chopped in half where
another line crosses it), and encodes per-pixel animation data into an RGBA
output texture:

    R = progress   - 0..1 position of this pixel along its own stroke
    G = delay      - 0..1 random per-stroke start offset
    B = length     - 0..1 stroke length normalized against the longest stroke
                     (used to scale draw duration so long lines take longer)
    A = ink_alpha  - anti-aliased "how much ink is here" opacity, taken
                     straight from the source image (not re-thresholded)

Feed the output into Shaders/mainmenu_line_reveal.gdshader as the texture of
a TextureRect placed over a static (line-free) background.

Usage:
    python tools/generate_line_reveal_mask.py Assets/mainmenu_bg_1.png

For painted, coloured art (the logo) rather than black line art, add
--ink-from-alpha: every opaque pixel counts as ink, whatever its colour. Add
--left-to-right to write the art from left to right - each stroke starts at
its left end, and the further right a stroke starts, the later - instead of in
a random order. The logo's mask:
    python tools/generate_line_reveal_mask.py Assets/golem_logo_reveal_source.png --ink-from-alpha --left-to-right --out Assets/golem_logo_reveal_mask.png --no-debug

Re-run this exact command any time the source PNG changes; there is nothing
to hand-tune for a typical edit. The one place that can occasionally need a
second look is a newly introduced or reshaped line crossing, where the
straight-through pairing heuristic can guess wrong -- open the debug preview
(<name>_reveal_debug.png) next to the mask and look for a stroke color that
abruptly changes where it shouldn't, or a stroke that dead-ends where a line
visually continues.
"""

from __future__ import annotations

import argparse
import colorsys
import sys
import time
from pathlib import Path

import networkx as nx
import numpy as np
from PIL import Image
from scipy import ndimage
from skimage.morphology import skeletonize


def load_ink(path: Path, threshold: float, from_alpha: bool = False) -> tuple[np.ndarray, np.ndarray]:
    """Returns (ink_bool, ink_alpha) for skeletonization / final alpha."""
    img = Image.open(path).convert("RGBA")
    arr = np.asarray(img).astype(np.float32)
    rgb = arr[..., :3]
    a = arr[..., 3] / 255.0
    gray = rgb.mean(axis=-1) / 255.0
    ink_alpha = a if from_alpha else np.clip(1.0 - gray, 0.0, 1.0) * a
    ink_bool = ink_alpha > threshold
    return ink_bool, ink_alpha


def build_skeleton_graph(skel: np.ndarray) -> nx.Graph:
    ys, xs = np.nonzero(skel)
    coords = set(zip(ys.tolist(), xs.tolist()))
    g = nx.Graph()
    g.add_nodes_from(coords)
    offsets = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
    for y, x in coords:
        for dy, dx in offsets:
            n = (y + dy, x + dx)
            if n in coords:
                g.add_edge((y, x), n)
    return g


def trace_segment(g: nx.Graph, start, first, keypoints: set) -> list:
    path = [start, first]
    prev, curr = start, first
    while curr not in keypoints:
        nxts = [n for n in g.neighbors(curr) if n != prev]
        if not nxts:
            break
        nxt = nxts[0]
        path.append(nxt)
        prev, curr = curr, nxt
    return path


def extract_segments(g: nx.Graph) -> list[dict]:
    segments = []
    seg_id = 0
    for comp_nodes in nx.connected_components(g):
        comp_nodes = set(comp_nodes)
        keypoints = {n for n in comp_nodes if g.degree(n) != 2}
        if not keypoints:
            # Pure closed loop (e.g. a small circle icon): cut it open at an
            # arbitrary, deterministic point.
            keypoints = {min(comp_nodes)}
        visited_edges = set()
        for kp in sorted(keypoints):
            for nbr in sorted(g.neighbors(kp)):
                edge = frozenset((kp, nbr))
                if edge in visited_edges:
                    continue
                path = trace_segment(g, kp, nbr, keypoints)
                for a, b in zip(path[:-1], path[1:]):
                    visited_edges.add(frozenset((a, b)))
                segments.append({"id": seg_id, "points": path, "a": path[0], "b": path[-1]})
                seg_id += 1
    return segments


def unit_vector(v: np.ndarray) -> np.ndarray:
    n = np.linalg.norm(v)
    if n < 1e-6:
        return np.zeros(2, dtype=np.float64)
    return v / n


def arrival_direction(seg: dict, end: str, sample_window: int) -> np.ndarray:
    points = seg["points"]
    n = min(len(points), sample_window)
    if end == "a":
        near = points[:n]
    else:
        near = list(reversed(points[-n:]))
    kp = np.array(near[0], dtype=np.float64)
    far = np.array(near[-1], dtype=np.float64)
    return unit_vector(kp - far)


def pair_segments_at_junctions(
    g: nx.Graph, segments: list[dict], sample_window: int, pair_dot_threshold: float
) -> nx.Graph:
    by_id = {s["id"]: s for s in segments}
    incident: dict = {}
    for s in segments:
        incident.setdefault(s["a"], []).append((s["id"], "a"))
        if s["b"] != s["a"]:
            incident.setdefault(s["b"], []).append((s["id"], "b"))
        else:
            incident[s["a"]].append((s["id"], "b"))

    sg = nx.Graph()
    for s in segments:
        sg.add_edge((s["id"], "a"), (s["id"], "b"), seg=s["id"])

    for kp, ends in incident.items():
        if len(ends) < 3:
            continue
        dirs = [arrival_direction(by_id[seg_id], end, sample_window) for seg_id, end in ends]
        used = set()
        for i in range(len(ends)):
            if i in used:
                continue
            best_j, best_dot = None, 2.0
            for j in range(len(ends)):
                if j == i or j in used:
                    continue
                d = float(np.dot(dirs[i], dirs[j]))
                if d < best_dot:
                    best_dot, best_j = d, j
            if best_j is not None and best_dot < pair_dot_threshold:
                sg.add_edge(ends[i], ends[j], seg=None)
                used.add(i)
                used.add(best_j)
    return sg


def build_strokes(sg: nx.Graph, segments: list[dict]) -> list[list[tuple]]:
    by_id = {s["id"]: s for s in segments}
    strokes = []
    visited_nodes = set()

    def points_for(seg_id: int, from_end: str) -> list:
        pts = by_id[seg_id]["points"]
        return pts if from_end == "a" else list(reversed(pts))

    for comp in nx.connected_components(sg):
        comp = set(comp)
        if comp & visited_nodes:
            continue
        terminals = [n for n in comp if sg.degree(n) == 1]
        if terminals:
            start = terminals[0]
        else:
            start = next(iter(comp))  # closed loop, arbitrary start

        stroke_points: list = []
        prev_node = None
        curr_node = start
        steps = 0
        max_steps = len(comp) + 1
        while steps <= max_steps:
            steps += 1
            visited_nodes.add(curr_node)
            seg_id, end = curr_node
            pts = points_for(seg_id, end)
            if stroke_points and stroke_points[-1] == pts[0]:
                stroke_points.extend(pts[1:])
            else:
                stroke_points.extend(pts)
            other_node = (seg_id, "b" if end == "a" else "a")
            nbrs = [n for n in sg.neighbors(other_node) if n != curr_node]
            if not nbrs:
                break
            nxt = nbrs[0]
            if nxt == start:
                # closed loop back to the beginning
                pts2 = points_for(nxt[0], nxt[1])
                if stroke_points[-1] == pts2[0]:
                    stroke_points.extend(pts2[1:])
                break
            prev_node, curr_node = other_node, nxt
        strokes.append(stroke_points)
    return strokes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", type=Path)
    parser.add_argument("--out", type=Path, default=None)
    parser.add_argument("--debug", type=Path, default=None)
    parser.add_argument("--no-debug", action="store_true")
    parser.add_argument("--threshold", type=float, default=0.4, help="ink binary threshold, 0..1")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--sample-window", type=int, default=10, help="pixels sampled to estimate a stroke's direction at a junction")
    parser.add_argument("--pair-dot-threshold", type=float, default=-0.5, help="how opposite two directions must be (dot product) to be joined through a crossing")
    parser.add_argument("--ink-from-alpha", action="store_true", help="painted art: every opaque pixel is ink, whatever its colour")
    parser.add_argument("--left-to-right", action="store_true", help="write from left to right instead of in a random order")
    args = parser.parse_args()

    out_path = args.out or args.input.with_name(args.input.stem + "_reveal_mask.png")
    debug_path = None if args.no_debug else (args.debug or args.input.with_name(args.input.stem + "_reveal_debug.png"))

    t0 = time.time()
    ink_bool, ink_alpha = load_ink(args.input, args.threshold, args.ink_from_alpha)
    print(f"ink pixels: {int(ink_bool.sum())}")

    skel = skeletonize(ink_bool)
    print(f"skeleton pixels: {int(skel.sum())}")

    g = build_skeleton_graph(skel)
    segments = extract_segments(g)
    print(f"raw segments (pre-junction-merge): {len(segments)}")

    sg = pair_segments_at_junctions(g, segments, args.sample_window, args.pair_dot_threshold)
    strokes = build_strokes(sg, segments)
    strokes = [s for s in strokes if len(s) > 0]
    if args.left_to_right:
        # Each stroke is drawn from its left end.
        strokes = [list(reversed(s)) if s[0][1] > s[-1][1] else s for s in strokes]
    print(f"final strokes: {len(strokes)}")

    h, w = ink_bool.shape
    skel_progress = np.zeros((h, w), dtype=np.float64)
    skel_stroke_id = np.full((h, w), -1, dtype=np.int32)
    stroke_lengths = np.zeros(len(strokes), dtype=np.float64)

    for idx, pts in enumerate(strokes):
        arr = np.array(pts, dtype=np.float64)
        if len(arr) == 1:
            dists = np.array([0.0])
        else:
            deltas = np.diff(arr, axis=0)
            seg_len = np.sqrt((deltas ** 2).sum(axis=1))
            dists = np.concatenate([[0.0], np.cumsum(seg_len)])
        total = dists[-1]
        stroke_lengths[idx] = total
        progress = dists / total if total > 1e-6 else np.zeros_like(dists)
        for (y, x), p in zip(pts, progress):
            skel_progress[y, x] = p
            skel_stroke_id[y, x] = idx

    rng = np.random.default_rng(args.seed)
    stroke_delay = rng.random(len(strokes))
    if args.left_to_right and strokes:
        # The further right a stroke starts, the later it starts.
        starts = np.array([s[0][1] for s in strokes], dtype=np.float64)
        stroke_delay = (starts - starts.min()) / max(starts.max() - starts.min(), 1.0)
    max_len = stroke_lengths.max() if len(stroke_lengths) else 1.0
    stroke_len_norm = stroke_lengths / max_len if max_len > 1e-6 else stroke_lengths

    # propagate skeleton attributes to every ink pixel via nearest-skeleton lookup
    _, indices = ndimage.distance_transform_edt(~skel, return_distances=True, return_indices=True)
    nearest_y, nearest_x = indices[0], indices[1]

    progress_full = skel_progress[nearest_y, nearest_x]
    stroke_id_full = skel_stroke_id[nearest_y, nearest_x]
    delay_full = np.where(stroke_id_full >= 0, stroke_delay[np.clip(stroke_id_full, 0, None)], 0.0)
    len_full = np.where(stroke_id_full >= 0, stroke_len_norm[np.clip(stroke_id_full, 0, None)], 0.0)

    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., 0] = np.clip(progress_full * 255.0, 0, 255).astype(np.uint8)
    out[..., 1] = np.clip(delay_full * 255.0, 0, 255).astype(np.uint8)
    out[..., 2] = np.clip(len_full * 255.0, 0, 255).astype(np.uint8)
    out[..., 3] = np.clip(ink_alpha * 255.0, 0, 255).astype(np.uint8)

    Image.fromarray(out, mode="RGBA").save(out_path)
    print(f"wrote {out_path}")

    if debug_path is not None:
        dbg = np.full((h, w, 3), 255, dtype=np.uint8)
        for idx in range(len(strokes)):
            hue = (idx * 0.6180339887) % 1.0
            mask = stroke_id_full == idx
            if not np.any(mask):
                continue
            p = progress_full[mask]
            v = 0.35 + 0.65 * p
            for ch in range(3):
                col = np.array([colorsys.hsv_to_rgb(hue, 0.85, vv)[ch] for vv in np.linspace(0.35, 1.0, 32)])
                bucket = np.clip((p * 31).astype(np.int32), 0, 31)
                dbg_channel = dbg[..., ch]
                dbg_channel[mask] = np.clip(col[bucket] * 255.0, 0, 255).astype(np.uint8)
        alpha_mask = ink_alpha > args.threshold
        for ch in range(3):
            dbg[..., ch] = np.where(alpha_mask, dbg[..., ch], 255)
        Image.fromarray(dbg, mode="RGB").save(debug_path)
        print(f"wrote {debug_path}")

    print(f"done in {time.time() - t0:.2f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
