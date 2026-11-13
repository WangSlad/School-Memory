#!/usr/bin/env python3
"""Generate restrained painted-wood joinery textures for the spring campus.

Dependencies: NumPy, Pillow. Run from any directory. The two wood base colors,
normal and roughness are seamless and share one grain pattern. Door panel is a
full-door, non-repeating image: U=left to right, image V=top to bottom, covering
1.3 x 2.35 metres. Map local door (x,y) to ((x+0.65)/1.3, 1-y/2.35).
No glass, hardware, text or door sign is baked into the panel image.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import shutil

import numpy as np
from PIL import Image


SIZE = 1024
PREFIX = "B03_teaching_spring_"
PLANAR = "_\u5e73\u9762.png"
ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "assets/buildings/teaching_floor/spring/textures"
DEFAULT_ARCHIVE = Path("D:/Research/GameDevelopment/\u89c6\u56fe/\u5e73\u9762\u7d20\u6750/B03_teaching_spring")


def periodic_field(seed: int, horizontal: float, vertical: float) -> np.ndarray:
    """An anisotropic random field synthesized directly on a periodic domain."""
    white = np.random.default_rng(seed).standard_normal((SIZE, SIZE))
    fy = np.fft.fftfreq(SIZE)[:, None]
    fx = np.fft.rfftfreq(SIZE)[None, :]
    filter_value = np.exp(-2.0 * np.pi**2 * ((fx * horizontal)**2 + (fy * vertical)**2))
    field = np.fft.irfft2(np.fft.rfft2(white) * filter_value, s=(SIZE, SIZE))
    field -= field.mean()
    field /= max(float(field.std()), 1e-8)
    return np.clip(field, -3.0, 3.0)


def painted_wood() -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    y, x = np.mgrid[:SIZE, :SIZE] / SIZE
    long_grain = periodic_field(1801, 2.2, 57.0)
    fine_grain = periodic_field(1802, 0.65, 18.0)
    soft_grain = periodic_field(1803, 13.0, 125.0)
    paint_stipple = periodic_field(1804, 0.7, 0.7)
    # The integer X/Y harmonics and periodic warp keep all fibres continuous
    # through both image borders. These subdued fibres show through aged paint.
    warp = 0.18 * np.sin(2 * np.pi * y) + 0.08 * np.sin(6 * np.pi * y + 1.4)
    phase = 2 * np.pi * (37.0 * x + warp + 0.04 * soft_grain)
    fibre = np.maximum(np.cos(phase), 0.0)**20
    fibre -= fibre.mean()
    variation = 0.84 * long_grain + 0.32 * fine_grain + 0.26 * soft_grain - 2.15 * fibre + 0.13 * paint_stipple
    variation -= variation.mean()
    door = np.array([89, 109, 104], dtype=float)[None, None, :] + variation[:, :, None]
    frame = np.array([116, 134, 128], dtype=float)[None, None, :] + variation[:, :, None] * 0.84
    height = 0.22 * long_grain + 0.06 * fine_grain - 0.40 * fibre + 0.03 * paint_stipple
    dx = 0.5 * (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.72
    dy = 0.5 * (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.72
    normal = np.stack((-dx, dy, np.ones_like(dx)), axis=2)
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    normal = (normal * 0.5 + 0.5) * 255.0
    roughness = (0.73 + 0.015 * long_grain + 0.008 * soft_grain + 0.006 * paint_stipple) * 255.0
    return door, frame, normal, roughness


def inside_rect(x: np.ndarray, y: np.ndarray, left: float, bottom: float, right: float, top: float, softness: float) -> np.ndarray:
    d = np.minimum.reduce((x - left, right - x, y - bottom, top - y))
    t = np.clip(d / softness + 0.5, 0.0, 1.0)
    return t * t * (3 - 2 * t)


def door_panel(wood: np.ndarray) -> np.ndarray:
    """Lightly routed panels, no invented window, handle, plate or text.

    Physical dimensions of the image: 1.30 m wide x 2.35 m high. All detail
    stops below 1.78 m so the existing plaque centered at 2.052 m remains clean.
    The line work is shallow joinery tint, not directional baked illumination.
    """
    yy, xx = np.mgrid[:SIZE, :SIZE]
    x = (xx + 0.5) / SIZE * 1.3
    y = (1.0 - (yy + 0.5) / SIZE) * 2.35
    panel = wood.copy()
    # A slightly denser protective coating along the outer stiles and rails.
    center = inside_rect(x, y, 0.065, 0.070, 1.235, 2.28, 0.006)
    panel -= (1 - center)[:, :, None] * 1.25
    # Twin raised-style recessed fields, with a single shallow perimeter groove.
    # The top rail is deliberately plain to receive the existing number shader.
    for bottom, top in ((0.16, 0.40), (0.48, 1.70)):
        outer = inside_rect(x, y, 0.17, bottom, 1.13, top, 0.006)
        inner = inside_rect(x, y, 0.182, bottom + 0.012, 1.118, top - 0.012, 0.005)
        outer_groove = np.clip(outer - inner, 0, 1)
        panel -= outer_groove[:, :, None] * 7.8
        inset = inside_rect(x, y, 0.199, bottom + 0.029, 1.101, top - 0.029, 0.005)
        soft_bead = np.clip(inner - inset, 0, 1)
        panel += soft_bead[:, :, None] * 1.7
        panel -= inset[:, :, None] * 0.8
    # A restrained pair of vertical seams in the small bottom field reinforces
    # the slim timber boards without becoming a graphic stripe pattern.
    bottom_field = inside_rect(x, y, 0.20, 0.19, 1.10, 0.37, 0.005)
    seams = np.exp(-((x - 0.50) / 0.0026)**2) + np.exp(-((x - 0.80) / 0.0026)**2)
    panel -= (seams * bottom_field)[:, :, None] * 4.0
    return panel


def quantize(data: np.ndarray) -> np.ndarray:
    return np.rint(np.clip(data, 0.0, 255.0)).astype(np.uint8)


def generate(output: Path, archive: Path) -> None:
    output, archive = output.resolve(), archive.resolve()
    output.mkdir(parents=True, exist_ok=True)
    archive.mkdir(parents=True, exist_ok=True)
    door, frame, normal, roughness = painted_wood()
    images = {
        PREFIX + "door_wood" + PLANAR: door,
        PREFIX + "frame_wood" + PLANAR: frame,
        PREFIX + "wood_normal.png": normal,
        PREFIX + "wood_roughness.png": roughness,
        PREFIX + "door_panel" + PLANAR: door_panel(door),
    }
    for name, data in images.items():
        destination = output / name
        Image.fromarray(quantize(data)).save(destination, optimize=True)
        if archive != output:
            shutil.copy2(destination, archive / name)
        with Image.open(destination) as image:
            assert image.size == (SIZE, SIZE)
            assert image.mode == ("L" if data.ndim == 2 else "RGB")
            image.verify()
        if archive != output:
            assert hashlib.sha256(destination.read_bytes()).digest() == hashlib.sha256((archive / name).read_bytes()).digest()
        f = quantize(data).astype(float)
        seam = (abs(f[:, 0] - f[:, -1]).mean() + abs(f[0] - f[-1]).mean()) * 0.5
        adjacent = (abs(np.diff(f, axis=0)).mean() + abs(np.diff(f, axis=1)).mean()) * 0.5
        print(f"{name.encode('ascii', 'backslashreplace').decode()}: 1024x1024 OK; seam={seam:.4f}, adjacent={adjacent:.4f}; archive identical")
    print("Generated five joinery PNGs. Existing spring textures were not opened or rewritten.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--archive", type=Path, default=DEFAULT_ARCHIVE)
    args = parser.parse_args()
    generate(args.output, args.archive)


if __name__ == "__main__":
    main()
