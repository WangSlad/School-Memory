#!/usr/bin/env python3
"""Rebuild the spring-campus male/female restroom sign atlas using Pillow.

The 1024x1024 RGB atlas has two equal columns: left male, right female. Each
column covers a complete 0.42 x 0.62 metre physical plaque, U=[0,.5] / [.5,1],
V=[0,1], PNG top at V=0. Artwork is drawn at the plaque's physical aspect ratio
before packing, so Chinese text and pictograms have correct proportions in 3D.
This is a non-tiling atlas; import with repeat disabled and clamp the cell UVs.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import shutil

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "assets/buildings/teaching_floor/spring/textures"
DEFAULT_ARCHIVE = Path("D:/Research/GameDevelopment/\u89c6\u56fe/\u5e73\u9762\u7d20\u6750/B03_teaching_spring")
NAME = "B03_teaching_spring_restroom_signs_\u5e73\u9762.png"
BACKGROUND = "#F1EDE5"
GREEN = "#596D68"
PINK = "#B07B85"  # A dark dusty-sakura ink for contrast on warm ivory.
SAKURA = "#D7A8AF"
WIDTH, HEIGHT = 672, 992  # Exactly the physical .42 : .62 plaque proportion.


def plaque(female: bool) -> Image.Image:
    image = Image.new("RGB", (WIDTH, HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(image)
    chinese = ImageFont.truetype("C:/Windows/Fonts/msyhbd.ttc", 142)
    english = ImageFont.truetype("C:/Windows/Fonts/seguisb.ttf", 68 if female else 77)
    ink = PINK if female else GREEN
    accent = SAKURA if female else "#748680"
    draw.rounded_rectangle((25, 25, WIDTH - 26, HEIGHT - 26), radius=30, outline=ink, width=5)
    draw.rounded_rectangle((58, 55, WIDTH - 59, 73), radius=9, fill=accent)
    center = WIDTH // 2
    # Widely recognized geometric silhouettes, drawn without dependence on
    # platform emoji fonts or downloaded graphics.
    draw.ellipse((center - 57, 137, center + 57, 251), fill=ink)
    if female:
        draw.rounded_rectangle((center - 70, 275, center + 70, 365), radius=35, fill=ink)
        draw.polygon(((center - 57, 307), (center + 57, 307), (center + 135, 509), (center - 135, 509)), fill=ink)
        draw.line((center - 66, 303, center - 134, 438), fill=ink, width=42)
        draw.line((center + 66, 303, center + 134, 438), fill=ink, width=42)
        draw.rounded_rectangle((center - 64, 486, center - 11, 613), radius=22, fill=ink)
        draw.rounded_rectangle((center + 11, 486, center + 64, 613), radius=22, fill=ink)
    else:
        draw.rounded_rectangle((center - 89, 275, center + 89, 451), radius=35, fill=ink)
        draw.rounded_rectangle((center - 133, 283, center - 88, 458), radius=21, fill=ink)
        draw.rounded_rectangle((center + 88, 283, center + 133, 458), radius=21, fill=ink)
        draw.rounded_rectangle((center - 78, 414, center - 12, 613), radius=24, fill=ink)
        draw.rounded_rectangle((center + 12, 414, center + 78, 613), radius=24, fill=ink)
    draw.text((center, 746), "\u5973" if female else "\u7537", font=chinese, fill=ink, anchor="mm")
    draw.line((145, 835, WIDTH - 145, 835), fill=accent, width=3)
    draw.text((center, 897), "WOMEN" if female else "MEN", font=english, fill=ink, anchor="mm")
    return image


def atlas() -> Image.Image:
    image = Image.new("RGB", (1024, 1024), BACKGROUND)
    for column in range(2):
        image.paste(plaque(bool(column)).resize((512, 1024), Image.Resampling.LANCZOS), (column * 512, 0))
    return image


def generate(output: Path, archive: Path) -> None:
    output, archive = output.resolve(), archive.resolve()
    output.mkdir(parents=True, exist_ok=True)
    archive.mkdir(parents=True, exist_ok=True)
    path = output / NAME
    atlas().save(path, optimize=True)
    if output != archive:
        shutil.copy2(path, archive / NAME)
    with Image.open(path) as image:
        assert image.size == (1024, 1024) and image.mode == "RGB"
        image.verify()
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    assert digest == hashlib.sha256((archive / NAME).read_bytes()).hexdigest()
    print("Generated 1024x1024 RGB restroom atlas: left male / right female.")
    print("Plaque aspect .42/.62; PNG top V=0; male U=0..0.5, female U=0.5..1.")
    print("SHA256: " + digest + "; archive identical.")
    print("Output: " + str(path).encode("ascii", "backslashreplace").decode())


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--archive", type=Path, default=DEFAULT_ARCHIVE)
    args = parser.parse_args()
    generate(args.output, args.archive)


if __name__ == "__main__":
    main()
