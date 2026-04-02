#!/usr/bin/env python3
"""Twelve app icon: pale blue sky, hand-drawn wobbly stick figure (Draw a Stickman–like), white card."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from icon_hand_drawn import (  # noqa: E402
    faint_breeze_arcs,
    fill_sky_gradient,
    stroke_wobbly_line,
    stroke_wobbly_ellipse,
    stroke_wobbly_round_rect,
)


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fill_sky_gradient(
        img,
        top=(240, 249, 255),
        bottom=(218, 236, 252),
    )
    draw = ImageDraw.Draw(img)
    s = size / 1024.0
    scale = s

    breeze = (255, 255, 255, 70)
    faint_breeze_arcs(draw, size, scale, breeze, max(2, int(3 * s)))

    pad = int(52 * s)
    r_card = int(198 * s)
    card_fill = (255, 255, 255, 255)
    card_outline = (120, 178, 230, 255)
    stroke_wobbly_round_rect(
        draw,
        float(pad),
        float(pad),
        float(size - pad),
        float(size - pad),
        float(r_card),
        fill=card_fill,
        outline=card_outline,
        width=max(3, int(10 * s)),
        scale=scale,
        phase=0.2,
    )

    cx = size / 2
    inset = pad + int(20 * s)
    inner_h = (size - inset) - inset
    ink = (72, 118, 175, 255)
    line_w = max(4, int(14 * s))
    head_w = max(3, int(11 * s))

    head_r = 0.185 * inner_h
    head_cy = inset + head_r + 0.035 * inner_h
    stroke_wobbly_ellipse(
        draw,
        cx,
        head_cy,
        head_r,
        head_r * 1.02,
        fill=card_fill,
        outline=ink,
        width=head_w,
        scale=scale,
        segments=48,
        phase=0.7,
    )

    shoulder_y = head_cy + head_r + 0.03 * inner_h
    torso_bot = size - inset - 0.055 * inner_h
    stroke_wobbly_line(
        draw,
        cx,
        shoulder_y,
        cx + 0.012 * size,
        torso_bot,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=32,
        phase=1.1,
    )

    arm_y = shoulder_y + 0.10 * inner_h
    half = 0.34 * (size - 2 * inset) * 0.5
    stroke_wobbly_line(
        draw,
        cx - half,
        arm_y + 0.008 * size,
        cx + half,
        arm_y - 0.006 * size,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=36,
        phase=2.0,
    )

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

    print("Wrote Twelve icons to", out_dir)


if __name__ == "__main__":
    main()
