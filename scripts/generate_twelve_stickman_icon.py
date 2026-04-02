#!/usr/bin/env python3
"""Generate Twelve app icon: soft sky + rounded card + simple stick figure (Pillow)."""

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
    pad = int(88 * s)
    draw.rounded_rectangle(
        [pad, pad, size - pad, size - pad],
        radius=int(190 * s),
        fill=(255, 255, 255, 255),
        outline=(0, 122, 255, 255),
        width=max(4, int(14 * s)),
    )

    cx = size // 2
    head_y = int(320 * s) + pad // 2
    head_r = int(62 * s)
    draw.ellipse(
        [cx - head_r, head_y - head_r, cx + head_r, head_y + head_r],
        fill=(40, 55, 95, 255),
        outline=(0, 90, 210, 255),
        width=max(2, int(6 * s)),
    )

    body_top = head_y + head_r + int(8 * s)
    body_bot = int(size * 0.72)
    draw.line([(cx, body_top), (cx, body_bot)], fill=(40, 55, 95, 255), width=max(5, int(14 * s)))

    arm_y = body_top + int(40 * s)
    arm_w = int(120 * s)
    draw.line([(cx - arm_w, arm_y), (cx + arm_w, arm_y)], fill=(40, 55, 95, 255), width=max(5, int(14 * s)))

    leg_spread = int(95 * s)
    foot_y = int(size * 0.78)
    draw.line([(cx, body_bot), (cx - leg_spread, foot_y)], fill=(40, 55, 95, 255), width=max(5, int(14 * s)))
    draw.line([(cx, body_bot), (cx + leg_spread, foot_y)], fill=(40, 55, 95, 255), width=max(5, int(14 * s)))

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
