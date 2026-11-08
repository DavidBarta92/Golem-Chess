"""Synthesises the pack opening's sounds into Audio/SFX, as placeholders for real
recordings of the same names: paper and foil are noise shaped by crackle, bells
are a few inharmonic partials.

    python tools/generate_pack_sounds.py

The game's sounds are quiet (peaks of about 0.03 to 0.25), so the levels here
match them rather than filling the range. SFXManager groups names ending in a
number, so pack_tear_1..4 play as "pack_tear".
"""

from pathlib import Path

import numpy as np
from scipy.signal import butter, fftconvolve, sosfilt

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "Audio" / "SFX"


def seconds(length):
    return np.arange(int(length * RATE)) / RATE


def band(signal, low, high):
    return sosfilt(butter(4, [low, high], btype="band", fs=RATE, output="sos"), signal)


def lowpass(signal, cutoff):
    return sosfilt(butter(4, cutoff, btype="low", fs=RATE, output="sos"), signal)


def crackle(rng, length, density):
    """Paper fibres giving way: a stream of tiny, uneven snaps. `density` is
    snaps a second, and may be an array along the sound."""
    count = int(length * RATE)
    rate_now = np.full(count, density) if np.isscalar(density) else np.interp(np.linspace(0, 1, count), np.linspace(0, 1, len(density)), density)
    snaps = (rng.random(count) < rate_now / RATE) * rng.lognormal(0.0, 0.8, count)
    tail = np.exp(-seconds(0.006) / 0.0012)
    return fftconvolve(snaps, tail)[:count]


def rip(rng, length, density, bright=(1800.0, 8500.0), body=(350.0, 1400.0)):
    """Crackle through paper's bands: a bright surface and a dull body."""
    grains = crackle(rng, length, density)
    noise = rng.standard_normal(len(grains))
    surface = band(noise * grains, *bright)
    weight = band(noise * grains, *body)
    return surface + weight * 0.55


def envelope(length, attack, release):
    time = seconds(length)
    rise = np.clip(time / max(attack, 1e-4), 0.0, 1.0)
    fall = np.clip((length - time) / max(release, 1e-4), 0.0, 1.0)
    return rise * fall


def bell(frequency, length, decay, partials=((1.0, 1.0), (2.76, 0.42), (5.4, 0.16))):
    time = seconds(length)
    out = np.zeros_like(time)
    for ratio, level in partials:
        out += level * np.sin(2.0 * np.pi * frequency * ratio * time) * np.exp(-time * ratio ** 0.6 / decay)
    return out


def place(target, sound, at):
    start = int(at * RATE)
    end = min(len(target), start + len(sound))
    target[start:end] += sound[: end - start]


def room(signal, rng, length=1.6, wet=0.32):
    """A soft room: the sound convolved with a decaying noise tail."""
    time = seconds(length)
    impulse = rng.standard_normal(len(time)) * np.exp(-time / (length * 0.24))
    impulse = lowpass(impulse, 6000.0)
    tail = fftconvolve(signal, impulse)[: len(signal)]
    return signal + tail / np.max(np.abs(tail)) * np.max(np.abs(signal)) * wet


def write(name, signal, rng, peak):
    """Stereo from one take: the two sides differ a little in their timing."""
    signal = signal - np.mean(signal)
    fade = np.clip((len(signal) - np.arange(len(signal))) / (0.01 * RATE), 0.0, 1.0)
    signal = signal * fade
    side = np.roll(signal, int(rng.integers(8, 28)))
    stereo = np.stack([signal, side * 0.94], axis=1)
    stereo *= peak / np.max(np.abs(stereo))
    data = np.clip(stereo * 32767.0, -32768, 32767).astype(np.int16)
    import wave

    with wave.open(str(OUT / f"{name}.wav"), "wb") as out:
        out.setnchannels(2)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(data.tobytes())
    print(f"{name}: {len(signal) / RATE:.2f} s, peak {peak:.2f}, rms {np.sqrt(np.mean(stereo ** 2)):.4f}")


def tear_grains(rng):
    """One short stretch of a rip each. The tear plays one every few percent of
    the width, so a slow drag rustles and a fast one runs together."""
    for i in range(1, 5):
        length = rng.uniform(0.13, 0.2)
        sound = rip(rng, length, rng.uniform(900.0, 1700.0)) * envelope(length, 0.004, length * 0.7)
        write(f"pack_tear_{i}", sound, rng, 0.11)


def crinkle(rng):
    for i in range(1, 4):
        length = rng.uniform(0.22, 0.32)
        sound = rip(rng, length, 170.0, bright=(2500.0, 11000.0), body=(600.0, 1800.0)) * envelope(length, 0.01, length * 0.6)
        write(f"pack_crinkle_{i}", sound, rng, 0.06)


def tear_finish(rng):
    """The last of the rip, quickening, then the strip snapping free and the
    pack's sigh as the strain goes out of it."""
    length = 0.5
    sound = np.zeros(int(length * RATE))
    run = 0.2
    place(sound, rip(rng, run, np.array([900.0, 2600.0])) * envelope(run, 0.005, 0.03), 0.0)
    snap_length = 0.05
    snap = band(rng.standard_normal(int(snap_length * RATE)), 900.0, 6000.0) * np.exp(-seconds(snap_length) / 0.009)
    place(sound, snap * 3.2, run - 0.012)
    time = seconds(0.22)
    thump = np.sin(2.0 * np.pi * (95.0 * time - 55.0 * time ** 2)) * np.exp(-time / 0.06)
    place(sound, thump * 0.42, run - 0.01)
    air_length = 0.26
    air = band(rng.standard_normal(int(air_length * RATE)), 300.0, 2200.0) * envelope(air_length, 0.02, 0.2)
    place(sound, air * 0.2, run)
    write("pack_tear_finish", sound, rng, 0.17)


def foil_tease(rng):
    """Thin shimmer: high partials beating against each other under a breath."""
    length = 1.0
    time = seconds(length)
    shimmer = np.zeros_like(time)
    for frequency in (2637.0, 3136.0, 3953.0, 4699.0, 5274.0):
        drift = 1.0 + 0.0016 * np.sin(2.0 * np.pi * rng.uniform(3.0, 6.0) * time + rng.uniform(0.0, 6.0))
        phase = 2.0 * np.pi * np.cumsum(frequency * drift) / RATE
        shimmer += np.sin(phase) * (0.5 + 0.5 * np.sin(2.0 * np.pi * rng.uniform(5.0, 11.0) * time + rng.uniform(0.0, 6.0)))
    air = band(rng.standard_normal(len(time)), 4000.0, 12000.0) * 0.5
    swell = np.clip(time / 0.55, 0.0, 1.0) ** 1.6 * np.clip((length - time) / 0.3, 0.0, 1.0)
    write("pack_foil_tease", (shimmer + air) * swell, rng, 0.07)


def foil_reveal(rng):
    """A short glint going up: four bells and a dust of tiny ones."""
    length = 1.5
    sound = np.zeros(int(length * RATE))
    for i, frequency in enumerate((1318.5, 1661.2, 1975.5, 2637.0)):
        place(sound, bell(frequency, 1.0, 0.34) * (0.8 + i * 0.1), i * 0.055)
    for _ in range(22):
        at = rng.uniform(0.04, 0.5)
        place(sound, bell(rng.uniform(3000.0, 7000.0), 0.12, 0.03, ((1.0, 1.0),)) * rng.uniform(0.04, 0.16), at)
    write("pack_foil_reveal", room(sound, rng, 1.0, 0.24), rng, 0.15)


def full_art_tease(rng):
    """Something heavy waking up: a low swell rising, with a shudder in it."""
    length = 1.25
    time = seconds(length)
    pitch = 46.0 + 44.0 * (time / length) ** 2
    phase = 2.0 * np.pi * np.cumsum(pitch) / RATE
    low = np.sin(phase) + 0.4 * np.sin(2.0 * phase) + 0.2 * np.sin(3.0 * phase)
    shudder = 0.72 + 0.28 * np.sin(2.0 * np.pi * (7.0 + 9.0 * time / length) * time)
    riser = band(rng.standard_normal(len(time)), 900.0, 7000.0) * (time / length) ** 3 * 0.32
    swell = (time / length) ** 1.5 * np.clip((length - time) / 0.05, 0.0, 1.0)
    write("pack_full_art_tease", (low * shudder + riser) * swell, rng, 0.17)


def full_art_reveal(rng):
    """The hit: a deep thump, a broad bright chord of bells, and a long tail."""
    length = 3.4
    sound = np.zeros(int(length * RATE))
    time = seconds(0.6)
    thump = np.sin(2.0 * np.pi * (110.0 * time - 62.0 * time ** 2)) * np.exp(-time / 0.16)
    place(sound, thump * 1.1, 0.0)
    crack_length = 0.09
    crack = band(rng.standard_normal(int(crack_length * RATE)), 1200.0, 9000.0) * np.exp(-seconds(crack_length) / 0.016)
    place(sound, crack * 0.8, 0.0)
    chord = (220.0, 329.6, 440.0, 554.4, 659.3, 880.0, 1108.7, 1318.5)
    for i, frequency in enumerate(chord):
        place(sound, bell(frequency, 3.0, 1.15, ((1.0, 1.0), (2.0, 0.34), (3.01, 0.14), (4.2, 0.07))) * (0.5 if i < 2 else 0.34), 0.012 * i)
    for _ in range(46):
        at = rng.uniform(0.05, 1.5)
        place(sound, bell(rng.uniform(2600.0, 8000.0), 0.3, 0.07, ((1.0, 1.0),)) * rng.uniform(0.02, 0.09), at)
    write("pack_full_art_reveal", room(sound, rng, 2.2, 0.42), rng, 0.24)


def main():
    rng = np.random.default_rng(7)
    tear_grains(rng)
    crinkle(rng)
    tear_finish(rng)
    foil_tease(rng)
    foil_reveal(rng)
    full_art_tease(rng)
    full_art_reveal(rng)


if __name__ == "__main__":
    main()
