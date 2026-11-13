#!/usr/bin/env python3
"""Rebuild the seamless spring-campus palette with NumPy and Pillow.

Run from any directory. Dependencies: pillow, numpy. All texture data is generated
locally; no downloaded images or hidden inputs are used. Normal maps use OpenGL
orientation (positive green points along positive UV V).
"""

from __future__ import annotations

import argparse
from pathlib import Path
import shutil

import numpy as np
from PIL import Image, ImageDraw, ImageFont


SIZE = 1024
PREFIX = "B03_teaching_spring_"
PLANAR = "_\u5e73\u9762.png"
PREVIEW = PREFIX + "\u9884\u89c8.png"
ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "assets/buildings/teaching_floor/spring/textures"
DEFAULT_ARCHIVE = Path("D:/Research/GameDevelopment/\u89c6\u56fe/\u5e73\u9762\u7d20\u6750/B03_teaching_spring")
PALETTE = {
    "wall": "F1EDE5",
    "floor": "C7C1B5",
    "door": "596D68",
    "frame": "748680",
    "concrete": "D5D0C7",
    "sakura": "D7A8AF",
    "malt": "D9BD7B",
}


def periodic_noise(seed: int, wavelength: float) -> np.ndarray:
    """Unit-variance toroidal random field, with no pasted or blended seams."""
    rng = np.random.default_rng(seed)
    white = rng.standard_normal((SIZE, SIZE))
    fy = np.fft.fftfreq(SIZE)[:, None]
    fx = np.fft.rfftfreq(SIZE)[None, :]
    # A smooth Gaussian spectrum gives brush-free, uniform fine material grain.
    spectrum = np.exp(-2.0 * np.pi**2 * (fx * fx + fy * fy) * wavelength**2)
    field = np.fft.irfft2(np.fft.rfft2(white) * spectrum, s=(SIZE, SIZE))
    field -= field.mean()
    field /= max(float(field.std()), 1e-8)
    return np.clip(field, -3.0, 3.0)


def rgb(hex_color: str) -> np.ndarray:
    return np.array([int(hex_color[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def painted(hex_color: str, seed: int, amplitude: float = 0.65) -> tuple[np.ndarray, np.ndarray]:
    grain = periodic_noise(seed, 0.7)
    soft = periodic_noise(seed + 1, 5.0)
    broad = periodic_noise(seed + 2, 42.0)
    variation = amplitude * (0.68 * grain + 0.24 * soft + 0.08 * broad)
    base = rgb(hex_color)[None, None, :] + variation[:, :, None]
    # Keep color shifts neutral: the supplied palette remains the material mean.
    height = 0.65 * grain + 0.25 * soft + 0.10 * broad
    return base, height


def normal_map(height: np.ndarray, strength: float) -> np.ndarray:
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 0.5 * strength
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * 0.5 * strength
    normals = np.stack((-dx, dy, np.ones_like(dx)), axis=2)
    normals /= np.linalg.norm(normals, axis=2, keepdims=True)
    return (normals * 0.5 + 0.5) * 255.0


def floor_texture() -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    yy, xx = np.mgrid[:SIZE, :SIZE]
    pitch = SIZE // 4
    dx = np.minimum(xx % pitch, pitch - xx % pitch)
    dy = np.minimum(yy % pitch, pitch - yy % pitch)
    distance = np.minimum(dx, dy).astype(np.float32)
    # Four-pixel visual seam, including the soft ceramic bevel.
    fill = np.clip((distance - 0.75) / 1.5, 0.0, 1.0)
    fill = fill * fill * (3.0 - 2.0 * fill)
    # Tile identities follow the actual joint positions, including the wrap tile.
    tile_ids_x = (xx // pitch) % 4
    tile_ids_y = (yy // pitch) % 4
    offsets = np.random.default_rng(340).uniform(-2.6, 2.6, size=(4, 4))
    offsets -= offsets.mean()
    fine = periodic_noise(341, 0.8)
    soft = periodic_noise(342, 9.0)
    ceramic = rgb(PALETTE["floor"])[None, None, :] + (
        offsets[tile_ids_y, tile_ids_x] + fine * 0.28 + soft * 0.20
    )[:, :, None]
    grout = np.array([166.0, 160.0, 149.0])[None, None, :] + fine[:, :, None] * 0.35
    base = ceramic * fill[:, :, None] + grout * (1.0 - fill[:, :, None])
    height = 0.68 * fill + fine * 0.006
    roughness = 0.69 * fill + 0.88 * (1.0 - fill) + soft * 0.006
    return base, height, roughness


def save_png(path: Path, data: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = Image.fromarray(np.rint(np.clip(data, 0, 255)).astype(np.uint8))
    temporary = path.with_suffix(".tmp.png")
    image.save(temporary, optimize=True)
    temporary.replace(path)


def boundary_stats(data: np.ndarray) -> tuple[float, float]:
    f = np.asarray(data, dtype=float)
    seam = 0.5 * (np.abs(f[:, 0] - f[:, -1]).mean() + np.abs(f[0] - f[-1]).mean())
    neighbors = 0.5 * (np.abs(np.diff(f, axis=0)).mean() + np.abs(np.diff(f, axis=1)).mean())
    return float(seam), float(neighbors)


def make_preview(output: Path, bases: dict[str, np.ndarray]) -> Path:
    preview = Image.new("RGB", (1400, 780), "#f6f1e8")
    draw = ImageDraw.Draw(preview)
    try:
        title_font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 30)
        label_font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 20)
    except OSError:
        title_font = label_font = ImageFont.load_default()
    draw.text((36, 22), "SPRING CAMPUS / MATERIAL PALETTE", fill="#596D68", font=title_font)
    draw.text((36, 67), "Warm ivory / limestone / sage / dusty sakura / malt", fill="#748680", font=label_font)
    for index, (name, base) in enumerate(bases.items()):
        col, row = index % 4, index // 4
        x, y = 36 + col * 342, 120 + row * 315
        sample = Image.fromarray(np.rint(np.clip(base, 0, 255)).astype(np.uint8)).resize((300, 235), Image.Resampling.LANCZOS)
        preview.paste(sample, (x, y))
        draw.text((x, y + 244), name.upper() + "  #" + PALETTE[name], fill="#596D68", font=label_font)
    draw.text((1062, 665), "1024 x 1024\nSeamless / OpenGL normals", fill="#596D68", font=label_font)
    path = output.parent / PREVIEW
    preview.save(path, optimize=True)
    return path


def sign_atlas(floor: int = 1) -> np.ndarray:
    """Eight horizontal door-sign strips, row 0 corresponding to room floor-01."""
    image = Image.new("RGB", (SIZE, SIZE), "#D9BD7B")
    draw = ImageDraw.Draw(image)
    try:
        number_font = ImageFont.truetype("C:/Windows/Fonts/seguisb.ttf", 79)
        small_font = ImageFont.truetype("C:/Windows/Fonts/seguisb.ttf", 29)
    except OSError:
        number_font = small_font = ImageFont.load_default()
    ink = "#596D68"
    for row in range(8):
        top = row * 128
        draw.rounded_rectangle((42, top + 10, 982, top + 117), radius=8, outline=ink, width=5)
        draw.text((89, top + 62), f"{floor}-{row + 1:02d}", fill=ink, font=number_font, anchor="lm")
        draw.line((521, top + 31, 521, top + 96), fill=ink, width=4)
        draw.text((568, top + 64), "CLASSROOM", fill=ink, font=small_font, anchor="lm")
    return np.array(image)


def sign_five_atlas() -> np.ndarray:
    """Five floor columns by eight classroom rows, with exact UV fifths.

    Draw each source plate at its original 1024 x 128 proportions. Resampling
    the complete 5120-wide atlas keeps column boundaries exactly at i / 5 UV,
    rather than accumulating errors from rounding each target column width.
    Every plate retains an eight-pixel horizontal safety margin after reduction.
    """
    large = Image.new("RGB", (SIZE * 5, SIZE), "#D9BD7B")
    for floor in range(1, 6):
        large.paste(Image.fromarray(sign_atlas(floor)), ((floor - 1) * SIZE, 0))
    return np.array(large.resize((SIZE, SIZE), Image.Resampling.LANCZOS))


def generate_sign_five_only(output: Path, archive: Path) -> None:
    """Add/update the five-floor atlas without opening or rewriting older PNGs."""
    output = output.resolve()
    archive = archive.resolve()
    output.mkdir(parents=True, exist_ok=True)
    archive.mkdir(parents=True, exist_ok=True)
    destination = output / (PREFIX + "sign_five" + PLANAR)
    save_png(destination, sign_five_atlas())
    if archive != output:
        shutil.copy2(destination, archive / destination.name)
    with Image.open(destination) as image:
        assert image.size == (SIZE, SIZE) and image.mode == "RGB"
        image.verify()
    print("Generated five-floor sign atlas: 1024x1024 RGB; 5 columns x 8 rows.")
    print("UV column bounds: i/5; UV row bounds: j/8; labels: 1-01 through 5-08.")
    print("Output: " + str(destination).encode("ascii", "backslashreplace").decode())


def generate(output: Path, archive: Path) -> None:
    output = output.resolve()
    archive = archive.resolve()
    output.mkdir(parents=True, exist_ok=True)
    archive.mkdir(parents=True, exist_ok=True)
    bases: dict[str, np.ndarray] = {}
    images: dict[str, np.ndarray] = {}
    heights: dict[str, np.ndarray] = {}
    for index, (name, color) in enumerate(PALETTE.items()):
        amplitude = 0.90 if name == "concrete" else 0.50 if name in ("door", "frame", "malt") else 0.65
        base, height = painted(color, 100 + index * 10, amplitude)
        if name == "floor":
            base, height, floor_roughness = floor_texture()
        bases[name] = base
        heights[name] = height
        images[PREFIX + name + PLANAR] = base

    for name, strength in (("wall", 0.055), ("concrete", 0.080), ("floor", 0.75)):
        images[PREFIX + name + "_normal.png"] = normal_map(heights[name], strength)
        if name == "floor":
            roughness = floor_roughness
        else:
            roughness = (0.86 if name == "wall" else 0.90) + periodic_noise(600 if name == "wall" else 610, 3.0) * 0.012
        images[PREFIX + name + "_roughness.png"] = roughness * 255.0
    images[PREFIX + "paint_roughness.png"] = (0.66 + periodic_noise(620, 2.0) * 0.009) * 255.0
    images[PREFIX + "sign" + PLANAR] = sign_atlas()
    images[PREFIX + "sign_five" + PLANAR] = sign_five_atlas()

    for filename, data in images.items():
        destination = output / filename
        save_png(destination, data)
        if archive != output:
            shutil.copy2(destination, archive / filename)
        seam, neighbor = boundary_stats(data)
        with Image.open(destination) as image:
            assert image.size == (SIZE, SIZE)
            assert image.mode in ("RGB", "L")
            image.verify()
        atlas_note = " (intentional non-tiling atlas)" if "sign" in filename else ""
        print(f"{filename.encode('ascii', 'backslashreplace').decode()}: seam={seam:.4f}; adjacent={neighbor:.4f}; 1024x1024 OK{atlas_note}")

    preview = make_preview(output, bases)
    if preview.parent != archive:
        shutil.copy2(preview, archive / preview.name)
    print(f"Generated {len(images)} texture PNGs and one palette preview.")
    print("Output: " + str(output).encode("ascii", "backslashreplace").decode())
    print("Archive: " + str(archive).encode("ascii", "backslashreplace").decode())


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Project texture directory")
    parser.add_argument("--archive", type=Path, default=DEFAULT_ARCHIVE, help="Source-art archive directory")
    parser.add_argument("--sign-five-only", action="store_true", help="Generate only the new five-floor door-sign atlas, preserving existing PNGs")
    args = parser.parse_args()
    if args.sign_five_only:
        generate_sign_five_only(args.output, args.archive)
    else:
        generate(args.output, args.archive)


if __name__ == "__main__":
    main()
