#!/usr/bin/env python3
"""Generate Twelve app icons (PNG) from a 1024 master matching the app's blue/white diary theme."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "Twelve" / "Assets.xcassets" / "AppIcon.appiconset"
FONT_PATH = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")

# Twelve / primary blue (sRGB)
BLUE = (0, 115, 255)
WHITE = (255, 255, 255)
GRAD_TOP = (238, 245, 255)
GRAD_BOTTOM = (214, 232, 255)


def draw_master(size: int = 1024) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(GRAD_TOP[0] + (GRAD_BOTTOM[0] - GRAD_TOP[0]) * t)
        g = int(GRAD_TOP[1] + (GRAD_BOTTOM[1] - GRAD_TOP[1]) * t)
        b = int(GRAD_TOP[2] + (GRAD_BOTTOM[2] - GRAD_TOP[2]) * t)
        for x in range(size):
            px[x, y] = (r, g, b, 255)

    draw = ImageDraw.Draw(img)
    # Soft "card" panel (rounded rect)
    margin = int(size * 0.12)
    corner = int(size * 0.18)
    panel = [margin, margin, size - margin, size - margin]
    draw.rounded_rectangle(panel, radius=corner, fill=(*WHITE, 255))

    # Subtle inner highlight (diary page feel)
    inset = int(size * 0.04)
    inner = [
        margin + inset,
        margin + inset,
        size - margin - inset,
        size - margin - inset,
    ]
    draw.rounded_rectangle(inner, radius=max(corner - inset, 8), outline=(*BLUE, 38), width=max(size // 256, 1))

    # "12" — app name mark
    text = "12"
    font_size = int(size * 0.36)
    try:
        font = ImageFont.truetype(str(FONT_PATH), font_size)
    except OSError:
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (size - tw) // 2
    ty = (size - th) // 2 - int(size * 0.02)
    draw.text((tx, ty), text, font=font, fill=(*BLUE, 255))

    # Small book / journal tick (minimal line art)
    line_y = int(size * 0.72)
    line_w = int(size * 0.22)
    lx0 = (size - line_w) // 2
    draw.rounded_rectangle(
        [lx0, line_y, lx0 + line_w, line_y + int(size * 0.018)],
        radius=int(size * 0.01),
        fill=(*BLUE, 90),
    )

    return img


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    master = draw_master(1024)

    outputs = [
        (40, "AppIcon-40.png"),
        (60, "AppIcon-60.png"),
        (58, "AppIcon-58.png"),
        (87, "AppIcon-87.png"),
        (80, "AppIcon-80.png"),
        (120, "AppIcon-120.png"),
        (180, "AppIcon-180.png"),
        (1024, "AppIcon-1024.png"),
    ]

    for dim, name in outputs:
        out = master.resize((dim, dim), Image.Resampling.LANCZOS)
        path = OUT_DIR / name
        out.save(path, "PNG")
        print(f"Wrote {path} ({dim}x{dim})")

    contents = {
        "images": [
            {"filename": "AppIcon-40.png", "idiom": "iphone", "scale": "2x", "size": "20x20"},
            {"filename": "AppIcon-60.png", "idiom": "iphone", "scale": "3x", "size": "20x20"},
            {"filename": "AppIcon-58.png", "idiom": "iphone", "scale": "2x", "size": "29x29"},
            {"filename": "AppIcon-87.png", "idiom": "iphone", "scale": "3x", "size": "29x29"},
            {"filename": "AppIcon-80.png", "idiom": "iphone", "scale": "2x", "size": "40x40"},
            {"filename": "AppIcon-120.png", "idiom": "iphone", "scale": "3x", "size": "40x40"},
            {"filename": "AppIcon-120.png", "idiom": "iphone", "scale": "2x", "size": "60x60"},
            {"filename": "AppIcon-180.png", "idiom": "iphone", "scale": "3x", "size": "60x60"},
            {"filename": "AppIcon-1024.png", "idiom": "ios-marketing", "scale": "1x", "size": "1024x1024"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    import json

    (OUT_DIR / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")
    print(f"Updated {OUT_DIR / 'Contents.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
