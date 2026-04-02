#!/usr/bin/env python3
"""Generate Twelve app icon: sky + rounded card + stick figure (hollow head, upper body only, fills frame)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pix = img.load()
    c_top = (247, 250, 255)
    c_bot = (230, 242, 255)
    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(lerp(c_top[0], c_bot[0], t))
        g = int(lerp(c_top[1], c_bot[1], t))
        b = int(lerp(c_top[2], c_bot[2], t))
        for x in range(size):
            pix[x, y] = (r, g, b, 255)

    draw = ImageDraw.Draw(img)
    s = size / 1024.0
    pad = int(56 * s)
    corner_r = int(200 * s)
    line = max(5, int(17 * s))
    head_line = max(4, int(13 * s))
    ink = (28, 52, 110, 255)
    card_white = (255, 255, 255, 255)
    rim = (0, 110, 230, 255)

    draw.rounded_rectangle(
        [pad, pad, size - pad, size - pad],
        radius=corner_r,
        fill=card_white,
        outline=rim,
        width=max(4, int(12 * s)),
    )

    cx = size // 2
    # Inner content area (inside blue rim)
    inset = pad + int(22 * s)
    inner_h = (size - inset) - inset

    # Large hollow head (white interior reads as empty ring on white card)
    head_r = int(0.19 * inner_h)
    head_cy = inset + head_r + int(0.04 * inner_h)
    hb = [
        cx - head_r,
        head_cy - head_r,
        cx + head_r,
        head_cy + head_r,
    ]
    draw.ellipse(hb, fill=card_white, outline=ink, width=head_line)

    shoulder_y = head_cy + head_r + int(0.035 * inner_h)
    torso_bot = size - inset - int(0.06 * inner_h)

    # Torso
    draw.line([(cx, shoulder_y), (cx, torso_bot)], fill=ink, width=line)

    # Arms (one line across chest)
    arm_y = shoulder_y + int(0.11 * inner_h)
    arm_half = int(0.36 * (size - 2 * inset) * 0.5)
    draw.line([(cx - arm_half, arm_y), (cx + arm_half, arm_y)], fill=ink, width=line)

    return img


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out_dir = root / "Twelve" / "Assets.xcassets" / "AppIcon.appiconset"
    out_dir.mkdir(parents=True, exist_ok=True)

    base = draw_icon(1024)
    sizes = {
        "AppIcon-1024.png": 1024,
        "AppIcon-180.png": 180,
        "AppIcon-120.png": 120,
        "AppIcon-87.png": 87,
        "AppIcon-80.png": 80,
        "AppIcon-60.png": 60,
        "AppIcon-58.png": 58,
        "AppIcon-40.png": 40,
    }
    for name, dim in sizes.items():
        base.resize((dim, dim), Image.Resampling.LANCZOS).save(out_dir / name, "PNG")

    print("Wrote Twelve stickman icons to", out_dir)


if __name__ == "__main__":
    main()
